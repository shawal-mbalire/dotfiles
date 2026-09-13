#!/usr/bin/python3 -S
"""Waybar helper scripts — thin entry point.

Delegates to the CLI driving adapter in ``cli.py``. Kept minimal so the
composition root stays easy to reason about; all wiring lives in ``wire.py``.
"""

from __future__ import annotations

import os
import sys

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)


def main(argv: list[str]) -> int:
    from cli import run

    return run(argv)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
