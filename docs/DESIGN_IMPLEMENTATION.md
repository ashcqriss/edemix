# Edemint design implementation status

This file tracks implementation of the authoritative first-build brief in
`DESIGN.md`. Prototype identities are in `prototypes/README.md`; measured colors
and hierarchy are in `PALETTE.md`.

## Phase rule

The operating-system base remains the priority. The current shell work is an
approximate, static first UI that makes the intended structure testable. It is
not the complete Edemint component system.

## Implemented for the first UI build

- Numeric palette families and corrected importance hierarchy.
- Blue-led shell tokens: ultramarine/azure core, navy anchor, and selective
  eco-green/turquoise accents.
- A persistent left pinned-app dock with a lower all-apps search/completer.
- A separate top-right date/time, connection, and system-status region.
- Rounded Hyprland window geometry and palette-driven active borders.
- Lock hierarchy based on `login_screen`: persistent time/date, centered
  username, and compact password input.
- Power menu retaining lock, log out, suspend, reboot, and shutdown actions.
- Low-power defaults with blur, shadows, and animations disabled.

## Hydroganic app design system (bp_des_5 pass)

Edemint's liquid glass is named **hydroganic**; translucent layered surfaces
are **frosty glass**. Both are implemented for the first-party GTK4 apps:

- `/usr/share/edemint/design/hydroganic.css` defines the palette tokens from
  `PALETTE.md`, frosty-glass windows/cards/wells, hydroganic buttons and
  controls (organic top light, hue-and-lightness-matched blue-to-blue and
  green gradients), turquoise focus rings, `panelv` window-control colors,
  and per-app accent subsets (`ed-accent-eco`, `ed-accent-turquoise`).
- `/usr/share/edemint/design/edemint_design.py` is the shared runtime every
  first-party app loads: stylesheet installation, `ed-frost` window marking,
  hero headers, symmetric equal-width action rows, and `Adw.Breakpoint`
  helpers for narrow/mobile collapsing. Apps degrade gracefully without it.
- All first-party apps (Settings, Activity Monitor, Console, Fullcall,
  Messenger, Phone, Inspector, App Library, Shortcuts, Automator, Default
  Apps, Mission Control, Sticky Notes) load the system. Layout corrections in
  the same pass: Settings sidebar icons and collapsing split view, Activity
  Monitor stat tiles with allocation-sized sparklines, Console column headers
  with an explicit empty state, composer pills whose primary button matches
  the entry height (Fullcall, Messenger, Phone), a centered App Library tile
  grid, a macOS-style Mission Control with a workspace shelf and window
  tiles, and paper-gradient Sticky Note windows.
- Frost never depends on compositor effects: every surface alpha reads on
  plain navy. `$ed_glass` in Hyprland gates blur for capable profiles, and
  waybar/notification layers blur with it so glass reads as one system.
- Integrated apps inherit the palette through skel `gtk-4.0/gtk.css`
  (importing the shared stylesheet) and a GTK3 recolor for Thunar-class
  apps; `gtk-decoration-layout` applies the `panelv` order system-wide.

## Deliberately pending

- Final logo, profile picture, wallpapers, fonts, production icon theme, and
  cursor theme. Dock labels remain readable text placeholders.
- The `dock` tap-in-void overlay, including four semi-transparent overlapping
  lines and its dedicated app-symbol layout.
- Complete widget surfaces and responsive `mobileratioqo` /
  `mobile_dock_ratio_2` behavior, including rotated/sidebar layouts.
- Production `panelv` controls across GTK and Qt. Green expands/fullscreens,
  yellow minimizes/hides, and red closes, but consistent implementation needs
  toolkit decoration work or a maintained compositor-decoration plugin.
- Final power glyph artwork and expansion animation.
- All other animations and motion curves.
- Binary import of the eight original JPEGs into `docs/prototypes/`. Their
  SHA-256 identities are recorded for later byte-for-byte verification.

## Build caveat

The existing image build installs Hyprland, hyprlock, and wlogout as optional
best-effort Debian packages. If a selected Debian snapshot does not provide one
for the target architecture, the image can still build but that surface will be
unavailable. This is pre-existing build policy rather than a design limitation.
