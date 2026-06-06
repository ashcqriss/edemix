# Edemint production remediation plan

Status: authoritative execution plan for turning the current repository and
prototype references into tested release artifacts.

Scope:

- `amd64` live/install ISO
- Raspberry Pi 4/5 `arm64` image
- Debian package and update path
- security, recovery, CI, documentation, and repository governance
- first-build UI and the later complete prototype-driven component system

The source repository `ashcqriss/edemint` remains read-only during this work.
All remediation occurs in `ashcqriss/edemix` until an explicit migration or
merge decision is approved.

## 1. Release policy

No artifact may be called production-ready because a build command completed.
A release exists only when the exact tagged artifacts pass the structural,
boot, installation, first-boot, security, update, recovery, UI, accessibility,
and hardware gates defined below.

The base operating system is the first dependency. Full UI components and
animations cannot become release blockers until the base boot/install/session
milestones pass, but UI work may proceed on a separate branch against a mocked
shell API.

## 2. Audited baseline

### Existing local artifacts

| Artifact | Size | SHA-256 | Read-only finding |
|---|---:|---|---|
| `binary.hybrid.iso` | about 1.4 GiB | `e7e8eb8103d18a3296b55bb07959f375ecd7272555bb44166740e20e1a5dd6f1` | Valid ISO-9660 structure with a BIOS boot catalog and internal checksums. No visible EFI tree was found. |
| `edemint-0.1-arm64-rpi.img.zst` | about 1.5 GiB | `efce152980f46c8789a224dbe96a94f3ab311411f1b5f78b306059e36e811221` | Recognized as Zstandard data. Integrity and partition inspection were not run locally because `zstd` is not installed and nothing may be downloaded to this computer. |

The ISO identifies itself internally as a Debian Trixie official snapshot built
on 2026-06-01. It predates the current `edemix/main` UI changes and therefore is
a baseline artifact, not proof of current source behavior.

### Verified defects and release risks

| ID | Priority | Finding | Evidence / impact |
|---|---|---|---|
| P0-01 | Blocker | Existing ISO has no Hyprland compositor. | `live/filesystem.packages` contains greetd, Waybar, Calamares, foot, and wofi, but not `hyprland`. greetd is configured to execute `Hyprland`, so the intended graphical session cannot start. |
| P0-02 | Blocker | Load-bearing desktop packages are installed best-effort. | `0050-extra-desktop.hook.chroot` skips unavailable packages and still succeeds. A release can therefore omit the compositor, locker, portal, or session tools. |
| P0-03 | Blocker | Pi boot filename contract is inconsistent. | `config.txt` requests `kernel=vmlinuz`; `seed-boot-firmware` writes `kernel8.img` and `kernel_2712.img`. The shipped firmware partition may not contain the requested kernel name. |
| P0-04 | Blocker | Pi has no account-provisioning path. | No repository code creates a usable Pi user or password. greetd and SSH are enabled, but the image has no confirmed non-root login path. |
| P0-05 | Blocker | ISO UEFI and Secure Boot claims are unproven. | The baseline ISO exposes `isolinux` but no visible `EFI/BOOT`, shim, or GRUB EFI files. Installed packages alone do not prove UEFI/Secure Boot bootability. |
| P0-06 | Blocker | Live-session access is unproven. | Shared greetd config has only a normal login session; no ISO-specific `initial_session` exists. Production must prove live autologin and passwordless installer elevation without weakening installed systems. |
| P0-07 | Blocker | Release apt repository job has no package transfer. | The publish job starts from a fresh checkout and copies generated `.deb` files that are neither committed nor downloaded from a prior artifact. `|| true` permits an empty repository. |
| P0-08 | Blocker | CI does not boot or install either image. | Current CI stops after lint, image creation, and artifact upload. It does not verify firmware contents, partition tables, users, systemd state, graphical session, Calamares, or first boot. |
| P0-09 | Blocker | Artifact/source traceability is missing. | Artifact names and `.disk/info` do not reliably identify the source commit, dependency snapshot, build workflow, or configuration version. |
| P1-01 | High | “Full effects” selection is a no-op. | `edemint-setup` writes `$low_power = false`, but blur, shadows, and animations remain hard-disabled in `hyprland.conf`. |
| P1-02 | High | XR support is intentionally absent. | `XR_SHA256` is a placeholder, so the driver always skips. Build dependencies remain in the image even when no driver is produced. |
| P1-03 | High | Edemint updates are not operational. | The source is disabled, the keyring is empty, the publishing target is unfinished, and the publish workflow cannot currently populate the repo. |
| P1-04 | High | Repository is public but has no license file. | Without an explicit license, the code is not legally open-source for reuse despite being publicly readable. License choice requires owner approval. |
| P1-05 | High | Security and product claims exceed tested evidence. | Secure Boot, rollback, encryption, privacy indicators, root locking, and first-boot behavior are mostly static assertions rather than artifact tests. |
| P1-06 | High | Workflow supply-chain controls are incomplete. | Actions use floating major tags, workflow-wide `contents: write`, no artifact attestations, no SBOM, no release checksums/signatures, and no protected release environment. |
| P1-07 | High | Build environment is not reproducible. | Ubuntu’s older live-build is patched through generated `LB_*` files; Pi builds fetch keys dynamically; Debian package versions are not locked to a release snapshot. |
| P1-08 | High | Documentation and canonical URLs are stale or ambiguous. | README, handoff, changelog, security links, package metadata, and OS URLs mix `edemint` and `edemix` and describe outdated CI or implementation state. |
| P1-09 | High | Complete UI behavior is not implemented. | Tap-in-void dock, mobile layouts, widgets, profile login, final power control, production window controls, icon/cursor themes, and animations remain prototypes. |
| P1-10 | High | Accessibility and localization have no release gates. | No automated contrast, keyboard-only, screen-reader, reduced-motion, scaling, RTL, or multilingual validation exists. `localepurge` currently favors an English-only image. |
| P2-01 | Medium | Pi service policy is desktop-heavy and insecure by default for headless use. | Shared service enablement includes printing, Bluetooth, discovery, and SSH without a completed account/provisioning policy. |
| P2-02 | Medium | Build scripts are difficult to test and maintain. | The amd64 builder mutates generated live-build configuration with a large inline compatibility block. Regression checks often grep comments rather than parse effective configuration. |
| P2-03 | Medium | No issue backlog maps defects to owners and acceptance tests. | The repository currently has no open issues for the production blockers above. |

