// CONTRACT — PowerProfilePort (power-profiles-daemon)
//   string profile         "Saver"|"Balanced"|"Performance"      (read-only)
//   bool   hasPerformance  the system offers a Performance profile (read-only)
//   setProfile(string name)
//     Pre:  name is "Saver"|"Balanced"|"Performance"; "Performance" only when
//           hasPerformance (ValidationError otherwise).
//     Invariant: an unrecognised daemon profile is a ContractViolation, never a default.
//     Post: profile == name once the daemon reports it.
import QtQml

QtObject {
  property string profile: "Balanced"
  property bool hasPerformance: false

  default property list<QtObject> resources

  function setProfile(name) {}
}
