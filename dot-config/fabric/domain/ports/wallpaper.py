"""WallpaperPort — the wallpaper set and current selection."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import Wallpaper
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class WallpaperPort(ObservablePort[Wallpaper], Protocol):
    """CONTRACT — WallpaperPort.

    ``read()`` → Wallpaper(wallpapers absolute paths, current applied path).

    Commands:
      refresh()  re-scan the configured directory.
      set(path)  apply *path*; Post: current == path.
      next() / previous() / random()  move the selection and apply it.
    """

    def read(self) -> Wallpaper: ...

    def subscribe(self, listener: Listener[Wallpaper]) -> Unsubscribe: ...

    def refresh(self) -> None: ...

    def set(self, path: str) -> None: ...

    def next(self) -> None: ...

    def previous(self) -> None: ...

    def random(self) -> None: ...
