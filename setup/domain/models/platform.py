from dataclasses import dataclass
from enum import StrEnum


class PlatformType(StrEnum):
    FEDORA = "fedora"
    MACOS = "macos"
    LINUX_OTHER = "linux_other"


@dataclass(frozen=True)
class Platform:
    type: PlatformType
    home_dir: str

    @classmethod
    def detect(cls, home_dir: str) -> "Platform":
        import sys
        if sys.platform == "darwin":
            return cls(type=PlatformType.MACOS, home_dir=home_dir)
        else:
            try:
                with open("/etc/os-release") as f:
                    content = f.read().lower()
                    if "fedora" in content:
                        return cls(type=PlatformType.FEDORA, home_dir=home_dir)
            except FileNotFoundError:
                pass
            return cls(type=PlatformType.LINUX_OTHER, home_dir=home_dir)
