#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: package.sh
# Purpose: Package management abstraction layer.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi
# ------------------------------------------------------------
# Public API
# ------------------------------------------------------------

# ------------------------------------------------------------
# Per-distro package name overrides
#
# Most packages share the same name across package managers, but a
# few don't (e.g. Debian/Ubuntu ships "fd-find" instead of "fd").
# This table maps "<generic-name>:<package-manager>" to the name
# that manager actually uses. Anything with no entry here is passed
# through unchanged.
# ------------------------------------------------------------

declare -gA _GLB_PACKAGE_OVERRIDES=(
    [fd:apt]="fd-find"
    [firefox:zypper]="MozillaFirefox"
    [libreoffice:pacman]="libreoffice-fresh"
    [gh:pacman]="github-cli"
)

# ------------------------------------------------------------
# Resolve a generic package name to the name a given package
# manager expects, applying _GLB_PACKAGE_OVERRIDES if present.
# ------------------------------------------------------------

glb_resolve_package_name() {
    local package="$1"
    local pkg_mgr="$2"
    local key="${package}:${pkg_mgr}"

    printf "%s\n" "${_GLB_PACKAGE_OVERRIDES[$key]:-$package}"
}

# ------------------------------------------------------------
# Reverse of glb_resolve_package_name: given a distro-specific
# package name and package manager, find the generic name it came
# from (if any override maps to it). Used by `glb export` to write
# packages.txt entries in GLB's canonical names rather than raw
# distro-specific ones.
# ------------------------------------------------------------

glb_reverse_resolve_package_name() {
    local resolved="$1"
    local pkg_mgr="$2"
    local key

    for key in "${!_GLB_PACKAGE_OVERRIDES[@]}"; do
        if [[ "$key" == *":$pkg_mgr" && "${_GLB_PACKAGE_OVERRIDES[$key]}" == "$resolved" ]]; then
            printf "%s\n" "${key%%:*}"
            return 0
        fi
    done

    printf "%s\n" "$resolved"
}

# ------------------------------------------------------------
# List packages explicitly installed by the user (not pulled in as
# a dependency of something else), in each package manager's own
# distro-specific names. Used by `glb export`.
#
# zypper has no first-class "manual vs automatic" query like the
# other three; it tracks this internally in
# /var/lib/zypp/AutoInstalled (a plain list of dependency-installed
# package names libzypp maintains for its own `zypper info`
# "Installed: Yes (automatically)" reporting) - manual is everything
# installed minus that list. Note this still includes base-system/
# pattern packages (e.g. glibc, kernel-default, grub2) that were
# "manually" installed as part of the OS install itself, not
# something the user consciously chose - a real limitation callers
# should account for (see the comment glb_export_packages writes
# into packages.txt).
# ------------------------------------------------------------

glb_list_installed_packages() {
    local pkg_mgr="$1"

    case "$pkg_mgr" in
        apt)
            apt-mark showmanual
            ;;
        dnf)
            dnf repoquery --userinstalled --qf '%{name}' 2>/dev/null
            ;;
        pacman)
            pacman -Qqe
            ;;
        zypper)
            comm -23 \
                <(rpm -qa --qf '%{NAME}\n' | sort -u) \
                <(grep -v '^#' /var/lib/zypp/AutoInstalled 2>/dev/null | sort -u)
            ;;
        *)
            glb_log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Pause and let the user complete a failed step manually, then
# continue. Used when a command GLB ran (e.g. a sudo-gated install)
# fails and retrying automatically wouldn't help - most commonly a
# sudo password prompt GLB can't satisfy non-interactively.
#
# Reads a line from stdin: empty/anything else means "done, continue",
# a leading s/S means "skip". If stdin has no input to give (already
# at EOF - GLB invoked non-interactively with nothing piped in),
# doesn't hang: treats that the same as skipping.
# ------------------------------------------------------------

