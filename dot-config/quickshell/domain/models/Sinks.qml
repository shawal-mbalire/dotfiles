import QtQml

// AudioNodes model: Pipewire eligible node filtering and arrived device tracking.
pragma Singleton

QtObject {
  // Sinks: RAOP/AirPlay and Mac mini are excluded.
  function isSinkEligible(name, description) {
    if (!name) return false
    const n = name.toLowerCase(), d = (description || "").toLowerCase()
    if (n.startsWith("raop_client.") || n.startsWith("raop_sink.")) return false
    if (n.includes("airplay") || d.includes("airplay")) return false
    if (n.includes("macmini") || d.includes("macmini")) return false
    if (n.includes("mac-mini") || d.includes("mac-mini")) return false
    if (n.includes("hdmi") || d.includes("hdmi")) return false
    if (n.includes("displayport") || d.includes("displayport")) return false
    return true
  }

  // Legacy alias for Sinks.isEligible
  function isEligible(name, description) { return isSinkEligible(name, description) }

  // Sources: monitor streams are recording taps from shell apps, not real microphones.
  function isSourceEligible(name) {
    const text = name || ""
    return !(/\.monitor$/i).test(text)
  }

  // Newly connected Bluetooth sink detector
  function arrivedBluetooth(previous, current) {
    const isBt = n => n.startsWith("bluez_output.")
    const prevBt = (previous || []).filter(isBt)
    const currBt = (current || []).filter(isBt)
    for (let i = 0; i < currBt.length; i++) {
      if (!prevBt.includes(currBt[i])) return currBt[i]
    }
    return ""
  }
}
