#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: extras.sh
# Purpose: Install software that doesn't fit the plain
#          apt/dnf/pacman/zypper packages.txt model - curl-install
#          scripts, Flatpak apps, and Snap packages - driven by a
#          profile's extras.txt.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Some snap / github-release extras have a real native package on
# certain package managers - when that's true, check/install/update
# through the plain package manager instead, sidestepping a snap/snapd
# (or a hand-managed binary in ~/.local/bin) where it isn't actually
# needed. Keyed "<name>:<package-manager>" -> the native package name.
#
# yazi:pacman - confirmed real (2026-08-16): Arch's own `extra` repo
# ships `yazi` directly, unlike CachyOS/EndeavourOS's snapd, which is
# AUR-only (see _GLB_PACKAGE_SKIP in lib/package.sh). Flagged as a
# known follow-up in packages.txt/CLAUDE.md since 2026-08-13, built
# now. zypper has no native yazi package at all (would need a
# non-default OBS repo), so it deliberately has no entry here - the
# snap method (and its own known snapd gap) stays the only path there.
#
# ghostty:pacman / ghostty:zypper - Ghostty (default's terminal-emulator
# exception for yazi image preview, see profiles/default/extras.txt and
# docs/PHILOSOPHY.md) ships as a native `ghostty` package in Arch's
# `extra` repo and in openSUSE's repo-oss - both confirmed. zypper does
# get an entry here (unlike yazi), so openSUSE installs Ghostty natively
# even though snapd isn't available there. No dnf entry: Fedora packages
# Ghostty only via COPR, not its official repos, and GLB doesn't route
# through non-default repos (same call as lazygit on dnf) - Fedora falls
# through to snap. apt has no Ghostty package on any Debian/Ubuntu-family
# distro, so it falls through to snap too, with the same snapd caveats
# yazi carries (notably Mint's nosnap.pref block).
#
# atuin:pacman / atuin:dnf / atuin:zypper - atuin (default's shell-history
# tool, see profiles/default/extras.txt) has a real native package on all
# three: Arch `extra` (confirmed), Fedora's official repos, and openSUSE
# (both believed-good, not yet VM-confirmed). apt has no atuin package,
# so Debian/Ubuntu/Pop!_OS/Mint use the `github-release` method (a
# static gnu binary dropped in ~/.local/bin). The atuin *snap* is
# deliberately not used: its strict confinement can't write
# ~/.config/atuin or ~/.local/share/atuin, `snap run` strips the
# ATUIN_*_DIR overrides that would redirect them, and `scripts` /
# `atuin import auto` don't work through the sandbox.
#
# fastfetch:dnf / fastfetch:pacman / fastfetch:zypper - fastfetch is a
# native package in Fedora's official repos, Arch `extra`, and openSUSE.
# It is NOT in apt's index on GLB's fresh-VM targets (Pop!_OS 24.04,
# Linux Mint 22.x - "no installation candidate", confirmed twice), so
# on apt it moves to the `github-release` method
# (fastfetch-cli/fastfetch, upstream tarball -> ~/.local/bin) rather
# than the manual-step pause a bare packages.txt entry used to force.
#
# nvim:pacman / nvim:dnf - apt's `neovim` is too old for LazyVim (0.9.5
# on Pop!_OS/Debian/Ubuntu/Mint; LazyVim needs >= 0.11.2), hit for real
# on Greg's E7450 (2026-09-06/2026-09-11) - `nvim` refused to load with
# "requires 0.11.2". Confirmed current on Arch `extra` (pacman) and
# Fedora's official repos (dnf), so those two route to the native
# `neovim` package via the `github-release-tree` method below instead
# of the upstream tarball. zypper deliberately has NO entry - openSUSE
# Tumbleweed's neovim version isn't verified either way, so it falls
# through to the same upstream-tarball path apt uses (always correct,
# just not the most native option there until confirmed) rather than
# risk silently shipping the same too-old-for-LazyVim bug this override
# exists to avoid.
# ------------------------------------------------------------

