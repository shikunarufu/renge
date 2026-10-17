import Qt.labs.folderlistmodel
import QtCore
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pam
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.WindowManager

ShellRoot {
  id: shellRoot

  property string trayPopupScreen: ""

  signal dismissPopups()
  
  // ── Configuration File ──
  Config {
    id: config
  }

  // ── Clock ──
  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  // ── Wallpaper Function ──
  Scope {
    id: wallpaper

    property string current: wallpaperSettings.current

    function step(delta) {
      var n = wallpaperFolder.count;
      if (n === 0)
        return ;

      var i = -1;
      for (var k = 0; k < n; k++) {
        if (wallpaperFolder.get(k, "filePath") === current) {
          i = k;
          break;
        }
      }
      var next = i === -1 ? 0 : (i + delta + n) % n;
      wallpaperSettings.current = wallpaperFolder.get(next, "filePath");
    }

    function applyPixels(data) {
      var buckets = {
      };
      for (var i = 0; i < data.length; i += 4) {
        if (data[i + 3] < 128)
          continue;

        var key = ((data[i] >> 4) << 8) | ((data[i + 1] >> 4) << 4) | (data[i + 2] >> 4);
        var bucket = buckets[key];
        if (!bucket)
          bucket = buckets[key] = {
            "n": 0,
            "r": 0,
            "g": 0,
            "b": 0
          };

        bucket.n++;
        bucket.r += data[i];
        bucket.g += data[i + 1];
        bucket.b += data[i + 2];
      }
      var list = Object.keys(buckets).map((k) => {
        return buckets[k];
      });
      list.sort((x, y) => {
        return y.n - x.n;
      });
      var colors = list.slice(0, config.themePaletteSize).map((c) => {
        return Qt.rgba(c.r / c.n / 255, c.g / c.n / 255, c.b / c.n / 255, 1);
      });
      if (colors.length === 0)
        return ;

      var base = colors[0];
      var accent = base;
      var best = -1;
      for (var j = 0; j < colors.length; j++) {
        var lightness = colors[j].hslLightness;
        if (lightness < 0.2 || lightness > 0.9)
          continue;

        var score = colors[j].hslSaturation * (1 - Math.abs(lightness - 0.5));
        if (score > best) {
          best = score;
          accent = colors[j];
        }
      }
      var accentHue = accent.hslHue >= 0 ? accent.hslHue : 0;
      var hue = base.hslSaturation > 0.08 && base.hslHue >= 0 ? base.hslHue : accentHue;
      var accentSaturation = accent.hslSaturation < 0.1 ? accent.hslSaturation : Math.min(Math.max(accent.hslSaturation, config.themeAccentMinSaturation), config.themeAccentMaxSaturation);
      config.barColor = Qt.hsla(hue, Math.min(base.hslSaturation, config.themeBarMaxSaturation), config.themeBarLightness, 1);
      config.colorText = Qt.hsla(hue, config.themeTextSaturation, config.themeTextLightness, 1);
      config.colorAccent = Qt.hsla(accentHue, accentSaturation, config.themeAccentLightness, 1);
      config.colorAccentText = config.barColor;
    }

    Settings {
      id: wallpaperSettings

      property string current: ""

      category: "Wallpaper"
      location: "file://" + Quickshell.env("HOME") + "/.config/quickshell/settings.ini"
    }

    FolderListModel {
      id: wallpaperFolder

      property bool picked: false

      folder: "file://" + config.wallpaperDir
      nameFilters: config.wallpaperFormats
      showDirs: false
      sortField: FolderListModel.Name
      onStatusChanged: {
        if (status !== FolderListModel.Ready || picked || count === 0)
          return ;

        picked = true;
        if (!config.wallpaperRandomOnStart && wallpaperSettings.current !== "")
          return ;

        wallpaperSettings.current = get(Math.floor(Math.random() * count), "filePath");
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
      color: config.wallpaperFallbackColor
      exclusionMode: ExclusionMode.Ignore
      screen: modelData

      anchors {
        left: true
        right: true
        top: true
        bottom: true
      }

      Image {
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: wallpaper.current !== "" ? "file://" + wallpaper.current : ""
        sourceSize: Qt.size(wallpaperWindow.modelData.width, wallpaperWindow.modelData.height)
      }

      Loader {
        active: config.themeFromWallpaper && wallpaperWindow.modelData === Quickshell.screens[0]

        sourceComponent: Canvas {
          id: sampler

          property string source: wallpaper.current
          property string sampled: ""

          height: config.themeSampleSize
          width: config.themeSampleSize
          x: -width
          onImageLoaded: requestPaint()
          onSourceChanged: requestPaint()
          onPaint: {
            if (source === "" || source === sampled)
              return ;

            var url = "file://" + source;
            if (!isImageLoaded(url)) {
              loadImage(url);
              return ;
            }
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.drawImage(url, 0, 0, width, height);
            wallpaper.applyPixels(ctx.getImageData(0, 0, width, height).data);
            sampled = source;
            Qt.callLater(function() {
              sampler.unloadImage(url);
            });
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        onClicked: shellRoot.dismissPopups()
      }
    }
  }

  // ── Now Playing Function ──
  Scope {
    id: media

    property var levels: []
    readonly property var player: {
      var list = Mpris.players.values;
      for (var i = 0; i < list.length; i++) {
        if (list[i].isPlaying)
          return list[i];

      }
      return null;
    }
    readonly property bool active: player !== null
    readonly property string label: {
      if (!player)
        return "";

      var parts = [];
      if (player.trackTitle)
        parts.push(player.trackTitle);

      if (player.trackArtist)
        parts.push(player.trackArtist);

      var text = parts.join(config.nowPlayingSeparator);
      return text.length > config.nowPlayingMaxLength ? text.substring(0, config.nowPlayingMaxLength - 1) + "…" : text;
    }

    onActiveChanged: {
      if (!active) {
        levels = [];
      }
    }

    Process {
      id: cava

      running: media.active && config.visualizerEnabled
      command: ["sh", "-c", 'f="${XDG_RUNTIME_DIR:-/tmp}/quickshell-cava.conf"; printf "%s\\n" "$0" > "$f"; exec cava -p "$f"', "[general]\n" + "bars = " + config.visualizerBars + "\n" + "framerate = " + config.visualizerFramerate + "\n" + "lower_cutoff_freq = " + config.visualizerMinFreq + "\n" + "higher_cutoff_freq = " + config.visualizerMaxFreq + "\n" + "[input]\nmethod = pipewire\nsource = auto\n" + "[output]\nmethod = raw\nraw_target = /dev/stdout\n" + "data_format = ascii\nascii_max_range = 100\n" + "bar_delimiter = 59\nframe_delimiter = 10\n" + "[smoothing]\nnoise_reduction = 77\n"]

      stdout: SplitParser {
        onRead: (data) => {
          var parts = data.split(";");
          var out = [];
          for (var i = 0; i < parts.length; i++) {
            if (parts[i] !== "")
              out.push(Number(parts[i]));

          }
          media.levels = out;
        }
      }
    }
  }

  // ── Layout State ──
  Scope {
    id: layoutState

    property var symbols: ({
    })

    Process {
      id: layoutWatcher

      command: ["mmsg", "watch", "all-monitors"]
      running: true
      onRunningChanged: {
        if (!running) {
          layoutRestart.start();
        }
      }

      stdout: SplitParser {
        onRead: (data) => {
          try {
            var monitors = JSON.parse(data).monitors || [];
            if (monitors.length === 0)
              return ;

            var next = Object.assign({
            }, layoutState.symbols);
            for (var i = 0; i < monitors.length; i++) next[monitors[i].name] = monitors[i].layout_symbol
              layoutState.symbols = next;
          } catch (e) {
          }
        }
      }
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

    function parse(text) {
      var lines = text.split("\n");
      for (var i = 0; i < lines.length; i++) {
        var fields = lines[i].split(":");
        if ((fields[0] === "wifi" || fields[0] === "ethernet") && fields[1] === "connected")
          return fields[0];

      }
      return "none";
    }

    Process {
      id: networkQuery

      command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]

      stdout: StdioCollector {
        onStreamFinished: network.kind = network.parse(text)
      }
    }

    Timer {
      interval: config.networkPollInterval
      repeat: true
      running: config.networkEnabled
      triggeredOnStart: true
      onTriggered: {
        if (!networkQuery.running) {
          networkQuery.running = true;
        }
      }
    }
  }

  // ── Input Method State ──
  Scope {
    id: inputMethod

    property string current: config.inputMethodLatin

    function toggle() {
      current = current === config.inputMethodJapanese ? config.inputMethodLatin : config.inputMethodJapanese;
      imHold.restart();
      Quickshell.execDetached(["fcitx5-remote", "-t"]);
    }

    Process {
      id: imQuery

      command: ["fcitx5-remote", "-n"]

      stdout: SplitParser {
        onRead: (data) => {
          if (data !== "" && !imHold.running)
            inputMethod.current = data.trim();

        }
      }
    }

    Timer {
      id: imHold

      interval: 800
    }

    Timer {
      interval: config.inputMethodPollInterval
      repeat: true
      running: config.inputMethodEnabled
      triggeredOnStart: true
      onTriggered: {
        if (!imQuery.running) {
          imQuery.running = true;
        }
      }
    }
  }

  // ── App Launcher Function ──
  Scope {
    id: launcher

    property var recentIds: JSON.parse(launcherSettings.recentIdsSerialized)

    function record(id) {
      var list = recentIds.filter((entry) => {
        return entry !== id;
      });
      list.unshift(id);
      if (list.length > config.appLauncherRecentMax)
        list.length = config.appLauncherRecentMax;

      recentIds = list;
      launcherSettings.recentIdsSerialized = JSON.stringify(list);
    }

    Settings {
      id: launcherSettings

      property string recentIdsSerialized: "[]"

      category: "AppLauncher"
      location: "file://" + Quickshell.env("HOME") + "/.config/quickshell/settings.ini"
    }
  }

  // ── Notification Function ──
  Scope {
    id: notifications

    NotificationServer {
      id: server

      actionsSupported: true
      bodyMarkupSupported: true
      bodySupported: true
      imageSupported: true
      onNotification: (n) => {
        n.tracked = true;
      }
    }

    PanelWindow {
      property real trayShift: shellRoot.trayPopupScreen === Quickshell.screens[0].name ? config.trayPopupExtent : 0

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.namespace: "notifications"
      color: "transparent"
      exclusiveZone: 0
      implicitHeight: Math.max(1, notificationColumn.implicitHeight)
      screen: Quickshell.screens[0]

      anchors {
        top: true
        left: true
        right: true
      }

      margins {
        top: config.notificationMargin + Math.round(trayShift)
      }

      ColumnLayout {
        id: notificationColumn

        spacing: config.notificationSpacing
        width: config.notificationWidth

        anchors {
          right: parent.right
          top: parent.top
          rightMargin: config.notificationMargin
        }

        Repeater {
          model: server.trackedNotifications

          delegate: Rectangle {
            id: card

            required property var modelData
            required property int index
            readonly property var notification: modelData
            readonly property bool critical: notification.urgency === NotificationUrgency.Critical
            readonly property int timeout: critical ? 0 : notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : config.notificationTimeout
            readonly property bool hasActions: {
              var list = notification.actions;
              for (var i = 0; i < list.length; i++) {
                if (list[i].identifier !== "default")
                  return true;

              }
              return false;
            }
            readonly property string iconSource: {
              if (notification.image !== "")
                return notification.image;

              var icon = notification.appIcon;
              if (icon === "")
                return "";

              return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true);
            }
            property real slideX: config.notificationWidth + config.notificationMargin
            property bool leaving: false
            property bool expireOnClose: false
            property var pendingAction: null

            function close(expired, action) {
              if (leaving)
                return ;

              leaving = true;
              expireOnClose = expired;
              pendingAction = action || null;
              slideIn.stop();
              slideOut.start();
            }

            Layout.fillWidth: true
            border.color: config.colorAccent
            border.width: critical ? 2 : 0
            color: config.barColor
            implicitHeight: cardContent.implicitHeight + config.notificationPadding * 2
            radius: config.notificationRadius
            visible: index < config.notificationMax
            Component.onCompleted: {
              if (visible) {
                slideIn.start();
              }
            }
            onVisibleChanged: {
              if (visible && !leaving) {
                slideIn.start();
              }
            }

            NumberAnimation {
              id: slideIn

              duration: config.notificationSlideDuration
              easing.type: Easing.OutQuint
              property: "slideX"
              target: card
              to: 0
            }

            NumberAnimation {
              id: slideOut

              duration: config.notificationSlideDuration
              easing.type: Easing.InQuint
              property: "slideX"
              target: card
              to: config.notificationWidth + config.notificationMargin
              onFinished: {
                var n = card.notification;
                var action = card.pendingAction;
                if (action) {
                  var keep = n.resident;
                  action.invoke();
                  if (keep)
                    n.dismiss();

                } else if (card.expireOnClose) {
                  n.expire();
                } else {
                  n.dismiss();
                }
              }
            }

            HoverHandler {
              id: cardHover
            }

            Timer {
              interval: card.timeout
              running: card.timeout > 0 && card.visible && !card.leaving && !cardHover.hovered
              onTriggered: card.close(true)
            }

            MouseArea {
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              anchors.fill: parent
              onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                  var list = card.notification.actions;
                  for (var i = 0; i < list.length; i++) {
                    if (list[i].identifier === "default") {
                      card.close(false, list[i]);
                      return ;
                    }
                  }
                }
                card.close(false);
              }
            }

            ColumnLayout {
              id: cardContent

              spacing: 8

              anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: config.notificationPadding
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Image {
                  Layout.alignment: Qt.AlignTop
                  Layout.preferredHeight: config.notificationIconSize
                  Layout.preferredWidth: config.notificationIconSize
                  asynchronous: true
                  fillMode: Image.PreserveAspectFit
                  source: card.visible ? card.iconSource : ""
                  sourceSize: Qt.size(config.notificationIconSize * 2, config.notificationIconSize * 2)
                  visible: source != ""
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  Text {
                    Layout.fillWidth: true
                    color: config.colorText
                    elide: Text.ElideRight
                    font.family: config.fontFamily
                    font.pixelSize: config.fontSize - 2
                    font.weight: config.fontWeight
                    opacity: 0.6
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
                    text: card.notification.body
                    textFormat: Text.StyledText
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
                    border.color: config.colorAccent
                    border.width: 1
                    color: actionArea.containsMouse ? config.colorAccent : "transparent"
                    implicitHeight: config.notificationButtonHeight
                    radius: config.notificationRadiusButton
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

            transform: Translate {
              x: card.slideX
            }
          }
        }
      }

      mask: Region {
        item: notificationColumn
      }

      Behavior on trayShift {
        NumberAnimation {
          duration: config.animationDuration
          easing.type: Easing.OutCubic
        }
      }
    }
  }

  // ── Lockscreen ──
  Scope {
    id: lockscreen

    property string password: ""
    property bool failed: false
    readonly property string background: config.lockWallpaper !== "" ? "file://" + config.lockWallpaper : (wallpaper.current !== "" ? "file://" + wallpaper.current : "")

    function format(text) {
      return config.lockUppercase ? text.toUpperCase() : text;
    }

    function submit(input) {
      if (pam.active || input.text === "")
        return ;

      lockscreen.password = input.text;
      input.text = "";
      pam.start();
    }

    IpcHandler {
      target: "lock"
      function lock(): void {
        if (!sessionLock.locked) sessionLock.locked = true
      }
    }

    QtObject {
      id: lockStyle

      readonly property color borderColor: config.lockColorBorder
      readonly property int borderWidth: config.lockButtonBorder
      readonly property int buttonHeight: config.lockButtonHeight
      readonly property string fontFamily: config.lockFontFamily
      readonly property int fontSize: config.lockButtonSize
      readonly property int fontWeight: config.lockFontWeight
      readonly property color hoverColor: config.lockColorAccent
      readonly property color hoverTextColor: config.lockColorAccentText
      readonly property real letterSpacing: config.lockLetterSpacing
      readonly property color textColor: config.lockColorText
    }

    PamContext {
      id: pam

      config: "password.conf"
      configDirectory: Quickshell.shellDir + "/pam"
      onCompleted: (result) => {
        lockscreen.password = "";
        if (result === PamResult.Success) {
          lockscreen.failed = false;
          sessionLock.locked = false;
        } else {
          lockscreen.failed = true;
        }
      }
      onResponseRequiredChanged: {
        if (responseRequired) {
          respond(lockscreen.password);
        }
      }
    }

    WlSessionLock {
      id: sessionLock

      WlSessionLockSurface {
        color: config.barColor

        Image {
          anchors.fill: parent
          asynchronous: true
          fillMode: Image.PreserveAspectCrop
          source: width > 0 ? lockscreen.background : ""
          sourceSize: Qt.size(width, height)
        }

        Rectangle {
          anchors.fill: parent
          color: "black"
          opacity: config.lockDim
        }

        Rectangle {
          height: parent.height * config.lockShadowHeight

          anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
          }

          gradient: Gradient {
            GradientStop {
              position: 0
              color: Qt.rgba(0, 0, 0, 0)
            }

            GradientStop {
              position: 1
              color: Qt.rgba(0, 0, 0, config.lockShadow)
            }
          }
        }

        // ── Now Playing Shadow ──
        CornerShadow {
          shadowHeight: config.lockPlayingShadowHeight
          shadowWidth: config.lockPlayingShadowWidth
          strength: media.active ? config.lockPlayingShadow : 0
        }

        // ── Clock Shadow ──
        CornerShadow {
          rightSide: true
          shadowHeight: config.lockClockShadowHeight
          shadowWidth: config.lockClockShadowWidth
          strength: config.lockClockShadow
        }

        // ── Lock Screen Now Playing ──
        Text {
          color: config.lockColorText
          font.family: config.lockFontFamily
          font.letterSpacing: config.lockLetterSpacing
          font.pixelSize: config.lockLabelSize
          font.weight: config.lockFontWeight
          text: lockscreen.format(media.label)
          visible: media.active

          anchors {
            left: parent.left
            top: parent.top
            margins: config.lockMargin
          }
        }

        // ── Lock Screen Clock ──
        Column {
          spacing: 4

          anchors {
            right: parent.right
            top: parent.top
            margins: config.lockMargin
          }

          Text {
            anchors.right: parent.right
            color: config.lockColorDate
            font.family: config.lockFontFamily
            font.letterSpacing: config.lockLetterSpacing
            font.pixelSize: config.lockDateSize
            font.weight: config.lockFontWeight
            text: lockscreen.format(Qt.formatDateTime(clock.date, config.lockDateFormat))
          }

          Text {
            anchors.right: parent.right
            color: config.lockColorText
            font.family: config.lockFontFamily
            font.pixelSize: config.lockClockSize
            font.weight: config.lockFontWeight
            text: Qt.formatTime(clock.date, config.lockClockFormat)
          }
        }

        // ── Login ──
        Column {
          spacing: config.lockSpacing

          anchors {
            left: parent.left
            bottom: parent.bottom
            margins: config.lockMargin
          }

          Text {
            color: config.lockColorText
            font.family: config.lockFontFamily
            font.letterSpacing: config.lockLetterSpacing
            font.pixelSize: config.lockLabelSize
            font.weight: config.lockFontWeight
            text: lockscreen.format(config.lockUsername)
          }

          Item {
            height: config.lockInputHeight
            width: config.lockInputWidth

            TextInput {
              id: lockInput

              color: config.lockColorText
              echoMode: TextInput.Password
              focus: true
              font.family: config.lockFontFamily
              font.pixelSize: config.lockLabelSize
              readOnly: pam.active
              onAccepted: lockscreen.submit(lockInput)
              onTextChanged: lockscreen.failed = false

              anchors {
                left: parent.left
                right: parent.right
                bottom: lockLine.top
                bottomMargin: 4
              }
            }

            Rectangle {
              id: lockLine

              color: lockscreen.failed ? config.lockColorError : config.lockColorAccent
              height: 2

              anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
              }
            }
          }

          Row {
            spacing: 16

            OutlineButton {
              id: loginButton

              horizontalPadding: config.lockLoginPadding
              label: lockscreen.format(config.lockLoginLabel)
              style: lockStyle
              onClicked: lockscreen.submit(lockInput)
            }

            Text {
              anchors.verticalCenter: loginButton.verticalCenter
              color: config.lockColorError
              font.family: config.lockFontFamily
              font.letterSpacing: config.lockLetterSpacing
              font.pixelSize: config.lockButtonSize
              font.weight: config.lockFontWeight
              text: lockscreen.format(config.lockErrorLabel)
              visible: lockscreen.failed
            }
          }
        }

        // ── Lock Screen Power Button ──
        Row {
          spacing: config.lockSpacing

          anchors {
            right: parent.right
            bottom: parent.bottom
            margins: config.lockMargin
          }

          Repeater {
            model: config.lockActions

            delegate: OutlineButton {
              required property var modelData

              horizontalPadding: config.lockButtonPadding
              label: lockscreen.format(modelData.label)
              style: lockStyle
              onClicked: Quickshell.execDetached(["sh", "-c", modelData.command])
            }
          }
        }
      }
    }
  }

  // ── Bar ──
  Scope {
    id: root

    Scope {
      id: launcherIpc

      signal toggleRequested()

      IpcHandler {
        target: "launcher"
        function toggle(): void {
          launcherIpc.toggleRequested()
        }
      }
    }

    Variants {
      model: Quickshell.screens

      Scope {
        id: screenRoot

        required property ShellScreen modelData
        readonly property bool cornersHidden: config.cornerHiddenLayouts.indexOf(layoutState.symbols[modelData.name]) !== -1
        property string openPopup: ""

        function closePopup(name) {
          Qt.callLater(() => {
            if (openPopup === name)
              openPopup = "";

          });
        }

        function togglePopup(name) {
          var wasOpen = openPopup === name;
          shellRoot.dismissPopups();
          if (!wasOpen)
            Qt.callLater(() => {
              openPopup = name;
            });
        }

        Connections {
          function onDismissPopups() {
            screenRoot.openPopup = "";
          }

          target: shellRoot
        }

        Connections {
          target: launcherIpc

          function onToggleRequested() {
            if (screenRoot.modelData === Quickshell.screens[0])
              screenRoot.togglePopup("launcher")
          }
        }

        PanelWindow {
          id: bar

          readonly property var projection: WindowManager.screenProjection(screenRoot.modelData)

          WlrLayershell.layer: WlrLayer.Bottom
          color: "transparent"
          exclusiveZone: config.barHeight
          implicitHeight: config.barHeight
          screen: screenRoot.modelData

          anchors {
            left: true
            right: true
            top: true
          }

          Item {
            anchors.fill: parent

            MouseArea {
              anchors.fill: parent
              onClicked: shellRoot.dismissPopups()
            }

            // ── Left Bar ──
            Rectangle {
              id: leftBar

              property int slideDuration: config.barSlideDuration
              property bool ready: false

              bottomRightRadius: config.barRadius
              clip: true
              color: config.barColor
              height: config.barHeight
              width: Math.round(leftRow.x + focusSlot.x + focusSlot.width + config.barPadding / 2)

              anchors {
                left: parent.left
                top: parent.top
              }

              Timer {
                interval: 1000
                running: true
                onTriggered: leftBar.ready = true
              }

              Row {
                id: leftRow

                spacing: config.barItemSpacing

                anchors {
                  left: parent.left
                  leftMargin: config.barPadding / 2
                  verticalCenter: parent.verticalCenter
                }

                // ── Power Menu ──
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: config.powerMenuIcon

                  MouseArea {
                    anchors.fill: parent
                    onClicked: screenRoot.togglePopup("power")
                  }
                }

                Separator {
                  cfg: config
                }

                // ── Layout ──
                Text {
                  id: layoutGlyph

                  property int nextIndex: 0
                  readonly property string currentLayout: layoutState.symbols[screenRoot.modelData.name] || config.layoutCycle[0]

                  anchors.verticalCenter: parent.verticalCenter
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: currentLayout

                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      layoutGlyph.nextIndex = (layoutGlyph.nextIndex + 1) % config.layoutCycle.length;
                      Quickshell.execDetached(["mmsg", "dispatch", "setlayout," + config.layoutCycle[layoutGlyph.nextIndex]]);
                    }
                  }
                }

                Separator {
                  cfg: config
                }

                // ── Workspace ──
                Row {
                  id: workspaceRow

                  anchors.verticalCenter: parent.verticalCenter
                  spacing: config.workspaceSpacing

                  Repeater {
                    model: bar.projection ? bar.projection.windowsets : []

                    delegate: Rectangle {
                      id: workspaceDelegate

                      required property var modelData
                      readonly property var ws: modelData
                      readonly property bool shouldShow: ws.shouldDisplay
                      property bool revealed: false

                      function reveal() {
                        revealTimer.stop();
                        if (leftBar.ready) {
                          revealed = false;
                          revealTimer.restart();
                        } else {
                          revealed = true;
                        }
                      }

                      anchors.verticalCenter: parent.verticalCenter
                      color: ws.urgent || ws.active ? config.colorAccent : "transparent"
                      implicitHeight: config.workspaceHeight
                      implicitWidth: Math.max(config.workspaceWidth, workspaceLabel.implicitWidth + config.workspacePadding)
                      opacity: revealed ? 1 : 0
                      radius: config.workspaceRadius
                      visible: shouldShow || opacity > 0
                      Component.onCompleted: {
                        if (shouldShow) {
                          reveal();
                        }
                      }
                      onShouldShowChanged: {
                        if (shouldShow) {
                          reveal();
                        } else {
                          revealTimer.stop();
                          revealed = false;
                        }
                      }

                      Timer {
                        id: revealTimer

                        interval: leftBar.slideDuration
                        onTriggered: workspaceDelegate.revealed = true
                      }

                      Text {
                        id: workspaceLabel

                        anchors.centerIn: parent
                        color: workspaceDelegate.ws.active ? config.colorAccentText : config.colorText
                        font.family: config.fontFamily
                        font.pixelSize: config.fontSize
                        font.weight: config.fontWeight
                        rightPadding: 1
                        text: workspaceDelegate.ws.name.length ? workspaceDelegate.ws.name : (workspaceDelegate.ws.coordinates[0] + 1)
                      }

                      MouseArea {
                        anchors.fill: parent
                        enabled: workspaceDelegate.shouldShow
                        onClicked: {
                          if (workspaceDelegate.ws.canActivate) {
                            workspaceDelegate.ws.activate();
                          }
                        }
                      }

                      Behavior on opacity {
                        enabled: leftBar.ready

                        NumberAnimation {
                          duration: config.animationDuration
                          easing.type: Easing.OutQuint
                        }
                      }
                    }
                  }

                  move: Transition {
                    NumberAnimation {
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                      properties: "x"
                    }
                  }
                }

                Separator {
                  cfg: config
                }

                // ── App Launcher ──
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: config.appLauncherIcon

                  MouseArea {
                    anchors.fill: parent
                    onClicked: screenRoot.togglePopup("launcher")
                  }
                }

                // ── Focus Window ──
                Item {
                  id: focusSlot

                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  height: focusWindow.implicitHeight
                  width: focusWindow.implicitWidth

                  RowLayout {
                    id: focusWindow

                    readonly property var toplevel: ToplevelManager.activeToplevel
                    readonly property string appKey: toplevel ? toplevel.appId.toLowerCase() : ""
                    readonly property string targetIcon: toplevel ? (config.focusWindowIcons[appKey] || config.focusWindowGlyph) : config.focusWindowGlyph
                    readonly property string targetLabel: toplevel ? (config.focusWindowNames[appKey] || toplevel.appId) : config.focusWindowPlaceholder
                    property string shownIcon: targetIcon
                    property string shownLabel: targetLabel

                    function apply() {
                      shownIcon = targetIcon;
                      shownLabel = targetLabel;
                    }

                    function update() {
                      if (leftBar.ready)
                        swap.restart();
                      else
                        apply();
                    }

                    spacing: 8
                    onTargetIconChanged: update()
                    onTargetLabelChanged: update()

                    anchors {
                      left: parent.left
                      verticalCenter: parent.verticalCenter
                    }

                    SequentialAnimation {
                      id: swap

                      NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutQuint
                        property: "opacity"
                        target: focusWindow
                        to: 0
                      }

                      ScriptAction {
                        script: focusWindow.apply()
                      }

                      NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutQuint
                        property: "opacity"
                        target: focusWindow
                        to: 1
                      }
                    }

                    Text {
                      color: config.colorText
                      font.family: config.iconFontFamily
                      font.pixelSize: config.iconSize
                      text: focusWindow.shownIcon
                    }

                    Text {
                      color: config.colorText
                      elide: Text.ElideRight
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      text: focusWindow.shownLabel
                    }
                  }

                  Behavior on width {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                    }
                  }
                }

                move: Transition {
                  NumberAnimation {
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                    properties: "x"
                  }
                }
              }
            }

            // ── Power Menu Popup ──
            LazyLoader {
              id: powerMenuLoader

              active: screenRoot.openPopup === "power"

              PopupWindow {
                anchor.edges: Edges.Top | Edges.Left
                anchor.gravity: Edges.Bottom | Edges.Right
                anchor.rect.x: config.powerMenuMargin
                anchor.rect.y: bar.height + config.powerMenuMargin
                anchor.window: bar
                color: "transparent"
                grabFocus: true
                implicitHeight: powerMenuColumn.implicitHeight + config.powerMenuPadding * 2
                implicitWidth: config.powerMenuWidth
                visible: true
                onVisibleChanged: {
                  if (!visible) {
                    screenRoot.closePopup("power");
                  }
                }

                Rectangle {
                  anchors.fill: parent
                  color: config.barColor
                  radius: config.powerMenuPopupRadius

                  ColumnLayout {
                    id: powerMenuColumn

                    anchors.fill: parent
                    anchors.margins: config.powerMenuPadding
                    spacing: config.powerMenuSpacing

                    Repeater {
                      model: config.powerMenuActions

                      delegate: Rectangle {
                        id: powerMenuOption

                        required property var modelData

                        Layout.fillWidth: true
                        color: powerMenuOptionArea.containsMouse ? config.colorAccent : "transparent"
                        implicitHeight: config.powerMenuItemHeight
                        radius: config.powerMenuRadius

                        Text {
                          anchors.verticalCenter: parent.verticalCenter
                          color: powerMenuOptionArea.containsMouse ? config.colorAccentText : config.colorText
                          font.family: config.fontFamily
                          font.pixelSize: config.fontSize
                          font.weight: config.fontWeight
                          leftPadding: 8
                          text: powerMenuOption.modelData.label
                        }

                        MouseArea {
                          id: powerMenuOptionArea

                          anchors.fill: parent
                          hoverEnabled: true
                          onClicked: {
                            Quickshell.execDetached(["sh", "-c", powerMenuOption.modelData.command]);
                            screenRoot.closePopup("power");
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            // ── App Launcher Click Catcher ──
            LazyLoader {
              id: launcherCatcherLoader

              active: screenRoot.openPopup === "launcher"

              PanelWindow {
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "app-launcher-catcher"
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                screen: screenRoot.modelData
                visible: true

                anchors {
                  left: true
                  right: true
                  top: true
                  bottom: true
                }

                MouseArea {
                  acceptedButtons: Qt.AllButtons
                  anchors.fill: parent
                  onClicked: screenRoot.closePopup("launcher")
                }
              }
            }

            // ── App Launcher Popup ──
            LazyLoader {
              id: launcherLoader

              active: screenRoot.openPopup === "launcher"

              PanelWindow {
                id: appLauncherPopup

                property string searchQuery: ""
                property int selectedIndex: 0
                property var recentSnapshot: []
                readonly property int chromeHeight: config.appLauncherSearchHeight + config.appLauncherPadding * 3
                readonly property int fullHeight: chromeHeight + config.appLauncherMaxVisible * config.appLauncherItemHeight
                readonly property var appsByName: DesktopEntries.applications.values.slice().sort((a, b) => {
                  return a.name.localeCompare(b.name);
                })
                readonly property var filteredApps: {
                  var apps = appsByName;
                  var q = searchQuery.trim().toLowerCase();
                  if (q !== "")
                    return apps.filter((entry) => {
                      return matches(entry, q);
                    });

                  var rank = new Map();
                  var recent = recentSnapshot;
                  for (var i = 0; i < recent.length; i++) rank.set(recent[i], i)
                    var head = [];
                  var tail = [];
                  for (var j = 0; j < apps.length; j++) {
                    if (rank.has(apps[j].id))
                      head.push(apps[j]);
                    else
                      tail.push(apps[j]);
                  }
                  head.sort((a, b) => {
                    return rank.get(a.id) - rank.get(b.id);
                  });
                  return head.concat(tail);
                }

                function matches(entry, q) {
                  if (entry.name.toLowerCase().indexOf(q) !== -1)
                    return true;

                  if (entry.genericName && entry.genericName.toLowerCase().indexOf(q) !== -1)
                    return true;

                  for (var i = 0; i < entry.keywords.length; i++) {
                    if (entry.keywords[i].toLowerCase().indexOf(q) !== -1)
                      return true;

                  }
                  return false;
                }

                function navigate(delta) {
                  if (filteredApps.length === 0)
                    return ;

                  selectedIndex = (selectedIndex + delta + filteredApps.length) % filteredApps.length;
                  appList.positionViewAtIndex(selectedIndex, ListView.Contain);
                }

                function launchEntry(entry) {
                  launcher.record(entry.id)
                  if (entry.runInTerminal) {
                    Quickshell.execDetached({
                      command: config.appLauncherTerminal.concat(entry.command),
                      workingDirectory: entry.workingDirectory
                    })
                  } else {
                    entry.execute()
                  }
                  appLauncherPopup.visible = false
                }

                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "app-launcher"
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                implicitHeight: fullHeight
                implicitWidth: config.appLauncherWidth
                margins.top: Math.max(0, Math.round((screenRoot.modelData.height - fullHeight) / 2))
                screen: screenRoot.modelData
                visible: true
                onFilteredAppsChanged: selectedIndex = 0
                Component.onCompleted: {
                  recentSnapshot = launcher.recentIds;
                  searchField.forceActiveFocus();
                }

                anchors {
                  top: true
                }

                Rectangle {
                  id: launcherCard

                  color: config.barColor
                  height: appLauncherPopup.chromeHeight + Math.min(appLauncherPopup.filteredApps.length, config.appLauncherMaxVisible) * config.appLauncherItemHeight
                  radius: config.workspaceRadius

                  anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                  }

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: config.appLauncherPadding
                    spacing: config.appLauncherPadding

                    Rectangle {
                      Layout.fillWidth: true
                      color: config.colorInput
                      implicitHeight: config.appLauncherSearchHeight
                      radius: config.workspaceRadius

                      TextInput {
                        id: searchField

                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        clip: true
                        color: config.colorText
                        font.family: config.fontFamily
                        font.pixelSize: config.fontSize
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: appLauncherPopup.searchQuery = text
                        Keys.onPressed: function(event) {
                          if (event.key === Qt.Key_Up) {
                            appLauncherPopup.navigate(-1);
                            event.accepted = true;
                          } else if (event.key === Qt.Key_Down) {
                            appLauncherPopup.navigate(1);
                            event.accepted = true;
                          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (appLauncherPopup.filteredApps.length > 0)
                              appLauncherPopup.launchEntry(appLauncherPopup.filteredApps[appLauncherPopup.selectedIndex]);

                            event.accepted = true;
                          } else if (event.key === Qt.Key_Escape) {
                            screenRoot.closePopup("launcher");
                            event.accepted = true;
                          }
                        }

                        Text {
                          anchors.fill: parent
                          color: config.colorText
                          font.family: config.fontFamily
                          font.pixelSize: config.fontSize
                          opacity: 0.35
                          text: config.appLauncherPlaceholder
                          verticalAlignment: Text.AlignVCenter
                          visible: searchField.text === ""
                        }
                      }
                    }

                    ListView {
                      id: appList

                      Layout.fillWidth: true
                      Layout.preferredHeight: Math.min(appLauncherPopup.filteredApps.length, config.appLauncherMaxVisible) * config.appLauncherItemHeight
                      boundsBehavior: Flickable.StopAtBounds
                      cacheBuffer: 0
                      clip: true
                      model: appLauncherPopup.filteredApps
                      reuseItems: true

                      Text {
                        anchors.centerIn: parent
                        color: config.colorText
                        font.family: config.fontFamily
                        font.pixelSize: config.fontSize
                        opacity: 0.35
                        text: config.appLauncherEmpty
                        visible: appLauncherPopup.filteredApps.length === 0
                      }

                      delegate: Rectangle {
                        id: appRow

                        required property var modelData
                        required property int index

                        color: appLauncherPopup.selectedIndex === index ? config.colorAccent : "transparent"
                        height: config.appLauncherItemHeight
                        radius: config.workspaceRadius
                        width: appList.width

                        Row {
                          anchors.fill: parent
                          anchors.leftMargin: 8
                          anchors.rightMargin: 8
                          spacing: 10

                          Image {
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            height: config.appLauncherIconSize
                            source: appRow.modelData.icon !== "" ? "image://icon/" + appRow.modelData.icon : ""
                            sourceSize: Qt.size(config.appLauncherIconSize * 2, config.appLauncherIconSize * 2)
                            width: config.appLauncherIconSize
                          }

                          Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: appLauncherPopup.selectedIndex === appRow.index ? config.colorAccentText : config.colorText
                            elide: Text.ElideRight
                            font.family: config.fontFamily
                            font.pixelSize: config.fontSize
                            font.weight: config.fontWeight
                            text: appRow.modelData.name
                            width: parent.width - config.appLauncherIconSize - 10
                          }
                        }

                        MouseArea {
                          anchors.fill: parent
                          hoverEnabled: true
                          onClicked: appLauncherPopup.launchEntry(appRow.modelData)
                          onEntered: appLauncherPopup.selectedIndex = appRow.index
                        }
                      }
                    }
                  }
                }

                mask: Region {
                  item: launcherCard
                }
              }
            }

            // ── Left Concave 2 ──
            Concave {
              cfg: config

              anchors {
                left: leftBar.right
                top: parent.top
              }
            }

            // ── Center Concave 1 ──
            Concave {
              cfg: config
              mirrored: true

              anchors {
                right: centerBar.left
                top: parent.top
              }
            }

            // ── Center Bar ──
            Rectangle {
              id: centerBar

              readonly property real contentEdge: mediaSlot.width > 0 ? mediaSlot.x + mediaSlot.width : clockLabel.x + clockLabel.width
              readonly property int roundedWidth: Math.round(centerRow.x + contentEdge + config.barPadding / 2)

              bottomLeftRadius: config.barRadius
              bottomRightRadius: config.barRadius
              clip: true
              color: config.barColor
              height: config.barHeight
              width: ((parent.width - roundedWidth) % 2 !== 0) ? roundedWidth + 1 : roundedWidth

              anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
              }

              Row {
                id: centerRow

                spacing: 0

                anchors {
                  left: parent.left
                  leftMargin: config.barPadding / 2
                  verticalCenter: parent.verticalCenter
                }

                // ── Clock ──
                Text {
                  id: clockLabel

                  anchors.verticalCenter: parent.verticalCenter
                  color: config.colorText
                  font.family: config.fontFamily
                  font.pixelSize: config.fontSize
                  font.weight: config.fontWeight
                  text: Qt.formatDateTime(clock.date, config.barClockFormat)
                }

                // ── Media ──
                Item {
                  id: mediaSlot

                  property bool expanded: false
                  property bool contentShown: false
                  readonly property bool wanted: media.active

                  function show() {
                    hideTimer.stop();
                    expanded = true;
                    if (leftBar.ready) {
                      contentShown = false;
                      showTimer.restart();
                    } else {
                      contentShown = true;
                    }
                  }

                  function hide() {
                    showTimer.stop();
                    labelSwap.stop();
                    contentShown = false;
                    if (leftBar.ready)
                      hideTimer.restart();
                    else
                      expanded = false;
                  }

                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  height: mediaRow.implicitHeight
                  width: expanded ? config.barItemSpacing + mediaRow.implicitWidth : 0
                  Component.onCompleted: {
                    if (wanted) {
                      show();
                    }
                  }
                  onWantedChanged: wanted ? show() : hide()

                  Timer {
                    id: showTimer

                    interval: leftBar.slideDuration
                    onTriggered: mediaSlot.contentShown = true
                  }

                  Timer {
                    id: hideTimer

                    interval: config.animationDuration
                    onTriggered: mediaSlot.expanded = false
                  }

                  RowLayout {
                    id: mediaRow

                    readonly property string targetLabel: media.label
                    property string shownLabel: targetLabel

                    function update() {
                      if (media.player === null)
                        return ;

                      if (leftBar.ready && mediaSlot.contentShown)
                        labelSwap.restart();
                      else
                        shownLabel = targetLabel;
                    }

                    opacity: mediaSlot.contentShown ? 1 : 0
                    spacing: config.barItemSpacing
                    onTargetLabelChanged: update()

                    anchors {
                      left: parent.left
                      leftMargin: config.barItemSpacing
                      verticalCenter: parent.verticalCenter
                    }

                    SequentialAnimation {
                      id: labelSwap

                      NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutQuint
                        property: "opacity"
                        target: mediaRow
                        to: 0
                      }

                      ScriptAction {
                        script: mediaRow.shownLabel = mediaRow.targetLabel
                      }

                      NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutQuint
                        property: "opacity"
                        target: mediaRow
                        to: 1
                      }
                    }

                    // ── Visualizer ──
                    Row {
                      Layout.alignment: Qt.AlignVCenter
                      Layout.preferredHeight: config.visualizerHeight
                      spacing: config.visualizerBarGap
                      visible: config.visualizerEnabled

                      Repeater {
                        model: config.visualizerBars

                        delegate: Rectangle {
                          required property int index

                          anchors.verticalCenter: parent.verticalCenter
                          color: config.colorAccent
                          height: Math.max(config.visualizerBarWidth, ((media.levels[index] || 0) / 100) * config.visualizerHeight)
                          width: config.visualizerBarWidth

                          Behavior on height {
                            NumberAnimation {
                              duration: config.animationDuration
                            }
                          }
                        }
                      }
                    }

                    // ── Now Playing ──
                    Text {
                      color: config.colorText
                      font.family: config.fontFamily
                      font.pixelSize: config.fontSize
                      font.weight: config.fontWeight
                      text: mediaRow.shownLabel

                      MouseArea {
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        anchors.fill: parent
                        onClicked: (mouse) => {
                          if (!media.player)
                            return ;

                          if (mouse.button === Qt.RightButton) {
                            if (media.player.canGoNext)
                              media.player.next();

                          } else if (media.player.canTogglePlaying) {
                            media.player.togglePlaying();
                          }
                        }
                      }
                    }

                    Behavior on opacity {
                      enabled: leftBar.ready && !labelSwap.running

                      NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutQuint
                      }
                    }
                  }

                  Behavior on width {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                    }
                  }
                }

                move: Transition {
                  NumberAnimation {
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                    properties: "x"
                  }
                }
              }
            }

            // ── Center Concave 2 ──
            Concave {
              cfg: config

              anchors {
                left: centerBar.right
                top: parent.top
              }
            }

            // ── Right Concave 1 ──
            Concave {
              cfg: config
              mirrored: true

              anchors {
                right: rightBar.left
                top: parent.top
              }
            }

            // ── Right Bar ──
            Rectangle {
              id: rightBar

              bottomLeftRadius: config.barRadius
              clip: true
              color: config.barColor
              height: config.barHeight
              width: Math.round(rightRow.x + imSlot.x + imSlot.width + config.barPadding / 2)

              anchors {
                right: parent.right
                top: parent.top
              }

              Row {
                id: rightRow

                spacing: config.barItemSpacing

                anchors {
                  left: parent.left
                  leftMargin: config.barPadding / 2
                  verticalCenter: parent.verticalCenter
                }

                // ── System Tray ──
                Item {
                  id: traySlot

                  readonly property bool shouldShow: SystemTray.items.values.length > 0
                  property bool revealed: false

                  function reveal() {
                    trayTimer.stop();
                    if (leftBar.ready) {
                      revealed = false;
                      trayTimer.restart();
                    } else {
                      revealed = true;
                    }
                  }

                  anchors.verticalCenter: parent.verticalCenter
                  implicitHeight: trayContent.implicitHeight
                  implicitWidth: trayContent.implicitWidth
                  opacity: revealed ? 1 : 0
                  visible: shouldShow || opacity > 0
                  Component.onCompleted: {
                    if (shouldShow) {
                      reveal();
                    }
                  }
                  onShouldShowChanged: {
                    if (shouldShow) {
                      reveal();
                    } else {
                      trayTimer.stop();
                      revealed = false;
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
                      text: screenRoot.openPopup === "tray" ? config.trayIconCollapse : config.trayIconExpand

                      MouseArea {
                        anchors.fill: parent
                        onClicked: screenRoot.togglePopup("tray")
                      }

                      LazyLoader {
                        id: trayLoader

                        active: screenRoot.openPopup === "tray"

                        PopupWindow {
                          anchor.edges: Edges.Bottom
                          anchor.gravity: Edges.Bottom
                          anchor.rect.height: 1
                          anchor.rect.width: 1
                          anchor.rect.x: 0
                          anchor.rect.y: bar.height + config.trayPopupMargin
                          anchor.window: bar
                          color: "transparent"
                          grabFocus: true
                          implicitHeight: config.trayIconSize + config.trayPopupPadding * 2
                          implicitWidth: trayIcons.implicitWidth + config.trayPopupPadding * 2
                          visible: false
                          Component.onCompleted: {
                            anchor.rect.x = trayArrow.mapToItem(null, trayArrow.width / 2, 0).x;
                            shellRoot.trayPopupScreen = screenRoot.modelData.name;
                            visible = true;
                          }
                          Component.onDestruction: {
                            if (shellRoot.trayPopupScreen === screenRoot.modelData.name)
                              shellRoot.trayPopupScreen = "";
                          }
                          onVisibleChanged: {
                            if (!visible) {
                              screenRoot.closePopup("tray");
                            }
                          }

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
                                    asynchronous: true
                                    source: trayDelegate.modelData.icon
                                  }

                                  MouseArea {
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    anchors.fill: parent
                                    onClicked: (mouse) => {
                                      var item = trayDelegate.modelData;
                                      if (mouse.button === Qt.LeftButton && !item.onlyMenu) {
                                        item.activate();
                                        screenRoot.closePopup("tray");
                                      } else if (mouse.button === Qt.MiddleButton) {
                                        item.secondaryActivate();
                                        screenRoot.closePopup("tray");
                                      } else if (item.hasMenu) {
                                        var pos = trayDelegate.mapToItem(null, 0, trayDelegate.height);
                                        item.display(trayDelegate.QsWindow.window, pos.x, pos.y);
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

                    Separator {
                      cfg: config
                    }
                  }

                  Behavior on opacity {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: config.animationDuration
                      easing.type: Easing.OutQuint
                    }
                  }
                }

                // ── Wallpaper ──
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  text: config.wallpaperIcon

                  MouseArea {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    anchors.fill: parent
                    onClicked: (mouse) => {
                      return wallpaper.step(mouse.button === Qt.RightButton ? -1 : 1);
                    }
                  }
                }

                Separator {
                  cfg: config
                }

                // ── Volume ──
                Item {
                  id: volumeItem

                  readonly property var sink: Pipewire.defaultAudioSink
                  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
                  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

                  anchors.verticalCenter: parent.verticalCenter
                  implicitHeight: volumeRow.implicitHeight
                  implicitWidth: volumeRow.implicitWidth

                  PwObjectTracker {
                    objects: [volumeItem.sink]
                  }

                  RowLayout {
                    id: volumeRow

                    spacing: 6

                    Text {
                      Layout.alignment: Qt.AlignVCenter
                      color: config.colorText
                      font.family: config.iconFontFamily
                      font.pixelSize: config.iconSize
                      text: volumeItem.muted ? config.volumeIconMuted : volumeItem.volume < 0.5 ? config.volumeIconLow : config.volumeIconHigh
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
                    acceptedButtons: Qt.LeftButton
                    anchors.fill: parent
                    onClicked: {
                      if (volumeItem.sink && volumeItem.sink.audio)
                        volumeItem.sink.audio.muted = !volumeItem.sink.audio.muted;
                    }
                    onWheel: (wheel) => {
                      if (!volumeItem.sink || !volumeItem.sink.audio)
                        return ;

                      var delta = wheel.angleDelta.y > 0 ? config.volumeStep : -config.volumeStep;
                      volumeItem.sink.audio.muted = false;
                      volumeItem.sink.audio.volume = Math.max(0, Math.min(1, volumeItem.volume + delta));
                    }
                  }
                }

                Separator {
                  cfg: config
                }

                // ── Network ──
                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  color: config.colorText
                  font.family: config.iconFontFamily
                  font.pixelSize: config.iconSize
                  opacity: network.kind === "none" ? config.networkDisconnectedOpacity : 1
                  text: network.kind === "ethernet" ? config.networkIconEthernet : config.networkIconWifi

                  MouseArea {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(config.networkCommand)
                  }
                }

                // ── Input Method ──
                Item {
                  id: imSlot

                  anchors.verticalCenter: parent.verticalCenter
                  clip: true
                  height: imText.implicitHeight
                  width: imText.implicitWidth

                  Text {
                    id: imText

                    readonly property string targetText: inputMethod.current === config.inputMethodJapanese ? config.inputMethodLabelJapanese : config.inputMethodLabelLatin
                    property string shownText: targetText

                    color: config.colorText
                    font.family: config.fontFamily
                    font.pixelSize: config.fontSize
                    font.weight: config.fontWeight
                    text: shownText
                    onTargetTextChanged: {
                      if (leftBar.ready)
                        imSwap.restart();
                      else
                        shownText = targetText;
                    }

                    anchors {
                      left: parent.left
                      verticalCenter: parent.verticalCenter
                    }

                    SequentialAnimation {
                      id: imSwap

                      NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutQuint
                        property: "opacity"
                        target: imText
                        to: 0
                      }

                      ScriptAction {
                        script: imText.shownText = imText.targetText
                      }

                      NumberAnimation {
                        duration: config.animationDuration
                        easing.type: Easing.OutQuint
                        property: "opacity"
                        target: imText
                        to: 1
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      onClicked: inputMethod.toggle()
                    }
                  }

                  Behavior on width {
                    enabled: leftBar.ready

                    NumberAnimation {
                      duration: leftBar.slideDuration
                      easing.type: Easing.InOutQuint
                    }
                  }
                }

                move: Transition {
                  NumberAnimation {
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                    properties: "x"
                  }
                }
              }
            }

            // ── Left Concave 1 ──
            PanelWindow {
              color: "transparent"
              exclusionMode: ExclusionMode.Ignore
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius
              margins.top: config.barHeight
              screen: screenRoot.modelData
              visible: !screenRoot.cornersHidden || leftConcave1.x > -config.barRadius

              anchors {
                left: true
                top: true
              }

              Concave {
                id: leftConcave1

                cfg: config
                x: screenRoot.cornersHidden ? -config.barRadius : 0

                Behavior on x {
                  NumberAnimation {
                    duration: leftBar.slideDuration
                    easing.type: Easing.InOutQuint
                  }
                }
              }

              mask: Region {
              }
            }

            // ── Right Concave 2 ──
            PanelWindow {
              color: "transparent"
              exclusionMode: ExclusionMode.Ignore
              implicitHeight: config.barRadius
              implicitWidth: config.barRadius
              margins.top: config.barHeight
              screen: screenRoot.modelData
              visible: !screenRoot.cornersHidden

              anchors {
                right: true
                top: true
              }

              Concave {
                cfg: config
                mirrored: true
              }

              mask: Region {
              }
            }
          }
        }
      }
    }
  }

  // ── Separator ──
  component Separator: Text {
    required property QtObject cfg

    anchors.verticalCenter: parent.verticalCenter
    bottomPadding: 3
    color: cfg.colorText
    font.family: cfg.fontFamily
    font.pixelSize: cfg.fontSize
    font.weight: cfg.fontWeight
    text: "|"
  }

  // ── Concave Shape ──
  component Concave: Shape {
    required property QtObject cfg
    property bool mirrored: false

    implicitHeight: cfg.barRadius
    implicitWidth: cfg.barRadius
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: cfg.barColor
      startX: cfg.barRadius
      startY: 0
      strokeColor: "transparent"

      PathLine {
        x: 0
        y: 0
      }

      PathLine {
        x: 0
        y: cfg.barRadius
      }

      PathArc {
        direction: PathArc.Clockwise
        radiusX: cfg.barRadius
        radiusY: cfg.barRadius
        x: cfg.barRadius
        y: 0
      }
    }

    transform: Scale {
      origin.x: cfg.barRadius / 2
      origin.y: 0
      xScale: mirrored ? -1 : 1
    }
  }

  // ── Shadow ──
  component CornerShadow: Shape {
    id: shadow

    property bool rightSide: false
    property real strength: 0
    property real shadowWidth: 1920
    property real shadowHeight: 540

    anchors.left: rightSide ? undefined : parent.left
    anchors.right: rightSide ? parent.right : undefined
    anchors.top: parent.top
    height: width
    visible: strength > 0
    width: Math.max(1, shadowWidth)

    ShapePath {
      startX: 0
      startY: 0
      strokeColor: "transparent"

      PathLine {
        x: shadow.width
        y: 0
      }

      PathLine {
        x: shadow.width
        y: shadow.height
      }

      PathLine {
        x: 0
        y: shadow.height
      }

      PathLine {
        x: 0
        y: 0
      }

      fillGradient: RadialGradient {
        centerRadius: shadow.width
        centerX: shadow.rightSide ? shadow.width : 0
        centerY: 0
        focalX: centerX
        focalY: 0

        GradientStop {
          position: 0
          color: Qt.rgba(0, 0, 0, shadow.strength)
        }

        GradientStop {
          position: 0.125
          color: Qt.rgba(0, 0, 0, shadow.strength * 0.765625)
        }

        GradientStop {
          position: 0.25
          color: Qt.rgba(0, 0, 0, shadow.strength * 0.5625)
        }

        GradientStop {
          position: 0.375
          color: Qt.rgba(0, 0, 0, shadow.strength * 0.390625)
        }

        GradientStop {
          position: 0.5
          color: Qt.rgba(0, 0, 0, shadow.strength * 0.25)
        }

        GradientStop {
          position: 0.625
          color: Qt.rgba(0, 0, 0, shadow.strength * 0.140625)
        }

        GradientStop {
          position: 0.75
          color: Qt.rgba(0, 0, 0, shadow.strength * 0.0625)
        }

        GradientStop {
          position: 0.875
          color: Qt.rgba(0, 0, 0, shadow.strength * 0.015625)
        }

        GradientStop {
          position: 1
          color: Qt.rgba(0, 0, 0, 0)
        }
      }
    }

    transform: Scale {
      yScale: shadow.shadowHeight / shadow.width
    }
  }

  // ── Login Button ──
  component OutlineButton: Rectangle {
    id: button

    required property QtObject style
    property string label: ""
    property int horizontalPadding: 24
    readonly property bool hovered: area.containsMouse

    signal clicked()

    border.color: style.borderColor
    border.width: style.borderWidth
    color: hovered ? style.hoverColor : "transparent"
    implicitHeight: style.buttonHeight
    implicitWidth: caption.implicitWidth + horizontalPadding

    Text {
      id: caption

      anchors.centerIn: parent
      color: button.hovered ? button.style.hoverTextColor : button.style.textColor
      font.family: button.style.fontFamily
      font.letterSpacing: button.style.letterSpacing
      font.pixelSize: button.style.fontSize
      font.weight: button.style.fontWeight
      text: button.label
    }

    MouseArea {
      id: area

      anchors.fill: parent
      hoverEnabled: true
      onClicked: button.clicked()
    }
  }
}
