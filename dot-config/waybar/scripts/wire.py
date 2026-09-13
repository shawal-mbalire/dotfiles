"""Composition root: build concrete adapters from typed config.

This is the only module that imports every adapter. Driving adapters (the CLI)
ask ``wire`` for collaborators; domain workflows only ever see the ports. Every
value a concrete adapter needs is injected here from :class:`infra.config.Config`
— no adapter reads the environment itself.
"""

from __future__ import annotations

from domain.ports.audio import AudioControl, AudioDevices
from domain.ports.bluetooth import BluetoothGateway, BluetoothPowerState
from domain.ports.core import (
    BarGateway,
    LifetimePort,
    Logger,
    Notifier,
    Prompt,
    SoundPlayer,
    TimePort,
)
from domain.ports.power import PowerGateway
from domain.ports.system import (
    BatteryGateway,
    BrightnessGateway,
    NetworkGateway,
    NightLightGateway,
)
from infra.config import Config

# ── Cross-cutting adapters ──────────────────────────────────────────────────


def build_logger(config: Config) -> Logger:
    from adapters.console_logger import ConsoleLogger

    return ConsoleLogger(config.log_level)


def build_notifier(config: Config) -> Notifier:
    from adapters.notify_send import NotifySend

    return NotifySend(config.notify_app, config.notify_urgency)


def build_prompt(config: Config) -> Prompt:
    from adapters.fuzzel_prompt import FuzzelPrompt

    return FuzzelPrompt(config.prompt_theme)


def build_bar() -> BarGateway:
    from adapters.waybar_bar import WaybarBar

    return WaybarBar()


def build_sound() -> SoundPlayer:
    from adapters.pw_play import PwPlay

    return PwPlay()


def build_time() -> TimePort:
    from adapters.system_time import SystemTime

    return SystemTime()


def build_lifetime(logger: Logger) -> LifetimePort:
    from adapters.process_lifetime import ProcessLifetime

    return ProcessLifetime(logger)


# ── Status adapters (poll + refresh) ────────────────────────────────────────


def build_network() -> NetworkGateway:
    from adapters.proc_network import ProcNetwork

    return ProcNetwork()


def build_battery(config: Config) -> BatteryGateway:
    from adapters.sysfs_battery import SysfsBattery

    return SysfsBattery(config.battery_supply)


def build_backlight(config: Config) -> BrightnessGateway:
    from adapters.sysfs_backlight import SysfsBacklight

    return SysfsBacklight(config.backlight_device)


def build_nightlight(config: Config) -> NightLightGateway:
    from adapters.proc_nightlight import GammaStepNightLight

    return GammaStepNightLight("gammastep", config.gammastep_temperature)


def build_bluetooth_power() -> BluetoothPowerState:
    from adapters.rfkill_bluetooth import RfkillBluetoothPower

    return RfkillBluetoothPower()


# ── Control adapters (actions) ──────────────────────────────────────────────


def build_power_gateway(config: Config) -> PowerGateway:
    from adapters.busctl_power import BusctlPowerGateway

    return BusctlPowerGateway(config.power_bus, config.power_path, config.power_iface)


def build_audio_control(config: Config) -> AudioControl:
    from adapters.wpctl_audio import WpctlAudioControl

    return WpctlAudioControl(config.audio_sink, config.volume_max)


def build_audio_devices(config: Config) -> AudioDevices:
    from adapters.pactl_audio import PactlAudioDevices

    return PactlAudioDevices(config.audio_description_strip, config.audio_description_codec)


def build_bluetooth_gateway() -> BluetoothGateway:
    from adapters.bluetoothctl_gateway import BluetoothctlGateway

    return BluetoothctlGateway()
