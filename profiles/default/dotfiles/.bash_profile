# ~/.bash_profile: executed by bash(1) for LOGIN shells. Interactive
# non-login shells (most terminal windows) read ~/.bashrc directly and
# never touch this file - but a login shell (a raw console/tty, some
# VM consoles, `bash -l`, some SSH configurations) reads ONLY this
# file, not .bashrc, unless something here says otherwise. Most
# distros' own /etc/skel/.bash_profile already does this, but GLB
# ships its own so ~/.bashrc (Starship, aliases, PATH, everything)
# loads the same way regardless of what the OS default did or didn't
# set up - confirmed missing on a minimal Fedora VM (2026-09-12): bash
# fell back to its bare compiled-in prompt while fish/zsh, which always
# read their own rc file, worked fine.

if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
