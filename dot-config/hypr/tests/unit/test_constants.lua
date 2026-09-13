local constants = require("domain.constants")

return {
  {
    name = "window_management_constants",
    run = function()
      assert(constants.RESIZE_STEP == 20, "RESIZE_STEP wrong")
      assert(constants.MAX_WS == 10, "MAX_WS wrong")
      assert(constants.SPECIAL_WS == "magic", "SPECIAL_WS wrong")
      assert(constants.MOUSE.LEFT == "mouse:272", "MOUSE.LEFT wrong")
      assert(constants.MOUSE.RIGHT == "mouse:273", "MOUSE.RIGHT wrong")
    end,
  },
  {
    name = "curves_are_named_and_have_two_points",
    run = function()
      assert(#constants.CURVES >= 5, "expected at least 5 curves")
      for _, curve in ipairs(constants.CURVES) do
        assert(type(curve.name) == "string", "curve missing name")
        assert(#curve.points == 2, "curve " .. tostring(curve.name) .. " needs 2 points")
      end
    end,
  },
  {
    name = "animations_reference_known_curves",
    run = function()
      assert(#constants.ANIMATIONS >= 16, "expected at least 16 animations")
      local known = { default = true }
      for _, curve in ipairs(constants.CURVES) do known[curve.name] = true end
      for _, anim in ipairs(constants.ANIMATIONS) do
        assert(known[anim.bezier], "animation " .. tostring(anim.leaf) .. " uses unknown curve " .. tostring(anim.bezier))
      end
    end,
  },
  {
    name = "layer_rules_have_a_namespace_match",
    run = function()
      assert(#constants.LAYER_RULES >= 3, "expected at least 3 layer rules")
      for _, rule in ipairs(constants.LAYER_RULES) do
        assert(rule.match and rule.match.namespace, "layer rule missing namespace match")
      end
    end,
  },
}
