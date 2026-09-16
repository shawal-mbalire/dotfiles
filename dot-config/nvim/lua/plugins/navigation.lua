-- Navigation Plugins
-- Adapter layer: translates domain navigation preferences into plugin specs.
-- To add a new navigation plugin:
--   1. Add preference to lua/domain/navigation.lua
--   2. Create adapter in lua/adapters/<plugin>.lua
--   3. Add adapter.spec() call below

local specs = {}

-- Tmux navigator (via adapter)
local tmux = require("adapters.tmux_navigator").spec()
if tmux then table.insert(specs, tmux) end

return specs
