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
expect("start event registered", hl:count("on"), 2)

local events = hl:find("on")
local start = events[1]
local reload = events[2]
if start then
  start.args[2]()
end
expect("autostart + wallpaper daemon spawned", hl:count("exec_cmd"), 1)

local before_reload = hl:count("exec_cmd")
if reload then
  reload.args[2]()
end
expect("reload re-ensures wallpaper daemon", hl:count("exec_cmd") - before_reload, 1)

local config = require("infra.config")
local conf = io.open(config.wallpaper.conf_path, "r")
expect("wallpaper conf written", conf and 1 or 0, 1)
if conf then
  conf:close()
end

if failed > 0 then
  os.exit(1)
end
io.write("integration OK\n")
