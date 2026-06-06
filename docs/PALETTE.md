# Edemint palette

This file records colors measured from the original JPEG design references supplied on 2026-06-06. JPEG compression creates small edge variations; the values below are sampled from the centers of the solid source blocks.

The palette image is the color authority. Yellow, pink, gold, and red blocks in the layout mockups remain functional placeholders unless explicitly listed as semantic exceptions.

## Primary families

### C1 - ultramarine

| Token | Hex |
|---|---|
| `ultramarine-500` | `#2001FF` |
| `ultramarine-400` | `#6D58FF` |
| `ultramarine-200` | `#AEA3FF` |

### C2 / C8b - deep indigo

The unlabelled source image makes the C2 versus C8b naming ambiguous. Keep these together until the final palette review.

| Token | Hex |
|---|---|
| `indigo-900` | `#261B67` |
| `indigo-800` | `#2C2656` |

### C3 - eco green

| Token | Hex |
|---|---|
| `eco-400` | `#45E289` |
| `eco-300` | `#88D0A8` |
| `eco-200` | `#819C8D` |

### C4 / C5 - forest and dark green

| Token | Hex |
|---|---|
| `forest-950` | `#093A02` |
| `forest-900` | `#0D6300` |
| `forest-700` | `#21920F` |
| `forest-ink` | `#162D13` |
| `forest-charcoal` | `#242E23` |
| `forest-deep` | `#253C22` |
| `forest-muted` | `#2C5126` |

### C6 - navy

| Token | Hex |
|---|---|
| `navy-700` | `#002C89` |
| `navy-950` | `#171E54` |

### C7 - turquoise

| Token | Hex |
|---|---|
| `turquoise-200` | `#74FBEA` |
| `turquoise-300` | `#1EE5CE` |
| `turquoise-500` | `#04A89D` |
| `turquoise-700` | `#007C76` |

### C8a - azure

| Token | Hex |
|---|---|
| `electric-blue` | `#0007FF` |
| `azure-500` | `#0080FF` |

## Secondary reference colors

These appear in supporting mockups and should be used sparingly.

| Token | Hex | Intended role |
|---|---|---|
| `magenta` | `#FF00C8` | Rare emphasis and prototype annotations |
| `gold` | `#B67E29` | Warm secondary surface |
| `maroon` | `#750303` | Warm dark surface |
| `warm-red` | `#B32B2B` | Warm secondary surface |
| `dusty-rose` | `#A45455` | Warm muted surface |
| `teal` | `#00816D` | Mobile surface reference |

## Confirmed semantic exceptions

The `panelv` prototype defines window controls independently of the main palette:

| Action | Hex |
|---|---|
| Expand / fullscreen | `#5BA453` |
| Hide / minimize | `#E9DE51` |
| Close | `#E31515` |

The `on_off2` prototype uses `#F4D956` with `#3F136A`. These are motif references, not general UI defaults.

## Provisional UI tokens

These map the measured palette into implementation roles. They must pass WCAG contrast checks before becoming final.

```css
--ed-background: #162D13;
--ed-surface: #253C22;
--ed-surface-raised: #2C5126;
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

## Rules

- Match adjacent surfaces by both hue and lightness.
- Prefer L1 colors: ultramarine, eco green, and azure.
- Use turquoise as supporting emphasis.
- Use warm colors rarely and deliberately.
- Do not treat the yellow, pink, and gold placeholder blocks in layout mockups as default product colors.
- Never encode state by color alone; controls need shape, icon, or text reinforcement.
