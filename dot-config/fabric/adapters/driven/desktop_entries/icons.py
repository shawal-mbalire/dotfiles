"""Icon resolution — locate an icon name in the freedesktop icon theme dirs."""

from __future__ import annotations

from pathlib import Path

ICON_SIZES = ("scalable", "512x512", "256x256", "128x128", "64x64", "48x48", "32x32")
ICON_EXTENSIONS = (".svg", ".png", ".xpm")


def icon_search_roots(data_home: Path, data_dirs: tuple[Path, ...]) -> tuple[Path, ...]:
    roots: list[Path] = []
    for base in (data_home, *data_dirs):
        roots.append(base / "icons")
    roots.extend([Path("/usr/share/pixmaps"), Path("/usr/local/share/pixmaps")])
    return tuple(roots)


def resolve_icon(name: str, roots: tuple[Path, ...]) -> str:
    """Return an absolute path to *name*, or "" when not found."""
    if not name:
        return ""
    if name.startswith("/"):
        return name if Path(name).exists() else ""
    for root in roots:
        for size in ICON_SIZES:
            for extension in ICON_EXTENSIONS:
                candidate = root / "hicolor" / size / "apps" / f"{name}{extension}"
                if candidate.exists():
                    return str(candidate)
        for extension in ICON_EXTENSIONS:
            candidate = root / f"{name}{extension}"
            if candidate.exists():
                return str(candidate)
    return ""
