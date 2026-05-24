#!/bin/sh
# Edemint image builder.
# Produces a bootable amd64 live ISO using Debian live-build.
#
# Requirements: a Debian/Ubuntu host, root (for debootstrap), ~10GB free disk,
# and network access to deb.debian.org.
#
# Usage:
#   sudo ./build.sh          # full build -> live-image-amd64.hybrid.iso
#   sudo ./build.sh clean    # remove build artifacts

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "This build needs root (debootstrap). Re-run with: sudo ./build.sh" >&2
    exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
    echo ">> live-build not found; installing it..."
    apt-get update
    apt-get install -y live-build
fi

if [ "$1" = "clean" ]; then
    lb clean --purge
    echo ">> cleaned."
    exit 0
fi

echo ">> configuring (auto/config)..."
lb config

echo ">> building image (this takes a while and needs network)..."
lb build

echo ">> done. Look for the *.iso in this directory."
ls -lh ./*.iso 2>/dev/null || true
