"""Config workflow: assemble the domain ``SwayncConfig`` from deployment data.

Pure: takes the injected config snapshot and returns domain models. Adapters
turn those models into JSON; the domain hardcodes no colours, paths or sizes.
"""

from __future__ import annotations

from domain import constants
from domain.errors import DuplicateWidgetError, InvalidWidgetError
from domain.models import (
    Behavior,
    Layer,
    Layout,
    Margins,
    Position,
    SwayncConfig,
    Widget,
)


def _buttons_grid(config: object, buttons: object, per_row: int, instance: str | None) -> Widget:
    if not buttons:
        raise InvalidWidgetError(constants.WIDGET_BUTTONS_GRID, "at least one button is required")
    return Widget(
        type=constants.WIDGET_BUTTONS_GRID,
        options={"buttons-per-row": per_row, "actions": tuple(buttons)},
        instance=instance,
    )


def widgets(config: object) -> tuple[Widget, ...]:
    """Build the control-center widget list from reusable components."""
    return (
        Widget(
            type=constants.WIDGET_MPRIS,
            options={
                "image-radius": config.mpris_image_radius,
                "autohide": config.mpris_autohide,
                "show-album-art": config.mpris_show_album_art.value,
            },
        ),
        _buttons_grid(config, config.buttons, config.buttons_per_row, None),
        Widget(type=constants.WIDGET_VOLUME, options={"label": config.volume_icon}),
        Widget(type=constants.WIDGET_BACKLIGHT, options={"label": config.backlight_icon}),
        Widget(
            type=constants.WIDGET_NOTIFICATIONS,
            options={"vexpand": config.notifications_vexpand},
        ),
        _buttons_grid(
            config,
            config.clear_buttons,
            config.clear_buttons_per_row,
            constants.WIDGET_INSTANCE_CLEARBAR,
        ),
    )


def behavior(config: object) -> Behavior:
    return Behavior(
        layer_shell=config.layer_shell,
        layer_shell_cover_screen=config.layer_shell_cover_screen,
        css_priority=config.css_priority,
        transition_time_ms=config.transition_time_ms,
        timeout=config.timeout,
        timeout_low=config.timeout_low,
        timeout_critical=config.timeout_critical,
        hide_on_clear=config.hide_on_clear,
        hide_on_action=config.hide_on_action,
        text_empty=config.text_empty,
        script_fail_notify=config.script_fail_notify,
        notification_2fa_action=config.notification_2fa_action,
        inline_replies=config.inline_replies,
        grouping=config.grouping,
        relative_timestamps=config.relative_timestamps,
        image_visibility=config.image_visibility,
        keyboard_shortcuts=config.keyboard_shortcuts,
    )


def build(config: object) -> SwayncConfig:
    """Assemble and validate the whole control-center configuration."""
    built = SwayncConfig(
        schema=config.schema,
        position=Position(x=config.position_x, y=config.position_y),
        layer=Layer(
            layer=config.layer,
            control_center_layer=config.control_center_layer,
        ),
        layout=Layout(
            notification_width=config.notification_width,
            control_center_width=config.control_center_width,
            control_center_height=config.control_center_height,
            fit_to_screen=config.fit_to_screen,
            margins=Margins(
                top=config.margins.top,
                bottom=config.margins.bottom,
                right=config.margins.right,
                left=config.margins.left,
            ),
        ),
        behavior=behavior(config),
        widgets=widgets(config),
    )

    keys = built.widget_keys()
    if len(keys) != len(set(keys)):
        seen: set[str] = set()
        for key in keys:
            if key in seen:
                raise DuplicateWidgetError(key)
            seen.add(key)

    return built
