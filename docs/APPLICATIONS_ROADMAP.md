# Edemint Application Platform and Core Apps Roadmap

Status: production planning baseline

Scope: desktop and mobile-shaped Edemint sessions on Debian 13 (Trixie), `amd64` and `arm64`

This document defines how Edemint will add its core applications without destabilizing the bootable OS base, misrepresenting upstream software, bypassing Unix security, or making the Raspberry Pi image unnecessarily large. Icons and final visual assets are deliberately deferred.

## 1. Product principles

1. Keep the operating-system base bootable before adding application volume.
2. Prefer maintained Debian applications and platform services for the first working release.
3. Build native Edemint applications only where they create a coherent system capability that an upstream application cannot provide.
4. Do not silently rename third-party software as an original Edemint implementation. Transitional launchers must disclose the upstream engine or application in About and package metadata.
5. Use Wayland-native APIs, XDG Desktop Portals, PipeWire, NetworkManager, BlueZ, UPower, UDisks2, CUPS and colord instead of direct privileged hardware access.
6. No graphical application runs as root. Privileged operations use narrowly scoped D-Bus services and polkit actions.
7. Every baseline package must resolve on both `amd64` and `arm64` in Debian Trixie before it is added to an image package list.
8. Large professional tools remain optional store installs unless they are essential for first boot.
9. Application identity, AppStream metadata and functionality come before final icons and animation.
10. A failed application must not prevent login, the compositor, Filer, Settings or recovery tools from starting.

## 2. Verified current inventory

The following inventory is verified from the repository package lists. It describes installed foundations, not completed Edemint-branded products.

| Requested capability | Existing repository foundation | Current gap |
| --- | --- | --- |
| Browser | Firefox ESR | Not WebKitGTK and not Adventurer |
| Settings | NetworkManager applet, Blueman, Pavucontrol, brightnessctl, power-profiles-daemon | No unified Settings application |
| Activity monitor | GNOME System Monitor, Baobab, htop | No unified GPU, disk-I/O and network-detail experience |
| Filer | Thunar, file-roller, GVfs-related desktop stack | Not named or integrated as Filer |
| App store | GNOME Software, Flatpak and its GNOME Software plugin | No Edemint-certified catalog or signing policy |
| Bluetooth | BlueZ and Blueman | No Edemint settings page |
| Calculator | GNOME Calculator | Identity and shell integration pending |
| Terminal and console tools | Foot, nano, Neovim and htop | Product distinction and launchers pending |
| Print services | CUPS, cups-browsed, Avahi | Complete printer-management UI not proven |
| Camera foundations | v4l-utils and libcamera-tools in the AR package set | No standard or advanced GUI camera application |
| Files and media inspection | Evince, EOG, imv, mpv and file-roller | No hardened Inspector sandbox |
| Storage tools | GNOME Disk Utility and Baobab | Not integrated into Settings or Activity Monitor |

The following requested products are not represented by a verified dedicated implementation in the repository: Adventurer, unified Settings, Edemint Activity Monitor, Messenger, Calendar, Maps, App Library, Inspector, Mail, Noterer, Dictionary, font management, Mission Control, Sticky Notes, color control, camera GUIs, Automator and an Edemint-certified store.

## 3. Package admission gate

No candidate package is added directly to `desktop.list.chroot` or `base.list.chroot` until a package-resolution job proves all of the following:

- the package exists in Debian Trixie;
- it resolves on `amd64` and `arm64`;
- dependencies do not remove or replace the Hyprland, PipeWire or portal stack;
- installation is noninteractive;
- the installed-size delta is recorded;
- the application can launch in the Edemint Wayland session;
- its license is compatible with redistribution;
- AppStream and desktop metadata are valid;
- it does not require an uncurated external repository.

Candidate names in this roadmap are implementation leads, not yet verified package commitments.

## 4. Application decisions

### 4.1 Adventurer browser

