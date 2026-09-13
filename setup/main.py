#!/usr/bin/env python3
"""
Dotfiles environment setup — hexagonal architecture.

Usage:
  uv run python setup/main.py install [--dry-run]
  uv run python setup/main.py check
  uv run python setup/main.py list
  uv run python setup/main.py stow [--dry-run]
  uv run python setup/main.py bootstrap [--dry-run]
  uv run python setup/main.py setup [--dry-run]
  uv run python setup/main.py update
"""

import shutil
import subprocess
import sys
from pathlib import Path

# Add parent dir to path so imports work
sys.path.insert(0, str(Path(__file__).parent))

from adapters.brew import BrewAdapter
from adapters.console_logger import ConsoleLogger
from adapters.dnf import DnfAdapter
from adapters.fedora_setup import FedoraSetup
from adapters.flatpak import FlatpakAdapter
from adapters.macos_setup import MacosSetup
from adapters.snap import SnapAdapter
from adapters.user import UserAdapter
from domain.models.platform import Platform
from domain.workflows.check import check_packages
from domain.workflows.install import install_packages
from domain.workflows.setup import setup_platform
from infra.config import PACKAGES

DOTFILES_DIR = Path(__file__).parent.parent


def _get_managers() -> list:
    """Get package managers based on current platform."""
    platform = Platform.detect(str(Path.home()))
    managers = []

    classic_snaps = {p.snap for p in PACKAGES if p.snap and p.snap_classic}

    if platform.type.value == "fedora":
        managers = [DnfAdapter(), BrewAdapter(), FlatpakAdapter(),
                    SnapAdapter(classic=classic_snaps), UserAdapter()]
    elif platform.type.value == "macos":
        managers = [BrewAdapter(), UserAdapter()]
    else:
        managers = [DnfAdapter(), BrewAdapter(), FlatpakAdapter(),
                    SnapAdapter(classic=classic_snaps), UserAdapter()]

    return managers


