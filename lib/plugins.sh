#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: plugins.sh
# Purpose: Vendor a curated set of zsh plugins, framework-free.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Curated zsh plugins (name -> git repo URL)
# ------------------------------------------------------------

declare -gA _GLB_ZSH_PLUGINS=(
    [zsh-autosuggestions]="https://github.com/zsh-users/zsh-autosuggestions"
    [zsh-syntax-highlighting]="https://github.com/zsh-users/zsh-syntax-highlighting"
)

# ------------------------------------------------------------
# Clone every curated plugin into ~/.local/share/glb/plugins
# ------------------------------------------------------------

glb_install_zsh_plugins() {
    local dry_run="${1:-}"
    local plugins_dir="$HOME/.local/share/glb/plugins"
    local name repo dest
    local failed=()

    if [[ "$dry_run" != "--dry-run" ]]; then
        glb_create_directory "$plugins_dir"
    fi

    for name in "${!_GLB_ZSH_PLUGINS[@]}"; do
        repo="${_GLB_ZSH_PLUGINS[$name]}"
        dest="$plugins_dir/$name"

        if [[ -d "$dest" ]]; then
            glb_log_info "Already installed: $name"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            glb_log_info "Would install zsh plugin: $name"
            continue
        fi

        glb_log_info "Installing zsh plugin: $name"

        if git clone --depth 1 "$repo" "$dest"; then
            glb_log_success "Installed zsh plugin: $name"
        else
            glb_log_error "Failed to install zsh plugin: $name"
            failed+=("$name")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to install ${#failed[@]} plugin(s): ${failed[*]}"
        return 1
    fi
}
