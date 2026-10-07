import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
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

    Behavior on colorText { ColorAnimation { duration: 500 } }
    Behavior on colorAccent { ColorAnimation { duration: 500 } }
    Behavior on colorAccentText { ColorAnimation { duration: 500 } }
    Behavior on barColor { ColorAnimation { duration: 500 } }

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

    // Power Menu
    property int powerMenuWidth: 160
    property string powerMenuIcon: "\udb82\udcc7"

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
    property string appLauncherIcon: "\uf002"

    // Focus Window
    property string focusWindowGlyph: "\uf2d0"

    // App Icon
    property var focusWindowIcons: ({
      "foot": "\uf489",
      "zen": "\udb83\ude95"
    })

    // Window Title
    property string focusWindowPlaceholder: "Desktop"
    property var focusWindowNames: ({
      "foot": "Foot",
      "zen": "Zen"
    })

    // Wallpaper
    property string wallpaperIcon: "\udb80\udeeb"

    // Volume
    property real volumeStep: 0.05
    property string volumeIconHigh: "\uf028"
    property string volumeIconLow: "\uf027"
    property string volumeIconMuted: "\ueee8"

    // System Tray
    property int trayIconSize: 16
    property int trayIconSpacing: 8
    property int trayPopupMargin: 6
    property int trayPopupPadding: 10
    property int trayPopupRadius: 12
    property string trayIconCollapse: "\uf0d8"
    property string trayIconExpand: "\uf0d7"

    // Network
    property int networkPollInterval: 3000
    property real networkDisconnectedOpacity: 0.5
    property string networkIconEthernet: "\uef44"
    property string networkIconWifi: "\uf1eb"

    // Notifications
    property int notificationWidth: 360
    property int notificationMargin: 8
    property int notificationSpacing: 8
    property int notificationPadding: 12
    property int notificationRadius: 12
    property int notificationIconSize: 32
    property int notificationMax: 1
    property int notificationTimeout: 5000
    property int notificationSlideDuration: 500

    // Now Playing
    property int nowPlayingMaxLength: 45
    property string nowPlayingSeparator: " - "

    // Visualizer
    property int visualizerBars: 10
    property int visualizerBarGap: 4
    property int visualizerBarWidth: 2
    property int visualizerFramerate: 60
    property int visualizerHeight: 12
    property int visualizerMaxFreq: 10000
    property int visualizerMinFreq: 20
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

    // Build a palette from RGBA pixel data (most frequent colors first),
    // then derive the bar, text and accent colors from it.
    function applyPixels(data) {
      var buckets = {}
      for (var i = 0; i < data.length; i += 4) {
        if (data[i + 3] < 128) continue
          var key = ((data[i] >> 4) << 8) | ((data[i + 1] >> 4) << 4) | (data[i + 2] >> 4)
          var b = buckets[key]
          if (!b) b = buckets[key] = { n: 0, r: 0, g: 0, b: 0 }
          b.n++
          b.r += data[i]
          b.g += data[i + 1]
          b.b += data[i + 2]
      }

      var list = Object.keys(buckets).map(k => buckets[k])
      list.sort((x, y) => y.n - x.n)

      var colors = list.slice(0, 8).map(c => Qt.rgba(c.r / c.n / 255, c.g / c.n / 255, c.b / c.n / 255, 1))
      if (colors.length === 0) return

        var base = colors[0]
        var accent = base
        var best = -1
        for (var j = 0; j < colors.length; j++) {
          var l = colors[j].hslLightness
          if (l < 0.2 || l > 0.9) continue
            var score = colors[j].hslSaturation * (1 - Math.abs(l - 0.5))
            if (score > best) { best = score; accent = colors[j] }
        }

        var accentHue = accent.hslHue >= 0 ? accent.hslHue : 0
        var hue = base.hslSaturation > 0.08 && base.hslHue >= 0 ? base.hslHue : accentHue
        var accentSat = accent.hslSaturation < 0.1
        ? accent.hslSaturation
        : Math.min(Math.max(accent.hslSaturation, 0.45), 0.8)

        config.barColor = Qt.hsla(hue, Math.min(base.hslSaturation, 0.3), 0.10, 1)
        config.colorText = Qt.hsla(hue, 0.15, 0.90, 1)
        config.colorAccent = Qt.hsla(accentHue, accentSat, 0.68, 1)
        config.colorAccentText = config.barColor
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

      property bool picked: false

      // Pick a random wallpaper once per shell start.
      onStatusChanged: {
        if (status !== FolderListModel.Ready || picked || count === 0) return
          picked = true
          wallpaperSettings.current = get(Math.floor(Math.random() * count), "filePath")
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: wallpaperWindow

      required property ShellScreen modelData

      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.namespace: "wallpaper"
      exclusionMode: ExclusionMode.Ignore
      anchors { left: true; right: true; top: true; bottom: true }
      color: config.barColor
      screen: modelData

      // Samples the wallpaper at low resolution to read its colors.
      // Placed off-screen (but still visible, so it paints); only the first screen runs it.
      Canvas {
        id: sampler

        property string source: wallpaper.current
        property string loadedUrl: ""

        x: -width
        width: 48
        height: 48

        onSourceChanged: requestPaint()
        onImageLoaded: requestPaint()

        onPaint: {
          if (wallpaperWindow.modelData !== Quickshell.screens[0] || source === "") return

            var url = "file://" + source
            if (!isImageLoaded(url)) { loadImage(url); return }

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.drawImage(url, 0, 0, width, height)
            wallpaper.applyPixels(ctx.getImageData(0, 0, width, height).data)

            if (loadedUrl !== "" && loadedUrl !== url) unloadImage(loadedUrl)
              loadedUrl = url
        }
      }

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

    property string kind: "none"

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

    property string current: imLatin
    property int imPollInterval: 500
    property string imLatin: "keyboard-us"
    property string imJapanese: "mozc"

    function toggle() {
      current = current === imJapanese ? imLatin : imJapanese
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

    Timer {
      id: imHold

      interval: 800
    }

    Timer {
      interval: imPollInterval
      repeat: true
      running: true
      triggeredOnStart: true

      onTriggered: if (!imQuery.running) imQuery.running = true
    }
  }

  // ── Notifications ──
  // Stop other notification daemons (dunst, mako, swaync) first; only one can own the D-Bus name.
  Scope {
    id: notifications

    // Oldest first: the earliest notification is shown, later ones wait in the queue.
    property var items: {
      var list = server.trackedNotifications.values
      var out = []
      for (var i = 0; i < list.length; i++) out.push(list[i])
      return out
    }

    NotificationServer {
      id: server

      actionsSupported: true
      bodySupported: true
      bodyMarkupSupported: true
      imageSupported: true

      onNotification: n => { n.tracked = true }
    }

    PanelWindow {
      screen: Quickshell.screens[0]
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "notifications"
      // Full-width and always mapped: cards slide in and out inside the surface,
      // so they start and end beyond the screen edge. Only the cards take input.
      anchors { top: true; left: true; right: true }
      margins { top: config.notificationMargin }
      exclusiveZone: 0
      color: "transparent"
      implicitHeight: Math.max(1, notificationColumn.implicitHeight)
      mask: Region { item: notificationColumn }

      ColumnLayout {
        id: notificationColumn

        anchors { right: parent.right; top: parent.top; rightMargin: config.notificationMargin }
        width: config.notificationWidth
        spacing: config.notificationSpacing

        Repeater {
          model: notifications.items

          delegate: Rectangle {
            id: card

            required property var modelData
            required property int index

            property var notification: modelData
            property bool critical: notification.urgency === NotificationUrgency.Critical
            // Critical notifications stay until dismissed. Others use their own timeout, or the default.
            property int timeout: critical ? 0
            : notification.expireTimeout > 0 ? notification.expireTimeout * 1000
            : config.notificationTimeout
            property bool hasActions: {
              var list = notification.actions
              for (var i = 0; i < list.length; i++) {
                if (list[i].identifier !== "default") return true
              }
              return false
            }
            property string iconSource: {
              if (notification.image !== "") return notification.image
                var icon = notification.appIcon
                if (icon === "") return ""
                  return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true)
            }

            // Horizontal offset in px: offscreen to the right (hidden) -> 0 (shown).
            property real slideX: config.notificationWidth + config.notificationMargin
            property bool leaving: false
            property bool expireOnClose: false
            property var pendingAction: null

            // Slide out to the right, then expire/dismiss, or invoke the given action.
            function close(expired, action) {
              if (leaving) return
                leaving = true
                expireOnClose = expired
                pendingAction = action || null
                slideIn.stop()
                slideOut.start()
            }

            Layout.fillWidth: true
            // Only the first notificationMax are shown; the rest wait in the queue.
            visible: index < config.notificationMax
            color: config.barColor
            radius: config.notificationRadius
            border.width: critical ? 2 : 0
            border.color: config.colorAccent
            implicitHeight: cardContent.implicitHeight + config.notificationPadding * 2

            transform: Translate { x: card.slideX }

            // Slide in from the right when shown (new, or promoted from the queue).
            Component.onCompleted: if (visible) slideIn.start()
            onVisibleChanged: if (visible && !leaving) slideIn.start()

            NumberAnimation {
              id: slideIn

              target: card
              property: "slideX"
              to: 0
              duration: config.notificationSlideDuration
              easing.type: Easing.OutQuint
            }

            NumberAnimation {
              id: slideOut

              target: card
              property: "slideX"
              to: config.notificationWidth + config.notificationMargin
              duration: config.notificationSlideDuration
              easing.type: Easing.InQuint

              onFinished: {
                var n = card.notification
                var action = card.pendingAction
                if (action) {
                  var keep = n.resident
                  action.invoke()
                  if (keep) n.dismiss()
                } else if (card.expireOnClose) {
                  n.expire()
                } else {
                  n.dismiss()
                }
              }
            }

            HoverHandler { id: cardHover }

            Timer {
              interval: card.timeout
              running: card.timeout > 0 && card.visible && !card.leaving && !cardHover.hovered
              onTriggered: card.close(true)
            }

            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) {
                  var list = card.notification.actions
                  for (var i = 0; i < list.length; i++) {
                    if (list[i].identifier === "default") {
                      card.close(false, list[i])
                      return
                    }
                  }
                }
                card.close(false)
              }
            }

            ColumnLayout {
              id: cardContent

              anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: config.notificationPadding
              }
              spacing: 8

              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Image {
                  Layout.alignment: Qt.AlignTop
                  Layout.preferredWidth: config.notificationIconSize
                  Layout.preferredHeight: config.notificationIconSize
                  fillMode: Image.PreserveAspectFit
                  source: card.iconSource
                  sourceSize: Qt.size(config.notificationIconSize * 2, config.notificationIconSize * 2)
                  visible: source != ""
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  Text {
                    Layout.fillWidth: true
                    color: config.colorText
                    opacity: 0.6
                    elide: Text.ElideRight
                    font.family: config.fontFamily
                    font.pixelSize: config.fontSize - 2
                    font.weight: config.fontWeight
                    text: card.notification.appName
                    visible: text !== ""
                  }

                  Text {
                    Layout.fillWidth: true
                    color: config.colorText
                    elide: Text.ElideRight
                    font.family: config.fontFamily
                    font.pixelSize: config.fontSize
                    font.weight: Font.Bold
                    text: card.notification.summary
                  }

                  Text {
                    Layout.fillWidth: true
                    color: config.colorText
                    elide: Text.ElideRight
                    font.family: config.fontFamily
                    font.pixelSize: config.fontSize
                    maximumLineCount: 3
                    textFormat: Text.StyledText
                    text: card.notification.body
                    visible: text !== ""
                    wrapMode: Text.Wrap
                  }
                }
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: card.hasActions

                Repeater {
                  model: card.notification.actions

                  delegate: Rectangle {
                    id: actionButton

                    required property var modelData

                    Layout.fillWidth: true
                    color: actionArea.containsMouse ? config.colorAccent : "transparent"
                    border.width: 1
                    border.color: config.colorAccent
                    radius: config.barRadius
                    implicitHeight: 28
                    visible: modelData.identifier !== "default"

                    Text {
                      anchors.centerIn: parent
                      color: actionArea.containsMouse ? config.colorAccentText : config.colorText
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      text: actionButton.modelData.text
                    }

                    MouseArea {
                      id: actionArea

                      anchors.fill: parent
                      hoverEnabled: true
                      onClicked: card.close(false, actionButton.modelData)
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

  // ── Bar ──
  Scope {
    id: root

    Variants {
      model: Quickshell.screens

      Scope {
        id: screenRoot

        required property ShellScreen modelData

        property var cornerHiddenLayouts: ["S"]
        property bool cornersHidden: cornerHiddenLayouts.indexOf(layoutState.symbols[modelData.name]) !== -1

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

              property int slideDuration: 500
              property bool ready: false

              clip: true
              bottomRightRadius: config.barRadius
              color: config.barColor
              anchors { left: parent.left; top: parent.top }
              height: config.barHeight

              // Bar edge follows the right edge of the last item, so it stretches
              // in the same frames as the contents slide. Rounded to whole pixels.
              width: Math.round(leftRow.x + focusSlot.x + focusSlot.width + config.barPadding / 2)

              Timer {
                interval: 1000
                running: true
                onTriggered: leftBar.ready = true
              }

              Row {
                id: leftRow

                anchors {
                  left: parent.left
                  leftMargin: config.barPadding / 2
                  verticalCenter: parent.verticalCenter
                }
                spacing: config.barItemSpacing

                move: Transition {
                  NumberAnimation {
                    properties: "x"
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                  }
                }

                // ── Power Menu ──
                Text {
                  anchors.verticalCenter: parent.verticalCenter
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
                  anchors.verticalCenter: parent.verticalCenter
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                }

                // ── Layout ──
                Text {
                  anchors.verticalCenter: parent.verticalCenter
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
                  anchors.verticalCenter: parent.verticalCenter
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                }

                // ── Workspace ──
                Row {
                  id: workspaceRow

                  anchors.verticalCenter: parent.verticalCenter
                  spacing: config.workspaceSpacing

                  move: Transition {
                    NumberAnimation {
                      properties: "x"
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                    }
                  }

                  Repeater {
                    model: bar.projection ? bar.projection.windowsets : []

                    delegate: Rectangle {
                      id: workspaceDelegate

                      anchors.verticalCenter: parent.verticalCenter
                      property color workspaceActiveColor: config.colorAccent
                      property color workspaceActiveTextColor: config.colorAccentText
                      property color workspaceInactiveColor: "transparent"
                      property color workspaceInactiveTextColor: config.colorText
                      property color workspaceUrgentColor: config.colorAccent
                      property var ws: modelData
                      property bool shouldShow: ws.shouldDisplay

                      color: ws.urgent ? workspaceUrgentColor : (ws.active ? workspaceActiveColor : workspaceInactiveColor)
                      radius: config.workspaceRadius
                      implicitHeight: config.workspaceHeight
                      implicitWidth: Math.max(config.workspaceWidth, workspaceLabel.implicitWidth + config.workspacePadding)

                      visible: shouldShow || opacity > 0

                      property bool revealed: false

                      opacity: revealed ? 1 : 0

                      Behavior on opacity {
                        enabled: leftBar.ready

                        NumberAnimation {
                          duration: 200
                          easing.type: Easing.OutQuint
                        }
                      }

                      Timer {
                        id: revealTimer

                        interval: leftBar.slideDuration
                        onTriggered: workspaceDelegate.revealed = true
                      }

                      function reveal() {
                        revealTimer.stop()
                        if (leftBar.ready) {
                          revealed = false
                          revealTimer.restart()
                        } else {
                          revealed = true
                        }
                      }

                      Component.onCompleted: if (shouldShow) reveal()

                      onShouldShowChanged: {
                        if (shouldShow) {
                          reveal()
                        } else {
                          revealTimer.stop()
                          revealed = false
                        }
                      }

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
                        enabled: workspaceDelegate.shouldShow
                        onClicked: if (workspaceDelegate.ws.canActivate) workspaceDelegate.ws.activate()

                        anchors.fill: parent
                      }
                    }
                  }
                }

                // Separator 3
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  bottomPadding: 3
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: "|"
                }

                // ── App Launcher ──
                Text {
                  anchors.verticalCenter: parent.verticalCenter
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
                // Slot width animates so the bar (which tracks its right edge) stretches with it.
                Item {
                  id: focusSlot

                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  width: focusWindow.implicitWidth
                  height: focusWindow.implicitHeight

                  Behavior on width {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                    }
                  }

                  RowLayout {
                    id: focusWindow

                    // Targets follow the active window; shown values change only while faded out.
                    property string targetIcon: {
                      var t = ToplevelManager.activeToplevel
                      if (!t) return config.focusWindowGlyph
                        return config.focusWindowIcons[t.appId.toLowerCase()] || config.focusWindowGlyph
                    }
                    property string targetLabel: {
                      var t = ToplevelManager.activeToplevel
                      if (!t) return config.focusWindowPlaceholder
                        return config.focusWindowNames[t.appId.toLowerCase()] || t.appId
                    }
                    property string shownIcon: targetIcon
                    property string shownLabel: targetLabel

                    function apply() {
                      shownIcon = targetIcon
                      shownLabel = targetLabel
                    }

                    function update() {
                      if (leftBar.ready) swap.restart()
                        else apply()
                    }

                    onTargetIconChanged: update()
                    onTargetLabelChanged: update()

                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: 8

                    SequentialAnimation {
                      id: swap

                      NumberAnimation {
                        target: focusWindow
                        property: "opacity"
                        to: 0
                        duration: 200
                        easing.type: Easing.OutQuint
                      }

                      ScriptAction { script: focusWindow.apply() }

                      NumberAnimation {
                        target: focusWindow
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutQuint
                      }
                    }

                    Text {
                      id: focusWindowIcon

                      color: config.colorText
                      font.family: config.iconFontFamily
                      font.pixelSize: config.iconSize
                      text: focusWindow.shownIcon
                    }

                    Text {
                      id: focusWindowLabel

                      elide: Text.ElideRight
                      color: config.colorText
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      text: focusWindow.shownLabel
                    }
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

              // Bar edges follow the right edge of the last item, so the bar stretches
              // in the same frames as the contents slide. Parity is matched to the
              // parent width so both edges land on whole pixels.
              // While the media slot has zero width, the Row may not position it, so its x
              // is unreliable; use the clock's edge instead.
              property real contentEdge: mediaSlot.width > 0
              ? mediaSlot.x + mediaSlot.width
              : clockLabel.x + clockLabel.width
              property real rawWidth: centerRow.x + contentEdge + config.barPadding / 2
              property int roundedWidth: Math.round(rawWidth)

              clip: true
              bottomLeftRadius: config.barRadius
              bottomRightRadius: config.barRadius
              color: config.barColor
              anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
              height: config.barHeight
              width: ((parent.width - roundedWidth) % 2 !== 0) ? roundedWidth + 1 : roundedWidth

              SystemClock {
                id: clock

                precision: SystemClock.Minutes
              }

              Row {
                id: centerRow

                anchors {
                  left: parent.left
                  leftMargin: config.barPadding / 2
                  verticalCenter: parent.verticalCenter
                }
                spacing: 0

                move: Transition {
                  NumberAnimation {
                    properties: "x"
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                  }
                }

                // ── Clock ──
                Text {
                  id: clockLabel

                  anchors.verticalCenter: parent.verticalCenter
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: Qt.formatDateTime(clock.date, "ddd, d MMM   HH:mm")
                }

                // ── Media (visualizer + now playing) ──
                // Always present; its width animates to 0 when nothing plays. Order on show:
                // the bar stretches first, then the content fades in. On hide: fade out, then shrink.
                Item {
                  id: mediaSlot

                  property bool wanted: media.active
                  property bool expanded: false
                  property bool contentShown: false

                  function show() {
                    hideTimer.stop()
                    expanded = true
                    if (leftBar.ready) {
                      contentShown = false
                      showTimer.restart()
                    } else {
                      contentShown = true
                    }
                  }

                  function hide() {
                    showTimer.stop()
                    labelSwap.stop()
                    contentShown = false
                    if (leftBar.ready) hideTimer.restart()
                      else expanded = false
                  }

                  Component.onCompleted: if (wanted) show()
                  onWantedChanged: wanted ? show() : hide()

                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  height: mediaRow.implicitHeight
                  width: expanded ? config.barItemSpacing + mediaRow.implicitWidth : 0

                  Behavior on width {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                    }
                  }

                  Timer {
                    id: showTimer

                    interval: leftBar.slideDuration
                    onTriggered: mediaSlot.contentShown = true
                  }

                  Timer {
                    id: hideTimer

                    interval: 200
                    onTriggered: mediaSlot.expanded = false
                  }

                  RowLayout {
                    id: mediaRow

                    // Keep the last label while fading out, so the text does not vanish early.
                    property string targetLabel: media.label
                    property string shownLabel: targetLabel

                    function update() {
                      // media.player is already updated here, unlike mediaSlot.wanted,
                      // which may still hold the old value when the label changes first.
                      if (media.player === null) return
                        if (leftBar.ready && mediaSlot.contentShown) labelSwap.restart()
                          else shownLabel = targetLabel
                    }

                    onTargetLabelChanged: update()

                    anchors {
                      left: parent.left
                      leftMargin: config.barItemSpacing
                      verticalCenter: parent.verticalCenter
                    }
                    opacity: mediaSlot.contentShown ? 1 : 0
                    spacing: config.barItemSpacing

                    Behavior on opacity {
                      enabled: leftBar.ready && !labelSwap.running

                      NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutQuint
                      }
                    }

                    SequentialAnimation {
                      id: labelSwap

                      NumberAnimation {
                        target: mediaRow
                        property: "opacity"
                        to: 0
                        duration: 200
                        easing.type: Easing.OutQuint
                      }

                      ScriptAction { script: mediaRow.shownLabel = mediaRow.targetLabel }

                      NumberAnimation {
                        target: mediaRow
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutQuint
                      }
                    }

                    // ── Visualizer ──
                    Row {
                      id: visualizer

                      Layout.alignment: Qt.AlignVCenter
                      Layout.preferredHeight: config.visualizerHeight
                      spacing: config.visualizerBarGap

                      Repeater {
                        model: config.visualizerBars

                        delegate: Rectangle {
                          required property int index

                          anchors.verticalCenter: parent.verticalCenter
                          color: config.colorAccent
                          height: Math.max(config.visualizerBarWidth, ((media.levels[index] || 0) / 100) * config.visualizerHeight)
                          width: config.visualizerBarWidth

                          Behavior on height { NumberAnimation { duration: 200 } }
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
                      text: mediaRow.shownLabel

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

              // Bar edge follows the right edge of the last item (animated), so the bar
              // stretches in the same frames as the contents slide.
              clip: true
              bottomLeftRadius: config.barRadius
              color: config.barColor
              anchors { right: parent.right; top: parent.top }
              height: config.barHeight
              width: Math.round(rightRow.x + imSlot.x + imSlot.width + config.barPadding / 2)

              Row {
                id: rightRow

                anchors {
                  left: parent.left
                  leftMargin: config.barPadding / 2
                  verticalCenter: parent.verticalCenter
                }
                spacing: config.barItemSpacing

                move: Transition {
                  NumberAnimation {
                    properties: "x"
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                  }
                }

                // ── System Tray (arrow + separator) ──
                // Fades out before the row slides, and fades in after it has slid.
                Item {
                  id: traySlot

                  property bool shouldShow: SystemTray.items.values.length > 0
                  property bool revealed: false

                  function reveal() {
                    trayTimer.stop()
                    if (leftBar.ready) {
                      revealed = false
                      trayTimer.restart()
                    } else {
                      revealed = true
                    }
                  }

                  Component.onCompleted: if (shouldShow) reveal()

                  onShouldShowChanged: {
                    if (shouldShow) {
                      reveal()
                    } else {
                      trayTimer.stop()
                      revealed = false
                    }
                  }

                  anchors.verticalCenter: parent.verticalCenter
                  implicitHeight: trayContent.implicitHeight
                  implicitWidth: trayContent.implicitWidth
                  opacity: revealed ? 1 : 0
                  visible: shouldShow || opacity > 0

                  Behavior on opacity {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: 200
                      easing.type: Easing.OutQuint
                    }
                  }

                  Timer {
                    id: trayTimer

                    interval: leftBar.slideDuration
                    onTriggered: traySlot.revealed = true
                  }

                  Row {
                    id: trayContent

                    spacing: config.barItemSpacing

                    Text {
                      id: trayArrow

                      anchors.verticalCenter: parent.verticalCenter
                      color: config.colorText
                      font.family: config.iconFontFamily
                      font.pixelSize: config.iconSize
                      text: trayPopup.visible ? config.trayIconCollapse : config.trayIconExpand

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
                      anchors.verticalCenter: parent.verticalCenter
                      bottomPadding: 3
                      color: config.colorText
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      text: "|"
                    }
                  }
                }

                // ── Wallpaper ──
                Text {
                  id: wallpaperGlyph

                  anchors.verticalCenter: parent.verticalCenter
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
                  anchors.verticalCenter: parent.verticalCenter
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

                  anchors.verticalCenter: parent.verticalCenter
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
                  anchors.verticalCenter: parent.verticalCenter
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

                  anchors.verticalCenter: parent.verticalCenter
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
                // Last item: its slot width animates, and the bar tracks the slot's right edge.
                Item {
                  id: imSlot

                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  width: imText.implicitWidth
                  height: imText.implicitHeight

                  Behavior on width {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                    }
                  }

                  Text {
                    id: imText

                    property string imJapanese: "mozc"
                    property string imLabelLatin: "en"
                    property string imLabelJapanese: "jp"
                    property string targetText: inputMethod.current === imJapanese ? imLabelJapanese : imLabelLatin
                    property string shownText: targetText

                    onTargetTextChanged: {
                      if (leftBar.ready) imSwap.restart()
                        else shownText = targetText
                    }

                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    color: config.colorText
                    font.family: config.fontFamily
                    font.pixelSize: config.fontSize
                    font.weight: config.fontWeight
                    text: shownText

                    SequentialAnimation {
                      id: imSwap

                      NumberAnimation {
                        target: imText
                        property: "opacity"
                        to: 0
                        duration: 200
                        easing.type: Easing.OutQuint
                      }

                      ScriptAction { script: imText.shownText = imText.targetText }

                      NumberAnimation {
                        target: imText
                        property: "opacity"
                        to: 1
                        duration: 200
                        easing.type: Easing.OutQuint
                      }
                    }

                    MouseArea {
                      anchors.fill: parent

                      onClicked: inputMethod.toggle()
                    }
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
              // Stay mapped until the slide-out finishes.
              visible: !screenRoot.cornersHidden || leftConcave1.x > -config.barRadius
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius

              Shape {
                id: leftConcave1

                // Slides in from / out to the left screen edge (window clips the overflow).
                x: screenRoot.cornersHidden ? -config.barRadius : 0

                Behavior on x {
                  NumberAnimation {
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                  }
                }

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
