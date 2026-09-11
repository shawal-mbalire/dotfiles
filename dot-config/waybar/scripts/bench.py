#!/usr/bin/python3 -S
"""Time-budget check for the polled waybar modules.

Runs every poll command several times and fails if any exceeds the configured
budget (default 50ms). This is what actually verifies the contract that the
thin client is meant to uphold.

Usage: bench.py [--budget MS] [--runs N]
"""

from __future__ import annotations

import os
import statistics
import subprocess
import sys
import time
from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parent
MAIN = SCRIPTS_DIR / "main.py"

POLL_COMMANDS = [
    ["pill", "clock"],
    ["pill", "temp"],
    ["pill", "network"],
    ["pill", "volume"],
    ["pill", "backlight"],
    ["pill", "battery"],
    ["pill", "bluetooth"],
    ["nightlight", "status"],
    ["audio", "status"],
    ["power", "status"],
    ["power", "pill"],
]


def measure(command: list[str], runs: int) -> list[float]:
    samples: list[float] = []
    for _ in range(runs):
        start = time.perf_counter()
        result = subprocess.run(
            [sys.executable, "-S", str(MAIN), *command],
            capture_output=True,
            text=True,
            check=False,
        )
        elapsed_ms = (time.perf_counter() - start) * 1000
        if result.returncode != 0:
            raise SystemExit(f"{' '.join(command)} failed: {result.stderr.strip()}")
        samples.append(elapsed_ms)
    return samples


def main(argv: list[str]) -> int:
    budget_ms = 50
    runs = 5
    if "--budget" in argv:
        budget_ms = int(argv[argv.index("--budget") + 1])
    if "--runs" in argv:
        runs = int(argv[argv.index("--runs") + 1])

    # Warm the cache so we measure the steady-state poll path.
    subprocess.run(
        [sys.executable, "-S", str(MAIN), "refresh"],
        env=os.environ,
        check=False,
        capture_output=True,
    )

    print(f"time budget: {budget_ms}ms, {runs} runs per module\n")
    failures: list[str] = []
    for command in POLL_COMMANDS:
        samples = measure(command, runs)
        median = statistics.median(samples)
        worst = max(samples)
        label = " ".join(command)
        flag = "OK" if worst <= budget_ms else "OVER"
        print(f"  {label:<22} median {median:5.1f}ms  max {worst:5.1f}ms  [{flag}]")
        if worst > budget_ms:
            failures.append(label)

    if failures:
        print(f"\nFAIL: over budget: {', '.join(failures)}")
        return 1
    print("\nAll poll modules within budget.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
