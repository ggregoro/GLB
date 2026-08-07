#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: repair.sh
# Purpose: Check whether the current machine still matches a
#          profile, and offer to fix it if not. Built entirely from
#          existing pieces - an ephemeral export (lib/export.sh)
#          diffed against the profile (lib/diff.sh's internals),
#          with a confirm-and-restore step if drift is found. No new
#          detection mechanism. See docs/design/repair.md.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# glb repair <profile>: ephemeral export + diff against a profile,
# then offer to re-run `glb restore` if any drift is found. Nothing
# is written to snapshots/ - the export lives only in a temp
# directory for the duration of the check and is always removed
# afterward.
# ------------------------------------------------------------

glb_repair() {
    local name="$1"
    local profile_dir
    local tmp_dir
    local pkg_status=0
    local dot_status=0
    local confirm

    if [[ -z "$name" ]]; then
        glb_log_error "Usage: glb repair <profile>"
        return 1
    fi

    profile_dir="$(_glb_profile_dir "$name")"
    if [[ ! -d "$profile_dir" ]]; then
        glb_log_error "Profile not found: $name"
        return 1
    fi

    tmp_dir="$(mktemp -d)"
    glb_create_directory "$tmp_dir/dotfiles"

    glb_export_packages "$tmp_dir"
    glb_export_dotfiles "$tmp_dir"

    printf "\n"
    printf "Checking profile: %s\n" "$name"
    printf -- "-------------------------------\n"
    printf "\nPackages:\n"
    _glb_diff_packages "$tmp_dir" "current state" "$profile_dir" "$name" || pkg_status=1
    printf "\nDotfiles:\n"
    _glb_diff_dotfiles "$tmp_dir" "current state" "$profile_dir" "$name" || dot_status=1
    printf "\n"

    rm -rf "$tmp_dir"

    if [[ "$pkg_status" -eq 0 && "$dot_status" -eq 0 ]]; then
        glb_log_success "No differences found: $name is healthy."
        return 0
    fi

    if ! read -r -p "Re-run 'glb restore $name' now to fix this? [Y/n] " confirm; then
        glb_log_warn "No input available; not repairing."
        return 1
    fi

    if [[ "$confirm" =~ ^[nN] ]]; then
        glb_log_warn "Cancelled; nothing changed."
        return 1
    fi

    glb_apply_profile "$name" ""
}
