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
