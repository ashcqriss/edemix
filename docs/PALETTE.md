# Edemint palette

This file records colors measured from the original JPEG reference supplied on
2026-06-06. JPEG compression creates small edge variations; values are sampled
from the centers of solid source blocks.

The palette image and the hierarchy in `DESIGN.md` are authoritative. An app or
component uses an appropriate subset; the entire palette is never required on
one surface.

## Diagram order

The original description names two complexes as "8th". `C8a` means the last
azure/ultramarine complex; `C8b` means the second-from-left dark-blue complex.

### C1 - first: ultramarine core

| Token | Hex |
|---|---|
| `ultramarine-500` | `#2001FF` |
| `ultramarine-400` | `#6D58FF` |
| `ultramarine-200` | `#AEA3FF` |

C1 is a level-1 family for the main dock, homescreens, system surfaces, and the
overall design language.

### C8b - second: rare dark blue / deep indigo

| Token | Hex |
|---|---|
| `indigo-900` | `#261B67` |
| `indigo-800` | `#2C2656` |

Despite its position near the start of the diagram, C8b belongs to the last
importance level. It is not a general shell background or common anchor.

### C3 - third: bright eco green

| Token | Hex |
|---|---|
| `eco-400` | `#45E289` |
| `eco-300` | `#88D0A8` |
| `eco-200` | `#819C8D` |

C3 provides secondary component accents and bright blue-to-green transitions.
It may be visually prominent without appearing on every OS layer.

### C4 - fourth: dark plant green

| Token | Hex |
|---|---|
| `plant-700` | `#21920F` |
| `plant-900` | `#0D6300` |
| `plant-950` | `#093A02` |

C4 is anchored secondary support and is structurally more important than the
bright-green component family.

### C5 - fifth: darkest green

| Token | Hex |
|---|---|
| `forest-ink` | `#162D13` |
| `forest-charcoal` | `#242E23` |
| `forest-deep` | `#253C22` |
| `forest-muted` | `#2C5126` |

C5 is rare and application-specific. It must not dominate the default shell.

### C6 - sixth: navy anchor

| Token | Hex |
|---|---|
| `navy-700` | `#002C89` |
| `navy-950` | `#171E54` |

C6 is the smallest complex and a level-2 anchored support family.

### C7 - seventh: turquoise support

| Token | Hex |
|---|---|
| `turquoise-200` | `#74FBEA` |
| `turquoise-300` | `#1EE5CE` |
| `turquoise-500` | `#04A89D` |
| `turquoise-700` | `#007C76` |

C7 is a level-3 supporter for selected components and transitions.

### C8a - last: azure and ultramarine core

| Token | Hex |
|---|---|
| `electric-blue` | `#0007FF` |
| `azure-500` | `#0080FF` |

C8a is a level-1 family directly integrated into the UI and design language.

## Secondary reference colors

These are level-5 or special-purpose colors unless a component explicitly
assigns them a semantic role.

| Token | Hex | Intended role |
|---|---|---|
| `magenta` | `#FF00C8` | Rare emphasis and prototype annotations |
| `gold` | `#B67E29` | Warm secondary surface |
| `maroon` | `#750303` | Warm dark surface |
| `warm-red` | `#B32B2B` | Warm secondary surface |
| `dusty-rose` | `#A45455` | Warm muted surface |
| `teal` | `#00816D` | Selected mobile/component reference |

## Confirmed semantic exceptions

`panelv` defines its controls independently of the general hierarchy:

| Action | Hex |
|---|---|
| Expand / fullscreen | `#5BA453` |
| Hide / minimize | `#E9DE51` |
| Close | `#E31515` |

`on_off2` uses `#F4D956` with `#3F136A` as a power-control motif. These are not
general shell defaults.

## Provisional first-build UI tokens

These tokens express the blue-led hierarchy while keeping the first UI readable
before final icons, wallpapers, and component artwork exist.

```css
--ed-background: #171E54;
--ed-surface: #002C89;
--ed-surface-raised: #2001FF;
--ed-primary: #2001FF;
--ed-primary-soft: #6D58FF;
--ed-accent: #45E289;
--ed-accent-cool: #0080FF;
--ed-focus: #74FBEA;
--ed-text-on-dark: #FFFFFF;
--ed-success: #5BA453;
--ed-warning: #E9DE51;
--ed-danger: #E31515;
```

These are implementation defaults, not a declaration that every app must use
the same blue surface. Final component combinations still require contrast and
visual testing.

## Light and dark surface roles

Backgrounds must work in both light and dark mode. The first build ships the
dark set; the light values are the approved counterparts for the later theme
work. Both columns use flat fills — gradients are forbidden by default.

| Role | Dark | Light |
|---|---|---|
| background | `#171E54` | `#FFFFFF` |
| surface | `#002C89` | `#AEA3FF` |
| raised / selection | `#2001FF` | `#2001FF` |
| text | `#FFFFFF` | `#171E54` |
| focus ring | `#74FBEA` | `#2001FF` |

The turquoise focus ring is a dark-mode color only: it is nearly invisible on
white, so light mode focuses with ultramarine instead. Semantic colors
(success, warning, danger) are shared across both modes.

## Rules

- Lead with C1 and C8a for the system, dock, and homescreens.
- Use C6 navy as a common anchor and C4 plant green as secondary support.
- Use C3 and C7 selectively for components, accents, and controlled stepped
  transitions. Gradients are forbidden by default; a component may use one
  only with explicit approval in its brief.
- Reserve C5, C8b, and warm colors for rare/application-specific uses.
- Match neighboring colors by hue and lightness whenever possible.
- Every background role has a light and a dark variant; components must stay
  readable on both.
- Do not treat yellow, pink, gold, red, or green prototype blocks as defaults
  unless their component description explicitly assigns that meaning.
- Never encode state by color alone; retain shape, symbol, or text.
