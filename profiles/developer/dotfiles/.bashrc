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
# snap binaries (e.g. yazi, installed via GLB's snap extras method)
# ------------------------------------------------------------
if [ -d /snap/bin ]; then
    export PATH="/snap/bin:$PATH"
fi

# ------------------------------------------------------------
# eza (modern ls) with plain ls fallback
# ------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --git --group-directories-first'
    alias ll='eza --icons --git -lah --group-directories-first'
    alias la='eza --icons --git -la --group-directories-first'
    alias l='eza --icons --git -l --group-directories-first'
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
    alias editbash='fresh-editor ~/.bashrc'
elif command -v fresh >/dev/null 2>&1; then
    alias editbash='fresh ~/.bashrc'
fi

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
fi
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ------------------------------------------------------------
# Prompt (Linux Mint default bash prompt — no Starship here)
# ------------------------------------------------------------
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# ------------------------------------------------------------
# mise (language version manager - installed via extras.txt)
# ------------------------------------------------------------
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash)"
fi

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
