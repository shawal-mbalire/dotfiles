-- Integration test: load the real composition root against a fake hl.
-- Proves the whole config wires up without touching a live compositor.
--
-- Usage (from the hypr config directory): lua tests/integration/run.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local fake_hl = require("tests.fixtures.fake_hl")

local hl = fake_hl.new()
_G.hl = hl

local ok, err = pcall(dofile, "hyprland.lua")
if not ok then
  io.stderr:write("FAIL  config failed to load: " .. tostring(err) .. "\n")
  os.exit(1)
end

local failed = 0

local function expect(name, actual, minimum)
  if actual < minimum then
    io.write(string.format("FAIL  %s: expected >= %d, got %d\n", name, minimum, actual))
    failed = failed + 1
  else
    io.write(string.format("PASS  %s (%d)\n", name, actual))
  end
end

expect("monitors applied", hl:count("monitor"), 1)
expect("env vars set", hl:count("env"), 1)
expect("input configured", hl:count("config"), 1)
expect("binds registered", hl:count("bind"), 1)
expect("curves registered", hl:count("curve"), 5)
expect("animations registered", hl:count("animation"), 16)
expect("layer rules applied", hl:count("layer_rule"), 3)
expect("start event registered", hl:count("on"), 1)

local start = hl:find("on")[1]
if start then
  start.args[2]()
end
expect("autostart commands spawned", hl:count("exec_cmd"), 1)

if failed > 0 then
  os.exit(1)
end
io.write("integration OK\n")
