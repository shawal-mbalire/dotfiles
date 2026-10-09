pragma Singleton
import QtQml

// domain/constants/TrayPolicy.qml
// Pure tray policy. Bluetooth/network applets duplicate the bar's own widgets,
// so they are suppressed. Matched case-insensitively against id + title.
QtObject {
  function isSuppressed(id, title) {
    var pattern = /bluetooth|bluez|blueman|networkmanager|nm-applet|\bnetwork\b|wi-?fi|wireless|ethernet/i
    return pattern.test((id || "") + " " + (title || ""))
  }
}