glb_prompt_manual_step() {
    local cmd="$1"
    local description="${2:-this step}"
    local reply

    glb_log_warn "Could not $description automatically."
    printf "\n  Run this yourself, then come back here:\n\n"
    printf "    %s\n\n" "$cmd"

    if ! read -r -p "  Press Enter once it's done (or type 's' to skip): " reply; then
        glb_log_warn "No input available; skipping: $description"
        return 1
    fi

    if [[ "$reply" =~ ^[sS] ]]; then
        glb_log_warn "Skipped: $description"
        return 1
    fi

    return 0
}

# ------------------------------------------------------------
# Install package
# ------------------------------------------------------------

glb_install_package() {
    local package="$1"
    local pkg_mgr
    local resolved
    local cmd

    if [[ -z "$package" ]]; then
        glb_log_error "No package specified."
        return 1
    fi

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    resolved="$(glb_resolve_package_name "$package" "$pkg_mgr")"

    if [[ "$resolved" != "$package" ]]; then
        glb_log_info "Installing package: $package (as $resolved)"
    else
        glb_log_info "Installing package: $package"
    fi

    case "$pkg_mgr" in
        apt)
            cmd=(apt install -y "$resolved")
            ;;
        dnf)
            cmd=(dnf install -y "$resolved")
            ;;
        pacman)
            cmd=(pacman -S --noconfirm "$resolved")
            ;;
        zypper)
            cmd=(zypper install -y "$resolved")
            ;;
        *)
            glb_log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac

    if glb_sudo "${cmd[@]}"; then
        return 0
    fi

    if ! glb_prompt_manual_step "sudo ${cmd[*]}" "install $package"; then
        return 1
    fi

    if glb_package_installed "$package" 2>/dev/null; then
        glb_log_success "Confirmed installed after manual step: $package"
        return 0
    fi

    glb_log_warn "Still not detected as installed: $package"
    return 1
}

# ------------------------------------------------------------
# Remove package
# ------------------------------------------------------------

glb_remove_package() {
    local package="$1"
    local pkg_mgr
    local resolved

    if [[ -z "$package" ]]; then
        glb_log_error "No package specified."
        return 1
    fi

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    resolved="$(glb_resolve_package_name "$package" "$pkg_mgr")"

    if [[ "$resolved" != "$package" ]]; then
        glb_log_info "Removing package: $package (as $resolved)"
    else
        glb_log_info "Removing package: $package"
    fi

    case "$pkg_mgr" in
        apt)
            glb_sudo apt remove -y "$resolved"
            ;;
        dnf)
            glb_sudo dnf remove -y "$resolved"
            ;;
        pacman)
            glb_sudo pacman -R --noconfirm "$resolved"
            ;;
        zypper)
            glb_sudo zypper remove -y "$resolved"
            ;;
        *)
            glb_log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Update packages
# ------------------------------------------------------------

glb_update_packages() {
    local pkg_mgr

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    glb_log_info "Updating system packages..."

    case "$pkg_mgr" in
        apt)
            glb_sudo apt update && glb_sudo apt upgrade -y
            ;;
        dnf)
            glb_sudo dnf upgrade -y
            ;;
        pacman)
            glb_sudo pacman -Syu --noconfirm
            ;;
        zypper)
            glb_sudo zypper refresh && glb_sudo zypper update -y
            ;;
        *)
            glb_log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Check if package is installed
# ------------------------------------------------------------

glb_package_installed() {
    local package="$1"
    local pkg_mgr
    local resolved

    if [[ -z "$package" ]]; then
        glb_log_error "No package specified."
        return 1
    fi

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    resolved="$(glb_resolve_package_name "$package" "$pkg_mgr")"

    case "$pkg_mgr" in
        apt)
            dpkg -s "$resolved" >/dev/null 2>&1
            ;;
        dnf)
            rpm -q "$resolved" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "$resolved" >/dev/null 2>&1
            ;;
        zypper)
            rpm -q "$resolved" >/dev/null 2>&1
            ;;
        *)
            glb_log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac
}

