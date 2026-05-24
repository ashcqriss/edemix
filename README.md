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
auto/config                         live-build options (distro, arch, areas)
build.sh                            one-command builder (sudo ./build.sh)
config/package-lists/base.list      core system packages (small)
config/package-lists/desktop.list   Hyprland + Wayland desktop
config/hooks/normal/0100-branding   os-release, motd, enable greetd, slimming
config/includes.chroot/             files baked into the image:
  etc/greetd/config.toml              login manager -> Hyprland
  etc/skel/.config/hypr/              default Hyprland config (low-power)
  etc/skel/.config/waybar/            status bar
  etc/skel/.config/foot/              terminal
```

## Build (amd64 live ISO)

Run on a Debian/Ubuntu host with root, ~10GB free disk, and network:

```sh
sudo ./build.sh           # -> live-image-amd64.hybrid.iso
sudo ./build.sh clean     # remove build artifacts
```

Write the ISO to a USB stick (`dd if=live-image-amd64.hybrid.iso of=/dev/sdX
bs=4M status=progress`) or boot it in a VM.

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

## Roadmap / not done yet

- **arm64 / Raspberry Pi image.** `live-build` here targets amd64 ISO only.
  The Pi needs a separate `.img` pipeline (e.g. `rpi-image-gen` or a
  debootstrap + genimage script reusing the same package lists). This is the
  next milestone.
- **Spatial AR** (head tracking, floating windows in 3D) — research track,
  per-device, not started.
- **Installer polish** (Calamares) for installs to disk.
