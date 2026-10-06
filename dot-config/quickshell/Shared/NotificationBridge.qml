pragma Singleton
import QtQuick

QtObject {
  signal notified(int key, string appName, string summary, string body, int urgency, bool isTransient)
}
