#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CANDIDATES=${EDEMINT_APP_CANDIDATES:-"$REPO_ROOT/shared/package-lists/app-foundations.candidates"}
ARCH=${1:-"$(dpkg --print-architecture 2>/dev/null || true)"}

usage() {
    printf 'Usage: %s [debian-architecture]\n' "$0" >&2
    printf 'Checks package metadata only; it does not install or download packages.\n' >&2
}

if [ "${ARCH}" = "-h" ] || [ "${ARCH}" = "--help" ]; then
    usage
    exit 0
fi

if [ -z "$ARCH" ]; then
    printf 'error: architecture is required when dpkg is unavailable\n' >&2
    usage
    exit 2
fi

if ! command -v apt-cache >/dev/null 2>&1; then
    printf 'error: apt-cache is required; run this in a Debian Trixie environment\n' >&2
    exit 2
fi

if [ ! -r "$CANDIDATES" ]; then
    printf 'error: candidate manifest is not readable: %s\n' "$CANDIDATES" >&2
    exit 2
fi

native_arch=$(dpkg --print-architecture 2>/dev/null || true)
if [ -n "$native_arch" ] && [ "$ARCH" != "$native_arch" ]; then
    foreign_arches=$(dpkg --print-foreign-architectures 2>/dev/null || true)
    if ! printf '%s\n' "$foreign_arches" | grep -Fxq "$ARCH"; then
        printf 'error: %s is not configured as a foreign architecture\n' "$ARCH" >&2
        printf 'hint: configure it in a disposable CI/container environment, refresh APT metadata, then rerun\n' >&2
        exit 2
    fi
fi

printf 'package\tcapability\tprofile\tarchitecture\tversion\tinstalled_kib\tresult\n'
failures=0

while IFS='|' read -r package capability profile status; do
    case "$package" in
        ''|'#'*) continue ;;
    esac

    if [ "$status" != "candidate" ]; then
        continue
    fi

    query="${package}:${ARCH}"
    policy=$(apt-cache policy "$query" 2>/dev/null || true)
    version=$(printf '%s\n' "$policy" | awk '/Candidate:/ { print $2; exit }')

    if [ -z "$version" ] || [ "$version" = "(none)" ]; then
        printf '%s\t%s\t%s\t%s\t-\t-\tMISSING\n' \
            "$package" "$capability" "$profile" "$ARCH"
        failures=$((failures + 1))
        continue
    fi

    metadata=$(apt-cache show --no-all-versions "$query" 2>/dev/null || true)
    installed_size=$(printf '%s\n' "$metadata" | awk '/^Installed-Size:/ { print $2; exit }')
    [ -n "$installed_size" ] || installed_size='unknown'

    printf '%s\t%s\t%s\t%s\t%s\t%s\tAVAILABLE\n' \
        "$package" "$capability" "$profile" "$ARCH" "$version" "$installed_size"
done < "$CANDIDATES"

if [ "$failures" -ne 0 ]; then
    printf 'error: %s candidate package(s) are unavailable for %s\n' "$failures" "$ARCH" >&2
    exit 1
fi
