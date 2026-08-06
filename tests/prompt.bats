#!/usr/bin/env bats
#
# Tests for lib/prompt.sh's glb_install_starship: already-installed
# detection and the --dry-run path. curl/sh are always stubbed - real
# installs are covered by manual verification, not this suite.
#
# The "not yet installed" scenarios override glb_command_exists as a
# test double, since the machine running this suite may genuinely
# already have a real starship binary on PATH.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/prompt.sh"
}

teardown() {
    glb_teardown_sandbox
}

@test "skips install when starship is already on PATH" {
    stub_command starship 'exit 0'

    run glb_install_starship

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed: starship"* ]]
}

@test "installs by piping the install script to sh when not already present" {
    glb_command_exists() { [[ "$1" != "starship" ]]; }
    stub_command curl 'echo "curl $*" >> "$TEST_TMP/calls"; exit 0'
    stub_command sh 'echo "sh ran" >> "$TEST_TMP/calls"; exit 0'

    run glb_install_starship

    [ "$status" -eq 0 ]
    grep -q "curl -sS https://starship.rs/install.sh" "$TEST_TMP/calls"
    grep -q "sh ran" "$TEST_TMP/calls"
}

@test "dry-run: announces it would install without touching curl/sh" {
    glb_command_exists() { [[ "$1" != "starship" ]]; }

    run glb_install_starship "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would install: starship"* ]]
}

@test "dry-run: still reports an already-installed starship as such" {
    stub_command starship 'exit 0'

    run glb_install_starship "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed: starship"* ]]
    [[ "$output" != *"Would install"* ]]
}
