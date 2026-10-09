"""AudioPort — the default output sink."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import Audio
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class AudioPort(ObservablePort[Audio], Protocol):
    """CONTRACT — AudioPort (default output sink).

    ``read()`` → Audio(ready, muted, volume 0..150).

    Commands:
      set_volume(percent)
        Pre:  percent is finite.
        Post: volume == clamp(round(percent), 0, 150) once the sink reports;
              no-op when not ready.
      set_muted(muted)
        Post: muted == muted once the sink reports; no-op when not ready.
    """

    def read(self) -> Audio: ...

    def subscribe(self, listener: Listener[Audio]) -> Unsubscribe: ...

    def set_volume(self, percent: int) -> None: ...

    def set_muted(self, muted: bool) -> None: ...
