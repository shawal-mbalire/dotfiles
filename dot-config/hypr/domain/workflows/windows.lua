-- Workflow: layer-surface rules.

local models = require("domain.models")
local constants = require("domain.constants")

return function(deps)
  for _, spec in ipairs(constants.LAYER_RULES) do
    deps.layer:apply_layer_rule(models.LayerRule.new(spec.match, spec.opts))
  end

  deps.logger:info("layer_rules_applied", { count = #constants.LAYER_RULES })
end
