# Edemint Complete Feature Audit

Audit date: 2026-06-08

Audited repository: `ashcqriss/edemix`

Audited branch: `codex/app-foundations-roadmap`

Audited branch head: `aac970bf69c66533b91794e3c7b4a26b6da0aba1`

This is a repository-verifiable inventory. It does not treat an installed
package, a roadmap entry, or a successful static check as proof that a feature
works in a booted image.

## Status Legend

- **Native MVP:** Edemint code exists and implements the listed limited behavior.
- **Integrated foundation:** an upstream Debian application supplies the main
  behavior; Edemint provides packaging, defaults, naming, or a launcher.
- **Experimental:** code exists, but the essential communications or hardware
  backend is not complete.
- **Configured, unproven:** source configuration exists, but the current branch
  lacks successful image, VM, installation, or physical-hardware evidence.
- **Missing:** required production behavior is not implemented or tested.

## Application Inventory

### 1. Adventurer

Status: **Integrated foundation**, GNOME Web/Epiphany using WebKitGTK.

Present:

- WebKit-based web rendering.
- Normal browser navigation, tabs, address/search entry, history, bookmarks,
  downloads, and private browsing supplied by GNOME Web.
- Wayland operation and desktop launcher integration.
- Portal and PipeWire infrastructure is installed for file selection and media.
- Firefox ESR remains installed as a recovery browser.

Missing compared with a production Edemint browser:

- Edemint-native browser interface and design system.
- Branch tests for TLS/certificate presentation, mixed content, popups, unsafe
  downloads, private-mode isolation, session recovery, and crash isolation.
- Audited per-site camera, microphone, location, notification, and clipboard
  permission controls.
- Download quarantine/reputation policy, managed policies, profile sync,
  extension policy, accessibility acceptance tests, and Web Platform tests.

### 2. Settings

Status: **Native MVP**.

Present:

- One Edemint window launching NetworkManager Wi-Fi/Ethernet/VPN controls.
- Bluetooth device management through Blueman.
- PipeWire input/output and volume controls through Pavucontrol.
- Wayland display inspection through `wlr-randr`.
- ICC color-profile viewer through GNOME Color Manager/colord.
- Printer management through system-config-printer/CUPS.
- Disk and filesystem tools through GNOME Disks.
- Battery statistics through GNOME Power Statistics.

Missing:

- Native settings pages instead of launcher rows.
- Integrated brightness, display arrangement, scaling, refresh rate, HDR, and
  color-temperature controls.
- Per-app audio, microphone permission, camera permission, privacy history, and
  application permission controls.
- User accounts, passwords, fingerprint enrollment, language, region, date,
  time, keyboard, accessibility, appearance, wallpaper, updates, sources,
  default apps, storage, backup, and recovery pages.
- Narrow polkit helpers and tests for every privileged operation.
- Search, deep links, transactional apply/revert, hardware capability handling,
  accessibility, and mobile layouts.

### 3. Activity Monitor

Status: **Native MVP**.

Present:

- Refreshes every two seconds.
- Reads 1/5/15-minute CPU load averages.
- Reports used and total memory.
- Reports cumulative received and transmitted network bytes.
- Counts DRM GPU devices.
- Opens GNOME System Monitor for processes.
- Opens Baobab for storage usage.

Missing:

- Actual per-core CPU percentages and history graphs.
- Native process list, process tree, sorting, search, signals, priorities, and
  resource limits.
- Swap, disk throughput/latency, per-interface network rate, open sockets, and
  per-process I/O.
- GPU utilization, VRAM, temperature, power, encoder/decoder, and
  driver-specific telemetry.
- Sensor/fan/temperature views, export, alerts, sampling controls, and remote
  monitoring.

### 4. Filer

Status: **Integrated foundation**, Thunar with GVfs.

Present:

- Standard folder browsing and file operations supplied by Thunar.
- Copy, move, rename, delete, trash, properties, bookmarks, and removable-media
  access supplied upstream.
- Network and virtual filesystem support through GVfs backends.
- Archive handling through File Roller.
- Thumbnail/viewer support from the installed desktop stack.
- An Edemint “open in Inspector” integration is configured.

