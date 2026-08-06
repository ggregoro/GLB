#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: completions.sh
# Purpose: Put `glb` itself on PATH (~/.local/bin) and install its
#          bash/zsh/fish shell completions.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Symlink src -> dest, backing up anything already at dest, with
# --dry-run support. Shared by the self-symlink and every shell's
# completion file below.
# ------------------------------------------------------------

_glb_link_with_backup() {
    local src="$1"
    local dest="$2"
    local dry_run="$3"
    local label="$4"

    if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        glb_log_info "Already linked: $label"
        return 0
    fi

    if [[ "$dry_run" == "--dry-run" ]]; then
        if [[ -e "$dest" || -L "$dest" ]]; then
            glb_log_info "Would back up $label -> $label.glb-backup, then link"
        else
            glb_log_info "Would link $label"
        fi
        return 0
    fi

    if ! glb_create_directory "$(dirname "$dest")"; then
        glb_log_error "Failed to create directory for $label"
        return 1
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        glb_log_warn "Backing up existing $label -> $label.glb-backup"
        if ! mv "$dest" "$dest.glb-backup"; then
            glb_log_error "Failed to back up $label"
            return 1
        fi
    fi

    if ln -s "$src" "$dest"; then
        glb_log_success "Linked $label"
    else
        glb_log_error "Failed to link $label"
        return 1
    fi
}

# ------------------------------------------------------------
# Symlink the glb script itself into ~/.local/bin so it's callable
# as a bare `glb` command - also required for completions to work.
# ------------------------------------------------------------

glb_install_self_symlink() {
    local dry_run="${1:-}"
    _glb_link_with_backup "$GLB_ROOT/glb" "$HOME/.local/bin/glb" "$dry_run" "~/.local/bin/glb"
}

# ------------------------------------------------------------
# Symlink each shell's completion file into its standard
# auto-loaded location.
# ------------------------------------------------------------

glb_install_completions() {
    local dry_run="${1:-}"
    local failed=()

    _glb_link_with_backup \
        "$GLB_ROOT/completions/glb.bash" \
        "$HOME/.local/share/bash-completion/completions/glb" \
        "$dry_run" "~/.local/share/bash-completion/completions/glb" \
        || failed+=("bash")

    _glb_link_with_backup \
        "$GLB_ROOT/completions/_glb" \
        "$HOME/.local/share/zsh/completions/_glb" \
        "$dry_run" "~/.local/share/zsh/completions/_glb" \
        || failed+=("zsh")

    _glb_link_with_backup \
        "$GLB_ROOT/completions/glb.fish" \
        "$HOME/.config/fish/completions/glb.fish" \
        "$dry_run" "~/.config/fish/completions/glb.fish" \
        || failed+=("fish")

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to install completions for: ${failed[*]}"
        return 1
    fi
}
