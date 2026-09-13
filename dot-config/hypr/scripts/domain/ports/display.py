"""Display port: discover monitors and apply a rule through the compositor."""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import Monitor, MonitorRule


@runtime_checkable
class MonitorGateway(Protocol):
    def list_monitors(self) -> list[Monitor]: ...

    def apply(self, rule: MonitorRule) -> None: ...
