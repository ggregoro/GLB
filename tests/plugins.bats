#!/usr/bin/env bats
#
# Tests for lib/plugins.sh's glb_install_zsh_plugins: already-installed
# detection and the --dry-run path. git is always stubbed - real clones
# are covered by manual verification, not this suite.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/plugins.sh"
}

teardown() {
    glb_teardown_sandbox
}

@test "skips a plugin whose directory already exists" {
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-autosuggestions"
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-syntax-highlighting"

    run glb_install_zsh_plugins

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed: zsh-autosuggestions"* ]]
    [[ "$output" == *"Already installed: zsh-syntax-highlighting"* ]]
}

@test "clones a plugin that isn't installed yet" {
    stub_command git 'mkdir -p "$5"; exit 0'
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-syntax-highlighting"

    run glb_install_zsh_plugins

    [ "$status" -eq 0 ]
    [[ "$output" == *"Installed zsh plugin: zsh-autosuggestions"* ]]
    [ -d "$HOME/.local/share/glb/plugins/zsh-autosuggestions" ]
}

@test "dry-run: announces what would install without cloning or creating the plugins dir" {
    run glb_install_zsh_plugins "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would install zsh plugin: zsh-autosuggestions"* ]]
    [[ "$output" == *"Would install zsh plugin: zsh-syntax-highlighting"* ]]
    [ ! -d "$HOME/.local/share/glb/plugins" ]
}

@test "dry-run: still reports an already-installed plugin as such" {
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-autosuggestions"

    run glb_install_zsh_plugins "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed: zsh-autosuggestions"* ]]
    [[ "$output" == *"Would install zsh plugin: zsh-syntax-highlighting"* ]]
}

# --- glb_update_zsh_plugins -------------------------------------------------

@test "update: skips a plugin that was never cloned" {
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-autosuggestions"
    stub_command git 'echo "git $*" >> "$TEST_TMP/calls"; exit 0'

    run glb_update_zsh_plugins

    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating zsh plugin: zsh-autosuggestions"* ]]
    [[ "$output" != *"zsh-syntax-highlighting"* ]]
    grep -q -- "-C .*zsh-autosuggestions pull" "$TEST_TMP/calls"
}

@test "update: git pulls every plugin directory that already exists" {
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-autosuggestions"
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-syntax-highlighting"
    stub_command git 'echo "git $*" >> "$TEST_TMP/calls"; exit 0'

    run glb_update_zsh_plugins

    [ "$status" -eq 0 ]
    [[ "$output" == *"Updated zsh plugin: zsh-autosuggestions"* ]]
    [[ "$output" == *"Updated zsh plugin: zsh-syntax-highlighting"* ]]
    grep -q -- "-C .*zsh-autosuggestions pull" "$TEST_TMP/calls"
    grep -q -- "-C .*zsh-syntax-highlighting pull" "$TEST_TMP/calls"
}

@test "update: no-op when no plugins have ever been installed" {
    stub_command git 'echo "git called" >> "$TEST_TMP/calls"; exit 0'

    run glb_update_zsh_plugins

    [ "$status" -eq 0 ]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "update: reports failure when a git pull fails" {
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-autosuggestions"
    stub_command git 'exit 1'

    run glb_update_zsh_plugins

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to update zsh plugin: zsh-autosuggestions"* ]]
}