**Decision:** build Adventurer on WebKitGTK, not Apple Safari or private Apple frameworks.

WebKitGTK is the supported Linux WebKit port. The first usable milestone may adopt GNOME Web as a clearly disclosed WebKitGTK reference application while the native Adventurer shell is developed.

Minimum native Adventurer scope:

- GTK4/libadwaita user interface using the stable WebKitGTK API available in Debian Trixie;
- tabs, back/forward/reload, address and search field;
- history, bookmarks, downloads and private windows;
- clear TLS error pages and certificate details;
- per-site camera, microphone, location, notification and clipboard permissions;
- portal-based file chooser and downloads;
- pop-up, mixed-content and unsafe-download controls;
- crash isolation and session recovery;
- selectable search provider;
- no bundled proprietary codecs or services.

Acceptance: Web Platform Tests smoke set, TLS failure tests, permission tests, download tests, keyboard navigation, screen-reader labels and clean launch on both architectures.

### 4.2 Settings

**Decision:** create a native Edemint Settings shell with modular pages backed by existing system services.

Required pages:

- Network and Wi-Fi through NetworkManager;
- Bluetooth through BlueZ;
- Sound through PipeWire and WirePlumber;
- Displays and brightness through compositor output APIs, backlight sysfs helpers and DDC only where supported;
- Power through UPower and power-profiles-daemon;
- Appearance, wallpaper, color tokens, dark/light preference and accessibility;
- Printers through CUPS;
- Color profiles through colord;
- Storage through UDisks2;
- users, passwords and authentication through AccountsService and polkit;
- privacy and application permissions through portals and Flatpak metadata;
- language, region, date and time;
- updates and software sources;
- system information and legal notices.

Brightness controls must report unsupported hardware honestly. Volume control must expose output, input, per-application streams and mute state. No page may write arbitrary files as root.

### 4.3 Activity Monitor

**Decision:** create a native monitor that combines process and hardware views while retaining GNOME System Monitor and htop as recovery tools during development.

Data sources:

- CPU, memory, swap and processes from `/proc`;
- disks and mount health from UDisks2 and `/sys`;
- disk throughput from kernel statistics;
- network throughput and interfaces from NetworkManager and kernel counters;
- GPU utilization, memory and temperature from DRM/sysfs or vendor-neutral interfaces when the driver exposes them;
- temperatures and fans from hwmon;
- per-application audio activity from PipeWire where useful.

GPU reporting is best effort. The UI must say `Not reported by this driver` instead of showing fabricated zero values. Signals are limited to processes owned by the user; actions against other users require a specific polkit authorization.

### 4.4 Filer

**Decision:** ship a working Filer identity over a maintained file-manager foundation first. Do not fork a file manager until Edemint-specific requirements justify the maintenance cost.

Phase 1 requirements:

- expose the existing Thunar foundation as `Filer` through Edemint-owned launcher metadata;
- retain upstream attribution in About and package metadata;
- support trash, search, removable media, archives, thumbnails and common network locations;
- use portals for opening files in sandboxed applications;
- provide `Open in Inspector` for untrusted content;
- never request blanket root access.

Phase 2 considers a native GTK4 Filer only after performance, accessibility and feature parity tests are defined.

### 4.5 Messenger

**Decision:** protocol choice precedes implementation. Matrix is the recommended open baseline; proprietary services are not promised without supported public APIs and licensing.

First milestone:

- one audited Matrix client foundation or a small Edemint Matrix client;
- encrypted account storage in Secret Service;
- end-to-end encryption support before claiming private messaging;
- portal notifications and file access;
- no silent contact upload;
- explicit device verification and session management.

SMS, iMessage, WhatsApp and other closed networks are separate integrations and cannot be represented as universally available.

### 4.6 Certified App Store

**Decision:** use signed repository metadata and AppStream. Never install arbitrary executables from web URLs by default.

The store combines:

