#!/usr/bin/env bats
#
# Tests for the spell script shipped in the default profile
# (dotfiles/.local/bin/spell). aspell itself is stubbed, so the suite
# behaves the same whether or not the host has it installed: the stub
# records how it was called and never opens its full-screen checker.

load 'test_helper'

setup() {
    glb_setup_sandbox
    SCRIPT="$GLB_REPO_ROOT/profiles/default/dotfiles/.local/bin/spell"
    stub_command aspell 'echo "aspell $*" >> "$TEST_TMP/aspell.log"
[[ " $* " == *" list "* ]] && { echo zebra; echo apple; echo zebra; }
exit 0'
    echo "some text" > "$TEST_TMP/notes.md"
    echo "some text" > "$TEST_TMP/plain.txt"
}

teardown() {
    glb_teardown_sandbox
}

@test "spell is executable" {
    [ -x "$SCRIPT" ]
}

@test "spell with no file shows the commands and runs nothing" {
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"spell notes.md"* ]]
    [ ! -e "$TEST_TMP/aspell.log" ]
}

@test "spell help shows the commands" {
    run "$SCRIPT" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"spell list notes.md"* ]]
}

@test "spell <file> runs aspell check on it" {
    run "$SCRIPT" "$TEST_TMP/notes.md"
    [ "$status" -eq 0 ]
    grep -qx "aspell check $TEST_TMP/notes.md" "$TEST_TMP/aspell.log"
}

@test "spell with several files checks each one in order" {
    run "$SCRIPT" "$TEST_TMP/notes.md" "$TEST_TMP/plain.txt"
    [ "$status" -eq 0 ]
    [ "$(sed -n 1p "$TEST_TMP/aspell.log")" = "aspell check $TEST_TMP/notes.md" ]
    [ "$(sed -n 2p "$TEST_TMP/aspell.log")" = "aspell check $TEST_TMP/plain.txt" ]
}

@test "a missing file is reported and the others are still checked" {
    run "$SCRIPT" "$TEST_TMP/nope.md" "$TEST_TMP/notes.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"no such file: $TEST_TMP/nope.md"* ]]
    grep -qx "aspell check $TEST_TMP/notes.md" "$TEST_TMP/aspell.log"
}

@test "spell list prints each misspelled word once, sorted" {
    run "$SCRIPT" list "$TEST_TMP/plain.txt"
    [ "$status" -eq 0 ]
    [ "$output" = $'apple\nzebra' ]
    grep -qx "aspell list" "$TEST_TMP/aspell.log"
}

@test "spell list uses Markdown mode for a .md file" {
    run "$SCRIPT" list "$TEST_TMP/notes.md"
    [ "$status" -eq 0 ]
    grep -qx "aspell --mode=markdown list" "$TEST_TMP/aspell.log"
}

@test "spell list with several files labels each one" {
    run "$SCRIPT" list "$TEST_TMP/notes.md" "$TEST_TMP/plain.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == *"== $TEST_TMP/notes.md"* ]]
    [[ "$output" == *"== $TEST_TMP/plain.txt"* ]]
}

@test "a file that is really named list is checked, not treated as the list command" {
    echo "some text" > "$TEST_TMP/list"
    cd "$TEST_TMP"
    run "$SCRIPT" list
    [ "$status" -eq 0 ]
    grep -qx "aspell check list" "$TEST_TMP/aspell.log"
}

@test "without aspell, spell says so and stops" {
    mkdir "$TEST_TMP/bare"
    for tool in env bash cat; do
        ln -s "$(command -v "$tool")" "$TEST_TMP/bare/$tool"
    done
    PATH="$TEST_TMP/bare" run "$SCRIPT" "$TEST_TMP/notes.md"
    [ "$status" -eq 1 ]
    [[ "$output" == *"aspell is not installed"* ]]
}

@test "default profile: aspell and its English dictionary are listed" {
    grep -q '^aspell$' "$GLB_REPO_ROOT/profiles/default/packages.txt"
    grep -q '^aspell-en$' "$GLB_REPO_ROOT/profiles/default/packages.txt"
}
