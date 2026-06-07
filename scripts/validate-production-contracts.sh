#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MANIFEST=shared/includes/usr/share/edemint/required-desktop.packages
AMD64_HOOK=profiles/amd64-iso/config/hooks/normal/0050-extra-desktop.hook.chroot
PI_RUNNER=profiles/arm64-pi/scripts/edemint-run-hooks
PI_CONFIG=profiles/arm64-pi/boot/config.txt
PI_SEED=profiles/arm64-pi/scripts/seed-boot-firmware
PROVISION=profiles/arm64-pi/includes/usr/local/sbin/edemint-firstboot-provision
PROVISION_UNIT=profiles/arm64-pi/includes/etc/systemd/system/edemint-firstboot-provision.service
GREETD_DROPIN=profiles/arm64-pi/includes/etc/systemd/system/greetd.service.d/10-edemint-provisioning.conf
SSH_DROPIN=profiles/arm64-pi/includes/etc/systemd/system/ssh.service.d/10-edemint-provisioning.conf
SSH_CONFIG=profiles/arm64-pi/includes/etc/ssh/sshd_config.d/90-edemint-firstboot.conf

for file in "$MANIFEST" "$AMD64_HOOK" "$PI_RUNNER" "$PI_CONFIG" "$PI_SEED" \
    "$PROVISION" "$PROVISION_UNIT" "$GREETD_DROPIN" "$SSH_DROPIN" "$SSH_CONFIG"; do
    [ -s "$file" ] || { echo "FAIL: missing $file" >&2; exit 1; }
done

for package in hyprland hyprlock hypridle xdg-desktop-portal-hyprland \
    wlogout swayosd cliphist wf-recorder jq; do
    grep -Eq "^${package}[[:space:]]+(trixie|trixie-backports)$" "$MANIFEST" || {
        echo "FAIL: required package is not pinned in manifest: $package" >&2
        exit 1
    }
    grep -Eq "(^|, )[[:space:]]*${package}([,[:space:]]|$)" \
        packaging/edemint-desktop/control || {
        echo "FAIL: edemint-desktop does not depend on $package" >&2
        exit 1
    }
done

for installer in "$AMD64_HOOK" "$PI_RUNNER"; do
    grep -q 'trixie-backports' "$installer" || {
        echo "FAIL: $installer does not enable trixie-backports" >&2
        exit 1
    }
    grep -q 'required-desktop.packages' "$installer" || {
        echo "FAIL: $installer ignores the required desktop manifest" >&2
        exit 1
    }
    grep -q 'dpkg-query' "$installer" || {
        echo "FAIL: $installer does not verify installed packages" >&2
        exit 1
    }
done

if grep -Eq '^[[:space:]]*kernel=' "$PI_CONFIG"; then
    echo "FAIL: Pi config overrides board-specific kernel selection" >&2
    exit 1
fi
for kernel in kernel8.img kernel_2712.img; do
    grep -q "$kernel" "$PI_SEED" || {
        echo "FAIL: seed-boot-firmware does not create $kernel" >&2
        exit 1
    }
done

sh -n "$AMD64_HOOK"
sh -n "$PI_RUNNER"
sh -n "$PROVISION"

grep -q 'Requires=edemint-firstboot-provision.service' "$GREETD_DROPIN"
grep -q 'ConditionPathExists=/var/lib/edemint/ssh-enabled' "$SSH_DROPIN"
grep -q '^PermitRootLogin no$' "$SSH_CONFIG"
grep -q '^PasswordAuthentication no$' "$SSH_CONFIG"
grep -q 'plaintext passwords are forbidden' "$PROVISION"
grep -q 'passwd --lock root' "$PROVISION"

if grep -Eq '(^|[[:space:]])(source|eval)[[:space:]].*PRESEED' "$PROVISION"; then
    echo "FAIL: first-boot preseed must never be sourced or evaluated" >&2
    exit 1
fi

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$AMD64_HOOK" "$PI_RUNNER" "$PROVISION" "$0"
fi

echo "Production contracts: PASS"
