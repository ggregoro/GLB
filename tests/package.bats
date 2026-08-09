#!/usr/bin/env bats
#
# Tests for lib/package.sh, focused on per-distro package name
# overrides (glb_resolve_package_name) and that install/remove/
# installed-check all resolve names before shelling out.

load 'test_helper'

setup() {
    glb_setup_sandbox
}

teardown() {
    glb_teardown_sandbox
}

# glb_resolve_package_name is pure (no package manager calls), so it
# can be tested directly without stubbing anything.

@test "resolve_package_name returns the override for a known generic:pkg_mgr pair" {
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_resolve_package_name fd apt"
    [ "$status" -eq 0 ]
    [ "$output" = "fd-find" ]
}

@test "resolve_package_name passes a name through unchanged when no override exists" {
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_resolve_package_name fd pacman"
    [ "$status" -eq 0 ]
    [ "$output" = "fd" ]
}

@test "resolve_package_name passes through packages with no override on any manager" {
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_resolve_package_name ripgrep apt"
    [ "$output" = "ripgrep" ]
}

@test "resolve_package_name returns the override for firefox on zypper" {
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_resolve_package_name firefox zypper"
    [ "$output" = "MozillaFirefox" ]
}

@test "resolve_package_name returns the override for libreoffice on pacman" {
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_resolve_package_name libreoffice pacman"
    [ "$output" = "libreoffice-fresh" ]
}

@test "install_package installs the resolved name, not the generic name" {
    stub_command apt 'exit 0'
    stub_command sudo 'echo "sudo $*" >> "$TEST_TMP/calls"; exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_install_package fd
    "
    [ "$status" -eq 0 ]
    grep -q "apt install -y fd-find" "$TEST_TMP/calls"
    ! grep -q "apt install -y fd$" "$TEST_TMP/calls"
}

@test "remove_package removes the resolved name, not the generic name" {
    stub_command apt 'exit 0'
    stub_command sudo 'echo "sudo $*" >> "$TEST_TMP/calls"; exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_remove_package fd
    "
    [ "$status" -eq 0 ]
    grep -q "apt remove -y fd-find" "$TEST_TMP/calls"
}

@test "package_installed checks the resolved name against dpkg" {
    stub_command apt 'exit 0'
    stub_command dpkg 'echo "dpkg $*" >> "$TEST_TMP/calls"; [ "$2" = "fd-find" ]'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_package_installed fd
    "
    [ "$status" -eq 0 ]
    grep -q "dpkg -s fd-find" "$TEST_TMP/calls"
}

@test "install_package leaves an unoverridden name untouched" {
    stub_command apt 'exit 0'
    stub_command sudo 'echo "sudo $*" >> "$TEST_TMP/calls"; exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_install_package ripgrep
    "
    [ "$status" -eq 0 ]
    grep -q "apt install -y ripgrep" "$TEST_TMP/calls"
}

@test "install_package still errors with no package specified" {
    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_install_package
    "
    [ "$status" -eq 1 ]
}

# --- manual-step pause/resume on install failure ---------------------------

@test "install_package pauses on failure, prints the exact resolved command, and succeeds once the user confirms" {
    stub_command apt 'exit 1'
    stub_command sudo 'exit 1'
    stub_command dpkg 'exit 0'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_install_package fd <<< ''
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Run this yourself"* ]]
    [[ "$output" == *"sudo apt install -y fd-find"* ]]
    [[ "$output" == *"Confirmed installed after manual step: fd"* ]]
}

@test "install_package returns failure when the user skips the manual step" {
    stub_command apt 'exit 1'
    stub_command sudo 'exit 1'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_install_package ripgrep <<< 's'
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"Skipped: install ripgrep"* ]]
}

@test "install_package fails without hanging when no input is available to wait on" {
    stub_command apt 'exit 1'
    stub_command sudo 'exit 1'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_install_package ripgrep </dev/null
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"No input available"* ]]
}

@test "install_package warns but still fails if the package still isn't detected after the manual step" {
    stub_command apt 'exit 1'
    stub_command sudo 'exit 1'
    stub_command dpkg 'exit 1'

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_install_package ripgrep <<< ''
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"Still not detected as installed: ripgrep"* ]]
}
