"""Power-profile gateway contract."""

from __future__ import annotations

from typing import Protocol


class PowerGateway(Protocol):
    def get_active(self) -> str | None: ...

    def set_profile(self, name: str) -> bool: ...
