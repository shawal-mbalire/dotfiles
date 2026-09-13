from typing import Protocol

from domain.models.platform import Platform


class PlatformSetup(Protocol):
    def bootstrap(self, platform: Platform, dry_run: bool = False) -> bool:
        """Ensure platform package managers (brew, flatpak, snap) exist."""
        ...

    def setup(self, platform: Platform, dry_run: bool = False) -> bool:
        """Run platform-specific setup. Returns True on success."""
        ...
