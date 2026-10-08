import QtQml
import "../../domain/ports"

NightLightPort {
  property int refreshes: 0
  function setActive(value) { active = value }
  function refresh() { refreshes++ }
}