Missing:

- Edemint-native interface and design.
- Audited portal-first handling, sandbox status display, permission explanations,
  tags, version history, cloud-provider integration, robust indexed search, and
  conflict resolution.
- Production tests for network shares, hotplug, large operations, cancellation,
  low-disk conditions, damaged filesystems, and accessibility.

### 5. Messenger

Status: **Edemint integration shell** over the Nheko Matrix client.

Present in the Edemint shell:

- Opens Nheko and discloses Nheko as the messaging engine.
- Accepts Matrix user IDs, room aliases, room IDs, `matrix:` URIs, and
  `matrix.to` links.
- Validates and normalizes conversation destinations.
- Saves, searches, opens, and removes favorite conversations locally.
- Creates, selects, opens, and forgets named Nheko profiles.
- Keeps profile names and destinations in a mode-0600 atomic JSON file.
- Reports Nheko installation, Matrix URI handler, and Secret Service status.
- Sends a local desktop-notification test.
- Provides security reminders for device verification and session review.
- Does not read Nheko messages, encryption keys, or credentials.

Supplied by Nheko, subject to upstream configuration and testing:

- Matrix accounts, rooms, direct messages, files, notifications, calls, and
  Matrix end-to-end encryption.

Missing:

- Edemint-owned message timeline, composer, attachment flow, account setup,
  contacts, search, moderation, calls, and encrypted storage.
- Verified deep-link compatibility across Nheko releases.
- Portal attachment handoff, headless Wayland launch test, accessibility audit,
  multi-account migration tests, offline behavior tests, and notification-action
  integration.
- Independent security audit of the complete messaging path.

### 6. App Store

Status: **Integrated foundation**, GNOME Software plus Flatpak plugin.

Present:

- Graphical software discovery and management supplied by GNOME Software.
- Flatpak runtime and GNOME Software Flatpak integration.
- Flathub registration is performed by an image hook.

Missing:

- An Edemint-certified application repository and certification process.
- Explicit trust levels, permission summaries, architecture support, signatures,
  checksums, revocation state, maintainer identity, and security-report links.
- A completed and enabled signed Edemint APT repository.
- Transaction/rollback guarantees, disk-space preview, parental/enterprise
  policy, malware review policy, reproducible package evidence, and tested
  recovery from interrupted installs.

### 7. Calendar

Status: **Integrated foundation**, GNOME Calendar.

Present:

- Standard local/online calendar views, event creation/editing, search, and
  reminders supplied upstream.

Missing:

- Edemint-native account setup and design.
- Repository tests for CalDAV providers, offline reconciliation, time zones,
  invitations, recurring events, notification actions, Secret Service use,
  import/export, accessibility, and mobile layouts.

### 8. Maps

Status: **Integrated foundation**, GNOME Maps.

Present:

- Map browsing, place search, and routing supplied upstream.

Missing:

- Edemint-native design, offline maps, download management, privacy controls,
  location-permission UI, saved collections, transit/provider guarantees,
  attribution validation, and tested mobile/navigation behavior.

### 9. App Library

Status: **Native MVP**.

Present:

- Scans user, local, and system `.desktop` files.
- Excludes hidden and non-application entries.
- Sorts and searches installed applications by display name.
- Launches applications by desktop ID.
- Adds applications directly to Edemint Shortcuts.

Missing:

- AppStream metadata, descriptions, icons, categories, folders, recent/frequent
  apps, install state, updates, and permission badges.
- Incremental indexing/cache, change monitoring, fuzzy search, keyboard grid,
  drag ordering, pagination, responsive/mobile layout, and shell integration.

### 10. Shortcuts

Status: **Native MVP**.

Present:

- Creates application, web, email, telephone, and folder shortcuts.
- Validates desktop IDs, URL schemes, and folder existence.
- Runs, lists, and removes shortcuts.
- Does not permit arbitrary shell-command shortcuts.
- Stores validated data atomically in a mode-0600 JSON file.
- Accepts shortcuts created from App Library.

