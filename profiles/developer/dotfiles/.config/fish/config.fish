# ============================================================
# Greg's Fish Configuration
# Pop!_OS Edition
# ============================================================

# Disable greeting
set -U fish_greeting

# User programs
fish_add_path ~/.local/bin

# snap binaries (e.g. yazi, installed via GLB's snap extras method)
if test -d /snap/bin
    fish_add_path /snap/bin
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
# Prompt (hand-rolled Pure-style — no Starship here)
# ------------------------------------------------------------
function fish_prompt
    set -l last_status $status

    # Status symbols mirror Starship's default git_status set (zsh prompt)
    # so both shells read the same way: = conflicted, $ stashed,
    # ✘ deleted, » renamed, ! modified, + staged, ? untracked.
    set -l git_info ""
    if command -q git; and git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        set git_info " $branch"

        set -l conflicted 0
        set -l deleted 0
        set -l renamed 0
        set -l modified 0
        set -l staged 0
        set -l untracked 0

        for line in (git status --porcelain 2>/dev/null)
            set -l x (string sub -l 1 $line)
            set -l y (string sub -s 2 -l 1 $line)
            if test "$x$y" = "??"
                set untracked 1
            else if contains U $x $y; or test "$x$y" = "AA"; or test "$x$y" = "DD"
                set conflicted 1
            else if test "$x" = D -o "$y" = D
                set deleted 1
            else if test "$x" = R
                set renamed 1
            else
                test "$x" != " " -a "$x" != "?"; and set staged 1
                test "$y" != " " -a "$y" != "?"; and set modified 1
            end
        end

        set -l stashed 0
        git rev-parse --verify --quiet refs/stash >/dev/null 2>&1; and set stashed 1

        set -l status_symbols ""
        test $conflicted -eq 1; and set status_symbols "$status_symbols="
        test $stashed -eq 1; and set status_symbols "$status_symbols\$"
        test $deleted -eq 1; and set status_symbols "$status_symbols✘"
        test $renamed -eq 1; and set status_symbols "$status_symbols»"
        test $modified -eq 1; and set status_symbols "$status_symbols!"
        test $staged -eq 1; and set status_symbols "$status_symbols+"
        test $untracked -eq 1; and set status_symbols "$status_symbols?"

        test -n "$status_symbols"; and set git_info "$git_info $status_symbols"
    end

    echo
    set_color blue --bold
    echo -n (prompt_pwd)
    set_color yellow
    echo -n $git_info
    set_color normal
    echo
    if test $last_status -eq 0
        set_color green
    else
        set_color red
    end
    echo -n '❯ '
    set_color normal
end

function fish_right_prompt
    if test -n "$CMD_DURATION" -a "$CMD_DURATION" -gt 5000
        set_color yellow
        set -l total_seconds (math -s0 "$CMD_DURATION / 1000")
        set -l hours (math -s0 "$total_seconds / 3600")
        set -l minutes (math -s0 "($total_seconds % 3600) / 60")
        set -l seconds (math -s0 "$total_seconds % 60")

        if test $hours -gt 0
            printf '%sh%sm%ss' $hours $minutes $seconds
        else if test $minutes -gt 0
            printf '%sm%ss' $minutes $seconds
        else
            printf '%ss' $seconds
        end
        set_color normal
    end
end

# ------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# ------------------------------------------------------------
# mise (language version manager - installed via extras.txt)
# ------------------------------------------------------------
if test -x "$HOME/.local/bin/mise"
    "$HOME/.local/bin/mise" activate fish | source
end
