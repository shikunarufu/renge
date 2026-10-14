// shell.qml — greetd login screen.
//
// Settings: edit Config.qml (same folder). This file only holds the layout and logic.

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Wayland

ShellRoot {
  id: greeter

  property string password: ""
  property bool busy: false
  property bool failed: false
  property var users: []
  property int userIndex: 0
  property var sessions: []
  property int sessionIndex: 0
  readonly property string currentUser: users.length > 0 ? users[userIndex] : config.username
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
    return command.split(" ").filter(part => part !== "")
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

  // ── Components ──

  // Quarter-ellipse shadow in the top right corner, shadowWidth x shadowHeight pixels.
  // The gradient is drawn on a square, then squashed to the requested height.
  component CornerShadow: Shape {
    id: shadow

    property real strength: 0       // 0 to 1; 0 hides it
    property real shadowWidth: 1920
    property real shadowHeight: 540

    anchors.right: parent.right
    anchors.top: parent.top
    height: width
    visible: strength > 0
    width: Math.max(1, shadowWidth)

    transform: Scale {
      yScale: shadow.shadowHeight / shadow.width
    }

    ShapePath {
      startX: 0
      startY: 0
      strokeColor: "transparent"

      fillGradient: RadialGradient {
        centerRadius: shadow.width
        centerX: shadow.width
        centerY: 0
        focalX: shadow.width
        focalY: 0

        GradientStop { position: 0; color: Qt.rgba(0, 0, 0, shadow.strength) }
        GradientStop { position: 0.125; color: Qt.rgba(0, 0, 0, shadow.strength * 0.765625) }
        GradientStop { position: 0.25; color: Qt.rgba(0, 0, 0, shadow.strength * 0.5625) }
        GradientStop { position: 0.375; color: Qt.rgba(0, 0, 0, shadow.strength * 0.390625) }
        GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, shadow.strength * 0.25) }
        GradientStop { position: 0.625; color: Qt.rgba(0, 0, 0, shadow.strength * 0.140625) }
        GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, shadow.strength * 0.0625) }
        GradientStop { position: 0.875; color: Qt.rgba(0, 0, 0, shadow.strength * 0.015625) }
        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
      }

      PathLine { x: shadow.width; y: 0 }
      PathLine { x: shadow.width; y: shadow.height }
      PathLine { x: 0; y: shadow.height }
      PathLine { x: 0; y: 0 }
    }
  }

  // Outlined button that fills with the accent color on hover.
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

  Config { id: config }

  // Look shared by every button.
  QtObject {
    id: buttonStyle

    readonly property color borderColor: config.colorBorder
    readonly property int borderWidth: config.buttonBorder
    readonly property int buttonHeight: config.buttonHeight
    readonly property string fontFamily: config.fontFamily
    readonly property int fontSize: config.buttonSize
    readonly property int fontWeight: config.fontWeight
    readonly property color hoverColor: config.colorAccent
    readonly property color hoverTextColor: config.colorAccentText
    readonly property real letterSpacing: config.letterSpacing
    readonly property color textColor: config.colorText
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
        if (line !== "") greeter.users = greeter.users.concat([line])
      }
    }

    // Start on the default user; add it to the list if it was not detected.
    onExited: {
      var index = greeter.users.indexOf(config.username)
      if (index < 0) {
        greeter.users = [config.username].concat(greeter.users)
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

        greeter.sessions = greeter.sessions.concat([{ name: parts[0], command: parts[1] }])
      }
    }

    onExited: {
      var wanted = config.defaultSession.toLowerCase()
      for (var i = 0; i < greeter.sessions.length; i++) {
        if (greeter.sessions[i].name.toLowerCase() === wanted) {
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

      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.layer: WlrLayer.Overlay
      anchors { top: true; bottom: true; left: true; right: true }
      color: config.backgroundColor
      exclusionMode: ExclusionMode.Ignore
      screen: modelData

      // Decoded at screen size instead of the file's full size.
      Image {
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: "file://" + config.wallpaper
        sourceSize: Qt.size(modelData.width, modelData.height)
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
      CornerShadow {
        shadowHeight: config.clockShadowHeight
        shadowWidth: config.clockShadowWidth
        strength: config.clockShadow
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
        spacing: config.spacing

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
          height: config.inputHeight
          width: config.inputWidth

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
            onAccepted: greeter.submit(greeterInput)
            onTextChanged: greeter.failed = false
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

          OutlineButton {
            id: loginButton

            horizontalPadding: config.loginPadding
            label: greeter.format(config.loginLabel)
            style: buttonStyle

            onClicked: greeter.submit(greeterInput)
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
        spacing: config.spacing

        // Click to cycle through installed sessions.
        OutlineButton {
          horizontalPadding: config.buttonPadding
          label: greeter.format(greeter.sessionName)
          style: buttonStyle

          onClicked: greeter.nextSession()
        }

        Repeater {
          model: config.actions

          delegate: OutlineButton {
            required property var modelData

            horizontalPadding: config.buttonPadding
            label: greeter.format(modelData.label)
            style: buttonStyle

            onClicked: Quickshell.execDetached(["sh", "-c", modelData.command])
          }
        }
      }
    }
  }
}
