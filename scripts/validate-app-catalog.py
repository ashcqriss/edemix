#!/usr/bin/python3
import json
from pathlib import Path
import re
import stat
import sys


def main() -> int:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "apps/catalog.json")
    root = Path(sys.argv[2] if len(sys.argv) > 2 else ".")
    payload = json.loads(path.read_text(encoding="utf-8"))
    apps = payload.get("apps")
    if payload.get("schema") != 1 or not isinstance(apps, list):
        raise SystemExit("invalid catalog schema")

    ids = set()
    execs = set()
    allowed_kinds = {"native", "foundation"}
    allowed_status = {"candidate", "integrated", "mvp", "experimental"}
    for app in apps:
        missing = {
            "id", "name", "kind", "status", "exec", "package", "profile"
        } - app.keys()
        if missing:
            raise SystemExit(f"{app!r}: missing {sorted(missing)}")
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", app["id"]):
            raise SystemExit(f"invalid id: {app['id']}")
        if app["id"] in ids:
            raise SystemExit(f"duplicate id: {app['id']}")
        if app["exec"] in execs and app["kind"] == "native":
            raise SystemExit(f"native executable reused: {app['exec']}")
        if app["kind"] not in allowed_kinds:
            raise SystemExit(f"invalid kind: {app['kind']}")
        if app["status"] not in allowed_status:
            raise SystemExit(f"invalid status: {app['status']}")
        ids.add(app["id"])
        execs.add(app["exec"])
        desktop = (
            root / "shared/includes/usr/share/applications"
            / f"edemint-{app['id']}.desktop"
        )
        if not desktop.is_file():
            raise SystemExit(f"missing desktop entry: {desktop}")
        if app["kind"] == "native":
            wrapper = root / "shared/includes/usr/local/bin" / app["exec"]
            if not wrapper.is_file():
                raise SystemExit(f"missing native wrapper: {wrapper}")
            if not wrapper.stat().st_mode & (
                stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
            ):
                raise SystemExit(f"native wrapper is not executable: {wrapper}")

    required = {
        "adventurer", "settings", "activity-monitor", "filer", "messenger",
        "app-store", "calendar", "maps", "app-library", "shortcuts",
        "inspector", "mail",
        "noterer", "bluetooth", "dictionary", "console", "font-manager",
        "terminal", "mission-control", "sticky-notes", "color-control",
        "print-control", "camera", "camera-studio", "automator", "calculator",
        "fullcall", "phone", "contacts",
    }
    absent = required - ids
    if absent:
        raise SystemExit(f"required apps missing: {sorted(absent)}")
    runtime = root / "shared/includes/usr/libexec/edemint-app"
    if not runtime.is_file():
        raise SystemExit(f"missing native runtime: {runtime}")
    if not runtime.stat().st_mode & (
        stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
    ):
        raise SystemExit(f"native runtime is not executable: {runtime}")
    library_runtime = root / "shared/includes/usr/libexec/edemint-library-tools"
    if not library_runtime.is_file():
        raise SystemExit(f"missing App Library runtime: {library_runtime}")
    if not library_runtime.stat().st_mode & (
        stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
    ):
        raise SystemExit(
            f"App Library runtime is not executable: {library_runtime}"
        )
    print(f"catalog valid: {len(apps)} applications")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
