"""Edemint hydroganic design runtime for the first-party GTK4 apps.

Every first-party app calls :func:`style_window` once. The module installs the
shared stylesheet for the display, marks the window as a frosty-glass surface
(`ed-frost`), claims the app's palette-subset accent class, and keeps window
transparency degradable: without compositor blur the frost still reads as
solid navy, so no readability depends on Hyprland effects.

The module must never break an app: every entry point swallows its own
failures and returns something usable.
"""

from __future__ import annotations

import os
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gtk  # noqa: E402

_CSS_CANDIDATES = (
    os.environ.get("EDEMINT_DESIGN_CSS", ""),
    str(Path(__file__).resolve().parent / "hydroganic.css"),
    "/usr/share/edemint/design/hydroganic.css",
)
# Palette subsets an app may claim; frost stays navy for matched lightness.
ACCENTS = {"ultramarine", "eco", "turquoise"}
_loaded_displays: set[int] = set()


def _stylesheet() -> str | None:
    for candidate in _CSS_CANDIDATES:
        if candidate and Path(candidate).is_file():
            return candidate
    return None


def install(display: Gdk.Display | None = None) -> bool:
    """Install the hydroganic stylesheet once per display."""
    try:
        display = display or Gdk.Display.get_default()
        if display is None or id(display) in _loaded_displays:
            return display is not None
        sheet = _stylesheet()
        if sheet is None:
            return False
        provider = Gtk.CssProvider()
        provider.load_from_path(sheet)
        Gtk.StyleContext.add_provider_for_display(
            display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        _loaded_displays.add(id(display))
        return True
    except Exception:
        return False


def style_window(window: Gtk.Window, accent: str = "ultramarine") -> None:
    """Mark a window as a frosty-glass surface with a palette-subset accent."""
    try:
        install(window.get_display())
        window.add_css_class("ed-frost")
        if accent in ACCENTS and accent != "ultramarine":
            window.add_css_class(f"ed-accent-{accent}")
    except Exception:
        pass


def hero(title: str, subtitle: str = "") -> Gtk.Box:
    """A page header: bold title over a dim subtitle, both wrapping."""
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    heading = Gtk.Label(label=title, xalign=0, wrap=True)
    heading.add_css_class("ed-hero-title")
    box.append(heading)
    if subtitle:
        line = Gtk.Label(label=subtitle, xalign=0, wrap=True)
        line.add_css_class("ed-hero-subtitle")
        box.append(line)
    return box


def equal_actions(*buttons: Gtk.Widget, spacing: int = 10) -> Gtk.Box:
    """A symmetric action row: equal minimum widths, homogeneous cells."""
    box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=spacing,
                  homogeneous=True)
    box.add_css_class("ed-equal")
    for button in buttons:
        button.set_hexpand(True)
        box.append(button)
    return box


def breakpoint_collapse(window: Adw.ApplicationWindow,
                        split: Adw.OverlaySplitView,
                        width: int = 760) -> None:
    """Collapse a split view under `width` px so narrow/mobile layouts work.

    Requires the window content to be set already; harmless when the
    breakpoint API is unavailable.
    """
    try:
        # Breakpoints require an explicit window minimum; this is the compact
        # floor every first-party app can shrink to.
        window.set_size_request(360, 294)
        condition = Adw.BreakpointCondition.parse(f"max-width: {width}sp")
        breakpoint = Adw.Breakpoint.new(condition)
        breakpoint.add_setter(split, "collapsed", True)
        window.add_breakpoint(breakpoint)
    except Exception:
        pass
