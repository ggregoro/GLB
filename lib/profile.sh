#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: profile.sh
# Purpose: Apply a profile (packages + dotfiles) to a fresh install.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Internal helper: resolve a profile's directory
# ------------------------------------------------------------

_glb_profile_dir() {
    printf "%s/profiles/%s\n" "$GLB_ROOT" "$1"
}

# ------------------------------------------------------------
# Install every package listed in a profile's packages.txt
# ------------------------------------------------------------

glb_apply_profile_packages() {
    local profile_dir="$1"
    local dry_run="${2:-}"
    local packages_file="$profile_dir/packages.txt"
    local line package
    local failed=()

    if [[ ! -f "$packages_file" ]]; then
        glb_log_warn "No packages.txt found, skipping packages."
        return 0
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        package="${line%%#*}"
        package="$(echo "$package" | xargs)"

        [[ -z "$package" ]] && continue

        if glb_package_installed "$package" 2>/dev/null; then
            glb_log_info "Already installed: $package"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_info "Would install: $package"
            continue
        fi

        if ! glb_install_package "$package"; then
            glb_log_error "Failed to install: $package"
            failed+=("$package")
        fi
    done < "$packages_file"

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to install ${#failed[@]} package(s): ${failed[*]}"
        return 1
    fi
}

# ------------------------------------------------------------
# Symlink every file under a profile's dotfiles/ into $HOME,
# backing up anything already there.
# ------------------------------------------------------------

glb_apply_profile_dotfiles() {
    local profile_dir="$1"
    local dry_run="${2:-}"
    local dotfiles_dir="$profile_dir/dotfiles"
    local src rel dest
    local failed=()

    if [[ ! -d "$dotfiles_dir" ]]; then
        glb_log_warn "No dotfiles directory found, skipping dotfiles."
        return 0
    fi

    while IFS= read -r -d '' src; do
        rel="${src#"$dotfiles_dir"/}"
        dest="$HOME/$rel"

        if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            glb_log_info "Already linked: ~/$rel"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            if [[ -e "$dest" || -L "$dest" ]]; then
                glb_log_info "Would back up ~/$rel -> ~/$rel.glb-backup, then link"
            else
                glb_log_info "Would link ~/$rel"
            fi
            continue
        fi

        if ! glb_create_directory "$(dirname "$dest")"; then
            glb_log_error "Failed to create directory for ~/$rel"
            failed+=("$rel")
            continue
        fi

        if [[ -e "$dest" || -L "$dest" ]]; then
            glb_log_warn "Backing up existing ~/$rel -> ~/$rel.glb-backup"
            if ! mv "$dest" "$dest.glb-backup"; then
                glb_log_error "Failed to back up ~/$rel"
                failed+=("$rel")
                continue
            fi
        fi

        if ln -s "$src" "$dest"; then
            glb_log_success "Linked ~/$rel"
        else
            glb_log_error "Failed to link ~/$rel"
            failed+=("$rel")
        fi
    done < <(find "$dotfiles_dir" -type f -not -name '.gitkeep' -print0)

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to link ${#failed[@]} file(s): ${failed[*]}"
        return 1
    fi
}

# ------------------------------------------------------------
# Undo a restore: walk $HOME for *.glb-backup files left behind by
# glb_apply_profile_dotfiles and swap each one back into place.
# ------------------------------------------------------------

glb_undo_restore() {
    local backup dest rel
    local restored=0
    local skipped=0
    local failed=()

    while IFS= read -r -d '' backup; do
        dest="${backup%.glb-backup}"
        rel="${dest#"$HOME"/}"

        if [[ -e "$dest" || -L "$dest" ]]; then
            if [[ ! -L "$dest" ]]; then
                glb_log_warn "Skipping ~/$rel: not a symlink, may have changed since restore"
                skipped=$((skipped + 1))
                continue
            fi

            if ! rm "$dest"; then
                glb_log_error "Failed to remove ~/$rel"
                failed+=("$rel")
                continue
            fi
        fi

        if mv "$backup" "$dest"; then
            glb_log_success "Restored ~/$rel"
            restored=$((restored + 1))
        else
            glb_log_error "Failed to restore ~/$rel"
            failed+=("$rel")
        fi
    done < <(find "$HOME" -name '*.glb-backup' -print0)

    if [[ "$restored" -eq 0 && "$skipped" -eq 0 && ${#failed[@]} -eq 0 ]]; then
        glb_log_info "No .glb-backup files found, nothing to undo."
        return 0
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Undo finished with errors: restored $restored, skipped $skipped, failed ${#failed[@]} (${failed[*]})"
        return 1
    fi

    if [[ "$skipped" -gt 0 ]]; then
        glb_log_success "Undo complete: restored $restored file(s), skipped $skipped"
    else
        glb_log_success "Undo complete: restored $restored file(s)"
    fi
}

# ------------------------------------------------------------
# Apply a named profile: packages, then dotfiles
# ------------------------------------------------------------

glb_apply_profile() {
    local name="${1:-default}"
    local dry_run="${2:-}"
    local profile_dir
    local status=0
    profile_dir="$(_glb_profile_dir "$name")"

    if [[ ! -d "$profile_dir" ]]; then
        glb_log_error "Profile not found: $name"
        return 1
    fi

    if [[ "$dry_run" == "--dry-run" ]]; then
        glb_log_info "Dry run for profile: $name (nothing will be installed or changed)"
    else
        glb_log_info "Applying profile: $name"
    fi

    glb_apply_profile_packages "$profile_dir" "$dry_run" || status=1
    glb_apply_profile_extras "$profile_dir" "$dry_run" || status=1
    glb_install_starship "$dry_run" || status=1
    glb_install_zsh_plugins "$dry_run" || status=1
    glb_apply_profile_dotfiles "$profile_dir" "$dry_run" || status=1

    if [[ "$status" -eq 0 ]]; then
        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_success "Dry run complete: $name"
        else
            glb_log_success "Profile applied: $name"
        fi
    else
        glb_log_error "Profile applied with errors: $name"
    fi

    return "$status"
}

# ------------------------------------------------------------
# List available profiles
# ------------------------------------------------------------

glb_list_profiles() {
    local profiles_root="$GLB_ROOT/profiles"
    local dir

    if [[ ! -d "$profiles_root" ]]; then
        glb_log_warn "No profiles directory found."
        return 0
    fi

    printf "\n"
    printf "Available Profiles\n"
    printf -- "-------------------\n"
    for dir in "$profiles_root"/*/; do
        [[ -d "$dir" ]] || continue
        printf "  %s\n" "$(basename "$dir")"
    done
    printf "\n"
}
