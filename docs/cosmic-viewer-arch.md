# COSMIC Viewer on Arch

How to build and install COSMIC Viewer (`cosmic-viewer`, the COSMIC
desktop's image viewer) on Arch and Arch-based distros (EndeavourOS,
CachyOS), how to fix it when an update breaks it, and how Ranger uses it.

Arch doesn't package COSMIC Viewer. The AUR only has `cosmic-viewer-git`,
which builds from source the same way this page does. So on Arch it's
built by hand.

## Build and install

1. **Install the build dependencies.**
   ```
   sudo pacman -Syu
   sudo pacman -S --needed base-devel git rust just cmake nasm pkgconf
   sudo pacman -S --needed libheif libxkbcommon wayland mesa libinput
   ```
2. **Get the source.**
   ```
   cd ~/Projects
   git clone https://github.com/pop-os/cosmic-viewer
   cd cosmic-viewer
   ```
3. **Build it.** Allow about 15–25 minutes the first time.
   ```
   just build-release
   ```
4. **Install it.** This copies the program, its menu entry and its icons
   into `/usr`.
   ```
   sudo just install
   ```
   If `just` came from `cargo install` (so it lives in `~/.cargo/bin`
   rather than `/usr/bin`), `sudo` can't find it. Use
   `sudo $(which just) install` in bash or zsh, or
   `sudo (which just) install` in fish.
5. **Check it.** Open an image from the file manager, or run
   `cosmic-viewer <image-file>`.

## When an update breaks it

**Symptom:** COSMIC Viewer won't open, and running it from a terminal
prints something like:

```
cosmic-viewer: error while loading shared libraries:
libopenjph.so.0.31: cannot open shared object file
```

**Why:** COSMIC Viewer links to system image libraries (`openjph`,
`libheif`, `libx265`, `dav1d` and others). When a `pacman -Syu` moves one
of them to a new major version, the old file is removed and a program
built against it can't start. Arch rebuilds its own packages when that
happens. A hand-built program isn't an Arch package, so nobody rebuilds
it for you. This happens again with every such library update, and
updating the rest of COSMIC doesn't prevent it.

**Find the missing library:**

```
ldd /usr/bin/cosmic-viewer | grep 'not found'
```

No output means nothing is missing.

**Fix: rebuild and reinstall.** Cargo doesn't notice when a system
library changes, so a plain `just build-release` may reuse the stale
build. Clear the part of the build that links the image libraries
first:

```
cd ~/Projects/cosmic-viewer
cargo clean --release -p libheif-sys
just build-release
sudo just install
```

If `ldd` still reports a missing library after that, clear everything
with `cargo clean` and build again. That's a full build, so it takes as
long as the first one.

This is also a good time to update to the latest release. Run
`git pull` before building.

## Updating to a new release

```
cd ~/Projects/cosmic-viewer
git pull
just build-release
sudo just install
```

Releases are tagged `epoch-<version>` (for example `epoch-1.9.0`), and
`git tag --sort=-creatordate | head -3` shows the newest ones. COSMIC
Viewer bundles its own copy of the COSMIC toolkit, so a newer Viewer
runs fine on an older COSMIC desktop.

## Ranger

GLB's `default` profile ships a Ranger `rifle.conf` that opens images
with, in order:

1. **COSMIC Viewer**, if it's installed
2. **`imv`**, a small image viewer from the official repos
3. `xdg-open`, which uses whatever app the desktop has set as the
   default for images

Install `imv` as a backup. It's an Arch package, so updates never break
it, and Ranger falls back to it whenever COSMIC Viewer is broken or
missing:

```
sudo pacman -S imv
```

To see which program Ranger will use for a file, and in what order:

```
rifle -l <image-file>
```

**Symptom without a working viewer:** opening an image in Ranger prints
browser messages such as `Opening in existing browser session`, or
takes over Ranger's screen. That's the `xdg-open` fallback handing the
image to a web browser. Installing `imv` or fixing COSMIC Viewer ends it.

## Check whether Arch packages it yet

When a new COSMIC release reaches Arch, check whether COSMIC Viewer
came with it:

```
pacman -Si cosmic-viewer
```

If it's there, switch to the Arch package. Arch then rebuilds it with
every library update, so the breakage above goes away. Remove the
hand-built copy first. The Arch package installs the same files, and
pacman refuses to overwrite files it doesn't own. `just uninstall` only
removes the program, so delete the rest by hand:

```
sudo rm /usr/bin/cosmic-viewer
sudo rm /usr/share/applications/com.system76.CosmicViewer.desktop
sudo rm /usr/share/metainfo/com.system76.CosmicViewer.metainfo.xml
sudo rm /usr/share/icons/hicolor/*/apps/com.system76.CosmicViewer.svg
sudo pacman -S cosmic-viewer
```
