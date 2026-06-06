# Edemint design reference

This document is the authoritative brief for the first Edemint UI build. The
attached images define an approximate visual direction, component placement,
interaction roles, and palette hierarchy. They are prototypes rather than
finished UI assets.

## Build order

1. Build and stabilize the operating-system base: boot, installation, login,
   session startup, hardware support, packages, updates, recovery, and images.
2. Apply the first approximate UI using the geometry and color rules here.
3. Build the complete UI complexes, responsive/mobile behavior, final icons,
   cursor theme, window controls, widgets, and artwork.
4. Add animations after the static components and interactions work.

The UI must not delay or disguise unfinished base-system work. Conversely, base
placeholders must not be mistaken for final Edemint design.

**No final logo exists yet.** The SVG at
`shared/includes/etc/calamares/branding/edemint/logo.svg` is only a placeholder.
The supplied prototypes do not define a finished logo, icon theme, cursor
family, wallpaper, font system, or profile image.

The original JPEG identities are recorded in `docs/prototypes/README.md` and
their measured colors in `docs/PALETTE.md`.

## Prototype files and functions

Prototype colors such as flat yellow and pink frequently identify component
roles; they do not automatically become production colors. The separate
palette image controls the real UI colors, except for explicitly confirmed
semantic colors such as `panelv`.

| Prototype | Authoritative meaning |
|---|---|
| `main_homescreen` | Advanced, basic, and default desktop homescreen. The left vertical dock stores important/pinned apps. The lower pill opens an expandable all-apps search/completer. The right pink line represents date, time, connections, frequencies, and status. App boxes are rounded placeholders and must be smaller than shown. |
| `dock` | Appears when the user taps/clicks empty space where no other process owns the action. The app boxes are placeholders. The left visual consists of four semi-transparent overlapping lines; the neighboring app symbolics are gray, black, white, and pink in the sketch. |
| `panelv` | Window action symbols and their behavior. Green expands or enters fullscreen, yellow hides/minimizes, and red closes the window. These semantics override macOS-style ordering or assumptions. |
| `mobileratioqo` | Mobile homescreen and reference for the default narrow-screen aspect. It is predominantly blue, with partially shown centered app icons. The bottom line indicates the active app page. The upper-left line carries time, date, and status updates. Icons remain placeholders. |
| `mobile_dock_ratio_2` | Prototype for a 1080x1920/mobile view, including the rotated interpretation where its sidebar appears on the left. Yellow blocks represent widgets, which are available on every homescreen even though previewed only here. The lower neon-pink pill is the expandable app component; the upper pink square represents date, time, and status. |
| `login_screen` | Center circle is the profile picture. The username is shown in the rectangle below it; an optional password/code field is half that width and only appears when authentication is enabled. The upper box always shows date and time, including while locked. |
| `on_off2` | Keyboard-oriented power symbol, composed from the yellow circle and second component. It expands to power on, turn off, or standby choices. |
| `color_palette` | Color-family and hierarchy authority for all prototypes. Individual apps may use subsets; the full palette is not applied to every component simultaneously. |

Animations are deferred for every prototype and component above.

## Color complexes

The palette diagram is read left to right. The original naming contains two
"8th" references, so this document uses `C8a` and `C8b` to keep them distinct.

| ID | Position | Family | Count | Role |
|---|---:|---|---:|---|
| C1 | first | bright ultramarine / neon-like blues | 3 | Core dock, system, homescreens, and design language. |
| C8b | second | dark blue / deep indigo | 2 shown | Extremely rare, last-level support. Do not treat it as a common default. |
| C3 | third | bright eco greens, including a pastel | 3 | Secondary component colors and bright transitions; not every OS layer. |
| C4 | fourth | dark green / plant accents | varies | Secondary but more structurally important than C3; useful as anchored support. |
| C5 | fifth | darkest greens | 4 | Rare and application-specific. |
| C6 | sixth | navy gradient | 2 | Smallest complex; second-level anchored design color. |
| C7 | seventh | neon blue-green / turquoise | 4 | Third-level supporting family. |
| C8a | last | azure + ultramarine | 2 | Core UI and design-language colors. |

## Importance pyramid

| Tier | Use | Families |
|---|---|---|
| **L1** | Deeply integrated into the UI, main dock, system, and homescreens. Bright colors lead the design. | C1 ultramarine and C8a azure/ultramarine. C3 light green may participate prominently in matching gradients and component accents, but should not flood every layer. |
| **L2** | Common anchored support across screens, functions, and applications. | C6 navy and C4 dark plant greens. |
| **L3** | Supporting colors for selected components and applications. | C7 turquoise / green-blue and most C3 eco-green component use. |
| **L4** | Rare application-specific support. | C5 darkest greens. |
| **L5** | Backup colors used only in particular functions or views. | C8b dark blue/deep indigo and the secondary warm/pink/earth palette. Brick is rarer still. |

## Color behavior

- Match adjacent surfaces by both hue and lightness: blue beside blue, green
  beside green, and bright beside bright where possible.
- Cross-family movement should use a deliberate transition or gradient, such as
  bright blue to bright green, rather than an abrupt jump.
- Two simultaneously open applications may create an unavoidable mismatch;
  that does not redefine the internal palette of either app.
- An application consumes only the subset appropriate to its function. Browser,
  music, settings, and system components do not each display the whole palette.
- Flat yellow, pink, gold, red, and green prototype fills are role markers
  unless this brief explicitly assigns them semantic meaning.
- Rounded rectangles are the default shape language. App placeholders in the
  sketches are larger than the eventual production icons.
- State must not be communicated by color alone; retain symbols, shape, or text.

## Source deliverables

1. **Logo SVG master** for Plymouth, greeter, Calamares, GRUB, and About views.
2. **Cursor theme** covering pointer, text, hand, move, wait, forbidden, resize,
   grab, crosshair, and help at multiple HiDPI sizes.
3. **Icon theme** covering apps, folders, MIME types, status, and actions with
   symbolic variants.
4. **Wallpapers and fonts** for desktop/mobile resolutions, UI text, monospace,
   and required icon glyphs.

## Derived targets

- GRUB and Raspberry Pi firmware splash assets
- Plymouth, greetd, and Calamares branding
- Waybar, OSD, notification, and status glyphs
- `panelv` window controls
- Wallpaper and responsive desktop/mobile shell assets
- Logo exports, favicon, fastfetch, website, and social artwork

## Current phase boundaries

The first UI pass may establish palette variables, rounded geometry, readable
text placeholders, a left dock, status region, lock hierarchy, and power-menu
behavior. It must not claim the following are finished:

- final logo, profile picture, icon theme, cursor theme, wallpaper, or fonts
- the tap-in-void `dock` overlay and its four translucent overlapping lines
- complete widgets and mobile/rotated layouts
- production `panelv` decorations across GTK and Qt applications
- animations or final motion curves

See `docs/DESIGN_IMPLEMENTATION.md` for the exact implementation state.
