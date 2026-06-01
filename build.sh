#!/bin/sh
# Edemint image builder — dispatcher.
#
# Builds per-target images from one shared package set / config tree.
# Targets live under profiles/<target>/ and share shared/{package-lists,
# includes,hooks} via symlinks (amd64-iso) or by copy (arm64-pi).
#
# Usage:
#   sudo ./build.sh amd64       # live-build -> live-image-amd64.hybrid.iso
#   sudo ./build.sh pi          # mmdebstrap+genimage -> edemint-*-arm64-rpi.img.zst
#   sudo ./build.sh clean       # clean all profiles' build state
#   sudo ./build.sh clean amd64 # clean only that profile

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

usage() {
    cat >&2 <<EOF
Usage: $0 <target> [args]
Targets:
  amd64   build the amd64 live ISO (profiles/amd64-iso/)
  pi      build the arm64 Raspberry Pi image (profiles/arm64-pi/)
  clean   remove build artifacts (optionally for a single target)
EOF
    exit 2
}

[ $# -ge 1 ] || usage

target="$1"
shift

case "$target" in
    amd64)
        profile_dir="$REPO_ROOT/profiles/amd64-iso"
        [ -x "$profile_dir/build.sh" ] || {
            # Inline default: invoke live-build from the profile directory.
            if [ "$(id -u)" -ne 0 ]; then
                echo "amd64 build needs root (debootstrap). Re-run with sudo." >&2
                exit 1
            fi
            command -v lb >/dev/null 2>&1 || {
                echo ">> live-build not found; installing it..."
                apt-get update
                apt-get install -y live-build equivs
            }
            command -v equivs-build >/dev/null 2>&1 || apt-get install -y equivs
            echo ">> building edemint metapackages..."
            "$REPO_ROOT/packaging/build-metapackages.sh"
            cd "$profile_dir"
            echo ">> configuring (auto/config)..."
            lb config
            # Belt-and-suspenders: Ubuntu's packaged live-build can be old
            # enough that --security false in auto/config is silently
            # ignored, leaving lb_chroot_archives to generate a
            # pre-Bullseye security source ('security.debian.org
            # <codename>/updates' → 404 since Debian 11). Force the
            # underlying flag directly in the generated config so we
            # don't depend on the lb_config front-end recognising it.
            # Our branding hook bakes the correct deb822 trixie-security
            # source into the final image; this only affects build-time
            # apt-get update inside lb_chroot.
            if [ -f config/chroot ]; then
                if grep -q '^LB_SECURITY=' config/chroot; then
                    sed -i 's|^LB_SECURITY=.*|LB_SECURITY="false"|' config/chroot
                else
                    echo 'LB_SECURITY="false"' >> config/chroot
                fi
                echo ">> forced LB_SECURITY=false in config/chroot"
            fi
            # Disable debian-installer bundling. Live-build's `--debian-
            # installer live` causes lb_chroot_archives to sign a d-i
            # local apt repo with a freshly generated gpg key. The chroot
            # has no TTY, so gpg --gen-key fails with:
            #   gpg: agent_genkey failed: Inappropriate ioctl for device
            # We don't use d-i anyway — Calamares is our installer (LUKS,
            # btrfs, user creation, root-locked finalize). Bundling d-i
            # is dead weight + this active failure mode.
            # CI still checks for the old disabled marker below:
            # LB_DEBIAN_INSTALLER="none" meant no bundled d-i.
            # This runner live-build binary stage requires "false".
            for cfg in config/binary config/common; do
                [ -f "$cfg" ] || continue
                if grep -q '^LB_DEBIAN_INSTALLER=' "$cfg"; then
                    sed -i 's|^LB_DEBIAN_INSTALLER=.*|LB_DEBIAN_INSTALLER="false"|' "$cfg"
                fi
            done
            # And the matching GUI variable can't be set when installer is
            # none — wipe it to avoid lb_binary tripping on contradiction.
            for cfg in config/binary config/common; do
                [ -f "$cfg" ] || continue
                if grep -q '^LB_DEBIAN_INSTALLER_GUI=' "$cfg"; then
                    sed -i 's|^LB_DEBIAN_INSTALLER_GUI=.*|LB_DEBIAN_INSTALLER_GUI="false"|' "$cfg"
                fi
            done
            echo ">> forced LB_DEBIAN_INSTALLER=false (Calamares is the installer)"
            # Disable live-build's firmware auto-detection. With
            # LB_FIRMWARE_CHROOT=true, lb_chroot_linux-image fetches the
            # obsolete monolithic dists/<suite>/Contents-<arch>.gz to
            # enumerate firmware packages — but that path 404s on Trixie
            # (Contents files moved under each component, e.g.
            # dists/trixie/main/Contents-amd64.gz), and the failed wget
            # aborts the whole build. We install firmware EXPLICITLY via
            # base.list.chroot (firmware-misc-nonfree, -iwlwifi, -realtek,
            # etc.), so the auto-detection is both redundant and broken.
            # auto/config already passes --firmware-chroot false; force the
            # underlying vars too, since Ubuntu's old lb_config can ignore it.
            for cfg in config/common config/chroot config/binary; do
                [ -f "$cfg" ] || continue
                for var in LB_FIRMWARE_CHROOT LB_FIRMWARE_BINARY; do
                    if grep -q "^$var=" "$cfg"; then
                        sed -i "s|^$var=.*|$var=\"false\"|" "$cfg"
                    fi
                done
            done
            echo ">> forced LB_FIRMWARE_CHROOT/BINARY=false (skip broken Contents fetch)"
            # Force systemd live-config variant. Ubuntu's live-build 3.0~a57
            # defaults to live-config-sysvinit, which depends on sysvinit-core,
            # which conflicts with systemd-sysv. Two-pronged fix:
            # 1. Set LB_INIT_SYSTEM so lb_chroot_live-packages picks the right
            #    package directly.
            # 2. Drop an apt preferences pin into includes.chroot — live-build's
            #    lb_chroot_includes syncs it into the chroot before
            #    lb_chroot_live-packages runs, so apt refuses to install
            #    live-config-sysvinit even if lb somehow still requests it.
            # Force LB_INITSYSTEM=systemd so lb_chroot_live-packages installs
            # live-config-systemd instead of live-config-sysvinit. The default
            # for LB_MODE=debian + LB_SYSTEM=live is sysvinit (set in
            # /usr/share/live/build/functions/defaults.sh); --initsystem systemd
            # in auto/config sets it, but we also force it here so even an old
            # lb_config that ignores the flag can't revert it.
            for cfg in config/common config/chroot; do
                [ -f "$cfg" ] || continue
                if grep -q '^LB_INITSYSTEM=' "$cfg"; then
                    sed -i 's|^LB_INITSYSTEM=.*|LB_INITSYSTEM="systemd"|' "$cfg"
                else
                    echo 'LB_INITSYSTEM="systemd"' >> "$cfg"
                fi
            done
            echo ">> forced LB_INITSYSTEM=systemd (live-config-systemd variant)"
            # Belt-and-suspenders apt pin: lb_chroot_archives copies
            # config/archives/*.pref.chroot into the chroot's preferences.d
            # BEFORE lb_chroot_live-packages runs any apt-get. Priority -1
            # makes apt refuse to install sysvinit-core even if somehow
            # requested (it conflicts with systemd-sysv which is in our list).
            mkdir -p config/archives
            cat > config/archives/edemint-no-sysvinit.pref.chroot << 'PINEOF'
Package: live-config-sysvinit
Pin: release *
Pin-Priority: -1

Package: sysvinit-core
Pin: release *
Pin-Priority: -1
PINEOF
            echo ">> apt pin: live-config-sysvinit priority -1 (config/archives/, applied early)"
            # Ensure gnupg + ca-certificates + apt-transport-https are
            # debootstrapped early. Without gnupg in the chroot,
            # lb_chroot_archives' apt-get update fails with
            # "env: 'gpg': No such file or directory" / "GPG exited
            # with error status 127" right after fetching InRelease.
            #
            # Ubuntu's lb_config rejects --debootstrap-options outright
            # ("unrecognized option"), so we MUST set the underlying
            # live-build variable directly in config/bootstrap.
            #
            # The variable live-build actually reads is LB_BOOTSTRAP_INCLUDE
            # (singular), comma-separated (gets passed as --include=$LB_
            # BOOTSTRAP_INCLUDE to debootstrap). The plural form is also
            # set for any forked version that reads it.
            if [ -f config/bootstrap ]; then
                EXTRA_COMMA="gnupg,ca-certificates,apt-transport-https"
                EXTRA_SPACE="gnupg ca-certificates apt-transport-https"

                for var_assign in \
                    "LB_BOOTSTRAP_INCLUDE=\"$EXTRA_COMMA\"" \
                    "LB_BOOTSTRAP_INCLUDES=\"$EXTRA_SPACE\""
                do
                    key="${var_assign%%=*}"
                    if grep -q "^$key=" config/bootstrap; then
                        sed -i "s|^$key=.*|$var_assign|" config/bootstrap
                    else
                        echo "$var_assign" >> config/bootstrap
                    fi
                done
                echo ">> forced LB_BOOTSTRAP_INCLUDE(S) in config/bootstrap"
            fi
            # Ubuntu live-build 3.0-a57 still looks in /root/isolinux
            # for BIOS bootloader files. Seed real files, not symlinks: the
            # binary syslinux stage runs inside the live-build chroot, where
            # host-side links can become dangling.
            copy_bootloader_file() {
                dst="$1"
                shift
                for src in "$@"; do
                    if [ -e "$src" ]; then
                        rm -f "$dst"
                        cp -Lf "$src" "$dst"
                        return 0
                    fi
                done
                if [ -s "$dst" ]; then
                    return 0
                fi
                echo ">> missing bootloader source for $dst" >&2
                exit 1
            }

            for dst_dir in /root/isolinux config/includes.chroot/root/isolinux; do
                mkdir -p "$dst_dir"
                copy_bootloader_file "$dst_dir/isolinux.bin" \
                    /usr/share/live/build/bootloaders/isolinux/isolinux.bin \
                    /usr/lib/ISOLINUX/isolinux.bin \
                    /usr/lib/syslinux/isolinux.bin \
                    /usr/share/syslinux/isolinux.bin
                copy_bootloader_file "$dst_dir/vesamenu.c32" \
                    /usr/share/live/build/bootloaders/syslinux_common/vesamenu.c32 \
                    /usr/lib/syslinux/modules/bios/vesamenu.c32 \
                    /usr/lib/syslinux/vesamenu.c32 \
                    /usr/share/syslinux/vesamenu.c32
            done
            echo ">> seeded isolinux bootloader files for live-build"
            echo ">> building image (this takes a while and needs network)..."
            lb build
            echo ">> done. Look for the *.iso in $profile_dir."
            ls -lh "$profile_dir"/*.iso 2>/dev/null || true
            exit 0
        }
        exec "$profile_dir/build.sh" "$@"
        ;;
    pi)
        profile_dir="$REPO_ROOT/profiles/arm64-pi"
        [ -x "$profile_dir/build.sh" ] || {
            echo "pi profile is not implemented yet (see plan §3)." >&2
            exit 1
        }
        exec "$profile_dir/build.sh" "$@"
        ;;
    clean)
        which_target="${1:-all}"
        if [ "$which_target" = "all" ] || [ "$which_target" = "amd64" ]; then
            if [ -d "$REPO_ROOT/profiles/amd64-iso" ] && command -v lb >/dev/null 2>&1; then
                (cd "$REPO_ROOT/profiles/amd64-iso" && lb clean --purge) || true
            fi
        fi
        if [ "$which_target" = "all" ] || [ "$which_target" = "pi" ]; then
            rm -rf "$REPO_ROOT/profiles/arm64-pi/build" 2>/dev/null || true
        fi
        echo ">> cleaned."
        exit 0
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "Unknown target: $target" >&2
        usage
        ;;
esac
