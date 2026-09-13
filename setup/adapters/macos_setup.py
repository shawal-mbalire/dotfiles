import shutil
import subprocess
from pathlib import Path

from domain.models.platform import Platform
from domain.ports.logger import Logger

BREW_PATHS = [
    Path("/opt/homebrew/bin/brew"),
    Path("/usr/local/bin/brew"),
]


def _has_brew() -> bool:
    return shutil.which("brew") is not None or any(p.exists() for p in BREW_PATHS)


class MacosSetup:
    def __init__(self, logger: Logger) -> None:
        self._logger = logger

    def bootstrap(self, platform: Platform, dry_run: bool = False) -> bool:
        if _has_brew():
            self._logger.info("  ✓ homebrew already installed")
            return True

        self._logger.info("  Installing homebrew...")
        cmd = (
            'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL '
            'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        )
        if dry_run:
            self._logger.dry_run(f"  [dry-run] {cmd}")
            return True

        result = subprocess.run(cmd, shell=True)
        if result.returncode != 0:
            self._logger.warning("  ⚠ failed to install homebrew")
        return True

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
        self._logger.info("  ✓ Symlinked nushell config")
        return True