Missing:

- Multi-step workflows, variables, conditions, loops, inputs/outputs, scheduling,
  triggers, share-sheet actions, and application intents.
- Categories, icons, drag ordering, keyboard shortcuts, desktop widgets, sync,
  import/export, versioning, undo, permission summaries, and sandboxed execution.

### 11. Inspector

Status: **Native MVP**.

Present:

- Opens only an explicitly selected path that the current user can read.
- Shows name, guessed MIME type, size, modification time, and resolved path.
- Reads at most 65,536 bytes.
- Displays UTF-8 text or a bounded hexadecimal preview.
- Is read-only and does not execute content or extract archives.
- Does not bypass Unix permissions.

Missing:

- The requested disposable secure preview environment.
- Bubblewrap profiles for PDF, image, audio, video, office, and archive viewers.
- No-network/no-device/no-process/no-SSH/no-password/no-arbitrary-D-Bus policy.
- MIME-content verification, decompression limits, timeouts, memory/CPU limits,
  macro/script blocking, archive-bomb handling, malware scanning as a warning
  signal, and viewer crash isolation.

### 12. Mail

Status: **Integrated foundation**, Geary.

Present:

- Standard IMAP/SMTP account, conversation, compose, search, attachment, and
  notification behavior supplied upstream.

Missing:

- Edemint-native design and account center.
- Repository tests for OAuth, credential storage, offline queues, conflict
  recovery, signatures, filters, encryption/signing, phishing controls,
  attachment sandboxing, accessibility, and provider compatibility.

### 13. Noterer

Status: **Integrated foundation**, GNOME Text Editor.

Present:

- Text-file open/save, tabs, undo/redo, find/replace, and editing supplied
  upstream.

Missing:

- Edemint-native design, explicit encoding and line-ending controls, autosave
  recovery acceptance tests, session restore, large-file behavior, compare,
  print/export, spellcheck policy, and mobile layout.

### 14. Bluetooth Manager

Status: **Integrated foundation**, Blueman plus BlueZ.

Present:

- Adapter discovery, pairing, trust, connection, removal, and common device
  service handling supplied upstream.
- PipeWire Bluetooth audio support is installed.

Missing:

- Edemint-native settings surface.
- Tested pairing confirmation, battery reporting, audio-profile switching,
  disabled/radio-blocked states, recovery, multi-adapter behavior, privacy
  visibility controls, and complete keyboard/screen-reader operation.

### 15. Dictionary

Status: **Integrated foundation**, GoldenDict-ng.

Present:

- Local dictionary lookup and support for upstream dictionary formats.

Missing:

- Guaranteed bundled offline dictionary data, language packs, pronunciation
  availability, source attribution UI, dictionary-store integration, privacy
  policy, and tested keyboard/accessibility behavior.

### 16. Console

Status: **Native MVP**.

Present:

- Read-only display of the latest 300 user-journal entries.
- ISO timestamp output and manual refresh.

Missing:

- Structured fields, severity/unit/time filters, search, follow mode, bookmarks,
  export, copy controls, boot selection, crash grouping, and authorized access
  to system logs.
- Redaction rules, large-log performance, persistent queries, and support-bundle
  creation.

### 17. Font Manager

Status: **Integrated foundation**, Font Manager.

Present:

- Font browsing, preview, metadata, and user-font management supplied upstream.

Missing:

- Edemint-native design; duplicate detection; license display; variable-font
  axes; enable/disable policy; font-store integration; system-font polkit flow;
  damaged-font isolation; and acceptance tests.

### 18. Terminal

Status: **Integrated foundation**, Foot.

Present:

- Wayland-native terminal emulation, shell launch, scrollback, clipboard, font,
  and color configuration supplied upstream.

Missing:

- Edemint profile editor, tabs/splits or session manager, searchable command
  history UI, safe-paste warnings, SSH profile management, restore, accessibility
  testing, and explicit shell-default management.

### 19. Mission Control

Status: **Native MVP**.

Present:

