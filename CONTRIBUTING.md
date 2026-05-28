# Contributing to Edemint

Edemint is a thin distribution layer on top of Debian Trixie. Most
contributions land in one of a few places:

- **`shared/package-lists/*.list.chroot`** — which packages get installed.
- **`shared/includes/`** — config files baked into the image.
- **`shared/hooks/normal/*.hook.chroot`** — shell scripts run inside the
  chroot during image build.
- **`profiles/amd64-iso/` / `profiles/arm64-pi/`** — per-target build
  configuration.
- **`packaging/`** — the equivs metapackages.

## Quick start

1. Fork + branch from `main`.
2. Make your change.
3. Run `make lint` — Tier A static checks must pass (shellcheck on every
   hook + script, nft -c on the firewall, equivs build of all three
   metapackages, repo-signing tamper test, security invariants).
4. If you touched the build pipeline, push a tag to your fork and let
   CI build the ISO + Pi image; verify both artifacts exist.
5. Open a PR with a clear description of what changed and why.

## Style

- **Shell scripts**: POSIX sh when possible; shellcheck-clean.
- **Comments**: explain WHY, never WHAT. Don't write comments that just
  restate code.
- **Per-target additions**: belong under `profiles/<target>/`, never
  `shared/`. The dividing line is "does this apply to every Edemint
  image?" — if no, profile-specific.
- **Service enablement**: edit `shared/hooks/normal/0100-branding.hook.chroot`,
  not separate hooks per-service.
- **Defaults**: privacy-first. AI is disabled. Cloud calls show in
  Waybar. Snapshots happen automatically.

## Adding a package

1. Add the line to the appropriate list under `shared/package-lists/`.
2. If it needs config, drop it under `shared/includes/`.
3. If it needs a service enabled, add the `systemctl enable` line to
   `0100-branding.hook.chroot`.
4. Re-run `make lint`.

## Adding a profile (new arch / new variant)

1. Create `profiles/<name>/`.
2. Add `build.sh`, `package-lists/<name>.list.chroot`, and any
   `includes/` overlay.
3. Wire it into the top-level `build.sh` dispatcher.
4. Update `.github/workflows/build.yml` with a build job.

## Security-sensitive changes

Anything that touches: firewall rules, AppArmor, sudo, PAM, Calamares
finalize, the apt sources, the XR driver hook, the AI cloud lock —
needs explicit reasoning in the PR body. Tier A invariants will fail if
you break: XR udev mode 0660, AI default-disabled, root-locked,
local_only cloud refusal.

## What NOT to do

- Don't add comments narrating what the code does.
- Don't add "future-proofing" abstractions for cases that don't exist.
- Don't change defaults silently — call them out in the PR.
- Don't ship images with placeholders that the user has to fix
  themselves (the XR_SHA256 and `edemint.invalid` URLs are
  intentional, time-bounded exceptions documented in CHANGELOG).
