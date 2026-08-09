#!/usr/bin/env bats
#
# Tests for lib/profile.sh's glb_apply_manifest: `glb restore
# --from-manifest <path>` applies a profile-shaped directory living
# anywhere on disk (not committed to profiles/) the same way
# glb_apply_profile applies a profile.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/extras.sh"
    source "$GLB_ROOT/lib/completions.sh"
    source "$GLB_ROOT/lib/profile.sh"

    INSTALL_LOG="$TEST_TMP/installed.log"
    : > "$INSTALL_LOG"
    ALREADY_INSTALLED=""
    FAIL_PACKAGES=""

    # Test doubles standing in for lib/package.sh, so these tests
    # exercise glb_apply_manifest's own logic in isolation - same
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
    # glb_apply_manifest calls unconditionally and which otherwise hit
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

@test "glb_apply_manifest fails cleanly for a nonexistent path" {
    run glb_apply_manifest "$TEST_TMP/does-not-exist"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Manifest directory not found: $TEST_TMP/does-not-exist"* ]]
}

@test "glb_apply_manifest errors when no path is given" {
    run glb_apply_manifest ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: glb restore --from-manifest"* ]]
}

@test "glb_apply_manifest applies packages then dotfiles for a real external directory" {
    local manifest="$TEST_TMP/my-manifest"
    mkdir -p "$manifest/dotfiles"
    printf 'git\n' > "$manifest/packages.txt"
    echo 'x' > "$manifest/dotfiles/.gitconfig"

    run glb_apply_manifest "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Applying manifest: $manifest"* ]]
    [[ "$output" == *"Manifest applied: $manifest"* ]]
    run cat "$INSTALL_LOG"
    [ "$output" = "git" ]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb_apply_manifest returns failure and reports errors when a package fails to install" {
    local manifest="$TEST_TMP/my-manifest"
    mkdir -p "$manifest/dotfiles"
    printf 'git\nzsh\n' > "$manifest/packages.txt"
    FAIL_PACKAGES="zsh"

    run glb_apply_manifest "$manifest"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Manifest applied with errors: $manifest"* ]]
}

@test "glb_apply_manifest --dry-run installs nothing and links nothing" {
    local manifest="$TEST_TMP/my-manifest"
    mkdir -p "$manifest/dotfiles"
    printf 'git\n' > "$manifest/packages.txt"
    echo 'x' > "$manifest/dotfiles/.gitconfig"

    run glb_apply_manifest "$manifest" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run for manifest: $manifest"* ]]
    [[ "$output" == *"Would install: git"* ]]
    [[ "$output" == *"Would link ~/.gitconfig"* ]]
    [[ "$output" == *"Dry run complete: $manifest"* ]]
    run cat "$INSTALL_LOG"
    [ "$output" = "" ]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb_apply_manifest works fine when the directory has no extras.txt" {
    local manifest="$TEST_TMP/my-manifest"
    mkdir -p "$manifest/dotfiles"
    printf 'git\n' > "$manifest/packages.txt"

    run glb_apply_manifest "$manifest"

    [ "$status" -eq 0 ]
}

@test "glb_apply_manifest works from a deeply nested arbitrary path" {
    local manifest="$TEST_TMP/some/deeply/nested/path/outside-glb-root"
    mkdir -p "$manifest/dotfiles"
    printf 'git\n' > "$manifest/packages.txt"

    run glb_apply_manifest "$manifest"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Manifest applied: $manifest"* ]]
}
