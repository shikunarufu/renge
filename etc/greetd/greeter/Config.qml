import QtQuick
import Quickshell

QtObject {
  // ── Login ──
  property string username: "user"
  property bool detectUsers: true
  property string defaultSession: "Mango"
  property string fallbackSessionName: "Mango"
  property string fallbackSessionCommand: "mango"

  // ── Background ──
  property string wallpaper: "/etc/greetd/greeter/wallpaper.png"
  property real dim: 0
  property real shadow: 0.75
  property real shadowHeight: 0.5
  property real clockShadow: 0.75
  property int clockShadowWidth: 1920
  property int clockShadowHeight: 540
  property color backgroundColor: "#18181b"

  // ── Font ──
  property string fontFamily: "Segoe UI Variable"
  property int fontWeight: Font.DemiBold
  property real letterSpacing: 2
  property bool uppercase: true

  // ── Size ──
  property int margin: 64
  property int spacing: 12
  property int clockSize: 96
  property int dateSize: 16
  property int labelSize: 18
  property int buttonSize: 13
  property int buttonHeight: 32
  property int buttonBorder: 2
  property int buttonPadding: 24
  property int loginPadding: 32
  property int inputWidth: 360
  property int inputHeight: 36

  // ── Text ──
  property string clockFormat: "HH:mm"
  property string dateFormat: "dddd, MMMM d"
  property string loginLabel: "Login"
  property string errorLabel: "Wrong password"

  // ── Color ──
  property color colorText: "#bbc3c4"
  property color colorDate: "#949f7f"
  property color colorAccent: "#949f7f"
  property color colorAccentText: "#0f2430"
  property color colorBorder: Qt.rgba(colorText.r, colorText.g, colorText.b, 0.35)
  property color colorError: "#be1923"

  // ── Power Buttons ──
  property var actions: [
    { label: "Restart", command: "systemctl reboot" },
    { label: "Shut Down", command: "systemctl poweroff" }
  ]
}