- Reads Hyprland IPC JSON.
- Lists workspaces, workspace window counts, and window titles/classes.
- Manual refresh and graceful “IPC unavailable” reporting.

Missing:

- Visual live overview, thumbnails, focus, close, move, drag between workspaces,
  workspace creation/removal, search, touch gestures, keyboard navigation,
  multi-monitor behavior, reduced motion, and IPC reconnect.

### 20. Sticky Notes

Status: **Native MVP**.

Present:

- One editable note.
- Explicit save.
- Atomic local persistence.

Missing:

- Multiple notes, autosave, pinning above windows, layer-shell positioning,
  colors, opacity, resize, workspace assignment, reminders, checklists, archive,
  trash, search, sync, import/export, and display-boundary clamping.

### 21. Color Control

Status: **Integrated foundation**, GNOME Color Manager plus colord.

Present:

- ICC profile viewing and colord infrastructure.

Missing:

- Complete display/device profile assignment flow, calibration handoff, profile
  import/export, soft proofing, ambient adaptation, per-monitor validation, and
  clear separation between UI theme colors and hardware color management.

### 22. Print Control

Status: **Integrated foundation**, system-config-printer plus CUPS.

Present:

- Printer discovery, addition, removal, defaults, queue viewing, job control,
  and driver/options behavior supplied upstream.
- CUPS TCP listening is restricted to localhost by Edemint.

Missing:

- Edemint-native design; tested IPP/IPPS authentication; driverless-printer
  matrix; scan integration; secure release; quota/accounting; policy; and robust
  offline/error/retry handling.

### 23. Camera

Status: **Integrated foundation**, Cheese.

Present:

- Basic camera preview, photo, video, timer, and effects supplied upstream.

Missing:

- Edemint-native design, explicit camera/microphone permission flow, device and
  format selection guarantees, save portal, privacy shutter state, metadata
  controls, and tested PipeWire portal behavior.

### 24. Camera Studio

Status: **Integrated foundation**, Webcamoid.

Present:

- Advanced capture and device controls supplied upstream where hardware exposes
  them.

Missing:

- Guaranteed professional controls across devices: manual exposure/focus/white
  balance, frame rate, resolution, bitrate, audio routing, scenes, overlays,
  profiles, scopes, color management, hardware encode, and capability-aware UI.
- Edemint-specific reliability, latency, synchronization, and hardware tests.

### 25. Automator

Status: **Native MVP**.

Present:

- Allowlisted action to open App Library.
- Allowlisted screenshot action saving to Automator’s private data directory.
- Allowlisted session-lock action.
- Refuses downloaded workflows and arbitrary privileged shell commands.

Missing:

- Workflow editor, action graph, variables, conditions, loops, triggers,
  schedules, app intents, notifications, calendar actions, text transforms,
  portal files, Secret Service, history, undo, debugging, signing, versioned
  import/export, permission review/revocation, and sandboxed untrusted imports.

### 26. Calculator

Status: **Integrated foundation**, GNOME Calculator.

Present:

- Basic, advanced, financial, and programming calculation modes supplied
  upstream, depending on packaged version.

Missing:

- Edemint-native design, repository acceptance tests for locale decimal rules,
  keyboard-only use, history persistence, unit/currency data behavior,
  accessibility, and offline guarantees.

### 27. Fullcall

Status: **Experimental native app**.

Present:

- Independent Edemint GTK application.
- Local channel-name entry.
- Local message composition and send.
- SQLite channel/message storage with timestamps.
- Per-channel timeline of up to 100 recent local messages.

Missing:

- User accounts, identity, teams, channels with membership/roles, contacts,
  network synchronization, server, federation, offline reconciliation, message
  edits/deletes/reactions/threads/search/files, notifications, encryption,
  device verification, moderation, retention, administration, audit logs,
  presence, voice/video meetings, screen sharing, recording, captions,
  calendar integration, and WebRTC/SFU infrastructure.
- It is not yet a functional Teams replacement.

### 28. Phone

Status: **Experimental native app**.

Present:

- Telephone/SIP-address entry.
- Numeric dial pad.
- Accepts `tel:` arguments.
- ModemManager device diagnostic.
- SQLite recent-call display.
- Call button deliberately disabled without a tested backend.

