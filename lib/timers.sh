#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: timers.sh
# Purpose: Enable the user systemd timers a profile lists in
#          timers.txt, once its dotfiles (which ship the unit
#          files) are linked.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Enable one user timer. Returns non-zero (after warning, with the
# exact command to run by hand) when it can't - no systemd, no
# reachable user session (ssh without a session bus, a chroot, a
# container), or the unit file isn't in place.
# ------------------------------------------------------------

_glb_enable_user_timer() {
    local unit="$1"
    local manual="systemctl --user enable --now $unit"

    if ! command -v systemctl >/dev/null 2>&1; then
        glb_log_warn "Not enabling $unit: systemctl not found."
        return 1
    fi

    if ! systemctl --user show-environment >/dev/null 2>&1; then
        glb_log_warn "Not enabling $unit: no systemd user session reachable here. Once logged in on the desktop, run: $manual"
        return 1
    fi

    if [[ ! -e "$HOME/.config/systemd/user/$unit" ]]; then
        glb_log_warn "Not enabling $unit: ~/.config/systemd/user/$unit isn't there (dotfiles step failed or was undone). Run: $manual"
        return 1
    fi

    if systemctl --user is-enabled --quiet "$unit" 2>/dev/null; then
        glb_log_info "Already enabled: $unit"
        return 0
    fi

    if systemctl --user daemon-reload && systemctl --user enable --now "$unit" >/dev/null 2>&1; then
        glb_log_success "Enabled timer: $unit"
        return 0
    fi

    glb_log_warn "Could not enable $unit. Run: $manual"
    return 1
}

# ------------------------------------------------------------
# Enable every timer listed in a profile's timers.txt.
#
# A timer that can't be enabled is a warning, not a failed restore:
# no reachable user session is an ordinary situation for a bootstrap
# tool (a restore over ssh), and the warning prints the exact command
# to run later, same spirit as the sudo-gated manual step.
# ------------------------------------------------------------

glb_apply_profile_timers() {
    local profile_dir="$1"
    local dry_run="${2:-}"
    local timers_file="$profile_dir/timers.txt"
    local line unit want current

    if [[ ! -f "$timers_file" ]]; then
        return 0
    fi

    current="$(glb_detect_package_manager 2>/dev/null)" || current=""

    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"

        [[ -z "$line" ]] && continue

        read -r unit want <<< "$line"

        if [[ -n "$want" && "$want" != "$current" ]]; then
            glb_log_info "Skipping timer $unit: only enabled on $want (this machine: ${current:-unknown})"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_info "Would enable timer: $unit"
            continue
        fi

        _glb_enable_user_timer "$unit" || true
    done 3< "$timers_file"

    return 0
}
