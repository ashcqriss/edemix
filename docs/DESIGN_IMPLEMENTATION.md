# Edemint design implementation status

This file tracks implementation of the original references described in
`DESIGN.md`. The source JPEG identities and interpretation are recorded in
`prototypes/README.md`; measured colors are in `PALETTE.md`.

## Implemented

- Numeric primary, secondary, power, and window-control colors.
- Separate desktop shell surfaces for the left application dock and top-right
  status strip, implemented as two Waybar instances.
- Rounded Hyprland window geometry and palette-driven active borders.
- Lock-screen hierarchy based on `login_screen`: persistent time/date,
  centered username, and compact password field.
- Power-menu styling based on `on_off2`, while retaining lock, log out,
  suspend, reboot, and shutdown actions.
- Low-power defaults: blur, shadows, and animation remain disabled.

## Deliberately pending

- Final logo. The current one-letter SVG remains a placeholder because none of
  the supplied references defines a finished logo.
- Profile-picture artwork for the lock screen.
- Production icon and cursor themes. Dock labels remain readable text until the
  icon masters exist.
- Wallpaper masters and responsive mobile/portrait shell behavior.
- `panelv` client window controls. Their green/yellow/red semantics are fixed,
  but implementing them consistently requires a GTK/Qt decoration theme or a
  maintained compositor decoration plugin, not only Hyprland CSS.
- Binary import of the eight original JPEG references into `docs/prototypes/`.
  Their SHA-256 identities are already recorded so a later import can be
  checked byte-for-byte.

## Build caveat

The existing image build installs Hyprland, hyprlock, and wlogout as optional
best-effort Debian packages. If a selected Debian snapshot does not provide
one of them for the target architecture, the image can still build but that
surface will not be available. This is pre-existing build policy rather than a
design limitation.
