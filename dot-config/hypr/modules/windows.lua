-- Window and workspace rules
local v = require("modules.variables")

-- Blur waybar layer
hl.layer_rule({
  match = { namespace = "waybar" },
  blur = true,
})

-- Notifications drop down from the bar
hl.layer_rule({
  match = { namespace = "notifications" },
  blur = true,
  ignore_alpha = 0.5,
  animation = "slide top",
})

-- Rofi menus (launcher, bluetooth, audio) drop down from the bar
hl.layer_rule({
  match = { namespace = "rofi" },
  blur = true,
  ignore_alpha = 0,
  animation = "slide top",
})
