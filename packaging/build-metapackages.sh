#!/bin/sh
# Build Edemint equivs metapackages and drop the .debs where each profile's
# build pipeline can pick them up as local packages.
#
# Inputs:  packaging/<pkg>/control (with a @DEPS@ marker)
#          shared/package-lists/<list>.list.chroot (one package per line)
# Outputs: profiles/amd64-iso/config/packages.chroot/<pkg>_<ver>_all.deb
#          profiles/arm64-pi/build/packages.chroot/<pkg>_<ver>_all.deb (if dir exists)
#
# Usage:   packaging/build-metapackages.sh

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$ROOT/packaging"
LISTS="$ROOT/shared/package-lists"
AMD64_DROP="$ROOT/profiles/amd64-iso/config/packages.chroot"
PI_DROP="$ROOT/profiles/arm64-pi/build/packages.chroot"

if ! command -v equivs-build >/dev/null 2>&1; then
    echo "equivs-build not found. Install: apt-get install -y equivs" >&2
    exit 1
fi

# pkg_name, list_basename
build_one() {
    pkg="$1"
    list="$2"

    pkg_dir="$PKG_DIR/$pkg"
    list_file="$LISTS/$list.list.chroot"
    [ -f "$pkg_dir/control" ] || { echo "missing $pkg_dir/control" >&2; exit 1; }
    [ -f "$list_file" ]       || { echo "missing $list_file" >&2; exit 1; }

    # Render comma-separated, single-line Depends from the list file
    # (strip comments + blank lines).
    deps="$(grep -vE '^\s*(#|$)' "$list_file" | paste -sd, - | sed 's/,/, /g')"

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    sed "s|@DEPS@|$deps|" "$pkg_dir/control" > "$tmp/control"

    (cd "$tmp" && equivs-build control >/dev/null)
    deb="$(find "$tmp" -maxdepth 1 -name "${pkg}_*_all.deb" | head -1)"
    [ -n "$deb" ] || { echo "equivs-build produced no .deb for $pkg" >&2; exit 1; }

    mkdir -p "$AMD64_DROP"
    cp "$deb" "$AMD64_DROP/"
    if [ -d "$(dirname "$PI_DROP")" ]; then
        mkdir -p "$PI_DROP"
        cp "$deb" "$PI_DROP/"
    fi
    echo ">> built $(basename "$deb")"

    rm -rf "$tmp"
    trap - EXIT
}

build_one edemint-base    base
build_one edemint-desktop desktop
