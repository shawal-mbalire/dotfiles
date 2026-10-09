"""Port primitives shared by every capability.

A *port* declares what the domain needs; an *adapter* fulfils it. Driven ports
are observable: they expose the latest reading via ``read()`` and push changes
to subscribers. The driving side never polls a concrete adapter.
"""

from __future__ import annotations

from collections.abc import Callable
from typing import Protocol, TypeVar, runtime_checkable

T_co = TypeVar("T_co", covariant=True)

Listener = Callable[[T_co], None]
Unsubscribe = Callable[[], None]


@runtime_checkable
class ObservablePort(Protocol[T_co]):
    """A source of readings the driving side can subscribe to.

    Postcondition: immediately after ``subscribe``, the listener is invoked once
    with the current reading (so views render without waiting for a change).
    """

    def read(self) -> T_co:
        """Return the most recent reading. Pure with respect to the adapter."""
        ...

    def subscribe(self, listener: Listener[T_co]) -> Unsubscribe:
        """Register a listener; return a function that unregisters it."""
        ...
