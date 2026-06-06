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
