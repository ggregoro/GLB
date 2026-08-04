#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: profile.sh
# Purpose: Apply a profile (packages + dotfiles) to a fresh install.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Internal helper: resolve a profile's directory
# ------------------------------------------------------------

_glb_profile_dir() {
    printf "%s/profiles/%s\n" "$GLB_ROOT" "$1"
}

# ------------------------------------------------------------
# Install every package listed in a profile's packages.txt
# ------------------------------------------------------------

glb_apply_profile_packages() {
    local profile_dir="$1"
    local packages_file="$profile_dir/packages.txt"
    local line package

    if [[ ! -f "$packages_file" ]]; then
        glb_log_warn "No packages.txt found, skipping packages."
        return 0
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        package="${line%%#*}"
        package="$(echo "$package" | xargs)"

        [[ -z "$package" ]] && continue

        if glb_package_installed "$package" 2>/dev/null; then
            glb_log_info "Already installed: $package"
            continue
        fi

        glb_install_package "$package"
    done < "$packages_file"
}

# ------------------------------------------------------------
# Symlink every file under a profile's dotfiles/ into $HOME,
# backing up anything already there.
# ------------------------------------------------------------

glb_apply_profile_dotfiles() {
    local profile_dir="$1"
    local dotfiles_dir="$profile_dir/dotfiles"
    local src rel dest

    if [[ ! -d "$dotfiles_dir" ]]; then
        glb_log_warn "No dotfiles directory found, skipping dotfiles."
        return 0
    fi

    while IFS= read -r -d '' src; do
        rel="${src#"$dotfiles_dir"/}"
        dest="$HOME/$rel"

        glb_create_directory "$(dirname "$dest")"

        if [[ -L "$dest" ]] && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
            glb_log_info "Already linked: ~/$rel"
            continue
        fi

        if [[ -e "$dest" || -L "$dest" ]]; then
            glb_log_warn "Backing up existing ~/$rel -> ~/$rel.glb-backup"
            mv "$dest" "$dest.glb-backup"
        fi

        ln -s "$src" "$dest"
        glb_log_success "Linked ~/$rel"
    done < <(find "$dotfiles_dir" -type f -not -name '.gitkeep' -print0)
}

# ------------------------------------------------------------
# Apply a named profile: packages, then dotfiles
# ------------------------------------------------------------

glb_apply_profile() {
    local name="${1:-default}"
    local profile_dir
    profile_dir="$(_glb_profile_dir "$name")"

    if [[ ! -d "$profile_dir" ]]; then
        glb_log_error "Profile not found: $name"
        return 1
    fi

    glb_log_info "Applying profile: $name"

    glb_apply_profile_packages "$profile_dir"
    glb_apply_profile_dotfiles "$profile_dir"

    glb_log_success "Profile applied: $name"
}

# ------------------------------------------------------------
# List available profiles
# ------------------------------------------------------------

glb_list_profiles() {
    local profiles_root="$GLB_ROOT/profiles"
    local dir

    if [[ ! -d "$profiles_root" ]]; then
        glb_log_warn "No profiles directory found."
        return 0
    fi

    printf "\n"
    printf "Available Profiles\n"
    printf -- "-------------------\n"
    for dir in "$profiles_root"/*/; do
        [[ -d "$dir" ]] || continue
        printf "  %s\n" "$(basename "$dir")"
    done
    printf "\n"
}
