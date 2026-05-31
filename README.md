# Edemint

A Wayland-first Linux distribution remixed from **Debian 13 (Trixie)**, running
**Hyprland**, aimed at AR glasses (as DisplayPort monitors), Raspberry Pi, and
ordinary PCs. Tuned to stay light on low-end hardware.

## Why Debian + Hyprland

- **Debian** is the only mainstream base that officially covers both `amd64`
  (PCs) and `arm64` (Raspberry Pi) from one userland, and Raspberry Pi OS is
  itself Debian — so the Pi path is well-trodden.
- **Hyprland** (a wlroots compositor) gives the "brand-new OS" look and is
  highly customisable, while still running on ~1GB RAM once the eye-candy is
  disabled (see `low_power` in the Hyprland config).
- AR glasses (RayNeo Air, Xreal, …) appear as ordinary USB-C DisplayPort
  **monitors**; no special driver is needed for basic display. True spatial /
  head-tracking AR is a separate, device-specific research track and is *not*
  included here.

## Layout

```
build.sh                            dispatcher: ./build.sh <amd64|pi|clean>
shared/                             single source of truth, used by every target
  package-lists/base.list.chroot      core system packages
  package-lists/desktop.list.chroot   Hyprland + Wayland desktop
  hooks/normal/0100-branding.*        os-release, motd, enable greetd, slimming
  includes/etc/greetd/config.toml     login manager -> Hyprland
  includes/etc/skel/.config/          default user configs (hypr, waybar, foot)
profiles/
  amd64-iso/                        live-build profile for the PC ISO
    auto/config                       live-build options (distro, arch, areas)
    config/                           symlinks back to ../../../shared/*
  arm64-pi/                         mmdebstrap + genimage pipeline (planned)
```

## Build (amd64 live ISO)

Image builds need root + loop devices (live-build/debootstrap), so the
canonical path is **GitHub Actions** on a privileged runner; tagged releases
publish both images automatically. To build locally on a Debian/Ubuntu host
with root, ~10GB free disk, and network:

```sh
sudo ./build.sh amd64     # -> profiles/amd64-iso/live-image-amd64.hybrid.iso
sudo ./build.sh pi        # -> profiles/arm64-pi/edemint-*-arm64-rpi.img.zst
sudo ./build.sh clean     # remove build artifacts
```

The Pi build runs ~4x faster on a native arm64 host (it skips qemu
emulation); on an amd64 host it auto-installs qemu-user-static and
cross-builds. CI defaults to the free amd64 (`ubuntu-latest`) cross-build;
set the `PI_RUNNER` repo variable to `ubuntu-24.04-arm` to build natively
(free for public repos, paid for private).

Write the ISO to a USB stick (`dd if=live-image-amd64.hybrid.iso of=/dev/sdX
bs=4M status=progress`) or boot it in a VM. Flash the Pi image with
`zstd -dc edemint-*-arm64-rpi.img.zst | sudo dd of=/dev/sdX bs=4M status=progress`
(or point Raspberry Pi Imager at the `.img.zst`).

## Default keybinds

| Keys | Action |
|------|--------|
| `Super`+`Return` | terminal (foot) |
| `Super`+`D` | app launcher (wofi) |
| `Super`+`Q` | close window |
| `Super`+`E` | file manager |
| `Super`+`F` | fullscreen |
| `Super`+`L` | lock |

## AR glasses

Plug glasses in over USB-C; they show up as a monitor. List them with
`hyprctl monitors` and configure placement in
`~/.config/hypr/hyprland.conf` (see the `monitor =` lines). `wlr-randr` is
included for quick output tweaks.

## Roadmap

In-flight (this build-out): metapackages (`edemint-base`/`-desktop`/`-ai`),
Calamares installer, arm64/Pi image via mmdebstrap+genimage, signed apt repo
+ unattended-upgrades, AppArmor / nftables / Secure Boot defaults, AR-glasses
support layer (kanshi + XR-driver IMU + sensor plumbing), optional AI
assistant (disabled by default), GitHub Actions release pipeline.

Deferred (later passes): graphical/shell visual design, 3D head-tracked
virtual-screen compositor on Hyprland (experimental), Bluetooth-companion
glasses (no Linux SDK).
