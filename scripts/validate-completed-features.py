#!/usr/bin/python3
"""Static contracts for non-design feature completion work."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def require(path: str, fragments: tuple[str, ...]) -> None:
    source = (ROOT / path).read_text(encoding="utf-8")
    for fragment in fragments:
        if fragment not in source:
            raise SystemExit(f"{path}: missing contract fragment {fragment!r}")


def reject(path: str, fragments: tuple[str, ...]) -> None:
    source = (ROOT / path).read_text(encoding="utf-8")
    for fragment in fragments:
        if fragment in source:
            raise SystemExit(f"{path}: forbidden contract fragment {fragment!r}")


def main() -> int:
    require(
        "shared/includes/usr/libexec/edemint-inspector",
        ("subprocess.run(", "timeout=timeout_seconds()", "sys.executable, PROBE"),
    )
    require(
        "shared/includes/usr/libexec/edemint-inspector-probe",
        ("MAX_PREVIEW_BYTES = 65536", "os.O_NOFOLLOW", "stat.S_ISREG"),
    )
    require(
        "shared/includes/usr/libexec/edemint-fullcall",
        (
            "CREATE TABLE IF NOT EXISTS accounts",
            "hashlib.pbkdf2_hmac",
            "hmac.compare_digest",
            "author_id INTEGER REFERENCES accounts(id)",
            "Signed in as",
        ),
    )
    require(
        "shared/includes/usr/libexec/edemint-default-apps",
        (
            "COMMON_TYPES",
            "Gio.AppInfo.get_all_for_type",
            "set_as_default_for_type",
            "reset_type_associations",
            "Custom MIME type or URI scheme",
        ),
    )
    require(
        "scripts/smoke-hyprland-session.sh",
        (
            "WLR_BACKENDS=headless",
            "Hyprland --config",
            "hyprctl -j monitors",
            "edemint-session-smoke",
        ),
    )
    require(
        "profiles/arm64-pi/build.sh",
        (
            "debian-archive-keyring.gpg",
            "EDEMINT_DEBIAN_KEYRING",
            "sha256sum \"$DEBIAN_KEYRING\"",
        ),
    )
    reject(
        "profiles/arm64-pi/build.sh",
        (
            "ftp-master.debian.org/keys",
            "archive-key-13.asc",
            "build_trixie_keyring",
        ),
    )
    audit = ROOT / "docs/EDEMINT_COMPLETE_FEATURE_AUDIT.md"
    if not audit.is_file():
        raise SystemExit("feature audit was removed")
    print("completed feature contracts valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
