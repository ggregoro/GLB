#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
# Installer: curl -fsSL <url>/install.sh | sh
#
# Clones GLB into ~/.local/share/glb (or updates it if already
# there) and tells you the next command to run. Does not run
# `glb restore` itself - that's an opinionated, interactive step
# (package installs, dotfile changes) that shouldn't happen as a
# surprise side effect of "get GLB onto my machine."
# ============================================================

set -euo pipefail

GLB_INSTALL_DIR="${GLB_INSTALL_DIR:-$HOME/.local/share/glb}"
GLB_REPO_URL="${GLB_REPO_URL:-https://github.com/ggregoro/GLB.git}"

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required to install GLB. Please install git and try again." >&2
    exit 1
fi

if [[ -d "$GLB_INSTALL_DIR/.git" ]]; then
    echo "GLB is already installed at $GLB_INSTALL_DIR - updating..."
    git -C "$GLB_INSTALL_DIR" pull --ff-only
elif [[ -e "$GLB_INSTALL_DIR" ]]; then
    echo "Error: $GLB_INSTALL_DIR already exists and isn't a GLB checkout." >&2
    echo "Move it aside or set GLB_INSTALL_DIR to a different location and try again." >&2
    exit 1
else
    echo "Cloning GLB to $GLB_INSTALL_DIR..."
    git clone --depth 1 "$GLB_REPO_URL" "$GLB_INSTALL_DIR"
fi

echo ""
echo "GLB installed. Run this to set up your shell:"
echo ""
echo "    $GLB_INSTALL_DIR/glb restore"
echo ""
echo "(After that first run, 'glb' itself will be on your PATH, so you"
echo "can just run 'glb restore', 'glb update', etc. directly.)"
