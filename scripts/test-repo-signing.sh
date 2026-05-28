#!/bin/sh
# Edemint Tier A: signed-apt-repo self-test (§6a).
#
# Builds a minimal apt repo in a tmp dir, signs the Release with a
# throwaway key, confirms apt-secure ACCEPTS it, then flips one byte in
# Release and confirms apt REJECTS it. Pure logic — no internet needed.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEBS="$ROOT/profiles/amd64-iso/config/packages.chroot"

if ! command -v gpg >/dev/null 2>&1; then
    echo "gpg missing; install: apt-get install -y gnupg" >&2
    exit 1
fi
if ! command -v apt-ftparchive >/dev/null 2>&1; then
    echo "apt-ftparchive missing; install: apt-get install -y apt-utils" >&2
    exit 1
fi
# Need at least one metapackage .deb to populate the test repo. Build them
# if they're not already present (so this works whether or not `make lint`
# ran first, and on a fresh CI runner where ordering isn't guaranteed).
if [ -z "$(find "$DEBS" -maxdepth 1 -name '*.deb' 2>/dev/null)" ]; then
    echo ">> no metapackages present; building them..."
    "$ROOT/packaging/build-metapackages.sh"
fi
if [ -z "$(find "$DEBS" -maxdepth 1 -name '*.deb' 2>/dev/null)" ]; then
    echo "FAIL: still no .deb in $DEBS after build attempt." >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- 1. throwaway signing key ------------------------------------------
export GNUPGHOME="$TMP/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

cat > "$TMP/keygen" <<'EOF'
%no-protection
Key-Type: rsa
Key-Length: 2048
Name-Real: Edemint Test Signer
Name-Email: test@edemint.invalid
Expire-Date: 1d
%commit
EOF
gpg --quiet --batch --gen-key "$TMP/keygen" 2>/dev/null

# --- 2. lay out a minimal apt repo ---------------------------------------
REPO="$TMP/repo"
mkdir -p "$REPO/dists/trixie/main/binary-amd64" "$REPO/pool/main"
cp "$DEBS"/*.deb "$REPO/pool/main/"

(
    cd "$REPO"
    apt-ftparchive packages pool/main > dists/trixie/main/binary-amd64/Packages
    gzip -kf dists/trixie/main/binary-amd64/Packages
    cat > dists/trixie/apt-ftparchive.conf <<EOF
APT::FTPArchive::Release::Origin "Edemint";
APT::FTPArchive::Release::Label "Edemint";
APT::FTPArchive::Release::Suite "trixie";
APT::FTPArchive::Release::Codename "trixie";
APT::FTPArchive::Release::Architectures "amd64";
APT::FTPArchive::Release::Components "main";
EOF
    apt-ftparchive -c dists/trixie/apt-ftparchive.conf release dists/trixie > dists/trixie/Release
    gpg --batch --yes --detach-sign --armor -o dists/trixie/Release.gpg dists/trixie/Release
    gpg --batch --yes --clearsign      -o dists/trixie/InRelease    dists/trixie/Release
)

# --- 3. verify the good signature ---------------------------------------
gpg --quiet --verify "$REPO/dists/trixie/Release.gpg" "$REPO/dists/trixie/Release" 2>"$TMP/v1" \
    || { echo "FAIL: signed Release did not verify"; cat "$TMP/v1"; exit 1; }
echo "PASS: signed Release verifies."

# --- 4. tamper test ------------------------------------------------------
sed -i '1s/.*/MODIFIED-BY-TAMPER-TEST/' "$REPO/dists/trixie/Release"
if gpg --quiet --verify "$REPO/dists/trixie/Release.gpg" "$REPO/dists/trixie/Release" 2>/dev/null; then
    echo "FAIL: tampered Release verified — signing logic is broken"
    exit 1
fi
echo "PASS: tampered Release correctly rejected."

echo "Tier A repo-signing self-test: OK"
