"""GTK4 layer-shell helpers (Wayland). Imports are lazy so the package loads
headless."""

from __future__ import annotations

from typing import Any


def gtk_available() -> bool:
    try:
        import gi

        gi.require_version("Gtk", "4.0")
        from gi.repository import Gtk  # noqa: F401
    except (ImportError, ValueError):
        return False
    return True


def layer_shell_available() -> bool:
    try:
        import gi

        gi.require_version("Gtk4LayerShell", "1.0")
        from gi.repository import Gtk4LayerShell  # noqa: F401
    except (ImportError, ValueError):
        return False
    return True


def _layer_shell():
    import gi

    gi.require_version("Gtk4LayerShell", "1.0")
    from gi.repository import Gtk4LayerShell

    return Gtk4LayerShell


def setup_bar_window(window: Any, *, height: int, namespace: str = "fabric:bar") -> None:
    """Anchor a window to the top edge as an exclusive-zone bar."""
    LayerShell = _layer_shell()
    LayerShell.init_for_window(window)
    LayerShell.set_layer(window, LayerShell.Layer.TOP)
    LayerShell.set_namespace(window, namespace)
    for edge in (LayerShell.Edge.TOP, LayerShell.Edge.LEFT, LayerShell.Edge.RIGHT):
        LayerShell.set_anchor(window, edge, True)
    LayerShell.set_exclusive_zone(window, height)
    LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.NONE)


def setup_background_window(window: Any, monitor: Any, namespace: str = "fabric:wallpaper") -> None:
    """Turn a window into a full-screen background layer on the given monitor."""
    LayerShell = _layer_shell()
    LayerShell.init_for_window(window)
    LayerShell.set_layer(window, LayerShell.Layer.BACKGROUND)
    LayerShell.set_monitor(window, monitor)
    LayerShell.set_namespace(window, namespace)
    for edge in (
        LayerShell.Edge.TOP,
        LayerShell.Edge.BOTTOM,
        LayerShell.Edge.LEFT,
        LayerShell.Edge.RIGHT,
    ):
        LayerShell.set_anchor(window, edge, True)
    LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.NONE)
    LayerShell.set_exclusive_zone(window, -1)


def setup_overlay_window(
    window: Any,
    *,
    namespace: str,
    width: int,
    height: int,
    anchor_right: bool = False,
    anchor_top: bool = True,
    top_margin: int = 60,
    right_margin: int = 0,
) -> None:
    """Anchor a keyboard-focusable overlay window for menus/popups."""
    LayerShell = _layer_shell()
    LayerShell.init_for_window(window)
    LayerShell.set_layer(window, LayerShell.Layer.OVERLAY)
    LayerShell.set_namespace(window, namespace)
    LayerShell.set_anchor(window, LayerShell.Edge.TOP, anchor_top)
    LayerShell.set_anchor(window, LayerShell.Edge.RIGHT, anchor_right)
    LayerShell.set_anchor(window, LayerShell.Edge.LEFT, not anchor_right)
    LayerShell.set_margin(window, LayerShell.Edge.TOP, top_margin)
    if anchor_right:
        LayerShell.set_margin(window, LayerShell.Edge.RIGHT, right_margin)
    LayerShell.set_exclusive_zone(window, -1)
    LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.ON_DEMAND)
    window.set_default_size(width, height)
