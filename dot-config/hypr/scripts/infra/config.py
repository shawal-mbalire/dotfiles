"""Infrastructure: deployment-specific configuration.

Reads environment variables exactly once. This is the only place in the
codebase where the environment is inspected; the composition root injects the
resulting values into every adapter.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

from infra import paths

DEFAULT_LOG_LEVEL = "warning"
DEFAULT_BATTERY_SUPPLY = "BAT0"
DEFAULT_NOTIFY_APP = "hypr"


def _env(name: str, default: str) -> str:
    value = os.environ.get(name)
    return value if value else default


@dataclass(frozen=True)
class Config:
    """Typed, immutable configuration injected into every adapter."""

    log_level: str
    battery_supply: str
    notify_app: str
    marker_dir: str


def load_config() -> Config:
    """Read the environment and return a fully-populated config object."""
    return Config(
        log_level=_env("HYPR_SCRIPTS_LOG_LEVEL", DEFAULT_LOG_LEVEL),
        battery_supply=_env("HYPR_BATTERY", DEFAULT_BATTERY_SUPPLY),
        notify_app=_env("HYPR_NOTIFY_APP", DEFAULT_NOTIFY_APP),
        marker_dir=_env("HYPR_MARKER_DIR", paths.app_cache_dir()),
    )
