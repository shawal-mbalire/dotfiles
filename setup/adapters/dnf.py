import subprocess
import shutil
from domain.models.package import Package
from domain.ports.package_manager import PackageManager


class DnfAdapter:
    name = "dnf"

    def __init__(self, copr_repos: dict[str, str] | None = None) -> None:
        self._copr_repos = copr_repos or {}

    def is_available(self) -> bool:
        return shutil.which("dnf") is not None

    def is_installed(self, package: Package) -> bool:
        pkg_name = package.dnf
        if not pkg_name:
            return False
        result = subprocess.run(
            ["rpm", "-q", pkg_name],
            capture_output=True, text=True,
        )
        return result.returncode == 0

    def search_available(self, package: Package) -> bool:
        pkg_name = package.dnf
        if not pkg_name:
            return False
        result = subprocess.run(
            ["dnf", "repoquery", "--quiet", "--queryformat", "%{name}", pkg_name],
            capture_output=True, text=True,
        )
        return result.returncode == 0 and result.stdout.strip() != ""

    def get_package_name(self, package: Package) -> str:
        return package.dnf

    def enable_copr(self, copr: str) -> bool:
        result = subprocess.run(
            ["sudo", "dnf", "copr", "enable", copr, "-y"],
            capture_output=True, text=True,
        )
        return result.returncode == 0

    def install_batch(self, names: list[str], dry_run: bool = False) -> list[str]:
        if not names:
            return []
        if dry_run:
            return []
        result = subprocess.run(
            ["sudo", "dnf", "install", "-y", "--skip-broken"] + names,
            capture_output=True, text=True,
        )
        return names if result.returncode != 0 else []

    def mark_status(self, package: Package) -> Package:
        from domain.models.package import PackageStatus, InstallMethod
        if self.is_installed(package):
            return package.with_status(PackageStatus.INSTALLED, InstallMethod.DNF, package.dnf)
        if self.search_available(package):
            return package.with_status(PackageStatus.AVAILABLE, InstallMethod.DNF, package.dnf)
        return package
