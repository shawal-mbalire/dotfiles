-- Workflow: layer-surface and window rules.

local models = require("domain.models")
local constants = require("domain.constants")

return function(deps)
  local started = deps.time:now_ms()

  for _, spec in ipairs(constants.LAYER_RULES) do
    deps.layer:apply_layer_rule(models.LayerRule.new(spec.match, spec.opts))
  end

  for _, spec in ipairs(constants.WINDOW_RULES) do
    deps.window_rule:apply_window_rule(models.WindowRule.new(spec.match, spec.opts))
  end

  deps.logger:info("rules_applied", {
    layer = #constants.LAYER_RULES,
    window = #constants.WINDOW_RULES,
    elapsed_ms = deps.time:elapsed_ms(started),
  })
end
