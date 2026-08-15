# ------------------------------------------------------------
# History (zsh has no useful defaults on its own -- Oh My Zsh used
# to set these; nothing replaced them when it was removed)
# ------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ------------------------------------------------------------
# User binaries (glb itself lives here - see lib/completions.sh)
# ------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# ------------------------------------------------------------
# snap binaries (e.g. yazi, installed via GLB's snap extras method)
# ------------------------------------------------------------
if [ -d /snap/bin ]; then
    export PATH="/snap/bin:$PATH"
fi

# ------------------------------------------------------------
# Completions (zsh has no completion system on its own -- Oh My Zsh
# used to init this too; glb's own completion lives in the fpath dir
# below, see lib/completions.sh)
# ------------------------------------------------------------
fpath=("$HOME/.local/share/zsh/completions" $fpath)
autoload -Uz compinit
compinit

# ------------------------------------------------------------
# eza (modern ls) with plain ls fallback
# ------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza --icons --git -lah --group-directories-first'
    alias la='eza --icons --git -la --group-directories-first'
    alias l='eza --icons --git -l --group-directories-first'
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
# Package manager shortcuts (auto-detected: apt/dnf/pacman/zypper)
# ------------------------------------------------------------
if command -v apt >/dev/null 2>&1; then
    alias update='sudo apt update && sudo apt upgrade'
    alias install='sudo apt install'
    alias remove='sudo apt remove'
    alias search='apt search'
elif command -v dnf >/dev/null 2>&1; then
    alias update='sudo dnf upgrade'
    alias install='sudo dnf install'
    alias remove='sudo dnf remove'
    alias search='dnf search'
elif command -v pacman >/dev/null 2>&1; then
    alias update='sudo pacman -Syu'
    alias install='sudo pacman -S'
    alias remove='sudo pacman -R'
    alias search='pacman -Ss'
elif command -v zypper >/dev/null 2>&1; then
    alias update='sudo zypper refresh && sudo zypper update'
    alias install='sudo zypper install'
    alias remove='sudo zypper remove'
    alias search='zypper search'
fi

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
# mise (language version manager - installed via extras.txt)
# ------------------------------------------------------------
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# ------------------------------------------------------------
# Framework-free plugins vendored by `glb restore` (see lib/plugins.sh)
# ------------------------------------------------------------
source "$HOME/.local/share/glb/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ------------------------------------------------------------
# Starship Prompt (Tokyo Night preset — see lib/prompt.sh / `glb prompt`)
# ------------------------------------------------------------
eval "$(starship init zsh)"

# Must be sourced last
source "$HOME/.local/share/glb/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
