#!/usr/bin/env bash
#
# Bash completion for glb. Installed by `glb restore` (see
# lib/completions.sh) as a symlink into
# ~/.local/share/bash-completion/completions/glb, where the
# bash-completion package's dynamic loader picks it up automatically
# (see .bashrc's existing bash_completion sourcing).

_glb_completions() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD - 1]}"
    commands="help version info install remove update restore profiles prompt"

    if [[ "$COMP_CWORD" -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return 0
    fi

    if [[ "$prev" == "restore" ]]; then
        local profiles
        # Every glb invocation prints a banner first, so pick out only
        # lines that are a single indented token (how glb_list_profiles
        # formats each profile name) rather than assuming a fixed
        # number of header lines to skip.
        profiles="$(glb profiles 2>/dev/null | awk 'NF==1 && /^[[:space:]]/ {print $1}')"
        COMPREPLY=($(compgen -W "$profiles --undo --dry-run" -- "$cur"))
    fi
}

complete -F _glb_completions glb