## 3. Architecture decisions

These decisions remove ambiguity from implementation.

1. **Base:** Debian 13 Trixie remains the base.
2. **Hyprland source:** enable official `trixie-backports` and pin only the
   required Hyprland ecosystem packages. Hyprland, hyprlock,
   xdg-desktop-portal-hyprland, and required session components become hard
   dependencies. They must never be best-effort in a release build.
3. **Stable packages:** install available Trixie packages such as Waybar and
   wlogout from stable rather than the optional hook.
4. **Build environment:** move the canonical ISO build to a pinned Debian 13
   builder environment using Debian’s live-build version. Keep the Ubuntu
   compatibility path only as a temporary fallback and delete it after parity.
5. **Package manifests:** define explicit shared, amd64-only, Pi-only,
   installer-only, and optional-feature manifests. Generate and validate the
   resolved package set for each target before bootstrap.
6. **Interim UI:** Waybar/wofi/hyprlock remain the first-build fallback while
   the base is stabilized.
7. **Production shell:** implement `edemint-shell` as a packaged Qt 6/QML
   layer-shell application using Debian’s LayerShellQt/QML packages. It owns the
   desktop dock, status surface, overview, app pages, widgets, responsive
   mobile layout, and tap-in-void behavior. Waybar remains a recovery fallback
   until feature parity and soak testing are complete.
8. **Greeter:** implement a separate `edemint-greeter` client for greetd using
   the same design-token package. The lock screen remains hyprlock but shares
   generated colors, typography, spacing, and artwork.
9. **Window controls:** use Debian’s version-matched
   `hyprland-plugin-hyprbars` for server-side controls where supported, plus
   GTK/Qt theme settings for client-side controls. Applications that draw
   proprietary client-side decorations are documented exceptions.
10. **Release artifacts:** every tag produces versioned artifacts, SHA-256 and
    SHA-512 files, package manifests, SBOMs, build provenance attestations, and
    a machine-readable build manifest containing the commit SHA and dependency
    snapshot.
11. **XR driver:** move the driver into a separately versioned Debian package.
    Vendor or pin its source and checksum before release; do not download and
    compile arbitrary source inside the final image build.

