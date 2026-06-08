#!/bin/sh
# Edemint arm64 Raspberry Pi build (§3).
#
# Pipeline: mmdebstrap (rootless-capable) under qemu-user-static + binfmt →
# in-chroot install of edemint-base/-desktop metapackages + raspi-firmware
# + linux-image-arm64 → run shared/hooks/normal/* → genimage assembles a
# FAT firmware partition + ext4 root → zstd-compress.
#
# Requirements: a Linux host with root + loop devices (mmdebstrap +
# genimage), and: mmdebstrap, genimage, parted, mtools, e2fsprogs,
# dosfstools, zstd, equivs, and debian-archive-keyring. On a non-arm64 host
# add qemu-user-static + binfmt-support.
#
# Usage:
#   sudo ./profiles/arm64-pi/build.sh
#   sudo ./profiles/arm64-pi/build.sh clean

set -e

PROFILE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$PROFILE_DIR/../.." && pwd)"
BUILD_DIR="$PROFILE_DIR/build"
ROOTFS_DIR="$BUILD_DIR/rootfs"
IMAGES_DIR="$BUILD_DIR/images"
TMP_DIR="$BUILD_DIR/tmp"
VERSION="${EDEMINT_VERSION:-0.1}"
IMG_NAME="edemint-${VERSION}-arm64-rpi.img"

if [ "${1:-}" = "clean" ]; then
    rm -rf "$BUILD_DIR"
    echo ">> cleaned $BUILD_DIR"
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Pi build needs root (mmdebstrap + genimage + loop devices)." >&2
    echo "Re-run with: sudo $0" >&2
    exit 1
fi

# --- 0. install host build deps if missing -------------------------------
HOST_ARCH="$(dpkg --print-architecture 2>/dev/null || echo unknown)"
if [ "$HOST_ARCH" = "arm64" ]; then
    echo ">> native arm64 host — building without qemu (fast path)"
else
    echo ">> cross-building arm64 on '$HOST_ARCH' — using qemu-user-static"
fi

need_pkgs=""
for cmd in mmdebstrap genimage parted mkfs.vfat mkfs.ext4 zstd equivs-build; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        case "$cmd" in
            mmdebstrap)   need_pkgs="$need_pkgs mmdebstrap" ;;
            genimage)     need_pkgs="$need_pkgs genimage" ;;
            parted)       need_pkgs="$need_pkgs parted" ;;
            mkfs.vfat)    need_pkgs="$need_pkgs dosfstools mtools" ;;
            mkfs.ext4)    need_pkgs="$need_pkgs e2fsprogs" ;;
            zstd)         need_pkgs="$need_pkgs zstd" ;;
            equivs-build) need_pkgs="$need_pkgs equivs" ;;
        esac
    fi
done
if [ ! -s /usr/share/keyrings/debian-archive-keyring.gpg ]; then
    need_pkgs="$need_pkgs debian-archive-keyring"
fi
if [ "$HOST_ARCH" != "arm64" ] && ! command -v qemu-aarch64-static >/dev/null 2>&1; then
    need_pkgs="$need_pkgs qemu-user-static binfmt-support"
fi
if [ -n "$need_pkgs" ]; then
    echo ">> installing host build deps:$need_pkgs"
    apt-get update
    # shellcheck disable=SC2086
    apt-get install -y $need_pkgs
fi

# The archive trust root must come from the host distribution package. Do not
# fetch loose release keys during a build: that makes the trust input mutable
# and bypasses package-manager provenance. CI installs debian-archive-keyring
# before invoking this script; custom builders may override the path only with
# an existing local keyring file.
DEBIAN_KEYRING="${EDEMINT_DEBIAN_KEYRING:-/usr/share/keyrings/debian-archive-keyring.gpg}"
[ -s "$DEBIAN_KEYRING" ] || {
    echo "missing packaged Debian archive keyring: $DEBIAN_KEYRING" >&2
    echo "install debian-archive-keyring or set EDEMINT_DEBIAN_KEYRING" >&2
    exit 1
}
echo ">> Debian archive keyring: $DEBIAN_KEYRING"
if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W -f='>> debian-archive-keyring package: ${Version}\n' \
        debian-archive-keyring 2>/dev/null || true
