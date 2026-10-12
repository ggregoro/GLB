#!/usr/bin/env bats
#
# Tests for the Yazi launcher script shipped in the default profile
# (dotfiles/.local/bin/yazi-launch) and the app-menu entry that runs it.
# ghostty, kitty, yazi, systemd-detect-virt and notify-send are always
# stubbed, and the script runs with only the stubs on PATH, so no test
# here opens a real window or depends on what the host has installed.

load 'test_helper'

setup() {
    glb_setup_sandbox
    SCRIPT="$GLB_REPO_ROOT/profiles/default/dotfiles/.local/bin/yazi-launch"
    DESKTOP="$GLB_REPO_ROOT/profiles/default/dotfiles/.local/share/applications/yazi.desktop"
    unset LIBGL_ALWAYS_SOFTWARE

    # Each terminal stub records its arguments and the drawing setting
    # it was started with.
    stub_command ghostty 'printf "ghostty %s | sw=%s\n" "$*" "${LIBGL_ALWAYS_SOFTWARE:-unset}" >> "$TEST_TMP/launched"'
    stub_command kitty 'printf "kitty %s | sw=%s\n" "$*" "${LIBGL_ALWAYS_SOFTWARE:-unset}" >> "$TEST_TMP/launched"'
    stub_command yazi 'exit 0'
    stub_command notify-send 'printf "%s\n" "$*" >> "$TEST_TMP/notified"'
    stub_command systemd-detect-virt 'echo none; exit 1'
}

teardown() {
    glb_teardown_sandbox
}

# Only the stubs on PATH: the host's own ghostty / kitty must not count.
launch() {
    PATH="$STUB_BIN" run "$GLB_REAL_BASH" "$SCRIPT" "$@"
}

@test "yazi-launch is executable" {
    [ -x "$SCRIPT" ]
}

@test "the app-menu entry runs yazi-launch from ~/.local/bin" {
    grep -qxF 'Exec=sh -c "exec ~/.local/bin/yazi-launch"' "$DESKTOP"
}

@test "opens Yazi in Ghostty when Ghostty is installed" {
    launch

    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_TMP/launched")" = "ghostty --class=com.yazi.Yazi -e yazi | sw=unset" ]
}

@test "falls back to Kitty when Ghostty isn't installed" {
    rm "$STUB_BIN/ghostty"

    launch

    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_TMP/launched")" = "kitty --class com.yazi.Yazi yazi | sw=unset" ]
}

@test "passes its arguments on to yazi" {
    launch "/some/folder with space"

    [ "$(cat "$TEST_TMP/launched")" = "ghostty --class=com.yazi.Yazi -e yazi /some/folder with space | sw=unset" ]
}

@test "VirtualBox guest: the window gets software drawing" {
    stub_command systemd-detect-virt 'echo oracle'

    launch

    [ "$(cat "$TEST_TMP/launched")" = "ghostty --class=com.yazi.Yazi -e yazi | sw=1" ]
}

@test "VirtualBox guest: Kitty gets software drawing too" {
    stub_command systemd-detect-virt 'echo oracle'
    rm "$STUB_BIN/ghostty"

    launch

    [ "$(cat "$TEST_TMP/launched")" = "kitty --class com.yazi.Yazi yazi | sw=1" ]
}

@test "another kind of VM is left alone" {
    stub_command systemd-detect-virt 'echo kvm'

    launch

    [ "$(cat "$TEST_TMP/launched")" = "ghostty --class=com.yazi.Yazi -e yazi | sw=unset" ]
}

@test "a drawing setting that is already set is not overridden" {
    stub_command systemd-detect-virt 'echo oracle'

    LIBGL_ALWAYS_SOFTWARE=0 launch

    [ "$(cat "$TEST_TMP/launched")" = "ghostty --class=com.yazi.Yazi -e yazi | sw=0" ]
}

@test "works where systemd-detect-virt doesn't exist" {
    rm "$STUB_BIN/systemd-detect-virt"

    launch

    [ "$status" -eq 0 ]
    [ "$(cat "$TEST_TMP/launched")" = "ghostty --class=com.yazi.Yazi -e yazi | sw=unset" ]
}

@test "no terminal installed: says so, in a notification too, and fails" {
    rm "$STUB_BIN/ghostty" "$STUB_BIN/kitty"

    launch

    [ "$status" -eq 1 ]
    [[ "$output" == *"Neither Ghostty nor Kitty is installed"* ]]
    grep -q "Neither Ghostty nor Kitty" "$TEST_TMP/notified"
    [ ! -e "$TEST_TMP/launched" ]
}

@test "yazi not installed: says so and starts no terminal" {
    rm "$STUB_BIN/yazi"

    launch

    [ "$status" -eq 1 ]
    [[ "$output" == *"yazi is not installed"* ]]
    [ ! -e "$TEST_TMP/launched" ]
}