## 4. Execution phases

### Phase 0: release freeze and governance

Tasks:

- Mark all current artifacts `development preview; not for production use`.
- Create GitHub issues P0-01 through P2-03 with the acceptance tests from this
  document.
- Protect `main`: require PRs, passing checks, resolved review conversations,
  linear history, and no force-pushes.
- Add `CODEOWNERS` for build, security, installer, Pi, and UI paths.
- Add pull-request and bug-report templates that require reproduction steps,
  affected artifact SHA, architecture, logs, and acceptance evidence.
- Choose and add an OS/repository license. Record third-party artwork and code
  licenses separately in `debian/copyright`-style manifests.
- Decide the canonical public repository name. Update all URLs only after that
  decision, then add redirects from the old project location where possible.

Exit criteria:

- No production release can be published from an unprotected branch.
- Every verified blocker has an issue, owner, dependency list, and test.
- Repository license is explicit and compatible with all bundled assets.

### Phase 1: deterministic package and build foundation

Tasks:

- Add Debian `trixie-backports` as a deb822 source with apt preferences that
  default to Trixie and selectively permit the Hyprland package set.
- Move `hyprland`, `hyprlock`, `xdg-desktop-portal-hyprland`, and other required
  session packages into a hard-fail package list.
- Move stable `wlogout` and any other available tools out of the best-effort
  hook.
- Split optional packages into feature packages: `edemint-ar`, `edemint-ai`,
  and nonessential desktop extras. Their absence must not break the base, but
  their UI must report “not installed” rather than pretending availability.
- Introduce `scripts/resolve-packages.sh <amd64|pi>` that emits a sorted package
  manifest and fails on duplicates, unresolved packages, wrong architectures,
  or optional packages accidentally used by required services.
- Build in a pinned Debian 13 environment. Record live-build, mmdebstrap,
  genimage, kernel, and archive snapshot versions in `build-manifest.json`.
- Add release mode using a pinned Debian snapshot timestamp; keep nightly mode
  against current Trixie security updates.
- Refactor the large amd64 inline builder into small tested scripts under
  `scripts/build/`. Parse effective live-build config instead of grepping
  comments.
- Make builds use clean work directories and fail if tracked files change.

Exit criteria:

- Both target package manifests resolve for amd64 and arm64.
- Required desktop packages are present in the built rootfs or the build fails.
- Two builds from the same source and snapshot produce equivalent package and
  filesystem manifests; any nondeterministic fields are documented.

### Phase 2: amd64 ISO recovery

Tasks:

- Add an ISO-only greetd configuration with an `initial_session` for the live
  user. Keep installed-system greetd password-gated.
- Verify the live user exists, owns its home, can start Hyprland, and has only
  the narrowly scoped passwordless privilege required to launch Calamares.
- Replace `sudo -E calamares` with a polkit or tightly scoped sudo rule that
  cannot execute arbitrary commands as root.
- Generate both BIOS and UEFI El Torito entries. Include `EFI/BOOT/BOOTX64.EFI`,
  signed shim, signed GRUB, and signed Debian kernel components.
- Add artifact checks that inspect the ISO boot catalog, EFI files, squashfs,
  package manifest, executable permissions, systemd unit enablement, desktop
  entry validity, and embedded source manifest.
- Remove the false “Official Debian Snapshot” identity from `.disk/info` and
  embed Edemint version, target, commit, and build date.
- Ensure the three Edemint metapackages are installed and reported by `dpkg`.
- Require Hyprland to start under software rendering in QEMU and under a
  virtio-GPU path.

Automated tests:

- QEMU BIOS live boot to graphical session.
- QEMU OVMF UEFI live boot.
- QEMU OVMF Secure Boot with Edemint/Ubuntu test keys as appropriate.
- Login, terminal launch, launcher, file manager, network indicator, lock,
  suspend simulation, and power-menu smoke tests.
- Calamares unattended test install into a disposable disk.

Exit criteria:

- Live desktop appears without manual TTY intervention in BIOS and UEFI modes.
- Secure Boot status is verified inside the booted session.
- Calamares completes and the installed disk boots to a password-gated greeter.

### Phase 3: Raspberry Pi image recovery

Tasks:

