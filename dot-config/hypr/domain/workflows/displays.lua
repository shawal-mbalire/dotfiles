-- Workflow: configure outputs from config.

local models = require("domain.models")

return function(deps)
  local started = deps.time:now_ms()
  local count = 0

  for _, spec in ipairs(deps.config.displays) do
    local display = models.Display.new(spec.output, spec.mode, spec.position, spec.scale, spec.mirror)
    deps.monitor:apply_monitor(display)
    deps.logger:debug("monitor_applied", { output = display.output })
    count = count + 1
  end

  deps.logger:info("displays_configured", {
    count = count,
    elapsed_ms = deps.time:elapsed_ms(started),
  })
end
