-- UI Plugins
-- Adapter layer: translates domain UI preferences into plugin specs.
-- To add a new UI plugin:
--   1. Add preference to lua/domain/ui.lua
--   2. Create adapter in lua/adapters/<plugin>.lua
--   3. Add adapter.spec() call below

local specs = {}

-- Catppuccin colorscheme (via adapter)
local catppuccin = require("adapters.catppuccin").spec()
if catppuccin then table.insert(specs, catppuccin) end

-- Neovim renderer plugins (via adapter)
local renderer = require("adapters.renderer").spec()
if renderer then table.insert(specs, renderer) end

return specs
