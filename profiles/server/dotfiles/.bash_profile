# ~/.bash_profile: executed by bash(1) for LOGIN shells. Interactive
# non-login shells (most terminal windows) read ~/.bashrc directly and
# never touch this file - but a login shell (a raw console/tty, some
# VM consoles, `bash -l`, and most SSH sessions - relevant here since
# `server` is aimed at remote administration) reads ONLY this file,
# not .bashrc, unless something here says otherwise. Most distros' own
# /etc/skel/.bash_profile already does this, but GLB ships its own so
# ~/.bashrc loads the same way regardless of what the OS default did
# or didn't set up - see `default`'s copy of this file for the bug
# this fixes (a minimal Fedora VM, 2026-09-12).

if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
