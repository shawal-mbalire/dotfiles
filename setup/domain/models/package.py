from dataclasses import dataclass
from enum import StrEnum


class InstallMethod(StrEnum):
    DNF = "dnf"
    BREW = "brew"
    FLATPAK = "flatpak"
    SNAP = "snap"
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
    snap: str = ""
    snap_classic: bool = False
    user: str = ""
    bin: str = ""
    copr: str = ""
    status: PackageStatus = PackageStatus.MISSING
    installed_via: InstallMethod | None = None
    installed_name: str = ""

    @property
    def display_name(self) -> str:
        return self.name

    def with_status(
        self,
        status: PackageStatus,
        via: InstallMethod | None = None,
        name: str = "",
    ) -> "Package":
        return Package(
            name=self.name,
            dnf=self.dnf,
            brew=self.brew,
            flatpak=self.flatpak,
            snap=self.snap,
            snap_classic=self.snap_classic,
            user=self.user,
            bin=self.bin,
            status=status,
            installed_via=via,
            installed_name=name,
        )
