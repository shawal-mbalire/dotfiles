-- Unit tests for cross-cutting adapters and the port-conformance checker.

local Logger = require("adapters.console_logger")
local SystemTime = require("adapters.system_time")
local ProcessLifetime = require("adapters.process_lifetime")
local verify = require("domain.ports.verify")

local function capturing_logger(min_level)
  local output = {}
  local logger = Logger.new({
    min_level = min_level,
    prefix = "[t]",
    sink = { write = function(_, chunk) output[#output + 1] = chunk end },
  })
  return logger, output
end

return {
  {
    name = "logger_prints_at_or_above_min_level",
    run = function()
      local logger, output = capturing_logger("info")
      logger:debug("quiet")
      assert(#output == 0, "debug should be suppressed")
      logger:error("boom")
      assert(#output == 1 and output[1]:find("ERROR"), "error should be printed")
    end,
  },
  {
    name = "logger_sorts_fields_and_quotes_spaces",
    run = function()
      local logger, output = capturing_logger("debug")
      logger:error("boom", { b = 2, a = 1, msg = "two words" })
      local line = output[1]
      assert(line:find("a=1 b=2", 1, true), "fields not sorted: " .. line)
      assert(line:find('msg="two words"', 1, true), "value not quoted: " .. line)
    end,
  },
  {
    name = "time_is_monotonic_wall_clock_in_ms",
    run = function()
      local time = SystemTime.new()
      local first = time:now_ms()
      assert(type(first) == "number", "now_ms must be numeric")
      assert(time:elapsed_ms(first) >= 0, "elapsed must be non-negative")
      assert(time:now_ms() >= first, "time went backwards")
    end,
  },
  {
    name = "lifetime_runs_handlers_once_in_reverse",
    run = function()
      local lifetime = ProcessLifetime.new()
      local order = {}
      lifetime:on_exit(function(reason) order[#order + 1] = "exit:" .. reason end)
      lifetime:register_cleanup(function() order[#order + 1] = "cleanup1" end)
      lifetime:register_cleanup(function() order[#order + 1] = "cleanup2" end)

      lifetime:set_reason(ProcessLifetime.REASON.USER_EXIT)
      lifetime:shutdown()

      assert(order[1] == "exit:user_exit", "exit handler wrong: " .. tostring(order[1]))
      assert(order[2] == "cleanup2" and order[3] == "cleanup1", "cleanups not reverse")
      assert(lifetime:get_exit_reason() == "user_exit", "reason not exposed")
      assert(lifetime:is_shutting_down(), "not marked shutting down")

      lifetime:shutdown()
      assert(#order == 3, "handlers must run exactly once")
    end,
  },
  {
    name = "verify_missing_port_method_fails_loud",
    run = function()
      local ok, err = pcall(verify.assert_port, {}, verify.time)
      assert(not ok, "expected conformance failure")
      assert(tostring(err):find("TimePort"), "message should name the port: " .. tostring(err))
    end,
  },
  {
    name = "verify_accepts_compliant_adapter",
    run = function()
      verify.assert_port({ now_ms = function() end, elapsed_ms = function() end }, verify.time)
    end,
  },
}
