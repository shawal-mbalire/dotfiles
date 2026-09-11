"""Artifact ports: persist the domain models as swaync's wire format.

Adapters translate domain models (``SwayncConfig`` / ``StyleSheet``) into the
files swaync actually reads. The domain never knows they are JSON or CSS.
"""

from __future__ import annotations

from typing import Protocol, runtime_checkable

from domain.models import StyleSheet, SwayncConfig


@runtime_checkable
class ConfigWriter(Protocol):
    def write_config(self, config: SwayncConfig) -> None: ...


@runtime_checkable
class StyleWriter(Protocol):
    def write_style(self, sheet: StyleSheet) -> None: ...
