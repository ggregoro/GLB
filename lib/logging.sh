#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: logging.sh
# Purpose: Provide consistent GLB logging functions.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Internal helper: determine if colors are supported
# ------------------------------------------------------------

_glb_color_enabled() {
    [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]
}

# ------------------------------------------------------------
# Internal helper: apply color
# ------------------------------------------------------------

_glb_color() {
    local color="$1"
    shift

    if _glb_color_enabled; then
        printf "\033[%sm%s\033[0m" "$color" "$*"
    else
        printf "%s" "$*"
    fi
}

# ------------------------------------------------------------
# Internal helper: standard log formatter
# ------------------------------------------------------------

_glb_log() {
    local level="$1"
    local color="$2"
    shift 2

    local message="$*"

    if [[ -n "$color" ]]; then
        printf "[%s] %s\n" \
            "$level" \
            "$(_glb_color "$color" "$message")"
    else
        printf "[%s] %s\n" "$level" "$message"
    fi
}

# ------------------------------------------------------------
# Public logging functions
# ------------------------------------------------------------

glb_log_info() {
    _glb_log "INFO" "" "$*"
}

glb_log_success() {
    _glb_log "SUCCESS" "32" "$*"
}

glb_log_warn() {
    _glb_log "WARNING" "33" "$*"
}

glb_log_error() {
    _glb_log "ERROR" "31" "$*"
}

glb_log_debug() {
    if [[ "${GLB_DEBUG:-0}" == "1" ]]; then
        _glb_log "DEBUG" "36" "$*"
    fi
}
