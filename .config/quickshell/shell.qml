import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.WindowManager
import Quickshell.Wayland

ShellRoot {

  // ────────────────── Configuration ──────────────────
  QtObject {
    id: config

    // Bar
    property int barHeight: 24
    property color barBackground: "transparent"
    property int marginTop: 6
    property int marginLeft: 8

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property bool fontBold: true

    // Workspace
    property int workspaceSize: 20
    property int workspaceRadius: 6
    property int workspaceSpacing: 6
    property color workspaceActiveColor: "#88c0d0"
    property color workspaceInactiveColor: "#3b4252"
    property color workspaceUrgentColor: "#bf616a"
    property color workspaceActiveTextColor: "#2e3440"
    property color workspaceInactiveTextColor: "#d8dee9"

    // Window Title
    property color windowTitleColor: "#d8dee9"
    property color windowTitleBackground: "#3b4252"
    property int windowTitleRadius: 6
    property int windowTitlePaddingH: 10
    property int windowTitlePaddingV: 4
    property int windowTitleSpacing: 10
    property string windowTitlePlaceholder: "Desktop"
  }

  // ── Bar ──
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property ShellScreen modelData
      screen: modelData

      implicitHeight: config.barHeight
      color: config.barBackground
      margins {
        top: config.marginTop
        left: config.marginLeft
      }
      anchors {
        top: true
        left: true
        right: true
      }

      property var projection: WindowManager.screenProjection(modelData)

      // ── Workspace ──
      RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: config.workspaceSpacing

        Repeater {
          model: projection ? projection.windowsets : []

          delegate: Rectangle {
            property var ws: modelData

            visible: ws.shouldDisplay
            implicitWidth: config.workspaceSize
            implicitHeight: config.workspaceSize
            radius: config.workspaceRadius
            color: ws.urgent
              ? config.workspaceUrgentColor
              : (ws.active ? config.workspaceActiveColor : config.workspaceInactiveColor)

            Text {
              anchors.centerIn: parent
              text: ws.name.length ? ws.name : (ws.coordinates[0] + 1)
              color: ws.active ? config.workspaceActiveTextColor : config.workspaceInactiveTextColor

              font.family: config.fontFamily
              font.pixelSize: config.fontSize
              font.bold: config.fontBold
            }

            MouseArea {
              anchors.fill: parent
              onClicked: if (ws.canActivate) ws.activate()
            }
          }
        }

        // ── Window Title ──
        Rectangle {
          Layout.leftMargin: config.windowTitleSpacing

          implicitWidth: windowTitleText.implicitWidth + config.windowTitlePaddingH * 2
          implicitHeight: windowTitleText.implicitHeight + config.windowTitlePaddingV * 2
          radius: config.windowTitleRadius
          color: config.windowTitleBackground

          Text {
            Layout.leftMargin: config.windowTitleSpacing
            text: ToplevelManager.activeToplevel
              ? ToplevelManager.activeToplevel.title
              : config.windowTitlePlaceholder
            color: config.windowTitleColor

            font.family: config.fontFamily
            font.pixelSize: config.fontSize
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
