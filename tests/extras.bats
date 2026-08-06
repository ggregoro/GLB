#!/usr/bin/env bats
#
# Tests for lib/extras.sh: extras.txt parsing and the curl/flatpak
# install paths, including pause/resume on failure via
# glb_prompt_manual_step (lib/package.sh). curl/sh/flatpak are always
# stubbed - nothing here touches the real network or installs
# anything real.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/package.sh"
    source "$GLB_ROOT/lib/extras.sh"
}

teardown() {
    glb_teardown_sandbox
}

# --- extras.txt parsing -----------------------------------------------

@test "missing extras.txt is a silent no-op" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"

    run glb_apply_profile_extras "$pdir"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "skips blank lines and comment-only lines" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    stub_command fresh 'exit 0'
    printf '# a comment\n\ncurl fresh https://example.test/install.sh\n   \n' > "$pdir/extras.txt"

    run glb_apply_profile_extras "$pdir"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed: fresh"* ]]
}

@test "dry-run: announces what would install without calling curl/sh" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'curl fresh https://example.test/install.sh\n' > "$pdir/extras.txt"

    run glb_apply_profile_extras "$pdir" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would install: fresh (via curl)"* ]]
}

@test "dry-run: still reports already-installed extras as such, not as a would-install" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    stub_command fresh 'exit 0'
    printf 'curl fresh https://example.test/install.sh\n' > "$pdir/extras.txt"

    run glb_apply_profile_extras "$pdir" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Already installed: fresh"* ]]
    [[ "$output" != *"Would install"* ]]
}

@test "unknown method is logged as a failure" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'appimage thing https://example.test/thing.AppImage\n' > "$pdir/extras.txt"

    run glb_apply_profile_extras "$pdir"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown extras method: appimage"* ]]
    [[ "$output" == *"Failed to install: thing"* ]]
}

# --- curl method ---------------------------------------------------------

@test "curl: skips install when the binary is already on PATH" {
    stub_command fresh 'exit 0'
    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_extra_installed curl fresh https://example.test/install.sh
    "
    [ "$status" -eq 0 ]
}

@test "curl: installs by piping the script to sh when not already installed" {
    stub_command curl 'echo "curl $*" >> "$TEST_TMP/calls"; exit 0'
    stub_command sh 'echo "sh ran" >> "$TEST_TMP/calls"; exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra curl fresh https://example.test/install.sh
    "
    [ "$status" -eq 0 ]
    grep -q "curl -fsSL https://example.test/install.sh" "$TEST_TMP/calls"
    grep -q "sh ran" "$TEST_TMP/calls"
}

@test "curl: pauses on failure, prints the exact command, and succeeds once confirmed" {
    stub_command curl 'exit 0'
    stub_command sh 'exit 1'
    stub_command fresh 'exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra curl fresh https://example.test/install.sh <<< ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Run this yourself"* ]]
    [[ "$output" == *"curl -fsSL https://example.test/install.sh | sh"* ]]
    [[ "$output" == *"Confirmed installed after manual step: fresh"* ]]
}

@test "curl: returns failure when the user skips the manual step" {
    stub_command curl 'exit 1'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra curl fresh https://example.test/install.sh <<< 's'
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"Skipped: install fresh"* ]]
}

@test "curl: a failed curl isn't masked by sh exiting 0 on empty input" {
    stub_command curl 'exit 7'
    stub_command sh 'exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra curl fresh https://example.test/install.sh </dev/null
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"Could not install fresh automatically"* ]]
}

# --- flatpak method --------------------------------------------------------

@test "flatpak: skips install when flatpak info reports it present" {
    stub_command flatpak 'case "$1" in info) exit 0 ;; esac'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_extra_installed flatpak wezterm org.wezfurlong.wezterm
    "
    [ "$status" -eq 0 ]
}

@test "flatpak: ensures the flathub remote then installs the app id" {
    stub_command flatpak 'echo "flatpak $*" >> "$TEST_TMP/calls"; exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra flatpak wezterm org.wezfurlong.wezterm
    "
    [ "$status" -eq 0 ]
    grep -q "remote-add --if-not-exists flathub" "$TEST_TMP/calls"
    grep -q "install -y flathub org.wezfurlong.wezterm" "$TEST_TMP/calls"
}

@test "flatpak: pauses on failure, prints the exact command, and succeeds once confirmed" {
    stub_command flatpak 'case "$1" in
        remote-add) exit 0 ;;
        install) exit 1 ;;
        info) exit 0 ;;
    esac'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra flatpak wezterm org.wezfurlong.wezterm <<< ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"flatpak install -y flathub org.wezfurlong.wezterm"* ]]
    [[ "$output" == *"Confirmed installed after manual step: wezterm"* ]]
}

@test "flatpak: returns failure when the user skips the manual step" {
    stub_command flatpak 'case "$1" in
        remote-add) exit 0 ;;
        install) exit 1 ;;
    esac'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra flatpak wezterm org.wezfurlong.wezterm <<< 's'
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"Skipped: install wezterm"* ]]
}
