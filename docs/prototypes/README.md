# UI prototypes

The original design references described by `docs/DESIGN.md` were supplied on 2026-06-06. All eight originals are 2940x1912 progressive JPEG files.

The binary originals remain untouched in the user's source folder. This manifest records their canonical project names and SHA-256 identities so later imports can be verified byte-for-byte.

| Canonical name | Original filename | SHA-256 |
|---|---|---|
| `color_palette.jpg` | `color_palette copy.jpg` | `cbd0fcffe6c843734ac012ab8af8290b11e985a2a92028a1f167955739f9ee83` |
| `login_screen.jpg` | `login_screen copy.jpg` | `89654bda3a7ab4eb607585c393e98336aff76033a67684ba04e1bf0d543e4d56` |
| `dock.jpg` | `dock copy.jpg` | `2aeb919d3ca1da5fdd9e6486101bcbd453645b92d017f96383fc71fe3539dc99` |
| `main_homescreen.jpg` | `main_homesccreen copy.jpg` | `5388f7c830c2e4e60654548c68fbd3a81bc737aad6c6a3de4b237d1879b56253` |
| `mobile_dock_ratio_2.jpg` | `mobile_dock_ratio_2 copy.jpg` | `2f3b818c1f8c01cf78300b267a15060d509ff48593f2f40ac04e7a825f87ecfd` |
| `mobile_ratio.jpg` | `mobilratioqo copy.jpg` | `742b77572705f2906073207f73314b3f91ed2ec3743b6a7994cffa565d45a7ae` |
| `on_off2.jpg` | `on_off2 copy.jpg` | `67861b9b5d68925c6ee9e095a9a2cfab3f654ce7b62b11f72637a93d555894ed` |
| `panelv.jpg` | `panelv copy.jpg` | `34789f874e7c07c1075768263f1619db7492f874a0034c875b587a3cc166090f` |

## Interpretation

- `color_palette`: authoritative color families. Numeric values are recorded in `docs/PALETTE.md`.
- `login_screen`: top date/time region, centered circular profile image, username field, and optional narrower password field.
- `dock`: left-side dock with four overlapping translucent bars and a large content/workspace region.
- `main_homescreen`: persistent left application dock and top-right date/time/status region.
- `mobile_dock_ratio_2`: portrait widget/app composition with a bottom expandable application component.
- `mobile_ratio`: portrait homescreen with centered application grid, top status region, left rail, and bottom page indicator.
- `on_off2`: power motif and expandable power-state control concept.
- `panelv`: expand, minimize, and close controls. Green means expand, yellow means minimize, red means close.

## Source versus placeholder

The geometry, hierarchy, placement, and interaction roles are authoritative design inputs. Flat yellow, pink, gold, red, and green fills in the layout sketches are mostly differentiation placeholders. The palette image and the explicit `panelv` exception determine real product colors.

The prototypes are blueprints, not production-ready raster assets. Final implementation should use SVG, CSS/QML, icon-theme assets, and compositor configuration so it remains sharp across desktop, mobile, HiDPI, and AR displays.