Missing:

- Actual cellular calling, SIP calling, emergency calling, incoming calls,
  ringing, answer/reject, call state, hangup, hold, mute, keypad tones, voicemail,
  contacts, favorites, call-history creation, audio routing, Bluetooth headset,
  SIM/PIN/eSIM, carrier status, multiple modems, permissions, and emergency
  location/compliance.

### 29. Contacts

Status: **Integrated foundation**, GNOME Contacts.

Present:

- Standard contact creation, editing, search, and account-backed contacts
  supplied upstream.

Missing:

- Edemint-native design, default contact provider, import/export, deduplication,
  merge, groups, privacy controls, Messenger/Mail/Phone integration, offline
  conflict handling, and repository acceptance tests.

## Operating-System Features Present in Source

### Base and architecture

- Debian 13 Trixie userland with Debian main, contrib, non-free, and
  non-free-firmware sources.
- `amd64` live/install ISO profile.
- `arm64` Raspberry Pi 4/5 image profile using mmdebstrap, genimage, FAT32 boot,
  ext4 root, first-boot filesystem growth, and Zstandard compression.
- Shared configuration, hooks, app catalog, and package manifests across targets.
- Required desktop packages resolve from Trixie and selectively pinned
  Trixie Backports.

### Boot, login, install, and storage

- systemd boot and graphical target.
- greetd login manager with tuigreet when available and agreety fallback.
- ISO-source live-session autologin configuration.
- Calamares graphical installer configuration.
- btrfs intended as the default installed root filesystem.
- LUKS2 encryption intended as the default erase-install choice.
- Root account locking and normal password-gated installed login are configured.
- Btrfs, ext4, NTFS, exFAT, FAT, LVM, cryptsetup, UDisks, and GNOME Disks tools.
- Snapper support and pre/post APT snapshot hook.
- Interactive `edemint-rollback`, including “last pre-APT” rollback.

### Desktop and window management

- Wayland-first Hyprland compositor.
- Release-critical hard dependency checks for Hyprland, hyprlock, hypridle,
  xdg-desktop-portal-hyprland, wlogout, SwayOSD, cliphist, wf-recorder, and jq.
- XWayland compatibility for X11 applications.
- Waybar status surface and separate approximate pinned-app dock.
- Wofi application launcher.
- Foot terminal.
- Mako notifications.
- Hyprlock lock screen and Hypridle idle handling.
- Wlogout power menu.
- Workspaces, keyboard focus movement, move-to-workspace, floating, fullscreen,
  close, lock, and exit bindings.
- Three-finger workspace swipe.
- Natural-scroll, tap-to-click, disable-while-typing, and drag-lock touchpad
  defaults.
- Screenshot selection/edit flow using Grim, Slurp, and Swappy.
- Screen recording using wf-recorder.
- Clipboard history for text and images using wl-clipboard and cliphist.
- Brightness, output volume, mute, and microphone mute OSD controls.
- Cursor zoom keyboard controls.
- Low-power defaults: no blur, shadows, or animations.
- Rounded windows, gaps, active-border gradient, variable-frame-rate idle, and
  fullscreen-only variable refresh.

### Status and shell information

- Clock/date and calendar tooltip.
- Network state/SSID.
- Volume and mute state.
- CPU and memory percentages.
- Battery percentage and charging state.
- System tray.
- Cloud-AI activity privacy indicator.
- Camera/microphone in-use indicator.
- Available-update indicator and click action.

### Networking and communications

- NetworkManager for Wi-Fi, Ethernet, and connection profiles.
- OpenVPN, OpenConnect, and WireGuard tooling.
- ModemManager installed and enabled.
- BlueZ Bluetooth stack and Blueman interface.
- DNS-over-TLS using Quad9 and Cloudflare fallbacks.
- systemd-resolved cache and stub resolver.
- DNSSEC `allow-downgrade`.
- systemd-timesyncd.
- Avahi service discovery.

### Audio, video, graphics, and display

