#!/usr/bin/env bats
#
# Tests for the update notifier script shipped in the default profile
# (dotfiles/.local/bin/update-check-notify). checkupdates, paru and
# notify-send are always stubbed - no test here reads the real package
# database, touches the network, or pops a real desktop notification.

load 'test_helper'

setup() {
    glb_setup_sandbox
    SCRIPT="$GLB_REPO_ROOT/profiles/default/dotfiles/.local/bin/update-check-notify"
    export XDG_STATE_HOME="$TEST_TMP/state"
    STATE="$XDG_STATE_HOME/update-check/last-notified"

    # Default: notify-send works and is recorded.
    stub_command notify-send 'printf "%s\n" "$*" >> "$TEST_TMP/notified"; exit 0'
}

teardown() {
    glb_teardown_sandbox
}

# stub_updates <repo-lines> [<aur-lines>]
# checkupdates exits 0 with output when there are updates, 2 when none
# (its real contract); paru -Qua exits 1 with no output when none.
stub_updates() {
    local repo="$1" aur="${2:-}"
    if [[ -n "$repo" ]]; then
        stub_command checkupdates "printf '%s\n' '$repo'; exit 0"
    else
        stub_command checkupdates 'exit 2'
    fi
    if [[ -n "$aur" ]]; then
        stub_command paru "printf '%s\n' '$aur'; exit 0"
    else
        stub_command paru 'exit 1'
    fi
}

notified_count() {
    if [[ -f "$TEST_TMP/notified" ]]; then wc -l < "$TEST_TMP/notified"; else echo 0; fi
}

@test "does nothing, quietly, when checkupdates isn't installed (non-Arch)" {
    stub_command paru 'exit 1'

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    [ "$(notified_count)" -eq 0 ]
}

@test "no updates: no notification and no state file" {
    stub_updates ""

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(notified_count)" -eq 0 ]
    [ ! -f "$STATE" ]
}

@test "repo updates: notifies once with the count and package names" {
    stub_updates $'linux 1-1 -> 2-1\nmesa 1-1 -> 2-1'

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(notified_count)" -eq 1 ]
    grep -q '2 update(s) available' "$TEST_TMP/notified"
    grep -q '2 repo, 0 AUR: linux, mesa' "$TEST_TMP/notified"
    [ -s "$STATE" ]
}

@test "AUR-only updates are counted and labelled as AUR" {
    stub_updates "" 'foo 1-1 -> 1-2'

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    grep -q '0 repo, 1 AUR: foo' "$TEST_TMP/notified"
}

@test "the same pending updates don't notify a second time" {
    stub_updates 'linux 1-1 -> 2-1'

    "$SCRIPT"
    "$SCRIPT"

    [ "$(notified_count)" -eq 1 ]
}

@test "a changed set of updates notifies again" {
    stub_updates 'linux 1-1 -> 2-1'
    "$SCRIPT"

    stub_updates $'linux 1-1 -> 2-1\nmesa 1-1 -> 2-1'
    "$SCRIPT"

    [ "$(notified_count)" -eq 2 ]
}

@test "once everything is updated the state clears, so a new update notifies" {
    stub_updates 'linux 1-1 -> 2-1'
    "$SCRIPT"
    [ -s "$STATE" ]

    stub_updates ""
    "$SCRIPT"
    [ ! -f "$STATE" ]

    stub_updates 'linux 2-1 -> 3-1'
    "$SCRIPT"
    [ "$(notified_count)" -eq 2 ]
}

@test "a checkupdates error (offline, mirror down) is silent" {
    stub_command checkupdates 'exit 1'
    stub_command paru 'exit 1'

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    [ "$(notified_count)" -eq 0 ]
    [ ! -f "$STATE" ]
}

@test "works without paru: repo updates still notify" {
    stub_command checkupdates "printf 'linux 1-1 -> 2-1\n'; exit 0"

    run "$SCRIPT"

    [ "$status" -eq 0 ]
    grep -q '1 repo, 0 AUR: linux' "$TEST_TMP/notified"
}

@test "a failed notify-send doesn't record the state, so it retries next run" {
    stub_updates 'linux 1-1 -> 2-1'
    stub_command notify-send 'exit 1'

    run "$SCRIPT"

    [ ! -f "$STATE" ]

    stub_command notify-send 'printf "%s\n" "$*" >> "$TEST_TMP/notified"; exit 0'
    run "$SCRIPT"
    [ "$(notified_count)" -eq 1 ]
}

@test "more than eight updates are truncated in the body with an ellipsis" {
    local repo="" i
    for i in 1 2 3 4 5 6 7 8 9 10; do repo+="pkg$i 1-1 -> 2-1"$'\n'; done
    stub_updates "${repo%$'\n'}"

    run "$SCRIPT"

    grep -q '10 update(s) available' "$TEST_TMP/notified"
    grep -q 'pkg1, pkg2, pkg3, ' "$TEST_TMP/notified"
    grep -q 'pkg8, \.\.\.' "$TEST_TMP/notified"
    ! grep -q 'pkg9' "$TEST_TMP/notified"
}
