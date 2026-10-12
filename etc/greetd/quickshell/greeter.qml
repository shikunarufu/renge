// greeter.qml — Quickshell greeter for greetd.
//
// Settings: edit GreeterConfig.qml (same folder).
// Preview without greetd: quickshell -p greeter.qml (no login happens).

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

ShellRoot {
  id: shellRoot

  property string hostname: ""
  property string loginUser: ""
  property string homeDir: ""
  property string wallpaperDir: ""
  property var passwdLines: []
  property bool wallpaperFailed: false
  readonly property string fallbackPath: config.background === "" || wallpaperDir === ""
    ? ""
    : (config.background.startsWith("/") ? config.background : wallpaperDir + "/" + config.background)
  property string wallpaper: ""
  property var wallpaperFiles: []
  property string status: ""
  property bool statusIsError: false
  property bool awaitingPassword: false
  property bool echoInput: false
  property bool leaving: false
  readonly property bool preview: !Greetd.available

  GreeterConfig { id: config }

  // ── Login flow ──
  function startSession() {
    if (loginUser === "") {
      status = "No user found"
      statusIsError = true
      return
    }
    if (preview) {
      awaitingPassword = true
      return
    }
    Greetd.createSession(loginUser)
  }

  function submit(password) {
    if (!awaitingPassword || leaving) return

    awaitingPassword = false
    status = ""
    statusIsError = false

    if (preview) {
      status = "Preview: greetd not available"
      awaitingPassword = true
      return
    }
    Greetd.respond(password)
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (responseRequired) {
        shellRoot.echoInput = echoResponse
        shellRoot.awaitingPassword = true
      } else {
        shellRoot.status = message
        shellRoot.statusIsError = error
      }
    }

    function onAuthFailure(message) {
      shellRoot.awaitingPassword = false
      shellRoot.status = "Authentication failed"
      shellRoot.statusIsError = true
      retry.restart()
    }

    function onError(error) {
      shellRoot.awaitingPassword = false
      shellRoot.status = error
      shellRoot.statusIsError = true
      retry.restart()
    }

    // Animations must finish before launch(); greetd expects the greeter to exit quickly.
    function onReadyToLaunch() {
      shellRoot.leaving = true
      fadeOut.start()
    }
  }

  Timer {
    id: retry

    interval: config.retryDelay

    onTriggered: {
      if (Greetd.state === GreetdState.Inactive) shellRoot.startSession()
      else retry.restart()
    }
  }

  // ── Data sources ──
  SystemClock {
    id: clock

    precision: SystemClock.Minutes
  }

  // Finds the login user from passwd (name:x:uid:gid:gecos:home:shell).
  // Uses config.user if set; otherwise the first account with UID 1000-59999 and a real shell.
  // Then starts the login session and the wallpaper scan.
  Process {
    running: true
    command: ["getent", "passwd"]

    stdout: SplitParser {
      onRead: data => { if (data !== "") shellRoot.passwdLines.push(data) }
    }

    onExited: {
      for (const line of shellRoot.passwdLines) {
        const f = line.split(":")
        if (f.length < 7) continue

        const uid = parseInt(f[2])
        const shell = f[6]
        const regular = uid >= 1000 && uid < 60000
          && !shell.endsWith("/nologin") && !shell.endsWith("/false")
        const match = config.user !== "" ? f[0] === config.user : regular

        if (match) {
          shellRoot.loginUser = f[0]
          shellRoot.homeDir = f[5]
          break
        }
      }

      shellRoot.wallpaperDir = config.wallpaperDir !== ""
        ? config.wallpaperDir
        : shellRoot.homeDir + "/Pictures/Wallpapers"
      shellRoot.startSession()
      wallpaperScan.running = true
    }
  }

  // Lists wallpapers in wallpaperDir and picks one at random.
  // If the folder is missing, empty or unreadable, wallpaper stays "" and the fallback is used.
  Process {
    id: wallpaperScan

    running: false
    command: {
      const args = ["find", "-L", shellRoot.wallpaperDir, "-maxdepth", "1", "-type", "f", "("]
      config.wallpaperExtensions.forEach((ext, i) => {
        if (i > 0) args.push("-o")
        args.push("-iname", "*." + ext)
      })
      args.push(")")
      return args
    }

    stdout: SplitParser {
      onRead: data => { if (data !== "") shellRoot.wallpaperFiles.push(data) }
    }

    onExited: {
      const files = shellRoot.wallpaperFiles
      if (files.length > 0)
        shellRoot.wallpaper = files[Math.floor(Math.random() * files.length)]
    }
  }

  Process {
    running: true
    command: ["hostname"]

    stdout: SplitParser {
      onRead: data => { if (data !== "") shellRoot.hostname = data.trim() }
    }
  }

  // ── Window ──
  FloatingWindow {
    visible: true
    color: "black"
    title: "greeter"

    Item {
      id: content

      // One unit = 1/225 of the window height (the reference image is 400x225).
      readonly property real u: height / 225 * config.uiScale

      anchors.fill: parent

      NumberAnimation {
        id: fadeOut

        target: content
        property: "opacity"
        to: 0
        duration: config.fadeOutDuration
        easing.type: Easing.OutQuad

        onFinished: Greetd.launch(config.sessionCommand, config.sessionEnvironment)
      }

      // ── Background ──
      AnimatedImage {
        id: background

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        playing: true
        smooth: true
        // Random wallpaper first; fallback if none was found or it failed to load.
        readonly property string path: shellRoot.wallpaper !== "" && !shellRoot.wallpaperFailed
          ? shellRoot.wallpaper
          : shellRoot.fallbackPath

        source: path !== "" ? "file://" + encodeURI(path) : ""

        onStatusChanged: {
          if (status === Image.Error && path === shellRoot.wallpaper)
            shellRoot.wallpaperFailed = true
        }
      }

      Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: config.overlayOpacity
      }

      // ── Clock and date (top left) ──
      Column {
        x: 18 * content.u
        y: 14 * content.u
        spacing: 3 * content.u

        Text {
          color: config.colorText
          font.family: config.fontFamily
          font.letterSpacing: 1 * content.u
          font.pixelSize: 28 * content.u
          font.weight: Font.Bold
          text: Qt.formatDateTime(clock.date, "HH:mm")
        }

        Row {
          spacing: 4 * content.u

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: config.colorText
            height: Math.max(1, 0.4 * content.u)
            opacity: 0.5
            width: 8 * content.u
          }

          Text {
            color: config.colorText
            font.family: config.fontFamily
            font.letterSpacing: 1.5 * content.u
            font.pixelSize: 4.5 * content.u
            opacity: 0.6
            text: Qt.formatDateTime(clock.date, "dddd · MMMM d").toUpperCase()
          }
        }
      }

      // ── Login (right, lower middle) ──
      Item {
        id: loginBox

        anchors.right: parent.right
        anchors.rightMargin: 12 * content.u
        y: 163 * content.u
        width: 84 * content.u
        height: 40 * content.u

        Text {
          anchors.right: parent.right
          color: config.colorText
          font.family: config.fontFamily
          font.letterSpacing: 1 * content.u
          font.pixelSize: 7 * content.u
          font.weight: Font.Bold
          text: shellRoot.loginUser.toUpperCase()
        }

        Item {
          id: passwordBox

          y: 15 * content.u
          width: parent.width
          height: 11 * content.u

          TextInput {
            id: passwordInput

            anchors.fill: parent
            clip: true
            color: config.colorText
            echoMode: shellRoot.echoInput ? TextInput.Normal : TextInput.Password
            enabled: shellRoot.awaitingPassword
            focus: true
            font.family: config.fontFamily
            font.letterSpacing: 1.5 * content.u
            font.pixelSize: 4.5 * content.u
            passwordCharacter: "•"
            selectionColor: config.colorText
            selectedTextColor: "black"
            verticalAlignment: TextInput.AlignVCenter

            Keys.onEscapePressed: text = ""

            onAccepted: {
              shellRoot.submit(text)
              text = ""
            }

            onEnabledChanged: if (enabled) forceActiveFocus()

            Component.onCompleted: forceActiveFocus()

            Text {
              anchors.fill: parent
              color: config.colorText
              font.family: config.fontFamily
              font.letterSpacing: 1.5 * content.u
              font.pixelSize: 4.5 * content.u
              opacity: 0.4
              text: shellRoot.awaitingPassword ? "ENTER PASSWORD" : (shellRoot.leaving ? "" : "PLEASE WAIT")
              verticalAlignment: Text.AlignVCenter
              visible: passwordInput.text === ""
            }
          }

          Rectangle {
            anchors.bottom: parent.bottom
            color: shellRoot.statusIsError ? config.colorError : config.colorText
            height: Math.max(1, 0.5 * content.u)
            opacity: passwordInput.activeFocus || shellRoot.statusIsError ? 0.8 : 0.4
            width: parent.width
          }
        }

        Text {
          anchors.right: parent.right
          color: shellRoot.statusIsError ? config.colorError : config.colorText
          font.family: config.fontFamily
          font.letterSpacing: 1 * content.u
          font.pixelSize: 3.8 * content.u
          opacity: 0.8
          text: shellRoot.status.toUpperCase()
          y: 29 * content.u
        }
      }

      // ── Debug: window size and wallpaper size (config.showInfo) ──
      Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14 * content.u
        anchors.horizontalCenter: parent.horizontalCenter
        color: config.colorText
        font.family: config.fontFamily
        font.pixelSize: 3.8 * content.u
        opacity: 0.6
        text: "window " + Math.round(content.width) + "x" + Math.round(content.height)
          + "  |  image " + background.implicitWidth + "x" + background.implicitHeight
        visible: config.showInfo
      }

      // ── Hostname (bottom left) ──
      Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14 * content.u
        anchors.left: parent.left
        anchors.leftMargin: 18 * content.u
        color: config.colorText
        font.family: config.fontFamily
        font.letterSpacing: 1 * content.u
        font.pixelSize: 3.8 * content.u
        opacity: 0.5
        text: shellRoot.hostname.toUpperCase()
      }

      // ── Power buttons (bottom right) ──
      Row {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14 * content.u
        anchors.right: parent.right
        anchors.rightMargin: 12 * content.u
        spacing: 10 * content.u

        Repeater {
          model: config.powerActions

          delegate: Text {
            id: powerButton

            required property var modelData

            color: config.colorText
            font.family: config.fontFamily
            font.letterSpacing: 1 * content.u
            font.pixelSize: 3.8 * content.u
            opacity: powerArea.containsMouse ? 1 : 0.55
            text: modelData.label.toUpperCase()

            MouseArea {
              id: powerArea

              anchors.fill: parent
              hoverEnabled: true

              onClicked: Quickshell.execDetached(powerButton.modelData.command)
            }
          }
        }
      }
    }
  }
}
