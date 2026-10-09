"""Runtime configuration — the only place environment variables are read.

The composition root calls :func:`load_config` once and injects the resulting
frozen struct into adapters. Domain code never reads the environment.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True, slots=True)
class AppConfig:
    """Immutable, deployment-specific settings."""

    # Paths
    home: Path
    config_dir: Path
    state_dir: Path
    runtime_dir: Path
    wallpaper_dir: Path
    clipboard_store: Path
    log_file: Path

    # Hyprland
    hyprland_signature: str
    hyprland_socket: Path

    # Capability toggles / tuning
    brightness_device: str
    night_light_temperature: int
    clipboard_max_items: int
    bar_height: int
    monitor_filter: str

    # Which driven adapters to use (composition root maps these to classes).
    audio_driver: str
    network_driver: str
    bluetooth_driver: str
    clipboard_driver: str
    notifications_driver: str
    wallpaper_driver: str
    nightlight_driver: str
    launcher_driver: str


def _env_path(name: str, default: str) -> Path:
    return Path(os.environ.get(name, default)).expanduser()


def _env_str(name: str, default: str) -> str:
    return os.environ.get(name, default)


def _env_int(name: str, default: int) -> int:
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    try:
        return int(raw)
    except ValueError as exc:
        raise ValueError(f"{name} must be an integer, got {raw!r}") from exc


def load_config() -> AppConfig:
    """Read the environment and assemble the frozen config struct.

    Raises ``ValueError`` for invalid values (fail fast). The composition root
    turns that into an ``AppError(ErrorCode.CONFIG)``.
    """
    home = _env_path("HOME", "~")
    xdg_config = _env_path("XDG_CONFIG_HOME", str(home / ".config"))
    xdg_state = _env_path("XDG_STATE_HOME", str(home / ".local/state"))
    xdg_runtime = _env_path("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")

    signature = _env_str("HYPRLAND_INSTANCE_SIGNATURE", "")
    hypr_socket = xdg_runtime / "hypr" / signature / ".socket.sock" if signature else Path("")

    state_dir = xdg_state / "fabric"

    return AppConfig(
        home=home,
        config_dir=xdg_config / "fabric",
        state_dir=state_dir,
        runtime_dir=xdg_runtime,
        wallpaper_dir=_env_path("FABRIC_WALLPAPER_DIR", str(home / "wallpapers")),
        clipboard_store=state_dir / "clipboard.json",
        log_file=state_dir / "fabric.log",
        hyprland_signature=signature,
        hyprland_socket=hypr_socket,
        brightness_device=_env_str("FABRIC_BACKLIGHT_DEVICE", ""),
        night_light_temperature=_env_int("FABRIC_NIGHT_LIGHT_TEMP", 16000),
        clipboard_max_items=_env_int("FABRIC_CLIPBOARD_MAX_ITEMS", 50),
        bar_height=_env_int("FABRIC_BAR_HEIGHT", 30),
        monitor_filter=_env_str("FABRIC_MONITOR", ""),
        audio_driver=_env_str("FABRIC_AUDIO_DRIVER", "pipewire"),
        network_driver=_env_str("FABRIC_NETWORK_DRIVER", "nm"),
        bluetooth_driver=_env_str("FABRIC_BLUETOOTH_DRIVER", "bluez"),
        clipboard_driver=_env_str("FABRIC_CLIPBOARD_DRIVER", "gdk"),
        notifications_driver=_env_str("FABRIC_NOTIFICATIONS_DRIVER", "dbus"),
        wallpaper_driver=_env_str("FABRIC_WALLPAPER_DRIVER", "native"),
        nightlight_driver=_env_str("FABRIC_NIGHTLIGHT_DRIVER", "hyprsunset"),
        launcher_driver=_env_str("FABRIC_LAUNCHER_DRIVER", "desktop-entries"),
    )
