# Shared setup for GLB bats tests.
#
# Every test gets its own copy of glb + lib/ under a temp GLB_ROOT and its
# own temp HOME, so tests never touch the real repo's profiles/ or the
# real user's home directory. A stub bin dir is prepended to PATH so
# package-manager / sudo calls can be faked per test.

GLB_REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

glb_setup_sandbox() {
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    export HOME="$TEST_TMP/home"
    export GLB_ROOT="$TEST_TMP/glb"

    mkdir -p "$HOME" "$GLB_ROOT"
    cp "$GLB_REPO_ROOT/glb" "$GLB_ROOT/glb"
    cp "$GLB_REPO_ROOT/VERSION" "$GLB_ROOT/VERSION"
    cp -r "$GLB_REPO_ROOT/lib" "$GLB_ROOT/lib"
    mkdir -p "$GLB_ROOT/profiles"

    STUB_BIN="$TEST_TMP/bin"
    export STUB_BIN
    mkdir -p "$STUB_BIN"
    export PATH="$STUB_BIN:$PATH"
}

glb_teardown_sandbox() {
    [[ -n "${TEST_TMP:-}" && -d "$TEST_TMP" ]] && rm -rf "$TEST_TMP"
}

# stub_command <name> <script-body>
# Writes an executable "$name" into STUB_BIN that runs <script-body>.
stub_command() {
    local name="$1"
    local body="$2"
    cat > "$STUB_BIN/$name" <<EOF
#!/usr/bin/env bash
$body
EOF
    chmod +x "$STUB_BIN/$name"
}
