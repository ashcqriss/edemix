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


def package_names(path: str) -> set[str]:
    names: set[str] = set()
    for line in (ROOT / path).read_text(encoding="utf-8").splitlines():
        value = line.strip()
        if value and not value.startswith("#"):
            names.add(value.split()[0])
    return names


def main() -> int:
    require("shared/includes/usr/libexec/edemint-inspector", (
        "timeout=timeout_seconds()", "SANDBOX", "Open Disposable Sandboxed Viewer", "mime_mismatch",
    ))
    require("shared/includes/usr/libexec/edemint-inspector-probe", (
        "MAX_PREVIEW_BYTES = 65536", "os.O_NOFOLLOW", "stat.S_ISREG",
        "--dereference", "pass_fds=(descriptor,)", "mime_mismatch",
    ))
    require("shared/includes/usr/libexec/edemint-inspector-sandbox", (
        "--unshare-all", "--disable-userns", "--cap-drop", "ALL",
        "--ro-bind", "/inspect/input", "RLIMIT_CPU", "RLIMIT_AS",
        "--safe-mode", "--audio=no", "dbus-run-session", "--dereference",
    ))
    require("shared/includes/usr/libexec/edemint-settings-app", (
        "PAGES = [", "Search settings", "session_env", "wpctl", "wlr-randr",
        "do-not-disturb", "permission-list", "install-updates", "create-snapshot",
        "reduced_motion", "edemint-default-apps", "smartctl", "pkexec",
    ))
    require("shared/includes/usr/libexec/edemint-settings-helper", (
        "if os.geteuid() != 0", "install-updates", "locale_supported",
        "valid_user", "existing_groups", "create-snapshot", "action or arguments are not allowed",
    ))
    require("shared/includes/usr/share/polkit-1/actions/org.edemint.settings.policy", (
        "org.edemint.settings.manage", "auth_admin_keep",
        "/usr/libexec/edemint-settings-helper",
    ))
    require("shared/includes/usr/libexec/edemint-fullcall", (
        "CREATE TABLE IF NOT EXISTS accounts", "hashlib.pbkdf2_hmac",
        "hmac.compare_digest", "author_id INTEGER REFERENCES accounts(id)", "Signed in as",
    ))
    require("shared/includes/usr/libexec/edemint-default-apps", (
        "COMMON_TYPES", "Gio.AppInfo.get_all_for_type", "set_as_default_for_type",
        "reset_type_associations", "Custom MIME type or URI scheme",
    ))
    require("shared/includes/usr/libexec/edemint-activity-monitor-app", (
        'Path("/proc/stat")', 'Path("/proc/diskstats")', "process_snapshot",
        "signal.SIGTERM", "os.setpriority", "gpu_snapshot", "temperature_snapshot",
        "Exported JSON and CSV history",
    ))
    require("shared/includes/usr/libexec/edemint-console-app", (
        '"journalctl", "--user"', '"--output=json"', "Previous boot", "Bookmark",
        "Support Bundle", "redact(", "timeout=8",
    ))
    require("shared/includes/usr/libexec/edemint-mission-control-app", (
        'hypr_json("workspaces")', 'hypr_json("clients")', 'dispatch("focuswindow"',
        'dispatch("closewindow"', 'dispatch("movetoworkspacesilent"', "Remove Empty",
        "set_accels_for_action", "reconnect automatically",
    ))
    require("shared/includes/usr/libexec/edemint-sticky-notes-app", (
        "MAX_NOTES = 1000", "save_store", "GLib.timeout_add(350, self.flush)",
        "Pinned", "Move to Trash", "Add Checkbox", "check_reminders",
        "export_notes", "import_notes", "set_opacity",
    ))
    require("shared/includes/usr/libexec/edemint-library-tools", (
        "SCHEMA = 2", "desktop-index.json", "monitor_directory", "fuzzy_score",
        "PAGE_SIZE = 80", "record_launch", '"folders": {}', "WORKFLOW_ACTIONS",
        "MAX_REPEAT = 10", "if_path_exists", "workflow_permissions",
        "undo_shortcuts", "Arbitrary shell commands are never accepted",
    ))
    require("scripts/smoke-hyprland-session.sh", (
        "AQ_DRM_DEVICES", "MESA_LOADER_DRIVER_OVERRIDE=kms_swrast", "GALLIUM_DRIVER=llvmpipe",
        "seatd -g video", "Hyprland --config", "hyprctl -j monitors", "edemint-session-smoke",
    ))
    require("profiles/arm64-pi/build.sh", (
        "debian-archive-keyring.gpg", "EDEMINT_DEBIAN_KEYRING", "sha256sum \"$DEBIAN_KEYRING\"",
    ))
    reject("profiles/arm64-pi/build.sh", (
        "ftp-master.debian.org/keys", "archive-key-13.asc", "build_trixie_keyring",
    ))
    base = package_names("shared/package-lists/base.list.chroot")
    desktop = package_names("shared/package-lists/desktop.list.chroot")
    if "localepurge" in base:
        raise SystemExit("base image must preserve the complete locale dataset")
    if (ROOT / "shared/includes/etc/locale.nopurge").exists():
        raise SystemExit("obsolete locale-pruning configuration must not be shipped")
    required_base = {"smartmontools", "procps", "locales"}
    required_desktop = {
        "libreoffice-writer", "speech-dispatcher", "gnome-accessibility-themes",
        "upower", "libglib2.0-bin", "pkexec",
    }
    if not required_base <= base:
        raise SystemExit(f"base package contract missing: {sorted(required_base - base)}")
    if not required_desktop <= desktop:
        raise SystemExit(f"desktop package contract missing: {sorted(required_desktop - desktop)}")
    audit = ROOT / "docs/EDEMINT_COMPLETE_FEATURE_AUDIT.md"
    if not audit.is_file():
        raise SystemExit("feature audit was removed")
    print("completed feature contracts valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
