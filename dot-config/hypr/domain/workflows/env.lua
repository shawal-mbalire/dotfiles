-- Workflow: set environment variables from config.

return function(deps)
  local started = deps.time:now_ms()
  local count = 0

  for name, value in pairs(deps.config.env) do
    deps.environment:set_env(name, value)
    deps.logger:debug("env_set", { name = name })
    count = count + 1
  end

  deps.logger:info("env_configured", {
    count = count,
    elapsed_ms = deps.time:elapsed_ms(started),
  })
end
