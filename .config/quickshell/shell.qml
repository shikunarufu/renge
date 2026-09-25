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

    // Color
    property color colorText: "#e5e7eb"
    property color colorAccent: "#e2a97b"
    property color colorAccentText: "#18181b"

    // Font
    property string fontFamily: "Segoe UI Variable"
    property int fontSize: 12
    property int fontWeight: Font.DemiBold
    property string iconFontFamily: "JetBrainsMono Nerd Font"
    property int iconSize: 16

    // Bar
    property color barColor: "#18181b"
    property int barHeight: 35
    property int barPadding: 28
    property int barRadius: 16

    // Workspace
    property int workspaceHeight: 16
    property int workspaceWidth: 16
    property int workspacePadding: 4
    property int workspaceRadius: 4
    property int workspaceSpacing: 8

    // Focus Window
    property string focusWindowGlyph: "\uebc4" // nf-cod-terminal
    property string focusWindowPlaceholder: "Desktop"

    // Power Menu
    property int powerMenuWidth: 160
    property string powerMenuIcon: "\uf303" // nf-linux-archlinux — verify against your installed Nerd Font version
  }
  // ─────────────────────────────────────────────────────

  // ── Bar ──
  Scope {
    id: root

    Variants {
      model: Quickshell.screens

      Item {
        id: screenRoot

        required property ShellScreen modelData

        PanelWindow {
          id: bar

          property var projection: WindowManager.screenProjection(screenRoot.modelData)

          exclusiveZone: config.barHeight
          WlrLayershell.layer: WlrLayer.Bottom
          anchors { left: true; right: true; top: true }
          color: "transparent"
          screen: screenRoot.modelData
          implicitHeight: config.barHeight

          Item {
            anchors.fill: parent

            // ── Left Bar ──
            Rectangle {
              id: leftBar

              bottomRightRadius: config.barRadius
              color: config.barColor
              anchors { left: parent.left; top: parent.top }
              height: config.barHeight
              width: leftRow.implicitWidth + config.barPadding

              RowLayout {
                id: leftRow

                anchors.centerIn: parent
                spacing: config.workspaceSpacing

                // ── Power Menu ──
                Text {
                  id: powerMenuGlyph

                  color: config.colorAccent
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: config.powerMenuIcon

                  MouseArea {
                    anchors.fill: parent

                    onClicked: powerContextMenu.visible = !powerContextMenu.visible
                  }
                }

                // Separator 1
                Text {
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                }

                // ── Workspace ──
                Repeater {
                  model: bar.projection ? bar.projection.windowsets : []

                  delegate: Rectangle {
                    id: workspaceDelegate

                    property color workspaceActiveColor: config.colorAccent
                    property color workspaceActiveTextColor: config.colorAccentText
                    property color workspaceInactiveColor: "transparent"
                    property color workspaceInactiveTextColor: config.colorText
                    property color workspaceUrgentColor: config.colorAccent
                    property var ws: modelData

                    color: ws.urgent ? workspaceUrgentColor : (ws.active ? workspaceActiveColor : workspaceInactiveColor)
                    radius: config.workspaceRadius
                    implicitHeight: config.workspaceHeight
                    implicitWidth: Math.max(config.workspaceWidth, workspaceLabel.implicitWidth + config.workspacePadding)
                    visible: ws.shouldDisplay

                    Text {
                      id: workspaceLabel

                      color: ws.active ? workspaceActiveTextColor : workspaceInactiveTextColor
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      rightPadding: 1
                      text: ws.name.length ? ws.name : (ws.coordinates[0] + 1)
                      anchors.centerIn: parent
                    }

                    MouseArea {
                      onClicked: if (workspaceDelegate.ws.canActivate) workspaceDelegate.ws.activate()

                      anchors.fill: parent
                    }
                  }
                }

                // Separator 2
                Text {
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                }

                // ── Focus Window ──
                RowLayout {
                  spacing: 6

                  Text {
                    id: focusWindowIcon

                    color: config.colorText
                    font.family: config.iconFontFamily
                    font.pixelSize: config.iconSize
                    text: config.focusWindowGlyph
                  }

                  Text {
                    id: focusWindowLabel

                    elide: Text.ElideRight
                    color: config.colorText
                    font.family: config.fontFamily
                    font.pixelSize: config.fontSize
                    font.weight: config.fontWeight
                    text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.appId : config.focusWindowPlaceholder
                  }
                }
              }
            }

            // ── Power Context Menu ──
            PopupWindow {
              id: powerContextMenu

              anchor.item: powerMenuGlyph
              anchor.edges: Edges.Bottom | Edges.Left
              anchor.gravity: Edges.Bottom | Edges.Right
              implicitWidth: config.powerMenuWidth
              implicitHeight: powerMenuColumn.implicitHeight + (powerMenuColumn.anchors.margins * 2)
              color: "transparent"
              visible: false
              grabFocus: true

              Rectangle {
                anchors.fill: parent
                color: config.barColor
                radius: config.workspaceRadius

                ColumnLayout {
                  id: powerMenuColumn

                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 2

                  Repeater {
                    model: [
                      { label: "Shut Down", command: cmdShutdown },
                      { label: "Restart", command: cmdRestart },
                      { label: "Sleep", command: cmdSleep },
                      { label: "Lock", command: cmdLock },
                      { label: "Log Out", command: cmdLogout }
                    ]

                    property string cmdShutdown: "systemctl poweroff"
                    property string cmdRestart: "systemctl reboot"
                    property string cmdSleep: "systemctl suspend"
                    property string cmdLock: "loginctl lock-session"
                    property string cmdLogout: "loginctl terminate-session self" // adjust for your compositor, e.g. "hyprctl dispatch exit" or "swaymsg exit"

                    delegate: Rectangle {
                      id: powerMenuOption

                      property var entry: modelData

                      Layout.fillWidth: true
                      color: powerMenuOptionArea.containsMouse ? config.colorAccent : "transparent"
                      radius: config.barRadius
                      implicitHeight: 28

                      Text {
                        color: powerMenuOptionArea.containsMouse ? config.colorAccentText : config.colorText
                        font.family: config.fontFamily
                        font.pixelSize: config.fontSize
                        font.weight: config.fontWeight
                        leftPadding: 8
                        text: powerMenuOption.entry.label
                        anchors.verticalCenter: parent.verticalCenter
                      }

                      MouseArea {
                        id: powerMenuOptionArea

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                          Quickshell.execDetached(["sh", "-c", powerMenuOption.entry.command])
                          powerMenuPopup.visible = false
                        }
                      }
                    }
                  }
                }
              }
            }

            // ── Left Concave 2 ──
            Shape {
              id: leftConcave2

              preferredRendererType: Shape.CurveRenderer
              anchors { left: leftBar.right; top: parent.top }
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius
              transform: Scale {
                xScale: 1
                origin { x: config.barRadius / 2; y: 0 }
              }

              ShapePath {
                fillColor: config.barColor
                strokeColor: "transparent"
                startX: config.barRadius
                startY: 0

                PathLine {
                  x: 0
                  y: 0
                }

                PathLine {
                  x: 0
                  y: config.barRadius
                }

                PathArc {
                  direction: PathArc.Clockwise
                  radiusX: config.barRadius
                  radiusY: config.barRadius
                  x: config.barRadius
                  y: 0
                }
              }
            }

            // ── Center Concave 1 ──
            Shape {
              id: centerConcave1

              preferredRendererType: Shape.CurveRenderer
              anchors { right: centerBar.left; top: parent.top }
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius
              transform: Scale {
                xScale: -1
                origin { x: config.barRadius / 2; y: 0 }
              }

              ShapePath {
                fillColor: config.barColor
                strokeColor: "transparent"
                startX: config.barRadius
                startY: 0

                PathLine {
                  x: 0
                  y: 0
                }

                PathLine {
                  x: 0
                  y: config.barRadius
                }

                PathArc {
                  direction: PathArc.Clockwise
                  radiusX: config.barRadius
                  radiusY: config.barRadius
                  x: config.barRadius
                  y: 0
                }
              }
            }

            // ── Center Bar ──
            Rectangle {
              id: centerBar

              bottomLeftRadius: config.barRadius
              bottomRightRadius: config.barRadius
              color: config.barColor
              anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
              height: config.barHeight
              width: 100
            }

            // ── Center Concave 2 ──
            Shape {
              id: centerConcave2

              preferredRendererType: Shape.CurveRenderer
              anchors { left: centerBar.right; top: parent.top }
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius
              transform: Scale {
                xScale: 1
                origin { x: config.barRadius / 2; y: 0 }
              }

              ShapePath {
                fillColor: config.barColor
                strokeColor: "transparent"
                startX: config.barRadius
                startY: 0

                PathLine {
                  x: 0
                  y: 0
                }

                PathLine {
                  x: 0
                  y: config.barRadius
                }

                PathArc {
                  direction: PathArc.Clockwise
                  radiusX: config.barRadius
                  radiusY: config.barRadius
                  x: config.barRadius
                  y: 0
                }
              }
            }

            // ── Right Concave 1 ──
            Shape {
              id: rightConcave1

              preferredRendererType: Shape.CurveRenderer
              anchors { right: rightBar.left; top: parent.top }
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius
              transform: Scale {
                xScale: -1
                origin { x: config.barRadius / 2; y: 0 }
              }

              ShapePath {
                fillColor: config.barColor
                strokeColor: "transparent"
                startX: config.barRadius
                startY: 0

                PathLine {
                  x: 0
                  y: 0
                }

                PathLine {
                  x: 0
                  y: config.barRadius
                }

                PathArc {
                  direction: PathArc.Clockwise
                  radiusX: config.barRadius
                  radiusY: config.barRadius
                  x: config.barRadius
                  y: 0
                }
              }
            }

            // ── Right Bar ──
            Rectangle {
              id: rightBar

              bottomLeftRadius: config.barRadius
              color: config.barColor
              anchors { right: parent.right; top: parent.top }
              height: config.barHeight
              width: 100
            }

            // ── Left Concave 1 ──
            PanelWindow {
              anchors { left: true; top: true }
              color: "transparent"
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius

              Shape {
                id: leftConcave1

                preferredRendererType: Shape.CurveRenderer
                implicitHeight: config.barRadius
                implicitWidth: config.barRadius
                transform: Scale {
                  xScale: 1
                  origin { x: config.barRadius / 2; y: 0 }
                }

                ShapePath {
                  fillColor: config.barColor
                  strokeColor: "transparent"
                  startX: config.barRadius
                  startY: 0

                  PathLine {
                    x: 0
                    y: 0
                  }

                  PathLine {
                    x: 0
                    y: config.barRadius
                  }

                  PathArc {
                    direction: PathArc.Clockwise
                    radiusX: config.barRadius
                    radiusY: config.barRadius
                    x: config.barRadius
                    y: 0
                  }
                }
              }
            }

            // ── Right Concave 2 ──
            PanelWindow {
              anchors { right: true; top: true }
              color: "transparent"
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius

              Shape {
                id: rightConcave2

                preferredRendererType: Shape.CurveRenderer
                implicitHeight: config.barRadius
                implicitWidth: config.barRadius
                transform: Scale {
                  xScale: -1
                  origin { x: config.barRadius / 2; y: 0 }
                }

                ShapePath {
                  fillColor: config.barColor
                  strokeColor: "transparent"
                  startX: config.barRadius
                  startY: 0

                  PathLine {
                    x: 0
                    y: 0
                  }

                  PathLine {
                    x: 0
                    y: config.barRadius
                  }

                  PathArc {
                    direction: PathArc.Clockwise
                    radiusX: config.barRadius
                    radiusY: config.barRadius
                    x: config.barRadius
                    y: 0
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
