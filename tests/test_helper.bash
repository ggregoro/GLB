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

# Commands GLB's extras install and detect with `command -v`
# (glb_command_exists). Tests must behave the same whether or not the
# host already has them - a test that wants one present stubs it into
# STUB_BIN, which is always first on PATH.
GLB_HIDDEN_COMMANDS=(fresh nvim yazi checkupdates paru notify-send)

# _glb_build_shadow_path <dest> [path]
# Populate <dest> with a symlink to every executable reachable on
# [path] (default: the current PATH) except GLB_HIDDEN_COMMANDS. First
# entry wins for duplicate names, matching normal lookup order. [path]
# is a parameter, not a PATH override, so callers can scan a fake PATH
# without losing the mkdir/find/xargs/ln this function itself needs.
_glb_build_shadow_path() {
    local dest="$1" scan_path="${2:-$PATH}" dir name
    local -a excl=()

    for name in "${GLB_HIDDEN_COMMANDS[@]}"; do
        excl+=(! -name "$name")
    done

    mkdir -p "$dest"
    while IFS= read -r dir; do
        [[ -d "$dir" ]] || continue
        find "$dir" -maxdepth 1 \( -type f -o -type l \) -perm -u+x \
            "${excl[@]}" -print0 2>/dev/null \
            | xargs -0 -r ln -s -t "$dest" 2>/dev/null || true
    done < <(printf '%s\n' "${scan_path//:/$'\n'}")
}

# _glb_shadow_path
# Print the directory _glb_build_shadow_path produced, building it once
# per bats run (BATS_RUN_TMPDIR) rather than once per test - a full
# build costs ~1s and the suite has hundreds of tests. Falls back to a
# per-test copy under TEST_TMP on a bats old enough to lack
# BATS_RUN_TMPDIR. Must run before PATH is modified, so it sees the
# host's real PATH.
_glb_shadow_path() {
    local dir tmp

    if [[ -z "${BATS_RUN_TMPDIR:-}" ]]; then
        dir="$TEST_TMP/shadow-bin"
        _glb_build_shadow_path "$dir"
        printf '%s\n' "$dir"
        return 0
    fi

    dir="$BATS_RUN_TMPDIR/glb-shadow-bin"
    if [[ ! -d "$dir" ]]; then
        tmp="$dir.$$"
        _glb_build_shadow_path "$tmp"
        # Atomic publish: if another job got there first, keep theirs.
        mv "$tmp" "$dir" 2>/dev/null || rm -rf "$tmp"
    fi
    printf '%s\n' "$dir"
}

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
    # Not "$STUB_BIN:$PATH": the host's real PATH would let tests see
    # whatever GLB itself already installed on this machine (fresh,
    # nvim, ...) and any test that assumes those are absent would fail
    # on every box GLB has been applied to. See _glb_shadow_path.
    export PATH="$STUB_BIN:$(_glb_shadow_path)"

    # _glb_ensure_snap_dir (lib/extras.sh) operates on a real, absolute
    # filesystem path by design (it manages an actual /snap symlink on
    # the real machine) - so unlike everything else sandboxed above, it
    # will happily touch the REAL /snap outside any test's control
    # unless every test that can reach the snap install path overrides
    # it. Set the override here, once, for the whole suite, rather than
    # trusting every current and future test to remember it themselves.
    export _GLB_SNAP_DIR="$TEST_TMP/snap"
    export _GLB_SNAPD_DIR="$TEST_TMP/var-lib-snapd-snap"
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

# stub_release_download_tools
# Stubs curl/tar/unzip so a profile restore's downloaded extras "install"
# for real inside the sandbox: curl writes an empty file for -o (and
# fails .sha256 lookups, which GLB treats as "no checksum published"),
# tar extracts a fake nvim tree, unzip yields either a font or a fake
# yazi archive depending on the archive name. Lets an end-to-end restore
# test pass without depending on nvim/yazi/fonts already being on the
# host.
stub_release_download_tools() {
    stub_command curl 'out=""; url=""
        while [ "$#" -gt 0 ]; do case "$1" in
            -o) out="$2"; shift 2 ;;
            -f|-s|-S|-L|-fsSL) shift ;;
            *) url="$1"; shift ;;
        esac; done
        if [ -n "$out" ]; then
            case "$url" in *.sha256) exit 22 ;; *) : > "$out"; exit 0 ;; esac
        fi
        exit 0'
    stub_command tar 'dest=""; while [ "$#" -gt 0 ]; do case "$1" in
            -C) dest="$2"; shift 2 ;;
            --strip-components=*) shift ;;
            *) shift ;;
        esac; done
        mkdir -p "$dest/bin"; printf "#!/bin/sh\n" > "$dest/bin/nvim"; chmod +x "$dest/bin/nvim"; exit 0'
    stub_command unzip 'archive=""; dest="${@: -1}"
        for a in "$@"; do case "$a" in *.zip) archive="$a" ;; esac; done
        mkdir -p "$dest"
        case "$archive" in
            *yazi*)
                mkdir -p "$dest/yazi-x86_64-unknown-linux-gnu"
                printf "not executable\n" > "$dest/yazi-x86_64-unknown-linux-gnu/yazi.bash"
                printf "#!/bin/sh\necho yazi\n" > "$dest/yazi-x86_64-unknown-linux-gnu/yazi"
                chmod +x "$dest/yazi-x86_64-unknown-linux-gnu/yazi"
                ;;
            *) touch "$dest/Fake-Regular.ttf" ;;
        esac
        exit 0'
}
