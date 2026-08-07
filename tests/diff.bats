#!/usr/bin/env bats
#
# Tests for lib/diff.sh: `glb diff <a> <b>` compares two
# profile-shaped directories (a profile, a snapshot, or either
# combination) for package and dotfile drift. See
# docs/design/state-export-import.md.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/diff.sh"
}

teardown() {
    glb_teardown_sandbox
}

# --- _glb_diff_resolve_dir --------------------------------------------------

@test "resolve_dir finds a profile by name" {
    mkdir -p "$GLB_ROOT/profiles/default"
    run _glb_diff_resolve_dir default
    [ "$status" -eq 0 ]
    [ "$output" = "$GLB_ROOT/profiles/default" ]
}

@test "resolve_dir falls back to a snapshot by name when no profile matches" {
    mkdir -p "$GLB_ROOT/snapshots/host-2026-08-07"
    run _glb_diff_resolve_dir host-2026-08-07
    [ "$status" -eq 0 ]
    [ "$output" = "$GLB_ROOT/snapshots/host-2026-08-07" ]
}

@test "resolve_dir prefers a profile over a same-named snapshot" {
    mkdir -p "$GLB_ROOT/profiles/default" "$GLB_ROOT/snapshots/default"
    run _glb_diff_resolve_dir default
    [ "$output" = "$GLB_ROOT/profiles/default" ]
}

@test "resolve_dir fails when the name matches neither a profile nor a snapshot" {
    run _glb_diff_resolve_dir nope
    [ "$status" -eq 1 ]
}

# --- _glb_diff_read_packages -------------------------------------------------

@test "read_packages strips comments, blank lines, and dedupes" {
    mkdir -p "$TEST_TMP/d"
    printf '# comment\n\ngit\nzsh   # shell\ngit\n  \n' > "$TEST_TMP/d/packages.txt"

    run _glb_diff_read_packages "$TEST_TMP/d"
    [ "$output" = "$(printf 'git\nzsh')" ]
}

