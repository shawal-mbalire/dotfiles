import QtQml
import "../../domain/ports"

BluetoothPort {
  available: true
  function setEnabled(value) { enabled = value; if (!value) connectedName = "" }
}
