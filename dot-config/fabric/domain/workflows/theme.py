"""Theme workflow — dark/light mode and native colour-scheme sync."""

from __future__ import annotations

from collections.abc import Callable

from domain.constants import Theme, theme_for
from domain.ports import ColorSchemePort, LoggerPort
from domain.result import Result, ok

ThemeListener = Callable[[Theme], None]


class ThemeWorkflow:
    """Holds the current theme and mirrors the desktop preference.

    Transient state scoped to this instance (allowed for a workflow): the
    current ``Theme`` and its listeners. Shared state never lives here.
    """

    def __init__(self, color_scheme: ColorSchemePort, logger: LoggerPort) -> None:
        self._color_scheme = color_scheme
        self._logger = logger
        self._listeners: list[ThemeListener] = []
        self._current = theme_for(color_scheme.read())
        color_scheme.subscribe(self._on_scheme)

    @property
    def current(self) -> Theme:
        return self._current

    def subscribe(self, listener: ThemeListener) -> Callable[[], None]:
        self._listeners.append(listener)
        listener(self._current)
        return lambda: self._listeners.remove(listener)

    def set_dark(self, dark: bool) -> Result[bool]:
        self._apply(theme_for(dark))
        self._color_scheme.set_dark(dark)
        return ok(dark)

    def toggle(self) -> Result[bool]:
        return self.set_dark(not self._current.dark)

    def _on_scheme(self, dark: bool) -> None:
        self._apply(theme_for(dark))

    def _apply(self, theme: Theme) -> None:
        if theme.dark == self._current.dark:
            return
        self._current = theme
        self._logger.debug("theme", "switched", dark=theme.dark)
        for listener in tuple(self._listeners):
            listener(theme)
