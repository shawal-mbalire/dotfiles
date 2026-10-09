"""Audio, brightness, and night-light workflows."""

from __future__ import annotations

from domain import constants as C
from domain import logic
from domain.errors import UnavailableError, ValidationError
from domain.ports import AudioPort, BrightnessPort, LoggerPort, NightLightPort
from domain.result import Result, fail, ok


class VolumeWorkflow:
    """Reads like pseudocode: validate → clamp → act → report."""

    def __init__(self, audio: AudioPort, logger: LoggerPort) -> None:
        self._audio = audio
        self._logger = logger

    def set_volume(self, requested: float) -> Result[int]:
        if not logic.is_finite(requested):
            return fail(
                ValidationError("volume must be a finite number", context={"requested": requested})
            )
        if not self._audio.read().ready:
            return fail(UnavailableError("audio sink is not ready"))
        target = int(logic.clamp(round(requested), C.VOLUME_MIN, C.VOLUME_MAX))
        self._audio.set_volume(target)
        self._logger.debug("volume", "set", target=target)
        return ok(target)

    def scroll(self, delta: int) -> Result[int]:
        current = self._audio.read().volume
        ceiling = max(C.VOLUME_BAR_CAP, current)
        return self.set_volume(logic.clamp(current + delta, C.VOLUME_MIN, ceiling))

    def set_muted(self, muted: bool) -> Result[bool]:
        if not self._audio.read().ready:
            return fail(UnavailableError("audio sink is not ready"))
        self._audio.set_muted(muted)
        return ok(muted)

    def toggle_muted(self) -> Result[bool]:
        return self.set_muted(not self._audio.read().muted)


class BrightnessWorkflow:
    def __init__(self, brightness: BrightnessPort, logger: LoggerPort) -> None:
        self._brightness = brightness
        self._logger = logger

    def set_percent(self, requested: float) -> Result[int]:
        if not logic.is_finite(requested):
            return fail(
                ValidationError("brightness must be finite", context={"requested": requested})
            )
        if not self._brightness.read().available:
            return fail(UnavailableError("no backlight device available"))
        target = int(logic.clamp(round(requested), C.BRIGHTNESS_MIN, C.BRIGHTNESS_MAX))
        self._brightness.set_percent(target)
        return ok(target)

    def scroll(self, delta: int) -> Result[int]:
        return self.set_percent(self._brightness.read().percent + delta)


class NightLightWorkflow:
    def __init__(self, nightlight: NightLightPort, logger: LoggerPort) -> None:
        self._nightlight = nightlight
        self._logger = logger

    def set_active(self, active: bool) -> Result[bool]:
        self._nightlight.set_active(active)
        return ok(active)

    def toggle(self) -> Result[bool]:
        return self.set_active(not self._nightlight.read().active)
