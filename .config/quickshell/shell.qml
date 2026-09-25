import QtCore
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

    // App Launcher
    property int appLauncherWidth: 360
    property int appLauncherMaxVisible: 7
    property int appLauncherItemHeight: 42
    property string appLauncherIcon: "\uea6d" // nf-cod-search
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

                // ── App Launcher ──
                Text {
                  id: appLauncherGlyph

                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: config.appLauncherIcon

                  MouseArea {
                    anchors.fill: parent

                    onClicked: appLauncherPopup.visible = !appLauncherPopup.visible
                  }
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

            // ── App Launcher Popup ──
            PopupWindow {
              id: appLauncherPopup

              property string searchQuery: ""
              property int selectedIndex: 0
              property var recentIds: JSON.parse(recentAppsSettings.recentIdsSerialized)

              property var filteredApps: {
                var q = searchQuery.trim().toLowerCase()
                var vals = DesktopEntries.applications.values

                if (q !== "") {
                  return vals.filter(function (e) {
                    if (e.name.toLowerCase().indexOf(q) !== -1) return true
                    if (e.genericName && e.genericName.toLowerCase().indexOf(q) !== -1) return true
                    for (var i = 0; i < e.keywords.length; i++)
                      if (e.keywords[i].toLowerCase().indexOf(q) !== -1) return true
                    return false
                  }).sort(function (a, b) { return a.name.localeCompare(b.name) })
                }

                var recent = appLauncherPopup.recentIds
                return vals.slice().sort(function (a, b) {
                  var ai = recent.indexOf(a.id)
                  var bi = recent.indexOf(b.id)
                  if (ai !== -1 && bi !== -1) return ai - bi
                  if (ai !== -1) return -1
                  if (bi !== -1) return 1
                  return a.name.localeCompare(b.name)
                })
              }

              anchor.item: appLauncherGlyph
              anchor.edges: Edges.Bottom | Edges.Left
              anchor.gravity: Edges.Bottom | Edges.Right
              implicitWidth: config.appLauncherWidth
              implicitHeight: 56 + Math.min(filteredApps.length, config.appLauncherMaxVisible) * config.appLauncherItemHeight
              color: "transparent"
              visible: false
              grabFocus: true

              onFilteredAppsChanged: selectedIndex = 0

              onVisibleChanged: {
                if (visible) {
                  searchField.text = ""
                  searchQuery = ""
                  selectedIndex = 0
                  searchField.forceActiveFocus()
                }
              }

              function recordLaunch(id) {
                var list = appLauncherPopup.recentIds.slice()
                var idx = list.indexOf(id)
                if (idx !== -1) list.splice(idx, 1)
                list.unshift(id)
                if (list.length > 12) list = list.slice(0, 12)
                appLauncherPopup.recentIds = list
                recentAppsSettings.recentIdsSerialized = JSON.stringify(list)
              }

              function navigate(delta) {
                if (filteredApps.length === 0) return
                selectedIndex = (selectedIndex + delta + filteredApps.length) % filteredApps.length
                appList.positionViewAtIndex(selectedIndex, ListView.Contain)
              }

              function launchEntry(entry) {
                recordLaunch(entry.id)
                entry.execute()
                appLauncherPopup.visible = false
              }

              Settings {
                id: recentAppsSettings

                category: "AppLauncher"
                property string recentIdsSerialized: "[]"
              }

              Rectangle {
                anchors.fill: parent
                color: config.barColor
                radius: config.workspaceRadius

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 8

                  Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: config.workspaceRadius
                    color: Qt.rgba(1, 1, 1, 0.07)

                    TextInput {
                      id: searchField

                      anchors.fill: parent
                      anchors.leftMargin: 8
                      anchors.rightMargin: 8
                      color: config.colorText
                      font.family: config.iconFontFamily
                      font.pixelSize: config.fontSize
                      verticalAlignment: TextInput.AlignVCenter
                      clip: true

                      onTextChanged: appLauncherPopup.searchQuery = text

                      Keys.onPressed: function (event) {
                        if (event.key === Qt.Key_Up) {
                          appLauncherPopup.navigate(-1)
                          event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                          appLauncherPopup.navigate(1)
                          event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                          if (appLauncherPopup.filteredApps.length > 0)
                            appLauncherPopup.launchEntry(appLauncherPopup.filteredApps[appLauncherPopup.selectedIndex])
                          event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                          appLauncherPopup.visible = false
                          event.accepted = true
                        }
                      }

                      Text {
                        anchors.fill: parent
                        color: config.colorText
                        font.family: config.iconFontFamily
                        font.pixelSize: config.fontSize
                        opacity: 0.35
                        text: "Search apps…"
                        verticalAlignment: Text.AlignVCenter
                        visible: searchField.text === ""
                      }
                    }
                  }

                  ListView {
                    id: appList

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(appLauncherPopup.filteredApps.length, config.appLauncherMaxVisible) * config.appLauncherItemHeight
                    model: appLauncherPopup.filteredApps
                    clip: true
                    interactive: false

                    Text {
                      anchors.centerIn: parent
                      color: config.colorText
                      font.family: config.iconFontFamily
                      font.pixelSize: config.fontSize
                      opacity: 0.35
                      text: "No apps found"
                      visible: appLauncherPopup.filteredApps.length === 0
                    }

                    delegate: Rectangle {
                      id: appRow

                      width: appList.width
                      height: config.appLauncherItemHeight
                      color: appLauncherPopup.selectedIndex === index ? config.colorAccent : "transparent"
                      radius: config.workspaceRadius

                      Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        Image {
                          width: 24
                          height: 24
                          anchors.verticalCenter: parent.verticalCenter
                          mipmap: true
                          smooth: true
                          source: modelData.icon !== "" ? "image://icon/" + modelData.icon : ""
                        }

                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          width: parent.width - 34
                          color: appLauncherPopup.selectedIndex === index ? config.colorAccentText : config.colorText
                          elide: Text.ElideRight
                          font.family: config.fontFamily
                          font.pixelSize: config.fontSize
                          font.weight: config.fontWeight
                          text: modelData.name
                        }
                      }

                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true

                        onEntered: appLauncherPopup.selectedIndex = index
                        onClicked: appLauncherPopup.launchEntry(modelData)
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
