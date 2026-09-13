from domain.models.package import Package
from domain.ports.logger import Logger
from domain.ports.package_manager import PackageManager


def _resolve_package(
    package: Package,
    managers: list[PackageManager],
    dry_run: bool,
    logger: Logger,
) -> tuple[str, str] | None:
    """Try each manager in order. Returns (method, name) or None."""
    for mgr in managers:
        if not mgr.is_available():
            continue

        pkg_name = mgr.get_package_name(package)
        if not pkg_name:
            continue

        if not dry_run and mgr.is_installed(package):
            return ("installed", package.name)

        if mgr.search_available(package):
            return (mgr.name, pkg_name)

        # For packages with COPR, assume available after repo enable
        if hasattr(mgr, "enable_copr") and package.copr and package.dnf:
            return (mgr.name, package.dnf)

    # User fallback
    if package.user:
        return ("user", package.user)

    return None


def _enable_copr_repos(
    packages: list[Package],
    managers: list[PackageManager],
    dry_run: bool,
    logger: Logger,
) -> None:
    """Enable COPR repos for packages that need them."""
    for mgr in managers:
        if not hasattr(mgr, "enable_copr"):
            continue

        copr_needed: set[str] = set()
        for pkg in packages:
            if pkg.copr and pkg.dnf and not mgr.is_installed(pkg):
                copr_needed.add(pkg.copr)

        for copr in copr_needed:
            if dry_run:
                logger.dry_run(f"  [dry-run] sudo dnf copr enable {copr} -y")
            else:
                logger.info(f"  Enabling COPR: {copr}")
                mgr.enable_copr(copr)


def install_packages(
    packages: list[Package],
    managers: list[PackageManager],
    logger: Logger,
    dry_run: bool = False,
) -> tuple[int, int, int]:
    """Install packages. Returns (installed, skipped, failed) counts."""

    queues: dict[str, list[str]] = {}
    user_queue: list[tuple[str, str]] = []
    installed = 0
    skipped = 0
    failed = 0

    # Enable COPR repos first
    _enable_copr_repos(packages, managers, dry_run, logger)

    for pkg in packages:
        method = _resolve_package(pkg, managers, dry_run, logger)

        if method is None:
            logger.warning(f"  {pkg.name} — not found anywhere")
            failed += 1
            continue

        mtype, mval = method

        if mtype == "installed":
            skipped += 1
            continue

        if mtype == "user":
            user_queue.append((pkg.name, mval))
        else:
            queues.setdefault(mtype, []).append(mval)

    # System batches
    for mgr in managers:
        batch = queues.get(mgr.name, [])
        if not batch:
            continue

        logger.info(f"\n{mgr.name}: {len(batch)} packages")
        for p in batch:
            logger.info(f"  + {p}")

        failed_names = mgr.install_batch(batch, dry_run=dry_run)
        installed += len(batch) - len(failed_names)
        failed += len(failed_names)

    # User packages
    if user_queue:
        logger.info(f"\nuser: {len(user_queue)} packages")
        for name, cmd in user_queue:
            logger.info(f"  → {name}")
            if not dry_run:
                import subprocess
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
                if result.returncode != 0:
                    logger.error(f"  [error] {name}: {result.stderr[:200]}")
                    failed += 1
                else:
                    installed += 1
            else:
                logger.dry_run(f"  [dry-run] {cmd}")
                installed += 1

    return installed, skipped, failed
