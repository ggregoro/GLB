#!/usr/bin/env bats
#
# End-to-end smoke tests for the `glb` dispatcher's newly-wired
# commands: remove, update, restore, profiles. sudo/apt are stubbed so
# nothing here touches real system packages.

load 'test_helper'

setup() {
    glb_setup_sandbox
    stub_command sudo 'exec "$@"'
    stub_command apt 'echo "apt $*"; exit 0'
    stub_command dpkg 'exit 1'
}

teardown() {
    glb_teardown_sandbox
}

@test "glb with no args shows help" {
    run "$GLB_ROOT/glb"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "glb help lists all commands including the new ones" {
    run "$GLB_ROOT/glb" help
    [[ "$output" == *"restore"* ]]
    [[ "$output" == *"profiles"* ]]
    [[ "$output" == *"remove"* ]]
    [[ "$output" == *"update"* ]]
}

@test "glb rejects an unknown command" {
    run "$GLB_ROOT/glb" bogus-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "glb profiles lists profiles under GLB_ROOT" {
    mkdir -p "$GLB_ROOT/profiles/default" "$GLB_ROOT/profiles/server"
    run "$GLB_ROOT/glb" profiles
    [[ "$output" == *"default"* ]]
    [[ "$output" == *"server"* ]]
}

@test "glb restore applies a profile end to end" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/default/packages.txt"
    echo 'x' > "$GLB_ROOT/profiles/default/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore default

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: default"* ]]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb restore applies the real new-to-linux profile end to end" {
    cp -r "$GLB_REPO_ROOT/profiles/new-to-linux" "$GLB_ROOT/profiles/new-to-linux"
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'

    run "$GLB_ROOT/glb" restore new-to-linux <<< ''

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: new-to-linux"* ]]
    [[ "$output" == *"Installing fresh via curl-install script"* ]]
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.zshrc" ]
    [ -L "$HOME/.config/fish/config.fish" ]
    [ -L "$HOME/.config/starship.toml" ]
    [ ! -e "$HOME/.gitconfig" ]
    [ ! -e "$HOME/.config/ranger" ]
}

@test "glb restore applies the real default profile end to end" {
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'
    stub_command flatpak 'echo "flatpak $*" >> "$TEST_TMP/calls"; [ "$1" = "info" ] && exit 1; exit 0'

    run "$GLB_ROOT/glb" restore default <<< ''

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: default"* ]]
    [[ "$output" == *"Installing fresh via curl-install script"* ]]
    [[ "$output" == *"Installing wezterm via Flatpak"* ]]
    grep -q "install -y flathub org.wezfurlong.wezterm" "$TEST_TMP/calls"
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.gitconfig" ]
    [ -L "$HOME/.config/wezterm/wezterm.lua" ]
}

@test "glb restore fails cleanly for an unknown profile" {
    run "$GLB_ROOT/glb" restore no-such-profile
    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile not found"* ]]
}

@test "glb restore --undo reverses a prior restore's dotfile changes" {
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'

    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    echo 'new content' > "$GLB_ROOT/profiles/default/dotfiles/.bashrc"
    echo 'old content' > "$HOME/.bashrc"

    run "$GLB_ROOT/glb" restore default
    [ "$status" -eq 0 ]
    [ -L "$HOME/.bashrc" ]
    [ -f "$HOME/.bashrc.glb-backup" ]

    run "$GLB_ROOT/glb" restore --undo

    [ "$status" -eq 0 ]
    [[ "$output" == *"Restored ~/.bashrc"* ]]
    [ ! -L "$HOME/.bashrc" ]
    [ "$(cat "$HOME/.bashrc")" = "old content" ]
    [ ! -e "$HOME/.bashrc.glb-backup" ]
}

@test "glb restore --undo reports cleanly when there is nothing to undo" {
    run "$GLB_ROOT/glb" restore --undo
    [ "$status" -eq 0 ]
    [[ "$output" == *"nothing to undo"* ]]
}

@test "glb remove without a package name errors instead of crashing" {
    run "$GLB_ROOT/glb" remove
    [ "$status" -eq 1 ]
    [[ "$output" == *"No package specified"* ]]
}

@test "glb remove calls the package manager's remove command" {
    run "$GLB_ROOT/glb" remove git
    [ "$status" -eq 0 ]
    [[ "$output" == *"apt remove -y git"* ]]
}

@test "glb update runs the package manager's update commands" {
    run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"apt update"* ]]
    [[ "$output" == *"apt upgrade -y"* ]]
}
