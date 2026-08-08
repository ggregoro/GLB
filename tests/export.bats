#!/usr/bin/env bats
#
# Tests for lib/export.sh: `glb export` captures the current
# machine's packages/dotfiles/shell setup into a profile-shaped
# snapshot, the reverse direction of `glb restore`. See
# docs/design/state-export-import.md.

load 'test_helper'

setup() {
    glb_setup_sandbox
    source "$GLB_ROOT/lib/logging.sh"
    source "$GLB_ROOT/lib/utils.sh"
    source "$GLB_ROOT/lib/detect.sh"
    source "$GLB_ROOT/lib/package.sh"
    source "$GLB_ROOT/lib/plugins.sh"
    source "$GLB_ROOT/lib/export.sh"
    export GLB_VERSION="0.1.0-test"
}

teardown() {
    glb_teardown_sandbox
}

# --- glb_list_installed_packages / reverse resolution ---------------------

@test "reverse_resolve_package_name maps a distro-specific override back to the generic name" {
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_reverse_resolve_package_name fd-find apt"
    [ "$output" = "fd" ]
}

@test "reverse_resolve_package_name passes through a name with no matching override" {
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_reverse_resolve_package_name ripgrep apt"
    [ "$output" = "ripgrep" ]
}

@test "reverse_resolve_package_name only matches within the given package manager" {
    # fd-find is apt's override; on pacman it should pass through unchanged.
    run bash -c "source '$GLB_ROOT/lib/package.sh'; glb_reverse_resolve_package_name fd-find pacman"
    [ "$output" = "fd-find" ]
}

@test "list_installed_packages uses apt-mark showmanual on apt" {
    stub_command apt-mark 'printf "git\nfd-find\n"'
    run glb_list_installed_packages apt
    [[ "$output" == *"git"* ]]
    [[ "$output" == *"fd-find"* ]]
}

@test "list_installed_packages uses pacman -Qqe on pacman" {
    stub_command pacman 'printf "git\nlibreoffice-fresh\n"'
    run glb_list_installed_packages pacman
    [[ "$output" == *"libreoffice-fresh"* ]]
}

@test "list_installed_packages uses dnf repoquery --userinstalled on dnf" {
    stub_command dnf 'printf "git\n"'
    run glb_list_installed_packages dnf
    [[ "$output" == *"git"* ]]
}

@test "list_installed_packages diffs rpm -qa against AutoInstalled on zypper" {
    stub_command rpm 'printf "git\nglibc\n"'
    mkdir -p "$TEST_TMP/fake-var-lib-zypp"
    printf "glibc\n" > "$TEST_TMP/fake-var-lib-zypp/AutoInstalled"

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/package.sh'
        glb_list_installed_packages() {
            comm -23 <(rpm -qa --qf '%{NAME}\n' | sort -u) <(grep -v '^#' '$TEST_TMP/fake-var-lib-zypp/AutoInstalled' | sort -u)
        }
        glb_list_installed_packages
    "
    [[ "$output" == *"git"* ]]
    [[ "$output" != *"glibc"* ]]
}

# --- glb_export_packages ---------------------------------------------------

@test "export_packages writes canonical names, reversing overrides" {
    stub_command apt-mark 'printf "git\nfd-find\n"'

    # glb_detect_package_manager is overridden directly (not via PATH
    # tricks) so this test is deterministic regardless of which real
    # package manager the host actually has (e.g. pacman, as on this VM)
    # - PATH-restricting instead would also hide coreutils glb_export_packages
    # itself needs (mkdir, hostname, date, sort, ...).
    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/export.sh'
        glb_detect_package_manager() { printf 'apt\n'; }
        mkdir -p '$TEST_TMP/snap'
        glb_export_packages '$TEST_TMP/snap'
    "
    [ "$status" -eq 0 ]

    run cat "$TEST_TMP/snap/packages.txt"
    [[ "$output" == *"git"* ]]
    [[ "$output" == *$'\n'"fd"$'\n'* ]] || [[ "$output" == *$'\n'"fd" ]]
    [[ "$output" != *"fd-find"* ]]
}

@test "export_packages adds the zypper base-package caveat only on zypper" {
    stub_command rpm 'printf "git\n"'

    # Same glb_detect_package_manager override as the apt test above -
    # deterministic regardless of the host's real package manager,
    # without hiding coreutils via a PATH restriction.
    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/export.sh'
        glb_detect_package_manager() { printf 'zypper\n'; }
        mkdir -p '$TEST_TMP/snap' /var/lib/zypp 2>/dev/null
        glb_export_packages '$TEST_TMP/snap'
    " || true

    run bash -c "
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/package.sh'
        source '$GLB_ROOT/lib/export.sh'
        glb_detect_package_manager() { printf 'zypper\n'; }
        mkdir -p '$TEST_TMP/snap2'
        glb_export_packages '$TEST_TMP/snap2'
    "
    run cat "$TEST_TMP/snap2/packages.txt"
    [[ "$output" == *"NOTE: zypper"* ]]
}

# --- glb_export_dotfiles ---------------------------------------------------

