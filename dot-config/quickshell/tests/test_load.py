#!/usr/bin/env python3
"""Load-time budget gate.

Runs a minimal Quickshell config that imports every singleton and measures
wall-clock time from process start to the "Configuration Loaded" line.
Exits 0 when load is within budget, 1 otherwise.
"""

import subprocess
import sys
import time
from pathlib import Path

BUDGET_MS = 50
TIMEOUT_S = 5
TAG = "Configuration Loaded"


def run_load_test(config_path: str, label: str) -> bool:
    start = time.monotonic()
    try:
        result = subprocess.run(
            ["qs", "-p", str(config_path)],
            capture_output=True,
            text=True,
            timeout=TIMEOUT_S,
        )
        output = result.stdout
    except subprocess.TimeoutExpired as e:
        output = (e.stdout or b"").decode("utf-8", errors="replace")

    elapsed_ms = (time.monotonic() - start) * 1000

    if TAG in output:
        ok = elapsed_ms <= BUDGET_MS
        status = "OK" if ok else "FAIL"
        print(f"  {status}  {label}: {elapsed_ms:.1f}ms (budget {BUDGET_MS}ms)")
        return ok

    print(f"  FAIL  {label}: no {TAG} in output ({elapsed_ms:.0f}ms)")
    return False


def main() -> int:
    base = Path(__file__).resolve().parent.parent
    tests = [
        ("shore/load_test.qml", "shore"),
        ("greet/load_test.qml", "greet"),
    ]

    all_ok = True
    for rel, label in tests:
        cfg = base / rel
        if not cfg.exists():
            print(f"  SKIP  {label}: {cfg} not found")
            continue
        if not run_load_test(str(cfg), label):
            all_ok = False

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
