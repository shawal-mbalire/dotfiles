"""Native wallpaper renderer — Fabric paints the wallpaper itself.

Opens one layer-shell BACKGROUND window per monitor and draws the current
wallpaper image with GTK4/GdkPixbuf. No hyprpaper, no swww, no CLI — the shell
itself is the wallpaper handler.
"""

# ruff: noqa: E402
from __future__ import annotations

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk  # noqa: E402

from adapters.driving.gtk.layer_shell import setup_background_window


class WallpaperBackground:
    def __init__(self, app: Gtk.Application, wallpaper_port, logger=None) -> None:
        self._app = app
        self._port = wallpaper_port
        self._logger = logger
        self._windows: list[Gtk.Window] = []
        self._port.subscribe(self._on_wallpaper)
        self._render()

    def close(self) -> None:
        for window in self._windows:
            window.destroy()
        self._windows = []

    def _on_wallpaper(self, _state) -> None:
        GLib.idle_add(self._render_idle)

    def _render_idle(self) -> bool:
        self._render()
        return False

    def _render(self) -> None:
        for window in self._windows:
            window.destroy()
        self._windows = []
        path = self._port.read().current
        display = Gdk.Display.get_default()
        if display is None:
            return
        for monitor in display.get_monitors():
            window = self._window(monitor, path)
            self._windows.append(window)

    def _window(self, monitor, path: str) -> Gtk.Window:
        window = Gtk.Window()
        setup_background_window(window, monitor)
        self._app.add_window(window)
        child: Gtk.Widget
        if path:
            child = self._picture(path)
        else:
            child = Gtk.Box()
            child.set_hexpand(True)
            child.set_vexpand(True)
        window.set_child(child)
        window.present()
        return window

    def _picture(self, path: str) -> Gtk.Picture:
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
        except Exception as exc:  # noqa: BLE001 - a bad image is not fatal
            if self._logger is not None:
                self._logger.warning("wallpaper", "cannot load image", path=path, error=str(exc))
            return Gtk.Picture()
        picture = Gtk.Picture.new_for_pixbuf(pixbuf)
        picture.set_keep_aspect_ratio(True)
        picture.set_content_fit(Gtk.ContentFit.COVER)
        picture.set_can_shrink(True)
        return picture
