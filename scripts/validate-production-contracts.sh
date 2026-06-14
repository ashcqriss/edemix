#!/bin/sh
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MANIFEST=shared/includes/usr/share/edemint/required-desktop.packages
SHARED_HOOK=shared/hooks/normal/0050-extra-desktop.hook.chroot
ISO_COMPAT_HOOK=shared/hooks/normal/0850-isolinux-compat.hook.chroot
AMD64_HOOK=profiles/amd64-iso/config/hooks/normal/0050-extra-desktop.hook.chroot
PI_RUNNER=profiles/arm64-pi/scripts/edemint-run-hooks
PI_CONFIG=profiles/arm64-pi/boot/config.txt
PI_SEED=profiles/arm64-pi/scripts/seed-boot-firmware
PROVISION=profiles/arm64-pi/includes/usr/local/sbin/edemint-firstboot-provision
PROVISION_UNIT=profiles/arm64-pi/includes/etc/systemd/system/edemint-firstboot-provision.service
GREETD_DROPIN=profiles/arm64-pi/includes/etc/systemd/system/greetd.service.d/10-edemint-provisioning.conf
SSH_DROPIN=profiles/arm64-pi/includes/etc/systemd/system/ssh.service.d/10-edemint-provisioning.conf
SSH_CONFIG=profiles/arm64-pi/includes/etc/ssh/sshd_config.d/90-edemint-firstboot.conf

for file in "$MANIFEST" "$SHARED_HOOK" "$ISO_COMPAT_HOOK" "$AMD64_HOOK" "$PI_RUNNER" "$PI_CONFIG" \
    "$PI_SEED" "$PROVISION" "$PROVISION_UNIT" "$GREETD_DROPIN" \
    "$SSH_DROPIN" "$SSH_CONFIG"; do
    [ -s "$file" ] || { echo "FAIL: missing $file" >&2; exit 1; }
done

[ -L "$AMD64_HOOK" ] || {
    echo "FAIL: amd64 desktop hook must remain a symlink to the shared hook" >&2
    exit 1
}
[ "$(readlink "$AMD64_HOOK")" = '../../../../../shared/hooks/normal/0050-extra-desktop.hook.chroot' ] || {
    echo "FAIL: amd64 desktop hook points to the wrong target" >&2
    exit 1
}

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

grep -q 'trixie-backports' "$SHARED_HOOK" || {
    echo "FAIL: shared desktop hook does not enable trixie-backports" >&2
    exit 1
}
grep -q 'required-desktop.packages' "$SHARED_HOOK" || {
    echo "FAIL: shared desktop hook ignores the required manifest" >&2
    exit 1
}
grep -q 'dpkg-query' "$SHARED_HOOK" || {
    echo "FAIL: shared desktop hook does not verify installed packages" >&2
    exit 1
}
grep -Fq "if [ \"\$arch\" != \"amd64\" ]" "$ISO_COMPAT_HOOK" || {
    echo "FAIL: isolinux compatibility hook is not scoped to amd64 images" >&2
    exit 1
}
grep -Fq "if ! sh \"\$hook\"" "$PI_RUNNER" || {
    echo "FAIL: Pi hook runner does not propagate hook failures" >&2
    exit 1
}
if grep -q 'FAILED (continuing)' "$PI_RUNNER"; then
    echo "FAIL: Pi hook runner still swallows failures" >&2
    exit 1
fi

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

sh -n "$SHARED_HOOK"
sh -n "$ISO_COMPAT_HOOK"
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

# Local actions and docker images are resolved differently. Every action fetched
# from another repository must be immutable, reviewable, and pinned to 40 hex.
grep -RhE '^[[:space:]]*-[[:space:]]*uses:[[:space:]]+' .github/workflows \
    | sed -E 's/.*uses:[[:space:]]+([^[:space:]#]+).*/\1/' \
    | while IFS= read -r action; do
        case "$action" in
            ./*|docker://*) continue ;;
        esac
        printf '%s\n' "$action" | grep -Eq '^[^@]+@[0-9a-f]{40}$' || {
            echo "FAIL: GitHub Action is not pinned to a full commit SHA: $action" >&2
            exit 1
        }
    done

if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$SHARED_HOOK" "$ISO_COMPAT_HOOK" "$PI_RUNNER" "$PROVISION" "$0"
fi

echo "Production contracts: PASS"