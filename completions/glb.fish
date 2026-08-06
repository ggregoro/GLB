# Fish completion for glb. Installed by `glb restore` (see
# lib/completions.sh) as a symlink into
# ~/.config/fish/completions/glb.fish, which fish auto-loads.

set -l commands help version info install remove update restore profiles prompt

complete -c glb -f
complete -c glb -n "not __fish_seen_subcommand_from $commands" -a "$commands"
complete -c glb -n "__fish_seen_subcommand_from restore" -a "--undo --dry-run"
complete -c glb -n "__fish_seen_subcommand_from restore" -a "(glb profiles 2>/dev/null | string match -rg '^\s+(\S+)\$')"
