"""NotificationFeedPort — live toasts and notification history."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import NotificationFeed
from domain.ports.base import Listener, ObservablePort, Unsubscribe


@runtime_checkable
class NotificationFeedPort(ObservablePort[NotificationFeed], Protocol):
    """CONTRACT — NotificationFeedPort (org.freedesktop.Notifications server).

    ``read()`` → NotificationFeed(active newest-last bounded by MAX_VISIBLE,
    history newest-first non-transient bounded by MAX_HISTORY, now_ms).

    Commands:
      dismiss(key)          user-initiated close.
      expire(key)           timeout-driven close.
      invoke_default(key)   run the "default" action; returns whether it ran.
      has_default_action(key) -> bool
      pause(key) / resume(key) -> bool   freeze/thaw a toast's countdown.
      clear_history()
      dismiss_all()
    """

    def read(self) -> NotificationFeed: ...

    def subscribe(self, listener: Listener[NotificationFeed]) -> Unsubscribe: ...

    def dismiss(self, key: int) -> None: ...

    def expire(self, key: int) -> None: ...

    def invoke_default(self, key: int) -> bool: ...

    def has_default_action(self, key: int) -> bool: ...

    def pause(self, key: int) -> bool: ...

    def resume(self, key: int) -> bool: ...

    def clear_history(self) -> None: ...

    def dismiss_all(self) -> None: ...
