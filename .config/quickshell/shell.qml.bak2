import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.WindowManager
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {

  // ─────────── Configuration (Okinami island bar, measured from screenshot) ───────────
  // Shape: a thin full-width "rail" sits flush at the very top of the screen, and each
  // widget group hangs from it as its own pill with square top corners (fused into the
  // rail) and rounded bottom corners — not one continuous floating bar.
  QtObject {
    id: config

    // Bar
    property int barHeight: 40        // total height incl. rail
    property int railHeight: 6        // thin connecting strip across the full width
    property int islandRadius: 16     // bottom-corner radius of each hanging group
    property int groupPaddingH: 14    // horizontal padding inside each island
    property color barBackground: "#18181b"

    // Font
    property string fontFamily: "Segoe UI Variable"
    property int fontSize: 13
    property int fontWeight: Font.DemiBold
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property int iconSize: 15

    // Palette
    property color colorText: "#e5e7eb"
    property color colorAccent: "#e2a97b"      // sampled from the active workspace pill
    property color colorAccentText: "#18181b"
    property color separatorColor: "#5a5a5e"

    // Workspace pill
    property int workspaceWidth: 22
    property int workspaceHeight: 22
    property int workspacePadding: 14
    property int workspaceSpacing: 8
    property int workspaceRadius: 5
    property color workspaceActiveColor: colorAccent
    property color workspaceInactiveColor: "transparent"
    property color workspaceUrgentColor: colorAccent
    property color workspaceActiveTextColor: colorAccentText
    property color workspaceInactiveTextColor: colorText

    // Window title (icon + text, no pill behind it)
    property color windowTitleColor: colorText
    property string windowTitleIcon: "\uebc4" // nf-cod-terminal
    property string windowTitlePlaceholder: "Desktop"

    // Now playing (its own island, center of bar)
    property color nowPlayingColor: colorText
    property int nowPlayingMaxWidth: 420
    property string nowPlayingSeparator: " • "
  }
  // ───────────────────────────────────────────────────────────────────────────────────

  // ── Bar ──
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property ShellScreen modelData
      property var projection: WindowManager.screenProjection(modelData)

      // MPRIS: pick the first active/playing player
      property var activePlayer: {
        for (const p of Mpris.players.values) {
          if (p.playbackState === MprisPlaybackState.Playing) return p;
        }
        return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null;
      }

      screen: modelData
      implicitHeight: config.barHeight
      color: "transparent"

      margins { top: 0; left: 0; right: 0 }
      anchors { top: true; left: true; right: true }

      // ── Connecting rail: fills the gaps between islands so the top edge reads as
      //    one continuous line, exactly like the reference screenshot. ──
      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: config.railHeight
        color: config.barBackground
      }

      // ── Left island: workspaces + active window ──
      Rectangle {
        id: leftIsland

        x: 0
        y: 0
        height: config.barHeight
        width: leftRow.implicitWidth + config.groupPaddingH * 2
        color: config.barBackground

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: config.islandRadius
        bottomRightRadius: config.islandRadius

        RowLayout {
          id: leftRow
          anchors.centerIn: parent
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
                font.weight: config.fontWeight
              }

              MouseArea {
                anchors.fill: parent
                onClicked: if (workspaceDelegate.ws.canActivate) workspaceDelegate.ws.activate()
              }
            }
          }

          // divider between workspaces and the active window title
          Text {
            text: "|"
            color: config.separatorColor
            font.family: config.fontFamily
            font.pixelSize: config.fontSize
          }

          // ── Active window (icon + text, plain, no pill background) ──
          RowLayout {
            spacing: 6

            Text {
              text: config.windowTitleIcon
              color: config.windowTitleColor
              font.family: config.iconFontFamily
              font.pixelSize: config.iconSize
            }

            Text {
              id: windowTitleLabel
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
        }
      }

      // ── Center island: now playing ──
      Rectangle {
        id: nowPlayingIsland

        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        height: config.barHeight
        width: nowPlayingLabel.implicitWidth + config.groupPaddingH * 2
        visible: panel.activePlayer !== null
        color: config.barBackground

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: config.islandRadius
        bottomRightRadius: config.islandRadius

        Text {
          id: nowPlayingLabel

          anchors.centerIn: parent
          width: Math.min(implicitWidth, config.nowPlayingMaxWidth)
          text: panel.activePlayer
          ? `${panel.activePlayer.trackArtist || "Unknown Artist"}${config.nowPlayingSeparator}${panel.activePlayer.trackTitle || "Unknown Track"}`
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
