#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: selfcheck.sh
# Purpose: Say so when this copy of GLB is behind its remote.
#          `glb update` updates the system's packages, never GLB
#          itself, so an old copy keeps running old code - and
#          keeps hitting problems that are already fixed - until
#          someone pulls it.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# How many commits this copy is behind, set by glb_check_self_update.
_GLB_SELF_BEHIND=0

# ------------------------------------------------------------
# Print how many commits this copy of GLB is behind its remote
# branch. Prints nothing and returns non-zero whenever that can't be
# worked out: GLB isn't a git checkout (a tarball or a plain copy), no
# git, no upstream branch, or the remote can't be reached. Never
# prompts - a remote that wants a password or a passphrase counts as
# unreachable.
# ------------------------------------------------------------

_glb_self_commits_behind() {
    local behind
    local -a fetch=(git -C "$GLB_ROOT" fetch --quiet)

    [[ -e "$GLB_ROOT/.git" ]] || return 1
    command -v git >/dev/null 2>&1 || return 1
    git -C "$GLB_ROOT" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1 || return 1

    if command -v timeout >/dev/null 2>&1; then
        fetch=(timeout "${GLB_SELF_CHECK_TIMEOUT:-10}" "${fetch[@]}")
    fi
    GIT_TERMINAL_PROMPT=0 \
        GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes}" \
        "${fetch[@]}" </dev/null >/dev/null 2>&1 || return 1

    behind="$(git -C "$GLB_ROOT" rev-list --count 'HEAD..@{u}' 2>/dev/null)" || return 1
    [[ "$behind" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$behind"
}

# ------------------------------------------------------------
# Warn, with the exact command to run, when this copy of GLB is
# behind its remote. A notice only: it never updates GLB and never
# stops the command. Silent when the copy is up to date or the check
# can't be made. GLB_NO_SELF_CHECK=1 turns it off.
# ------------------------------------------------------------

glb_check_self_update() {
    local behind

    [[ "${GLB_NO_SELF_CHECK:-0}" == "1" ]] && return 0

    behind="$(_glb_self_commits_behind)" || return 0
    [[ "$behind" -gt 0 ]] || return 0

    _GLB_SELF_BEHIND="$behind"
    glb_log_warn "This copy of GLB is $behind commit(s) behind its remote; newer fixes are not in it."
    glb_log_warn "To update it:  git -C $GLB_ROOT pull --ff-only"
    printf "\n"
}

# ------------------------------------------------------------
# Meant for an EXIT trap: when the command failed and this copy of
# GLB is behind, repeat the notice as the last thing on screen - the
# first one has scrolled away by then, and a failure on an old copy
# may already be fixed.
# ------------------------------------------------------------

glb_self_update_reminder() {
    local status="$1"

    [[ "$status" -ne 0 && "$_GLB_SELF_BEHIND" -gt 0 ]] || return 0

    printf "\n"
    glb_log_warn "This copy of GLB is $_GLB_SELF_BEHIND commit(s) behind its remote; this problem may already be fixed."
    glb_log_warn "Update it, then run the command again:  git -C $GLB_ROOT pull --ff-only"
}
