// import Quickshell
// import Quickshell.Wayland
// import QtQuick
//
// PanelWindow {
//   anchors {
//     top: true
//     right: true
//     left: true
//   }
//   implicitHeight: 30
//   color: "#1a1b26"
//
//   Text {
//     anchors.centerIn: parent
//     text: "My First Bar"
//     color: "#a9b1d6"
//     font.pixelSize: 14
//   }
// }

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
            height: 32
            color: "#2e3440"

            property var projection: WindowManager.screenProjection(modelData)

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                spacing: 4

                Repeater {
                    model: projection ? projection.windowsets : []

                    delegate: Rectangle {
                        property var ws: modelData

                        visible: ws.shouldDisplay
                        implicitWidth: 28
                        implicitHeight: 24
                        radius: 4
                        color: ws.urgent ? "#bf616a" : (ws.active ? "#88c0d0" : "#3b4252")

                        Text {
                            anchors.centerIn: parent
                            text: ws.name.length ? ws.name : (ws.coordinates[0] + 1)
                            color: ws.active ? "#2e3440" : "#d8dee9"
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