- Establish one kernel naming contract. Either remove the `kernel=` override and
  use Pi firmware defaults, or write the exact configured names for Pi 4 and
  Pi 5. Add a structural test that every referenced kernel, initrd, DTB, and
  overlay exists in the FAT image.
- Add `edemint-firstboot-provision.service`, ordered before greetd and SSH.
- Support two secure provisioning modes:
  - local TTY wizard: username, password, locale, keyboard, timezone, hostname,
    and optional Wi-Fi;
  - headless preseed file on the firmware partition containing username,
    password hash or SSH public key, Wi-Fi settings, hostname, and an option to
    enable SSH. Plaintext account passwords are forbidden.
- Lock root, create the user and required groups, copy `/etc/skel`, then enable
  greetd. Keep SSH disabled until a user explicitly enables it or supplies an
  SSH key through the preseed.
- Make the provisioning file one-shot: consume it, remove secrets from the FAT
  partition, and write an auditable completion stamp.
- Apply Pi-specific service presets. Disable printing, discovery, modem, and
  other desktop services unless the user enables them.
- Validate Pi 4 and Pi 5 DTBs, KMS, initramfs, root label, fstab, growfs, and
  flash-kernel fixup behavior.
- Remove risky hardware overrides such as forced PCIe Gen 3 unless a tested
  device matrix proves them stable.

Automated structural tests:

- `zstd -t` archive integrity.
- Decompress to a sparse temporary image.
- Validate MBR, FAT32 firmware partition, ext4 root, labels, UUID references,
  filesystem checks, kernel/initrd/DTBs, enabled units, and absence of plaintext
  credentials.
- Boot generic arm64 portions under QEMU where possible.

Physical hardware tests:

- Pi 4: 2 GB and 4/8 GB, microSD, HDMI, Ethernet, Wi-Fi, Bluetooth.
- Pi 5: 4/8 GB, microSD and NVMe, HDMI, Ethernet, Wi-Fi, Bluetooth, active
  cooler behavior.
- Headless preseed and local interactive first boot.
- Power loss during growfs/provisioning followed by recovery on the next boot.

Exit criteria:

- Both Pi 4 and Pi 5 reach a usable account and graphical session.
- Headless SSH is key-based and opt-in.
- First boot is idempotent and survives interruption.

### Phase 4: installer, update, security, and recovery

Installer matrix:

- UEFI erase install: btrfs + LUKS2 + swapfile.
- UEFI erase install: btrfs without encryption.
- Manual partition install.
- ext4 install without btrfs-only services.
- Existing Windows-style EFI partition preservation test.
- BIOS install where supported.
- Non-ASCII username, hostname, passphrase, and locale test.

Required assertions after install:

- root is locked;
- user sudo requires the user password;
- live user and installer launcher are absent;
- greetd starts Hyprland;
- EFI/GRUB entries are valid;
- encrypted root unlocks and initramfs contains required modules;
- snapper is enabled only on btrfs;
- AppArmor and nftables are active;
- no build keys, temporary files, or live credentials remain.

Updates and recovery:

- Fix the publish pipeline by uploading metapackage artifacts from the package
  job and downloading them into the release job.
- Publish the apt repository to a real immutable target. Ship its public key in
  the image and enable the source only after the endpoint and rollback plan are
  operational.
- Test install, upgrade, downgrade, revoked release metadata, expired metadata,
  bad signatures, and interrupted dpkg recovery.
- Test snapper pre/post creation and rollback on a real btrfs install. Verify
  user data boundaries and document what rollback does not restore.
- Validate unattended-upgrades against Debian Security and Edemint origin.
- Replace static security claims with tests whose results are attached to the
  release.

Exit criteria:

- Every installer matrix entry boots after installation.
- A deliberately broken package upgrade can be rolled back using documented
  recovery media and commands.
- A tampered or unsigned repository is rejected.

### Phase 5: repository and supply-chain hardening

Tasks:

- Split CI permissions per job. Default to `contents: read`; grant release and
  attestation permissions only to protected tag jobs.
- Pin every third-party action to a full commit SHA and automate reviewed update
  PRs.
- Add workflow concurrency, explicit timeouts, disk-space checks, and failure
  log collection for every long-running job.
- Add secret scanning, dependency review, CodeQL where applicable, shell/YAML/
  QML linting, systemd unit verification, desktop-file validation, and license
  scanning.
