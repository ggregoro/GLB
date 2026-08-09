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

# --- manual-step pause interacting with the extras.txt loop ---------------
#
# Regression test for the same stdin-hijack bug fixed in
# glb_apply_profile_packages (see tests/profile.bats): the extras.txt loop
# had the identical `done < "$extras_file"` pattern, so a failed extra's
# manual-step `read -p` would silently consume the next extras.txt line
# instead of waiting on real stdin, and anything after a failed extra
# vanished without being processed.

@test "manual-step pause during extras.txt loop waits on real stdin, not the next extras.txt line" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    # "faketool" (not "fresh") deliberately - some real machines already
    # have a "fresh" binary on PATH (e.g. the fresh-editor apt package),
    # which would make it look "already installed" and never exercise
    # the failure/manual-step path this test is actually checking.
    printf 'curl faketool https://example.test/install.sh\nflatpak wezterm org.wezfurlong.wezterm\n' > "$pdir/extras.txt"

    stub_command curl 'exit 0'
    stub_command bash 'exit 1'
    stub_command flatpak 'case "$1" in
        remote-add) exit 0 ;;
        install) exit 0 ;;
        info) exit 1 ;;
    esac'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_apply_profile_extras '$pdir' <<< 's'
    "

    [ "$status" -eq 1 ]
    [[ "$output" == *"Skipped: install faketool"* ]]
    [[ "$output" == *"Installing wezterm via Flatpak"* ]]
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

@test "curl: installs by piping the script to bash when not already installed" {
    stub_command curl 'echo "curl $*" >> "$TEST_TMP/calls"; exit 0'
    stub_command bash 'echo "bash ran" >> "$TEST_TMP/calls"; exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra curl fresh https://example.test/install.sh
    "
    [ "$status" -eq 0 ]
    grep -q "curl -fsSL https://example.test/install.sh" "$TEST_TMP/calls"
    grep -q "bash ran" "$TEST_TMP/calls"
}

@test "curl: pauses on failure, prints the exact command, and succeeds once confirmed" {
    stub_command curl 'exit 0'
    stub_command bash 'exit 1'
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
    [[ "$output" == *"curl -fsSL https://example.test/install.sh | bash"* ]]
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

@test "curl: a failed curl isn't masked by bash exiting 0 on empty input" {
    stub_command curl 'exit 7'
    stub_command bash 'exit 0'

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

# --- font method -----------------------------------------------------------
#
# Regression coverage for a real gap found on a Linux Mint test VM: every
# machine tested before this one already had the Nerd Font pre-installed by
# hand, which masked the fact glb restore never actually installed it.

@test "font: not installed when the destination directory has no font files" {
    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_extra_installed font jetbrains-mono-nerd-font https://example.test/Font.zip
    "
    [ "$status" -ne 0 ]
}

@test "font: already installed when a font file exists in the destination directory" {
    mkdir -p "$HOME/.local/share/fonts/jetbrains-mono-nerd-font"
    touch "$HOME/.local/share/fonts/jetbrains-mono-nerd-font/JetBrainsMonoNerdFont-Regular.ttf"

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_extra_installed font jetbrains-mono-nerd-font https://example.test/Font.zip
    "
    [ "$status" -eq 0 ]
}

@test "dry-run: font extra announces would-install without downloading" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'font jetbrains-mono-nerd-font https://example.test/Font.zip\n' > "$pdir/extras.txt"

    run glb_apply_profile_extras "$pdir" "--dry-run"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Would install: jetbrains-mono-nerd-font (via font)"* ]]
}

@test "font: downloads and unzips into ~/.local/share/fonts/<name>, then refreshes the font cache" {
    stub_command curl 'echo "curl $*" >> "$TEST_TMP/calls"; touch "${@: -1}"; exit 0'
    stub_command unzip 'echo "unzip $*" >> "$TEST_TMP/calls"; mkdir -p "${@: -1}"; touch "${@: -1}/Fake-Regular.ttf"; exit 0'
    stub_command fc-cache 'echo "fc-cache $*" >> "$TEST_TMP/calls"; exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra font jetbrains-mono-nerd-font https://example.test/Font.zip
    "
    [ "$status" -eq 0 ]
    [ -f "$HOME/.local/share/fonts/jetbrains-mono-nerd-font/Fake-Regular.ttf" ]
    grep -q "fc-cache -f $HOME/.local/share/fonts/jetbrains-mono-nerd-font" "$TEST_TMP/calls"
}

@test "font: pauses on failure, prints the exact command, and succeeds once confirmed" {
    stub_command curl 'exit 7'
    mkdir -p "$HOME/.local/share/fonts/jetbrains-mono-nerd-font"
    touch "$HOME/.local/share/fonts/jetbrains-mono-nerd-font/Fake-Regular.ttf"

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra font jetbrains-mono-nerd-font https://example.test/Font.zip <<< ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Run this yourself"* ]]
    [[ "$output" == *"curl -fsSL https://example.test/Font.zip -o font.zip"* ]]
    [[ "$output" == *"Confirmed installed after manual step: jetbrains-mono-nerd-font"* ]]
}

@test "font: returns failure when the user skips the manual step" {
    stub_command curl 'exit 1'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/extras.sh'
        glb_install_extra font jetbrains-mono-nerd-font https://example.test/Font.zip <<< 's'
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"Skipped: install jetbrains-mono-nerd-font"* ]]
}

