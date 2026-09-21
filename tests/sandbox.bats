#!/usr/bin/env bats
#
# Tests for the test sandbox itself (test_helper.bash): the sandbox PATH
# must hide the host's copies of the commands GLB installs, so no test
# depends on whether GLB has already been applied to the machine running
# the suite.

load 'test_helper'

setup() {
    glb_setup_sandbox
}

teardown() {
    glb_teardown_sandbox
}

@test "shadow path leaves out hidden commands but keeps everything else" {
    local fake="$TEST_TMP/fakebin" dest="$TEST_TMP/shadow-test"
    mkdir -p "$fake"
    printf '#!/bin/sh\n' > "$fake/nvim";  chmod +x "$fake/nvim"
    printf '#!/bin/sh\n' > "$fake/fresh"; chmod +x "$fake/fresh"
    printf '#!/bin/sh\n' > "$fake/keepme"; chmod +x "$fake/keepme"

    _glb_build_shadow_path "$dest" "$fake"

    [ ! -e "$dest/nvim" ]
    [ ! -e "$dest/fresh" ]
    [ -x "$dest/keepme" ]
}

@test "shadow path resolves duplicate names to the first PATH entry" {
    local a="$TEST_TMP/a" b="$TEST_TMP/b" dest="$TEST_TMP/shadow-test"
    mkdir -p "$a" "$b"
    printf '#!/bin/sh\n' > "$a/tool"; chmod +x "$a/tool"
    printf '#!/bin/sh\n' > "$b/tool"; chmod +x "$b/tool"

    _glb_build_shadow_path "$dest" "$a:$b"

    [ "$(readlink "$dest/tool")" = "$a/tool" ]
}

@test "sandbox PATH hides the hidden commands from command -v" {
    run bash -c 'command -v fresh'
    [ "$status" -ne 0 ]
    run bash -c 'command -v nvim'
    [ "$status" -ne 0 ]
}

@test "sandbox PATH still finds ordinary host tools" {
    run bash -c 'command -v ls && command -v sort'
    [ "$status" -eq 0 ]
}

@test "a stub in STUB_BIN takes priority over the hiding" {
    stub_command nvim 'echo stubbed'

    run bash -c 'nvim'
    [ "$status" -eq 0 ]
    [ "$output" = "stubbed" ]
}
