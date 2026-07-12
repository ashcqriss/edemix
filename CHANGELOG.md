# Changelog

All notable changes to Edemint are recorded here.

## Unreleased

### Added — ripe desktop pass
- `edemint-quick` — Super+S / clock-click quick-settings menu: night light,
  gaming mode, screen recorder, screenshot, color picker, power profile,
  Wi-Fi, Bluetooth, sound, system monitor, updates, lock.
- `edemint-power-profile` — cycles power-profiles-daemon profiles from the
  battery pill.
- Status bar: workspace pills, Bluetooth, backlight (scroll to dim), idle
  inhibitor; every pill now does something on click.
- Hyprland: workspaces 1-9/0 with Super+Tab bounce and Super+scroll, mouse
  move/resize (Super+drag), window groups (tabs), Alt+Tab, scratchpad
  workspace, keyboard move/resize, media keys, Print-key screenshots,
  color picker bind.
- Files app: thumbnails (tumbler + ffmpegthumbnailer), archive
  extract/compress in the context menu, removable-media handling. GUI text
  editor (gnome-text-editor) added to the desktop set.

### Fixed — ripe desktop pass
- The polkit authentication agent never started: Debian ships it under
  /usr/lib/<triplet>/libexec/, not the hardcoded /usr/lib path. GUI
  privilege prompts (installing apps, mounting disks) now work.
- Night light ran with latitude/longitude 0,0 (equatorial sunset times for
  everyone); replaced with an explicit 07:00-20:00 schedule.

### Added — mega features
- `edemint-rollback` — walk the btrfs root back to any snapper snapshot;
  apt now takes pre/post snapshots around every dpkg pass.
- AI privacy meter — Waybar pill that lights red only while a cloud LLM
  call is in flight.
- `edemint-sync` — git-based config sync across machines.
- `edemint-setup` — first-boot TUI wizard (Wi-Fi, effects profile, AI
  opt-in, sync remote).
- `edemint-gaming on/off` — sysctl + gamemoded + CPU governor toggle.
- `edemint-doctor` — read-only system health report.
- Shell helper: `?ai` / `eai` aliases explain the last failed command via
  the AI assistant.
- Waybar: camera/mic in-use indicator + updates-available indicator.
- DNS-over-TLS by default (Quad9 + Cloudflare) via systemd-resolved.
- LUKS encrypted installs are now the Calamares default.
- `wf-recorder`, `gamemode`, `mangohud`, `distrobox`, `podman` shipped.

### Added — core
- Hyprland Wayland desktop on Debian 13 Trixie (amd64 + arm64).
- Full Hyprland UX layer: waybar / hyprlock / hypridle / wlogout /
  swayosd / cliphist / hyprpicker / kanshi.
- Calamares installer (btrfs default, LUKS2, snapper, grub-btrfs).
- Secure Boot signed chain on amd64 (shim-signed + grub-efi-amd64-signed).
- arm64 Raspberry Pi image via mmdebstrap + genimage; firstboot growfs.
- AR-glasses support layer — XR driver hook (SHA-pinned, non-root build),
  edemint-ar group + 0660 udev rules, `edemint-ar-status` helper.
- AI assistant — Claude / OpenAI / Gemini / ollama backends, keyring-stored
  keys, `local_only` egress lockdown.
- Equivs metapackages: edemint-base / edemint-desktop / edemint-ai.
- GitHub Actions release pipeline (Tier A lint + sign-test + amd64 ISO +
  Pi image + signed apt repo on tag).

### Optimizations
- Boot speed: NetworkManager-wait-online disabled,
  plymouth-quit-wait masked, MODULES=dep initramfs.
- Sysctl: swappiness=10, BBR + fq_codel, dirty-ratio tuning.
- btrfs: noatime, compress=zstd:1, ssd, discard=async, space_cache=v2.
- Mesa: shader cache 2 GB.
- ISO trim: localepurge keeps en/en_US.UTF-8/en_GB.UTF-8 only (~150 MB).
- Hyprland: VRR fullscreen-only, no focus-on-activate.
- Kernel cmdline: amd_pstate=guided / intel_pstate=active, nowatchdog.

### Known placeholders
- `XR_SHA256` in the XR-driver hook — every build skips AR driver build
  until updated with a real upstream tag + hash (vendored per release).
- deb822 Edemint apt source ships `Enabled: no` until CI populates
  `https://ashcqriss.github.io/edemint/debian` from the publish job and a
  matching public key is shipped to `/etc/apt/keyrings/`.
- Calamares logo / slideshow / Hyprland visuals are placeholders pending
  the deferred design pass.
