"""Infrastructure: runtime path resolution.

The only place XDG paths are read. Kept free of heavier imports so a
short-lived CLI invocation resolves paths cheaply.
"""

from __future__ import annotations

import os

FALLBACK_CACHE_DIR = "/tmp"
APP_DIR_NAME = "hypr-scripts"


def cache_home() -> str:
    """Base directory for per-user cache state (XDG_CACHE_HOME or ~/.cache)."""
    return os.environ.get("XDG_CACHE_HOME") or os.path.join(
        os.environ.get("HOME", FALLBACK_CACHE_DIR), ".cache"
    )


def app_cache_dir() -> str:
    """Per-user directory holding notification markers and other runtime state."""
    return os.path.join(cache_home(), APP_DIR_NAME)
