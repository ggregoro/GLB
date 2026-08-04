This directory mirrors your home directory structure.

Every regular file placed here gets symlinked into `$HOME` at the
matching relative path when you run `glb restore`. For example:

    dotfiles/.zshrc          -> ~/.zshrc
    dotfiles/.config/nvim/init.vim -> ~/.config/nvim/init.vim

If a file already exists at the destination (and isn't already a
symlink to this one), it gets renamed to `<name>.glb-backup` before
the new symlink is created, so nothing is lost.

This README is not itself linked anywhere; it's just documentation.
Delete it or leave it, it won't be touched.
