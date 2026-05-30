#!/bin/sh
# Build Edemint equivs metapackages and drop the .debs under
# shared/includes/usr/share/edemint/metapackages/ — they ship via
# includes.chroot to BOTH targets, and the late 0900-install-metapackages
# hook installs them with dpkg -i (deps already satisfied by the
# *.list.chroot installs that ran earlier).
#
# Why not config/packages.chroot/?  live-build builds an internal
# signed local-apt-archive for any .deb dropped under that path, and
# the signing step needs gpg --gen-key, which needs a TTY/pinentry —
# the chroot has neither, so the build dies with:
#   gpg: agent_genkey failed: Inappropriate ioctl for device
# Bypassing the local-archive avoids the whole class of failure.
#
# Inputs:  packaging/<pkg>/control (with a @DEPS@ marker)
#          shared/package-lists/<list>.list.chroot (one package per line)
# Output:  shared/includes/usr/share/edemint/metapackages/<pkg>_<ver>_all.deb

set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$ROOT/packaging"
LISTS="$ROOT/shared/package-lists"
DROP="$ROOT/shared/includes/usr/share/edemint/metapackages"

if ! command -v equivs-build >/dev/null 2>&1; then
    echo "equivs-build not found. Install: apt-get install -y equivs" >&2
    exit 1
fi

mkdir -p "$DROP"

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
    # equivs-build copies the control into its OWN internal build dir
    # under $TMPDIR and writes the resulting .deb to $TMPDIR itself, not
    # to the user's cwd. Override $TMPDIR so its output lands under $tmp.
    mkdir "$tmp/work" "$tmp/out"
    trap 'rm -rf "$tmp"' EXIT
    sed "s|@DEPS@|$deps|" "$pkg_dir/control" > "$tmp/work/control"

    (cd "$tmp/work" && TMPDIR="$tmp/out" equivs-build control >/dev/null)
    deb="$(find "$tmp" -name "${pkg}_*_all.deb" | head -1)"
    [ -n "$deb" ] || { echo "equivs-build produced no .deb for $pkg" >&2; exit 1; }

    cp "$deb" "$DROP/"
    echo ">> built $(basename "$deb") -> $DROP"

    rm -rf "$tmp"
    trap - EXIT
}

build_one edemint-base    base
build_one edemint-desktop desktop
build_one edemint-ai      ai
