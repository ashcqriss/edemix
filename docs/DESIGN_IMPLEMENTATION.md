# Edemint design implementation status

This file tracks implementation of the authoritative first-build brief in
`DESIGN.md`. Prototype identities are in `prototypes/README.md`; measured colors
and hierarchy are in `PALETTE.md`.

## Phase rule

The operating-system base remains the priority. The current shell work is the
first Liquid Glass UI: the intended structure, material, and motion are real
and testable, but it is not the complete Edemint component system.

## Implemented for the first UI build

- Numeric palette families and corrected importance hierarchy.
- **Flat pure-black canvas** (`swaybg -c 000000`, `misc:background_color`) —
  no gradient, no wallpaper. Light mode's pure-white canvas is defined by the
  brief but not yet wired to a session toggle.
- **Liquid Glass shell, on by default** (`hyprland.conf`): compositor blur
  (+ vibrancy) behind every shell layer (`waybar`, `wofi`, `notifications`,
  `swayosd`, `logout_dialog`), soft shadows, 16px rounded windows, and
  palette-driven active borders (ultramarine→eco, a sanctioned bright
  transition).
- **macOS-like motion, on by default**: spring pop-in for windows and layers
  (`edeSpring` overshoot bezier), eased fades, border-color easing, workspace
  slide-fade. Hover states on shell controls ease via CSS transitions.
- **Low-power opt-out instead of low-power default**: `profile.conf` is
  sourced at the *end* of `hyprland.conf`, so it can override the glass with
  plain `section:option` keywords. `edemint-setup`'s effects chooser writes
  either the glass default or the low-power override block (blur, shadows,
  animations off) — the old `$low_power` variable, which nothing consumed,
  is gone.
- **Glass status region** (waybar): translucent neutral pills with specular
  hairlines; the clock leads in ultramarine; solid color is reserved for
  operational signals (privacy red, battery-critical red, update yellow).
- **Glass pinned-app dock** (waybar): one frosted slab of rounded glass
  tiles; periwinkle hover; eco-green all-apps pill; the power tile carries
  the final `on_off2` motif (yellow on violet).
- **Glass launcher** (wofi config + style): the first-build all-apps
  search/completer — capsule search field, rounded rows, ultramarine
  selection.
- **Glass notifications** (mako): translucent black toasts, periwinkle edge,
  solid red reserved for critical urgency.
- **Lock hierarchy** (`hyprlock.conf`, from `login_screen`): persistent
  time/date, a glass profile-picture circle with periwinkle rim, centered
  username, compact capsule password input on the black canvas.
- **Glass power menu** (wlogout): translucent scrim + glass action tiles;
  hover/focus fills with the final `on_off2` yellow-on-violet power motif;
  shutdown carries the `panelv` red close semantic.
- **Glass terminal** (foot): pure-black at 92% alpha so the compositor frosts
  what's behind it.
- **Boot & installer on the flat canvas**: GRUB theme and Calamares branding
  moved from the old placeholder blue-grays to black + palette accents;
  `edemint-setup`'s TUI palette matches.

## Deliberately pending

- Final logo, profile picture, wallpapers, fonts, production icon theme, and
  cursor theme. Dock labels remain readable text placeholders.
- A light-mode (pure-white canvas) session toggle mirroring the dark default.
- The `dock` tap-in-void overlay, including four semi-transparent overlapping
  lines and its dedicated app-symbol layout.
- Complete widget surfaces and responsive `mobileratioqo` /
  `mobile_dock_ratio_2` behavior, including rotated/sidebar layouts.
- Production `panelv` controls across GTK and Qt. Green expands/fullscreens,
  yellow minimizes/hides, and red closes, but consistent implementation needs
  toolkit decoration work or a maintained compositor-decoration plugin.
- Final power glyph artwork and the power control's expansion animation;
  other per-component choreography beyond the shell's glass motion.
- Binary import of the eight original JPEGs into `docs/prototypes/`. Their
  SHA-256 identities are recorded for later byte-for-byte verification.

## Build caveat

The existing image build installs Hyprland, hyprlock, and wlogout as optional
best-effort Debian packages. If a selected Debian snapshot does not provide one
for the target architecture, the image can still build but that surface will be
unavailable. This is pre-existing build policy rather than a design limitation.
On such images the glass defaults simply have no compositor to run on.
