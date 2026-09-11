"""Power-profile workflow: resolve, present, cycle and set profiles."""

from __future__ import annotations

from domain.constants import (
    ACCENT_BATTERY,
    DEFAULT_POWER_PROFILE,
    MARKUP_CLOSE,
    MARKUP_LABEL,
    MARKUP_VALUE,
    POWER_ACCENTS,
    POWER_PROFILES,
)
from domain.errors import UnknownPowerProfileError
from domain.models import ModuleOutput, PowerProfile
from domain.ports.core import BarGateway, Logger, Notifier, Prompt, TimePort
from domain.ports.power import PowerGateway


def profile_names() -> tuple[str, ...]:
    return tuple(profile.name for profile in POWER_PROFILES)


def find_profile(name: str) -> PowerProfile | None:
    return next((profile for profile in POWER_PROFILES if profile.name == name), None)


def profile_by_label(label: str) -> PowerProfile | None:
    return next((profile for profile in POWER_PROFILES if profile.label == label), None)


def exists(name: str) -> bool:
    return find_profile(name) is not None


def next_profile(current: str) -> PowerProfile:
    """Return the next profile in cycle order, wrapping around."""
    names = profile_names()
    try:
        index = names.index(current)
    except ValueError:
        return POWER_PROFILES[0]
    return POWER_PROFILES[(index + 1) % len(POWER_PROFILES)]


def validate_current(candidate: str | None) -> PowerProfile:
    """Normalise an adapter-reported profile, falling back to the default."""
    return find_profile(candidate or "") or find_profile(DEFAULT_POWER_PROFILE) or POWER_PROFILES[0]


def _accent(profile: PowerProfile) -> str:
    return POWER_ACCENTS.get(profile.css_class, ACCENT_BATTERY)


def tooltip(profile: PowerProfile) -> str:
    return (
        f"<span foreground='{_accent(profile)}' font_weight='bold'>POWER{MARKUP_CLOSE}\n"
        f"{MARKUP_LABEL}Profile{MARKUP_CLOSE}  "
        f"{MARKUP_VALUE}{profile.label}{MARKUP_CLOSE}"
    )


def status_output(profile: PowerProfile) -> ModuleOutput:
    return ModuleOutput(text=profile.label, tooltip=tooltip(profile), css_class=profile.css_class)


def pill_output(profile: PowerProfile) -> ModuleOutput:
    return ModuleOutput(text=profile.icon, tooltip=tooltip(profile), css_class=profile.css_class)


def resolve_current(gateway: PowerGateway, logger: Logger, time: TimePort) -> PowerProfile:
    start = time.now_ms()
    raw = gateway.get_active()
    profile = validate_current(raw)
    logger.debug(f"power resolved {profile.name} in {time.elapsed_ms(start)}ms")
    return profile


def set_profile(
    name: str,
    gateway: PowerGateway,
    notifier: Notifier,
    bar: BarGateway,
    logger: Logger,
    time: TimePort,
    signal: int,
) -> bool:
    profile = find_profile(name)
    if profile is None:
        notifier.notify("Power Profile", f"Unknown profile: {name}", "critical")
        raise UnknownPowerProfileError(name)

    start = time.now_ms()
    if not gateway.set_profile(name):
        notifier.notify("Power Profile", f"Failed to switch to: {profile.label}", "critical")
        return False

    logger.debug(f"power set {name} in {time.elapsed_ms(start)}ms")
    notifier.notify("Power Profile", f"Switched to: {profile.label}")
    bar.refresh(signal)
    return True


def cycle(
    gateway: PowerGateway,
    notifier: Notifier,
    bar: BarGateway,
    logger: Logger,
    time: TimePort,
    signal: int,
) -> bool:
    current = resolve_current(gateway, logger, time)
    return set_profile(
        next_profile(current.name).name, gateway, notifier, bar, logger, time, signal
    )


def select(
    gateway: PowerGateway,
    prompt: Prompt,
    notifier: Notifier,
    bar: BarGateway,
    logger: Logger,
    time: TimePort,
    signal: int,
) -> bool:
    current = resolve_current(gateway, logger, time)
    lines = [
        f"{profile.label}  ✓" if profile.name == current.name else profile.label
        for profile in POWER_PROFILES
    ]
    chosen = prompt.choose(lines, "Power Profile")
    if not chosen:
        return True

    label = chosen.removesuffix("  ✓")
    profile = profile_by_label(label)
    if profile is None:
        return True
    return set_profile(profile.name, gateway, notifier, bar, logger, time, signal)
