from domain.models.platform import Platform
from domain.ports.logger import Logger
from domain.ports.platform_setup import PlatformSetup


def setup_platform(
    platform: Platform,
    setup_adapter: PlatformSetup,
    logger: Logger,
    dry_run: bool = False,
) -> bool:
    """Run platform-specific setup."""
    logger.info(f"Setting up {platform.type.value}...")
    return setup_adapter.setup(platform, dry_run)
