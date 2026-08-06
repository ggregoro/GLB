#!/usr/bin/env bats
#
# Tests for lib/profile.sh: packages.txt parsing, dotfiles symlinking
# and backup behavior, and the glb_apply_profile / glb_list_profiles
# entry points.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/extras.sh"
    source "$GLB_ROOT/lib/profile.sh"

    INSTALL_LOG="$TEST_TMP/installed.log"
    : > "$INSTALL_LOG"
    ALREADY_INSTALLED=""
    FAIL_PACKAGES=""

    # Test doubles standing in for lib/package.sh, so these tests
    # exercise profile.sh's own logic in isolation.
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
    # glb_apply_profile calls unconditionally and which otherwise hit
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

# --- packages.txt parsing -------------------------------------------------

@test "installs each package listed in packages.txt" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'git\nzsh\n' > "$pdir/packages.txt"

    glb_apply_profile_packages "$pdir"

    run cat "$INSTALL_LOG"
    [ "$output" = "$(printf 'git\nzsh')" ]
}

@test "skips blank lines and comment-only lines" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf '# a comment\n\ngit\n   \n' > "$pdir/packages.txt"

    glb_apply_profile_packages "$pdir"

    run cat "$INSTALL_LOG"
    [ "$output" = "git" ]
}

@test "strips trailing inline comments and surrounding whitespace" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf '  git   # version control\n' > "$pdir/packages.txt"

    glb_apply_profile_packages "$pdir"

    run cat "$INSTALL_LOG"
    [ "$output" = "git" ]
}

@test "does not reinstall a package that is already installed" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'git\nzsh\n' > "$pdir/packages.txt"
    ALREADY_INSTALLED="git"

    glb_apply_profile_packages "$pdir"

    run cat "$INSTALL_LOG"
    [ "$output" = "zsh" ]
}

@test "handles a packages.txt with no trailing newline on the last line" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'git\nzsh' > "$pdir/packages.txt"

    glb_apply_profile_packages "$pdir"

    run cat "$INSTALL_LOG"
    [ "$output" = "$(printf 'git\nzsh')" ]
}

@test "warns and does nothing when packages.txt is missing" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"

    run glb_apply_profile_packages "$pdir"

    [ "$status" -eq 0 ]
    [[ "$output" == *"No packages.txt found"* ]]
    run cat "$INSTALL_LOG"
    [ "$output" = "" ]
}

@test "reports failure and continues installing remaining packages when one fails" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'git\nzsh\ntmux\n' > "$pdir/packages.txt"
    FAIL_PACKAGES="zsh"

    run glb_apply_profile_packages "$pdir"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to install: zsh"* ]]
    [[ "$output" == *"Failed to install 1 package(s): zsh"* ]]
    run cat "$INSTALL_LOG"
    [ "$output" = "$(printf 'git\ntmux')" ]
}

# --- dotfiles symlinking ---------------------------------------------------

@test "symlinks a flat dotfile into HOME" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles"
    echo 'test content' > "$pdir/dotfiles/.zshrc"

    glb_apply_profile_dotfiles "$pdir"

    [ -L "$HOME/.zshrc" ]
    [ "$(readlink -f "$HOME/.zshrc")" = "$(readlink -f "$pdir/dotfiles/.zshrc")" ]
}

@test "symlinks a nested dotfile, creating parent directories" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles/.config/nvim"
    echo 'nvim config' > "$pdir/dotfiles/.config/nvim/init.vim"

    glb_apply_profile_dotfiles "$pdir"

    [ -L "$HOME/.config/nvim/init.vim" ]
}

@test "backs up an existing regular file before symlinking" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles"
    echo 'new content' > "$pdir/dotfiles/.bashrc"
    echo 'old content' > "$HOME/.bashrc"

    glb_apply_profile_dotfiles "$pdir"

    [ -L "$HOME/.bashrc" ]
    [ -f "$HOME/.bashrc.glb-backup" ]
    [ "$(cat "$HOME/.bashrc.glb-backup")" = "old content" ]
}

