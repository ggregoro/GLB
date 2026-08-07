#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: export.sh
# Purpose: Capture a machine's current state (packages, tracked
#          dotfiles, shell/prompt setup) into a profile-shaped
#          snapshot, the reverse direction of `glb restore`.
#          See docs/design/state-export-import.md.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Write packages.txt: every explicitly-installed package,
# reverse-mapped through _GLB_PACKAGE_OVERRIDES back to GLB's
# canonical names.
# ------------------------------------------------------------

glb_export_packages() {
    local snapshot_dir="$1"
    local pkg_mgr raw generic

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    {
        printf "# GLB snapshot: packages explicitly installed on %s\n" "$(hostname)"
        printf "# Captured by 'glb export' on %s (%s)\n" "$(date +%Y-%m-%d)" "$pkg_mgr"
        printf "#\n"
        printf "# Same format as a profile's packages.txt - one package per\n"
        printf "# line, reverse-mapped through _GLB_PACKAGE_OVERRIDES back to\n"
        printf "# GLB's canonical name where an override exists.\n"
        if [[ "$pkg_mgr" == "zypper" ]]; then
            printf "#\n"
            printf "# NOTE: zypper has no true manual-vs-dependency split, so\n"
            printf "# this also includes base-system/pattern packages (glibc,\n"
            printf "# kernel-default, grub2, ...) that were never a deliberate\n"
            printf "# choice - prune by hand before using this as a real profile.\n"
        fi
    } > "$snapshot_dir/packages.txt"

    while IFS= read -r raw; do
        [[ -z "$raw" ]] && continue
        generic="$(glb_reverse_resolve_package_name "$raw" "$pkg_mgr")"
        printf "%s\n" "$generic"
    done < <(glb_list_installed_packages "$pkg_mgr" | sort -u) >> "$snapshot_dir/packages.txt"
}

# ------------------------------------------------------------
# Copy every dotfile GLB tracks (the union of relative paths under
# every local profile's dotfiles/) that actually exists in $HOME
# right now - not a blind home-directory scrape. Copies real
# content (cp -L), so a file that was hand-edited since the last
# restore is captured as-is, not just the symlink target.
# ------------------------------------------------------------

glb_export_dotfiles() {
    local snapshot_dir="$1"
    local profiles_root="$GLB_ROOT/profiles"
    local dest_dir="$snapshot_dir/dotfiles"
    local f rel src count=0
    declare -A rel_seen

    if [[ ! -d "$profiles_root" ]]; then
        return 0
    fi

    while IFS= read -r -d '' f; do
        rel="${f#*/dotfiles/}"
        rel_seen["$rel"]=1
    done < <(find "$profiles_root" -type f -path '*/dotfiles/*' -not -name '.gitkeep' -print0)

    for rel in "${!rel_seen[@]}"; do
        src="$HOME/$rel"
        [[ -e "$src" ]] || continue

        if ! glb_create_directory "$(dirname "$dest_dir/$rel")"; then
            glb_log_error "Failed to create directory for ~/$rel"
            continue
        fi

        if cp -L "$src" "$dest_dir/$rel"; then
            count=$((count + 1))
        else
            glb_log_error "Failed to export ~/$rel"
        fi
    done

    glb_log_info "Exported $count dotfile(s)"
}

# ------------------------------------------------------------
# Write shell.txt: detected shell, whether Starship is installed,
# and which of GLB's curated zsh plugins are present.
# ------------------------------------------------------------

glb_export_shell() {
    local snapshot_dir="$1"
    local starship_status="not installed"
    local name

    glb_command_exists starship && starship_status="installed"

    {
        printf "shell=%s\n" "$(glb_detect_shell)"
        printf "starship=%s\n" "$starship_status"
        for name in "${!_GLB_ZSH_PLUGINS[@]}"; do
            if [[ -d "$HOME/.local/share/glb/plugins/$name" ]]; then
                printf "zsh_plugin=%s\n" "$name"
            fi
        done
    } > "$snapshot_dir/shell.txt"
}

# ------------------------------------------------------------
# Write metadata.yaml: distro, GLB version, timestamp, hostname.
# ------------------------------------------------------------

glb_export_metadata() {
    local snapshot_dir="$1"

    {
        printf "hostname: %s\n" "$(hostname)"
        printf "distro: %s\n" "$(glb_detect_os 2>/dev/null || printf 'unknown')"
        printf "distro_version: %s\n" "$(glb_detect_version 2>/dev/null || printf 'unknown')"
        printf "package_manager: %s\n" "$(glb_detect_package_manager 2>/dev/null || printf 'unknown')"
        printf "glb_version: %s\n" "$GLB_VERSION"
        printf "captured_at: %s\n" "$(date -Iseconds)"
    } > "$snapshot_dir/metadata.yaml"
}

# ------------------------------------------------------------
# Capture the current machine's state into
# snapshots/<hostname>-<date>/, in the same shape `glb restore`
# already understands (packages.txt + dotfiles/), plus shell.txt
# and metadata.yaml.
# ------------------------------------------------------------

glb_export_snapshot() {
    local hostname snapshot_name snapshot_dir

    hostname="$(hostname)"
    snapshot_name="${hostname}-$(date +%Y-%m-%d)"
    snapshot_dir="$GLB_ROOT/snapshots/$snapshot_name"

    if [[ -d "$snapshot_dir" ]]; then
        glb_log_warn "Snapshot already exists for today, overwriting: $snapshot_name"
    fi

    if ! glb_create_directory "$snapshot_dir/dotfiles"; then
        glb_log_error "Failed to create snapshot directory: $snapshot_dir"
        return 1
    fi

    glb_export_metadata "$snapshot_dir"
    glb_export_packages "$snapshot_dir" || return 1
    glb_export_dotfiles "$snapshot_dir"
    glb_export_shell "$snapshot_dir"

    glb_log_success "Exported snapshot: snapshots/$snapshot_name"
}