fi
sha256sum "$DEBIAN_KEYRING"

# --- 1. build the equivs metapackages -----------------------------------
echo ">> building edemint metapackages..."
"$REPO_ROOT/packaging/build-metapackages.sh"

# --- 2. build the arm64 rootfs with mmdebstrap ---------------------------
echo ">> bootstrapping arm64 Trixie rootfs (this fetches packages)..."
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR" "$IMAGES_DIR" "$TMP_DIR"

PKG_LIST="$(
    awk '
        {
            sub(/[[:space:]]*#.*/, "")
            if ($0 ~ /[^[:space:]]/) {
                print $1
            }
        }
    ' "$REPO_ROOT"/shared/package-lists/*.list.chroot \
      "$PROFILE_DIR"/package-lists/*.list.chroot \
    | tr '\n' ' '
)"

APT_CACHE="$BUILD_DIR/apt-cache"
mkdir -p "$APT_CACHE"
cached_in=$(find "$APT_CACHE" -maxdepth 1 -name '*.deb' 2>/dev/null | wc -l)
echo ">> apt-cache: seeding $cached_in cached .debs into chroot"

# shellcheck disable=SC2016
mmdebstrap \
    --arch=arm64 \
    --keyring="$DEBIAN_KEYRING" \
    --components="main contrib non-free non-free-firmware" \
    --include="$PKG_LIST" \
    --aptopt='Acquire::Languages "none"' \
    --aptopt='APT::Install-Recommends "false"' \
    --aptopt='APT::Install-Suggests "false"' \
    --aptopt='APT::Keep-Downloaded-Packages "true"' \
    --aptopt='Acquire::http::Pipeline-Depth "10"' \
    --aptopt='Acquire::Retries "5"' \
    --dpkgopt='force-unsafe-io' \
    --dpkgopt='path-exclude=/usr/share/man/*' \
    --dpkgopt='path-exclude=/usr/share/groff/*' \
    --dpkgopt='path-exclude=/usr/share/info/*' \
    --dpkgopt='path-exclude=/usr/share/lintian/*' \
    --dpkgopt='path-exclude=/usr/share/doc/*' \
    --dpkgopt='path-include=/usr/share/doc/*/copyright' \
    --essential-hook='chroot "$1" mkdir -p /var/cache/apt/archives /etc/initramfs-tools/conf.d /etc/flash-kernel /etc/default' \
    --essential-hook='sync-in '"$APT_CACHE"' /var/cache/apt/archives' \
    --essential-hook='copy-in '"$REPO_ROOT"'/shared/includes/etc/initramfs-tools/conf.d/edemint.conf /etc/initramfs-tools/conf.d/' \
    --essential-hook='copy-in '"$PROFILE_DIR"'/includes/etc/flash-kernel/machine /etc/flash-kernel/' \
    --essential-hook='copy-in '"$PROFILE_DIR"'/includes/etc/default/flash-kernel /etc/default/' \
    --essential-hook='chroot "$1" dpkg-divert --rename --quiet --add /usr/sbin/flash-kernel' \
    --essential-hook='ln -s /bin/true "$1/usr/sbin/flash-kernel"' \
    --customize-hook='chroot "$1" mkdir -p /usr/local/share/edemint-hooks' \
    --customize-hook='sync-in '"$REPO_ROOT"'/shared/includes /' \
    --customize-hook='sync-in '"$PROFILE_DIR"'/includes /' \
    --customize-hook='sync-in '"$REPO_ROOT"'/shared/hooks/normal /usr/local/share/edemint-hooks' \
    --customize-hook='copy-in '"$PROFILE_DIR"'/scripts/edemint-run-hooks /usr/local/sbin/' \
    --customize-hook='chroot "$1" sh /usr/local/sbin/edemint-run-hooks' \
    --customize-hook='chroot "$1" sh -c "systemctl enable edemint-firstboot-growfs.service edemint-flash-kernel-fixup.service ssh.service || true"' \
    --customize-hook='rm -f "$1/usr/sbin/flash-kernel"' \
    --customize-hook='chroot "$1" dpkg-divert --rename --quiet --remove /usr/sbin/flash-kernel' \
    --customize-hook='copy-in '"$PROFILE_DIR"'/scripts/seed-boot-firmware /usr/local/sbin/' \
    --customize-hook='chroot "$1" sh /usr/local/sbin/seed-boot-firmware' \
    --customize-hook='sync-out /var/cache/apt/archives '"$APT_CACHE" \
    trixie \
    "$ROOTFS_DIR" \
    'http://deb.debian.org/debian'

