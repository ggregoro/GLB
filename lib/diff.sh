#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: diff.sh
# Purpose: Compare two profile-shaped directories - a profile, a
#          snapshot (see lib/export.sh), or either against the
#          other - for package and dotfile drift. Both shapes are
#          identical (packages.txt + dotfiles/), so this can diff
#          any combination: a snapshot against the profile it
#          should match, or two snapshots from different machines.
#          See docs/design/state-export-import.md.
# ============================================================

# Prevent direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This module should be sourced, not executed directly."
    exit 1
fi

# ------------------------------------------------------------
# Resolve a name to a directory: checks profiles/<name> first,
# then snapshots/<name>.
# ------------------------------------------------------------

_glb_diff_resolve_dir() {
    local name="$1"

    if [[ -d "$GLB_ROOT/profiles/$name" ]]; then
        printf "%s\n" "$GLB_ROOT/profiles/$name"
        return 0
    fi

    if [[ -d "$GLB_ROOT/snapshots/$name" ]]; then
        printf "%s\n" "$GLB_ROOT/snapshots/$name"
        return 0
    fi

    return 1
}

# ------------------------------------------------------------
# Read a packages.txt into a sorted, deduplicated list of package
# names - same comment/blank-line/inline-comment stripping as
# glb_apply_profile_packages (lib/profile.sh).
# ------------------------------------------------------------

_glb_diff_read_packages() {
    local dir="$1"
    local packages_file="$dir/packages.txt"
    local line package

    [[ -f "$packages_file" ]] || return 0

    while IFS= read -r line; do
        package="${line%%#*}"
        package="$(echo "$package" | xargs)"
        [[ -z "$package" ]] && continue
        printf "%s\n" "$package"
    done < "$packages_file" | sort -u
}

# ------------------------------------------------------------
# Join newline-separated input into a single ", "-separated line.
# ------------------------------------------------------------

_glb_diff_join() {
    local line first=1 joined=""

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$first" -eq 1 ]]; then
            joined="$line"
            first=0
        else
            joined="$joined, $line"
        fi
    done <<< "$1"

    printf "%s" "$joined"
}

# ------------------------------------------------------------
# Report package drift between two directories. Returns 1 if any
# differences were found, 0 if the package lists match exactly.
# ------------------------------------------------------------

_glb_diff_packages() {
    local dir_a="$1"
    local label_a="$2"
    local dir_b="$3"
    local label_b="$4"
    local only_a only_b

    only_a="$(comm -23 <(_glb_diff_read_packages "$dir_a") <(_glb_diff_read_packages "$dir_b"))"
    only_b="$(comm -13 <(_glb_diff_read_packages "$dir_a") <(_glb_diff_read_packages "$dir_b"))"

    if [[ -z "$only_a" && -z "$only_b" ]]; then
        printf "  (no package differences)\n"
        return 0
    fi

    [[ -n "$only_a" ]] && printf "  + only in %s: %s\n" "$label_a" "$(_glb_diff_join "$only_a")"
    [[ -n "$only_b" ]] && printf "  - only in %s: %s\n" "$label_b" "$(_glb_diff_join "$only_b")"

    return 1
}

# ------------------------------------------------------------
# Report dotfile drift between two directories: relative paths that
# exist on only one side, and paths that exist on both but with
# different content. Returns 1 if any differences were found, 0 if
# every tracked dotfile matches exactly.
# ------------------------------------------------------------

_glb_diff_dotfiles() {
    local dir_a="$1"
    local label_a="$2"
    local dir_b="$3"
    local label_b="$4"
    local f rel status=0
    declare -A rel_a=() rel_b=()

    while IFS= read -r -d '' f; do
        rel="${f#*/dotfiles/}"
        rel_a["$rel"]=1
    done < <(find "$dir_a/dotfiles" -type f -not -name '.gitkeep' -print0 2>/dev/null)

    while IFS= read -r -d '' f; do
        rel="${f#*/dotfiles/}"
        rel_b["$rel"]=1
    done < <(find "$dir_b/dotfiles" -type f -not -name '.gitkeep' -print0 2>/dev/null)

    for rel in "${!rel_a[@]}"; do
        if [[ -z "${rel_b[$rel]:-}" ]]; then
            printf "  + only in %s: ~/%s\n" "$label_a" "$rel"
            status=1
        elif ! cmp -s "$dir_a/dotfiles/$rel" "$dir_b/dotfiles/$rel"; then
            printf "  ~ changed: ~/%s\n" "$rel"
            status=1
        fi
    done

    for rel in "${!rel_b[@]}"; do
        [[ -z "${rel_a[$rel]:-}" ]] || continue
        printf "  - only in %s: ~/%s\n" "$label_b" "$rel"
        status=1
    done

    if [[ "$status" -eq 0 ]]; then
        printf "  (no dotfile differences)\n"
    fi

    return "$status"
}

# ------------------------------------------------------------
# glb diff <a> <b>: compare two profiles and/or snapshots (either
# name is looked up in profiles/ then snapshots/) for package and
# dotfile drift. Exit status matches `diff`'s convention: 0 if
# identical, 1 if any differences were found (or on a usage/lookup
# error).
# ------------------------------------------------------------

glb_diff_snapshot() {
    local a="$1"
    local b="$2"
    local dir_a dir_b
    local pkg_status=0
    local dot_status=0

    if [[ -z "$a" || -z "$b" ]]; then
        glb_log_error "Usage: glb diff <profile-or-snapshot> <profile-or-snapshot>"
        return 1
    fi

    dir_a="$(_glb_diff_resolve_dir "$a")" || {
        glb_log_error "Not found (checked profiles/ and snapshots/): $a"
        return 1
    }
    dir_b="$(_glb_diff_resolve_dir "$b")" || {
        glb_log_error "Not found (checked profiles/ and snapshots/): $b"
        return 1
    }

    printf "\n"
    printf "Diff: %s vs %s\n" "$a" "$b"
    printf -- "-------------------------------\n"
    printf "\nPackages:\n"
    _glb_diff_packages "$dir_a" "$a" "$dir_b" "$b" || pkg_status=1
    printf "\nDotfiles:\n"
    _glb_diff_dotfiles "$dir_a" "$a" "$dir_b" "$b" || dot_status=1
    printf "\n"

    [[ "$pkg_status" -eq 0 && "$dot_status" -eq 0 ]]
}