declare -gA _GLB_EXTRA_NATIVE_OVERRIDES=(
    [yazi:pacman]="yazi"
    [ghostty:pacman]="ghostty"
    [ghostty:zypper]="ghostty"
    [atuin:pacman]="atuin"
    [atuin:dnf]="atuin"
    [atuin:zypper]="atuin"
    [fastfetch:dnf]="fastfetch"
    [fastfetch:pacman]="fastfetch"
    [fastfetch:zypper]="fastfetch"
    [nvim:pacman]="neovim"
    [nvim:dnf]="neovim"
)

_glb_extra_native_package() {
    local name="$1"
    local pkg_mgr

    pkg_mgr="$(glb_detect_package_manager)" || return 1
    printf "%s\n" "${_GLB_EXTRA_NATIVE_OVERRIDES[${name}:${pkg_mgr}]:-}"
}

# ------------------------------------------------------------
# Download <asset> from <repo>'s latest GitHub release to
# <dest_dir>/<asset>, verifying a sibling "<asset>.sha256" when the
# release publishes one (skipped, not an error, when it doesn't).
# Shared by both github-release install methods below. Deliberately
# does NOT report the downloaded path via a `$(...)` capture - GLB's
# glb_log_* helpers write to stdout, and capturing this function's
# stdout would silently swallow their output into the "path" instead
# of showing it. The caller already knows the path is
# "<dest_dir>/<asset>" (that's exactly what's downloaded to), so there
# is nothing to hand back beyond a plain success/failure.
# ------------------------------------------------------------

_glb_download_release_asset() {
    local repo="$1"
    local asset="$2"
    local dest_dir="$3"
    local base="https://github.com/$repo/releases/latest/download"
    local archive="$dest_dir/$asset"
    local want have

    if ! curl -fsSL "$base/$asset" -o "$archive"; then
        glb_log_error "Could not download $asset from $repo's latest release"
        return 1
    fi

    if curl -fsSL "$base/$asset.sha256" -o "$archive.sha256" 2>/dev/null \
        && [[ -s "$archive.sha256" ]]; then
        want="$(awk '{print $1}' "$archive.sha256")"
        have="$(sha256sum "$archive" | awk '{print $1}')"
        if [[ "$want" != "$have" ]]; then
            glb_log_error "Checksum mismatch for $asset (expected $want, got $have)"
            return 1
        fi
        glb_log_info "Checksum verified: $asset"
    fi
}

# ------------------------------------------------------------
# Download a project's latest GitHub release asset and drop its
# <name> binary into ~/.local/bin. <asset> is a literal filename
# (GLB doesn't do per-arch substitution anywhere else, so profiles
# name the asset they want) fetched from
#   https://github.com/<owner/repo>/releases/latest/download/<asset>
# .tar.*/.zip archives are unpacked and the <name> file located
# within; anything else is treated as a raw binary.
# ------------------------------------------------------------

_glb_install_github_release() {
    local name="$1"
    local repo="$2"
    local asset="$3"
    local bindir="$HOME/.local/bin"
    local tmp archive found

    if [[ -z "$name" || -z "$repo" || -z "$asset" ]]; then
        glb_log_error "github-release: expected <name> <owner/repo> <asset>"
        return 1
    fi

    tmp="$(mktemp -d)" || return 1
    archive="$tmp/$asset"

    if ! _glb_download_release_asset "$repo" "$asset" "$tmp"; then
        rm -rf "$tmp"
        return 1
    fi

    if ! glb_create_directory "$bindir"; then
        rm -rf "$tmp"
        return 1
    fi

    case "$asset" in
        *.tar.gz|*.tgz|*.tar.xz|*.tar.bz2|*.tar.zst|*.tar)
            mkdir -p "$tmp/x"
            if ! tar -xf "$archive" -C "$tmp/x"; then
                glb_log_error "Could not extract $asset"
                rm -rf "$tmp"
                return 1
            fi
            ;;
        *.zip)
            mkdir -p "$tmp/x"
            if ! unzip -o -q "$archive" -d "$tmp/x"; then
                glb_log_error "Could not unzip $asset"
                rm -rf "$tmp"
                return 1
            fi
            ;;
        *)
            install -m 0755 "$archive" "$bindir/$name"
            rm -rf "$tmp"
            if [[ -x "$bindir/$name" ]]; then
                glb_log_success "Installed $name -> $bindir/$name"
                return 0
            fi
            return 1
            ;;
    esac

    found="$(find "$tmp/x" -type f -name "$name" -perm -u+x -print -quit)"
    [[ -z "$found" ]] && found="$(find "$tmp/x" -type f -name "$name" -print -quit)"
    if [[ -z "$found" ]]; then
        glb_log_error "No '$name' binary found inside $asset"
        rm -rf "$tmp"
        return 1
    fi

    install -m 0755 "$found" "$bindir/$name"
    rm -rf "$tmp"

    if [[ -x "$bindir/$name" ]]; then
        glb_log_success "Installed $name -> $bindir/$name"
        return 0
    fi

    glb_log_error "github-release install of $name did not produce $bindir/$name"
    return 1
}

