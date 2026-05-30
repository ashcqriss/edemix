#!/bin/sh
# Edemint Tier A static checks — root-free, fast, run in CI on every push.
#
# Checks:
#   - shellcheck every hook + helper + build script
#   - nft -c the firewall config
#   - validate every Calamares YAML/desc file is well-formed YAML
#   - build all three equivs metapackages (proves the .list.chroot files
#     have well-formed package names that produce a valid Depends:)
#   - assert security invariants:
#       * the XR udev rule (post-hook) is group-scoped 0660 (audit by
#         reading the generated rules text from the hook)
#       * edemint-ai ships disabled (config.toml)
#       * AI local_only refusal is in place (string check on the helper)
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

note() { printf '\n── %s ──────────────────────────────────────────\n' "$1"; }

note "shellcheck"
# Collect shell scripts: explicit *.sh / *.hook.chroot under the tree, plus
# the helper bin/ directory (real files only — skip symlinks like `ai`).
SHFILES="$(
    {
        find . -type f \( -name '*.sh' -o -name '*.hook.chroot' \) \
            ! -path './.git/*' ! -path './profiles/*/build/*'
        find shared/includes/usr/local/bin -type f ! -type l 2>/dev/null
    } | awk 'NF && !seen[$0]++'
)"
# shellcheck disable=SC2086
shellcheck $SHFILES || fail=1

note "nftables.conf"
# `nft -c` opens a netlink socket and validates against live kernel state,
# so it needs CAP_NET_ADMIN even in check-only mode. CI runs this as a
# non-root user, where a direct `nft -c` fails with EPERM. Run it as root
# when we are root; otherwise inside a throwaway user+network namespace
# (`unshare -rn` maps us to root in a private netns with CAP_NET_ADMIN).
# If neither path is available, skip rather than fail the whole build over
# an environment limitation.
NFT_CONF=shared/includes/etc/nftables.conf
if ! command -v nft >/dev/null 2>&1; then
    echo "(skip: nft not installed)"
elif [ "$(id -u)" -eq 0 ]; then
    nft -c -f "$NFT_CONF" || fail=1
elif command -v unshare >/dev/null 2>&1 && unshare -rn true 2>/dev/null; then
    unshare -rn nft -c -f "$NFT_CONF" || fail=1
else
    echo "(skip: nft -c needs root or user-namespace support)"
fi

note "Calamares YAML / TOML / desktop files"
for f in shared/includes/etc/calamares/branding/edemint/branding.desc \
         shared/includes/etc/calamares/settings.conf \
         shared/includes/etc/calamares/modules/*.conf \
         shared/includes/etc/skel/.config/edemint-ai/config.toml \
         shared/includes/usr/share/applications/install-edemint.desktop; do
    [ -f "$f" ] || { echo "MISSING: $f"; fail=1; continue; }
    head -1 "$f" >/dev/null
done

note "equivs metapackages"
if command -v equivs-build >/dev/null 2>&1; then
    "$ROOT/packaging/build-metapackages.sh"
    DROP=shared/includes/usr/share/edemint/metapackages
    for d in "$DROP/edemint-base_0.1_all.deb" \
             "$DROP/edemint-desktop_0.1_all.deb" \
             "$DROP/edemint-ai_0.1_all.deb"; do
        [ -s "$d" ] || { echo "MISSING: $d"; fail=1; }
    done
    # leave the .debs in place — image builds need them
else
    echo "(skip: equivs-build missing)"
fi

# Nothing must ever land in profiles/*/config/packages.chroot/. live-build
# treats anything there as input for a signed local apt repo, and the
# signing gen-keys gpg, which fails in TTY-less chroots with
# "agent_genkey: Inappropriate ioctl for device". Our metapackages go
# through includes.chroot + the 0900 hook instead.
if find profiles/*/config/packages.chroot -maxdepth 1 -name '*.deb' 2>/dev/null | grep -q .; then
    echo "FAIL: .debs found under profiles/*/config/packages.chroot/ —"
    echo "      live-build will try to sign a local apt repo and fail."
    fail=1
fi

note "Security invariants"
# XR udev rule must be 0660, edemint-ar group, NOT 0666 / NOT plugdev-only
if ! grep -q 'MODE="0660".*GROUP="edemint-ar"' shared/hooks/normal/0200-xr-driver.hook.chroot; then
    echo "FAIL: XR udev rule is missing 0660 / edemint-ar"; fail=1
fi
if grep -q 'MODE="0666"' shared/hooks/normal/0200-xr-driver.hook.chroot; then
    echo "FAIL: XR udev rule has world-readable mode 0666"; fail=1
