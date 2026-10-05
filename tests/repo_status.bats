#!/usr/bin/env bats
#
# Tests for the repo-status script shipped in the default profile
# (dotfiles/.local/bin/repo-status). Every repo here is a throwaway one
# under the sandboxed HOME with a local bare repo as its remote - no
# test reads a real ~/Projects or touches the network.

load 'test_helper'

setup() {
    glb_setup_sandbox
    SCRIPT="$GLB_REPO_ROOT/profiles/default/dotfiles/.local/bin/repo-status"
    mkdir -p "$HOME/Projects"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
}

teardown() {
    glb_teardown_sandbox
}

# make_synced_repo <name>: a clone with one pushed commit.
make_synced_repo() {
    git init -q --bare "$TEST_TMP/$1.git"
    git clone -q "$TEST_TMP/$1.git" "$HOME/Projects/$1" 2>/dev/null
    git -C "$HOME/Projects/$1" commit -q --allow-empty -m one
    git -C "$HOME/Projects/$1" push -q -u origin HEAD 2>/dev/null
}

# Strip the color codes so assertions read as plain text.
plain() {
    printf '%s\n' "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

@test "repo-status is executable" {
    [ -x "$SCRIPT" ]
}

@test "a clean, pushed repo shows as clean and in sync" {
    make_synced_repo alpha
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    out="$(plain "$output")"
    [[ "$out" == *"alpha"*"clean"*"in sync"* ]]
    [[ "$out" == *"1 repos, 0 with changes"* ]]
}

@test "uncommitted work shows as has changes and is counted" {
    make_synced_repo alpha
    touch "$HOME/Projects/alpha/new-file"
    run "$SCRIPT"
    out="$(plain "$output")"
    [[ "$out" == *"alpha"*"has changes"* ]]
    [[ "$out" == *"1 repos, 1 with changes"* ]]
}

@test "unpushed commits show as ahead" {
    make_synced_repo alpha
    git -C "$HOME/Projects/alpha" commit -q --allow-empty -m two
    git -C "$HOME/Projects/alpha" commit -q --allow-empty -m three
    run "$SCRIPT"
    [[ "$(plain "$output")" == *"↑2 ↓0"* ]]
}

@test "a branch that was never pushed says no upstream, with no git errors" {
    git init -q "$HOME/Projects/local-only"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    out="$(plain "$output")"
    [[ "$out" == *"local-only"*"no upstream"* ]]
    [[ "$out" != *"fatal"* ]]
}

@test "folders that are not git repos are skipped" {
    make_synced_repo alpha
    mkdir "$HOME/Projects/just-a-folder"
    run "$SCRIPT"
    out="$(plain "$output")"
    [[ "$out" != *"just-a-folder"* ]]
    [[ "$out" == *"1 repos, 0 with changes"* ]]
}
