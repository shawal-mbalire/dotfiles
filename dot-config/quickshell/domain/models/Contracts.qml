pragma Singleton
import QtQml

// Pure clause predicates for port contracts (AGENTS §4). Each returns a boolean.
// The caller decides whether a false clause is a precondition or a postcondition.
QtObject {
  function isBool(value) {
    return typeof value === "boolean"
  }

  function isNonEmptyString(value) {
    return typeof value === "string" && value.trim() !== ""
  }

  function isFiniteNumber(value) {
    return typeof value === "number" && Number.isFinite(value)
  }

  function isInRange(value, min, max) {
    return isFiniteNumber(value) && value >= min && value <= max
  }

  function isNonNegative(value) {
    return isFiniteNumber(value) && value >= 0
  }

  function isOneOf(value, allowed) {
    return allowed.indexOf(value) >= 0
  }
}
