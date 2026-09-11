-- Minimal dependency-free unit test runner.
-- Usage (from the hypr config directory): lua tests/run.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local SUITES = {
  "tests.unit.test_models",
  "tests.unit.test_constants",
  "tests.unit.test_mappings",
  "tests.unit.test_adapter",
  "tests.unit.test_workflows",
  "tests.unit.test_crosscutting",
}

local total = 0
local passed = 0
local failures = {}

for _, suite_name in ipairs(SUITES) do
  local suite = require(suite_name)
  for _, test in ipairs(suite) do
    total = total + 1
    local ok, err = xpcall(test.run, debug.traceback)
    if ok then
      passed = passed + 1
      io.write(string.format("PASS  %s :: %s\n", suite_name, test.name))
    else
      table.insert(failures, test.name)
      io.write(string.format("FAIL  %s :: %s\n      %s\n", suite_name, test.name, tostring(err)))
    end
  end
end

io.write(string.format("\n%d/%d passed\n", passed, total))
if #failures > 0 then
  os.exit(1)
end
