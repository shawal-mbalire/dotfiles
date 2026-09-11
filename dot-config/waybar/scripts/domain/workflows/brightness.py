"""Brightness workflow: smooth steps at low levels plus preset menu."""

from __future__ import annotations

from domain.constants import (
    BRIGHTNESS_LOW_PERCENT,
    BRIGHTNESS_MID_PERCENT,
    BRIGHTNESS_PRESETS,
    BRIGHTNESS_STEP_HIGH,
    BRIGHTNESS_STEP_LOW,
    BRIGHTNESS_STEP_MID,
)
from domain.ports.core import Logger, Prompt
from domain.ports.system import BrightnessGateway


def step_for(percent: int, direction: str) -> int:
    """Smaller steps at low brightness so the jump is never jarring."""
    if direction == "up":
        if percent < BRIGHTNESS_LOW_PERCENT:
            return BRIGHTNESS_STEP_LOW
        if percent < BRIGHTNESS_MID_PERCENT:
            return BRIGHTNESS_STEP_MID
        return BRIGHTNESS_STEP_HIGH

    if percent <= BRIGHTNESS_LOW_PERCENT:
        return BRIGHTNESS_STEP_LOW
    if percent <= BRIGHTNESS_MID_PERCENT:
        return BRIGHTNESS_STEP_MID
    return BRIGHTNESS_STEP_HIGH


def brightness_delta(percent: int, direction: str) -> int:
    """Signed delta to apply, clamping so the level never drops below 1%."""
    step = step_for(percent, direction)
    if direction == "up":
        return step

    if percent - step < 1:
        return -(percent - 1)
    return -step


def adjust(gateway: BrightnessGateway, direction: str, logger: Logger) -> None:
    percent = gateway.get_percent()
    delta = brightness_delta(percent, direction)
    if delta == 0:
        logger.debug("brightness at minimum, no change")
        return
    gateway.set_relative(delta)
    logger.debug(f"brightness {percent}% {delta:+d}")


def choose_preset(gateway: BrightnessGateway, prompt: Prompt, logger: Logger) -> None:
    chosen = prompt.choose(list(BRIGHTNESS_PRESETS), "Brightness")
    if not chosen:
        return
    percent = int(chosen.rstrip("%"))
    gateway.set_percent(percent)
    logger.info(f"brightness preset -> {percent}%")
