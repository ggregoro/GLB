#!/usr/bin/env bats
#
# Tests for install.sh, the curl-install bootstrap script. Doesn't use
# the shared glb_setup_sandbox (that's for testing lib/ modules against
# a fake GLB_ROOT) - install.sh is a standalone script that clones a
# fresh checkout, so each test gets its own temp dir and stubs git.

GLB_REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    TEST_TMP="$(mktemp -d)"
    STUB_BIN="$TEST_TMP/bin"
    mkdir -p "$STUB_BIN"
    export PATH="$STUB_BIN:$PATH"
    export GLB_INSTALL_DIR="$TEST_TMP/install-dir"
    export GLB_REPO_URL="https://example.test/GLB.git"
}

teardown() {
    rm -rf "$TEST_TMP"
}

stub_command() {
    local name="$1"
    local body="$2"
    cat > "$STUB_BIN/$name" <<EOF
#!/usr/bin/env bash
$body
EOF
    chmod +x "$STUB_BIN/$name"
}

@test "install.sh errors cleanly when git is not available" {
    # Invoke bash by absolute path (resolved before narrowing PATH) so
    # the interpreter itself doesn't need a PATH lookup - only the
    # script's own `command -v git` check does, which is what this
    # test actually wants to fail. The failure path only uses bash
    # builtins (command, echo, exit), so an empty PATH is safe here.
    local real_bash old_path
    real_bash="$(command -v bash)"
    old_path="$PATH"
    export PATH=""

    run "$real_bash" "$GLB_REPO_ROOT/install.sh"

    export PATH="$old_path"

    [ "$status" -eq 1 ]
    [[ "$output" == *"git is required"* ]]
}

@test "install.sh clones fresh when the install dir doesn't exist yet" {
    stub_command git 'echo "git $*" >> "'"$TEST_TMP"'/calls"; [ "$1" = "clone" ] && mkdir -p "${@: -1}/.git"; exit 0'

    run bash "$GLB_REPO_ROOT/install.sh"

    [ "$status" -eq 0 ]
    grep -q "git clone --depth 1 https://example.test/GLB.git $GLB_INSTALL_DIR" "$TEST_TMP/calls"
    [[ "$output" == *"$GLB_INSTALL_DIR/glb restore"* ]]
}

@test "install.sh updates an existing checkout instead of re-cloning" {
    mkdir -p "$GLB_INSTALL_DIR/.git"
    stub_command git 'echo "git $*" >> "'"$TEST_TMP"'/calls"; exit 0'

    run bash "$GLB_REPO_ROOT/install.sh"

    [ "$status" -eq 0 ]
    [[ "$output" == *"already installed"* ]]
    grep -q -- "-C $GLB_INSTALL_DIR pull --ff-only" "$TEST_TMP/calls"
    ! grep -q "clone" "$TEST_TMP/calls"
}

@test "install.sh refuses to clone over an existing non-GLB directory" {
    mkdir -p "$GLB_INSTALL_DIR"
    echo "unrelated" > "$GLB_INSTALL_DIR/some-file"
    stub_command git 'exit 0'

    run bash "$GLB_REPO_ROOT/install.sh"

    [ "$status" -eq 1 ]
    [[ "$output" == *"already exists and isn't a GLB checkout"* ]]
}
