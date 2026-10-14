import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland

ShellRoot {
  id: greeter

  Config { id: config }

  property string password: ""
  property bool busy: false
  property bool failed: false
  property var users: []
  property int userIndex: 0
  readonly property string currentUser: users.length > 0 ? users[userIndex] : config.username
  property var sessions: []
  property int sessionIndex: 0
  readonly property string sessionName: sessions.length > 0
    ? sessions[sessionIndex].name
    : config.fallbackSessionName

  function format(text) {
    return config.uppercase ? text.toUpperCase() : text
  }

  function launchCommand() {
    var command = sessions.length > 0
      ? sessions[sessionIndex].command
      : config.fallbackSessionCommand
    return command.split(" ").filter(function (part) { return part !== "" })
  }

  function nextUser(input) {
    if (users.length < 2) return

    userIndex = (userIndex + 1) % users.length
    input.text = ""
    failed = false
  }

  function nextSession() {
    if (sessions.length > 1) sessionIndex = (sessionIndex + 1) % sessions.length
  }

  function submit(input) {
    if (busy || input.text === "") return

    password = input.text
    input.text = ""
    failed = false
    busy = true
    Greetd.createSession(currentUser)
  }

  SystemClock {
    id: greeterClock
    precision: SystemClock.Minutes
  }

  // Reads regular users: one login name per line.
  Process {
    command: ["bash", Quickshell.shellDir + "/list-users.sh"]
    running: config.detectUsers

    stdout: SplitParser {
      onRead: line => {
        if (line === "") return

        var list = greeter.users.slice()
        list.push(line)
        greeter.users = list
      }
    }

    // Start on the default user; add it to the list if it was not detected.
    onExited: {
      var index = greeter.users.indexOf(config.username)
      if (index < 0) {
        var list = greeter.users.slice()
        list.unshift(config.username)
        greeter.users = list
        index = 0
      }
      greeter.userIndex = index
    }
  }

  // Reads installed sessions: one "name<TAB>command" line each.
  Process {
    command: ["bash", Quickshell.shellDir + "/list-sessions.sh"]
    running: true

    stdout: SplitParser {
      onRead: line => {
        var parts = line.split("\t")
        if (parts.length < 2) return

        var list = greeter.sessions.slice()
        list.push({ name: parts[0], command: parts[1] })
        greeter.sessions = list
      }
    }

    onExited: {
      for (var i = 0; i < greeter.sessions.length; i++) {
        if (greeter.sessions[i].name.toLowerCase() === config.defaultSession.toLowerCase()) {
          greeter.sessionIndex = i
          break
        }
      }
    }
  }

  Connections {
    target: Greetd

    function onAuthMessage(message, error, responseRequired, echoResponse) {
      if (responseRequired) {
        Greetd.respond(greeter.password)
        greeter.password = ""
      }
    }

    function onAuthFailure(message) {
      greeter.password = ""
      greeter.busy = false
      greeter.failed = true
    }

    function onReadyToLaunch() {
      Greetd.launch(greeter.launchCommand())
    }

    function onError(error) {
      greeter.password = ""
      greeter.busy = false
      greeter.failed = true
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData

      anchors { top: true; bottom: true; left: true; right: true }
      color: config.backgroundColor
      exclusionMode: ExclusionMode.Ignore
      screen: modelData
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.layer: WlrLayer.Overlay

      Image {
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: "file://" + config.wallpaper
      }

      Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: config.dim
      }

      // Bottom shadow so the login and buttons stay readable
      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height * config.shadowHeight

        gradient: Gradient {
          GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
          GradientStop { position: 1; color: Qt.rgba(0, 0, 0, config.shadow) }
        }
      }

      // Top-right shadow behind the date and clock
      Item {
        id: clockShadow

        anchors { right: parent.right; top: parent.top }
        height: config.clockShadowHeight
        visible: config.clockShadow > 0
        width: config.clockShadowWidth

        layer.enabled: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: clockShadowMask
        }

        Rectangle {
          anchors.fill: parent

          gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, config.clockShadow) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
          }
        }
      }

      // Fades the shadow sideways so only the corner side stays dark
      Item {
        id: clockShadowMask

        height: clockShadow.height
        layer.enabled: true
        visible: false
        width: clockShadow.width

        Rectangle {
          anchors.fill: parent

          gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 1) }
          }
        }
      }

      // ── Top right: date and clock ──
      Column {
        anchors { right: parent.right; top: parent.top; margins: config.margin }
        spacing: 4

        Text {
          anchors.right: parent.right
          color: config.colorDate
          font.family: config.fontFamily
          font.letterSpacing: config.letterSpacing
          font.pixelSize: config.dateSize
          font.weight: config.fontWeight
          text: greeter.format(Qt.formatDateTime(greeterClock.date, config.dateFormat))
        }

        Text {
          anchors.right: parent.right
          color: config.colorText
          font.family: config.fontFamily
          font.pixelSize: config.clockSize
          font.weight: config.fontWeight
          text: Qt.formatTime(greeterClock.date, config.clockFormat)
        }
      }

      // ── Bottom left: username, password, login ──
      Column {
        anchors { left: parent.left; bottom: parent.bottom; margins: config.margin }
        spacing: 12

        // Click to cycle through users (only when more than one exists).
        Text {
          color: userArea.containsMouse && greeter.users.length > 1 ? config.colorAccent : config.colorText
          font.family: config.fontFamily
          font.letterSpacing: config.letterSpacing
          font.pixelSize: config.labelSize
          font.weight: config.fontWeight
          text: greeter.format(greeter.currentUser)

          MouseArea {
            id: userArea

            anchors.fill: parent
            cursorShape: greeter.users.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            hoverEnabled: true

            onClicked: greeter.nextUser(greeterInput)
          }
        }

        Item {
          width: config.inputWidth
          height: config.inputHeight

          TextInput {
            id: greeterInput

            anchors { left: parent.left; right: parent.right; bottom: greeterLine.top; bottomMargin: 4 }
            color: config.colorText
            echoMode: TextInput.Password
            focus: true
            font.family: config.fontFamily
            font.pixelSize: config.labelSize
            readOnly: greeter.busy

            Component.onCompleted: forceActiveFocus()
            onTextChanged: greeter.failed = false
            onAccepted: greeter.submit(greeterInput)
          }

          Rectangle {
            id: greeterLine

            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            color: greeter.failed ? config.colorError : config.colorAccent
            height: 2
          }
        }

        Row {
          spacing: 16

          Rectangle {
            id: loginButton

            border.color: config.colorBorder
            border.width: 2
            color: loginArea.containsMouse ? config.colorAccent : "transparent"
            height: config.buttonHeight
            width: loginText.implicitWidth + 32

            Text {
              id: loginText

              anchors.centerIn: parent
              color: loginArea.containsMouse ? config.colorAccentText : config.colorText
              font.family: config.fontFamily
              font.letterSpacing: config.letterSpacing
              font.pixelSize: config.buttonSize
              font.weight: config.fontWeight
              text: greeter.format(config.loginLabel)
            }

            MouseArea {
              id: loginArea

              anchors.fill: parent
              hoverEnabled: true

              onClicked: greeter.submit(greeterInput)
            }
          }

          Text {
            anchors.verticalCenter: loginButton.verticalCenter
            color: config.colorError
            font.family: config.fontFamily
            font.letterSpacing: config.letterSpacing
            font.pixelSize: config.buttonSize
            font.weight: config.fontWeight
            text: greeter.format(config.errorLabel)
            visible: greeter.failed
          }
        }
      }

      // ── Bottom right: session changer and power buttons ──
      Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: config.margin }
        spacing: 12

        // Click to cycle through installed sessions.
        Rectangle {
          border.color: config.colorBorder
          border.width: 2
          color: sessionArea.containsMouse ? config.colorAccent : "transparent"
          height: config.buttonHeight
          width: sessionText.implicitWidth + 24

          Text {
            id: sessionText

            anchors.centerIn: parent
            color: sessionArea.containsMouse ? config.colorAccentText : config.colorText
            font.family: config.fontFamily
            font.letterSpacing: config.letterSpacing
            font.pixelSize: config.buttonSize
            font.weight: config.fontWeight
            text: greeter.format(greeter.sessionName)
          }

          MouseArea {
            id: sessionArea

            anchors.fill: parent
            hoverEnabled: true

            onClicked: greeter.nextSession()
          }
        }

        Repeater {
          model: config.actions

          Rectangle {
            id: actionButton

            required property var modelData

            border.color: config.colorBorder
            border.width: 2
            color: actionArea.containsMouse ? config.colorAccent : "transparent"
            height: config.buttonHeight
            width: actionText.implicitWidth + 24

            Text {
              id: actionText

              anchors.centerIn: parent
              color: actionArea.containsMouse ? config.colorAccentText : config.colorText
              font.family: config.fontFamily
              font.letterSpacing: config.letterSpacing
              font.pixelSize: config.buttonSize
              font.weight: config.fontWeight
              text: greeter.format(actionButton.modelData.label)
            }

            MouseArea {
              id: actionArea

              anchors.fill: parent
              hoverEnabled: true

              onClicked: Quickshell.execDetached(["sh", "-c", actionButton.modelData.command])
            }
          }
        }
      }
    }
  }
}