- Produce CycloneDX or SPDX SBOMs for each image and Debian package.
- Generate GitHub artifact attestations and detached release signatures.
- Publish `SHA256SUMS`, `SHA512SUMS`, package manifests, SBOMs, provenance,
  source commit, dependency snapshot, and test report with every release.
- Use a protected `release` environment with human approval for stable tags.
- Store signing material in an environment secret or external signing service;
  document rotation and revocation.

Exit criteria:

- A consumer can verify artifact checksum, signature, provenance, source commit,
  package manifest, and SBOM without trusting the release web page alone.
- Pull requests cannot obtain release write permissions or signing secrets.

### Phase 6: design source normalization

Tasks:

- Import the eight original JPEGs into `docs/prototypes/original/` without
  modification and verify them against the recorded SHA-256 values.
- Redraw geometry as SVG/Figma-compatible vector masters. Keep originals as
  historical evidence, not runtime assets.
- Create one machine-readable token source, for example
  `design/tokens/edemint.tokens.json`, containing:
  - raw C1-C8 palette samples;
  - semantic light/dark surface roles;
  - text, focus, success, warning, and danger colors;
  - spacing, corner radii, strokes, opacity, elevation, and typography;
  - desktop, narrow, mobile, and HiDPI breakpoints;
  - animation durations and reduced-motion alternatives.
- Generate Hyprland, Qt/QML, GTK, Waybar fallback, Calamares, GRUB, Plymouth,
  and documentation color outputs from the token source.
- Add contrast tests for every text/state pair. Normal text requires at least
  WCAG AA 4.5:1; large text requires 3:1; focus and controls require 3:1 against
  adjacent colors.
- Define icon safe areas, optical sizes, touch targets, keyboard focus order,
  and localization expansion allowances.

Exit criteria:

- No production component copies colors manually from JPEGs.
- Generated token outputs are reproducible and drift checks pass in CI.

### Phase 7: production shell and prototype components

#### `main_homescreen`

Implementation:

- Persistent left pinned-app dock managed by `edemint-shell`.
- Configurable pinned applications using desktop-file IDs, not executable
  strings.
- Lower expandable all-apps/search component backed by desktop-entry indexing.
- Top-right status region for time, network, Bluetooth, audio, battery, privacy,
  updates, and notifications.
- Smaller rounded app icons than the prototype placeholders.

Acceptance:

- Keyboard, pointer, touch, and screen-reader operation.
- Correct behavior at 1280x720 through 4K and 1x/1.5x/2x scaling.
- Missing apps, multiple batteries, no Wi-Fi, airplane mode, and disconnected
  states are handled without blank or broken modules.

#### `dock` tap-in-void overview

Implementation:

- Desktop-layer input region receives only compositor-unclaimed background
  clicks/taps.
- Four translucent overlapping lines are vector surfaces with tokenized opacity.
- App overview never steals input from application windows or desktop menus.

Acceptance:

- Opens only on empty desktop input or an explicit keyboard shortcut.
- Escape, outside click, workspace switch, and app launch close it reliably.
- Multi-monitor focus and touch behavior are deterministic.

#### `mobileratioqo`

Implementation:

- Aspect-responsive mobile/narrow layout with centered paginated app grid.
- Upper-left time/date/status surface and bottom page indicator.
- Orientation and output changes are driven by compositor output events.

Acceptance:

- Portrait 1080x1920, 720x1280, and narrow desktop outputs.
- Touch targets are at least 44 CSS pixels; keyboard fallback remains complete.
- Rotation does not restart applications or lose page state.

#### `mobile_dock_ratio_2`

Implementation:

- Widget model shared across all homescreens, not special-cased to one view.
- Rotated layout places the sidebar according to physical orientation.
- Lower expandable app component and upper status block share the same data
  model as desktop.

Acceptance:

- Widget failure is isolated; one broken widget cannot crash the shell.
- Widget permissions and network access are explicit.
- Layout survives rotation, scaling, hotplug, and safe-area changes.

#### `panelv`

Implementation:

- Green expands/fullscreens, yellow minimizes/hides, red closes.
- Use hyprbars for server-side decorations and generated GTK/Qt themes for
  supported client-side decorations.
- Provide icon shape and accessible names in addition to color.

Acceptance:

- Correct action, hover, focus, pressed, disabled, and maximized states.
- No accidental close when the user intends fullscreen.
- Document applications with non-themeable proprietary decorations.