- PipeWire, PipeWire PulseAudio compatibility, and WirePlumber.
- Bluetooth audio integration.
- Mesa OpenGL/Vulkan stack and VA-API video decoding tools.
- FFmpeg and broad GStreamer good/bad/ugly/libav codec sets.
- MPV video/audio playback.
- Eye of GNOME and imv image viewing.
- Evince document viewing.
- Wlsunset color-temperature service.
- Kanshi display profiles and `wlr-randr`.
- Qt 5/6 Wayland support and Wayland environment defaults for Firefox.

### Hardware and firmware

- Intel/AMD/Realtek/Atheros/Broadcom firmware coverage plus wireless-regdb.
- amd64-specific CPU microcode and media-driver manifests.
- PCI and USB inspection tools.
- Power Profiles Daemon.
- Battery charge-limit helper/service for supported hardware.
- Fingerprint daemon and PAM package.
- Automatic filesystem trim timer.
- Raspberry Pi firmware/kernel/image tooling and first-boot root expansion.

### AR and external-display support

- AR glasses can operate as ordinary DisplayPort/USB-C external monitors.
- Kanshi hotplug/output profiles.
- XR build dependencies and optional XRLinuxDriver build hook.
- Dedicated `edemint-ar` system group.
- Intended 0660 group-scoped XR udev access.
- `edemint-ar-status` diagnostic helper.
- Camera and USB-device tools useful for glasses.

Important limitation:

- True head-tracked/spatial AR is absent because the XR source checksum remains a
  placeholder and the driver build is skipped.

### Security and privacy

- AppArmor packages and service enablement.
- nftables default-deny inbound and forwarding policy.
- Loopback, established/related traffic, required ICMP/ICMPv6, and DHCP replies
  allowed; outbound traffic allowed.
- CUPS TCP interface bound to localhost.
- GNOME Keyring and PAM login integration.
- GUI polkit authentication agent.
- Rootless Podman container runtime.
- Bubblewrap and xdg-dbus-proxy available for future app sandboxes.
- AI disabled by default.
- AI API keys stored through Secret Service rather than plaintext config.
- `local_only` AI mode refuses cloud backends.
- Red Waybar privacy state while a cloud AI call is active.
- Inspector does not bypass file permissions or execute selected content.
- Shortcuts do not execute arbitrary shell commands.

### Updates, packaging, and recovery

- Debian security, Trixie, and Trixie Updates sources.
- unattended-upgrades and apt-listchanges.
- Update-availability status indicator.
- Three equivs metapackages: base, desktop, and AI.
- Signed-repository generation logic for tagged releases.
- SHA-256 and SHA-512 release checksum generation.
- Snapper APT snapshots and manual rollback helper.
- Edemint repository source/keyring placeholders.

Important limitation:

- The Edemint source is disabled and its keyring/hosted repository are not yet
  operationally proven.

### Performance and low-resource operation

- zram swap.
- EarlyOOM.
- Swappiness, dirty-page, and network queue/congestion tuning documented in the
  system configuration.
- BBR/fq_codel networking tuning.
- Initramfs `MODULES=dep` and Zstandard settings.
- tmpfs `/tmp`.
- NetworkManager wait-online disabled.
- Plymouth quit-wait masked.
- Mesa shader cache set to 2 GiB.
- Localepurge image-size reduction.
- btrfs `noatime`, compression, SSD, async discard, and space-cache intentions.
- Pi-native arm64 fast build path and dynamic root image sizing.
- Gaming mode helper, GameMode, and MangoHud.

### User setup, diagnostics, and synchronization

- One-time text UI setup for Wi-Fi, effects profile, AI opt-in/backend, API key,
  and optional config-sync remote.
- `edemint-doctor` read-only health report for identity, boot mode, services,
  firewall, AppArmor, root lock, keyring, graphics, audio, memory, zram, AR, and
  AI state.
- `edemint-sync` private Git-based push/pull/clone/status for selected desktop
  configuration.
- Sync excludes keyring, SSH, GnuPG, caches, session state, and user application
  data, and makes first-apply backups.