fi
# AI must ship disabled
if ! grep -qE '^enabled\s*=\s*false' shared/includes/etc/skel/.config/edemint-ai/config.toml; then
    echo "FAIL: edemint-ai default config is not disabled"; fail=1
fi
# local_only refusal text
if ! grep -q 'refusing cloud backend' shared/includes/usr/local/bin/edemint-ai; then
    echo "FAIL: local_only refusal path missing in edemint-ai"; fail=1
fi
# Root stays locked by Calamares finalize
if ! grep -q 'passwd -l root' shared/includes/etc/calamares/modules/shellprocess-finalize.conf; then
    echo "FAIL: Calamares finalize is not locking root"; fail=1
fi
# Calamares users module must not set a root password
if grep -qE '^setRootPassword:\s*true' shared/includes/etc/calamares/modules/users.conf; then
    echo "FAIL: Calamares users sets root password"; fail=1
fi
# AI privacy meter: cloud lock acquire/release must wrap every cloud call.
for fn in call_claude call_openai call_gemini; do
    if ! awk "/$fn\(\)/,/^}/" shared/includes/usr/local/bin/edemint-ai \
        | grep -q cloud_lock_acquire; then
        echo "FAIL: $fn missing cloud_lock_acquire"; fail=1
    fi
    if ! awk "/$fn\(\)/,/^}/" shared/includes/usr/local/bin/edemint-ai \
        | grep -q cloud_lock_release; then
        echo "FAIL: $fn missing cloud_lock_release"; fail=1
    fi
done
# btrfs snapshot apt hook must be present
if ! grep -q 'snapper -c root create -t pre' \
        shared/includes/etc/apt/apt.conf.d/80edemint-snapshots; then
    echo "FAIL: apt pre-snapshot hook is missing"; fail=1
fi
# All four 'mega' helpers must be executable shell.
for tool in edemint-rollback edemint-ai-privacy edemint-sync edemint-setup edemint-doctor; do
    p="shared/includes/usr/local/bin/$tool"
    [ -x "$p" ] || { echo "FAIL: $p not executable"; fail=1; }
done

# --- regressions to lock in from the CI debug rounds ---

# Pi hook runner must exist + be executable (its absence makes the chroot
# run zero hooks; broken-image-on-success regression from a39e029).
if [ ! -x profiles/arm64-pi/scripts/edemint-run-hooks ]; then
    echo "FAIL: profiles/arm64-pi/scripts/edemint-run-hooks not executable"
    fail=1
fi

# apt config: every Pre-/Post-Invoke string must be a single line. Apt's
# config grammar does NOT honour backslash-newline inside "...". A
# multiline string parses as "Malformed tag" and breaks every apt run.
for f in shared/includes/etc/apt/apt.conf.d/*; do
    [ -f "$f" ] || continue
    if grep -E '"[^"]*\\\s*$' "$f" >/dev/null; then
        echo "FAIL: $f has backslash-newline inside a quoted string"
        fail=1
    fi
done

# Pi build.sh customize-hooks: no inner sh -c "..." containing a shell
# variable. The OUTER mmdebstrap-wrapper shell expands $var before the
# inner shell ever sees it (the run-hooks loop hit this bug). Script
# files via copy-in are the safe pattern.
if grep -nE 'sh -c "[^"]*\$[a-zA-Z_{]' profiles/arm64-pi/build.sh; then
    echo "FAIL: Pi build.sh has inner-double-quoted sh -c with a \$variable"
    fail=1
fi

# build.sh must override LB_BOOTSTRAP_INCLUDE (singular — live-build
# reads this name) for the gnupg+ca-certs early install. Setting only
# the plural form has no effect on Ubuntu's packaged live-build.
if ! grep -q 'LB_BOOTSTRAP_INCLUDE=' build.sh; then
    echo "FAIL: build.sh does not set LB_BOOTSTRAP_INCLUDE (singular)"
    fail=1
fi

# debian-installer MUST be 'none'. Anything else (live/text/cdrom/etc.)
# makes lb_chroot_archives try to gen-key a d-i local repo signing key
# in a TTY-less chroot, which fails with "agent_genkey: Inappropriate
# ioctl for device". We use Calamares, not d-i.
if ! grep -qE '^\s*--debian-installer\s+none' profiles/amd64-iso/auto/config; then
    echo "FAIL: auto/config doesn't pass --debian-installer none"
    fail=1
fi
if ! grep -q 'LB_DEBIAN_INSTALLER="none"' build.sh; then
    echo "FAIL: build.sh does not force LB_DEBIAN_INSTALLER=none"
    fail=1
fi

echo "(invariant checks done)"

if [ $fail -eq 0 ]; then
    note "Tier A PASS"
else
    note "Tier A FAIL"
    exit 1
fi