# ------------------------------------------------------------
# Download a project's latest GitHub release asset and extract it
# WHOLE into ~/.local, stripping the archive's one top-level directory
# so a bin/lib/share tree merges straight into ~/.local/{bin,lib,share}.
# For tools whose binary looks up sibling files (runtime data,
# libraries) at a path relative to itself - Neovim's `nvim` needs its
# own lib/nvim + share/nvim/runtime alongside it, or it can't find
# syntax/ftplugin/colorscheme files (confirmed: `bin/nvim` copied out
# on its own errors "E484: Can't open file .../syntax/syntax.vim").
# `github-release` (above) is for a single self-contained binary;
# this is for anything that isn't one. Only tar archives are supported
# (nvim's Linux releases are the only current user of this method; zip
# support can be added if something else needs it).
# ------------------------------------------------------------

_glb_install_github_release_tree() {
    local name="$1"
    local repo="$2"
    local asset="$3"
    local target="$HOME/.local"
    local tmp archive

    if [[ -z "$name" || -z "$repo" || -z "$asset" ]]; then
        glb_log_error "github-release-tree: expected <name> <owner/repo> <asset>"
        return 1
    fi

    case "$asset" in
        *.tar.gz|*.tgz|*.tar.xz|*.tar.bz2|*.tar.zst|*.tar) ;;
        *)
            glb_log_error "github-release-tree: $asset is not a supported archive (tar only)"
            return 1
            ;;
    esac

    tmp="$(mktemp -d)" || return 1
    archive="$tmp/$asset"

    if ! _glb_download_release_asset "$repo" "$asset" "$tmp"; then
        rm -rf "$tmp"
        return 1
    fi

    if ! glb_create_directory "$target"; then
        rm -rf "$tmp"
        return 1
    fi

    if ! tar -xf "$archive" -C "$target" --strip-components=1; then
        glb_log_error "Could not extract $asset"
        rm -rf "$tmp"
        return 1
    fi

    rm -rf "$tmp"

    if [[ -x "$target/bin/$name" ]]; then
        glb_log_success "Installed $name -> $target/bin/$name"
        return 0
    fi

    glb_log_error "github-release-tree install of $name did not produce $target/bin/$name"
    return 1
}

# ------------------------------------------------------------
# Check whether an extra is already installed
# ------------------------------------------------------------

glb_extra_installed() {
    local method="$1"
    local name="$2"
    local spec="$3"
    local native

    case "$method" in
        curl)
            glb_command_exists "$name"
            ;;
        flatpak)
            flatpak info "$spec" >/dev/null 2>&1
            ;;
        font)
            compgen -G "$HOME/.local/share/fonts/$name/*.[ot]tf" >/dev/null
            ;;
        snap)
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                glb_package_installed "$native"
            else
                snap list "$name" >/dev/null 2>&1
            fi
            ;;
        github-release | github-release-tree)
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                glb_package_installed "$native"
            else
                glb_command_exists "$name"
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Internal helper: pause for a failed extra's manual step, then
# recheck whether it's installed
# ------------------------------------------------------------

_glb_extras_prompt_and_recheck() {
    local method="$1"
    local name="$2"
    local spec="$3"
    local cmd_display="$4"

    if ! glb_prompt_manual_step "$cmd_display" "install $name"; then
        return 1
    fi

    if glb_extra_installed "$method" "$name" "$spec"; then
        glb_log_success "Confirmed installed after manual step: $name"
        return 0
    fi

    glb_log_warn "Still not detected as installed: $name"
    return 1
}

