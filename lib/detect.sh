#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: detect.sh
# Purpose: Detect system information.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Load operating system information
# ------------------------------------------------------------

_glb_load_os_release() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        return 0
    fi

    return 1
}

# ------------------------------------------------------------
# Detect operating system ID
# ------------------------------------------------------------

glb_detect_os() {
    _glb_load_os_release || return 1
    printf "%s\n" "$ID"
}

# ------------------------------------------------------------
# Detect operating system version
# ------------------------------------------------------------

glb_detect_version() {
    _glb_load_os_release || return 1
    printf "%s\n" "$VERSION_ID"
}

# ------------------------------------------------------------
# Detect available package manager
# ------------------------------------------------------------

glb_detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        printf "apt\n"
    elif command -v dnf >/dev/null 2>&1; then
        printf "dnf\n"
    elif command -v pacman >/dev/null 2>&1; then
        printf "pacman\n"
    elif command -v zypper >/dev/null 2>&1; then
        printf "zypper\n"
    else
        return 1
    fi
}

# ------------------------------------------------------------
# Detect user's shell
# ------------------------------------------------------------

glb_detect_shell() {
    printf "%s\n" "$SHELL"
}
