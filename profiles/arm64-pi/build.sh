#!/bin/sh
# Edemint arm64 Raspberry Pi build (§3).
#
# Pipeline: mmdebstrap (rootless-capable) under qemu-user-static + binfmt →
# in-chroot install of edemint-base/-desktop metapackages + raspi-firmware
# + linux-image-arm64 → run shared/hooks/normal/* → genimage assembles a
# FAT firmware partition + ext4 root → xz-compress.
#
# Requirements: amd64 Linux host with root + loop devices (mmdebstrap +
# genimage), and: mmdebstrap, qemu-user-static, binfmt-support, genimage,
# parted, mtools, e2fsprogs, dosfstools, xz-utils, equivs (for metapackages).
#
# Usage:
#   sudo ./profiles/arm64-pi/build.sh           # full build → *.img.xz
#   sudo ./profiles/arm64-pi/build.sh clean     # remove build/ dir

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
need_pkgs=""
for cmd in mmdebstrap qemu-aarch64-static genimage parted mkfs.vfat mkfs.ext4 xz equivs-build gpg curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        case "$cmd" in
            mmdebstrap)       need_pkgs="$need_pkgs mmdebstrap" ;;
            qemu-aarch64-static) need_pkgs="$need_pkgs qemu-user-static binfmt-support" ;;
            genimage)         need_pkgs="$need_pkgs genimage" ;;
            parted)           need_pkgs="$need_pkgs parted" ;;
            mkfs.vfat)        need_pkgs="$need_pkgs dosfstools mtools" ;;
            mkfs.ext4)        need_pkgs="$need_pkgs e2fsprogs" ;;
            xz)               need_pkgs="$need_pkgs xz-utils" ;;
            equivs-build)     need_pkgs="$need_pkgs equivs" ;;
            gpg)              need_pkgs="$need_pkgs gnupg" ;;
            curl)             need_pkgs="$need_pkgs curl" ;;
        esac
    fi
done
if [ -n "$need_pkgs" ]; then
    echo ">> installing host build deps:$need_pkgs"
    apt-get update
    # shellcheck disable=SC2086  # word splitting is intentional here
    apt-get install -y $need_pkgs
fi

# --- 1. build the equivs metapackages and stash them ---------------------
echo ">> building edemint metapackages..."
mkdir -p "$BUILD_DIR/packages.chroot"
EDEMINT_PI_PKG_DROP="$BUILD_DIR/packages.chroot" \
    "$REPO_ROOT/packaging/build-metapackages.sh"
# build-metapackages.sh always writes to amd64; copy from there.
cp "$REPO_ROOT/profiles/amd64-iso/config/packages.chroot/"*.deb \
   "$BUILD_DIR/packages.chroot/" 2>/dev/null || true

# --- 2. build the arm64 rootfs with mmdebstrap ---------------------------
echo ">> bootstrapping arm64 Trixie rootfs (this fetches packages)..."
rm -rf "$ROOTFS_DIR"
mkdir -p "$ROOTFS_DIR" "$IMAGES_DIR" "$TMP_DIR"

