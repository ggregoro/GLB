#!/usr/bin/env bats
#
# Tests for lib/repair.sh: `glb repair <profile>` does an ephemeral
# export + diff against a profile (no snapshot saved to disk), then
# offers to fix any drift found by re-running glb restore. See
# docs/design/repair.md.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/detect.sh"
    source "$GLB_ROOT/lib/package.sh"
    source "$GLB_ROOT/lib/extras.sh"
    source "$GLB_ROOT/lib/completions.sh"
    source "$GLB_ROOT/lib/plugins.sh"
    source "$GLB_ROOT/lib/profile.sh"
    source "$GLB_ROOT/lib/export.sh"
    source "$GLB_ROOT/lib/diff.sh"
    source "$GLB_ROOT/lib/repair.sh"

    stub_command apt 'echo "apt $*" >> "$TEST_TMP/calls"; exit 0'
    stub_command sudo 'exec "$@"'
    stub_command dpkg 'exit 1'
    stub_command apt-mark 'printf ""'

    # Test doubles standing in for lib/prompt.sh / lib/plugins.sh,
    # which glb_apply_profile calls unconditionally.
    glb_install_starship() { return 0; }
    glb_install_zsh_plugins() { return 0; }
}

teardown() {
    glb_teardown_sandbox
}

@test "repair errors when no profile name is given" {
    run glb_repair ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: glb repair"* ]]
}

@test "repair errors for an unknown profile" {
    run glb_repair "does-not-exist"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile not found: does-not-exist"* ]]
}

@test "repair reports no differences when the machine already matches the profile" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/work/packages.txt"
    echo 'x' > "$GLB_ROOT/profiles/work/dotfiles/.bashrc"
    stub_command apt-mark 'printf "git\n"'
    echo 'x' > "$HOME/.bashrc"

    run glb_repair "work"

    [ "$status" -eq 0 ]
    [[ "$output" == *"No differences found: work is healthy."* ]]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "repair reports drift and applies the profile for real once confirmed" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\nzsh\n' > "$GLB_ROOT/profiles/work/packages.txt"
    stub_command apt-mark 'printf "git\n"'

    run glb_repair "work" <<< 'y'

    [ "$status" -eq 0 ]
    [[ "$output" == *"- only in work: zsh"* ]]
    [[ "$output" == *"Profile applied: work"* ]]
    grep -q "apt install -y zsh" "$TEST_TMP/calls"
}

@test "repair leaves the machine untouched when the user declines to fix drift" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\nzsh\n' > "$GLB_ROOT/profiles/work/packages.txt"
    stub_command apt-mark 'printf "git\n"'

    run glb_repair "work" <<< 'n'

    [ "$status" -eq 1 ]
    [[ "$output" == *"Cancelled; nothing changed."* ]]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "repair leaves the machine untouched when no confirmation input is available" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\nzsh\n' > "$GLB_ROOT/profiles/work/packages.txt"
    stub_command apt-mark 'printf "git\n"'

    run glb_repair "work" </dev/null

    [ "$status" -eq 1 ]
    [[ "$output" == *"No input available; not repairing."* ]]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "repair cleans up its ephemeral export directory afterward" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/work/packages.txt"
    stub_command apt-mark 'printf "git\n"'
    stub_command mktemp 'mkdir -p "$TEST_TMP/ephemeral"; echo "$TEST_TMP/ephemeral"'

    run glb_repair "work"

    [ ! -d "$TEST_TMP/ephemeral" ]
}

@test "repair detects a dotfile changed since the last restore" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/work/packages.txt"
    printf 'profile version\n' > "$GLB_ROOT/profiles/work/dotfiles/.bashrc"
    stub_command apt-mark 'printf "git\n"'
    printf 'hand-edited version\n' > "$HOME/.bashrc"

    run glb_repair "work" <<< 'n'

    [ "$status" -eq 1 ]
    [[ "$output" == *"~ changed: ~/.bashrc"* ]]
}
