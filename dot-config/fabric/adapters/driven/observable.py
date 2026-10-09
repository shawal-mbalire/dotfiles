"""Adapter plumbing: portable observables and polling helpers.

These depend only on the standard library. They are aggregate-agnostic — the
reading type ``T`` is supplied by each adapter, so this file copies into any
project unchanged.
"""

from __future__ import annotations

import threading
from collections.abc import Callable
from typing import Generic, TypeVar

T = TypeVar("T")

Listener = Callable[[T], None]
Unsubscribe = Callable[[], None]


class Observable(Generic[T]):
    """Thread-safe observable value with immediate-on-subscribe semantics."""

    def __init__(self, initial: T) -> None:
        self._value = initial
        self._listeners: list[Listener[T]] = []
        self._lock = threading.RLock()

    def read(self) -> T:
        with self._lock:
            return self._value

    def subscribe(self, listener: Listener[T]) -> Unsubscribe:
        with self._lock:
            self._listeners.append(listener)
            current = self._value
        listener(current)

        def unsubscribe() -> None:
            with self._lock:
                if listener in self._listeners:
                    self._listeners.remove(listener)

        return unsubscribe

    def notify(self, value: T) -> None:
        """Publish a new reading to every subscriber. Idempotent if unchanged."""
        with self._lock:
            if value == self._value:
                return
            self._value = value
            listeners = tuple(self._listeners)
        for listener in listeners:
            listener(value)


class Poller:
    """Run *produce* on an interval in a daemon thread, publishing readings.

    The read function must be pure I/O; all interpretation belongs in the
    adapter's own pure mapping function.
    """

    def __init__(self, produce: Callable[[], None], interval: float) -> None:
        self._produce = produce
        self._interval = interval
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        if self._thread is not None:
            return

        def loop() -> None:
            while not self._stop.wait(self._interval):
                try:
                    self._produce()
                except Exception:  # noqa: BLE001 - never let a background poll die silently
                    # Adapters translate their own failures; a crash here would
                    # otherwise kill the poll loop. Surfaced via the adapter.
                    continue

        self._thread = threading.Thread(target=loop, daemon=True, name="fabric-poller")
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
