import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.WindowManager
import Quickshell.Wayland

ShellRoot {

  // ─────────────────── Configuration ───────────────────
  QtObject {
    id: config

    // Bar
    property int barHeight: 24
    property int marginTop: 6
    property int marginLeft: 8
    property int rectangleHeight: 20
    property int rectangleRadius: 2
    property color barBackground: "transparent"

    // Font
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property bool fontBold: true

    // Workspace
    property int workspaceWidth: 20
    property int workspacePadding: 12
    property int workspaceSpacing: 6
    property color workspaceActiveColor: "#88c0d0"
    property color workspaceInactiveColor: "#3b4252"
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
            implicitHeight: config.rectangleHeight
            radius: config.rectangleRadius
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
          id: windowTitle

          Layout.leftMargin: config.windowTitleLeftMargin
          Layout.rightMargin: config.windowTitleRightMargin

          implicitWidth: windowTitleLabel.implicitWidth + config.windowTitlePadding
          implicitHeight: config.rectangleHeight
          radius: config.rectangleRadius
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

        // ── Now Playing ──
        Rectangle {
          id: nowPlaying

          Layout.leftMargin: config.nowPlayingLeftMargin
          Layout.rightMargin: config.nowPlayingRightMargin

          visible: panel.activePlayer !== null
          implicitWidth: Math.min(nowPlayingLabel.implicitWidth + config.nowPlayingPadding, config.nowPlayingMaxWidth)
          implicitHeight: config.nowPlayingHeight
          radius: config.rectangleRadius
          color: config.nowPlayingBackground

          Text {
            id: nowPlayingLabel

            anchors.centerIn: parent
            width: parent.width - config.nowPlayingPadding
            text: panel.activePlayer
            ? `${config.nowPlayingIcon} ${panel.activePlayer.trackArtist || "Unknown Artist"} – ${panel.activePlayer.trackTitle || "Unknown Track"}`
            : ""
            color: config.nowPlayingColor

            font.family: config.fontFamily
            font.pixelSize: config.fontSize
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