- Edemint-signed Flatpak remote for desktop apps;
- Debian packages only through configured signed APT repositories;
- AppStream metadata, screenshots, version, license, architecture and permission display;
- an allowlist and review state: `certified`, `verified publisher`, `community`, or `blocked`;
- signature, checksum and revocation verification;
- transactional install/remove/update behavior;
- disk-space preview and rollback where the packaging system supports it;
- parental or administrator policy hooks;
- a security-report channel.

GNOME Software remains the initial functional frontend until an Edemint store client meets these requirements.

### 4.7 Calendar, Maps and Mail

**Decision:** adopt maintained GNOME foundations first, subject to the package admission gate.

Candidate foundations:

- Calendar: GNOME Calendar;
- Maps: GNOME Maps;
- Mail: Geary.

Required integration includes portal notifications, Secret Service credentials, correct default-application handling, online/offline behavior and truthful upstream attribution.

### 4.8 App Library

**Decision:** build App Library as an Edemint shell component, not a standalone package manager.

It indexes desktop entries and AppStream metadata, groups applications, supports keyboard search, exposes recent and installed applications and launches through the compositor session. It must update incrementally and remain usable without network access.

### 4.9 Inspector

**Decision:** build a hardened file-preview launcher. Inspector does not and must not bypass Unix file permissions.

Inspector may open only a file the current user can already read or a file explicitly granted through a portal. Its sandbox profile provides:

- a read-only bind of the selected file;
- a disposable empty home and temporary directory;
- no network by default;
- no device, process, SSH-agent, password-store or arbitrary D-Bus access;
- only the minimum Wayland and portal access required for display and accessibility;
- MIME detection from content and extension mismatch warnings;
- resource limits and timeouts;
- optional malware scanning as an additional signal, never as the sandbox boundary;
- dedicated previewers for text, image, PDF, audio/video and archive listings;
- no active document macros, embedded scripts or archive extraction by default.

Candidate platform tools include bubblewrap, xdg-dbus-proxy, AppArmor and XDG Desktop Portals, all subject to package and architecture verification.

### 4.10 Noterer and Sticky Notes

**Noterer decision:** adopt a maintained plain-text editor first, then create an Edemint editor only if required. It must support UTF-8, undo/redo, find/replace, autosave recovery, line endings and portal file access without pretending to be a rich word processor.

**Sticky Notes decision:** build a small Edemint layer-shell application. Notes persist locally, remain on the selected workspace unless the user hides them and expose pin, color, opacity, archive and delete controls. Persistence uses a versioned local database or structured data store with atomic writes. Screen position is clamped after display changes.

### 4.11 Bluetooth Manager

**Decision:** keep BlueZ and Blueman as the initial functional stack while implementing the Bluetooth page in Settings.

Required behavior includes discovery, pairing confirmation, trusted-device management, connect/disconnect, battery reporting where available, audio-profile selection and clear adapter-disabled or hardware-absent states.

### 4.12 Dictionary

**Decision:** provide local-first dictionary lookup with optional network sources. Package and dictionary-data availability must be verified before selection.

Requirements include offline lookup, language selection, pronunciation field support where data permits, source attribution, no search telemetry by default and installation of additional dictionaries through the store.

### 4.13 Console and Terminal

**Terminal:** Foot remains the initial terminal emulator. Edemint integration supplies profiles, font/color settings, safe paste warnings and shell defaults.

**Console:** define Console as the friendly system-log and diagnostic viewer, not a second terminal. It reads the user journal by default, supports filtering/export and requests authorization only for protected system logs.

### 4.14 Font Management

**Decision:** adopt a maintained font-manager foundation first.

Requirements include preview, user-level installation, duplicate detection, metadata and license display, enable/disable, variable-font axes where supported and explicit authorization for system-wide installation.

### 4.15 Mission Control

**Decision:** implement as a compositor-integrated shell surface.

