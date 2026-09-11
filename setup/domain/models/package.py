from dataclasses import dataclass, field
from enum import StrEnum


class InstallMethod(StrEnum):
    DNF = "dnf"
    BREW = "brew"
    FLATPAK = "flatpak"
    USER = "user"
    INSTALLED = "installed"


class PackageStatus(StrEnum):
    INSTALLED = "installed"
    AVAILABLE = "available"
    MISSING = "missing"
    FAILED = "failed"


@dataclass(frozen=True)
class Package:
    name: str
    dnf: str = ""
    brew: str = ""
    flatpak: str = ""
    user: str = ""
    bin: str = ""
    copr: str = ""
    status: PackageStatus = PackageStatus.MISSING
    installed_via: InstallMethod | None = None
    installed_name: str = ""

    @property
    def display_name(self) -> str:
        return self.name

    def with_status(self, status: PackageStatus, via: InstallMethod | None = None, name: str = "") -> "Package":
        return Package(
            name=self.name,
            dnf=self.dnf,
            brew=self.brew,
            flatpak=self.flatpak,
            user=self.user,
            bin=self.bin,
            status=status,
            installed_via=via,
            installed_name=name,
        )