- `?ai`/`eai` shell assistance and keybind help.
- NVIDIA toggle helper.

### Accessibility and international input

- AT-SPI and Orca screen reader packages.
- GTK/Qt accessibility environment variables.
- fcitx5 with Chinese additions and Mozc.
- Cursor zoom.
- Noto, emoji, Liberation, JetBrains Mono, Fira Code, and Font Awesome fonts.

Important limitation:

- The image currently removes most locales and lacks automated keyboard,
  screen-reader, contrast, scaling, reduced-motion, RTL, and multilingual gates.

### Printing, backup, containers, and developer utilities

- CUPS, cups-browsed, printer GUI, and Avahi.
- Deja Dup backup application.
- Rootless Podman and optional Distrobox.
- Git, curl, wget, Nano, Neovim, htop, and standard diagnostics.
- File Roller archive manager.

## CI and Repository Features

Present:

- Static/Tier-A checks and signed-repository tamper test.
- Cross-architecture app package availability contract for amd64 and arm64.
- Python compilation, shell syntax, catalog validation, desktop validation, and
  MIME launcher-reference validation.
- Workflow concurrency with cancellation of superseded non-tag builds.
- Long-job timeouts and failure-log artifacts.
- Debian package build artifact.
- amd64 ISO build and structural inspection job.
- ISO contract requires a squashfs, package manifest, UEFI El Torito entry,
  Hyprland, hyprlock, and xdg-desktop-portal-hyprland.
- Pi build starts only after the ISO inspection job.
- Pi archive integrity and partition-table inspection.
- Tagged-release assembly from previously tested artifacts.
- Signed APT metadata plus SHA-256/SHA-512 release files.

Current evidence:

- The lightweight application-foundations contract passed on the audited branch.
- No successful full build workflow for this branch proves that the current ISO
  boots, installs, or passes its inspection contract.
- No current Pi artifact or physical Pi 4/5 test proves first boot.

## Missing Operating-System Features and Production Gaps

### Release blockers

- No successful current-branch BIOS, UEFI, Secure Boot, or graphical QEMU boot.
- No automated Hyprland login/session smoke test.
- No automated Calamares installation and installed-disk boot test.
- No complete installer matrix for encryption, unencrypted btrfs, ext4, manual
  partitioning, BIOS, EFI preservation, and non-ASCII input.
- Pi has no secure owner/account provisioning workflow.
- Pi enables SSH without a completed opt-in/key/account policy.
- Pi 4 and Pi 5 physical boot, Wi-Fi, Bluetooth, HDMI, NVMe, cooling, power-loss,
  and first-boot tests are missing.
- Current artifacts are not proven to contain the exact branch’s behavior.

### Core desktop gaps compared with macOS, Windows, GNOME, and KDE

- No production `edemint-shell`; Waybar/Wofi are approximations.
- No final desktop, app-grid, status center, notification center, control center,
  widgets, global search, recent apps/documents, or responsive shell.
- No completed mobile/narrow layouts, rotation handling, safe areas, or touch
  shell.
- No production visual Mission Control.
- No consistent green/yellow/red PanelV controls across GTK, Qt, server-side,
  and proprietary decorations.
- No final login greeter, profile selector, lock-screen integration, or power
  control matching the supplied prototypes.
- No final icon theme, cursor, logo, wallpaper, typography, boot theme,
  installer theme, or licensed artwork inventory.
- No implemented animation system or reduced-motion variants.
- The setup wizard’s “full effects” setting writes a variable but does not yet
  enable blur, shadows, or animations in the shown Hyprland configuration.

### System-management gaps

- No complete native Settings application.
- No unified notification history/do-not-disturb UI.
- No native update UI with rollback, progress, errors, release notes, and
  repository trust.
- No polished recovery environment or graphical rollback.
- No integrated backup/restore onboarding and restore testing.
- No account, parental-control, enterprise/device-management, secure remote
  support, or guest-session product.
- No OS-wide content index/search service.
- No comprehensive default-app/file-association UI.
- No storage-health, SMART alerting, low-disk remediation, or encrypted-removable
  media workflow.

