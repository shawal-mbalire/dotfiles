// PowerProfilePort over Quickshell.Services.UPower (power-profiles-daemon).
// Vendor enum values are translated to the domain strings at this boundary.
import QtQml
import Quickshell.Services.UPower
import "../../domain/ports"
import "../../domain/models"
import "../../domain/errors"

PowerProfilePort {
  id: root

  profile: profileName(PowerProfiles.profile)
  hasPerformance: PowerProfiles.hasPerformanceProfile

  // Postcondition: the daemon reports one of the three known profiles. An unknown
  // value is a backend defect, never silently mapped to "Balanced".
  function profileName(vendor) {
    if (vendor === PowerProfile.PowerSaver) return "Saver"
    if (vendor === PowerProfile.Balanced) return "Balanced"
    if (vendor === PowerProfile.Performance) return "Performance"
    Errors.postcondition(false, "power.unknown-profile", "daemon reported an unknown profile",
                         { vendor: vendor })
    return ""
  }

  // Pre: name is a known profile, and "Performance" only when the system offers it.
  function setProfile(name) {
    Errors.precondition(Contracts.isOneOf(name, ["Saver", "Balanced", "Performance"]),
                        "power.unknown-profile-name", "profile must be Saver, Balanced or Performance",
                        { name: name })
    Errors.precondition(name !== "Performance" || hasPerformance, "power.performance-unavailable",
                        "system has no Performance profile", { name: name })
    if (name === "Saver") PowerProfiles.profile = PowerProfile.PowerSaver
    else if (name === "Balanced") PowerProfiles.profile = PowerProfile.Balanced
    else PowerProfiles.profile = PowerProfile.Performance
  }
}
