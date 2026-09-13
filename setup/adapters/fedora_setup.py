import shutil
import subprocess
from pathlib import Path

from domain.models.platform import Platform
from domain.ports.logger import Logger

BREW_PATHS = [
    Path("/home/linuxbrew/.linuxbrew/bin/brew"),
    Path.home() / ".linuxbrew" / "bin" / "brew",
]


def _has_brew() -> bool:
    return shutil.which("brew") is not None or any(p.exists() for p in BREW_PATHS)


class FedoraSetup:
    def __init__(self, logger: Logger) -> None:
        self._logger = logger

    def bootstrap(self, platform: Platform, dry_run: bool = False) -> bool:
        steps = [
            ("flatpak", lambda: shutil.which("flatpak") is not None, [
                "sudo dnf install -y flatpak",
            ]),
            ("snapd", lambda: shutil.which("snap") is not None, [
                "sudo dnf install -y snapd",
                "sudo systemctl enable --now snapd.socket",
                "sudo ln -sf /var/lib/snapd/snap /snap",
            ]),
            ("homebrew", _has_brew, [
                'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL '
                'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
            ]),
        ]

        for label, installed, commands in steps:
            if installed():
                self._logger.info(f"  ✓ {label} already installed")
                continue

            self._logger.info(f"  Installing {label}...")
            for cmd in commands:
                if dry_run:
                    self._logger.dry_run(f"  [dry-run] {cmd}")
                    continue
                result = subprocess.run(cmd, shell=True)
                if result.returncode != 0:
                    self._logger.warning(f"  ⚠ failed: {cmd}")

        return True

    def setup(self, platform: Platform, dry_run: bool = False) -> bool:
        home = Path(platform.home_dir)

        dirs = [
            home / ".cache" / "carapace",
            home / ".cache" / "starship",
            home / ".local" / "share" / "atuin",
        ]

        for d in dirs:
            if dry_run:
                self._logger.dry_run(f"  [dry-run] mkdir -p {d}")
            else:
                d.mkdir(parents=True, exist_ok=True)

        commands = [
            ("carapace init nu", home / ".cache" / "carapace" / "init.nu"),
            ("starship init nu", home / ".cache" / "starship" / "init.nu"),
            ("atuin init nu", home / ".local" / "share" / "atuin" / "init.nu"),
        ]

        for cmd, output_file in commands:
            if dry_run:
                self._logger.dry_run(f"  [dry-run] {cmd} > {output_file}")
                continue

            try:
                result = subprocess.run(
                    cmd, shell=True, capture_output=True, text=True,
                )
                if result.returncode == 0:
                    output_file.write_text(result.stdout)
                    self._logger.info(f"  ✓ Generated {output_file.name}")
                else:
                    self._logger.warning(
                        f"  ⚠ {cmd} failed (tool may not be installed)"
                    )
            except FileNotFoundError:
                self._logger.warning(f"  ⚠ {cmd.split()[0]} not found, skipping")

        return True