def cmd_stow(dry_run: bool = False) -> None:
    """Symlink dotfiles via GNU Stow, removing conflicts."""
    logger = ConsoleLogger()
    logger.info("Stowing dotfiles...")

    if dry_run:
        # Show what would conflict
        result = subprocess.run(
            ["stow", "--dotfiles", "-n", "-v", "."],
            cwd=DOTFILES_DIR,
            capture_output=True, text=True,
        )
        for line in result.stderr.splitlines():
            if "CONFLICT" in line or "would" in line.lower():
                logger.dry_run(f"  {line.strip()}")
        logger.dry_run(f"  [dry-run] stow --dotfiles --adopt . (in {DOTFILES_DIR})")
        return

    # First try stow with --adopt (overwrite existing)
    result = subprocess.run(
        ["stow", "--dotfiles", "--adopt", "."],
        cwd=DOTFILES_DIR,
        capture_output=True, text=True,
    )

    if result.returncode == 0:
        logger.success("  ✓ Dotfiles stowed")
    else:
        # If adopt fails, try removing conflicts manually
        logger.warning("  Conflicts found, removing...")
        _remove_conflicts(logger)
        # Retry stow
        result = subprocess.run(
            ["stow", "--dotfiles", "."],
            cwd=DOTFILES_DIR,
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            logger.success("  ✓ Dotfiles stowed")
        else:
            logger.error(f"  ✗ Stow failed: {result.stderr}")
            sys.exit(1)


def _remove_conflicts(logger: ConsoleLogger) -> None:
    """Find and remove files that conflict with stow targets."""
    home = Path.home()

    # Walk through all stow targets
    for stow_dir in DOTFILES_DIR.iterdir():
        if not stow_dir.is_dir() or stow_dir.name.startswith("."):
            continue
        if stow_dir.name in ("setup", "tests", "__pycache__", ".git", ".venv"):
            continue

        # Map stow dir to home location
        if stow_dir.name == "dot-config":
            target_base = home / ".config"
        elif stow_dir.name == "dot-local":
            target_base = home / ".local"
        else:
            continue

        # Find all files in stow dir
        for item in stow_dir.rglob("*"):
            if item.is_dir():
                continue
            # Calculate target path
            rel = item.relative_to(stow_dir)
            target = target_base / rel

            if target.exists() and not target.is_symlink():
                logger.info(f"  Removing: {target}")
                target.unlink()
            elif target.is_symlink():
                # Remove broken symlinks
                if not target.exists():
                    target.unlink()


def cmd_install(dry_run: bool = False) -> None:
    logger = ConsoleLogger()
    _bootstrap_managers(logger, dry_run)
    managers = _get_managers()

    installed, skipped, failed = install_packages(PACKAGES, managers, logger, dry_run)

    logger.info(f"\n  installed: {installed}")
    logger.info(f"  skipped:   {skipped} (already installed)")
    if failed:
        logger.error(f"  failed:    {failed}")
    sys.exit(1 if failed else 0)


def cmd_check() -> None:
    logger = ConsoleLogger()
    managers = _get_managers()

    installed, missing = check_packages(PACKAGES, managers, logger)
    logger.info(f"\n  {installed} installed/available, {missing} missing")


def cmd_list() -> None:
    logger = ConsoleLogger()

    logger.info("Packages and their install methods:\n")
    for pkg in PACKAGES:
        parts = []
        if pkg.dnf:
            parts.append(f"dnf:{pkg.dnf}")
        if pkg.brew:
            parts.append(f"brew:{pkg.brew}")
        if pkg.flatpak:
            parts.append(f"flatpak:{pkg.flatpak}")
        if pkg.snap:
            parts.append(f"snap:{pkg.snap}")
        if pkg.user:
            parts.append(f"user: {pkg.user[:40]}...")
        logger.info(f"  {pkg.name:25s} {' → '.join(parts)}")


def _get_setup_adapter(logger: ConsoleLogger):
    """Return (platform, platform_setup_adapter) for the current platform."""
    platform = Platform.detect(str(Path.home()))
    if platform.type.value == "fedora":
        return platform, FedoraSetup(logger)
    if platform.type.value == "macos":
        return platform, MacosSetup(logger)
    return platform, None


def _bootstrap_managers(logger: ConsoleLogger, dry_run: bool = False) -> None:
    """Ensure brew, flatpak and snap are installed before resolving deps."""
    platform, adapter = _get_setup_adapter(logger)
    if adapter is None:
        return
    logger.info("Bootstrapping package managers...")
    adapter.bootstrap(platform, dry_run)


def cmd_bootstrap(dry_run: bool = False) -> None:
    logger = ConsoleLogger()
    _bootstrap_managers(logger, dry_run)


def cmd_setup(dry_run: bool = False) -> None:
    logger = ConsoleLogger()
    platform, adapter = _get_setup_adapter(logger)

    if adapter is None:
        logger.warning(f"  No setup script for {platform.type.value}")
        return

    setup_platform(platform, adapter, logger, dry_run)


def cmd_update() -> None:
    if shutil.which("brew"):
        print("Updating brew...")
        subprocess.run(["brew", "update"], check=False)
        subprocess.run(["brew", "upgrade"], check=False)

    if shutil.which("flatpak"):
        print("Updating flatpak...")
        subprocess.run(["flatpak", "update", "-y"], check=False)

    if shutil.which("snap"):
        print("Updating snap...")
        subprocess.run(["sudo", "snap", "refresh"], check=False)

    if shutil.which("cargo"):
        print("Updating cargo binaries...")
        subprocess.run(["cargo", "install-update", "-a"], check=False)

    print("Done.")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__.strip())
        sys.exit(1)

    cmd = sys.argv[1]
    dry_run = "--dry-run" in sys.argv

    commands = {
        "install": lambda: cmd_install(dry_run),
        "check": cmd_check,
        "list": cmd_list,
        "stow": lambda: cmd_stow(dry_run),
        "bootstrap": lambda: cmd_bootstrap(dry_run),
        "setup": lambda: cmd_setup(dry_run),
        "update": cmd_update,
    }

    if cmd in commands:
        commands[cmd]()
    else:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
