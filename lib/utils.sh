#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: utils.sh
# Purpose: Provide reusable helper functions.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Check whether a command exists
# ------------------------------------------------------------

glb_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------
# Check whether a file exists
# ------------------------------------------------------------

glb_file_exists() {
    [[ -f "$1" ]]
}

# ------------------------------------------------------------
# Check whether a directory exists
# ------------------------------------------------------------

glb_directory_exists() {
    [[ -d "$1" ]]
}

# ------------------------------------------------------------
# Create a directory if needed
# ------------------------------------------------------------

glb_create_directory() {
    local directory="$1"

    if [[ -d "$directory" ]]; then
        return 0
    fi

    mkdir -p "$directory"
}

# ------------------------------------------------------------
# Check if running as root
# ------------------------------------------------------------

glb_is_root() {
    [[ "$EUID" -eq 0 ]]
}

# ------------------------------------------------------------
# Run a command with sudo, using -n (non-interactive) whenever
# there's no real TTY to prompt through. A plain `sudo` call with
# no TTY still triggers a real pam_unix auth-failure attempt on
# every invocation, which counts against pam_faillock's deny
# counter on distros that enable it - confirmed to lock a user out
# after 3 sudo-gated steps on Arch-based systems (CachyOS,
# EndeavourOS - see CLAUDE.md), purely as a side effect of GLB's
# own designed-to-fail-cleanly sudo attempts. `-n` fails
# immediately instead, without that auth conversation. When a real
# TTY *is* available (someone running glb directly in their own
# terminal), use plain sudo so the normal interactive password
# prompt keeps working exactly as before.
# ------------------------------------------------------------

glb_sudo() {
    if [[ -t 0 ]]; then
        sudo "$@"
    else
        sudo -n "$@"
    fi
}
