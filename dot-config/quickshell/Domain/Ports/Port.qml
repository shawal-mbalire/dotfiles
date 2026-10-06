// Domain/Ports/Port.qml
// Base for every port. `QtObject` has no default property, so an adapter that
// needs helper objects (Process/FileView/Timer) cannot declare them as children.
// This base provides the default property; adapters extend a port, which extends
// this, and their child objects land in `content`.
import QtQml

QtObject {
  default property list<QtObject> content
}
