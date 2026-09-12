# ============================================================
# Greg's Fish Configuration
# Pop!_OS Edition
# ============================================================

# Disable greeting
set -U fish_greeting

# User programs
fish_add_path ~/.local/bin

# snap binaries (e.g. yazi, installed via GLB's snap extras method).
# --append so ~/.local/bin stays ahead of /snap/bin: a GLB-installed
# upstream binary must beat a same-named snap.
if test -d /snap/bin
    fish_add_path --append /snap/bin
end

# ------------------------------------------------------------
# eza (modern ls)
# ------------------------------------------------------------
if command -q eza
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza --icons --git --hyperlink -lah --group-directories-first'
    alias la='eza --icons --git --hyperlink -la --group-directories-first'
    alias l='eza --icons --git --hyperlink -l --group-directories-first'
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
    alias update='yay -Syu'
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
else if command -q fresh
    alias editfish='fresh ~/.config/fish/config.fish'
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

# Force fzf to open as a 40% height bottom pop-up layout in Fish
set -gx FZF_DEFAULT_OPTS "--height 40% --layout=reverse --border"

# ------------------------------------------------------------
# atuin (searchable, synced shell history - replaces Ctrl-R).
# Sourced after fzf so atuin's Ctrl-R binding wins. --disable-up-arrow
# keeps plain Up as normal per-session history.
# ------------------------------------------------------------
if command -q atuin
    atuin init fish --disable-up-arrow | source
end

# ------------------------------------------------------------
# Starship Prompt (Tokyo Night preset, blue accent — see
# ~/.config/starship-fish.toml / lib/prompt.sh / `glb prompt`).
# STARSHIP_CONFIG is set explicitly, not left to default, so a value
# leaked from another shell's environment can never override it.
# ------------------------------------------------------------
set -gx STARSHIP_CONFIG ~/.config/starship-fish.toml
starship init fish | source

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# ------------------------------------------------------------
# Rust / Cargo (cargo install puts binaries in ~/.cargo/bin)
# ------------------------------------------------------------
if test -d ~/.cargo/bin
    fish_add_path ~/.cargo/bin
end
