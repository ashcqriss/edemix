# Claude Instance 2 — Error-Fix & Optimization Handoff

This document is written by Claude Instance 2 (the error-fix instance, spawned from
the original Instance 1 at >800k context) to itself and to Instance 1.
Read it cold — it assumes you have not seen the conversation that produced it.

## What the two-instance split is

- **Instance 1** (the original session): Holds the full design history, the user's
  architectural decisions, and the "why" behind every feature. Continues new feature
  work. Has >800k context — slower, but complete.
- **Instance 2** (this session, and the one that will continue it): Starts fresh from
  the codebase + SESSION_HANDOFF.md. Handles build errors, CI failures, and small
  optimizations quickly because it is not dragging 800k tokens through every call.

**Neither instance is more important.** Instance 1 builds features; Instance 2 keeps
the build green and cleans up behind it. They converge on the same codebase via git.

## Branch model (READ THIS — prevents "failed copies")

Two long-lived branches, both descended from the same base commit `4ac3192`:

| Branch | Owner | Role | Who writes |
|---|---|---|---|
| `claude/pensive-pasteur-YEzPq` | Instance 1 | Feature branch — new capabilities | **Instance 1 only** |
| `claude/nice-volta-bkx1i` | Instance 2 | **Canonical "runs-clean" branch** = pensive-pasteur's core + Instance 2's fixes | **Instance 2 only** |

Rules that keep the project from breaking on a bad copy:

1. **Instance 2 never writes to pensive-pasteur.** Instance 1 never writes to
   nice-volta. Each instance owns exactly one branch.
2. **There is no hand-copying.** Both branches share git history from `4ac3192`, so
   the core is *byte-identical* by construction — not a duplicated copy that can rot.
   Verify any time with:
   `git diff --diff-filter=D --name-only origin/claude/pensive-pasteur-YEzPq origin/claude/nice-volta-bkx1i`
   — it must print **nothing** (zero files missing on nice-volta).
3. **nice-volta is the branch where everything runs.** CI (`.github/workflows/build.yml`
   triggers on `claude/**`) runs lint→iso→pi on it automatically; it is the strict
   superset (full core + fixes), so it is the safe branch to build/release from.
4. **Keeping them in sync over time:** when Instance 1 pushes features to
   pensive-pasteur, Instance 2 merges them forward into nice-volta
   (`git merge origin/claude/pensive-pasteur-YEzPq`) and re-runs `make lint &&
   make sign-test`. Because they share `4ac3192`, merges are clean (no rebase needed).
   This is the ONE maintenance action that keeps "nice-volta = pensive-pasteur core +
   fixes" true. Do it at the start of every Instance-2 session.

As of this writing the two are in sync: pensive-pasteur HEAD is exactly `4ac3192`
(no features pushed yet), and nice-volta = `4ac3192` + the fix commits below.

## Session 2 scope (what was done in the first run)

All changes are on branch `claude/nice-volta-bkx1i`. Confirmed green: `make lint &&
make sign-test`. Nothing was committed yet — the user may want to review first.

### Bug 1 — `scripts/test-repo-signing.sh`: wrong `.deb` search path

**Root cause:** Commit `b2d3c1d` ("Stop using config/packages.chroot/") moved the
metapackage `.deb` output from `profiles/amd64-iso/config/packages.chroot/` to
`shared/includes/usr/share/edemint/metapackages/`, but the sign-test script still
pointed at the old path.