It shows workspaces and windows, supports keyboard/touch navigation, drag between workspaces, close and focus actions, multi-monitor layouts and reduced-motion mode. It uses Hyprland IPC through a small bounded service and must survive compositor event reconnects.

### 4.16 Color Control

**Decision:** integrate colord into Settings and provide a focused advanced utility only if needed.

Scope includes ICC profile assignment, calibration-device handoff, display profile import, soft-proof selection where applications support it and clear separation between UI theme colors and hardware color management.

### 4.17 Print Control

**Decision:** use CUPS as the backend with a maintained management frontend first, then integrate common operations into Settings.

Required flows: discovery, add/remove, default printer, queue, cancel/retry, duplex/color/paper options, test page, driverless IPP Everywhere preference and clear authentication prompts.

### 4.18 Camera and Camera Studio

**Camera:** a small default application for photo, video, timer, camera selection, microphone selection and portal permissions.

**Camera Studio:** an optional advanced install for manual controls, exposure, focus, white balance, frame rate, resolution, audio meters, scenes, overlays and recording profiles. Unsupported controls must be disabled based on actual V4L2/libcamera capability discovery.

The advanced application is not part of the minimal Pi image unless size and performance budgets are met. Candidate maintained foundations must pass Wayland, PipeWire, libcamera and architecture tests.

### 4.19 Automator

**Decision:** build a permission-aware workflow runner rather than exposing unrestricted root shell scripts as friendly automation.

Initial action model:

- files and folders selected through portals;
- application launch and URL open;
- notifications, timers and calendar triggers;
- text transformation;
- approved command execution in a visible sandbox;
- explicit secrets access through Secret Service;
- import/export of signed, versioned workflow documents;
- per-workflow permission summary and revocation.

Workflows from the web open disabled in Inspector and require explicit review before activation.

### 4.20 Calculator

**Decision:** retain GNOME Calculator initially and integrate its launcher and AppStream identity. A native replacement is unnecessary unless Edemint requires behavior not available upstream.

Acceptance includes basic, scientific and programmer modes, locale-aware input, keyboard operation and no network dependency for ordinary calculations.

## 5. Shared application platform

Before native Edemint apps multiply, establish reusable libraries and services:

- design tokens matching `docs/DESIGN.md` without final icons;
- GTK4/libadwaita component library for headers, sidebars, dialogs and status surfaces;
- application ID and D-Bus naming policy under an Edemint-controlled reverse-DNS namespace;
- logging, crash reporting and privacy policy with telemetry disabled by default;
- portal helpers for files, URLs, notifications, camera, microphone, printing and screenshots;
- Secret Service credential helper;
- polkit helper pattern with one action per privileged operation;
- AppStream, desktop-entry, MIME and default-application templates;
- accessibility checklist and automated metadata validation;
- localization extraction and fallback rules;
- semantic versioning and migration policy for settings and local data.

## 6. Delivery phases

### Phase 0: inventory and proof

- add architecture-aware package resolution and installed-size reports;
- record licenses and upstream project URLs;
- verify every candidate in a disposable Debian Trixie environment;
- establish application IDs and ownership;
- define minimal, desktop and optional application profiles.

Exit: no unresolved package name, architecture, license or image-size question for Phase 1.

### Phase 1: working upstream foundations

- add only verified calendar, maps, mail, text editor, font, print, color and camera foundations;
- add a verified WebKitGTK browser foundation without disguising it as completed Adventurer;
- retain current recovery applications;
- keep Camera Studio and large optional tools out of the base image.

Exit: every installed application launches on Wayland on `amd64` and `arm64`, has valid metadata and does not break ISO or Pi contracts.

### Phase 2: Edemint identity and integration

- add honest Edemint launchers for Filer and established foundations;
- implement App Library indexing;
- add default-app and MIME policies;
- connect design tokens and accessibility settings;
- complete AppStream metadata and legal notices.

Exit: coherent naming and shell integration with upstream attribution intact.

### Phase 3: core native system apps

