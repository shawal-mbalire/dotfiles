"""ClipboardPort — text clipboard history (persisted, unique, bounded)."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import Clipboard
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class ClipboardPort(ObservablePort[Clipboard], Protocol):
    """CONTRACT — ClipboardPort.

    ``read()`` → Clipboard(history newest-first unique bounded, state ∈
    {"loading","ready","unavailable"}).

    Commands:
      copy(text)              Pre: text satisfies logic.is_usable_text.
                              Post: text is the selection and history[0].
      remove(text)            Post: text is no longer in history.
      clear()                 Post: history is empty (selection untouched).

    Invariant: every entry is usable; no duplicates; history persists across
    restarts; sensitive selections are never recorded.
    """

    def read(self) -> Clipboard: ...

    def subscribe(self, listener: Listener[Clipboard]) -> Unsubscribe: ...

    def copy(self, text: str) -> None: ...

    def remove(self, text: str) -> None: ...

    def clear(self) -> None: ...
