# Shared setup for GLB bats tests.
#
# Every test gets its own copy of glb + lib/ under a temp GLB_ROOT and its
# own temp HOME, so tests never touch the real repo's profiles/ or the
# real user's home directory. A stub bin dir is prepended to PATH so
# package-manager / sudo calls can be faked per test.

GLB_REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Resolved once, before any test prepends STUB_BIN to PATH, so
# stub_command's "bash" special-case (see below) always has a real
# interpreter to fall back to regardless of what's stubbed later.
GLB_REAL_BASH="$(command -v bash)"

glb_setup_sandbox() {
    TEST_TMP="$(mktemp -d)"
    export TEST_TMP
    export HOME="$TEST_TMP/home"
    export GLB_ROOT="$TEST_TMP/glb"

    mkdir -p "$HOME" "$GLB_ROOT"
    cp "$GLB_REPO_ROOT/glb" "$GLB_ROOT/glb"
    cp "$GLB_REPO_ROOT/VERSION" "$GLB_ROOT/VERSION"
    cp -r "$GLB_REPO_ROOT/lib" "$GLB_ROOT/lib"
    cp -r "$GLB_REPO_ROOT/completions" "$GLB_ROOT/completions"
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
#
# Every stub uses an absolute bash shebang ($GLB_REAL_BASH), not
# `#!/usr/bin/env bash`. This matters as soon as any test also stubs
# "bash" itself (to intercept a `curl | bash` install target): `env`
# does its own PATH lookup for "bash" to interpret a script's shebang,
# and with STUB_BIN prepended to PATH, that lookup would resolve to
# the fake "bash" stub instead of a real interpreter - silently
# breaking every *other* stub in the same test (their shebang
# processing never reaches their actual body). An absolute path
# bypasses that lookup entirely, for every stub, all the time.
#
# Stubbing "bash" itself needs one more piece of special handling on
# top of that: bats' own `run bash -c "..."` invocations, glb's own
# `#!/usr/bin/env bash` shebang (invoked by the kernel/env as `bash
# <script-path> [args...]`, not `-c`), and any other real script
# invocation all resolve "bash" via PATH too, same as the code under
# test's own `curl | bash`. The actual `curl | bash` pipe target is
# always invoked with zero arguments (it reads its script from stdin);
# every other real invocation always has at least one argument (a
# script path, or `-c`). So: any arguments at all means "run this for
# real," passed straight through to the real bash - only a truly
# bare, argument-less invocation runs <script-body>.
stub_command() {
    local name="$1"
    local body="$2"

    if [[ "$name" == "bash" ]]; then
        cat > "$STUB_BIN/$name" <<EOF
#!$GLB_REAL_BASH
if [ "\$#" -gt 0 ]; then
    exec "$GLB_REAL_BASH" "\$@"
fi
$body
EOF
    else
        cat > "$STUB_BIN/$name" <<EOF
#!$GLB_REAL_BASH
$body
EOF
    fi
    chmod +x "$STUB_BIN/$name"
}
