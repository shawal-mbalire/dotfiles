import os
import sys
from pathlib import Path
from domain.models.platform import Platform, PlatformType
from domain.ports.platform_setup import PlatformSetup
from domain.ports.logger import Logger


class MacosSetup:
    def __init__(self, logger: Logger) -> None:
        self._logger = logger

    def setup(self, platform: Platform, dry_run: bool = False) -> bool:
        home = Path(platform.home_dir)
        nushell_app_support = home / "Library" / "Application Support" / "nushell"
        target = home / ".config" / "nushell"

        if dry_run:
            self._logger.dry_run(f"  [dry-run] ln -s {target} {nushell_app_support}")
            return True

        if nushell_app_support.is_symlink():
            self._logger.info(f"  ✓ Symlink already exists: {nushell_app_support}")
            return True

        if nushell_app_support.exists():
            import shutil
            shutil.rmtree(nushell_app_support)

        nushell_app_support.symlink_to(target)
        self._logger.info(f"  ✓ Symlinked nushell config")
        return True
