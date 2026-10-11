#!/usr/bin/env bats
#
# Tests for the "this copy of GLB is behind" notice (lib/selfcheck.sh).
# The remote is a bare repo on local disk; nothing here touches the
# network. sudo/apt are stubbed so `glb update` changes nothing real.

load 'test_helper'

setup() {
    glb_setup_sandbox
    stub_command sudo '[ "$1" = "-n" ] && shift; exec "$@"'
    stub_command apt 'echo "apt $*"; exit 0'
    stub_command dpkg 'exit 1'
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'

    ORIGIN="$TEST_TMP/origin.git"
    SEED="$TEST_TMP/seed"
}

teardown() {
    glb_teardown_sandbox
}

_git() {
    git -c user.name=test -c user.email=test@example.com \
        -c init.defaultBranch=main -c commit.gpgsign=false "$@"
}

# make_glb_checkout
# Turn the sandbox GLB_ROOT into a git checkout that tracks a local
# bare remote, up to date with it.
make_glb_checkout() {
    _git init -q --bare "$ORIGIN"
    _git init -q "$SEED"
    _git -C "$SEED" commit -q --allow-empty -m "first"
    _git -C "$SEED" push -q "$ORIGIN" main

    _git -C "$GLB_ROOT" init -q
    _git -C "$GLB_ROOT" remote add origin "$ORIGIN"
    _git -C "$GLB_ROOT" fetch -q origin
    _git -C "$GLB_ROOT" reset -q --soft origin/main
    _git -C "$GLB_ROOT" branch -q --set-upstream-to=origin/main
}

# push_to_remote <count>
# Add <count> commits to the remote that GLB_ROOT doesn't have yet.
push_to_remote() {
    local i
    for ((i = 0; i < $1; i++)); do
        _git -C "$SEED" commit -q --allow-empty -m "newer $i"
    done
    _git -C "$SEED" push -q "$ORIGIN" main
}

@test "no notice when GLB is not a git checkout" {
    run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" != *"behind its remote"* ]]
}

@test "no notice when the copy is up to date" {
    make_glb_checkout

    run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" != *"behind its remote"* ]]
}

@test "update warns, with the pull command, when the copy is behind" {
    make_glb_checkout
    push_to_remote 2

    run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"This copy of GLB is 2 commit(s) behind its remote"* ]]
    [[ "$output" == *"git -C $GLB_ROOT pull --ff-only"* ]]
    # The notice comes before the work starts.
    [[ "${output%%apt *}" == *"behind its remote"* ]]
}

@test "the notice never updates GLB itself" {
    make_glb_checkout
    before="$(git -C "$GLB_ROOT" rev-parse HEAD)"
    push_to_remote 1

    run "$GLB_ROOT/glb" update
    [ "$(git -C "$GLB_ROOT" rev-parse HEAD)" = "$before" ]
}

@test "restore and repair warn too" {
    make_glb_checkout
    push_to_remote 1

    run "$GLB_ROOT/glb" restore no-such-profile
    [[ "$output" == *"behind its remote"* ]]

    run "$GLB_ROOT/glb" repair no-such-profile
    [[ "$output" == *"behind its remote"* ]]
}

@test "a failed command repeats the notice at the end" {
    make_glb_checkout
    push_to_remote 1

    run "$GLB_ROOT/glb" update no-such-profile
    [ "$status" -eq 1 ]
    [[ "${lines[-1]}" == *"git -C $GLB_ROOT pull --ff-only"* ]]
    [[ "$output" == *"this problem may already be fixed"* ]]
}

@test "a successful command does not repeat the notice" {
    make_glb_checkout
    push_to_remote 1

    run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" != *"this problem may already be fixed"* ]]
}

@test "commands that change nothing stay quiet" {
    make_glb_checkout
    push_to_remote 1

    run "$GLB_ROOT/glb" help
    [[ "$output" != *"behind its remote"* ]]
    run "$GLB_ROOT/glb" profiles
    [[ "$output" != *"behind its remote"* ]]
}

@test "an unreachable remote is silent and does not fail the command" {
    make_glb_checkout
    push_to_remote 1
    rm -rf "$ORIGIN"

    run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" != *"behind its remote"* ]]
}

@test "GLB_NO_SELF_CHECK=1 turns the notice off" {
    make_glb_checkout
    push_to_remote 1

    GLB_NO_SELF_CHECK=1 run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" != *"behind its remote"* ]]
}
