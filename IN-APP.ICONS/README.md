# IN-APP.ICONS

Suggestions for the in-app glyphs the first-party apps currently take from
the themed freedesktop set. Each row is a place where a dedicated Edemint
glyph would replace the fallback without code changes (the apps reference
icon names, not files).

| App | Usage | Current fallback name | Suggested Edemint glyph |
|---|---|---|---|
| Settings | Overview page | `computer-symbolic` | rounded monitor with ultramarine screen glow |
| Settings | Connections | `network-wireless-signal-excellent-symbolic` | three nested arcs, turquoise tip |
| Settings | Sound | `audio-volume-high-symbolic` | speaker with liquid ripple waves |
| Settings | Display | `video-display-symbolic` | display with hydroganic top light |
| Settings | Power | `battery-good-symbolic` | leaf-shaped battery (plant support color) |
| Settings | Notifications | `dialog-information-symbolic` | droplet-shaped bell |
| Settings | Privacy | `security-high-symbolic` | shield with frost texture |
| Settings | Accounts | `system-users-symbolic` | two rounded profiles |
| Settings | Language and Region | `preferences-desktop-locale-symbolic` | globe with meridian ripple |
| Settings | Accessibility | `preferences-desktop-accessibility-symbolic` | open figure in a rounded ring |
| Settings | Updates | `software-update-available-symbolic` | sprout arrow (growth = update) |
| Settings | Default Applications | `emblem-default-symbolic` | check inside rounded square |
| Settings | Storage | `drive-harddisk-symbolic` | rounded disk with water level |
| Settings | Backup | `document-save-symbolic` | folded leaf over box |
| Settings | Recovery | `edit-undo-symbolic` | counter-clockwise droplet arrow |
| Settings | Security | `dialog-password-symbolic` | key with organic bow |
| Settings | Sidebar toggle | `sidebar-show-symbolic` | split-pane glyph |
| Fullcall | Attach | `mail-attachment-symbolic` | vine paperclip |
| Fullcall / Phone | Clear / cancel mode | `edit-clear-symbolic` | dissolving droplet cross |
| App Library | Open app | `media-playback-start-symbolic` | rounded play droplet |
| App Library | Add to folder | `folder-new-symbolic` | folder with plus leaf |
| App Library / Shortcuts | Create shortcut | `list-add-symbolic` | plus inside rounded square |
| Shortcuts | Move up / down | `go-up-symbolic` / `go-down-symbolic` | soft chevrons |
| Shortcuts | Remove | `user-trash-symbolic` | rounded bin with wave lid |
| Sticky Notes | Note color identity | in-app color dots | tilted mini sticky with curled corner |

General rules for the glyph set:

- Match the symbolic grid (16 px logical, 2 px stroke) so GTK recolors them.
- Keep silhouettes rounded; no sharp 90-degree outer corners.
- One accent maximum per glyph, taken from the app's palette subset.
