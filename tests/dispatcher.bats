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

@test "glb restore fails cleanly for an unknown profile" {
    run "$GLB_ROOT/glb" restore no-such-profile
    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile not found"* ]]
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
