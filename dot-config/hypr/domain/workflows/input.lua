-- Workflow: keyboard, pointer and device configuration.

local models = require("domain.models")

return function(deps)
  local started = deps.time:now_ms()
  local input = deps.config.input

  deps.input:configure_input(models.InputSettings.new({
    keyboard = {
      layout = input.kb_layout,
      variant = input.kb_variant,
      model = input.kb_model,
      options = input.kb_options,
      rules = input.kb_rules,
    },
    follow_mouse = input.follow_mouse,
    sensitivity = input.sensitivity,
    touchpad = input.touchpad,
  }))

  deps.input:configure_device(models.Device.new(input.mouse.name, input.mouse))

  deps.logger:info("input_configured", {
    layout = input.kb_layout,
    elapsed_ms = deps.time:elapsed_ms(started),
  })
end
