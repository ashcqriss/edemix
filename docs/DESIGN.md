# Edemint design reference

The structural build-out (everything else in this repo) deliberately ships
**placeholder visuals**: a one-letter "E" logo SVG, default Hyprland colors,
a stub Calamares slideshow, a colors-only GRUB theme, etc. This document
captures the source-of-truth design notes from the planning session so the
design pass — explicitly deferred from the first build-out — has a brief to
work from and nothing gets lost.

**Status:** **no logo exists yet** — the SVG at
`shared/includes/etc/calamares/branding/edemint/logo.svg` is a placeholder.
All prototype attachments the user provided during planning are **prototypes,
not a finished mark**. The actual logo / cursor theme / icon theme / fonts /
wallpaper are produced in the design pass.

The prototype PNG/SVG files the user attached during planning are **not
currently committed to this repo** — they live only in the planning session.
When the design pass starts, the prototypes should be re-attached and
committed under `docs/prototypes/` so this doc + the images are co-located.

## Source deliverables (four masters, everything else is derived)

1. **Logo (SVG master)** — feeds Plymouth, greeter, Calamares, GRUB,
   "About" dialogs.
2. **Cursor theme** — full named set: arrow, I-beam, hand, resize (↔ ↕ ⤡),
   move, wait, not-allowed, grab/grabbing, crosshair, help — at multiple
   HiDPI sizes.
3. **Icon theme** — apps, folder, MIME types, status (battery / wifi /
   bluetooth / volume / brightness), action icons, symbolic variants.
4. **Wallpaper(s) + fonts** — UI font, monospace, Nerd/icon font.

## Derived / placement targets

Where the four sources end up:

- GRUB background (`/boot/grub/themes/edemint/`)
- Pi firmware splash (`/boot/firmware/`)
- Plymouth logo + spinner
- greetd login background + logo
- Waybar glyphs
- Window-decoration buttons (panelv green/yellow/red — see below)
- Volume / brightness OSD icons (swayosd)
- Notification icons (mako)
- Calamares banner / sidebar / slideshow
- PNG logo exports at 16, 24, 32, 48, 64, 128, 256, 512 px
- Favicon
- fastfetch logo
- Website / social art

## Prototype files & functions

Names match the prototype attachments captured during planning. Placeholder
fills in the mockups (yellow / green / blue tiles) **do not map to the final
palette** — they were just for differentiation. Real colors come from the
palette below.

| Prototype | Description |
|---|---|
| `main_homescreen` | Default desktop. Left = main app dock (pinned apps). Bottom pill = expandable "all apps" search/completer. Right pink line = date/time + connection/status. App tiles are rounded placeholders, smaller than drawn. |
| `dock` | Tap-in-void view. Tiles are placeholder icons. Left "lines" are **four half-transparent overlapping bars**. |
| `panelv` | Window controls. **Green = expand/fullscreen, yellow = hide/minimize, red = close**. Confirmed; differs from the macOS convention. |
| `mobileratioqo` | Portrait mobile homescreen (also the default aspect). Mostly blue. Centered icons. Bottom line = current-app-page indicator. Top-left line = time/date/status. |
| `mobile_dock_ratio_2` | 1080×1920 view. Yellow = widgets (available on any homescreen, only previewed here). Bottom neon-pink pill = expandable app component. Top pink square = date/time/status. |
| `login_screen` | Centered circle = profile picture. Yellow rect above = username. Password field = half the yellow rect's width (only when a code is enabled). Top pink box = date/time (shown even when locked). |
| `on/off2` | Power glyph (yellow circle + a second component, e.g. the wave). Expands to standby / off / on. Oriented for keyboards. |

**Animations are deferred** for every component above. The design pass
defines motion curves separately.

## Color system

### Primary palette (cool diagram)

Complexes read left → right in the planning attachment:

| ID | Family | Count | Notes |
|----|--------|------:|-------|
| C1 | ultramarine blues | 3 | |
| C2 | plum / purple | — | |
| C3 | bright "eco" greens | 3 | includes one pastel |
| C4 | dark greens | — | |
| C5 | darkest greens | 4 | |
| C6 | navy gradient | 2 | smallest complex |
| C7 | turquoise / green-blue | 4 | |
| C8a | azure + ultramarine | 2 | last in the diagram |
| C8b | dark blues | — | second from left |

