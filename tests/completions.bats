#!/usr/bin/env bats
#
# Tests for lib/completions.sh: symlinking glb itself into
# ~/.local/bin and installing bash/zsh/fish completion files, plus
# the shared backup-and-link helper's --dry-run path.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/completions.sh"
}

teardown() {
    glb_teardown_sandbox
}

# --- glb_install_self_symlink -----------------------------------------------

@test "self_symlink: links glb into ~/.local/bin" {
    run glb_install_self_symlink

    [ "$status" -eq 0 ]
    [[ "$output" == *"Linked ~/.local/bin/glb"* ]]
    [ -L "$HOME/.local/bin/glb" ]
    [ "$(readlink -f "$HOME/.local/bin/glb")" = "$(readlink -f "$GLB_ROOT/glb")" ]
}

@test "self_symlink: does nothing when already correctly linked" {
    mkdir -p "$HOME/.local/bin"
    ln -s "$GLB_ROOT/glb" "$HOME/.local/bin/glb"

    run glb_install_self_symlink

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already linked: ~/.local/bin/glb"* ]]
}

@test "self_symlink: backs up an existing file at the destination" {
    mkdir -p "$HOME/.local/bin"
    echo 'old script' > "$HOME/.local/bin/glb"

    run glb_install_self_symlink

    [ "$status" -eq 0 ]
    [ -L "$HOME/.local/bin/glb" ]
    [ "$(cat "$HOME/.local/bin/glb.glb-backup")" = "old script" ]
}

@test "self_symlink: dry-run announces the link without creating anything" {
    run glb_install_self_symlink "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would link ~/.local/bin/glb"* ]]
    [ ! -e "$HOME/.local/bin/glb" ]
}

@test "self_symlink: dry-run announces a backup+link when something already exists" {
    mkdir -p "$HOME/.local/bin"
    echo 'old script' > "$HOME/.local/bin/glb"

    run glb_install_self_symlink "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would back up ~/.local/bin/glb -> ~/.local/bin/glb.glb-backup, then link"* ]]
    [ "$(cat "$HOME/.local/bin/glb")" = "old script" ]
}

# --- glb_install_completions -------------------------------------------------

@test "completions: links all three shells' completion files" {
    run glb_install_completions

    [ "$status" -eq 0 ]
    [ -L "$HOME/.local/share/bash-completion/completions/glb" ]
    [ -L "$HOME/.local/share/zsh/completions/_glb" ]
    [ -L "$HOME/.config/fish/completions/glb.fish" ]
    [ "$(readlink -f "$HOME/.local/share/bash-completion/completions/glb")" = "$(readlink -f "$GLB_ROOT/completions/glb.bash")" ]
    [ "$(readlink -f "$HOME/.local/share/zsh/completions/_glb")" = "$(readlink -f "$GLB_ROOT/completions/_glb")" ]
    [ "$(readlink -f "$HOME/.config/fish/completions/glb.fish")" = "$(readlink -f "$GLB_ROOT/completions/glb.fish")" ]
}

@test "completions: is a no-op the second time (already linked)" {
    glb_install_completions

    run glb_install_completions

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already linked"* ]]
    [[ "$output" != *"[SUCCESS] Linked"* ]]
}

@test "completions: dry-run announces all three without creating anything" {
    run glb_install_completions "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would link ~/.local/share/bash-completion/completions/glb"* ]]
    [[ "$output" == *"Would link ~/.local/share/zsh/completions/_glb"* ]]
    [[ "$output" == *"Would link ~/.config/fish/completions/glb.fish"* ]]
    [ ! -e "$HOME/.local/share/bash-completion" ]
    [ ! -e "$HOME/.local/share/zsh" ]
    [ ! -e "$HOME/.config/fish" ]
}

@test "completions: reports failure and continues when a directory can't be created" {
    mkdir -p "$HOME/.local/share"
    chmod 555 "$HOME/.local/share"

    run glb_install_completions

    chmod 755 "$HOME/.local/share"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to install completions for:"* ]]
    [[ "$output" == *"bash"* ]]
    [[ "$output" == *"zsh"* ]]
    # fish's target is under ~/.config, unaffected by ~/.local/share being locked
    [ -L "$HOME/.config/fish/completions/glb.fish" ]
}
