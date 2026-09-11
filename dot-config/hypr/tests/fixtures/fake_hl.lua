-- Fake lower-level `hl` table (the external Hyprland system).
-- Records every call so adapter/integration tests can assert on it.

local M = {}

function M.new()
  local calls = {}

  local function record(name)
    return function(...)
      local entry = { name = name, args = { ... } }
      table.insert(calls, entry)
      return entry
    end
  end

  local dsp = {
    exec_cmd = record("dsp.exec_cmd"),
    focus = record("dsp.focus"),
    window = {
      move = record("dsp.window.move"),
      float = record("dsp.window.float"),
      close = record("dsp.window.close"),
      pseudo = record("dsp.window.pseudo"),
      drag = record("dsp.window.drag"),
      resize = record("dsp.window.resize"),
    },
    workspace = {
      toggle_special = record("dsp.workspace.toggle_special"),
      move = record("dsp.workspace.move"),
    },
  }

  local hl = {
    dsp = dsp,
    calls = calls,
    monitor = record("monitor"),
    env = record("env"),
    config = record("config"),
    device = record("device"),
    bind = record("bind"),
    curve = record("curve"),
    animation = record("animation"),
    layer_rule = record("layer_rule"),
    on = record("on"),
    exec_cmd = record("exec_cmd"),
  }

  function hl:find(name)
    local out = {}
    for _, call in ipairs(calls) do
      if call.name == name then table.insert(out, call) end
    end
    return out
  end

  function hl:count(name)
    return #self:find(name)
  end

  return hl
end

return M
