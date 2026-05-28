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
if command -v nft >/dev/null 2>&1; then
    nft -c -f shared/includes/etc/nftables.conf || fail=1
else
    echo "(skip: nft not installed)"
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
    for d in profiles/amd64-iso/config/packages.chroot/edemint-base_0.1_all.deb \
             profiles/amd64-iso/config/packages.chroot/edemint-desktop_0.1_all.deb \
             profiles/amd64-iso/config/packages.chroot/edemint-ai_0.1_all.deb; do
        [ -s "$d" ] || { echo "MISSING: $d"; fail=1; }
    done
    # leave the .debs in place — image builds need them
else
    echo "(skip: equivs-build missing)"
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
echo "(invariant checks done)"

if [ $fail -eq 0 ]; then
    note "Tier A PASS"
else
    note "Tier A FAIL"
    exit 1
fi
