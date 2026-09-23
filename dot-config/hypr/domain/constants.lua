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
  { name = "linear",         points = { { 0, 0 },       { 1, 1 } } },
  { name = "quick",          points = { { 0.15, 0 },    { 0.1, 1 } } },
}

-- Animations (fast, minimal)
M.ANIMATIONS = {
  { leaf = "global",        speed = 4,   bezier = "default" },
  { leaf = "border",        speed = 3,   bezier = "easeOutQuint" },
  { leaf = "windows",       speed = 3,   bezier = "easeOutQuint" },
  { leaf = "windowsIn",     speed = 3,   bezier = "easeOutQuint", style = "popin 87%" },
  { leaf = "windowsOut",    speed = 4,   bezier = "linear",       style = "popin 87%" },
  { leaf = "fade",          speed = 3,   bezier = "quick" },
  { leaf = "workspaces",    speed = 0.05, bezier = "linear",      style = "fade" },
  { leaf = "workspacesIn",  speed = 0.05, bezier = "linear",      style = "fade" },
  { leaf = "workspacesOut", speed = 0.05, bezier = "linear",      style = "fade" },
}

-- Layer-surface rules (static domain knowledge about known clients)
M.LAYER_RULES = {
  { match = { namespace = "^(quickshell.*)$" }, opts = { blur = false, ignore_alpha = 0.2 } },
}

-- Window rules (static domain knowledge about known clients)
M.WINDOW_RULES = {}

return M
