import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Widgets
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
    property int barItemSpacing: 16
    property int barPadding: 44
    property int barRadius: 22

    // Bar Corners (layout symbols from mmsg: S = scroller, VS = vertical scroller)
    property var cornerHiddenLayouts: ["S"]

    // Power Menu
    property int powerMenuWidth: 160
    property string powerMenuIcon: "\uf303" // nf-linux-archlinux

    // Workspace
    property int workspaceHeight: 16
    property int workspaceWidth: 16
    property int workspacePadding: 8
    property int workspaceRadius: 4
    property int workspaceSpacing: 8

    // App Launcher
    property int appLauncherWidth: 360
    property int appLauncherMaxVisible: 7
    property int appLauncherItemHeight: 42
    property string appLauncherIcon: "\uea6d" // nf-cod-search

    // Focus Window
    property string focusWindowGlyph: "\uebc4" // nf-cod-terminal
    property string focusWindowPlaceholder: "Desktop"

    // Wallpaper
    property string wallpaperIcon: "\uf03e" // nf-fa-image

    // Volume
    property real volumeStep: 0.05
    property string volumeIconHigh: "\uf028" // nf-fa-volume_up
    property string volumeIconLow: "\uf027" // nf-fa-volume_down
    property string volumeIconMuted: "\uf026" // nf-fa-volume_off

    // System Tray
    property int trayIconSize: 16
    property int trayIconSpacing: 8
    property int trayPopupPadding: 10
    property int trayPopupMargin: 6
    property int trayPopupRadius: 12
    property string trayIconExpand: "\uf0d7" // nf-fa-caret_down
    property string trayIconCollapse: "\uf0d8" // nf-fa-caret_up

    // Networks
    property int networkPollInterval: 3000
    property string networkIconWifi: "\uf1eb" // nf-fa-wifi
    property string networkIconEthernet: "\uf0e8" // nf-fa-sitemap
    property real networkDisconnectedOpacity: 0.4

    // Input Method
    property string imLatin: "keyboard-us"
    property string imJapanese: "mozc"
    property string imLabelLatin: "en"
    property string imLabelJapanese: "jp"
    property int imPollInterval: 500

    // Now Playing
    property string nowPlayingSeparator: " - "
    property int nowPlayingMaxLength: 45

    // Visualizer
    property int visualizerBars: 10
    property int visualizerBarWidth: 2
    property int visualizerBarGap: 4
    property int visualizerHeight: 12
    property int visualizerFramerate: 60
    property int visualizerMinFreq: 20
    property int visualizerMaxFreq: 10000
  }
  // ─────────────────────────────────────────────────────

  // ── Wallpaper ──
  Scope {
    id: wallpaper

    property string current: wallpaperSettings.current

    function step(delta) {
      var n = wallpaperFolder.count
      if (n === 0) return

      var i = -1
      for (var k = 0; k < n; k++) {
        if (wallpaperFolder.get(k, "filePath") === current) { i = k; break }
      }

      var next = i === -1 ? 0 : (i + delta + n) % n
      wallpaperSettings.current = wallpaperFolder.get(next, "filePath")
    }

    Settings {
      id: wallpaperSettings

      category: "Wallpaper"
      property string current: ""
    }

    FolderListModel {
      id: wallpaperFolder

      property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

      folder: "file://" + wallpaperDir
      nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
      showDirs: false
      sortField: FolderListModel.Name

      onStatusChanged: {
        if (status === FolderListModel.Ready && wallpaper.current === "" && count > 0)
          wallpaperSettings.current = get(0, "filePath")
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property ShellScreen modelData

      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.namespace: "wallpaper"
      exclusionMode: ExclusionMode.Ignore
      anchors { left: true; right: true; top: true; bottom: true }
      color: config.barColor
      screen: modelData

      Image {
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: wallpaper.current !== "" ? "file://" + wallpaper.current : ""
        sourceSize: Qt.size(modelData.width, modelData.height)
      }
    }
  }

  // ── Now Playing Function ──
  Scope {
    id: media

    property var player: {
      var list = Mpris.players.values
      for (var i = 0; i < list.length; i++) {
        if (list[i].isPlaying) return list[i]
      }
      return null
    }
    property bool active: player !== null
    property var levels: []

    property string label: {
      if (!player) return ""

      var parts = []
      if (player.trackTitle) parts.push(player.trackTitle)
      if (player.trackArtist) parts.push(player.trackArtist)

      var text = parts.join(config.nowPlayingSeparator)
      return text.length > config.nowPlayingMaxLength
        ? text.substring(0, config.nowPlayingMaxLength - 1) + "…"
        : text
    }

    onActiveChanged: if (!active) levels = []

    // ── Visualizer Function ──
    Process {
      id: cava

      running: media.active
      command: [
        "sh", "-c",
        'f="${XDG_RUNTIME_DIR:-/tmp}/quickshell-cava.conf"; printf "%s\\n" "$0" > "$f"; exec cava -p "$f"',
        "[general]\n"
        + "bars = " + config.visualizerBars + "\n"
        + "framerate = " + config.visualizerFramerate + "\n"
        + "lower_cutoff_freq = " + config.visualizerMinFreq + "\n"
        + "higher_cutoff_freq = " + config.visualizerMaxFreq + "\n"
        + "[input]\nmethod = pipewire\nsource = auto\n"
        + "[output]\nmethod = raw\nraw_target = /dev/stdout\n"
        + "data_format = ascii\nascii_max_range = 100\n"
        + "bar_delimiter = 59\nframe_delimiter = 10\n"
        + "[smoothing]\nnoise_reduction = 77\n"
      ]

      stdout: SplitParser {
        onRead: data => {
          var out = []
          var parts = data.split(";")
          for (var i = 0; i < parts.length; i++) {
            if (parts[i] !== "") out.push(Number(parts[i]))
          }
          media.levels = out
        }
      }
    }
  }

  // ── Layout State ──
  Scope {
    id: layoutState

    // Layout symbol per monitor name
    property var symbols: ({})

    Process {
      id: layoutWatcher

      command: ["mmsg", "watch", "all-monitors"]
      running: true

      stdout: SplitParser {
        onRead: data => {
          try {
            var payload = JSON.parse(data)
            var monitors = payload.monitors || []
            if (monitors.length === 0) return

            var next = {}
            for (var key in layoutState.symbols) next[key] = layoutState.symbols[key]
            for (var i = 0; i < monitors.length; i++) next[monitors[i].name] = monitors[i].layout_symbol
            layoutState.symbols = next
          } catch (e) {
            // ignore partial/malformed JSON chunks
          }
        }
      }

      onRunningChanged: if (!running) layoutRestart.start()
    }

    Timer {
      id: layoutRestart

      interval: 1000

      onTriggered: layoutWatcher.running = true
    }
  }

  // ── Network State ──
  Scope {
    id: network

    property string kind: "none" // wifi | ethernet | none

    Process {
      id: networkQuery

      command: [
        "sh", "-c",
        "nmcli -t -f TYPE,STATE device | awk -F: '($1==\"wifi\"||$1==\"ethernet\")&&$2==\"connected\"{print $1; f=1; exit} END{if(!f)print \"none\"}'"
      ]

      stdout: SplitParser {
        onRead: data => { if (data !== "") network.kind = data.trim() }
      }
    }

    Timer {
      interval: config.networkPollInterval
      repeat: true
      running: true
      triggeredOnStart: true

      onTriggered: if (!networkQuery.running) networkQuery.running = true
    }
  }

  // ── Input Method State ──
  Scope {
    id: inputMethod

    property string current: config.imLatin

    function toggle() {
      current = current === config.imJapanese ? config.imLatin : config.imJapanese
      imHold.restart()
      Quickshell.execDetached(["fcitx5-remote", "-t"])
    }

    Process {
      id: imQuery

      command: ["fcitx5-remote", "-n"]

      stdout: SplitParser {
        onRead: data => { if (data !== "" && !imHold.running) inputMethod.current = data.trim() }
      }
    }

    // Pause polling after a click so a stale reply can't overwrite the new value
    Timer {
      id: imHold

      interval: 800
    }

    Timer {
      interval: config.imPollInterval
      repeat: true
      running: true
      triggeredOnStart: true

      onTriggered: if (!imQuery.running) imQuery.running = true
    }
  }

  // ── Bar ──
  Scope {
    id: root

    Variants {
      model: Quickshell.screens

      Scope {
        id: screenRoot

        required property ShellScreen modelData

        property bool cornersHidden: config.cornerHiddenLayouts.indexOf(layoutState.symbols[modelData.name]) !== -1

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
                spacing: config.barItemSpacing

                // ── Power Menu ──
                Text {
                  id: powerMenuGlyph

                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: config.powerMenuIcon

                  MouseArea {
                    anchors.fill: parent

                    onClicked: powerMenuPopup.visible = !powerMenuPopup.visible
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

                // ── Layout ──
                Text {
                  id: layoutGlyph

                  property var layoutList: ["tile", "monocle", "grid", "scroller"]
                  property string currentLayout: layoutState.symbols[screenRoot.modelData.name] || layoutList[0]
                  property int nextIndex: 0

                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: currentLayout

                  MouseArea {
                    anchors.fill: parent

                    onClicked: {
                      layoutGlyph.nextIndex = (layoutGlyph.nextIndex + 1) % layoutGlyph.layoutList.length
                      Quickshell.execDetached(["mmsg", "dispatch", "setlayout," + layoutGlyph.layoutList[layoutGlyph.nextIndex]])
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

                // ── Workspace ──
                RowLayout {
                  id: workspaceRow

                  spacing: config.workspaceSpacing

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
                }

                // Separator 3
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
                  spacing: 8

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

            // ── Power Menu Popup ──
            PopupWindow {
              id: powerMenuPopup

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
                      { label: "Shut Down", command: "systemctl poweroff" },
                      { label: "Restart", command: "systemctl reboot" },
                      { label: "Sleep", command: "systemctl suspend" },
                      { label: "Lock", command: "loginctl lock-session" },
                      { label: "Log Out", command: "loginctl terminate-session self" } // adjust for your compositor, e.g. "hyprctl dispatch exit" or "swaymsg exit"
                    ]

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
            PanelWindow {
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
                    for (var i = 0; i < e.keywords.length; i++) {
                      if (e.keywords[i].toLowerCase().indexOf(q) !== -1) return true
                    }
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

              screen: screenRoot.modelData
              WlrLayershell.layer: WlrLayer.Overlay
              WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
              WlrLayershell.namespace: "app-launcher"
              exclusionMode: ExclusionMode.Ignore
              anchors { left: true; top: true }
              margins.left: 0
              margins.top: config.barHeight
              implicitWidth: config.appLauncherWidth
              implicitHeight: 56 + Math.min(filteredApps.length, config.appLauncherMaxVisible) * config.appLauncherItemHeight
              color: "transparent"
              visible: false

              onFilteredAppsChanged: selectedIndex = 0

              onVisibleChanged: {
                if (visible) {
                  margins.left = Math.max(0, appLauncherGlyph.mapToItem(null, 0, 0).x)
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
                      font.family: config.fontFamily
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
                        font.family: config.fontFamily
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
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    interactive: true

                    Text {
                      anchors.centerIn: parent
                      color: config.colorText
                      font.family: config.fontFamily
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
              width: centerRow.implicitWidth + config.barPadding

              SystemClock {
                id: clock

                precision: SystemClock.Minutes
              }

              RowLayout {
                id: centerRow

                anchors.centerIn: parent
                spacing: config.barItemSpacing

                // ── Clock ──
                Text {
                  id: clockLabel

                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: Qt.formatDateTime(clock.date, "ddd, d MMM   HH:mm")
                }

                // ── Visualizer ──
                Row {
                  id: visualizer

                  Layout.alignment: Qt.AlignVCenter
                  Layout.preferredHeight: config.visualizerHeight
                  spacing: config.visualizerBarGap
                  visible: media.active

                  Repeater {
                    model: config.visualizerBars

                    delegate: Rectangle {
                      required property int index

                      anchors.verticalCenter: parent.verticalCenter
                      color: config.colorAccent
                      height: Math.max(config.visualizerBarWidth, ((media.levels[index] || 0) / 100) * config.visualizerHeight)
                      width: config.visualizerBarWidth

                      Behavior on height { NumberAnimation { duration: 60 } }
                    }
                  }
                }

                // ── Now Playing ──
                Text {
                  id: nowPlayingLabel

                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: media.label
                  visible: media.active

                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                      if (!media.player) return

                      if (mouse.button === Qt.RightButton) {
                        if (media.player.canGoNext) media.player.next()
                      } else if (media.player.canTogglePlaying) {
                        media.player.togglePlaying()
                      }
                    }
                  }
                }
              }
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
              width: rightRow.implicitWidth + config.barPadding

              RowLayout {
                id: rightRow

                anchors.centerIn: parent
                spacing: config.barItemSpacing

                // ── System Tray ──
                Text {
                  id: trayArrow

                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: trayPopup.visible ? config.trayIconCollapse : config.trayIconExpand
                  visible: SystemTray.items.values.length > 0

                  MouseArea {
                    anchors.fill: parent

                    onClicked: trayPopup.visible = !trayPopup.visible
                  }

                  PopupWindow {
                    id: trayPopup

                    anchor.item: trayArrow
                    anchor.edges: Edges.Bottom | Edges.Right
                    anchor.gravity: Edges.Bottom | Edges.Left
                    anchor.margins.top: config.trayPopupMargin
                    color: "transparent"
                    implicitHeight: config.trayIconSize + config.trayPopupPadding * 2
                    implicitWidth: trayIcons.implicitWidth + config.trayPopupPadding * 2
                    visible: false
                    grabFocus: true

                    Rectangle {
                      anchors.fill: parent
                      color: config.barColor
                      radius: config.trayPopupRadius

                      RowLayout {
                        id: trayIcons

                        anchors.centerIn: parent
                        spacing: config.trayIconSpacing

                        Repeater {
                          model: SystemTray.items

                          delegate: Item {
                            id: trayDelegate

                            required property SystemTrayItem modelData

                            implicitHeight: config.trayIconSize
                            implicitWidth: config.trayIconSize

                            IconImage {
                              anchors.fill: parent
                              source: trayDelegate.modelData.icon
                            }

                            MouseArea {
                              anchors.fill: parent
                              acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                              onClicked: mouse => {
                                var item = trayDelegate.modelData
                                if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                                  item.activate()
                                  trayPopup.visible = false
                                } else if (mouse.button === Qt.MiddleButton) {
                                  item.secondaryActivate()
                                  trayPopup.visible = false
                                } else if (item.hasMenu) {
                                  var pos = trayDelegate.mapToItem(null, 0, trayDelegate.height)
                                  item.display(trayDelegate.QsWindow.window, pos.x, pos.y)
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }

                // Separator 4
                Text {
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                  visible: trayArrow.visible
                }

                // ── Wallpaper ──
                Text {
                  id: wallpaperGlyph

                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: config.wallpaperIcon

                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => wallpaper.step(mouse.button === Qt.RightButton ? -1 : 1)
                  }
                }

                // Separator 5
                Text {
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                }

                // ── Volume ──
                Item {
                  id: volumeItem

                  property var sink: Pipewire.defaultAudioSink
                  property real volume: sink && sink.audio ? sink.audio.volume : 0
                  property bool muted: sink && sink.audio ? sink.audio.muted : false

                  implicitHeight: volumeRow.implicitHeight
                  implicitWidth: volumeRow.implicitWidth

                  PwObjectTracker { objects: [volumeItem.sink] }

                  RowLayout {
                    id: volumeRow

                    spacing: 6

                    Text {
                      Layout.alignment: Qt.AlignVCenter
                      color: config.colorText
                      font.family: config.iconFontFamily
                      font.pixelSize: config.iconSize
                      text: volumeItem.muted ? config.volumeIconMuted
                        : volumeItem.volume < 0.5 ? config.volumeIconLow
                        : config.volumeIconHigh
                    }

                    Text {
                      Layout.alignment: Qt.AlignVCenter
                      color: config.colorText
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      text: Math.round(volumeItem.volume * 100) + "%"
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton

                    onClicked: {
                      if (volumeItem.sink && volumeItem.sink.audio)
                        volumeItem.sink.audio.muted = !volumeItem.sink.audio.muted
                    }

                    onWheel: wheel => {
                      if (!volumeItem.sink || !volumeItem.sink.audio) return

                      var delta = wheel.angleDelta.y > 0 ? config.volumeStep : -config.volumeStep
                      volumeItem.sink.audio.muted = false
                      volumeItem.sink.audio.volume = Math.max(0, Math.min(1, volumeItem.volume + delta))
                    }
                  }
                }

                // Separator 6
                Text {
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                }

                // ── Networks ──
                Text {
                  id: networkGlyph

                  property string kind: network.kind

                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  opacity: kind === "none" ? config.networkDisconnectedOpacity : 1
                  text: kind === "ethernet" ? config.networkIconEthernet : config.networkIconWifi

                  MouseArea {
                    anchors.fill: parent

                    property var networkCommand: ["foot", "-e", "nmtui"]

                    onClicked: Quickshell.execDetached(networkCommand)
                  }
                }

                // ── Input Method ──
                Text {
                  id: imText

                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: inputMethod.current === config.imJapanese ? config.imLabelJapanese : config.imLabelLatin

                  MouseArea {
                    anchors.fill: parent

                    onClicked: inputMethod.toggle()
                  }
                }
              }
            }

            // ── Left Concave 1 ──
            PanelWindow {
              anchors { left: true; top: true }
              color: "transparent"
              exclusionMode: ExclusionMode.Ignore
              mask: Region {} // click-through
              screen: screenRoot.modelData
              margins.top: config.barHeight
              visible: !screenRoot.cornersHidden
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
              exclusionMode: ExclusionMode.Ignore
              mask: Region {} // click-through
              screen: screenRoot.modelData
              margins.top: config.barHeight
              visible: !screenRoot.cornersHidden
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
