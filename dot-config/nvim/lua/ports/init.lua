-- Ports: Capability contracts
-- Each port defines WHAT capability the domain needs.
-- Adapters implement HOW that capability is fulfilled.
--
-- In Lua, ports are duck-typed interfaces documented here.
-- Each port module returns a table describing the expected shape.
--
-- Adding a new capability:
--   1. Define the port here (what you need)
--   2. Implement an adapter (which plugin provides it)
--   3. Create a plugin spec file in the appropriate category

return {
  colorscheme = require("ports.colorscheme"),
  navigation = require("ports.navigation"),
  session = require("ports.session"),
  render = require("ports.render"),
  venv = require("ports.venv"),
}
