# Session handoff — Edemint

A handoff document for the next Claude Code instance (or any human) picking
up this work. Read this once, then trust the codebase and the commit log —
both are deliberately detailed.

## What Edemint is

A Wayland-first **Debian 13 (Trixie) remix** that ships:
- **amd64 live ISO** with Calamares installer (LUKS by default, btrfs root)
- **arm64 Raspberry Pi 4/5 image** via mmdebstrap + genimage

The desktop is **Hyprland** (wlroots). The product is 100% Debian — only the
build host (GitHub Actions runner) is Ubuntu.

Three intentional differentiators that no other distro ships together:
- **AR-glasses support layer** (kanshi + XR-driver IMU + udev scoped 0660)
- **AI assistant** (Claude/OpenAI/Gemini/ollama, off by default, cloud calls
  show as a red Waybar pill while in flight)
- **Reliability**: btrfs auto-snapshots on every apt run + `edemint-rollback`

## Communication style the user prefers

Tight, direct, honest. Match this exactly:
- **No emojis** except when the user uses them first.
- **Short paragraphs**, action lists when there are >2 things to do.
- **Lead with the diagnosis** in failure cases ("the actual error is X"),
  then the fix. Never speculate when you can read the code/log.
- **Honest about uncertainty** — say "I can't reach the archive from this
  sandbox, so I can't verify the exact name; here's the safe fix" rather
  than guessing and pretending.
- **No filler**: "let me…" / "I'll proceed to…" preambles are noise.
- **End-of-turn summary**: 1-2 sentences. What changed. What's next.
- **Code style**: explain WHY in comments, never WHAT. No "for future use"
  abstractions. POSIX sh, shellcheck-clean.

## Repo architecture (CRITICAL)

```
shared/                              single source of truth, EVERY target reads this
  package-lists/{base,desktop,ai,ar,installer}.list.chroot
  includes/                          configs baked into the image
  hooks/normal/*.hook.chroot         chroot-phase build hooks (numbered, alphabetical order)
profiles/
  amd64-iso/                         live-build profile
    auto/config                      `lb config` flags
    config/                          package-list symlinks + amd64-only extras
  arm64-pi/                          mmdebstrap + genimage pipeline
    build.sh                         orchestrator
    package-lists/pi.list.chroot     Pi-specific (raspi-firmware, etc.)
    includes/                        Pi-only systemd units (firstboot growfs)
    boot/{config.txt,cmdline.txt}    Pi firmware config
    genimage.cfg                     FAT firmware + ext4 root layout
packaging/                           equivs metapackages
  build-metapackages.sh              builds edemint-{base,desktop,ai} .debs
  edemint-{base,desktop,ai}/control  templates with @DEPS@ marker
scripts/
  tier-a-lint.sh                     CI lint (shellcheck, nft, invariants)
  test-repo-signing.sh               signed-Release tamper self-test
build.sh                             top-level dispatcher: amd64 / pi / clean
Makefile                             friendly wrapper: iso, pi, lint, sign-test
.github/workflows/build.yml          CI: lint → iso → pi → publish (tag-gated)
```

## The "Ubuntu live-build is older than Debian Trixie" pattern

This is the single most important debugging pattern. Internalise it.

GitHub Actions runners are Ubuntu. Ubuntu packages `live-build` at a version
that **rejects modern flags** Debian's documentation says exist. Three flags
we've already lost to this:
- `--updates`, `--backports` → "unrecognized option" hard error
- `--debootstrap-options` → "unrecognized option" hard error
- `--security` → DOES work (kept)

**The fix template** (use this any time `lb config` rejects a flag):

1. Remove the failing flag from `profiles/amd64-iso/auto/config`.
2. In `build.sh`'s amd64 path, AFTER `lb config` runs, sed the underlying
   `LB_*` variable directly into `config/{bootstrap,chroot,binary}`.
3. Set BOTH the newer and older variable names where they differ:
   - newer: `LB_BOOTSTRAP_INCLUDES`
   - older: `LB_DEBOOTSTRAP_OPTIONS="--include=foo,bar,baz"`

We already do this for `LB_SECURITY=false`, `LB_BOOTSTRAP_INCLUDES`, and
`LB_DEBOOTSTRAP_OPTIONS`. Pattern proven — extend it for the next gap.

## The "package missing on this arch / not in Trixie" pattern

