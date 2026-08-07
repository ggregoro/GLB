#!/usr/bin/env bats
#
# Tests for lib/export.sh's glb_apply_snapshot: `glb restore
# --from-snapshot <name>` applies a snapshot (see glb_export_snapshot)
# the same way glb_apply_profile (lib/profile.sh) applies a profile.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/extras.sh"
    source "$GLB_ROOT/lib/completions.sh"
    source "$GLB_ROOT/lib/profile.sh"
    source "$GLB_ROOT/lib/export.sh"

    INSTALL_LOG="$TEST_TMP/installed.log"
    : > "$INSTALL_LOG"
    ALREADY_INSTALLED=""
    FAIL_PACKAGES=""

    # Test doubles standing in for lib/package.sh, so these tests
    # exercise glb_apply_snapshot's own logic in isolation - same
    # pattern as tests/profile.bats' glb_apply_profile tests.
    glb_package_installed() {
        [[ " $ALREADY_INSTALLED " == *" $1 "* ]]
    }
    glb_install_package() {
        if [[ " $FAIL_PACKAGES " == *" $1 "* ]]; then
            return 1
        fi
        echo "$1" >> "$INSTALL_LOG"
    }

    # Test doubles standing in for lib/prompt.sh / lib/plugins.sh, which
    # glb_apply_snapshot calls unconditionally and which otherwise hit
    # the real network (starship.rs, GitHub git clone).
    glb_install_starship() {
        return 0
    }
    glb_install_zsh_plugins() {
        return 0
    }
}

teardown() {
    glb_teardown_sandbox
}

@test "glb_apply_snapshot fails cleanly for a nonexistent snapshot" {
    run glb_apply_snapshot "does-not-exist"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Snapshot not found: does-not-exist"* ]]
}

@test "glb_apply_snapshot errors when no name is given" {
    run glb_apply_snapshot ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: glb restore --from-snapshot"* ]]
}

@test "glb_apply_snapshot applies packages then dotfiles for a real snapshot" {
    mkdir -p "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles"
    printf 'git\n' > "$GLB_ROOT/snapshots/host-2026-08-07/packages.txt"
    echo 'x' > "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles/.gitconfig"

    run glb_apply_snapshot "host-2026-08-07"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Applying snapshot: host-2026-08-07"* ]]
    [[ "$output" == *"Snapshot applied: host-2026-08-07"* ]]
    run cat "$INSTALL_LOG"
    [ "$output" = "git" ]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb_apply_snapshot returns failure and reports errors when a package fails to install" {
    mkdir -p "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles"
    printf 'git\nzsh\n' > "$GLB_ROOT/snapshots/host-2026-08-07/packages.txt"
    FAIL_PACKAGES="zsh"

    run glb_apply_snapshot "host-2026-08-07"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Snapshot applied with errors: host-2026-08-07"* ]]
}

@test "glb_apply_snapshot --dry-run installs nothing and links nothing" {
    mkdir -p "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles"
    printf 'git\n' > "$GLB_ROOT/snapshots/host-2026-08-07/packages.txt"
    echo 'x' > "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles/.gitconfig"

    run glb_apply_snapshot "host-2026-08-07" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run for snapshot: host-2026-08-07"* ]]
    [[ "$output" == *"Would install: git"* ]]
    [[ "$output" == *"Would link ~/.gitconfig"* ]]
    [[ "$output" == *"Dry run complete: host-2026-08-07"* ]]
    run cat "$INSTALL_LOG"
    [ "$output" = "" ]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb_apply_snapshot works fine when the snapshot has no extras.txt (snapshots never write one)" {
    mkdir -p "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles"
    printf 'git\n' > "$GLB_ROOT/snapshots/host-2026-08-07/packages.txt"

    run glb_apply_snapshot "host-2026-08-07"

    [ "$status" -eq 0 ]
}