# ------------------------------------------------------------
# Install a single extra
# ------------------------------------------------------------

glb_install_extra() {
    local method="$1"
    local name="$2"
    local spec="$3"
    local pipe_status

    case "$method" in
        curl)
            glb_log_info "Installing $name via curl-install script"
            curl -fsSL "$spec" | bash
            # PIPESTATUS is clobbered by the very next simple command
            # (even a plain assignment), so capture the whole array in
            # one shot rather than reading two separate indices.
            pipe_status=("${PIPESTATUS[@]}")

            if [[ "${pipe_status[0]}" -eq 0 && "${pipe_status[1]}" -eq 0 ]]; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" "curl -fsSL $spec | bash"
            ;;
        flatpak)
            glb_log_info "Installing $name via Flatpak ($spec)"
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1

            if flatpak install -y flathub "$spec"; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" "flatpak install -y flathub $spec"
            ;;
        font)
            glb_log_info "Installing font: $name"
            local font_dir="$HOME/.local/share/fonts/$name"
            local tmp_zip
            tmp_zip="$(mktemp --suffix=.zip)"

            if curl -fsSL "$spec" -o "$tmp_zip" && glb_create_directory "$font_dir" \
                && unzip -o -q "$tmp_zip" -d "$font_dir"; then
                rm -f "$tmp_zip"
                glb_command_exists fc-cache && fc-cache -f "$font_dir" >/dev/null 2>&1
                return 0
            fi

            rm -f "$tmp_zip"
            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" \
                "curl -fsSL $spec -o font.zip && mkdir -p $font_dir && unzip -o font.zip -d $font_dir && fc-cache -f $font_dir"
            ;;
        snap)
            local native
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                glb_log_info "Installing $name via the package manager ($native), not snap"
                glb_install_package "$native"
                return $?
            fi

            glb_log_info "Installing $name via snap${spec:+ (--$spec)}"

            if glb_sudo snap install "$name" ${spec:+--$spec}; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" \
                "sudo snap install $name${spec:+ --$spec}"
            ;;
        github-release)
            local native repo asset
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                glb_log_info "Installing $name via the package manager ($native), not a GitHub release"
                glb_install_package "$native"
                return $?
            fi

            read -r repo asset <<< "$spec"
            glb_log_info "Installing $name from ${repo}'s latest GitHub release"

            if _glb_install_github_release "$name" "$repo" "$asset"; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" \
                "download $asset from https://github.com/$repo/releases/latest and put its '$name' binary in ~/.local/bin"
            ;;
        github-release-tree)
            local native repo asset
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                glb_log_info "Installing $name via the package manager ($native), not a GitHub release"
                glb_install_package "$native"
                return $?
            fi

            read -r repo asset <<< "$spec"
            glb_log_info "Installing $name from ${repo}'s latest GitHub release"

            if _glb_install_github_release_tree "$name" "$repo" "$asset"; then
                return 0
            fi

            _glb_extras_prompt_and_recheck "$method" "$name" "$spec" \
                "download $asset from https://github.com/$repo/releases/latest, extract it, and copy its bin/lib/share tree into ~/.local"
            ;;
        *)
            glb_log_error "Unknown extras method: $method"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Re-run a single already-installed extra's install step, to pick
# up whatever's current. Distinct per method from glb_install_extra:
# flatpak uses the native "update" verb rather than "install", and
# neither curl nor font need the not-yet-installed framing (no
# manual-step pause on failure - matches glb update's existing
# unprompted style, this isn't the first install attempt).
# ------------------------------------------------------------

