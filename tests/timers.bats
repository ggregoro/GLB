#!/usr/bin/env bats
#
# Tests for lib/timers.sh: timers.txt parsing and enabling user systemd
# timers. systemctl is always stubbed - nothing here touches the real
# user session. Also checks the shipped `default` profile's timer is
# wired up consistently (unit files exist, pacman-only gating).

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/detect.sh"
    source "$GLB_ROOT/lib/package.sh"
    source "$GLB_ROOT/lib/timers.sh"

    # Deterministic package manager, regardless of the host's.
    glb_detect_package_manager() { printf 'pacman\n'; }

    PDIR="$TEST_TMP/profile"
    mkdir -p "$PDIR"
    UNIT_DIR="$HOME/.config/systemd/user"
    mkdir -p "$UNIT_DIR"
}

teardown() {
    glb_teardown_sandbox
}

# Records every systemctl call. STUB_ENABLED=1 makes is-enabled succeed,
# STUB_NO_SESSION=1 makes show-environment fail.
stub_systemctl() {
    stub_command systemctl 'echo "systemctl $*" >> "$TEST_TMP/calls"
        case "$2" in
            show-environment) [ "${STUB_NO_SESSION:-0}" = 1 ] && exit 1; exit 0 ;;
            is-enabled)       [ "${STUB_ENABLED:-0}" = 1 ] && exit 0; exit 1 ;;
            *)                exit 0 ;;
        esac'
}

# --- timers.txt parsing ----------------------------------------------

@test "missing timers.txt is a silent no-op" {
    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "skips blank lines and comment-only lines" {
    printf '\n# a comment\n   \n' > "$PDIR/timers.txt"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "strips a trailing comment after the unit" {
    printf 'foo.timer   # why it exists\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    grep -q -- '--user enable --now foo.timer' "$TEST_TMP/calls"
}

# --- package-manager gating -------------------------------------------

@test "skips a timer restricted to a different package manager" {
    printf 'foo.timer apt\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping timer foo.timer: only enabled on apt"* ]]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "enables a timer restricted to the matching package manager" {
    printf 'foo.timer pacman\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Enabled timer: foo.timer"* ]]
}

@test "a timer with no package manager listed is enabled everywhere" {
    glb_detect_package_manager() { printf 'zypper\n'; }
    printf 'foo.timer\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Enabled timer: foo.timer"* ]]
}

# --- dry run -----------------------------------------------------------

@test "dry-run announces the timer without calling systemctl" {
    printf 'foo.timer pacman\n' > "$PDIR/timers.txt"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would enable timer: foo.timer"* ]]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "dry-run still honours the package-manager restriction" {
    printf 'foo.timer apt\n' > "$PDIR/timers.txt"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR" "--dry-run"

    [[ "$output" == *"Skipping timer foo.timer"* ]]
    [[ "$output" != *"Would enable"* ]]
}

# --- enabling -----------------------------------------------------------

@test "enable: reloads the user manager, then enables and starts the unit" {
    printf 'foo.timer\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    grep -q -- '--user daemon-reload' "$TEST_TMP/calls"
    grep -q -- '--user enable --now foo.timer' "$TEST_TMP/calls"
}

@test "enable: an already-enabled timer is left alone" {
    printf 'foo.timer\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_systemctl

    STUB_ENABLED=1 run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already enabled: foo.timer"* ]]
    ! grep -q -- 'enable --now' "$TEST_TMP/calls"
}

# --- can't enable: warn, don't fail the restore ---------------------

@test "no reachable user session warns with the manual command, restore still succeeds" {
    printf 'foo.timer\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_systemctl

    STUB_NO_SESSION=1 run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"no systemd user session"* ]]
    [[ "$output" == *"systemctl --user enable --now foo.timer"* ]]
    ! grep -q -- 'enable --now' "$TEST_TMP/calls"
}

@test "a missing unit file warns instead of enabling" {
    printf 'foo.timer\n' > "$PDIR/timers.txt"
    stub_systemctl

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"foo.timer isn't there"* ]]
    ! grep -q -- 'enable --now' "$TEST_TMP/calls"
}

@test "no systemctl at all: the enable helper warns and reports failure" {
    touch "$UNIT_DIR/foo.timer"

    # Called directly rather than through glb_apply_profile_timers: with
    # PATH emptied to hide the host's systemctl, the parser's own xargs
    # would vanish too. The helper itself only needs shell builtins.
    PATH="$STUB_BIN" run _glb_enable_user_timer foo.timer

    [ "$status" -ne 0 ]
    [[ "$output" == *"systemctl not found"* ]]
}

@test "a failing enable warns with the manual command and does not fail the restore" {
    printf 'foo.timer\n' > "$PDIR/timers.txt"
    touch "$UNIT_DIR/foo.timer"
    stub_command systemctl 'case "$2" in
            show-environment|daemon-reload) exit 0 ;;
            is-enabled) exit 1 ;;
            enable) exit 1 ;;
        esac'

    run glb_apply_profile_timers "$PDIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Could not enable foo.timer"* ]]
}

# --- the shipped default profile -----------------------------------------

@test "default profile: every timer in timers.txt has its unit file in dotfiles" {
    local units="$GLB_REPO_ROOT/profiles/default/dotfiles/.config/systemd/user"
    local line unit

    while IFS= read -r line; do
        line="${line%%#*}"; line="$(echo "$line" | xargs)"
        [[ -z "$line" ]] && continue
        read -r unit _ <<< "$line"
        [ -f "$units/$unit" ]
        # A timer activates the same-named service.
        [ -f "$units/${unit%.timer}.service" ]
    done < "$GLB_REPO_ROOT/profiles/default/timers.txt"
}

@test "default profile: the update-check timer is enabled on pacman only" {
    grep -Eq '^update-check\.timer[[:space:]]+pacman([[:space:]]|$)' \
        "$GLB_REPO_ROOT/profiles/default/timers.txt"
}

@test "default profile: the notifier script ships executable" {
    [ -x "$GLB_REPO_ROOT/profiles/default/dotfiles/.local/bin/update-check-notify" ]
}

@test "default profile: pacman-contrib is listed and skipped on apt/dnf/zypper but not pacman" {
    grep -q '^pacman-contrib' "$GLB_REPO_ROOT/profiles/default/packages.txt"

    local mgr
    for mgr in apt dnf zypper; do
        glb_detect_package_manager() { printf '%s\n' "$mgr"; }
        run glb_package_skip_reason pacman-contrib
        [ "$status" -eq 0 ]
    done

    glb_detect_package_manager() { printf 'pacman\n'; }
    run glb_package_skip_reason pacman-contrib
    [ "$status" -ne 0 ]
}
