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
- Flat fills everywhere: the former gradient active window border is now flat
  ultramarine, the placeholder logo lost its gradient, and no shipped surface
  uses a gradient (gradients are forbidden by default per `DESIGN.md`).
- Light/dark mode doctrine recorded in `PALETTE.md`: mode flips app
  backgrounds and swaps accents between light and dark steps of the same
  family; all other elements keep their fixed palette hues. The first build
  ships the dark set as the OS default (GTK settings, dconf color-scheme for
  libadwaita/portal apps, and Qt via the gtk3 platform theme).
- App content backgrounds are plain black (dark set) / white (light set),
  applied through GTK3 and GTK4/libadwaita named-color overrides in skel
  `gtk.css` and the foot terminal. The elements on that background keep
  their palette hues: navy-700 header bars / sidebars / cards / popovers,
  ultramarine-500 selection and filled accents, ultramarine-200 accent text,
  semantic success/warning/danger. Shell surfaces stay palette-led and do
  not switch to black/white. The light counterpart replaces these files
  when mode switching lands.
- A persistent left pinned-app dock with a lower all-apps search/completer.
- Palette-styled wofi completer surface (rounded, flat, text placeholders)
  and mako notification surface with a persistent danger style for critical
  urgency.
- A separate top-right date/time, connection, and system-status region.
- Rounded Hyprland window geometry and palette-driven active borders.
- Lock hierarchy based on `login_screen`: persistent time/date, centered
  username, and compact password input.
- Power menu retaining lock, log out, suspend, reboot, and shutdown actions.
- Low-power defaults with blur, shadows, and animations disabled. The "full"
  effects profile is now functional: `edemint-setup` writes
  `~/.config/hypr/effects.conf`, sourced after the low-power defaults.
- GRUB theme, Calamares sidebar/slideshow/logo, foot terminal palette, and the
  setup wizard colors aligned to `PALETTE.md` (the pre-palette cyan/green
  placeholder values are gone).
- OS-wide surfaces beyond the shell: tuigreet login theme (named terminal
  colors approximating the families), a minimal Calamares `stylesheet.qss`
  (light installer surface, dark accent steps), swayosd volume/brightness OSD,
  and fastfetch defaults.

## Known whole-OS gaps

- No Plymouth boot splash is shipped at all (the package is absent); boot
  shows kernel text until the greeter. A palette Plymouth theme is a separate
  work item that also touches initramfs and kernel cmdline.
- TTY apps (tuigreet, whiptail, fastfetch) can only approximate the palette
  with terminal colors.
- Firefox, and any app drawing proprietary decorations or theming, follows
  only the dark-mode preference, not the palette.

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
