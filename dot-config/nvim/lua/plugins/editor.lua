-- Editor Plugins
-- Adapter layer: translates domain editor preferences into plugin specs.
-- To add a new editor plugin:
--   1. Add preference to lua/domain/editor.lua
--   2. Create adapter in lua/adapters/<plugin>.lua
--   3. Add adapter.spec() call below

local specs = {}

-- Session persistence (via adapter)
local persistence = require("adapters.persistence").spec()
if persistence then table.insert(specs, persistence) end

return specs