# --- glb_update_profile_extras / _glb_update_extra --------------------------
#
# Re-running an already-installed extra to pick up updates. Deliberately
# no pause/manual-step here (unlike glb_install_extra) - matches glb
# update's existing unprompted style, see docs/design/update-components.md.

@test "update: missing extras.txt is a silent no-op" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"

    run glb_update_profile_extras "$pdir"

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

@test "update: skips an extra that isn't currently installed" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'curl fresh https://example.test/install.sh\n' > "$pdir/extras.txt"
    stub_command curl 'echo "curl called" >> "$TEST_TMP/calls"; exit 0'

    run glb_update_profile_extras "$pdir"

    [ "$status" -eq 0 ]
    [ ! -f "$TEST_TMP/calls" ]
}

@test "update: curl - re-runs the install script for an already-installed extra" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'curl fresh https://example.test/install.sh\n' > "$pdir/extras.txt"
    stub_command fresh 'exit 0'
    stub_command curl 'echo "curl $*" >> "$TEST_TMP/calls"; exit 0'
    stub_command bash 'echo "bash ran" >> "$TEST_TMP/calls"; exit 0'

    run glb_update_profile_extras "$pdir"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Updating fresh via curl-install script"* ]]
    grep -q "curl -fsSL https://example.test/install.sh" "$TEST_TMP/calls"
    grep -q "bash ran" "$TEST_TMP/calls"
}

@test "update: flatpak - runs flatpak update, not install, for an already-installed extra" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'flatpak wezterm org.wezfurlong.wezterm\n' > "$pdir/extras.txt"
    stub_command flatpak 'echo "flatpak $*" >> "$TEST_TMP/calls"; case "$1" in info) exit 0 ;; esac'

    run glb_update_profile_extras "$pdir"

    [ "$status" -eq 0 ]
    grep -q "update -y org.wezfurlong.wezterm" "$TEST_TMP/calls"
    ! grep -q "flatpak install" "$TEST_TMP/calls"
}

@test "update: font - re-downloads and unzips, refreshing the font cache" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'font jetbrains-mono-nerd-font https://example.test/Font.zip\n' > "$pdir/extras.txt"
    mkdir -p "$HOME/.local/share/fonts/jetbrains-mono-nerd-font"
    touch "$HOME/.local/share/fonts/jetbrains-mono-nerd-font/Old-Regular.ttf"
    stub_command curl 'echo "curl $*" >> "$TEST_TMP/calls"; touch "${@: -1}"; exit 0'
    stub_command unzip 'echo "unzip $*" >> "$TEST_TMP/calls"; mkdir -p "${@: -1}"; touch "${@: -1}/New-Regular.ttf"; exit 0'
    stub_command fc-cache 'echo "fc-cache $*" >> "$TEST_TMP/calls"; exit 0'

    run glb_update_profile_extras "$pdir"

    [ "$status" -eq 0 ]
    [ -f "$HOME/.local/share/fonts/jetbrains-mono-nerd-font/New-Regular.ttf" ]
    grep -q "fc-cache -f $HOME/.local/share/fonts/jetbrains-mono-nerd-font" "$TEST_TMP/calls"
}

@test "update: a failed update is logged and aggregated, no manual-step pause" {
    local pdir="$TEST_TMP/profile"
    mkdir -p "$pdir"
    printf 'curl fresh https://example.test/install.sh\n' > "$pdir/extras.txt"
    stub_command fresh 'exit 0'
    stub_command curl 'exit 0'
    stub_command bash 'exit 1'

    run glb_update_profile_extras "$pdir" </dev/null

    [ "$status" -eq 1 ]
    [[ "$output" == *"Failed to update: fresh"* ]]
    [[ "$output" != *"Run this yourself"* ]]
}
