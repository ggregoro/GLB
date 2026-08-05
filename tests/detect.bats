#!/usr/bin/env bats
#
# Tests for lib/detect.sh, focused on glb_detect_package_manager since
# that's what changed recently (the zypper detection fix).

load 'test_helper'

setup() {
    glb_setup_sandbox
}

teardown() {
    glb_teardown_sandbox
}

# Each case sources detect.sh in a fresh bash with PATH restricted to
# STUB_BIN only, so results don't depend on what's really installed
# on the host.

@test "detects apt when apt is available" {
    stub_command apt 'exit 0'
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$status" -eq 0 ]
    [ "$output" = "apt" ]
}

@test "detects dnf when only dnf is available" {
    stub_command dnf 'exit 0'
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$status" -eq 0 ]
    [ "$output" = "dnf" ]
}

@test "detects pacman when only pacman is available" {
    stub_command pacman 'exit 0'
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$status" -eq 0 ]
    [ "$output" = "pacman" ]
}

@test "detects zypper when only zypper is available (regression test for the zypper fix)" {
    stub_command zypper 'exit 0'
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$status" -eq 0 ]
    [ "$output" = "zypper" ]
}

@test "prioritizes apt over dnf, pacman, and zypper when several are present" {
    stub_command apt 'exit 0'
    stub_command dnf 'exit 0'
    stub_command pacman 'exit 0'
    stub_command zypper 'exit 0'
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$output" = "apt" ]
}

@test "prioritizes dnf over pacman and zypper" {
    stub_command dnf 'exit 0'
    stub_command pacman 'exit 0'
    stub_command zypper 'exit 0'
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$output" = "dnf" ]
}

@test "prioritizes pacman over zypper" {
    stub_command pacman 'exit 0'
    stub_command zypper 'exit 0'
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$output" = "pacman" ]
}

@test "returns failure when no known package manager is available" {
    run bash -c "PATH='$STUB_BIN'; source '$GLB_ROOT/lib/detect.sh'; glb_detect_package_manager"
    [ "$status" -eq 1 ]
}