@test "export_dotfiles copies only tracked files that exist in HOME" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    printf '# bashrc\n' > "$GLB_ROOT/profiles/default/dotfiles/.bashrc"
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles/.config"
    printf 'starship\n' > "$GLB_ROOT/profiles/default/dotfiles/.config/starship.toml"

    printf 'real bashrc content\n' > "$HOME/.bashrc"
    # .config/starship.toml deliberately absent from $HOME

    mkdir -p "$TEST_TMP/snap"
    glb_export_dotfiles "$TEST_TMP/snap"

    [ -f "$TEST_TMP/snap/dotfiles/.bashrc" ]
    [ "$(cat "$TEST_TMP/snap/dotfiles/.bashrc")" = "real bashrc content" ]
    [ ! -e "$TEST_TMP/snap/dotfiles/.config/starship.toml" ]
}

@test "export_dotfiles follows symlinks and captures real content" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    printf 'placeholder\n' > "$GLB_ROOT/profiles/default/dotfiles/.zshrc"

    printf 'actual linked content\n' > "$TEST_TMP/target.zshrc"
    ln -s "$TEST_TMP/target.zshrc" "$HOME/.zshrc"

    mkdir -p "$TEST_TMP/snap"
    glb_export_dotfiles "$TEST_TMP/snap"

    [ ! -L "$TEST_TMP/snap/dotfiles/.zshrc" ]
    [ "$(cat "$TEST_TMP/snap/dotfiles/.zshrc")" = "actual linked content" ]
}

# --- glb_export_shell -------------------------------------------------------

@test "export_shell records shell, starship presence, and installed zsh plugins" {
    stub_command starship 'exit 0'
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-autosuggestions"
    mkdir -p "$TEST_TMP/snap"

    # PATH restricted to STUB_BIN only - otherwise a real starship
    # already installed on the host machine (as it is on this VM)
    # would make "not installed" below a false negative.
    run bash -c "
        PATH='$STUB_BIN'
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/plugins.sh'
        source '$GLB_ROOT/lib/export.sh'
        SHELL=/usr/bin/zsh glb_export_shell '$TEST_TMP/snap'
    "
    [ "$status" -eq 0 ]

    run cat "$TEST_TMP/snap/shell.txt"
    [[ "$output" == *"shell=/usr/bin/zsh"* ]]
    [[ "$output" == *"starship=installed"* ]]
    [[ "$output" == *"zsh_plugin=zsh-autosuggestions"* ]]
    [[ "$output" != *"zsh_plugin=zsh-syntax-highlighting"* ]]
}

@test "export_shell reports starship as not installed when absent" {
    mkdir -p "$TEST_TMP/snap"

    run bash -c "
        PATH='$STUB_BIN'
        source '$GLB_ROOT/lib/logging.sh'
        source '$GLB_ROOT/lib/utils.sh'
        source '$GLB_ROOT/lib/detect.sh'
        source '$GLB_ROOT/lib/plugins.sh'
        source '$GLB_ROOT/lib/export.sh'
        glb_export_shell '$TEST_TMP/snap'
    "
    [ "$status" -eq 0 ]

    run cat "$TEST_TMP/snap/shell.txt"
    [[ "$output" == *"starship=not installed"* ]]
}

# --- glb_export_metadata ----------------------------------------------------

@test "export_metadata records hostname, distro, package manager, and GLB version" {
    stub_command apt 'exit 0'
    stub_command hostname 'echo test-host'

    mkdir -p "$TEST_TMP/snap"
    glb_export_metadata "$TEST_TMP/snap"

    run cat "$TEST_TMP/snap/metadata.yaml"
    [[ "$output" == *"hostname: test-host"* ]]
    [[ "$output" == *"package_manager: apt"* ]]
    [[ "$output" == *"glb_version: 0.1.0-test"* ]]
}

# --- glb_export_snapshot (integration) -------------------------------------

@test "export_snapshot creates a hostname-dated snapshot with all four artifacts" {
    stub_command apt-mark 'printf "git\n"'
    stub_command apt 'exit 0'
    stub_command hostname 'echo test-host'
    stub_command date 'if [ "$1" = "+%Y-%m-%d" ]; then echo 2026-08-07; else /usr/bin/date "$@"; fi'

    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    printf 'x\n' > "$GLB_ROOT/profiles/default/dotfiles/.bashrc"
    printf 'x\n' > "$HOME/.bashrc"

    run glb_export_snapshot
    [ "$status" -eq 0 ]
    [[ "$output" == *"Exported snapshot: snapshots/test-host-2026-08-07"* ]]

    [ -f "$GLB_ROOT/snapshots/test-host-2026-08-07/packages.txt" ]
    [ -f "$GLB_ROOT/snapshots/test-host-2026-08-07/shell.txt" ]
    [ -f "$GLB_ROOT/snapshots/test-host-2026-08-07/metadata.yaml" ]
    [ -f "$GLB_ROOT/snapshots/test-host-2026-08-07/dotfiles/.bashrc" ]
}

@test "export_snapshot warns but overwrites when a snapshot for today already exists" {
    stub_command apt-mark 'printf "git\n"'
    stub_command apt 'exit 0'
    stub_command hostname 'echo test-host'
    stub_command date 'if [ "$1" = "+%Y-%m-%d" ]; then echo 2026-08-07; else /usr/bin/date "$@"; fi'

    mkdir -p "$GLB_ROOT/snapshots/test-host-2026-08-07"

    run glb_export_snapshot
    [ "$status" -eq 0 ]
    [[ "$output" == *"already exists for today, overwriting"* ]]
}
