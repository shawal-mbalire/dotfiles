import shutil

from domain.models.package import Package


class UserAdapter:
    name = "user"

    def is_available(self) -> bool:
        return True

    def is_installed(self, package: Package) -> bool:
        bin_name = package.bin or package.name
        return shutil.which(bin_name) is not None

    def search_available(self, package: Package) -> bool:
        return bool(package.user)

    def get_package_name(self, package: Package) -> str:
        return package.user

    def install_batch(self, names: list[str], dry_run: bool = False) -> list[str]:
        return []

    def mark_status(self, package: Package) -> Package:
        from domain.models.package import InstallMethod, PackageStatus
        if self.is_installed(package):
            return package.with_status(
                PackageStatus.INSTALLED, InstallMethod.USER, package.name
            )
        return package
