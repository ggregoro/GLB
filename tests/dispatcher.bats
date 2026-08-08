#!/usr/bin/env bats
#
# End-to-end smoke tests for the `glb` dispatcher's newly-wired
# commands: remove, update, restore, profiles. sudo/apt are stubbed so
# nothing here touches real system packages.

load 'test_helper'

setup() {
    glb_setup_sandbox
    stub_command sudo 'exec "$@"'
    stub_command apt 'echo "apt $*"; exit 0'
    stub_command dpkg 'exit 1'
    # glb update unconditionally exercises glb_update_starship, which
    # checks for a real starship binary via PATH (not just STUB_BIN) -
    # this machine may genuinely have one installed. Default curl/sh to
    # safe no-ops so that path never makes a real network call; tests
    # that care about the exact command re-stub these themselves.
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'
}

teardown() {
    glb_teardown_sandbox
}

@test "glb with no args shows help" {
    run "$GLB_ROOT/glb"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "glb help lists all commands including the new ones" {
    run "$GLB_ROOT/glb" help
    [[ "$output" == *"restore"* ]]
    [[ "$output" == *"profiles"* ]]
    [[ "$output" == *"remove"* ]]
    [[ "$output" == *"update"* ]]
}

@test "glb rejects an unknown command" {
    run "$GLB_ROOT/glb" bogus-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "glb profiles lists profiles under GLB_ROOT" {
    mkdir -p "$GLB_ROOT/profiles/default" "$GLB_ROOT/profiles/server"
    run "$GLB_ROOT/glb" profiles
    [[ "$output" == *"default"* ]]
    [[ "$output" == *"server"* ]]
}

@test "glb restore applies a profile end to end" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/default/packages.txt"
    echo 'x' > "$GLB_ROOT/profiles/default/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore default

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: default"* ]]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb restore applies the real new-to-linux profile end to end" {
    cp -r "$GLB_REPO_ROOT/profiles/new-to-linux" "$GLB_ROOT/profiles/new-to-linux"
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'
    stub_command unzip 'mkdir -p "${@: -1}"; touch "${@: -1}/Fake-Regular.ttf"; exit 0'
    stub_command fc-cache 'exit 0'

    run "$GLB_ROOT/glb" restore new-to-linux <<< ''

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: new-to-linux"* ]]
    [[ "$output" == *"Installing fresh via curl-install script"* ]]
    [[ "$output" == *"Installing font: jetbrains-mono-nerd-font"* ]]
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.zshrc" ]
    [ -L "$HOME/.config/fish/config.fish" ]
    [ -L "$HOME/.config/starship.toml" ]
    [ ! -e "$HOME/.gitconfig" ]
    [ ! -e "$HOME/.config/ranger" ]
}

@test "glb restore applies the real default profile end to end" {
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'
    stub_command flatpak 'echo "flatpak $*" >> "$TEST_TMP/calls"; [ "$1" = "info" ] && exit 1; exit 0'
    stub_command unzip 'mkdir -p "${@: -1}"; touch "${@: -1}/Fake-Regular.ttf"; exit 0'
    stub_command fc-cache 'exit 0'

    run "$GLB_ROOT/glb" restore default <<< ''

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: default"* ]]
    [[ "$output" == *"Installing fresh via curl-install script"* ]]
    [[ "$output" == *"Installing wezterm via Flatpak"* ]]
    [[ "$output" == *"Installing font: jetbrains-mono-nerd-font"* ]]
    grep -q "install -y flathub org.wezfurlong.wezterm" "$TEST_TMP/calls"
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.gitconfig" ]
    [ -L "$HOME/.config/wezterm/wezterm.lua" ]
}

@test "glb restore applies the real developer profile end to end" {
    cp -r "$GLB_REPO_ROOT/profiles/developer" "$GLB_ROOT/profiles/developer"
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'
    stub_command unzip 'mkdir -p "${@: -1}"; touch "${@: -1}/Fake-Regular.ttf"; exit 0'
    stub_command fc-cache 'exit 0'

    run "$GLB_ROOT/glb" restore developer <<< ''

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: developer"* ]]
    [[ "$output" == *"Installing fresh via curl-install script"* ]]
    [[ "$output" == *"Installing mise via curl-install script"* ]]
    [[ "$output" == *"Installing font: jetbrains-mono-nerd-font"* ]]
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.zshrc" ]
    [ -L "$HOME/.config/fish/config.fish" ]
    [ -L "$HOME/.config/starship.toml" ]
    [ ! -e "$HOME/.gitconfig" ]
    [ ! -e "$HOME/.config/ranger" ]
    grep -q "mise (language version manager" "$HOME/.bashrc"
}

@test "glb restore applies the real server profile end to end" {
    cp -r "$GLB_REPO_ROOT/profiles/server" "$GLB_ROOT/profiles/server"
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'
    stub_command unzip 'mkdir -p "${@: -1}"; touch "${@: -1}/Fake-Regular.ttf"; exit 0'
    stub_command fc-cache 'exit 0'

    run "$GLB_ROOT/glb" restore server <<< ''

    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile applied: server"* ]]
    [[ "$output" == *"Installing font: jetbrains-mono-nerd-font"* ]]
    [[ "$output" == *"apt install -y ufw"* ]]
    [[ "$output" == *"apt install -y restic"* ]]
    [[ "$output" == *"apt install -y fail2ban"* ]]
    [ -L "$HOME/.bashrc" ]
    [ -L "$HOME/.zshrc" ]
    [ -L "$HOME/.config/fish/config.fish" ]
    [ -L "$HOME/.config/starship.toml" ]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb restore fails cleanly for an unknown profile" {
    run "$GLB_ROOT/glb" restore no-such-profile
    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile not found"* ]]
}

@test "glb restore --from-snapshot applies a snapshot end to end" {
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'

    mkdir -p "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles"
    printf 'git\n' > "$GLB_ROOT/snapshots/host-2026-08-07/packages.txt"
    echo 'x' > "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore --from-snapshot host-2026-08-07

    [ "$status" -eq 0 ]
    [[ "$output" == *"apt install -y git"* ]]
    [[ "$output" == *"Snapshot applied: host-2026-08-07"* ]]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb restore --from-snapshot works with --dry-run in either order" {
    mkdir -p "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles"
    printf 'git\n' > "$GLB_ROOT/snapshots/host-2026-08-07/packages.txt"
    echo 'x' > "$GLB_ROOT/snapshots/host-2026-08-07/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore --from-snapshot host-2026-08-07 --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run for snapshot: host-2026-08-07"* ]]
    [ ! -e "$HOME/.gitconfig" ]

    run "$GLB_ROOT/glb" restore --dry-run --from-snapshot host-2026-08-07
    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run for snapshot: host-2026-08-07"* ]]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb restore --from-snapshot fails cleanly for a nonexistent snapshot" {
    run "$GLB_ROOT/glb" restore --from-snapshot no-such-snapshot
    [ "$status" -eq 1 ]
    [[ "$output" == *"Snapshot not found"* ]]
}

@test "glb export then glb restore --from-snapshot round-trips a real machine's state" {
    stub_command apt-mark 'printf "git\n"'
    stub_command hostname 'echo test-host'
    stub_command date 'if [ "$1" = "+%Y-%m-%d" ]; then echo 2026-08-07; else /usr/bin/date "$@"; fi'
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'

    mkdir -p "$GLB_ROOT/profiles"
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"
    printf 'my real bashrc\n' > "$HOME/.bashrc"

    run "$GLB_ROOT/glb" export
    [ "$status" -eq 0 ]

    rm "$HOME/.bashrc"

    run "$GLB_ROOT/glb" restore --from-snapshot test-host-2026-08-07
    [ "$status" -eq 0 ]
    [[ "$output" == *"Snapshot applied: test-host-2026-08-07"* ]]
    [ -L "$HOME/.bashrc" ]
    [ "$(cat "$HOME/.bashrc")" = "my real bashrc" ]
}

@test "glb restore --undo reverses a prior restore's dotfile changes" {
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'

    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    echo 'new content' > "$GLB_ROOT/profiles/default/dotfiles/.bashrc"
    echo 'old content' > "$HOME/.bashrc"

    run "$GLB_ROOT/glb" restore default
    [ "$status" -eq 0 ]
    [ -L "$HOME/.bashrc" ]
    [ -f "$HOME/.bashrc.glb-backup" ]

    run "$GLB_ROOT/glb" restore --undo

    [ "$status" -eq 0 ]
    [[ "$output" == *"Restored ~/.bashrc"* ]]
    [ ! -L "$HOME/.bashrc" ]
    [ "$(cat "$HOME/.bashrc")" = "old content" ]
    [ ! -e "$HOME/.bashrc.glb-backup" ]
}

@test "glb restore --undo reports cleanly when there is nothing to undo" {
    run "$GLB_ROOT/glb" restore --undo
    [ "$status" -eq 0 ]
    [[ "$output" == *"nothing to undo"* ]]
}

@test "glb restore --dry-run previews the real default profile without changing anything" {
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"

    run "$GLB_ROOT/glb" restore default --dry-run

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run for profile: default"* ]]
    [[ "$output" == *"Would install: git"* ]]
    [[ "$output" == *"Would link ~/.bashrc"* ]]
    [[ "$output" == *"Dry run complete: default"* ]]
    [ ! -e "$HOME/.bashrc" ]
    [ ! -e "$HOME/.gitconfig" ]
    [ ! -d "$HOME/.config" ]
}

@test "glb restore --dry-run also works with the flag before the profile name" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/default/packages.txt"
    echo 'x' > "$GLB_ROOT/profiles/default/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore --dry-run default

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run for profile: default"* ]]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb restore with no profile name shows a picker, previews, then applies once confirmed" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles" "$GLB_ROOT/profiles/work/dotfiles"
    printf 'git\n' > "$GLB_ROOT/profiles/default/packages.txt"
    echo 'x' > "$GLB_ROOT/profiles/work/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore <<< $'2\ny'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Choose a profile to restore"* ]]
    [[ "$output" == *"1) default"* ]]
    [[ "$output" == *"2) work"* ]]
    [[ "$output" == *"Preview of profile: work"* ]]
    [[ "$output" == *"Profile applied: work"* ]]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb restore with no profile name does nothing when the user declines to confirm" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles" "$GLB_ROOT/profiles/work/dotfiles"
    echo 'x' > "$GLB_ROOT/profiles/work/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore <<< $'2\nn'

    [ "$status" -eq 1 ]
    [[ "$output" == *"Cancelled; nothing changed."* ]]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb restore with no profile name shows real profile descriptions" {
    mkdir -p "$GLB_ROOT/profiles"
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"
    cp -r "$GLB_REPO_ROOT/profiles/new-to-linux" "$GLB_ROOT/profiles/new-to-linux"

    run "$GLB_ROOT/glb" restore <<< $'1\nn'

    [[ "$output" == *"default - Greg's own daily-driver setup"* ]]
    [[ "$output" == *"new-to-linux - Curated picks for someone switching"* ]]
}