@test "read_packages returns nothing when packages.txt is absent" {
    mkdir -p "$TEST_TMP/d"
    run _glb_diff_read_packages "$TEST_TMP/d"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

# --- _glb_diff_packages -----------------------------------------------------

@test "diff_packages reports nothing and returns 0 when package lists match" {
    mkdir -p "$TEST_TMP/a" "$TEST_TMP/b"
    printf 'git\nzsh\n' > "$TEST_TMP/a/packages.txt"
    printf 'zsh\ngit\n' > "$TEST_TMP/b/packages.txt"

    run _glb_diff_packages "$TEST_TMP/a" A "$TEST_TMP/b" B
    [ "$status" -eq 0 ]
    [[ "$output" == *"no package differences"* ]]
}

@test "diff_packages reports packages only in each side and returns 1" {
    mkdir -p "$TEST_TMP/a" "$TEST_TMP/b"
    printf 'git\nneovim\nhtop\n' > "$TEST_TMP/a/packages.txt"
    printf 'git\nranger\n' > "$TEST_TMP/b/packages.txt"

    run _glb_diff_packages "$TEST_TMP/a" A "$TEST_TMP/b" B
    [ "$status" -eq 1 ]
    [[ "$output" == *"+ only in A: htop, neovim"* ]]
    [[ "$output" == *"- only in B: ranger"* ]]
}

# --- _glb_diff_dotfiles ------------------------------------------------------

@test "diff_dotfiles reports nothing and returns 0 when dotfiles match exactly" {
    mkdir -p "$TEST_TMP/a/dotfiles/.config" "$TEST_TMP/b/dotfiles/.config"
    printf 'x\n' > "$TEST_TMP/a/dotfiles/.bashrc"
    printf 'x\n' > "$TEST_TMP/b/dotfiles/.bashrc"
    printf 'y\n' > "$TEST_TMP/a/dotfiles/.config/starship.toml"
    printf 'y\n' > "$TEST_TMP/b/dotfiles/.config/starship.toml"

    run _glb_diff_dotfiles "$TEST_TMP/a" A "$TEST_TMP/b" B
    [ "$status" -eq 0 ]
    [[ "$output" == *"no dotfile differences"* ]]
}

@test "diff_dotfiles reports changed content, and files only on one side" {
    mkdir -p "$TEST_TMP/a/dotfiles" "$TEST_TMP/b/dotfiles"
    printf 'a content\n' > "$TEST_TMP/a/dotfiles/.bashrc"
    printf 'b content\n' > "$TEST_TMP/b/dotfiles/.bashrc"
    printf 'only a\n' > "$TEST_TMP/a/dotfiles/.zshrc"
    printf 'only b\n' > "$TEST_TMP/b/dotfiles/.gitconfig"

    run _glb_diff_dotfiles "$TEST_TMP/a" A "$TEST_TMP/b" B
    [ "$status" -eq 1 ]
    [[ "$output" == *"~ changed: ~/.bashrc"* ]]
    [[ "$output" == *"+ only in A: ~/.zshrc"* ]]
    [[ "$output" == *"- only in B: ~/.gitconfig"* ]]
}

# --- glb_diff_snapshot (full command) ---------------------------------------

@test "diff_snapshot errors when an argument is missing" {
    run glb_diff_snapshot default ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage: glb diff"* ]]
}

@test "diff_snapshot errors when a name resolves to neither a profile nor a snapshot" {
    mkdir -p "$GLB_ROOT/profiles/default"
    run glb_diff_snapshot default nope
    [ "$status" -eq 1 ]
    [[ "$output" == *"Not found"* ]]
    [[ "$output" == *"nope"* ]]
}

@test "diff_snapshot returns 0 and reports no differences for two identical profiles" {
    mkdir -p "$GLB_ROOT/profiles/a/dotfiles" "$GLB_ROOT/profiles/b/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/a/packages.txt"
    printf 'git\n' > "$GLB_ROOT/profiles/b/packages.txt"
    printf 'x\n' > "$GLB_ROOT/profiles/a/dotfiles/.bashrc"
    printf 'x\n' > "$GLB_ROOT/profiles/b/dotfiles/.bashrc"

    run glb_diff_snapshot a b
    [ "$status" -eq 0 ]
    [[ "$output" == *"Diff: a vs b"* ]]
    [[ "$output" == *"no package differences"* ]]
    [[ "$output" == *"no dotfile differences"* ]]
}

@test "diff_snapshot returns 1 and reports both package and dotfile drift" {
    mkdir -p "$GLB_ROOT/profiles/a/dotfiles" "$GLB_ROOT/profiles/b/dotfiles"
    printf 'git\nneovim\n' > "$GLB_ROOT/profiles/a/packages.txt"
    printf 'git\n' > "$GLB_ROOT/profiles/b/packages.txt"
    printf 'a version\n' > "$GLB_ROOT/profiles/a/dotfiles/.bashrc"
    printf 'b version\n' > "$GLB_ROOT/profiles/b/dotfiles/.bashrc"

    run glb_diff_snapshot a b
    [ "$status" -eq 1 ]
    [[ "$output" == *"+ only in a: neovim"* ]]
    [[ "$output" == *"~ changed: ~/.bashrc"* ]]
}

@test "diff_snapshot can compare a snapshot against a profile" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles" "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles"
    printf 'git\nhtop\n' > "$GLB_ROOT/profiles/default/packages.txt"
    printf 'git\n' > "$GLB_ROOT/snapshots/host-2026-08-07/packages.txt"

    run glb_diff_snapshot host-2026-08-07 default
    [ "$status" -eq 1 ]
    [[ "$output" == *"Diff: host-2026-08-07 vs default"* ]]
    [[ "$output" == *"- only in default: htop"* ]]
}
