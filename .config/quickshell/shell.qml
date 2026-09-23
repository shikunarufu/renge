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
    property int barRadius: 12
  }
  // ─────────────────────────────────────────────────────

  // ── Bar ──
  Variants {
    model: Quickshell.screens

    Item {
      id: screenRoot

      required property var modelData

      PanelWindow {
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
            width: 100
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

          // ── Right Bar ──
          Rectangle {
            id: leftBar

            bottomLeftRadius: config.barRadius
            color: config.barColor
            anchors { right: parent.right; top: parent.top }
            height: config.barHeight
            width: 100
          }
        }

        // ── Concave ──
        PanelWindow {
          anchors { top: true; left: true }
          color: "transparent"
          }

          Item {
            anchors { top: parent.top; left: parent.left }

            Shape {
              id: concave1

              preferredRendererType: Shape.CurveRenderer
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius
              transform: Scale {
                xScale: 1
                origin { x: config.barRadius; y: 0 }
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
