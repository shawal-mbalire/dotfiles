-- Entry point (composition root).
-- Reads config, creates adapters, injects ports into domain workflows.

local config = require("infra.config")
local constants = require("domain.constants")
local Adapter = require("adapters.hyprland_adapter")
local HyprpaperAdapter = require("adapters.hyprpaper_adapter")
local Logger = require("adapters.console_logger")
local SystemTime = require("adapters.system_time")
local ProcessLifetime = require("adapters.process_lifetime")
local LifetimePort = require("domain.ports.lifetime")
local verify = require("domain.ports.verify")
local autostart = require("domain.workflows.autostart")
local wallpaper_daemon = require("domain.workflows.wallpaper_daemon")

local logger = Logger.new({ min_level = config.log_level, prefix = "[hypr]" })
local time = SystemTime.new()
local lifetime = ProcessLifetime.new()
local hypr = Adapter.new(hl)
local wallpaper = HyprpaperAdapter.new({ conf_path = config.wallpaper.conf_path, command = hypr })

-- Fail loud if any adapter drifts from its port contract.
verify.assert_ports(hypr, verify.HYPR_PORTS)
verify.assert_port(wallpaper, verify.wallpaper)
verify.assert_port(logger, verify.logger)
verify.assert_port(time, verify.time)
verify.assert_port(lifetime, verify.lifetime)

local deps = {
  config = config,
  logger = logger,
  time = time,
  lifetime = lifetime,
  monitor = hypr,
  environment = hypr,
  input = hypr,
  binding = hypr,
  command = hypr,
  visual = hypr,
  layer = hypr,
  runtime = hypr,
  wallpaper = wallpaper,
}

local WORKFLOWS = {
  "domain.workflows.displays",
  "domain.workflows.env",
  "domain.workflows.look",
  "domain.workflows.wallpaper",
  "domain.workflows.input",
  "domain.workflows.keybindings",
  "domain.workflows.windows",
}

lifetime:register_cleanup(function()
  logger:debug("shutdown_cleanup_complete")
end)

lifetime:on_exit(function(reason)
  logger:info("config_lifetime_ended", { reason = reason })
end)

local started = time:now_ms()

local ok, err = xpcall(function()
  for _, module in ipairs(WORKFLOWS) do
    require(module)(deps)
  end

  -- Autostart is event-driven: the composition root wires the compositor
  -- events to the pure workflows. config.reloaded re-ensures the wallpaper
  -- daemon so a reload does not leave the screen bare.
  deps.runtime:on_event(constants.EVENTS.START, function()
    autostart(deps)
    wallpaper_daemon(deps)
  end)

  deps.runtime:on_event(constants.EVENTS.RELOAD, function()
    wallpaper_daemon(deps)
  end)
end, debug.traceback)

if not ok then
  lifetime:set_reason(LifetimePort.REASON.CRASH)
  logger:error("config_load_failed", { error = tostring(err) })
  lifetime:shutdown(LifetimePort.REASON.CRASH)
  error(err)
end

lifetime:set_reason(LifetimePort.REASON.NORMAL)
logger:info("config_loaded", {
  profile = config.profile,
  elapsed_ms = time:elapsed_ms(started),
})
lifetime:shutdown(LifetimePort.REASON.NORMAL)
