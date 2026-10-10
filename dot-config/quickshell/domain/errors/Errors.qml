pragma Singleton
import QtQml

// Contract violations are defects, so they are thrown, never returned as values.
//   ValidationError    a caller broke a precondition (bad argument, wrong state)
//   ContractViolation  a backend broke a postcondition (malformed or impossible data)
// Expected outcomes (device absent, unknown app, network not found) are not errors:
// adapters log them and report them through the port's normal result path.
QtObject {
  function make(kind, code, message, context) {
    const error = new Error("[" + code + "] " + message)
    error.kind = kind
    error.code = code
    error.context = context || {}
    return error
  }

  function precondition(ok, code, message, context) {
    if (!ok) throw make("ValidationError", code, message, context)
  }

  function postcondition(ok, code, message, context) {
    if (!ok) throw make("ContractViolation", code, message, context)
  }
}