rm -rf "$APT_CACHE/partial" 2>/dev/null || true
cached_out=$(find "$APT_CACHE" -maxdepth 1 -name '*.deb' 2>/dev/null | wc -l)
if [ "${EDEMINT_KEEP_APT_CACHE:-0}" = "1" ]; then
    echo ">> apt-cache: $cached_out .debs saved for next run"
else
    rm -rf "$APT_CACHE"
    echo ">> apt-cache: removed $cached_out cached .debs to reduce CI disk pressure"
fi

# --- 3. Pi firmware boot files -------------------------------------------
mkdir -p "$ROOTFS_DIR/boot/firmware"
cp -f "$PROFILE_DIR/boot/config.txt"  "$ROOTFS_DIR/boot/firmware/config.txt"
cp -f "$PROFILE_DIR/boot/cmdline.txt" "$ROOTFS_DIR/boot/firmware/cmdline.txt"

# --- 4. genimage: build firmware partition + root partition --------------
echo ">> assembling image..."
GENIMAGE_TMP="$TMP_DIR/genimage"
rm -rf "$GENIMAGE_TMP"
mkdir -p "$GENIMAGE_TMP"

BOOT_IMG="$TMP_DIR/boot.vfat"
dd if=/dev/zero of="$BOOT_IMG" bs=1M count=512 status=none
mkfs.vfat -F 32 -n FIRMWARE "$BOOT_IMG"
BOOT_MNT="$TMP_DIR/boot-mnt"
mkdir -p "$BOOT_MNT"
mount -o loop "$BOOT_IMG" "$BOOT_MNT"
cp -a "$ROOTFS_DIR/boot/firmware/." "$BOOT_MNT/"
sync
umount "$BOOT_MNT"
echo ">> boot.vfat: $(find "$ROOTFS_DIR/boot/firmware" -type f | wc -l) firmware files"

ROOT_KB="$(du -sk "$ROOTFS_DIR" | awk '{print $1}')"
ROOT_SIZE_MB="$(( ROOT_KB * 130 / 100 / 1024 + 512 ))"
[ "$ROOT_SIZE_MB" -lt 4096 ] && ROOT_SIZE_MB=4096
echo ">> rootfs is ${ROOT_KB} KB; sizing ext4 root to ${ROOT_SIZE_MB}M"

GENIMAGE_CFG="$TMP_DIR/genimage.cfg"
sed -e "s|edemint-0\.1-arm64-rpi\.img|$IMG_NAME|g" \
    -e "s|size = 5G|size = ${ROOT_SIZE_MB}M|" \
    "$PROFILE_DIR/genimage.cfg" > "$GENIMAGE_CFG"

genimage \
    --config "$GENIMAGE_CFG" \
    --rootpath "$ROOTFS_DIR" \
    --tmppath "$GENIMAGE_TMP" \
    --inputpath "$TMP_DIR" \
    --outputpath "$IMAGES_DIR"

echo ">> freeing build scratch before compression..."
rm -rf "$ROOTFS_DIR" "$TMP_DIR"

# --- 5. compress --------------------------------------------------------
echo ">> compressing (zstd -12, multithreaded)..."
zstd -T0 -12 -f --rm "$IMAGES_DIR/$IMG_NAME"
ls -lh "$IMAGES_DIR/$IMG_NAME.zst"
echo ">> done: $IMAGES_DIR/$IMG_NAME.zst"
