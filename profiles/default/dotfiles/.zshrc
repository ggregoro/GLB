# User configuration / aliases
alias ll="ls -lah"

# Force fzf to open as a pop-up taking up 40% of the screen height from the bottom
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_TMUX_OPTS="-p 80%,40%"

# Framework-free plugins vendored by `glb restore` (see lib/plugins.sh)
source "$HOME/.local/share/glb/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Starship prompt (see lib/prompt.sh / `glb prompt`)
eval "$(starship init zsh)"

# Must be sourced last
source "$HOME/.local/share/glb/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
