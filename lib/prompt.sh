#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: prompt.sh
# Purpose: Install and configure the Starship shell prompt.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Install the starship binary if it isn't already present
# ------------------------------------------------------------

glb_install_starship() {
    if glb_command_exists starship; then
        glb_log_info "Already installed: starship"
        return 0
    fi

    glb_log_info "Installing starship..."

    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        glb_log_success "Installed starship"
    else
        glb_log_error "Failed to install starship"
        return 1
    fi
}

# ------------------------------------------------------------
# Back up an existing file to <name>.glb-backup
# ------------------------------------------------------------

_glb_backup_file() {
    local target="$1"

    if [[ -e "$target" || -L "$target" ]]; then
        glb_log_warn "Backing up existing $target -> $target.glb-backup"
        mv "$target" "$target.glb-backup"
    fi
}

# ------------------------------------------------------------
# Prompt the user to pick a Starship preset and write
# ~/.config/starship.toml accordingly
# ------------------------------------------------------------

glb_configure_starship() {
    local config_file="$HOME/.config/starship.toml"
    local choice slug

    printf "\n"
    printf "Choose a Starship prompt preset:\n"
    printf "  1) Default (Starship's built-in look)\n"
    printf "  2) Pure Prompt\n"
    printf "  3) Pastel Powerline\n"
    printf "  4) Nerd Font Symbols\n"
    printf "  5) Plain Text Symbols\n"
    printf "  6) No Runtime Versions\n"
    read -r -p "> " choice

    case "$choice" in
        1) slug="default" ;;
        2) slug="pure-preset" ;;
        3) slug="pastel-powerline" ;;
        4) slug="nerd-font-symbols" ;;
        5) slug="plain-text-symbols" ;;
        6) slug="no-runtime-versions" ;;
        *)
            glb_log_error "Invalid choice: $choice"
            return 1
            ;;
    esac

    glb_create_directory "$HOME/.config"
    _glb_backup_file "$config_file"

    if [[ "$slug" == "default" ]]; then
        glb_log_success "Using Starship's default look (no config file written)"
        return 0
    fi

    if starship preset "$slug" -o "$config_file"; then
        glb_log_success "Wrote $config_file ($slug)"
    else
        glb_log_error "Failed to generate starship preset: $slug"
        return 1
    fi
}

# ------------------------------------------------------------
# Ensure ~/.zshrc initializes starship (idempotent)
# ------------------------------------------------------------

glb_enable_starship_zsh() {
    local zshrc="$HOME/.zshrc"

    glb_create_directory "$(dirname "$zshrc")"
    [[ -f "$zshrc" ]] || touch "$zshrc"

    if grep -q 'starship init zsh' "$zshrc" 2>/dev/null; then
        glb_log_info "starship already initialized in ~/.zshrc"
        return 0
    fi

    printf '\neval "$(starship init zsh)"\n' >> "$zshrc"
    glb_log_success "Added starship init to ~/.zshrc"
}

# ------------------------------------------------------------
# Full prompt setup: install, configure, enable
# ------------------------------------------------------------

glb_setup_prompt() {
    glb_install_starship || return 1
    glb_configure_starship || return 1
    glb_enable_starship_zsh
}
