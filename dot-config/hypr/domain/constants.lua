-- Domain constants (named, no magic numbers)
--
-- Static constants: pure business knowledge, fixed rules. Deployment-specific
-- values (paths, env overrides) live in infra/config.lua instead.

local M = {}

-- Window management
M.RESIZE_STEP = 20
M.MAX_WS = 10
M.SPECIAL_WS = "magic"

-- Wallpaper fit modes (static vocabulary for the wallpaper engine)
M.WALLPAPER_FIT = {
  DEFAULT = "cover",
}

-- Compositor lifecycle events (driving-adapter vocabulary)
M.EVENTS = {
  START = "hyprland.start",
  RELOAD = "config.reloaded",
}

-- Bind action kinds (domain vocabulary, mapped to dispatchers by adapters)
M.ACTION = {
  EXEC_CMD  = "exec_cmd",
  WINDOW    = "window",
  FOCUS     = "focus",
  WORKSPACE = "workspace",
}

-- Window sub-actions
M.WINDOW_ACTION = {
  MOVE   = "move",
  FLOAT  = "float",
  CLOSE  = "close",
  PSEUDO = "pseudo",
  DRAG   = "drag",
  RESIZE = "resize",
}

-- Pointer button codes used as bind keys
M.MOUSE = {
  LEFT  = "mouse:272",
  RIGHT = "mouse:273",
}

-- Animation curves (static aesthetic rules)
M.CURVES = {
  { name = "easeOutQuint",   points = { { 0.23, 1 },    { 0.32, 1 } } },
  { name = "easeInOutCubic", points = { { 0.65, 0.05 }, { 0.36, 1 } } },
  { name = "linear",         points = { { 0, 0 },       { 1, 1 } } },
  { name = "almostLinear",   points = { { 0.5, 0.5 },   { 0.75, 1 } } },
  { name = "quick",          points = { { 0.15, 0 },    { 0.1, 1 } } },
}

-- Animations (static aesthetic rules)
M.ANIMATIONS = {
  { leaf = "global",        speed = 10,   bezier = "default" },
  { leaf = "border",        speed = 5.39, bezier = "easeOutQuint" },
  { leaf = "windows",       speed = 4.79, bezier = "easeOutQuint" },
  { leaf = "windowsIn",     speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" },
  { leaf = "windowsOut",    speed = 1.49, bezier = "linear",       style = "popin 87%" },
  { leaf = "fadeIn",        speed = 1.73, bezier = "almostLinear" },
  { leaf = "fadeOut",       speed = 1.46, bezier = "almostLinear" },
  { leaf = "fade",          speed = 3.03, bezier = "quick" },
  { leaf = "layers",        speed = 3.81, bezier = "easeOutQuint" },
  { leaf = "layersIn",      speed = 4,    bezier = "easeOutQuint", style = "fade" },
  { leaf = "layersOut",     speed = 1.5,  bezier = "linear",       style = "fade" },
  { leaf = "fadeLayersIn",  speed = 1.79, bezier = "almostLinear" },
  { leaf = "fadeLayersOut", speed = 1.39, bezier = "almostLinear" },
  { leaf = "workspaces",    speed = 1.94, bezier = "almostLinear", style = "fade" },
  { leaf = "workspacesIn",  speed = 1.21, bezier = "almostLinear", style = "fade" },
  { leaf = "workspacesOut", speed = 1.94, bezier = "almostLinear", style = "fade" },
}

-- Layer-surface rules (static domain knowledge about known clients)
M.LAYER_RULES = {
  { match = { namespace = "waybar" }, opts = { blur = true } },
  { match = { namespace = "swaync" }, opts = { blur = true, ignore_alpha = 0, animation = "slide top" } },
  { match = { namespace = "fuzzel" }, opts = { blur = true, ignore_alpha = 0, animation = "slide top" } },
}

return M