When `lb_chroot_install_packages` or mmdebstrap aborts on a missing package,
the fix depends on WHY:

| Reason | Fix |
|---|---|
| **x86-only** (microcode, Intel VA-API, etc.) | Move to `profiles/amd64-iso/config/package-lists/amd64-firmware.list.chroot`. Pi never reads that path. |
| **Wrong name** | Look up the actual Debian package name. `qt5-wayland` → `qtwayland5`. The error log names it; don't guess. |
| **Genuinely not in Trixie main / arm64 main** | Move to `shared/hooks/normal/0050-extra-desktop.hook.chroot` (best-effort: missing = log "SKIPPED" and continue, never abort the build). |
| **Not in Debian at all** (ollama, whisper-cpp, hyprshot) | Same best-effort hook. Document in the EXTRAS list comment. |

## Tier A invariants (lint script)

`scripts/tier-a-lint.sh` asserts security properties on EVERY push. If you
add a security-relevant feature, add a check. Current invariants:

- XR udev rule is `0660` + `edemint-ar` group (NOT 0666)
- `edemint-ai` config.toml ships `enabled = false`
- The local-only refusal text is in `edemint-ai`
- `call_claude` / `call_openai` / `call_gemini` each contain
  `cloud_lock_acquire` AND `cloud_lock_release` (privacy meter integrity)
- Calamares finalize includes `passwd -l root`
- Calamares users module does NOT set `setRootPassword: true`
- apt pre-snapshot hook is present
- All `edemint-*` user-facing helpers are executable

`nft -c` runs in a `unshare -rn` user namespace when not root (CI runs the
lint as the unprivileged `runner` user).

## CI fix history (every commit on this branch)

Read commit messages with `git log --format=full`. They're written for you.
Short summary in chronological order:

| Commit | Issue | Fix |
|---|---|---|
| `d5dfcf2` | scaffold restructure | shared/ + profiles/ + build.sh dispatcher |
| `8ba7fe3` | complete OS package set | base + desktop + configs |
| `7a1560f` | reproducibility | equivs metapackages |
| `28ce5a3` | installer | Calamares + Secure Boot |
| `82d86b1` | arm64 target | mmdebstrap+genimage Pi pipeline |
| `0e6acb7` | AR layer | XR driver hook, udev, status helper |
| `113e637` | AI layer | helper with 4 backends, off by default |
| `ff119f9` | CI | workflow, Tier A lint, sign-test |
| `d008de8` | bug pass | CUPS sed, mmdebstrap copy-in→sync-in, etc. |
| `c78df81` | optimizations | swappiness, BBR, initramfs, tmpfs /tmp |
| `6eac00a` | polish | libnotify-bin, locale.nopurge, snapper init |
| `cc44a97` | mega features | rollback, AI privacy meter, sync, setup |
| `56da2a3` | easy wins | gaming mode, ?ai, wf-recorder, LUKS default, DoT |
| `a47b389` | reboot+battery+grub | Waybar reboot click, battery cap, GRUB theme |
| `061e2ea` | URLs | replace example.invalid with real github.com URLs |
| `f94bb66` | CI lint | nft -c needs user namespace as non-root |
| `619a60d` | bleeding-edge resilience | best-effort extras hook |
| `51206b9` | CI bootstrap | install debian-archive-keyring on Ubuntu |
| `07270a7` | live-build security | --security false (and LB_SECURITY override) |
| `5928b14` | belt-and-suspenders | force LB_SECURITY in config/chroot |
| `7ce5ac4` | per-arch fixes | drop --updates, x86-only packages out, qt5→qtwayland5 |
| `4d1cbf0` | gpg in chroot | --debootstrap-options + LB_BOOTSTRAP_INCLUDES |
| `fb62aec` | Pi sync-in target | pre-mkdir /var/cache/edemint + /usr/local/share/edemint-hooks |
| `a792bb0` | --debootstrap-options rejected | drop from auto/config, force via build.sh |

## CURRENT STATE (when this doc was written)

- **Lint job**: ✅ passing (since `f94bb66`).
- **ISO job**: pending verification after `a792bb0`. Was failing at
  `env: 'gpg': No such file or directory` (exit 127). The fix forces
  `LB_BOOTSTRAP_INCLUDES` + `LB_DEBOOTSTRAP_OPTIONS` for gnupg + ca-certs.
