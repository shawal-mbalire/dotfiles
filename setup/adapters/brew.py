import subprocess
import shutil
from domain.models.package import Package
from domain.ports.package_manager import PackageManager


class BrewAdapter:
    name = "brew"

    def is_available(self) -> bool:
        return shutil.which("brew") is not None

    def is_installed(self, package: Package) -> bool:
        pkg_name = package.brew
        if not pkg_name:
            return False
        result = subprocess.run(
            ["brew", "list", "--formula", pkg_name],
            capture_output=True, text=True,
        )
        return result.returncode == 0

    def search_available(self, package: Package) -> bool:
        pkg_name = package.brew
        if not pkg_name:
            return False
        result = subprocess.run(
            ["brew", "search", pkg_name],
            capture_output=True, text=True,
        )
        return result.returncode == 0 and pkg_name in result.stdout

    def get_package_name(self, package: Package) -> str:
        return package.brew

    def install_batch(self, names: list[str], dry_run: bool = False) -> list[str]:
        if not names or not self.is_available():
            return names
        if dry_run:
            return []
        result = subprocess.run(
            ["brew", "install"] + names,
            capture_output=True, text=True,
        )
        return names if result.returncode != 0 else []

    def mark_status(self, package: Package) -> Package:
        from domain.models.package import PackageStatus, InstallMethod
        if self.is_installed(package):
            return package.with_status(PackageStatus.INSTALLED, InstallMethod.BREW, package.brew)
        if self.search_available(package):
            return package.with_status(PackageStatus.AVAILABLE, InstallMethod.BREW, package.brew)
        return package
