#!/bin/sh
# Edemint arm64 Raspberry Pi build (§3).
#
# Pipeline: mmdebstrap (rootless-capable) under qemu-user-static + binfmt →
# in-chroot install of edemint-base/-desktop metapackages + raspi-firmware
# + linux-image-arm64 → run shared/hooks/normal/* → genimage assembles a
# FAT firmware partition + ext4 root → xz-compress.
#
# Requirements: a Linux host with root + loop devices (mmdebstrap +
# genimage), and: mmdebstrap, genimage, parted, mtools, e2fsprogs,
# dosfstools, zstd, equivs (for metapackages). On a non-arm64 host add
# qemu-user-static + binfmt-support (the script installs them automatically);
# on a native arm64 host they are not needed and the build is ~4x faster.
#
# Usage:
#   sudo ./profiles/arm64-pi/build.sh           # full build → *.img.zst
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
# A native arm64 host (e.g. a GitHub `ubuntu-24.04-arm` runner) runs the
# arm64 chroot WITHOUT qemu — package postinst scripts execute natively
# instead of under slow TCG emulation. That emulation is the single biggest
# Pi-build cost, so the native path is roughly 4x faster end to end. We only
# pull qemu-user-static when actually cross-building from a non-arm64 host;
# mmdebstrap's `--arch=arm64` is correct either way.
HOST_ARCH="$(dpkg --print-architecture 2>/dev/null || echo unknown)"
if [ "$HOST_ARCH" = "arm64" ]; then
    echo ">> native arm64 host — building without qemu (fast path)"
else
    echo ">> cross-building arm64 on '$HOST_ARCH' — using qemu-user-static (slow path)"
fi

need_pkgs=""
for cmd in mmdebstrap genimage parted mkfs.vfat mkfs.ext4 zstd equivs-build gpg curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        case "$cmd" in
            mmdebstrap)       need_pkgs="$need_pkgs mmdebstrap" ;;
            genimage)         need_pkgs="$need_pkgs genimage" ;;
            parted)           need_pkgs="$need_pkgs parted" ;;
            mkfs.vfat)        need_pkgs="$need_pkgs dosfstools mtools" ;;
            mkfs.ext4)        need_pkgs="$need_pkgs e2fsprogs" ;;
            zstd)             need_pkgs="$need_pkgs zstd" ;;
            equivs-build)     need_pkgs="$need_pkgs equivs" ;;
            gpg)              need_pkgs="$need_pkgs gnupg" ;;
            curl)             need_pkgs="$need_pkgs curl" ;;
        esac
    fi
done
# Cross-build only: the qemu-aarch64 binfmt handler must be registered.
if [ "$HOST_ARCH" != "arm64" ] && ! command -v qemu-aarch64-static >/dev/null 2>&1; then
    need_pkgs="$need_pkgs qemu-user-static binfmt-support"
fi
if [ -n "$need_pkgs" ]; then
    echo ">> installing host build deps:$need_pkgs"
    apt-get update
    # shellcheck disable=SC2086  # word splitting is intentional here
    apt-get install -y $need_pkgs
fi

# --- 1. build the equivs metapackages -----------------------------------
# The script drops .debs under shared/includes/usr/share/edemint/
# metapackages/, which the sync-in shared/includes hook below carries
# into the chroot. The 0900-install-metapackages hook then dpkg -i's
# them. No more per-target packages.chroot/ copy.
echo ">> building edemint metapackages..."
"$REPO_ROOT/packaging/build-metapackages.sh"

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

# apt-archives cache. mmdebstrap downloads .debs into /var/cache/apt/
# archives inside the chroot; we save them to the host so the 2nd+ CI
# run skips most of the apt download phase. APT::Keep-Downloaded-
# Packages keeps the .debs around (mmdebstrap's default cleans them).
# essential-hook seeds the chroot from cache before "installing
# remaining packages"; the trailing customize-hook copies back out.
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

# sync-out may have brought back the partial/ subdir; drop it.
rm -rf "$APT_CACHE/partial" 2>/dev/null || true
cached_out=$(find "$APT_CACHE" -maxdepth 1 -name '*.deb' 2>/dev/null | wc -l)
echo ">> apt-cache: $cached_out .debs saved for next run"

# --- 3. Pi firmware boot files -------------------------------------------
# raspi-firmware populates /boot/firmware; our config.txt/cmdline.txt must
# always take precedence over the package defaults (raspi-firmware ships its
# own versions, so the old `if [ ! -f ]` guard silently dropped ours).
mkdir -p "$ROOTFS_DIR/boot/firmware"
cp -f "$PROFILE_DIR/boot/config.txt"  "$ROOTFS_DIR/boot/firmware/config.txt"
cp -f "$PROFILE_DIR/boot/cmdline.txt" "$ROOTFS_DIR/boot/firmware/cmdline.txt"

# --- 4. genimage: build firmware partition + root partition --------------
echo ">> assembling image..."
GENIMAGE_TMP="$TMP_DIR/genimage"
rm -rf "$GENIMAGE_TMP"
mkdir -p "$GENIMAGE_TMP"

# Build a complete FAT image with ALL files from /boot/firmware.
# genimage.cfg has no 'image boot.vfat {}' block so genimage reads
# this pre-built file from --inputpath instead of building its own
# (which could only enumerate files statically).
# Loop-mount is reliable for root builds and avoids mtools quoting issues.
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

# Size the ext4 root to the ACTUAL rootfs + 30% headroom (min 4G). The cfg
# ships a 5G default, but the populated desktop rootfs (firmware-misc-nonfree
# alone is ~1GB, plus Firefox/GNOME/fonts-noto/ffmpeg/fcitx5-mozc) can exceed
# that, and genimage's `mke2fs -d` aborts when content overflows a fixed
# size. firstboot-growfs expands the partition to the card on first boot, so
# this only needs to hold the shipped content, not the final disk.
ROOT_KB="$(du -sk "$ROOTFS_DIR" | awk '{print $1}')"
ROOT_SIZE_MB="$(( ROOT_KB * 130 / 100 / 1024 + 512 ))"
[ "$ROOT_SIZE_MB" -lt 4096 ] && ROOT_SIZE_MB=4096
echo ">> rootfs is ${ROOT_KB} KB; sizing ext4 root to ${ROOT_SIZE_MB}M"

# genimage.cfg names its output image edemint-0.1-arm64-rpi.img and sets a
# placeholder 5G root size. For a versioned build (EDEMINT_VERSION != 0.1)
# the name must track IMG_NAME, or the xz step below looks for a file
# genimage never wrote. Template a copy of the cfg with the real name + size.
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

# --- 5. compress --------------------------------------------------------
# zstd -T0 over xz: multithreaded zstd at -12 packs a multi-GB image in
# tens of seconds (xz -3 took minutes) at a comparable ratio. The level is
# the speed/size knob — raise toward -19 for smaller downloads, lower for a
# faster build. .img.zst flashes with `zstd -dc img.zst | dd ...` and via
# current Raspberry Pi Imager / balenaEtcher builds.
echo ">> compressing (zstd -12, multithreaded)..."
zstd -T0 -12 -f --rm "$IMAGES_DIR/$IMG_NAME"
ls -lh "$IMAGES_DIR/$IMG_NAME.zst"
echo ">> done: $IMAGES_DIR/$IMG_NAME.zst"
