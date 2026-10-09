"""Architecture guard: the domain must not import anything outward.

Run as ``python -m tests.guards.boundaries`` (used by ``just architecture``).
Exits non-zero listing every offending import. Also collected as a pytest test.
"""

from __future__ import annotations

import ast
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOMAIN = ROOT / "domain"
FORBIDDEN_PREFIXES = ("adapters", "infra", "tests", "gi", "PySide6", "cairo")
ALLOWED_INTERNAL = {"domain"}


def _imported_roots(tree: ast.AST) -> list[str]:
    roots: list[str] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            roots.extend(alias.name.split(".")[0] for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.level == 0 and node.module:
            roots.append(node.module.split(".")[0])
    return roots


def violations() -> list[str]:
    problems: list[str] = []
    stdlib = set(sys.stdlib_module_names)
    for path in sorted(DOMAIN.rglob("*.py")):
        tree = ast.parse(path.read_text(), filename=str(path))
        for root in _imported_roots(tree):
            if root in ALLOWED_INTERNAL:
                continue
            if root.startswith(FORBIDDEN_PREFIXES):
                problems.append(f"{path.relative_to(ROOT)}: forbidden import '{root}'")
            elif root not in stdlib:
                problems.append(f"{path.relative_to(ROOT)}: non-stdlib import '{root}'")
    return problems


def main() -> int:
    problems = violations()
    if problems:
        print("Architecture violations (domain must import only stdlib + itself):")
        for problem in problems:
            print(f"  - {problem}")
        return 1
    print("architecture: domain boundary clean")
    return 0


def test_domain_boundary_is_clean() -> None:
    assert violations() == []


if __name__ == "__main__":
    raise SystemExit(main())
