# Edemint features

The complete feature inventory of the current tree. CHANGELOG.md records
when each landed; DESIGN.md / PALETTE.md govern how things look;
PRODUCTION_REMEDIATION_PLAN.md tracks what release-readiness still needs.

## Base OS and images

- Debian 13 (Trixie) remix, Wayland-first; one shared config tree builds
  every target.
- amd64 hybrid live/install ISO (BIOS + UEFI) with a Secure Boot signed
  chain (shim-signed + grub-efi-amd64-signed).
- arm64 Raspberry Pi 4/5 image via mmdebstrap + genimage with first-boot
  filesystem growth.
- greetd login manager running a palette-themed tuigreet, with agreety as
  an always-works fallback.
- Equivs metapackages: edemint-base / edemint-desktop / edemint-ai.

## Installer (Calamares)

- btrfs root by default; LUKS2 full-disk encryption is the default choice.
- snapper + grub-btrfs wired in at install time; root account locked.
- Branded sidebar, slideshow, logo placeholder, and palette stylesheet.

## Desktop shell and session (Hyprland)

- Persistent left pinned-app dock (Home, Web, Files, terminal, AI) with an
  all-apps fuzzy search launcher and a power button.
- Top-right glass status region: workspace pills, clock + calendar, AI
  privacy meter, camera/mic in-use, updates, idle inhibitor, tray, volume,
  brightness (scroll to dim), network, Bluetooth, CPU, RAM, battery.
  Every pill acts on click.
- Quick settings (Super+S or click the clock): night light, gaming mode,
  screen recorder, screenshot, color picker, power profile, Wi-Fi,
  Bluetooth, sound mixer, system monitor, updates, keybinds, lock.
- Workspaces 1-9 and 0, Super+Tab previous-workspace bounce, Super+scroll
  walking; mouse move/resize (Super+drag) and keyboard move/resize;
  tabbed window groups (Super+G); Alt+Tab; scratchpad special workspace.
- Screenshots: full to ~/Pictures, area to clipboard, area to annotation
  editor (swappy); screen recording toggle; clipboard history; color
  picker; media keys via playerctl; OSD for volume/brightness; cursor
  zoom accessibility binds; keybind cheat-sheet on Super+?.
- Lock screen with always-visible clock/date; idle policy: dim, screen
  off, lock, lock-before-sleep; power menu (lock / logout / suspend /
  reboot / shutdown); 3-finger workspace swipe; fcitx5 input methods;
  kanshi monitor auto-profiles.

## Design system

- Measured eight-family palette with a written importance hierarchy.
- Flat fills only — gradients forbidden by default; rounded-rectangle
  shape language.
- Liquid-glass control layer: translucent flat tints + hairline edges on
  dock, status, launcher, notifications, OSD, power scrim, lock input;
  compositor blur (lensing) in the full effects profile; alphas tuned to
  stay legible without blur; emphasis/critical surfaces stay opaque.
- Conscious ink (#0C0F1D) / paper (#F4F6FF) app backgrounds; accents swap
  light/dark steps of the same family per mode; hue families never change.
- Dark set is the OS-wide default: GTK3/GTK4/libadwaita recolor, dconf
  color-scheme for portal apps, Qt via the gtk3 platform theme.
- Themed GRUB menu, installer, terminal ANSI palette, setup wizard,
  notifications (persistent opaque critical style), and OSD.
- Low-power profile (Pi/1GB default) and a full-effects profile switchable
  in the setup wizard; low-power doubles as reduced transparency.

## Applications

- Firefox ESR; Thunar with thumbnails, archive extract/compress, and
  removable-media handling; GUI text editor; foot terminal; Evince and
  Eye of GNOME; mpv; calculator; disk utility and Baobab; GNOME System
  Monitor + htop; Deja Dup backups; GNOME Software with Flatpak;
  file-roller; Neovim + nano; fastfetch.
- Gaming mode: gamemode + MangoHud + sysctl/CPU-governor toggle
  (edemint-gaming, gmr alias).
- Containers: podman + distrobox.

## Settings

- edemint-settings (Super+I, in the app grid and quick menu): hierarchical
  settings hub over real backends with live state on every entry.
  - Network: Wi-Fi radio and airplane-mode toggles, nmtui picker/editor,
    connection + DNS status.
  - Bluetooth: power toggle, paired devices, blueman manager.
  - Displays: output list, per-output scale (1.0-2.0) and rotation via
    hyprctl, AR-glasses status.
  - Appearance: dark/light app-mode switch (ink/paper doctrine; swaps
    gtk.css + settings.ini + dconf color-scheme), effects profile
    (low-power/full incl. glass blur), night light, text scale, cursor
    size.
  - Sound: output/mic mute, volume presets (wpctl), mixer.
  - Power: profile picker, battery charge limit (80%/reset/status), idle
    policy summary.
  - Privacy & AI: assistant enable/disable, backend picker, local-only
    egress lock, camera/mic status.
  - System: updates, snapshots/rollback, health report, gaming mode,
    NVIDIA opt-in, config sync, about.

## Edemint helper suite

- edemint-rollback — btrfs rollback to any snapper snapshot; apt takes
  pre/post snapshots around every dpkg run.
- edemint-doctor — read-only pasteable health report.
- edemint-sync — git-based config sync across machines (keys excluded).
- edemint-setup — first-boot wizard: Wi-Fi, effects, AI opt-in, sync.
- edemint-quick / edemint-power-profile — quick settings + profile cycler.
- edemint-welcome, edemint-nvidia-toggle (opt-in proprietary driver),
  edemint-battery-limit (charge cap), edemint-keybinds.
- Shell: ?ai / eai explain the last failed command via the AI assistant
  (never re-executes it).

## AI assistant (disabled by default)

- Backends: Claude, OpenAI, Gemini (cloud) and ollama (local).
- API keys only in gnome-keyring; local_only switch refuses all egress.
- Privacy meter pill lights red only while a cloud call is in flight;
  camera/microphone in-use indicators.

## AR glasses

- USB-C DP-Alt glasses appear as monitors; kanshi hotplug profiles.
- XR-driver support layer: SHA-pinned non-root build hook, 0660 udev
  rules + edemint-ar group, edemint-ar-status enable/disable helper.

## Security and privacy

- nftables firewall, AppArmor, DNS-over-TLS (Quad9 + Cloudflare),
  unattended security upgrades, CUPS bound to localhost, locked root,
  signed apt repo path, PAM-unlocked keyring.
- Tier A CI lint asserts the security invariants on every push.

## Reliability, performance

- Snapshots on every apt run + one-command rollback.
- Fast boot: no network-wait barrier, MODULES=dep initramfs, masked
  plymouth-quit-wait.
- zram swap, earlyoom, swappiness 10, BBR + fq_codel, btrfs zstd:1 +
  noatime + discard=async, Mesa shader cache, VRR fullscreen-only,
  ~1 GB RAM floor with the low-power profile.

## Known limits (see PRODUCTION_REMEDIATION_PLAN.md)

- XR driver hash and the Edemint apt repo are release-gated placeholders.
- No Plymouth boot splash yet; icons, cursor, wallpaper, logo await the
  artwork pass; Hyprland installs best-effort until backports hardening.
- Tap-in-void overview, widgets, and mobile layouts land with the
  planned edemint-shell.
