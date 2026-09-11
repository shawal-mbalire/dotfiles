-- Workflow: general, decoration, curves and animations.

local models = require("domain.models")
local constants = require("domain.constants")

return function(deps)
  local started = deps.time:now_ms()
  local visual = deps.config.visual
  local colors = deps.config.colors

  local settings = models.VisualSettings.new({
    gaps_in = visual.gaps_in,
    gaps_out = visual.gaps_out,
    border_size = visual.border_size,
    colors = {
      active = models.Color.from_hex(colors.active.hex, colors.active.alpha),
      inactive = models.Color.from_hex(colors.inactive.hex, colors.inactive.alpha),
      shadow = models.Color.from_hex(colors.shadow.hex, colors.shadow.alpha),
    },
    gradient_angle = visual.gradient_angle,
    resize_on_border = visual.resize_on_border,
    allow_tearing = visual.allow_tearing,
    rounding = visual.rounding,
    rounding_power = visual.rounding_power,
    active_opacity = visual.active_opacity,
    inactive_opacity = visual.inactive_opacity,
    shadow_enabled = visual.shadow_enabled,
    shadow_range = visual.shadow_range,
    shadow_render_power = visual.shadow_render_power,
    blur_enabled = visual.blur_enabled,
    blur_size = visual.blur_size,
    blur_passes = visual.blur_passes,
    blur_vibrancy = visual.blur_vibrancy,
    force_default_wallpaper = visual.force_default_wallpaper,
    disable_hyprland_logo = visual.disable_hyprland_logo,
  })

  deps.visual:configure_visual(settings)

  for _, curve in ipairs(constants.CURVES) do
    deps.visual:register_curve(models.Bezier.new(curve.name, curve.points))
  end

  for _, anim in ipairs(constants.ANIMATIONS) do
    deps.visual:register_animation(models.Anim.new(anim.leaf, anim.speed, anim.bezier, anim.style))
  end

  deps.logger:info("look_configured", {
    curves = #constants.CURVES,
    animations = #constants.ANIMATIONS,
    elapsed_ms = deps.time:elapsed_ms(started),
  })
end
