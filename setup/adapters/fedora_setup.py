import subprocess
from pathlib import Path
from domain.models.platform import Platform, PlatformType
from domain.ports.platform_setup import PlatformSetup
from domain.ports.logger import Logger


class FedoraSetup:
    def __init__(self, logger: Logger) -> None:
        self._logger = logger

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
                    self._logger.warning(f"  ⚠ {cmd} failed (tool may not be installed)")
            except FileNotFoundError:
                self._logger.warning(f"  ⚠ {cmd.split()[0]} not found, skipping")

        return True
