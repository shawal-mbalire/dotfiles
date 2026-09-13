-- Workflow: configure the wallpaper daemon from domain models.

local models = require("domain.models")

return function(deps)
  local started = deps.time:now_ms()
  local specs = deps.config.wallpaper.wallpapers
  local wallpapers = {}

  for _, spec in ipairs(specs) do
    table.insert(wallpapers, models.Wallpaper.new(spec))
  end

  deps.wallpaper:configure(wallpapers)

  deps.logger:info("wallpaper_configured", {
    count = #wallpapers,
    elapsed_ms = deps.time:elapsed_ms(started),
  })
end
