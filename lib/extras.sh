#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: extras.sh
# Purpose: Install software that doesn't fit the plain
#          apt/dnf/pacman/zypper packages.txt model - curl-install
#          scripts, Flatpak apps, and Snap packages - driven by a
#          profile's extras.txt.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Check whether an extra is already installed
# ------------------------------------------------------------

glb_extra_installed() {
    local method="$1"
    local name="$2"
    local spec="$3"

    case "$method" in
        curl)
            glb_command_exists "$name"
            ;;
        flatpak)
            flatpak info "$spec" >/dev/null 2>&1
            ;;
        font)
            compgen -G "$HOME/.local/share/fonts/$name/*.[ot]tf" >/dev/null
            ;;
        snap)
            snap list "$name" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Internal helper: pause for a failed extra's manual step, then
# recheck whether it's installed
# ------------------------------------------------------------

_glb_extras_prompt_and_recheck() {
    local method="$1"
    local name="$2"
    local spec="$3"
    local cmd_display="$4"

    if ! glb_prompt_manual_step "$cmd_display" "install $name"; then
        return 1
    fi

    if glb_extra_installed "$method" "$name" "$spec"; then
        glb_log_success "Confirmed installed after manual step: $name"
        return 0
    fi

    glb_log_warn "Still not detected as installed: $name"
    return 1
}

# ------------------------------------------------------------
# Install a single extra
# ------------------------------------------------------------

glb_install_extra() {
    local method="$1"
    local name="$2"
    local spec="$3"
    local pipe_status

    case "$method" in
        curl)
            glb_log_info "Installing $name via curl-install script"
            curl -fsSL "$spec" | bash
            # PIPESTATUS is clobbered by the very next simple command
            # (even a plain assignment), so capture the whole array in
            # one shot rather than reading two separate indices.
            pipe_status=("${PIPESTATUS[@]}")

            if [[ "${pipe_status[0]}" -eq 0 && "${pipe_status[1]}" -eq 0 ]]; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" "curl -fsSL $spec | bash"
            ;;
        flatpak)
            glb_log_info "Installing $name via Flatpak ($spec)"
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1

            if flatpak install -y flathub "$spec"; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" "flatpak install -y flathub $spec"
            ;;
        font)
            glb_log_info "Installing font: $name"
            local font_dir="$HOME/.local/share/fonts/$name"
            local tmp_zip
            tmp_zip="$(mktemp --suffix=.zip)"

            if curl -fsSL "$spec" -o "$tmp_zip" && glb_create_directory "$font_dir" \
                && unzip -o -q "$tmp_zip" -d "$font_dir"; then
                rm -f "$tmp_zip"
                glb_command_exists fc-cache && fc-cache -f "$font_dir" >/dev/null 2>&1
                return 0
            fi

            rm -f "$tmp_zip"
            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" \
                "curl -fsSL $spec -o font.zip && mkdir -p $font_dir && unzip -o font.zip -d $font_dir && fc-cache -f $font_dir"
            ;;
        snap)
            glb_log_info "Installing $name via snap${spec:+ (--$spec)}"

            if glb_sudo snap install "$name" ${spec:+--$spec}; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" \
                "sudo snap install $name${spec:+ --$spec}"
            ;;
        *)
            glb_log_error "Unknown extras method: $method"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Re-run a single already-installed extra's install step, to pick
# up whatever's current. Distinct per method from glb_install_extra:
# flatpak uses the native "update" verb rather than "install", and
# neither curl nor font need the not-yet-installed framing (no
# manual-step pause on failure - matches glb update's existing
# unprompted style, this isn't the first install attempt).
# ------------------------------------------------------------

_glb_update_extra() {
    local method="$1"
    local name="$2"
    local spec="$3"
    local pipe_status

    case "$method" in
        curl)
            glb_log_info "Updating $name via curl-install script"
            curl -fsSL "$spec" | bash
            # See glb_install_extra's curl case for why PIPESTATUS is
            # captured as a whole array rather than read index by index.
            pipe_status=("${PIPESTATUS[@]}")
            [[ "${pipe_status[0]}" -eq 0 && "${pipe_status[1]}" -eq 0 ]]
            ;;
        flatpak)
            glb_log_info "Updating $name via Flatpak ($spec)"
            flatpak update -y "$spec"
            ;;
        font)
            glb_log_info "Updating font: $name"
            local font_dir="$HOME/.local/share/fonts/$name"
            local tmp_zip
            tmp_zip="$(mktemp --suffix=.zip)"

            if curl -fsSL "$spec" -o "$tmp_zip" && unzip -o -q "$tmp_zip" -d "$font_dir"; then
                rm -f "$tmp_zip"
                glb_command_exists fc-cache && fc-cache -f "$font_dir" >/dev/null 2>&1
                return 0
            fi

            rm -f "$tmp_zip"
            return 1
            ;;
        snap)
            glb_log_info "Updating $name via snap"
            glb_sudo snap refresh "$name"
            ;;
        *)
            glb_log_error "Unknown extras method: $method"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Re-run every currently-installed extra in a profile's extras.txt,
# to pick up updates. Extras that were never installed in the first
# place are silently skipped - nothing to key an update against.
# ------------------------------------------------------------

glb_update_profile_extras() {
    local profile_dir="$1"
    local extras_file="$profile_dir/extras.txt"
    local line method name spec
    local failed=()

    if [[ ! -f "$extras_file" ]]; then
        return 0
    fi

    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"

        [[ -z "$line" ]] && continue

        read -r method name spec <<< "$line"

        if ! glb_extra_installed "$method" "$name" "$spec"; then
            continue
        fi

        if ! _glb_update_extra "$method" "$name" "$spec"; then
            glb_log_error "Failed to update: $name"
            failed+=("$name")
        fi
    done 3< "$extras_file"

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to update ${#failed[@]} extra(s): ${failed[*]}"
        return 1
    fi
}

# ------------------------------------------------------------
# Install every extra listed in a profile's extras.txt
# ------------------------------------------------------------

glb_apply_profile_extras() {
    local profile_dir="$1"
    local dry_run="${2:-}"
    local extras_file="$profile_dir/extras.txt"
    local line method name spec
    local failed=()

    if [[ ! -f "$extras_file" ]]; then
        return 0
    fi

    # Read extras_file on fd 3, not stdin (fd 0) - same reasoning as
    # glb_apply_profile_packages in lib/profile.sh: glb_install_extra can
    # fall through to glb_prompt_manual_step's interactive `read -p`,
    # which needs real stdin free rather than the next extras_file line.
    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"

        [[ -z "$line" ]] && continue

        read -r method name spec <<< "$line"

        if glb_extra_installed "$method" "$name" "$spec"; then
            glb_log_info "Already installed: $name"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_info "Would install: $name (via $method)"
            continue
        fi

        if ! glb_install_extra "$method" "$name" "$spec"; then
            glb_log_error "Failed to install: $name"
            failed+=("$name")
        fi
    done 3< "$extras_file"

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to install ${#failed[@]} extra(s): ${failed[*]}"
        return 1
    fi
}
