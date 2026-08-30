#!/usr/bin/env bats
#
# Tests for lib/profile.sh's glb_install_nvim_config: the per-profile
# nvim-config.txt gate, clone / pull / backup behavior, the --dry-run
# path, and the GLB_NVIM_CONFIG_REPO override. git and nvim are stubbed
# - a real clone against the private repo is covered by manual
# verification, not this suite.

load 'test_helper'

REPO_URL="git@github.com:ggregoro/nvim-config.git"

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/profile.sh"

    PROFILE_DIR="$TEST_TMP/profile"
    mkdir -p "$PROFILE_DIR"

    NVIM_DIR="$HOME/.config/nvim"

    # nvim present by default; individual tests can undo this.
    stub_command nvim 'exit 0'

    # A git stub that covers the three subcommands the function uses:
    #   git -C <dir> remote get-url origin   -> prints $STUB_GIT_ORIGIN
    #   git -C <dir> pull --ff-only --quiet  -> exit $STUB_GIT_PULL_RC
    #   git clone --quiet <url> <dest>       -> mkdir <dest>, drop an
    #                                           init.lua unless STUB_GIT_CLONE_BARE
    export STUB_GIT_ORIGIN=""
    export STUB_GIT_PULL_RC=0
    export STUB_GIT_CLONE_BARE=""
    stub_command git '
        if [ "$1" = "-C" ]; then
            sub="$3"
            if [ "$sub" = "remote" ]; then printf "%s\n" "$STUB_GIT_ORIGIN"; exit 0; fi
            if [ "$sub" = "pull" ]; then exit "$STUB_GIT_PULL_RC"; fi
            exit 0
        fi
        if [ "$1" = "clone" ]; then
            dest="${@: -1}"
            mkdir -p "$dest/.git"
            [ -n "$STUB_GIT_CLONE_BARE" ] || printf "-- config --\n" > "$dest/init.lua"
            exit 0
        fi
        exit 0
    '
}

teardown() {
    glb_teardown_sandbox
}

write_repo_file() {
    printf '%s\n' "$1" > "$PROFILE_DIR/nvim-config.txt"
}

@test "no-op when the profile has no nvim-config.txt" {
    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ ! -e "$NVIM_DIR" ]
}

@test "warns and no-ops when nvim-config.txt has no URL (only comments)" {
    write_repo_file "# just a comment"

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"no repo URL"* ]]
    [ ! -e "$NVIM_DIR" ]
}

@test "clones the repo when ~/.config/nvim doesn't exist yet" {
    write_repo_file "$REPO_URL"

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"nvim-config cloned"* ]]
    [ -f "$NVIM_DIR/init.lua" ]
}

@test "reports failure when the clone produces no init.lua" {
    write_repo_file "$REPO_URL"
    export STUB_GIT_CLONE_BARE=1

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to clone nvim-config"* ]]
}

@test "pulls in place when ~/.config/nvim is already a clone of the same repo" {
    write_repo_file "$REPO_URL"
    mkdir -p "$NVIM_DIR/.git"
    printf 'old\n' > "$NVIM_DIR/init.lua"
    export STUB_GIT_ORIGIN="$REPO_URL"

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"nvim-config updated"* ]]
    [ ! -e "$NVIM_DIR.glb-backup" ]
}

@test "warns but does not fail when an in-place pull fails" {
    write_repo_file "$REPO_URL"
    mkdir -p "$NVIM_DIR/.git"
    export STUB_GIT_ORIGIN="$REPO_URL"
    export STUB_GIT_PULL_RC=1

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"pull failed"* ]]
}

@test "backs up a pre-existing non-clone ~/.config/nvim exactly once, then clones" {
    write_repo_file "$REPO_URL"
    mkdir -p "$NVIM_DIR"
    printf 'hand-rolled\n' > "$NVIM_DIR/init.vim"

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Backing up existing ~/.config/nvim"* ]]
    [ -f "$NVIM_DIR.glb-backup/init.vim" ]
    [ -f "$NVIM_DIR/init.lua" ]
}

@test "does not clobber an existing .glb-backup on a later run" {
    write_repo_file "$REPO_URL"
    mkdir -p "$NVIM_DIR.glb-backup"
    printf 'the real original\n' > "$NVIM_DIR.glb-backup/init.vim"
    mkdir -p "$NVIM_DIR"
    printf 'a stale intermediate\n' > "$NVIM_DIR/init.vim"

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"nvim-config cloned"* ]]
    run cat "$NVIM_DIR.glb-backup/init.vim"
    [[ "$output" == "the real original" ]]
}

@test "GLB_NVIM_CONFIG_REPO overrides the URL in nvim-config.txt" {
    write_repo_file "$REPO_URL"
    mkdir -p "$NVIM_DIR/.git"
    # The dir is a clone of the file's URL, but the override points
    # elsewhere - so it must NOT be treated as an own-clone (no pull),
    # it must back up and re-clone from the override.
    export STUB_GIT_ORIGIN="$REPO_URL"
    export GLB_NVIM_CONFIG_REPO="git@github.com:someone/other-nvim.git"

    run glb_install_nvim_config "$PROFILE_DIR"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Backing up existing ~/.config/nvim"* ]]
    [ -f "$NVIM_DIR/init.lua" ]
}

@test "dry-run: would-clone message, nothing created" {
    write_repo_file "$REPO_URL"

    run glb_install_nvim_config "$PROFILE_DIR" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would clone nvim-config"* ]]
    [ ! -e "$NVIM_DIR" ]
}

@test "dry-run: would-pull message when already the right clone" {
    write_repo_file "$REPO_URL"
    mkdir -p "$NVIM_DIR/.git"
    export STUB_GIT_ORIGIN="$REPO_URL"

    run glb_install_nvim_config "$PROFILE_DIR" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would pull latest nvim-config"* ]]
}

@test "dry-run: would-back-up message when a foreign ~/.config/nvim is present" {
    write_repo_file "$REPO_URL"
    mkdir -p "$NVIM_DIR"

    run glb_install_nvim_config "$PROFILE_DIR" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would back up ~/.config/nvim"* ]]
    [ ! -e "$NVIM_DIR.glb-backup" ]
}

@test "no-op with a dry-run note when nvim isn't installed" {
    write_repo_file "$REPO_URL"
    # An empty PATH - no nvim, no git. The nvim-absent branch returns
    # before it needs either external command (the file read is pure
    # bash), so this exercises it deterministically even on a host that
    # has a real nvim on its own PATH.
    mkdir -p "$TEST_TMP/emptybin"
    PATH="$TEST_TMP/emptybin" run "$GLB_REAL_BASH" -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/profile.sh'
        glb_install_nvim_config '$PROFILE_DIR' --dry-run
    "

    [ "$status" -eq 0 ]
    [[ "$output" == *"nvim isn't installed"* ]]
}

@test "undo restores ~/.config/nvim from its .glb-backup" {
    mkdir -p "$NVIM_DIR.glb-backup"
    printf 'original\n' > "$NVIM_DIR.glb-backup/init.vim"
    mkdir -p "$NVIM_DIR/.git"
    printf 'cloned lazyvim\n' > "$NVIM_DIR/init.lua"

    run glb_undo_restore

    [ "$status" -eq 0 ]
    [[ "$output" == *"Restored ~/.config/nvim from backup"* ]]
    [ -f "$NVIM_DIR/init.vim" ]
    [ ! -e "$NVIM_DIR/init.lua" ]
    [ ! -e "$NVIM_DIR.glb-backup" ]
}
