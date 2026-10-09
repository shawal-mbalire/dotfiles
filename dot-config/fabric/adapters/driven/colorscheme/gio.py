"""GioColorSchemeAdapter — native colour-scheme read/write/watch via GSettings.

GSettings is a native library (Gio/PyGObject), not a shell-out. The composition
root falls back to :class:`NullColorSchemeAdapter` when PyGObject is absent.
"""

from __future__ import annotations

from adapters.driven.observable import Observable

SCHEMA = "org.gnome.desktop.interface"
KEY = "color-scheme"


class GioColorSchemeAdapter(Observable[bool]):
    def __init__(self, logger=None) -> None:
        try:
            import gi

            gi.require_version("Gio", "2.0")
            from gi.repository import Gio
        except (ImportError, ValueError) as exc:  # pragma: no cover - depends on host
            raise RuntimeError("PyGObject/Gio is not available") from exc

        self._logger = logger
        self._settings = Gio.Settings.new(SCHEMA)
        super().__init__(self._read_scheme())
        self._settings.connect(f"changed::{KEY}", self._on_changed)

    def _read_scheme(self) -> bool:
        return self._settings.get_string(KEY) == "prefer-dark"

    def _on_changed(self, *_args) -> None:
        self.notify(self._read_scheme())

    def read(self) -> bool:
        return self._read_scheme()

    def set_dark(self, dark: bool) -> None:
        self._settings.set_string(KEY, "prefer-dark" if dark else "prefer-light")
        self.notify(dark)


class NullColorSchemeAdapter(Observable[bool]):
    """Used when GSettings is unavailable; dark by default, writes are logged."""

    def __init__(self, logger=None, dark: bool = True) -> None:
        super().__init__(dark)
        self._logger = logger

    def set_dark(self, dark: bool) -> None:
        if self._logger is not None:
            self._logger.warning("theme", "no settings backend; ignoring set_dark", dark=dark)
        self.notify(dark)