_glb_update_extra() {
    local method="$1"
    local name="$2"
    local spec="$3"
    local pipe_status

    case "$method" in
        curl)
            glb_log_info "Updating $name via curl-install script"
            curl -fsSL "$spec" | bash
            # See glb_install_extra's curl case for why PIPESTATUS is
            # captured as a whole array rather than read index by index.
            pipe_status=("${PIPESTATUS[@]}")
            [[ "${pipe_status[0]}" -eq 0 && "${pipe_status[1]}" -eq 0 ]]
            ;;
        flatpak)
            glb_log_info "Updating $name via Flatpak ($spec)"
            flatpak update -y "$spec"
            ;;
        font)
            glb_log_info "Updating font: $name"
            local font_dir="$HOME/.local/share/fonts/$name"
            local tmp_zip
            tmp_zip="$(mktemp --suffix=.zip)"

            if curl -fsSL "$spec" -o "$tmp_zip" && unzip -o -q "$tmp_zip" -d "$font_dir"; then
                rm -f "$tmp_zip"
                glb_command_exists fc-cache && fc-cache -f "$font_dir" >/dev/null 2>&1
                return 0
            fi

            rm -f "$tmp_zip"
            return 1
            ;;
        snap)
            local native
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                # Native package - already kept current by
                # glb_update_packages (the plain package-manager
                # update), nothing extra to do here.
                return 0
            fi

            glb_log_info "Updating $name via snap"
            glb_sudo snap refresh "$name"
            ;;
        github-release)
            local native repo asset
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                # Native package - kept current by glb_update_packages,
                # nothing extra to do here.
                return 0
            fi

            read -r repo asset <<< "$spec"
            glb_log_info "Updating $name from ${repo}'s latest GitHub release"
            _glb_install_github_release "$name" "$repo" "$asset"
            ;;
        github-release-tree)
            local native repo asset
            native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                # Native package - kept current by glb_update_packages,
                # nothing extra to do here.
                return 0
            fi

            read -r repo asset <<< "$spec"
            glb_log_info "Updating $name from ${repo}'s latest GitHub release"
            _glb_install_github_release_tree "$name" "$repo" "$asset"
            ;;
        *)
            glb_log_error "Unknown extras method: $method"
            return 1
            ;;
    esac
}

# ------------------------------------------------------------
# Re-run every currently-installed extra in a profile's extras.txt,
# to pick up updates. Extras that were never installed in the first
# place are silently skipped - nothing to key an update against.
# ------------------------------------------------------------

glb_update_profile_extras() {
    local profile_dir="$1"
    local extras_file="$profile_dir/extras.txt"
    local line method name spec
    local failed=()

    if [[ ! -f "$extras_file" ]]; then
        return 0
    fi

    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"

        [[ -z "$line" ]] && continue

        read -r method name spec <<< "$line"

        if ! glb_extra_installed "$method" "$name" "$spec"; then
            continue
        fi

        if ! _glb_update_extra "$method" "$name" "$spec"; then
            glb_log_error "Failed to update: $name"
            failed+=("$name")
        fi
    done 3< "$extras_file"

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to update ${#failed[@]} extra(s): ${failed[*]}"
        return 1
    fi
}

# ------------------------------------------------------------
# Install every extra listed in a profile's extras.txt
# ------------------------------------------------------------

glb_apply_profile_extras() {
    local profile_dir="$1"
    local dry_run="${2:-}"
    local extras_file="$profile_dir/extras.txt"
    local line method name spec
    local failed=()

    if [[ ! -f "$extras_file" ]]; then
        return 0
    fi

    # Read extras_file on fd 3, not stdin (fd 0) - same reasoning as
    # glb_apply_profile_packages in lib/profile.sh: glb_install_extra can
    # fall through to glb_prompt_manual_step's interactive `read -p`,
    # which needs real stdin free rather than the next extras_file line.
    while IFS= read -r line <&3 || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"

        [[ -z "$line" ]] && continue

        read -r method name spec <<< "$line"

        if glb_extra_installed "$method" "$name" "$spec"; then
            glb_log_info "Already installed: $name"
            continue
        fi

        if [[ "$dry_run" == "--dry-run" ]]; then
            local native=""
            [[ "$method" == "snap" || "$method" == "github-release" || "$method" == "github-release-tree" ]] \
                && native="$(_glb_extra_native_package "$name")"
            if [[ -n "$native" ]]; then
                glb_log_info "Would install: $name (via the package manager, $native - not $method)"
            else
                glb_log_info "Would install: $name (via $method)"
            fi
            continue
        fi

        if ! glb_install_extra "$method" "$name" "$spec"; then
            glb_log_error "Failed to install: $name"
            failed+=("$name")
        fi
    done 3< "$extras_file"

    if [[ ${#failed[@]} -gt 0 ]]; then
        glb_log_error "Failed to install ${#failed[@]} extra(s): ${failed[*]}"
        return 1
    fi
}