- Settings;
- Activity Monitor;
- Console;
- Store catalog and policy client;
- Adventurer minimum viable browser.

Exit: production acceptance suites pass and upstream recovery tools remain available.

### Phase 4: security boundary

- Inspector sandbox profiles;
- untrusted-file routing from Filer, Mail, Messenger and browser downloads;
- workflow import quarantine;
- permission viewer and revocation UI.

Exit: threat-model review, sandbox escape tests and malicious fixture suite pass.

### Phase 5: communications and productivity

- Messenger after protocol decision;
- Noterer and Sticky Notes;
- Calendar/Mail account integration;
- Dictionary;
- Automator constrained action set.

Exit: encrypted credential storage, offline behavior and backup/restore tests pass.

### Phase 6: shell experiences

- Mission Control;
- mobile-shaped App Library and launcher layouts;
- multi-monitor and orientation behavior;
- touch targets, keyboard navigation and reduced motion.

Exit: desktop and 1080x1920 reference layouts pass automated and physical-device checks.

### Phase 7: selective native replacements

Replace an upstream foundation only when a written decision demonstrates a user benefit, maintenance owner, migration path, accessibility parity and test coverage. Visual consistency alone is not enough reason to fork complex software.

## 7. Image profiles and size policy

**Minimal recovery profile:** Filer foundation, Settings essentials, Terminal, Calculator and recovery diagnostics.

**Desktop profile:** minimal plus Adventurer foundation, store, mail, calendar, maps, Noterer, camera and standard utilities.

**Optional store profile:** Camera Studio, development tools, additional dictionaries, advanced font/color tools and large communications clients.

Each application integration reports compressed image delta, installed disk delta, idle memory and cold-start time. Pi baseline additions require explicit performance evidence. Optional applications must not be pulled into the base through broad recommends.

## 8. CI and test contract

Application changes are split from OS-base changes and must not force the long Pi image build until lightweight gates pass.

Required lightweight gates:

- package resolution for `amd64` and `arm64`;
- license and source inventory;
- desktop-entry and AppStream validation;
- dependency and image-size diff;
- unit tests and static analysis;
- GTK and D-Bus API tests;
- sandbox policy tests;
- headless Wayland launch smoke tests.

Only after those pass:

- build and inspect the `amd64` ISO;
- run application smoke tests in the image;
- build the Pi image when package or architecture-sensitive content changed.

When a newer workflow supersedes an older run, the older run should be cancelled. Failed jobs should be rerun selectively when the source and relevant inputs are unchanged.

## 9. Definition of done for every app

An application is not complete until it has:

- a named maintainer and upstream dependency owner;
- reproducible builds on `amd64` and `arm64`;
- valid desktop, AppStream, MIME and legal metadata;
- Wayland-native launch or a documented temporary compatibility path;
- keyboard-only and screen-reader usable primary flows;
- high-contrast and reduced-motion behavior;
- portal-based file and device access where applicable;
- no unnecessary root, network or D-Bus access;
- crash recovery and corrupt-state handling;
- migration tests for persistent data;
- offline behavior documentation;
- unit, integration and image smoke tests;
- measured image size, idle memory and launch time;
- a user-facing privacy and permission explanation;
- no dependency on unfinished icons or animations.

## 10. Proposed change sequence

Keep changes reviewable and independently reversible:

1. Package candidate verifier and architecture matrix.
2. Small upstream-foundation package additions.
3. Application identity, AppStream and default-app policy.
4. Shared GTK/portal/polkit platform.
5. Settings vertical slice: audio, display and power.
6. Activity Monitor vertical slice: CPU, memory, disk and network.
7. Inspector threat model and sandbox prototype.
8. Filer integration and Inspector routing.
9. Adventurer browser shell.
10. Certified store metadata and signing pipeline.
11. Remaining productivity, communication and shell applications.

No step above should be combined with unrelated bootloader, installer or image-layout work.
