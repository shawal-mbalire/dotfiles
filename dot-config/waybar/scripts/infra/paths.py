"""Runtime path resolution — the only place XDG paths are read.

Kept free of heavier imports (``dataclasses`` and friends) so the sub-50ms
poll path can resolve the cache directory without pulling in the full config
module. ``infra/config`` builds on these helpers for everything else.
"""

from __future__ import annotations

import os

FALLBACK_RUNTIME_DIR = "/tmp"


def runtime_dir() -> str:
    """Base directory for per-user runtime state, off disk when available."""
    return os.environ.get("XDG_RUNTIME_DIR") or FALLBACK_RUNTIME_DIR


def cache_dir() -> str:
    """Per-user directory holding the rendered module payload cache."""
    return os.path.join(runtime_dir(), f"waybar-cache-{os.getuid()}")