# Combine the shared base list (no installer.list — ISO-only) with the
# Pi-specific list. Strip comments/blank lines, join with spaces.
PKG_LIST="$(
    cat "$REPO_ROOT"/shared/package-lists/*.list.chroot \
        "$PROFILE_DIR"/package-lists/*.list.chroot \
    | grep -vE '^\s*(#|$)' \
    | tr '\n' ' '
)"

# mmdebstrap evaluates $1 inside the chroot hook; keep those bits
# single-quoted so the host shell doesn't expand them.
# `sync-in` copies the contents of the host path INTO the named chroot
# directory (rsync-like), which is what we want for both includes and
# hooks. copy-in's semantics are subtly different — sync-in is correct.
#
# Keyring: mmdebstrap is strict and aborts if it can't verify Trixie's
# InRelease signature (NO_PUBKEY 6ED0E7B8... etc). Ubuntu hosts (GitHub
# Actions ubuntu-latest) ship a debian-archive-keyring that PREDATES
# Debian 13's 2025 archive keys, so the packaged keyring is useless here.
# Fetch the authoritative Debian 13 keys straight from ftp-master over
# HTTPS and dearmor them into a binary keyring mmdebstrap/gpgv can use.
DEBIAN_KEYRING="$BUILD_DIR/debian-trixie-keyring.gpg"
build_trixie_keyring() {
    keydir="$BUILD_DIR/keys"
    mkdir -p "$keydir"
    : > "$keydir/all.asc"
    got=0
    for k in archive-key-13.asc archive-key-13-security.asc release-13.asc; do
        if curl -fsSL "https://ftp-master.debian.org/keys/$k" >> "$keydir/all.asc" 2>/dev/null; then
            got=1
        fi
    done
    [ "$got" -eq 1 ] || return 1
    gpg --dearmor < "$keydir/all.asc" > "$DEBIAN_KEYRING" 2>/dev/null || return 1
    [ -s "$DEBIAN_KEYRING" ]
}
echo ">> assembling Debian 13 archive keyring from ftp-master.debian.org..."
if ! build_trixie_keyring; then
    echo ">> ftp-master fetch failed; falling back to host debian-archive-keyring."
    command -v gpg >/dev/null 2>&1 || apt-get install -y gnupg
    apt-get install -y debian-archive-keyring 2>/dev/null || true
    DEBIAN_KEYRING=/usr/share/keyrings/debian-archive-keyring.gpg
fi
[ -s "$DEBIAN_KEYRING" ] || { echo "no usable Debian keyring"; exit 1; }

# shellcheck disable=SC2016
mmdebstrap \
    --arch=arm64 \
    --keyring="$DEBIAN_KEYRING" \
    --components="main contrib non-free non-free-firmware" \
    --include="$PKG_LIST" \
    --customize-hook='chroot "$1" mkdir -p /var/cache/edemint /usr/local/share/edemint-hooks' \
    --customize-hook='sync-in '"$BUILD_DIR"'/packages.chroot /var/cache/edemint' \
    --customize-hook='chroot "$1" sh -c "dpkg -i /var/cache/edemint/*.deb || apt-get -y -f install"' \
    --customize-hook='sync-in '"$REPO_ROOT"'/shared/includes /' \
    --customize-hook='sync-in '"$PROFILE_DIR"'/includes /' \
    --customize-hook='sync-in '"$REPO_ROOT"'/shared/hooks/normal /usr/local/share/edemint-hooks' \
    --customize-hook='chroot "$1" sh -c "for h in /usr/local/share/edemint-hooks/*.hook.chroot; do echo running $h; sh \"$h\" || true; done"' \
    --customize-hook='chroot "$1" sh -c "systemctl enable edemint-firstboot-growfs.service ssh.service || true"' \
    trixie \
    "$ROOTFS_DIR" \
    'http://deb.debian.org/debian'

# --- 3. Pi firmware boot files -------------------------------------------
# raspi-firmware lays files under /usr/lib/raspi-firmware; the package
# itself, if installed in the rootfs, populates /boot/firmware. The hooks
# above already ran, so /boot/firmware should be set up. Ensure config.txt
# + cmdline.txt are present.
mkdir -p "$ROOTFS_DIR/boot/firmware"
if [ ! -f "$ROOTFS_DIR/boot/firmware/config.txt" ]; then
    cp "$PROFILE_DIR/boot/config.txt"  "$ROOTFS_DIR/boot/firmware/config.txt"
fi
if [ ! -f "$ROOTFS_DIR/boot/firmware/cmdline.txt" ]; then
    cp "$PROFILE_DIR/boot/cmdline.txt" "$ROOTFS_DIR/boot/firmware/cmdline.txt"
fi

# --- 4. genimage: build firmware partition + root partition --------------
echo ">> assembling image..."
GENIMAGE_TMP="$TMP_DIR/genimage"
rm -rf "$GENIMAGE_TMP"
mkdir -p "$GENIMAGE_TMP"

# Split rootfs into a boot/firmware staging dir + the rest (genimage wants
# the boot partition contents as a directory).
BOOT_STAGE="$TMP_DIR/boot-firmware"
rm -rf "$BOOT_STAGE"
mkdir -p "$BOOT_STAGE"
cp -a "$ROOTFS_DIR/boot/firmware/." "$BOOT_STAGE/"

genimage \
    --config "$PROFILE_DIR/genimage.cfg" \
    --rootpath "$ROOTFS_DIR" \
    --tmppath "$GENIMAGE_TMP" \
    --inputpath "$BOOT_STAGE" \
    --outputpath "$IMAGES_DIR"

# --- 5. compress --------------------------------------------------------
echo ">> compressing..."
xz -T0 -9e -f "$IMAGES_DIR/$IMG_NAME"
ls -lh "$IMAGES_DIR/$IMG_NAME.xz"
echo ">> done: $IMAGES_DIR/$IMG_NAME.xz"
