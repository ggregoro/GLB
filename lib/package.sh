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
# Install package
# ------------------------------------------------------------

glb_install_package() {
    local package="$1"
    local pkg_mgr

    if [[ -z "$package" ]]; then
        glb_log_error "No package specified."
        return 1
    fi

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    glb_log_info "Installing package: $package"

    case "$pkg_mgr" in
        apt)
            sudo apt install -y "$package"
            ;;
        dnf)
            sudo dnf install -y "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        zypper)
            sudo zypper install -y "$package"
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

    if [[ -z "$package" ]]; then
        glb_log_error "No package specified."
        return 1
    fi

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    glb_log_info "Removing package: $package"

    case "$pkg_mgr" in
        apt)
            sudo apt remove -y "$package"
            ;;
        dnf)
            sudo dnf remove -y "$package"
            ;;
        pacman)
            sudo pacman -R --noconfirm "$package"
            ;;
        zypper)
            sudo zypper remove -y "$package"
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

    if [[ -z "$package" ]]; then
        glb_log_error "No package specified."
        return 1
    fi

    pkg_mgr="$(glb_detect_package_manager)" || {
        glb_log_error "Unable to detect package manager."
        return 1
    }

    case "$pkg_mgr" in
        apt)
            dpkg -s "$package" >/dev/null 2>&1
            ;;
        dnf)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        zypper)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        *)
            glb_log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac
}