**Effect:** `make sign-test` exited 1 ("FAIL: still no .deb in … after build
attempt") on every run, breaking CI.

**Fix:** `scripts/test-repo-signing.sh` line 10:
```diff
-DEBS="$ROOT/profiles/amd64-iso/config/packages.chroot"
+DEBS="$ROOT/shared/includes/usr/share/edemint/metapackages"
```

### Bug 2 — `.github/workflows/build.yml`: same stale path in publish job

**Root cause:** Same as Bug 1 — the publish step's `cp *.deb` still referenced the
old path, so publishing would have found no `.deb` files.

**Fix:** `.github/workflows/build.yml` line 161:
```diff
-cp profiles/amd64-iso/config/packages.chroot/*.deb repo/pool/main/ || true
+cp shared/includes/usr/share/edemint/metapackages/*.deb repo/pool/main/ || true
```

### Bug 3 — `profiles/arm64-pi/genimage.cfg` + `build.sh`: FAT partition missing all firmware files

**Root cause:** The genimage.cfg `image boot.vfat {}` block explicitly listed only
two files (`config.txt`, `cmdline.txt`) via `file {}` entries. All other
raspi-firmware content (dtbs, start4.elf, fixup4.dat, overlays/, kernel image) was
missing from the FAT partition. A Pi image built by the old code would not boot.

**Additional sub-bug:** `build.sh` section 3 guarded config.txt/cmdline.txt copies
with `if [ ! -f ]`. Since `raspi-firmware` always installs its own versions, our
custom config (with `dtoverlay=vc4-kms-v3d`, Pi 5 tweaks, etc.) was silently
discarded.

**Fix approach:**
1. `build.sh`: always `cp -f` our config.txt/cmdline.txt (remove the guards).
2. `build.sh`: before calling genimage, loop-mount-create a complete `$TMP_DIR/boot.vfat`
   from `$ROOTFS_DIR/boot/firmware/` (all files via `cp -a`). genimage reads this
   pre-built image from `--inputpath "$TMP_DIR"` instead of building its own.
3. `genimage.cfg`: remove the `image boot.vfat { vfat { ... } }` block. genimage
   finds `boot.vfat` in `--inputpath` (our pre-built one) and uses it as-is.
4. `genimage.cfg`: add a clear comment explaining the pre-built FAT approach.

**Why loop-mount over mcopy:** mtools `mcopy -s . ::` has quoting/path edge cases
with recursive copies from a real rootfs. The build already runs as root (required
for mmdebstrap + genimage loop devices), so `mount -o loop` is reliable.

### Bug 4 — `profiles/arm64-pi/`: fixed 5G ext4 root overflows the desktop set

**Root cause:** `genimage.cfg` sized the root partition at a fixed `size = 5G`. The
populated rootfs (firmware-misc-nonfree ~1GB + Firefox + GNOME apps + fonts-noto +
ffmpeg/gstreamer + fcitx5-mozc + the full Hyprland userland) can exceed 5G, and
genimage's `mke2fs -d` aborts when the content overflows a fixed filesystem size.
This stage had **never run** — the Pi build historically died one `mkdir` before
genimage — so the limit was untested.

**Fix:** `build.sh` now `du -sk`s the real rootfs and templates the cfg to
`size = (rootfs × 1.30 + 512MiB, min 4G)` before calling genimage. `firstboot-growfs`
expands the partition to the card on first boot, so the shipped size only needs to
hold the content. The cfg keeps `size = 5G` as a self-documented placeholder.

### Bug 5 — `profiles/arm64-pi/`: genimage output name didn't track EDEMINT_VERSION

**Root cause:** `genimage.cfg` hardcoded `edemint-0.1-arm64-rpi.img`; `build.sh`
derives `IMG_NAME` from `$EDEMINT_VERSION` and `xz`-es that name. A versioned build
(`EDEMINT_VERSION=0.2`) would have genimage write `…0.1…` while `xz` looked for
`…0.2…` → fail. (No effect on the default 0.1 build, but it would break the first
tagged release.)

**Fix:** the same `sed` that injects the ext4 size also rewrites the image name to
`$IMG_NAME` (a no-op substitution at 0.1).

Both fixes are locked in by new Tier A invariants (see `scripts/tier-a-lint.sh`):
build.sh must pre-build boot.vfat (`mkfs.vfat`) and dynamically size the root
(`ROOT_SIZE_MB`); genimage.cfg must not re-declare `boot.vfat`; neither the
sign-test nor the workflow may reference the dead `config/packages.chroot` path.

## How to continue as Instance 2 in the next session

1. Read `SESSION_HANDOFF.md` — that is the primary reference document written by
   Instance 1 with the full CI debug history and patterns.
2. Read this file (`claudeinstance2/INSTANCE2_HANDOFF.md`) for what Instance 2 has
   already done.
3. Read the git log: `git log --oneline -10`. The most recent commits are on
   `claude/nice-volta-bkx1i`.
4. Run `make lint && make sign-test` — must stay green before every push.
5. Check CI status at `https://github.com/ashcqriss/edemint/actions` (use the GitHub
   MCP tools if available, since `gh` CLI is absent in the web environment).

## Pi build speed (the qemu bottleneck)

The ~50-min Pi CI build is dominated by **qemu TCG emulation**: on an amd64
runner, every arm64 package postinst executes under emulation. The fixes:

- **`profiles/arm64-pi/build.sh` is arch-aware.** `HOST_ARCH=$(dpkg --print-architecture)`;
  on a native arm64 host it skips qemu-user-static entirely (mmdebstrap runs the
  arm64 chroot natively, ~4x faster). On amd64 it auto-installs qemu and cross-builds.
- **The workflow runner is configurable:** `runs-on: ${{ vars.PI_RUNNER || 'ubuntu-latest' }}`.
  Default = free amd64 cross-build (always works). Set repo variable
  `PI_RUNNER=ubuntu-24.04-arm` for the native fast path.
- **IMPORTANT — the repo is PRIVATE.** arm64 hosted runners are free only for *public*
  repos; on a private repo they need a **paid plan** and bill Actions minutes. That's
  why the default stays on the free amd64 runner rather than hardcoding arm64. To get
  the 4x win for free, the alternative is making the repo public.
- **Compression is now `zstd -T0 -12`** (was `xz -3`): the image is `*.img.zst`, packed
  in tens of seconds instead of minutes. Flash with `zstd -dc img.zst | dd …`.

**Next free speedup (needs Instance 1 sign-off — it's a design change, not a fix):**
the AR build toolchain (`build-essential`, `cmake`, `pkg-config`, the `lib*-dev` set
in `shared/package-lists/ar.list.chroot`) is installed on every image but the XR-driver
hook is skipped today (placeholder SHA), so those packages' postinsts are pure dead
weight under qemu AND ~250MB of image bloat. Moving the XR-driver build to first-boot
/ on-demand (so the toolchain isn't in the base image) would cut both build time and
image size — but it changes WHEN the AR driver compiles, which is Instance 1's call.

## Patterns to know (summarised from SESSION_HANDOFF.md)

| Problem | Fix |
|---|---|
| `lb config` rejects a flag | Remove from `auto/config`; force `LB_*` var in `build.sh` |
| Package missing on arm64 | Move to `profiles/amd64-iso/config/package-lists/amd64-firmware.list.chroot` |
| Package wrong name / not in Trixie | Move to `0050-extra-desktop.hook.chroot` (best-effort) |
| `.deb` path changes | Grep for both old + new paths across `scripts/`, `.github/workflows/`, `build.sh` |

## Known latent issues (not in scope for a fix-pass)

These are NOT CI failures right now but may surface:

- **`/etc/fstab` has no `/boot/firmware` entry:** the ext4 rootfs written by genimage
  also contains the firmware files as regular files (the mountpoint isn't excluded).
  On a real Pi the FAT partition is what's mounted at `/boot/firmware`, so the ext4
  copy is dormant — but no fstab entry mounts the FAT partition there yet. Add one
  when confirming on real hardware (Tier C); flash-kernel writes to `/boot/firmware`
  on updates and needs the real partition mounted.
- **Pi AI HAT+ / Hailo hook** (`0400-hailo.hook.chroot`): depends on the Raspberry Pi
  apt component being available. CI can't test this; Tier C only.
- **XR driver SHA placeholder**: `0200-xr-driver.hook.chroot` has `XR_SHA256=PLACEHOLDER`.
  The hook gracefully skips — intentional until a real XRLinuxDriver tag is pinned.

## Communication between instances

There is no live channel. Both instances push to the same branch. The coordination
mechanism is:
- This file (`claudeinstance2/INSTANCE2_HANDOFF.md`) — updated by Instance 2 after
  each fix session.
- `SESSION_HANDOFF.md` — maintained by Instance 1 after feature work.
- Git commit messages — the project's incident + feature log; always read the last
  5-10 commits on entry.

**Instance 1 instruction:** Before starting a new feature, run `make lint && make
sign-test` to confirm Instance 2's fixes landed cleanly. If the lint fails after a
feature push, that is the error-fix session's first job.

**Instance 2 instruction:** Do not add features. Fix what is broken. Add a Tier A
invariant for every security-relevant fix so regressions are caught automatically.
After each fix batch: commit with a detailed message (root cause + fix), push to
`claude/nice-volta-bkx1i`, and update this file.
