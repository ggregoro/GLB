#!/usr/bin/env bash
#
# ============================================================
# GLB - Greg's Linux Bootstrap
#
# Module: banner.sh
# Purpose: Display the GLB application banner.
# ============================================================

glb_show_banner() {
    local version="$1"

    printf "\n"
    printf "============================================================\n"
    printf "             Greg's Linux Bootstrap (GLB)\n"
    printf "                     Version %s\n" "$version"
    printf "============================================================\n"
    printf "\n"
}
