import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.WindowManager

ShellRoot {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property ShellScreen modelData
      screen: modelData

      anchors { top: true; left: true; right: true }
      implicitHeight: 24
      color: "transparent"
      margins.top: 6
      margins.left: 8

      property var projection: WindowManager.screenProjection(modelData)

      RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: 6

        Repeater {
          model: projection ? projection.windowsets : []

          delegate: Rectangle {
            property var ws: modelData

            visible: ws.shouldDisplay
            implicitWidth: 20
            implicitHeight: 20
            radius: 6
            color: ws.urgent ? "#bf616a" : (ws.active ? "#88c0d0" : "#3b4252")

            Text {
              anchors.centerIn: parent
              text: ws.name.length ? ws.name : (ws.coordinates[0] + 1)
              color: ws.active ? "#2e3440" : "#d8dee9"

              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 13
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: if (ws.canActivate) ws.activate()
            }
          }
        }
      }
    }
  }
}
