# ------------------------------------------------------------
# eza (modern ls) with plain ls fallback
# ------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza --icons -lah --group-directories-first'
    alias la='eza --icons -la --group-directories-first'
    alias l='eza --icons -l --group-directories-first'
else
    alias ll='ls -lah'
    alias la='ls -la'
    alias l='ls -l'
fi

# ------------------------------------------------------------
# bat
# ------------------------------------------------------------
if command -v batcat >/dev/null 2>&1; then
    alias cat='batcat'
elif command -v bat >/dev/null 2>&1; then
    alias cat='bat'
fi

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
alias reload='source ~/.zshrc'

# ------------------------------------------------------------
# APT shortcuts (Pop!_OS / Ubuntu / Debian)
# ------------------------------------------------------------
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias search='apt search'

# ------------------------------------------------------------
# Editors
# ------------------------------------------------------------
if command -v fresh-editor >/dev/null 2>&1; then
    alias editzsh='fresh-editor ~/.zshrc'
    alias editstarship='fresh-editor ~/.config/starship.toml'
elif command -v fresh >/dev/null 2>&1; then
    alias editzsh='fresh ~/.zshrc'
    alias editstarship='fresh ~/.config/starship.toml'
fi

# ------------------------------------------------------------
# zoxide
# ------------------------------------------------------------
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# ------------------------------------------------------------
# fzf
# ------------------------------------------------------------
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
elif [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
fi

# Force fzf to open as a pop-up taking up 40% of the screen height from the bottom
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_TMUX_OPTS="-p 80%,40%"

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ------------------------------------------------------------
# Framework-free plugins vendored by `glb restore` (see lib/plugins.sh)
# ------------------------------------------------------------
source "$HOME/.local/share/glb/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ------------------------------------------------------------
# Starship Prompt (see lib/prompt.sh / `glb prompt`)
# ------------------------------------------------------------
export GLB_SHELL="Ⓩ zsh"
eval "$(starship init zsh)"

# Must be sourced last
source "$HOME/.local/share/glb/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
