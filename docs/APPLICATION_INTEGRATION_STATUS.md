# Application Integration Status

Branch: `codex/app-foundations-roadmap`

This matrix distinguishes installed foundations, functional Edemint MVPs, and
experimental products. An application being present in the image does not mean
that every production roadmap requirement is complete.

## Native Edemint MVPs

| App | Current integrated behavior | Remaining production work |
| --- | --- | --- |
| Settings | Launches NetworkManager, Blueman, PipeWire, display, color, print, disk and power tools from one Edemint window | Native pages, polkit helpers, complete display/power/privacy controls |
| Activity Monitor | Live memory, load, network totals and DRM GPU discovery; links to process and storage tools | Per-process charts, disk throughput, driver-specific GPU telemetry |
| App Library | Discovers, searches and launches installed desktop applications; adds application entries to Shortcuts | Categories, recent apps, mobile layout and incremental cache |
| Shortcuts | Creates, lists, runs and removes application, web and folder shortcuts using atomic local storage | Categories, drag ordering, global key bindings and synchronization |
| Inspector | Read-only metadata and bounded text/hex preview for an explicitly selected readable file | Bubblewrap viewer profiles for PDF, media, images and archives |
| Console | Read-only user journal viewer | Structured filtering, export and authorized system-log access |
| Mission Control | Lists Hyprland workspaces and windows | Interactive overview, drag, focus, touch and multi-monitor controls |
| Sticky Notes | Persistent atomic local note storage | Multiple notes, pinning, layer-shell positioning, color and archive |
| Automator | Runs a small reviewed allowlist of local actions | Versioned workflows, permissions, triggers and sandboxed imports |
| Fullcall | Independent local channel/message store and native UI | Matrix sync, encryption, accounts, WebRTC calls and server services |
| Phone | Independent dialer, local call-history store and modem diagnostics | Tested ModemManager voice calls, SIP engine, contacts and audio routing |

Fullcall and Phone are deliberately labelled `experimental`. Their launchers
must not claim that network calling, encryption, cellular service or emergency
calling is complete.

## Maintained foundations

| Edemint name | Foundation |
| --- | --- |
| Adventurer | GNOME Web / WebKitGTK |
| Filer | Thunar |
| Messenger | Nheko / Matrix |
| App Store | GNOME Software and Flatpak |
| Calendar | GNOME Calendar |
| Maps | GNOME Maps |
| Mail | Geary |
| Noterer | GNOME Text Editor |
| Bluetooth Manager | Blueman and BlueZ |
| Dictionary | GoldenDict-ng |
| Font Manager | Font Manager |
| Terminal | Foot |
| Color Control | GNOME Color Manager and colord |
| Print Control | system-config-printer and CUPS |
| Camera | Cheese |
| Camera Studio | Webcamoid |
| Calculator | GNOME Calculator |
| Contacts | GNOME Contacts |

Foundation launchers retain upstream attribution in desktop metadata. They are
not represented as original Edemint implementations.

## Image profiles

- The full 29-app catalog is wired into both the amd64 desktop image and the
  Raspberry Pi arm64 image.
- The shared package contract verifies every Debian foundation on both
  architectures before either expensive image job is started.
- No icon or animation work is required for functional integration.

## Release gates

Before this branch is merged:

1. package resolution must pass for `amd64` and `arm64`;
2. Python source, shell wrappers, catalog and desktop files must validate;
3. native apps must launch in a Debian Trixie Wayland test session;
4. installed-size deltas must be reported;
5. the amd64 ISO contract must pass;
6. Pi image construction starts only after lightweight and size gates pass;
7. Phone and Fullcall require physical/backend tests before production status.