#### `login_screen`

Implementation:

- `edemint-greeter` talks to greetd and shares design tokens with hyprlock.
- Always-visible date/time, centered profile image, username, and optional
  half-width password/code field.
- No profile picture or password is exposed across accounts without permission.

Acceptance:

- Password, no-password, multiple-user, wrong-password, expired-password,
  keyboard-layout, accessibility, and power-action paths.
- Lock screen cannot be bypassed by compositor crash or VT switching.

#### `on_off2`

Implementation:

- Vector power motif with explicit standby, power off, reboot, log out, and lock
  choices where appropriate.
- Confirmation policy is configurable; destructive actions remain visually and
  semantically distinct.

Acceptance:

- Fully operable by keyboard and touch.
- Inhibitors, unsaved-session warnings where available, and polkit failures are
  shown rather than ignored.

#### Animation phase

Animations begin only after all static acceptance tests pass.

- Use tokenized durations and curves.
- Respect `prefers-reduced-motion`/Edemint reduced-motion setting.
- Keep Pi/low-power profile at zero or minimal motion.
- Require frame-time and memory budgets on Pi 4 and integrated graphics.

### Phase 8: quality, accessibility, localization, and performance

Quality matrix:

- Resolutions: 1280x720, 1920x1080, 2560x1440, 3840x2160, 1080x1920.
- Scale: 1.0, 1.25/1.5 where supported, and 2.0.
- Input: mouse, touchpad, touchscreen, keyboard-only, screen reader.
- Hardware: Intel, AMD, software renderer, Pi 4, Pi 5.
- Monitors: single, dual, hotplug, AR glasses as an external display.

Accessibility gates:

- WCAG AA contrast.
- Visible focus and logical traversal.
- No color-only state.
- Accessible names for every icon-only control.
- Orca smoke test for greeter, dock, app search, power menu, and settings.
- Reduced motion and large-text modes.

Localization gates:

- Stop deleting locales required by supported language packs.
- Test German and English initially, then one RTL locale and one CJK locale.
- Validate date/time formats, text expansion, IME, keyboard layout switching,
  and translated installer/greeter strings.

Performance budgets:

- Idle shell RSS target: <= 180 MiB on amd64 and <= 140 MiB on Pi fallback
  profile, measured consistently and revised only with evidence.
- No continuous CPU wakeups above an agreed idle baseline.
- Graphical login to interactive shell: target <= 10 seconds after systemd
  reaches graphical target on reference SSD hardware.
- Pi first interactive boot after provisioning: target <= 90 seconds excluding
  package downloads.

### Phase 9: CI test topology

Required jobs, in dependency order:

1. `validate`: shellcheck, shfmt check, YAML/TOML/JSON schemas, QML lint, CSS
   parser, desktop-file validation, systemd-analyze verify, license checks.
2. `resolve-packages-amd64` and `resolve-packages-arm64`.
3. `build-packages`: Edemint metapackages, shell, greeter, themes, XR optional
   package; upload `.deb` artifacts and repository metadata.
4. `build-iso` and `build-pi` from the same dependency snapshot.
5. `inspect-iso`: boot catalog, EFI tree, signatures, squashfs, packages,
   users, units, manifests, checksums.
6. `inspect-pi`: zstd, partition table, filesystems, firmware references,
   rootfs users/units, no secrets.
7. `boot-iso-bios`, `boot-iso-uefi`, and `boot-iso-secureboot`.
8. `install-matrix` for Calamares scenarios.
9. `session-smoke`: Hyprland, portal, lock, launcher, network, audio, power.
10. `ui-visual-regression`: deterministic screenshots at required layouts.
11. `upgrade-rollback`: apt update, interrupted dpkg, snapshot, rollback.
12. `hardware-approval`: protected manual gate with attached Pi and PC reports.
13. `release`: checksums, signatures, SBOM, provenance, GitHub release, apt repo.

A release job must use the exact artifacts tested by previous jobs; it may not
rebuild them.

## 5. Ordered implementation PRs

Each PR remains independently reviewable and must include its new tests.

1. **PR-01 Governance and baseline:** license decision, branch protection docs,
   issue templates, CODEOWNERS, artifact baseline, preview warning.
