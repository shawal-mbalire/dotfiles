-- Language Plugins
-- Adapter layer: translates domain language preferences into plugin specs.
-- To add a new language plugin:
--   1. Add preference to lua/domain/languages.lua
--   2. Create adapter in lua/adapters/<plugin>.lua
--   3. Add adapter.spec() call below
--
-- LazyVim language extras are enabled in lazyvim.json.
-- This file only handles custom language plugins not covered by LazyVim.

local specs = {}

-- Python venv selector (via adapter)
local venv = require("adapters.venv_selector").spec()
if venv then table.insert(specs, venv) end

-- MQL filetype support (via adapter)
local mql = require("adapters.mql_filetype").spec()
if mql then table.insert(specs, mql) end

return specs
