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
    property int marginTop: 6
    property int marginLeft: 8
    property color barBackground: "transparent"

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property bool fontBold: true

    // Workspace
    property int workspaceWidth: 20
    property int workspaceHeight: 20
    property int workspacePadding: 10
    property int workspaceRadius: 6
    property int workspaceSpacing: 6
    property color workspaceActiveColor: "#88c0d0"
    property color workspaceInactiveColor: "#3b4252"
    property color workspaceUrgentColor: "#bf616a"
    property color workspaceActiveTextColor: "#2e3440"
    property color workspaceInactiveTextColor: "#d8dee9"

    // Window Title
    property int windowTitleHeight: 20
    property int windowTitlePadding: 12
    property int windowTitleRadius: 6
    property int windowTitleSpacing: 10
    property color windowTitleColor: "#d8dee9"
    property color windowTitleBackgroundColor: "#3b4252"
    property string windowTitlePlaceholder: "Desktop"
  }

  // ── Bar ──
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property ShellScreen modelData
      property var projection: WindowManager.screenProjection(modelData)

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

      // ── Workspace ──
      RowLayout {
        id: barRow

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: config.workspaceSpacing

        Repeater {
          model: panel.projection ? panel.projection.windowsets : []

          delegate: Rectangle {
            id: workspaceDelegate

            property var ws: modelData

            visible: ws.shouldDisplay
            implicitWidth: Math.max(config.workspaceWidth, workspaceLabel.implicitWidth + config.workspacePadding)
            implicitHeight: config.workspaceHeight
            radius: config.workspaceRadius
            color: ws.urgent
            ? config.workspaceUrgentColor
            : (ws.active ? config.workspaceActiveColor : config.workspaceInactiveColor)

            Text {
              id: workspaceLabel

              anchors.centerIn: parent
              text: ws.name.length ? ws.name : (ws.coordinates[0] + 1)
              color: ws.active ? config.workspaceActiveTextColor : config.workspaceInactiveTextColor

              font.family: config.fontFamily
              font.pixelSize: config.fontSize
              font.bold: config.fontBold
            }

            MouseArea {
              anchors.fill: parent
              onClicked: if (workspaceDelegate.ws.canActivate) workspaceDelegate.ws.activate()
            }
          }
        }

        // ── Window Title ──
        Rectangle {
          id: windowTitleLabel

          Layout.leftMargin: config.windowTitleSpacing

          implicitWidth: windowTitleLabel.implicitWidth + config.windowTitlePadding
          implicitHeight: config.windowTitleHeight
          radius: config.windowTitleRadius
          color: config.windowTitleBackgroundColor

          Text {
            id: windowTitleLabel

            anchors.centerIn: parent
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
