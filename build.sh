#!/bin/sh
# Edemint image builder — dispatcher.
#
# Builds per-target images from one shared package set / config tree.
# Targets live under profiles/<target>/ and share shared/{package-lists,
# includes,hooks} via symlinks (amd64-iso) or by copy (arm64-pi).
#
# Usage:
#   sudo ./build.sh amd64       # live-build -> live-image-amd64.hybrid.iso
#   sudo ./build.sh pi          # mmdebstrap+genimage -> edemint-*-arm64-rpi.img.xz
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
            for cfg in config/binary config/common; do
                [ -f "$cfg" ] || continue
                if grep -q '^LB_DEBIAN_INSTALLER=' "$cfg"; then
                    sed -i 's|^LB_DEBIAN_INSTALLER=.*|LB_DEBIAN_INSTALLER="none"|' "$cfg"
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
            echo ">> forced LB_DEBIAN_INSTALLER=none (Calamares is the installer)"
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
