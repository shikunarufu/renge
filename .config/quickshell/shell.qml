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
    property color barColor: "black"
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
    property int nowPlayingMaxWidth: 260
    property color nowPlayingColor: "#d8dee9"
    property string nowPlayingPlaceholder: "Nothing playing"

    // Left cluster (workspace group / layout mode / launcher)
    property string homeLabel: "家"
    property string layoutModeLabel: "BSP"
    property color leftLabelColor: "#d8dee9"

    // Shared
    property color separatorColor: "#4c566a"
    property color iconColor: "#d8dee9"
    property string iconFontFamily: "JetBrainsMono Nerd Font"

    // Right cluster (clock / status icons)
    property color clockColor: "#d8dee9"
    property string clockFormat: "ddd, d MMM HH:mm"
    property int volumePercent: 50   // TODO: wire to a real audio service (e.g. Pipewire)
    property string currentLang: "en" // TODO: wire to a real keyboard-layout service
  }
  // ─────────────────────────────────────────────────────

  // ── Bar ──
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property ShellScreen modelData
      property var projection: WindowManager.screenProjection(modelData)
      // TODO: wire this to a real MPRIS source, e.g. Quickshell.Services.Mpris
      property var activePlayer: null
      screen: modelData

      implicitHeight: config.barHeight + config.barRadius
      exclusiveZone: config.barHeight
      color: config.barColor

      anchors {
        top: true
        left: true
        right: true
      }

      RowLayout {
        anchors.fill: parent
        spacing:0
        Rectangle {
          id: leftBar
          color: config.barColor
          implicitWidth: barRow.implicitWidth + config.marginLeft * 2
          Layout.preferredHeight: config.barHeight
          bottomRightRadius: config.barRadius

          // ── Workspace ──
          RowLayout {
            id: barRow

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: config.marginLeft
            spacing: config.workspaceSpacing

            // ── Home / launcher label ──
            Text {
              text: config.homeLabel
              color: config.leftLabelColor
              font.family: config.fontFamily
              font.pixelSize: config.fontSize
              font.bold: config.fontBold
            }

            // ── Layout mode (e.g. BSP, tiling, floating) ──
            Text {
              text: config.layoutModeLabel
              color: config.leftLabelColor
              font.family: config.fontFamily
              font.pixelSize: config.fontSize
              font.bold: config.fontBold
            }

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
                : (ws.active ? config.workspaceActiveColor : "transparent")

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

              // ── Separator ──
              Text {
                text: "|"
                color: config.separatorColor
                font.family: config.fontFamily
                font.pixelSize: config.fontSize
              }

              // ── Search ──
              Text {
                text: "\uf002" // nf-fa-search
                color: config.iconColor
                font.family: config.iconFontFamily
                font.pixelSize: config.fontSize
              }

              // ── Active window / terminal ──
              RowLayout {
                spacing: 6

                Text {
                  text: "\uf120" // nf-fa-terminal
                  color: config.iconColor
                  font.family: config.iconFontFamily
                  font.pixelSize: config.fontSize
                }

                Text {
                  text: ToplevelManager.activeToplevel
                  ? ToplevelManager.activeToplevel.appId
                  : config.windowTitlePlaceholder
                  color: config.windowTitleColor
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  elide: Text.ElideRight
                }
              }
          }
        }

        Rectangle {
          id: centerBar
          color: "transparent"
          Layout.fillWidth: true
          Layout.preferredHeight: config.barHeight
          Layout.alignment: Qt.VCenter
        }

        Rectangle {
          id: rightBar
          color: config.barColor
          implicitWidth: rightRow.implicitWidth + config.marginLeft * 2
          Layout.preferredHeight: config.barHeight
          bottomLeftRadius: config.barRadius

          // live clock, ticks once a second
          property date currentTime: new Date()
          Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: rightBar.currentTime = new Date()
          }

          RowLayout {
            id: rightRow

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: config.marginLeft
            spacing: config.workspaceSpacing

            // ── Clock ──
            Text {
              text: Qt.formatDateTime(rightBar.currentTime, config.clockFormat)
              color: config.clockColor
              font.family: config.fontFamily
              font.pixelSize: config.fontSize
              font.bold: config.fontBold
            }

            // ── Now Playing ──
            Text {
              text: panel.activePlayer
              ? `${panel.activePlayer.trackArtist || "Unknown Artist"} • ${panel.activePlayer.trackTitle || "Unknown Track"}`
              : config.nowPlayingPlaceholder
              color: config.nowPlayingColor
              font.family: config.fontFamily
              font.pixelSize: config.fontSize
              elide: Text.ElideRight
              Layout.maximumWidth: config.nowPlayingMaxWidth
            }

            // ── Dropdown (e.g. quick settings) ──
            Text {
              text: "\uf078" // nf-fa-chevron_down
              color: config.iconColor
              font.family: config.iconFontFamily
              font.pixelSize: config.fontSize
            }

            // ── Screenshot / gallery ──
            Text {
              text: "\uf03e" // nf-fa-picture_o
              color: config.iconColor
              font.family: config.iconFontFamily
              font.pixelSize: config.fontSize
            }

            // ── Volume ──
            RowLayout {
              spacing: 4
              Text {
                text: "\uf028" // nf-fa-volume_up
                color: config.iconColor
                font.family: config.iconFontFamily
                font.pixelSize: config.fontSize
              }
              Text {
                text: config.volumePercent + "%"
                color: config.iconColor
                font.family: config.fontFamily
                font.pixelSize: config.fontSize
              }
            }

            // ── Notifications ──
            Text {
              text: "\uf0f3" // nf-fa-bell
              color: config.iconColor
              font.family: config.iconFontFamily
              font.pixelSize: config.fontSize
            }

            // ── Keyboard layout / language ──
            Text {
              text: config.currentLang
              color: config.iconColor
              font.family: config.fontFamily
              font.pixelSize: config.fontSize
            }

            // ── Settings ──
            Text {
              text: "\uf013" // nf-fa-cog
              color: config.iconColor
              font.family: config.iconFontFamily
              font.pixelSize: config.fontSize
            }
          }
        }
      }
    }
  }
}
