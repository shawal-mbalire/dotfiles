from domain.models.package import Package
from domain.ports.logger import Logger
from domain.ports.package_manager import PackageManager


def check_packages(
    packages: list[Package],
    managers: list[PackageManager],
    logger: Logger,
) -> tuple[int, int]:
    """Check package status. Returns (installed, missing) counts."""

    installed = 0
    missing = 0

    for pkg in packages:
        found = False
        via = ""

        for mgr in managers:
            if not mgr.is_available():
                continue

            if mgr.is_installed(pkg):
                found = True
                via = mgr.name
                break

        if found:
            logger.success(f"  ✓ {pkg.name} ({via})")
            installed += 1
        else:
            # Check if available in any manager
            available_in = []
            for mgr in managers:
                if mgr.is_available() and mgr.search_available(pkg):
                    available_in.append(mgr.name)

            if available_in:
                logger.warning(
                    f"  → {pkg.name} (available via {', '.join(available_in)})"
                )
                installed += 1
            else:
                logger.error(f"  ✗ {pkg.name}")
                missing += 1

    return installed, missing
