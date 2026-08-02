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
