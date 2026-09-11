-- Window and workspace rules
local v = require("modules.variables")

-- Blur waybar layer
hl.layer_rule({
  match = { namespace = "waybar" },
  blur = true,
})

-- SwayNC notifications
hl.layer_rule({
  match = { namespace = "swaync" },
  blur = true,
  ignore_alpha = 0,
  animation = "slide top",
})

-- Fuzzel menus (launcher, bluetooth, audio) drop down from the bar
hl.layer_rule({
  match = { namespace = "fuzzel" },
  blur = true,
  ignore_alpha = 0,
  animation = "slide top",
})