### Importance pyramid

| Tier | Use | Colors |
|------|-----|--------|
| **L1** | Everywhere; the design language. Dock, system, homescreens. | C1 (ultramarine) + C3 (bright light-green) + C8a (azure/ultramarine) |
| **L2** | Common, anchored. | C6 (navy) + C4 (dark greens) + C8b (dark blues) |
| **L3** | Supporters. | C7 (turquoise / green-blue) |
| **L4** | Rare; certain apps only. | C5 (darkest greens) |
| **L5** | Backup; very rare. | Secondary warm/pink/earthy palette — magenta, gold/ochre, maroon, dusty rose, teal → mint gradient. **Brick** is rarer still — almost never used. |

### Design rules

- **Match colors by hue *and* lightness** across adjacent surfaces —
  blue ↔ blue, green ↔ green. Cross-hue jumps only via deliberate
  gradients (e.g. bright blue → bright green). Abrupt mismatches only
  happen incidentally between two simultaneously-open apps.
- The yellow / green / blue tile fills in the homescreen mockups are
  **placeholder differentiation only** and **do not map to the palette**.
  Actual default surfaces come from L1 (ultramarine / bright green /
  azure).
- **Shapes**: rounded rectangles throughout; window decorations rounded;
  panelv traffic-light controls rounded.

## What ships TODAY as placeholders (replace these in the design pass)

| File | Current placeholder | Target |
|------|---------------------|--------|
| `shared/includes/etc/calamares/branding/edemint/logo.svg` | "E" on a cyan→green gradient, square | The real logo SVG master |
| `shared/includes/etc/calamares/branding/edemint/show.qml` | One-slide "Installing Edemint…" stub | Real install slideshow |
| `shared/includes/boot/grub/themes/edemint/theme.txt` | Colors-only (no PNG assets), Edemint palette | Boot screen with real logo + wallpaper |
| `shared/includes/etc/skel/.config/hypr/hyprland.conf` | Gaps, border colors, anim curves are placeholder values | Tuned per the palette + design rules |
| `shared/includes/etc/skel/.config/hypr/hyprlock.conf` | Lock-screen colors / fonts placeholders | Per the `login_screen` prototype |
| `shared/includes/etc/skel/.config/waybar/style.css` | Placeholder Waybar styling | Per the palette + glyph icons from the icon theme |
| `shared/includes/usr/share/applications/install-edemint.desktop` | `Icon=calamares` (generic) | Edemint launcher icon |

## How to do the design pass

When the design pass starts:

1. **Drop the prototype files** under `docs/prototypes/` (PNGs or SVGs as
   the user provided them) — keeps the brief and the source images
   together.
2. **Lock the palette numerically** — turn C1–C8 into concrete hex codes
   in `docs/PALETTE.md`; export them to `shared/includes/etc/skel/
   .config/hypr/profile.conf` as Hyprland color variables.
3. **Replace `logo.svg` first** — every other surface (Calamares, GRUB,
   Plymouth, greetd, fastfetch) consumes it. The placeholder lives at
   the same path so swapping is a single-file edit.
4. **Build a cursor theme** (Xcursor format) under
   `shared/includes/usr/share/icons/Edemint/cursors/`.
5. **Build an icon theme** under `shared/includes/usr/share/icons/Edemint/`
   with the standard FreeDesktop category tree.
6. **Wallpaper(s)** at common HiDPI resolutions under
   `shared/includes/usr/share/backgrounds/edemint/`; set the default via
   the swaybg `exec-once` in `hyprland.conf`.
7. **Plymouth theme** under `shared/includes/usr/share/plymouth/themes/
   edemint/`; register via `update-alternatives`.
8. **GRUB theme** assets land under `shared/includes/boot/grub/themes/
   edemint/`; the existing `theme.txt` references them.

Everything else (Waybar glyphs, OSD icons, notification icons, panelv
buttons, Calamares slideshow) consumes the cursor + icon themes by
reference, so they update automatically once those land.