### Security and privacy gaps

- AppArmor/nftables/root-lock/encryption/rollback claims need artifact and booted
  system tests.
- No complete application sandbox policy or permission broker for native apps.
- Inspector’s requested secure disposable viewers are not implemented.
- No SBOMs, provenance attestations, detached artifact signatures, or complete
  package/source manifest in releases.
- Third-party GitHub Actions are not pinned to full commit SHAs.
- No protected release environment or documented signing-key rotation/revocation.
- No explicit repository license, so public visibility is not sufficient to
  grant open-source reuse rights.
- No vulnerability-response implementation evidence, reproducible build proof,
  license scan, secret scan, dependency review, or complete CodeQL policy.
- No secure crash-reporting design with privacy-preserving opt-in/redaction.

### Update and reproducibility gaps

- The Edemint APT endpoint and public key are placeholders.
- Dependency versions are not pinned to a Debian snapshot for reproducible
  releases.
- Pi builds fetch archive keys dynamically.
- No tested install, upgrade, downgrade, revoked metadata, expired metadata,
  bad signature, interrupted dpkg, or rollback scenario.
- No proof that two builds from one source/snapshot are equivalent.

### Hardware and platform gaps

- XR driver and spatial/head-tracked AR are missing.
- Hardware matrices for Intel, AMD, NVIDIA, software rendering, tablets, HiDPI,
  multi-monitor, hotplug, suspend/resume, docks, and AR displays are missing.
- Phone cellular/SIP backends are missing.
- Fullcall network and calling backends are missing.
- No tested camera, microphone, fingerprint enrollment, printer, scanner,
  Bluetooth-audio, modem, or power-profile matrix.
- No immutable/recovery partition or A/B update mechanism.

### Accessibility, localization, and quality gaps

- No automated WCAG contrast validation.
- No complete visible-focus, logical traversal, keyboard-only, screen-reader,
  large-text, high-contrast, or reduced-motion gates.
- No German/English/RTL/CJK localization matrix.
- Current locale trimming conflicts with a multilingual general-purpose OS.
- No visual regression tests at desktop, HiDPI, narrow, portrait, and mobile
  resolutions.
- No established startup-time, memory, frame-time, idle CPU, battery, or thermal
  release measurements.
- No application crash/corrupt-state/migration/offline documentation gates.

## Precise Overall Assessment

Edemint currently has a substantial Debian-based system integration, a
cross-architecture 29-application catalog, eleven native MVP/experimental
applications, a Messenger integration shell, a configured Hyprland desktop,
security defaults, recovery helpers, AI routing, and image build pipelines.

It is not yet a production-ready operating system. The repository is strongest
as a development preview and architecture foundation. The remaining work is not
mainly “adding app names”; it is completing the native behavior, proving every
image through boot/install/hardware tests, finishing secure updates and
provisioning, implementing the production shell, and adding accessibility,
localization, reproducibility, and supply-chain evidence.

## Repository Sources

- [Application catalog](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/apps/catalog.json)
- [Application integration status](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/docs/APPLICATION_INTEGRATION_STATUS.md)
- [Application roadmap](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/docs/APPLICATIONS_ROADMAP.md)
- [Native application host](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/includes/usr/libexec/edemint-app)
- [App Library and Shortcuts](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/includes/usr/libexec/edemint-library-tools)
- [Messenger integration](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/includes/usr/libexec/edemint-messenger)
- [Base package manifest](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/package-lists/base.list.chroot)
- [Desktop package manifest](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/package-lists/desktop.list.chroot)
- [App-suite package manifest](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/package-lists/app-suite.list.chroot)
- [Hyprland configuration](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/includes/etc/skel/.config/hypr/hyprland.conf)
- [Required desktop contract](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/shared/includes/usr/share/edemint/required-desktop.packages)
- [Build workflow](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/.github/workflows/build.yml)
- [Production remediation plan](https://github.com/ashcqriss/edemix/blob/codex/app-foundations-roadmap/docs/PRODUCTION_REMEDIATION_PLAN.md)