2. **PR-02 Required desktop stack:** Trixie backports, apt pinning, hard package
   dependencies, package resolver, remove load-bearing best-effort behavior.
3. **PR-03 ISO boot and identity:** Debian builder, BIOS/UEFI/Secure Boot,
   Edemint metadata, live-session access, artifact inspection.
4. **PR-04 Pi boot and provisioning:** kernel naming, first-boot user/preseed,
   SSH policy, service preset, structural tests.
5. **PR-05 VM and hardware smoke framework:** QEMU BIOS/UEFI/session checks,
   Pi inspection, hardware report format.
6. **PR-06 Calamares installation matrix:** privilege boundary, encrypted and
   unencrypted installs, installed-system assertions.
7. **PR-07 Updates and recovery:** functional apt repo publishing, key shipping,
   upgrade/downgrade, snapper and rollback tests.
8. **PR-08 Supply chain:** action SHA pinning, least privilege, SBOM, checksums,
   signatures, attestations, protected release environment.
9. **PR-09 Design sources and tokens:** original images, SVG redraws, generated
   palette/theme outputs, accessibility checks.
10. **PR-10 Interim UI correctness:** fallback dock/status/lock/power behavior,
    full-effects implementation, responsive fallback configs.
11. **PR-11 Shell and greeter foundation:** packaged Qt/QML shell API, greetd
    client, test harness, Waybar fallback.
12. **PR-12 Desktop components:** main homescreen, all-apps completer, status,
    tap-in-void overview.
13. **PR-13 Mobile/widgets:** mobile ratios, rotation, widget sandbox/failure
    isolation, page indicator.
14. **PR-14 Window and power controls:** panelv semantics, themes, hyprbars,
    power motif and confirmations.
15. **PR-15 Motion and polish:** reduced motion, performance budgets, final
    artwork integration, visual regression baselines.
16. **PR-16 Release documentation:** README, handoff, security policy, support,
    flashing/installing/recovery manuals, known limitations.

## 6. Definition of done

### Base release candidate

- Both artifacts are generated from a protected tag and exact commit.
- ISO boots in BIOS, UEFI, and Secure Boot configurations.
- ISO reaches Hyprland and installs successfully across the installer matrix.
- Pi 4 and Pi 5 boot and complete secure provisioning.
- Required packages are hard dependencies and present in artifact manifests.
- Root/security/update/recovery assertions pass on installed systems.
- Checksums, signatures, SBOMs, provenance, package manifests, and test reports
  are published.
- No P0 issue remains open.

### Full UI release candidate

- Every prototype component meets its acceptance criteria.
- Final icon, cursor, profile, wallpaper, font, and logo licenses are recorded.
- Accessibility, localization, scaling, multi-monitor, mobile, and reduced-motion
  gates pass.
- Pi low-power and amd64 performance budgets pass.
- Waybar fallback remains usable if `edemint-shell` crashes.
- No P0/P1 UI issue remains open; documented P2 limitations have workarounds.

## 7. Effort and sequencing

Estimated engineering effort, not calendar promises:

| Track | Effort |
|---|---:|
| Governance, reproducible build, package correction | 2-3 engineer-weeks |
| ISO boot, Secure Boot, live session, installer matrix | 2-4 engineer-weeks |
| Pi boot, provisioning, physical hardware validation | 2-4 engineer-weeks |
| Updates, recovery, CI, release supply chain | 2-3 engineer-weeks |
| Design source normalization and first fallback UI | 1-2 engineer-weeks |
| Production shell, greeter, desktop/mobile components | 6-10 engineer-weeks |
| Accessibility, localization, performance, RC soak | 2-4 engineer-weeks |

A credible base OS release candidate is approximately 8-14 engineer-weeks for
one experienced engineer with access to amd64 test hardware and Pi 4/5 devices.
The complete prototype-driven UI adds approximately 8-14 engineer-weeks. Work
can overlap across build, UI, and QA owners, but release gates cannot be
parallelized away.

## 8. Immediate next actions

1. Open P0 issues from the verified defect table.
2. Implement PR-02 first: official Trixie backports and hard compositor
   dependencies. Rebuild the ISO and prove Hyprland is present before any more
   visual work.
3. Implement PR-04 kernel naming and Pi provisioning in parallel.
4. Add artifact inspection jobs before attempting another release.
5. Do not publish or promote the June 1 artifacts as usable releases.
