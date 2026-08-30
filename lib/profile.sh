#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: profile.sh
# Purpose: Apply a profile (packages + dotfiles) to a fresh install.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Internal helper: resolve a profile's directory
# ------------------------------------------------------------

_glb_profile_dir() {
    printf "%s/profiles/%s\n" "$GLB_ROOT" "$1"
}

# ------------------------------------------------------------
# Internal helper: a profile's one-line description, if it has one
# (profiles/<name>/description.txt). Used by glb_restore_interactive's
# picker. Not every profile needs one - falls back to nothing, and the
# picker just shows the bare name in that case.
# ------------------------------------------------------------

_glb_profile_description() {
    local name="$1"
    local desc_file
    desc_file="$(_glb_profile_dir "$name")/description.txt"

    [[ -f "$desc_file" ]] && head -n1 "$desc_file"
}

# ------------------------------------------------------------
# Install every package listed in a profile's packages.txt
# ------------------------------------------------------------

glb_apply_profile_packages() {
    local profile_dir="$1"
    local dry_run="${2:-}"
    local packages_file="$profile_dir/packages.txt"
    local line package
    local failed=()

    if [[ ! -f "$packages_file" ]]; then
        glb_log_warn "No packages.txt found, skipping packages."
        return 0
    fi

    # Read packages_file on fd 3, not stdin (fd 0) - glb_install_package
    # can fall through to glb_prompt_manual_step's interactive `read -p`
    # on a failed install, which needs real stdin free to wait on the
    # user's actual keypress rather than silently consuming the next
    # line of packages_file as if it were the answer.
    local skip_reason
    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
        package="${line%%#*}"
        package="$(echo "$package" | xargs)"

        [[ -z "$package" ]] && continue

        if glb_package_installed "$package" 2>/dev/null; then
            glb_log_info "Already installed: $package"
            continue
        fi

        if skip_reason="$(glb_package_skip_reason "$package")"; then
            glb_log_info "Skipping $package: $skip_reason"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_info "Would install: $package"
            continue
        fi

        if ! glb_install_package "$package"; then
            glb_log_error "Failed to install: $package"
            failed+=("$package")
        fi
    done 3< "$packages_file"

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to install ${#failed[@]} package(s): ${failed[*]}"
        return 1
    fi
}

# ------------------------------------------------------------
# Symlink every file under a profile's dotfiles/ into $HOME,
# backing up anything already there.
# ------------------------------------------------------------

glb_apply_profile_dotfiles() {
    local profile_dir="$1"
    local dry_run="${2:-}"
    local dotfiles_dir="$profile_dir/dotfiles"
    local src rel dest
    local failed=()

    if [[ ! -d "$dotfiles_dir" ]]; then
        glb_log_warn "No dotfiles directory found, skipping dotfiles."
        return 0
    fi

    while IFS= read -r -d '' src; do
        rel="${src#"$dotfiles_dir"/}"
        dest="$HOME/$rel"

        if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            glb_log_info "Already linked: ~/$rel"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            if [[ -e "$dest.glb-backup" || -L "$dest.glb-backup" ]]; then
                if [[ -L "$dest" ]]; then
                    glb_log_info "Would replace ~/$rel's link (existing ~/$rel.glb-backup kept as-is)"
                else
                    glb_log_info "Would refuse to link ~/$rel: ~/$rel.glb-backup already exists"
                fi
            elif [[ -e "$dest" || -L "$dest" ]]; then
                glb_log_info "Would back up ~/$rel -> ~/$rel.glb-backup, then link"
            else
                glb_log_info "Would link ~/$rel"
            fi
            continue
        fi

        if ! glb_create_directory "$(dirname "$dest")"; then
            glb_log_error "Failed to create directory for ~/$rel"
            failed+=("$rel")
            continue
        fi

        if [[ -e "$dest.glb-backup" || -L "$dest.glb-backup" ]]; then
            # A backup from an earlier restore already exists and holds the
            # original pre-GLB data. If $dest is just this profile's previous
            # symlink (the normal case when switching profiles), replace it
            # without touching that backup — overwriting it here would
            # silently destroy the original data it's protecting.
            if [[ -L "$dest" ]]; then
                glb_log_info "~/$rel.glb-backup already exists, keeping it; replacing ~/$rel's previous link"
                if ! rm "$dest"; then
                    glb_log_error "Failed to remove existing ~/$rel"
                    failed+=("$rel")
                    continue
                fi
            else
                glb_log_error "~/$rel.glb-backup already exists and ~/$rel is not a symlink; refusing to overwrite the existing backup. Resolve manually."
                failed+=("$rel")
                continue
            fi
        elif [[ -e "$dest" || -L "$dest" ]]; then
            glb_log_warn "Backing up existing ~/$rel -> ~/$rel.glb-backup"
            if ! mv "$dest" "$dest.glb-backup"; then
                glb_log_error "Failed to back up ~/$rel"
                failed+=("$rel")
                continue
            fi
        fi

        if ln -s "$src" "$dest"; then
            glb_log_success "Linked ~/$rel"
        else
            glb_log_error "Failed to link ~/$rel"
            failed+=("$rel")
        fi
    done < <(find "$dotfiles_dir" -type f -not -name '.gitkeep' -print0)

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to link ${#failed[@]} file(s): ${failed[*]}"
        return 1
    fi
}

# ------------------------------------------------------------
# Undo a restore: walk $HOME for *.glb-backup files left behind by
# glb_apply_profile_dotfiles and swap each one back into place.
# ------------------------------------------------------------

glb_undo_restore() {
    local backup dest rel
    local restored=0
    local skipped=0
    local failed=()

    while IFS= read -r -d '' backup; do
        dest="${backup%.glb-backup}"
        rel="${dest#"$HOME"/}"

        if [[ -e "$dest" || -L "$dest" ]]; then
            if [[ ! -L "$dest" ]]; then
                glb_log_warn "Skipping ~/$rel: not a symlink, may have changed since restore"
                skipped=$((skipped + 1))
                continue
            fi

            if ! rm "$dest"; then
                glb_log_error "Failed to remove ~/$rel"
                failed+=("$rel")
                continue
            fi
        fi

        if mv "$backup" "$dest"; then
            glb_log_success "Restored ~/$rel"
            restored=$((restored + 1))
        else
            glb_log_error "Failed to restore ~/$rel"
            failed+=("$rel")
        fi
    done < <(find "$HOME" -name '*.glb-backup' -print0)

    if [[ "$restored" -eq 0 && "$skipped" -eq 0 && ${#failed[@]} -eq 0 ]]; then
        glb_log_info "No .glb-backup files found, nothing to undo."
        return 0
    fi

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Undo finished with errors: restored $restored, skipped $skipped, failed ${#failed[@]} (${failed[*]})"
        return 1
    fi

    if [[ "$skipped" -gt 0 ]]; then
        glb_log_success "Undo complete: restored $restored file(s), skipped $skipped"
    else
        glb_log_success "Undo complete: restored $restored file(s)"
    fi
}

# ------------------------------------------------------------
# Apply a named profile: packages, then dotfiles
# ------------------------------------------------------------

glb_apply_profile() {
    local name="${1:-default}"
    local dry_run="${2:-}"
    local profile_dir
    local status=0
    profile_dir="$(_glb_profile_dir "$name")"

    if [[ ! -d "$profile_dir" ]]; then
        glb_log_error "Profile not found: $name"
        return 1
    fi

    if [[ "$dry_run" == "--dry-run" ]]; then
        glb_log_info "Dry run for profile: $name (nothing will be installed or changed)"
    else
        glb_log_info "Applying profile: $name"
    fi

    glb_apply_profile_packages "$profile_dir" "$dry_run" || status=1
    glb_apply_profile_extras "$profile_dir" "$dry_run" || status=1
    glb_install_starship "$dry_run" || status=1
    glb_install_zsh_plugins "$dry_run" || status=1
    glb_install_self_symlink "$dry_run" || status=1
    glb_install_completions "$dry_run" || status=1
    glb_apply_profile_dotfiles "$profile_dir" "$dry_run" || status=1

    if [[ "$status" -eq 0 ]]; then
        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_success "Dry run complete: $name"
        else
            glb_log_success "Profile applied: $name"
        fi
    else
        glb_log_error "Profile applied with errors: $name"
    fi

    return "$status"
}

# ------------------------------------------------------------
# Apply an external manifest directory - a profile-shaped directory
# (packages.txt + optional extras.txt/dotfiles/) living anywhere on
# disk, not committed to profiles/. Applies the same way
# glb_apply_profile applies a profile. Used by
# `glb restore --from-manifest <path>`, for a one-off custom install
# without creating a full profile in the repo.
# ------------------------------------------------------------

glb_apply_manifest() {
    local path="$1"
    local dry_run="${2:-}"
    local status=0

    if [[ -z "$path" ]]; then
        glb_log_error "Usage: glb restore --from-manifest <path>"
        return 1
    fi

    if [[ ! -d "$path" ]]; then
        glb_log_error "Manifest directory not found: $path"
        return 1
    fi

    if [[ "$dry_run" == "--dry-run" ]]; then
        glb_log_info "Dry run for manifest: $path (nothing will be installed or changed)"
    else
        glb_log_info "Applying manifest: $path"
    fi

    glb_apply_profile_packages "$path" "$dry_run" || status=1
    glb_apply_profile_extras "$path" "$dry_run" || status=1
    glb_install_starship "$dry_run" || status=1
    glb_install_zsh_plugins "$dry_run" || status=1
    glb_install_self_symlink "$dry_run" || status=1
    glb_install_completions "$dry_run" || status=1
    glb_apply_profile_dotfiles "$path" "$dry_run" || status=1

    if [[ "$status" -eq 0 ]]; then
        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_success "Dry run complete: $path"
        else
            glb_log_success "Manifest applied: $path"
        fi
    else
        glb_log_error "Manifest applied with errors: $path"
    fi

    return "$status"
}

# ------------------------------------------------------------
# Interactively pick a profile (numbered menu, like
# glb_configure_starship in lib/prompt.sh) and apply it. Used by the
# dispatcher when `glb restore` is run with no profile name.
#
# The guided flow (no --dry-run flag given): list profiles with their
# one-line descriptions, then once one is chosen, automatically show a
# --dry-run preview and ask for confirmation before actually applying
# it - someone who runs `glb restore` with no arguments presumably
# wants guidance, not an immediate irreversible change. If --dry-run
# was explicitly requested, skip the confirmation and just preview, as
# before - the caller already said what they want.
# ------------------------------------------------------------

glb_restore_interactive() {
    local dry_run="${1:-}"
    local profiles_root="$GLB_ROOT/profiles"
    local profiles=()
    local dir choice i desc chosen confirm

    if [[ ! -d "$profiles_root" ]]; then
        glb_log_warn "No profiles directory found."
        return 1
    fi

    for dir in "$profiles_root"/*/; do
        [[ -d "$dir" ]] || continue
        profiles+=("$(basename "$dir")")
    done

    if [[ ${#profiles[@]} -eq 0 ]]; then
        glb_log_warn "No profiles found."
        return 1
    fi

    printf "\n"
    printf "Choose a profile to restore:\n"
    for i in "${!profiles[@]}"; do
        desc="$(_glb_profile_description "${profiles[$i]}")"
        if [[ -n "$desc" ]]; then
            printf "  %d) %s - %s\n" "$((i + 1))" "${profiles[$i]}" "$desc"
        else
            printf "  %d) %s\n" "$((i + 1))" "${profiles[$i]}"
        fi
    done
    read -r -p "> " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#profiles[@]} )); then
        glb_log_error "Invalid choice: $choice"
        return 1
    fi

    chosen="${profiles[$((choice - 1))]}"

    if [[ "$dry_run" == "--dry-run" ]]; then
        glb_apply_profile "$chosen" "--dry-run"
        return
    fi

    printf "\n"
    printf "Preview of profile: %s\n" "$chosen"
    glb_apply_profile "$chosen" "--dry-run"

    if ! read -r -p $'\nApply this profile now? [Y/n] ' confirm; then
        glb_log_warn "No input available; not applying."
        return 1
    fi

    if [[ "$confirm" =~ ^[nN] ]]; then
        glb_log_warn "Cancelled; nothing changed."
        return 1
    fi

    glb_apply_profile "$chosen" ""
}

# ------------------------------------------------------------
# List available profiles
# ------------------------------------------------------------

glb_list_profiles() {
    local profiles_root="$GLB_ROOT/profiles"
    local dir

    if [[ ! -d "$profiles_root" ]]; then
        glb_log_warn "No profiles directory found."
        return 0
    fi

    printf "\n"
    printf "Available Profiles\n"
    printf -- "-------------------\n"
    for dir in "$profiles_root"/*/; do
        [[ -d "$dir" ]] || continue
        printf "  %s\n" "$(basename "$dir")"
    done
    printf "\n"
}