- **Pi job**: pending verification after `fb62aec`. Was failing at first
  `sync-in /var/cache/edemint` because target dir didn't exist; fixed
  with pre-mkdir hook. Full 50-min Pi build had previously cleared
  bootstrap and package install — it was 1 mkdir away from running
  hooks + genimage.
- **Publish job**: tag-gated only. EDEMINT_APT_PRIVATE_KEY secret not set
  yet — the job no-ops cleanly when absent.

## Known placeholders (intentional, time-bounded)

| Where | What | When to fix |
|---|---|---|
| `shared/hooks/normal/0200-xr-driver.hook.chroot:20` | `XR_SHA256="PLACEHOLDER-..."` | Each release: pin an XRLinuxDriver tag, fetch tarball, compute SHA-256, bump both in one commit. |
| `shared/includes/etc/apt/sources.list.d/edemint.sources` | `Enabled: no`, URL `ashcqriss.github.io/edemint/debian` | When the apt repo is published via CI gh-pages. Until then: harmless. |
| `/etc/apt/keyrings/edemint-archive-keyring.gpg` (in branding hook) | empty file | When the apt repo is published — CI's publish job populates the public key. |
| Calamares branding `logo.svg`, `show.qml` | placeholder visuals | Explicitly deferred "design pass" — see plan §10. |
| Hyprland config gaps/colors/anim curves | placeholder values | Same design pass. |

## How to debug a new CI failure

1. **Read the failing step in the workflow log.** The actual error is
   usually in the last 30 lines. apt errors are clearest; live-build's
   own diagnostics often misleadingly point at the previous step.
2. **Categorise**: tooling-version mismatch (use the `LB_*` override
   pattern), package mismatch (use the moved/renamed/best-effort
   pattern), permission (CI runs non-root unless explicitly `sudo`),
   path doesn't exist (pre-mkdir).
3. **Reproduce locally** if the sandbox allows. As `root` in this
   container we hit different paths than CI's `runner` user; switch to
   a non-root user with `setpriv --reuid=ciuser ...` to find privilege
   bugs (the `nft -c` fix came from this).
4. **Tier A FIRST**: `make lint && make sign-test` must stay green
   through every change. The invariants in `scripts/tier-a-lint.sh`
   are the safety net.
5. **Commit with a detailed message** explaining the root cause AND
   the fix. The commit log is the project's incident log; future-you
   reads it.

## Sandbox limitations the user should know about

When working in this Claude Code container:
- **Network is restricted**: deb.debian.org, packages.debian.org,
  GitHub API → all 403. ftp-master.debian.org may also be blocked.
- **Can't reach CI logs via API** — must wait for the user to paste them.
- **`/tmp` is locked down**: `TMPDIR=/tmp/claude-0` is root-owned, which
  broke `equivs-build` (fixed by overriding TMPDIR per-invocation).
- **Cannot actually build the ISO/Pi image here** — needs root + loop
  devices + native qemu-user-static + ~10GB free.

This means: many fixes must be made by READING and REASONING about the
code rather than testing the actual build. Trust the patterns, test
what you CAN test (lint, shellcheck, syntax), commit, push, wait for
user's CI log.

## Files the next instance should read first

1. `README.md` — what Edemint is
2. `CHANGELOG.md` — what's shipped
3. This file
4. `shared/hooks/normal/0100-branding.hook.chroot` — central state
5. `build.sh` — entry point, contains the LB_* override patterns
6. `profiles/arm64-pi/build.sh` — mmdebstrap orchestration
7. `scripts/tier-a-lint.sh` — invariants
8. `.github/workflows/build.yml` — CI structure
9. Most recent 5 commits via `git log --format=full -5`

## On "as good as you" — the honest framing

A successor instance that reads this + walks the repo will match my
output ~95%. What's harder to transfer:
- **The accumulated context** of which fix to try first (covered above
  with patterns).
- **The user's preference for tight, action-oriented prose** (covered
  in "Communication style").
- **Knowing what's load-bearing vs decoration** (covered in commit
  messages + this doc).

What IS preserved perfectly:
- Every line of code.
- Every commit message (read with `git log --format=full`).
- The Tier A invariants — they assert the contracts.
- This handoff.

If the next instance follows the patterns and reads the commit log,
they'll converge on the same quality within their first 2-3 messages.
