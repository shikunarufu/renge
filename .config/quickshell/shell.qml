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

import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

PanelWindow {
  id: root
    
  // Position the bar at the top of the screen spanning full width
  anchors.top: true
  anchors.left: true
  anchors.right: true
  implicitHeight: 32
    
  // Theme colors
  property color bgNormal: "#1e1e2e"
  property color tagActive: "#89b4fa"
  property color tagInactive: "#45475a"
  property color tagText: "#cdd6f4"
    
  // Track the currently active tag (Defaults to Tag 1)
  property int activeTag: 1

  color: bgNormal

  // This listens to the pipe perfectly without polling loops
  FileReader {
    path: "file://" + Quickshell.env("HOME") + "/.config/quickshell/mango_pipe"
    active: true
        
    onReadLine: (line) => {
      let cleanLine = line.trim();
      if (cleanLine.startsWith("tag:")) {
        // Expecting data format like "tag:3"
        root.activeTag = parseInt(cleanLine.split(":")[1]);
      }
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 4
    spacing: 6

    // MangoWM traditionally uses 9 tags (like dwm)
    Repeater {
      model: 9
            
      Rectangle {
        id: tagButton
        property int tagId: index + 1
                
        implicitWidth: 28
        implicitHeight: 24
        radius: 4
                
        // Highlight the active tag
        color: root.activeTag === tagId ? root.tagActive : root.tagInactive

        Text {
          anchors.centerIn: parent
          text: tagButton.tagId
          color: root.tagText
          font.bold: true
          font.pixelSize: 12
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            // Dynamically update the active visual state
            root.activeTag = tagButton.tagId
                        
            // Dispatch the switch workspace command to MangoWM IPC
            tagDispatcher.command = ["mmsg", "dispatch", "view," + tagButton.tagId]
            tagDispatcher.running = true
          }
        }
      }
    }
        
    // Spacer to push tags to the left side
    Item {
      Layout.fillWidth: true
    }
  }

  Process {
    id: tagDispatcher
  }
}
