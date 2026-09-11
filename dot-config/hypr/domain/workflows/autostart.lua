-- Workflow: spawn background services.
-- Pure/stateless: the composition root wires the compositor's start event to
-- this workflow, so no closure over deps lives inside the domain.

return function(deps)
  for _, command in ipairs(deps.config.autostart) do
    deps.command:run_command(command)
    deps.logger:debug("autostart_spawned", { command = command })
  end
  deps.logger:info("autostart_complete", { count = #deps.config.autostart })
end
