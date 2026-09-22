import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.WindowManager
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {

  // ─────────────────── Configuration (Okinami — MonochromeAccentDark) ───────────────────
  QtObject {
    id: config

    // Bar — floating "island" shell, matches yasb-bar.adaptive edgeradius/border
    property int barHeight: 35
    property int marginTop: 6
    property int marginLeft: 8
    property int marginRight: 8
    property int barPaddingH: 14
    property int edgeRadius: 22       // outer bar corner radius (-qproperty-edgeradius)
    property int islandRadius: 14     // per-group pill radius  (--border-radius)
    property int smallRadius: 4       // workspace pill radius  (--border-radius2)
    property int borderWidth: 1
    property color barBackground: "#18181b"   // --background
    property color barBorderColor: "#3f3f42"  // --border

    // Font — Okinami uses Segoe UI Variable, semi-bold, 12px
    property string fontFamily: "Segoe UI Variable"
    property int fontSize: 12
    property int fontWeight: Font.DemiBold
    property bool fontBold: false

    // Palette
    property color colorText: "#e5e7eb"        // --text
    property color colorBackground2: "#3f3f42" // --background2 / --mutedBG
    property color colorAccent: "#9599b2"      // --accent (normally system accent color; tune to taste)
    property color colorAccentText: "#18181b"  // --accentText

    // Workspace (komorebi-workspaces .ws-btn)
    property int workspaceWidth: 20
    property int rectangleHeight: 20
    property int workspacePadding: 12
    property int workspaceSpacing: 6
    property int workspaceRadius: smallRadius
    property color workspaceActiveColor: colorAccent
    property color workspaceInactiveColor: colorBackground2
    property color workspaceUrgentColor: "#e5e7eb"   // --redFlash in this variant is monochrome
    property color workspaceActiveTextColor: colorAccentText
    property color workspaceInactiveTextColor: colorText

    // Window Title (.widget pill)
    property int windowTitlePadding: 16
    property int windowTitleLeftMargin: 8
    property int windowTitleRightMargin: 6
    property int windowTitleRadius: islandRadius
    property color windowTitleColor: colorText
    property color windowTitleBackgroundColor: colorBackground2
    property string windowTitlePlaceholder: "Desktop"

    // Now Playing (.widget pill)
    property int nowPlayingLeftMargin: 6
    property int nowPlayingRightMargin: 0
    property int nowPlayingPadding: 16
    property int nowPlayingHeight: rectangleHeight
    property int nowPlayingMaxWidth: 280
    property int nowPlayingRadius: islandRadius
    property color nowPlayingBackground: colorBackground2
    property color nowPlayingColor: colorText
    property string nowPlayingIcon: "\uf001" // nf-fa-music
    property string iconFontFamily: "JetBrainsMono Nerd Font"
  }
  // ─────────────────────────────────────────────────────

  // ── Bar ──
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property ShellScreen modelData
      property var projection: WindowManager.screenProjection(modelData)

      // MPRIS: pick the first active/playing player, mirroring panel.activePlayer
      property var activePlayer: {
        for (const p of Mpris.players.values) {
          if (p.playbackState === MprisPlaybackState.Playing) return p;
        }
        return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null;
      }

      screen: modelData
      implicitHeight: config.barHeight
      color: "transparent" // window surface stays transparent; the pill below draws the bar

      margins {
        top: config.marginTop
        left: config.marginLeft
        right: config.marginRight
      }

      anchors {
        top: true
        left: true
        right: true
      }

      // ── Floating island bar background ──
      Rectangle {
        anchors.fill: parent
        radius: config.edgeRadius
        color: config.barBackground
        border.width: config.borderWidth
        border.color: config.barBorderColor
      }

      // ── Workspace ──
      RowLayout {
        id: barRow

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: config.barPaddingH
        anchors.rightMargin: config.barPaddingH
        spacing: config.workspaceSpacing

        Repeater {
          model: panel.projection ? panel.projection.windowsets : []

          delegate: Rectangle {
            id: workspaceDelegate

            property var ws: modelData

            visible: ws.shouldDisplay
            implicitWidth: Math.max(config.workspaceWidth, workspaceLabel.implicitWidth + config.workspacePadding)
            implicitHeight: config.rectangleHeight
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
              font.weight: config.fontWeight
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
          radius: config.windowTitleRadius
          color: config.windowTitleBackgroundColor

          Text {
            id: windowTitleLabel

            anchors.centerIn: parent
            text: ToplevelManager.activeToplevel
            ? ToplevelManager.activeToplevel.appId
            : config.windowTitlePlaceholder
            color: config.windowTitleColor

            font.family: config.fontFamily
            font.pixelSize: config.fontSize
            font.weight: config.fontWeight
            elide: Text.ElideRight
          }
        }

        // ── Now Playing ──
        Rectangle {
          id: nowPlaying

          Layout.leftMargin: config.nowPlayingLeftMargin
          Layout.rightMargin: config.nowPlayingRightMargin

          visible: panel.activePlayer !== null
          implicitWidth: Math.min(nowPlayingRow.implicitWidth + config.nowPlayingPadding, config.nowPlayingMaxWidth)
          implicitHeight: config.nowPlayingHeight
          radius: config.nowPlayingRadius
          color: config.nowPlayingBackground

          Row {
            id: nowPlayingRow
            anchors.centerIn: parent
            spacing: 4

            Text {
              text: config.nowPlayingIcon
              color: config.nowPlayingColor
              font.family: config.iconFontFamily
              font.pixelSize: config.fontSize
            }

            Text {
              id: nowPlayingLabel
              width: Math.min(implicitWidth, config.nowPlayingMaxWidth - config.nowPlayingPadding - 20)
              text: panel.activePlayer
              ? `${panel.activePlayer.trackArtist || "Unknown Artist"} – ${panel.activePlayer.trackTitle || "Unknown Track"}`
              : ""
              color: config.nowPlayingColor

              font.family: config.fontFamily
              font.pixelSize: config.fontSize
              font.weight: config.fontWeight
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
