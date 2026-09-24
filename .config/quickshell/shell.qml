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
    property int barRadius: 16

    // Workspace
    property int workspaceHeight: 16
    property int workspaceWidth: 16
    property int workspacePadding: 4
    property int workspaceRadius: 4
    property int workspaceSpacing: 8

    // Focus Window
    property string focusWindowIcon: "\uebc4" // nf-cod-terminal
    property string focusWindowPlaceholder: "Desktop"
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

          property var projection: WindowManager.screenProjection(modelData)

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
              width: leftRow.implicitWidth

              RowLayout {
                id: leftRow

                anchors.centerIn: parent
                spacing: config.workspaceSpacing

                // ── Workspace ──
                Repeater {
                  model: bar.projection ? bar.projection.windowsets : []

                  delegate: Rectangle {
                    id: workspaceDelegate

                    property color workspaceActiveColor: colorAccent
                    property color workspaceActiveTextColor: colorAccentText
                    property color workspaceInactiveColor: "transparent"
                    property color workspaceInactiveTextColor: colorText
                    property color workspaceUrgentColor: colorAccent
                    property var ws: modelData

                    color: ws.urgent ? config.workspaceUrgentColor : (ws.active ? config.workspaceActiveColor : config.workspaceInactiveColor)
                    radius: config.workspaceRadius
                    implicitHeight: config.workspaceHeight
                    implicitWidth: Math.max(config.workspaceWidth, workspaceLabel.implicitWidth + config.workspacePadding)
                    visible: ws.shouldDisplay

                    Text {
                      id: workspaceLabel

                      color: ws.active ? config.workspaceActiveTextColor : config.workspaceInactiveTextColor
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      text: ws.name.length ? ws.name : (ws.coordinates[0] + 1)
                      anchors.centerIn: parent
                    }

                    MouseArea {
                      onClicked: if (workspaceDelegate.ws.canActivate) workspaceDelegate.ws.activate()

                      anchors.fill: parent
                    }
                  }
                }

                // Separator
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
                    text: config.focusWindowIcon
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
