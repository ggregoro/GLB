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

declare -A _GLB_PACKAGE_OVERRIDES=(
    [fd:apt]="fd-find"
    [firefox:zypper]="MozillaFirefox"
    [libreoffice:pacman]="libreoffice-fresh"
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
# Install package
# ------------------------------------------------------------

glb_install_package() {
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
        glb_log_info "Installing package: $package (as $resolved)"
    else
        glb_log_info "Installing package: $package"
    fi

    case "$pkg_mgr" in
        apt)
            sudo apt install -y "$resolved"
            ;;
        dnf)
            sudo dnf install -y "$resolved"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$resolved"
            ;;
        zypper)
            sudo zypper install -y "$resolved"
            ;;
        *)
            glb_log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac
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
            sudo apt remove -y "$resolved"
            ;;
        dnf)
            sudo dnf remove -y "$resolved"
            ;;
        pacman)
            sudo pacman -R --noconfirm "$resolved"
            ;;
        zypper)
            sudo zypper remove -y "$resolved"
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
            sudo apt update && sudo apt upgrade -y
            ;;
        dnf)
            sudo dnf upgrade -y
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
        zypper)
            sudo zypper refresh && sudo zypper update -y
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