@test "does not touch a dotfile that is already correctly linked" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles"
    echo 'content' > "$pdir/dotfiles/.zshrc"
    ln -s "$pdir/dotfiles/.zshrc" "$HOME/.zshrc"

    run glb_apply_profile_dotfiles "$pdir"

    [[ "$output" == *"Already linked"* ]]
    [ ! -e "$HOME/.zshrc.glb-backup" ]
}

@test "ignores .gitkeep files" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles"
    touch "$pdir/dotfiles/.gitkeep"

    glb_apply_profile_dotfiles "$pdir"

    [ ! -e "$HOME/.gitkeep" ]
}

@test "warns and does nothing when dotfiles directory is missing" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"

    run glb_apply_profile_dotfiles "$pdir"

    [ "$status" -eq 0 ]
    [[ "$output" == *"No dotfiles directory found"* ]]
}

@test "reports failure when a destination directory cannot be created" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles/.config/app"
    echo 'content' > "$pdir/dotfiles/.config/app/config.yml"

    mkdir -p "$HOME/.config"
    chmod 555 "$HOME/.config"

    run glb_apply_profile_dotfiles "$pdir"

    chmod 755 "$HOME/.config"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to create directory for ~/.config/app/config.yml"* ]]
}

@test "reports failure when backing up an existing file is not permitted" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles/.config"
    echo 'new' > "$pdir/dotfiles/.config/app.conf"

    mkdir -p "$HOME/.config"
    echo 'old' > "$HOME/.config/app.conf"
    chmod 555 "$HOME/.config"

    run glb_apply_profile_dotfiles "$pdir"

    chmod 755 "$HOME/.config"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to back up ~/.config/app.conf"* ]]
    [ ! -L "$HOME/.config/app.conf" ]
}

@test "reports failure when creating a new symlink is not permitted" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles/.config"
    echo 'content' > "$pdir/dotfiles/.config/app.conf"

    mkdir -p "$HOME/.config"
    chmod 555 "$HOME/.config"

    run glb_apply_profile_dotfiles "$pdir"

    chmod 755 "$HOME/.config"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to link ~/.config/app.conf"* ]]
}

@test "backs up a broken symlink found at the destination" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir/dotfiles"
    echo 'content' > "$pdir/dotfiles/.zshrc"
    ln -s "/nonexistent/target" "$HOME/.zshrc"

    glb_apply_profile_dotfiles "$pdir"

    [ -L "$HOME/.zshrc" ]
    [ "$(readlink -f "$HOME/.zshrc")" = "$(readlink -f "$pdir/dotfiles/.zshrc")" ]
    [ -L "$HOME/.zshrc.glb-backup" ]
}

# --- glb_apply_profile / glb_list_profiles ---------------------------------

@test "glb_apply_profile fails cleanly for an unknown profile" {
    run glb_apply_profile "does-not-exist"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile not found"* ]]
}

@test "glb_apply_profile applies packages then dotfiles for a valid profile" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/work/packages.txt"
    echo 'x' > "$GLB_ROOT/profiles/work/dotfiles/.gitconfig"

    glb_apply_profile "work"

    run cat "$INSTALL_LOG"
    [ "$output" = "git" ]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb_apply_profile returns failure and reports errors when a package fails to install" {
    mkdir -p "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\nzsh\n' > "$GLB_ROOT/profiles/work/packages.txt"
    FAIL_PACKAGES="zsh"

    run glb_apply_profile "work"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile applied with errors: work"* ]]
}

@test "glb_apply_profile defaults to the 'default' profile when no name is given" {
    mkdir -p "$GLB_ROOT/profiles/default"
    run glb_apply_profile
    [ "$status" -eq 0 ]
}

@test "glb_list_profiles lists each profile directory" {
    mkdir -p "$GLB_ROOT/profiles/default" "$GLB_ROOT/profiles/work"
    run glb_list_profiles
    [[ "$output" == *"default"* ]]
    [[ "$output" == *"work"* ]]
}

@test "glb_list_profiles warns when the profiles directory is missing" {
    rm -rf "$GLB_ROOT/profiles"
    run glb_list_profiles
    [ "$status" -eq 0 ]
    [[ "$output" == *"No profiles directory found"* ]]
}
