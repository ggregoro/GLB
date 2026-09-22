#!/usr/bin/env bats
#
# Tests for the Arch `update` function shipped in each profile's shell
# dotfiles (bash, zsh, fish). The real function body is extracted from
# the dotfile and run with stubbed package tools, so what's tested is
# what ships - not a copy. Nothing here touches the real package
# database, network, or sudo.

load 'test_helper'

setup() {
    glb_setup_sandbox
    stub_command sudo '[ "$1" = "-n" ] && shift; exec "$@"'
    for tool in pacman paru yay flatpak; do
        stub_command "$tool" 'echo "'"$tool"' $*" >> "$TEST_TMP/calls"; exit "${STUB_FAIL_'"$tool"':-0}"'
    done
    # Only some tests want a given tool present; start with none.
    rm -f "$STUB_BIN/paru" "$STUB_BIN/yay" "$STUB_BIN/flatpak"
}

teardown() {
    glb_teardown_sandbox
}

want() { local t; for t in "$@"; do
    stub_command "$t" 'echo "'"$t"' $*" >> "$TEST_TMP/calls"; exit "${STUB_FAIL_'"$t"':-0}"'
done; }

# extract_update <profile> <dotfile-relative-path> <style>
# Print the `update` definition from a dotfile. bash/zsh: a 4-space
# indented `update() {` ... `}`; fish: `function update` ... `end`.
extract_update() {
    local file="$GLB_REPO_ROOT/profiles/$1/dotfiles/$2"
    if [[ "$3" == fish ]]; then
        awk '/^    function update /{p=1} p{print} p&&/^    end$/{exit}' "$file"
    else
        awk '/^    update\(\) \{$/{p=1} p{print} p&&/^    \}$/{exit}' "$file"
    fi
}

# run_update <profile> <shell> [args...]
run_update() {
    local profile="$1" shell="$2"; shift 2
    local fn
    case "$shell" in
        bash) fn="$(extract_update "$profile" .bashrc posix)" ;;
        zsh)  fn="$(extract_update "$profile" .zshrc posix)" ;;
        fish) fn="$(extract_update "$profile" .config/fish/config.fish fish)" ;;
    esac
    [ -n "$fn" ]
    run "$shell" -c "$fn
update $*"

    # fish's own startup Flatpak integration runs `flatpak
    # --installations` (to extend XDG_DATA_DIRS), which lands in the
    # stub's log whenever a flatpak stub is present. That's the shell,
    # not `update` - drop it so the log shows only what update called.
    if [[ -f "$TEST_TMP/calls" ]]; then
        { grep -v '^flatpak --installations$' "$TEST_TMP/calls" || true; } > "$TEST_TMP/calls.filtered"
        mv "$TEST_TMP/calls.filtered" "$TEST_TMP/calls"
    fi
}

# for_each_shell <function>
# Runs <function> once per installed shell (bash/zsh/fish), with a clean
# call log each time. A shell that isn't installed is skipped, not
# failed; at least one must be present or the test is skipped.
SHELLS_RUN=0
for_each_shell() {
    local fn="$1" shell
    SHELLS_RUN=0
    for shell in bash zsh fish; do
        command -v "$shell" >/dev/null 2>&1 || continue
        rm -f "$TEST_TMP/calls"
        SHELLS_RUN=$((SHELLS_RUN + 1))
        "$fn" "$shell"
    done
    [ "$SHELLS_RUN" -gt 0 ] || skip "no shells installed"
}

# --- every shell of the default profile ------------------------------

@test "default: prefers paru and runs -Syu, then updates Flatpak" {
    check() {
        want paru yay flatpak
        run_update default "$1"
        [ "$status" -eq 0 ]
        [ "$(sed -n 1p "$TEST_TMP/calls")" = "paru -Syu" ]
        [ "$(sed -n 2p "$TEST_TMP/calls")" = "flatpak update" ]
        ! grep -q '^yay' "$TEST_TMP/calls"
    }
    for_each_shell check
}

@test "default: falls back to yay when paru isn't installed" {
    check() {
        want yay
        run_update default "$1"
        [ "$status" -eq 0 ]
        grep -q '^yay -Syu$' "$TEST_TMP/calls"
    }
    for_each_shell check
}

@test "default: falls back to sudo pacman -Syu with no AUR helper" {
    check() {
        run_update default "$1"
        [ "$status" -eq 0 ]
        grep -q '^pacman -Syu$' "$TEST_TMP/calls"
    }
    for_each_shell check
}

@test "default: skips Flatpak quietly when it isn't installed" {
    check() {
        want paru
        run_update default "$1"
        [ "$status" -eq 0 ]
        [ "$(wc -l < "$TEST_TMP/calls")" -eq 1 ]
    }
    for_each_shell check
}

@test "default: stops, and returns the failure, when the package update fails" {
    check() {
        want paru flatpak
        STUB_FAIL_paru=3 run_update default "$1"
        [ "$status" -eq 3 ]
        grep -q '^paru -Syu$' "$TEST_TMP/calls"
        ! grep -q '^flatpak' "$TEST_TMP/calls"
    }
    for_each_shell check
}

@test "default: extra arguments pass through to the package step" {
    check() {
        want paru
        run_update default "$1" --noconfirm
        [ "$status" -eq 0 ]
        grep -q '^paru -Syu --noconfirm$' "$TEST_TMP/calls"
    }
    for_each_shell check
}

# --- developer and server: AUR-helper fallback, but no Flatpak ---------

@test "developer and server: same helper fallback in every shell, never Flatpak" {
    check() {
        local profile
        for profile in developer server; do
            rm -f "$TEST_TMP/calls"
            want paru flatpak
            run_update "$profile" "$1"
            [ "$status" -eq 0 ]
            [ "$(cat "$TEST_TMP/calls")" = "paru -Syu" ]
        done
    }
    for_each_shell check
}

@test "no profile still points update at yay unconditionally" {
    ! grep -rn "alias update='yay" "$GLB_REPO_ROOT/profiles"
}
