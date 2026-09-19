import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  anchors {
    top: true
    right: true
    left: true
  }
  implicitHeight: 30
  color: "#1a1b26"

  Text {
    anchors.centerIn: parent
    text: "My First Bar"
    color: "#a9b1d6"
    font.pixelSize: 14
  }
}
