# ============================================================
# Greg's Fish Configuration
# Pop!_OS Edition
# ============================================================

# Disable greeting
set -U fish_greeting

# User programs
fish_add_path ~/.local/bin

# ------------------------------------------------------------
# eza (modern ls)
# ------------------------------------------------------------
if command -q eza
    alias ls='eza --icons --group-directories-first'
    alias ll='eza --icons -lah --group-directories-first'
    alias la='eza --icons -la --group-directories-first'
    alias l='eza --icons -l --group-directories-first'
else
    alias ll='ls -lah'
    alias la='ls -la'
    alias l='ls -l'
end

# ------------------------------------------------------------
# bat
# ------------------------------------------------------------
if command -q batcat
    alias cat='batcat'
else if command -q bat
    alias cat='bat'
end

# ------------------------------------------------------------
# Navigation
# ------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias home='cd ~'

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------
alias md='mkdir -p'
alias rd='rmdir'

# ------------------------------------------------------------
# System
# ------------------------------------------------------------
alias ff='fastfetch'
alias c='clear'
alias cls='clear'
alias reload='source ~/.config/fish/config.fish'

# ------------------------------------------------------------
# Package manager shortcuts (auto-detected: apt/dnf/pacman/zypper)
# ------------------------------------------------------------
if command -q apt
    alias update='sudo apt update && sudo apt upgrade'
    alias install='sudo apt install'
    alias remove='sudo apt remove'
    alias search='apt search'
else if command -q dnf
    alias update='sudo dnf upgrade'
    alias install='sudo dnf install'
    alias remove='sudo dnf remove'
    alias search='dnf search'
else if command -q pacman
    alias update='sudo pacman -Syu'
    alias install='sudo pacman -S'
    alias remove='sudo pacman -R'
    alias search='pacman -Ss'
else if command -q zypper
    alias update='sudo zypper refresh && sudo zypper update'
    alias install='sudo zypper install'
    alias remove='sudo zypper remove'
    alias search='zypper search'
end

# ------------------------------------------------------------
# Editors
# ------------------------------------------------------------
if command -q fresh-editor
    alias editfish='fresh-editor ~/.config/fish/config.fish'
    alias editstarship='fresh-editor ~/.config/starship.toml'
    alias editconfig='fresh-editor ~/.config/fish/config.fish ~/.config/starship.toml'
else if command -q fresh
    alias editfish='fresh ~/.config/fish/config.fish'
    alias editstarship='fresh ~/.config/starship.toml'
    alias editconfig='fresh ~/.config/fish/config.fish ~/.config/starship.toml'
end

# ------------------------------------------------------------
# zoxide
# ------------------------------------------------------------
if command -q zoxide
    zoxide init fish | source
end

# ------------------------------------------------------------
# fzf
# ------------------------------------------------------------
if test -f /usr/share/fzf/shell/key-bindings.fish
    source /usr/share/fzf/shell/key-bindings.fish
else if test -f /usr/share/fzf/key-bindings.fish
    source /usr/share/fzf/key-bindings.fish
end

# ------------------------------------------------------------
# Starship Prompt
# ------------------------------------------------------------
set -gx GLB_SHELL "Ⓕ fish"
if command -q starship
    starship init fish | source

    # Force fzf to open as a 40% height bottom pop-up layout in Fish
    set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"
end

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end