@test "glb restore with no profile name and --dry-run picks interactively then previews" {
    mkdir -p "$GLB_ROOT/profiles/default/dotfiles" "$GLB_ROOT/profiles/work/dotfiles"
    echo 'x' > "$GLB_ROOT/profiles/work/dotfiles/.gitconfig"

    run "$GLB_ROOT/glb" restore --dry-run <<< '2'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Dry run for profile: work"* ]]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb remove without a package name errors instead of crashing" {
    run "$GLB_ROOT/glb" remove
    [ "$status" -eq 1 ]
    [[ "$output" == *"No package specified"* ]]
}

@test "glb remove calls the package manager's remove command" {
    run "$GLB_ROOT/glb" remove git
    [ "$status" -eq 0 ]
    [[ "$output" == *"apt remove -y git"* ]]
}

@test "glb update runs the package manager's update commands" {
    run "$GLB_ROOT/glb" update
    [ "$status" -eq 0 ]
    [[ "$output" == *"apt update"* ]]
    [[ "$output" == *"apt upgrade -y"* ]]
}

@test "glb update with no profile also updates starship/zsh plugins but not any extras" {
    stub_command starship 'exit 0'
    stub_command curl 'echo "curl $*" >> "$TEST_TMP/calls"; exit 0'
    stub_command sh 'echo "sh ran" >> "$TEST_TMP/calls"; exit 0'
    stub_command git 'echo "git $*" >> "$TEST_TMP/calls"; exit 0'
    mkdir -p "$HOME/.local/share/glb/plugins/zsh-autosuggestions"

    run "$GLB_ROOT/glb" update

    [ "$status" -eq 0 ]
    [[ "$output" == *"Updated starship"* ]]
    [[ "$output" == *"Updated zsh plugin: zsh-autosuggestions"* ]]
    grep -q "curl -sS https://starship.rs/install.sh" "$TEST_TMP/calls"
}

@test "glb update <profile> also re-runs that profile's already-installed extras" {
    mkdir -p "$GLB_ROOT/profiles/default"
    printf 'flatpak wezterm org.wezfurlong.wezterm\n' > "$GLB_ROOT/profiles/default/extras.txt"
    stub_command flatpak 'echo "flatpak $*" >> "$TEST_TMP/calls"; case "$1" in info) exit 0 ;; esac'

    run "$GLB_ROOT/glb" update default

    [ "$status" -eq 0 ]
    grep -q "update -y org.wezfurlong.wezterm" "$TEST_TMP/calls"
}

@test "glb update rejects an unknown profile" {
    run "$GLB_ROOT/glb" update bogus-profile
    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile not found: bogus-profile"* ]]
}

@test "glb export captures the real default profile's tracked dotfiles and packages into a snapshot" {
    stub_command apt-mark 'printf "git\nfd-find\n"'
    stub_command hostname 'echo test-host'
    stub_command date 'if [ "$1" = "+%Y-%m-%d" ]; then echo 2026-08-07; else /usr/bin/date "$@"; fi'

    mkdir -p "$GLB_ROOT/profiles"
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"
    printf 'my real bashrc\n' > "$HOME/.bashrc"

    run "$GLB_ROOT/glb" export
    [ "$status" -eq 0 ]
    [[ "$output" == *"Exported snapshot: snapshots/test-host-2026-08-07"* ]]

    run cat "$GLB_ROOT/snapshots/test-host-2026-08-07/packages.txt"
    [[ "$output" == *$'\n'"git"$'\n'* ]] || [[ "$output" == *$'\n'"git" ]]
    [[ "$output" == *$'\n'"fd"$'\n'* ]] || [[ "$output" == *$'\n'"fd" ]]
    [[ "$output" != *"fd-find"* ]]

    [ "$(cat "$GLB_ROOT/snapshots/test-host-2026-08-07/dotfiles/.bashrc")" = "my real bashrc" ]
    [ ! -e "$GLB_ROOT/snapshots/test-host-2026-08-07/dotfiles/.zshrc" ]
}

@test "glb diff reports real drift between the default and new-to-linux profiles" {
    mkdir -p "$GLB_ROOT/profiles"
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"
    cp -r "$GLB_REPO_ROOT/profiles/new-to-linux" "$GLB_ROOT/profiles/new-to-linux"

    run "$GLB_ROOT/glb" diff default new-to-linux
    [ "$status" -eq 1 ]
    [[ "$output" == *"Diff: default vs new-to-linux"* ]]
    # default has .gitconfig, new-to-linux deliberately doesn't
    [[ "$output" == *"+ only in default: ~/.gitconfig"* ]]
}

@test "glb diff reports no differences when comparing a profile to itself" {
    mkdir -p "$GLB_ROOT/profiles"
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"

    run "$GLB_ROOT/glb" diff default default
    [ "$status" -eq 0 ]
    [[ "$output" == *"no package differences"* ]]
    [[ "$output" == *"no dotfile differences"* ]]
}

@test "glb diff errors cleanly for an unresolvable name" {
    run "$GLB_ROOT/glb" diff default nope
    [ "$status" -eq 1 ]
    [[ "$output" == *"Not found"* ]]
}

@test "glb repair finds real drift against the default profile and fixes it once confirmed" {
    stub_command starship 'exit 0'
    stub_command git 'mkdir -p "$5"; exit 0'
    stub_command curl 'exit 0'
    stub_command sh 'exit 0'
    stub_command flatpak 'echo "flatpak $*" >> "$TEST_TMP/calls"; [ "$1" = "info" ] && exit 1; exit 0'
    stub_command unzip 'mkdir -p "${@: -1}"; touch "${@: -1}/Fake-Regular.ttf"; exit 0'
    stub_command fc-cache 'exit 0'
    stub_command apt-mark 'printf ""'

    mkdir -p "$GLB_ROOT/profiles"
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"

    run "$GLB_ROOT/glb" repair default <<< 'y'

    [ "$status" -eq 0 ]
    [[ "$output" == *"Checking profile: default"* ]]
    [[ "$output" == *"- only in default:"* ]]
    [[ "$output" == *"Profile applied: default"* ]]
    [ -L "$HOME/.gitconfig" ]
}

@test "glb repair leaves the machine untouched when declined" {
    stub_command apt-mark 'printf ""'

    mkdir -p "$GLB_ROOT/profiles"
    cp -r "$GLB_REPO_ROOT/profiles/default" "$GLB_ROOT/profiles/default"

    run "$GLB_ROOT/glb" repair default <<< 'n'

    [ "$status" -eq 1 ]
    [[ "$output" == *"Cancelled; nothing changed."* ]]
    [ ! -e "$HOME/.gitconfig" ]
}

@test "glb repair fails cleanly for an unknown profile" {
    run "$GLB_ROOT/glb" repair no-such-profile
    [ "$status" -eq 1 ]
    [[ "$output" == *"Profile not found"* ]]
}
