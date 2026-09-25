# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls, grep, etc.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ------------------------------------------------------------
# User binaries (glb itself lives here - see lib/completions.sh)
# ------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"

# ------------------------------------------------------------
# snap binaries (e.g. yazi, installed via GLB's snap extras method).
# Appended, not prepended: ~/.local/bin must stay ahead of /snap/bin so
# a GLB-installed upstream binary beats a same-named snap.
# ------------------------------------------------------------
if [ -d /snap/bin ]; then
    export PATH="$PATH:/snap/bin"
fi

# ------------------------------------------------------------
# eza (modern ls) with plain ls fallback
# ------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza --icons --git --hyperlink -lah --group-directories-first'
    alias la='eza --icons --git --hyperlink -la --group-directories-first'
    alias l='eza --icons --git --hyperlink -l --group-directories-first'
    alias lt='eza --tree --level=2 --long --icons --git'
    alias lta='lt -a'
else
    alias ls='ls --color=auto'
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
alias reload='source ~/.bashrc'

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
    # `update` brings the whole system current: repo + AUR updates, then
    # Flatpak apps. Uses whichever AUR helper is installed (paru, then
    # yay), else plain `sudo pacman -Syu`. Stops at the first step that
    # fails or is declined. Extra arguments pass through to the package
    # step.
    update() {
        if command -v paru >/dev/null 2>&1; then
            paru -Syu "$@" || return $?
        elif command -v yay >/dev/null 2>&1; then
            yay -Syu "$@" || return $?
        else
            sudo pacman -Syu "$@" || return $?
        fi
        if command -v flatpak >/dev/null 2>&1; then
            flatpak update
        fi
    }
    alias install='sudo pacman -S'
    alias remove='sudo pacman -Rns'
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
    export EDITOR=fresh-editor VISUAL=fresh-editor
    alias editbash='fresh-editor ~/.bashrc'
elif command -v fresh >/dev/null 2>&1; then
    export EDITOR=fresh VISUAL=fresh
    alias editbash='fresh ~/.bashrc'
fi

# ------------------------------------------------------------
# bash-preexec (must load before atuin/starship below). Both of them
# register into the precmd_functions/preexec_functions arrays instead
# of setting PROMPT_COMMAND directly whenever those arrays already
# exist - a real bash-preexec convention, but neither of them actually
# provides the dispatcher that reads those arrays; that's bash-preexec's
# job. Without it loaded first, atuin's init (which unconditionally
# defines the arrays) makes starship think a framework is already
# present, so starship also just appends itself to the same arrays -
# and since nothing then reads them, PROMPT_COMMAND is silently left
# holding only zoxide's hook and the Starship prompt never renders.
# Hit for real on Fedora 44 (2026-09-14): zsh/fish were unaffected
# (they have native precmd/preexec support built into the shell), only
# bash showed the plain, uncustomized prompt.
# ------------------------------------------------------------
if [ ! -f "$HOME/.bash-preexec.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o "$HOME/.bash-preexec.sh" 2>/dev/null
fi
[ -f "$HOME/.bash-preexec.sh" ] && source "$HOME/.bash-preexec.sh"

# ------------------------------------------------------------
# zoxide
# ------------------------------------------------------------
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# ------------------------------------------------------------
# fzf
# ------------------------------------------------------------
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
elif [ -f /usr/share/fzf/key-bindings.bash ]; then
    source /usr/share/fzf/key-bindings.bash
elif [ -f /usr/share/fzf/shell/key-bindings.bash ]; then
    source /usr/share/fzf/shell/key-bindings.bash
fi
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# ------------------------------------------------------------
# atuin (searchable, synced shell history - replaces Ctrl-R).
# Sourced after fzf so atuin's Ctrl-R binding wins. --disable-up-arrow
# keeps plain Up as normal per-session history.
# ------------------------------------------------------------
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash --disable-up-arrow)"
fi

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ------------------------------------------------------------
# Rust / Cargo (cargo install puts binaries in ~/.cargo/bin)
# ------------------------------------------------------------
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# ------------------------------------------------------------
# Starship Prompt (Tokyo Night preset, green accent — see
# ~/.config/starship-bash.toml / lib/prompt.sh / `glb prompt`).
# STARSHIP_CONFIG is set explicitly, not left to default, so a value
# leaked from another shell's environment can never override it.
# ------------------------------------------------------------
export STARSHIP_CONFIG="$HOME/.config/starship-bash.toml"
eval "$(starship init bash)"

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
