import shutil
import subprocess

from domain.models.package import Package


class SnapAdapter:
    name = "snap"

    def __init__(self, classic: set[str] | None = None) -> None:
        self._classic = classic or set()

    def is_available(self) -> bool:
        return shutil.which("snap") is not None

    def is_installed(self, package: Package) -> bool:
        pkg_name = package.snap
        if not pkg_name:
            return False
        result = subprocess.run(
            ["snap", "list", pkg_name],
            capture_output=True, text=True,
        )
        return result.returncode == 0 and pkg_name in result.stdout

    def search_available(self, package: Package) -> bool:
        pkg_name = package.snap
        if not pkg_name:
            return False
        result = subprocess.run(
            ["snap", "find", pkg_name],
            capture_output=True, text=True,
        )
        return result.returncode == 0 and pkg_name in result.stdout

    def get_package_name(self, package: Package) -> str:
        return package.snap

    def install_batch(self, names: list[str], dry_run: bool = False) -> list[str]:
        if not names or not self.is_available():
            return names
        if dry_run:
            return []
        failed = []
        for name in names:
            cmd = ["sudo", "snap", "install", name]
            if name in self._classic:
                cmd.append("--classic")
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                failed.append(name)
        return failed

    def mark_status(self, package: Package) -> Package:
        from domain.models.package import InstallMethod, PackageStatus
        if self.is_installed(package):
            return package.with_status(
                PackageStatus.INSTALLED, InstallMethod.SNAP, package.snap
            )
        if self.search_available(package):
            return package.with_status(
                PackageStatus.AVAILABLE, InstallMethod.SNAP, package.snap
            )
        return package
