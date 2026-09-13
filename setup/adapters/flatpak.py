import shutil
import subprocess

from domain.models.package import Package


class FlatpakAdapter:
    name = "flatpak"

    def is_available(self) -> bool:
        return shutil.which("flatpak") is not None

    def is_installed(self, package: Package) -> bool:
        pkg_name = package.flatpak
        if not pkg_name:
            return False
        result = subprocess.run(
            ["flatpak", "list", "--app", f"--name={pkg_name}"],
            capture_output=True, text=True,
        )
        return result.returncode == 0 and pkg_name in result.stdout

    def search_available(self, package: Package) -> bool:
        pkg_name = package.flatpak
        if not pkg_name:
            return False
        result = subprocess.run(
            ["flatpak", "search", pkg_name],
            capture_output=True, text=True,
        )
        return result.returncode == 0 and pkg_name in result.stdout

    def get_package_name(self, package: Package) -> str:
        return package.flatpak

    def install_batch(self, names: list[str], dry_run: bool = False) -> list[str]:
        if not names or not self.is_available():
            return names
        if dry_run:
            return []
        subprocess.run(
            ["flatpak", "remote-add", "--if-not-exists", "flathub",
             "https://dl.flathub.org/repo/flathub.flatpakrepo"],
            capture_output=True,
        )
        result = subprocess.run(
            ["flatpak", "install", "-y", "flathub"] + names,
            capture_output=True, text=True,
        )
        return names if result.returncode != 0 else []

    def mark_status(self, package: Package) -> Package:
        from domain.models.package import InstallMethod, PackageStatus
        if self.is_installed(package):
            return package.with_status(
                PackageStatus.INSTALLED, InstallMethod.FLATPAK, package.flatpak
            )
        if self.search_available(package):
            return package.with_status(
                PackageStatus.AVAILABLE, InstallMethod.FLATPAK, package.flatpak
            )
        return package
