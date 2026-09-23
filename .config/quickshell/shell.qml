import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.WindowManager

ShellRoot {

  // ─────────────────── Configuration ───────────────────
  QtObject {
    id: config

    // Bar
    property int barHeight: 24
    property color barColor: "#18181b"


    property int barRadius: 6
    property int marginTop: 6
    property int marginLeft: 8
    property int rectangleHeight: 20
    property int rectangleRadius: 2

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property bool fontBold: true

    // Workspace
    property int workspaceWidth: 20
    property int workspacePadding: 12
    property int workspaceSpacing: 6
    property color workspaceActiveColor: "#88c0d0"
    property color workspaceInactiveColor: "#3b4252" // delete
    property color workspaceUrgentColor: "#bf616a"
    property color workspaceActiveTextColor: "#2e3440"
    property color workspaceInactiveTextColor: "#d8dee9"

    // Window Title
    property int windowTitlePadding: 12
    property int windowTitleLeftMargin: 0
    property int windowTitleRightMargin: 6
    property color windowTitleColor: "#d8dee9"
    property color windowTitleBackgroundColor: "#3b4252"
    property string windowTitlePlaceholder: "Desktop"

    // Now Playing
    property int nowPlayingLeftMargin: 0
    property int nowPlayingRightMargin: 0
  }
  // ─────────────────────────────────────────────────────

  // ── Bar ──
  Variants {
    model: Quickshell.screens

    Item {
      id: screenRoot
      required property var modelData

      PanelWindow {
        screen: screenRoot.modelData
        implicitHeight: config.barHeight
        exclusiveZone: config.barHeight
        color: config.barColor
        anchors {
          top: true
          left: true
          right: true
        }
        WlrLayershell {
          layer: WlrLayer.Bottom
        }
      }
    }
  }
}
