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
# Detect whether this is Windows Subsystem for Linux
#
# Both WSL1 and WSL2 kernels report "microsoft"/"Microsoft" in
# /proc/version; no real Linux install does. The path is overridable
# (_GLB_PROC_VERSION) so the test suite gives the same answer whether
# or not it's itself running under WSL - see tests/test_helper.bash.
# ------------------------------------------------------------

glb_is_wsl() {
    local version_file="${_GLB_PROC_VERSION:-/proc/version}"

    [[ -r "$version_file" ]] && grep -qi microsoft "$version_file"
}

# ------------------------------------------------------------
# Detect user's shell
# ------------------------------------------------------------

glb_detect_shell() {
    printf "%s\n" "$SHELL"
}
