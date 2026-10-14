import QtQuick
import Quickshell

// Greeter settings. Edit values only; shell.qml reads them as `config.<name>`.
// The greeter runs as the `greeter` user, so paths and fonts must be system-wide.
QtObject {
  // ── Login ──
  property string username: "user"                         // Default user shown at startup
  property bool detectUsers: true                          // List regular users (UID 1000+); click the name to cycle
  property string defaultSession: "Mango"                  // Matched against the session Name=
  property string fallbackSessionName: "Mango"             // Used if no session file is found
  property string fallbackSessionCommand: "mango"

  // ── Background ──
  property string wallpaper: "/etc/greetd/greeter/wallpaper.png"  // Absolute path, readable by `greeter`
  property real dim: 0                                     // 0 to 1, black overlay on the wallpaper
  property real shadow: 0.75                                // 0 to 1, darkness at the bottom edge (0 = off)
  property real shadowHeight: 0.5                         // Fraction of the screen height the shadow covers
  property real clockShadow: 0.7                           // 0 to 1, darkness at the top right corner (0 = off)
  property int clockShadowWidth: 700                       // Pixels
  property int clockShadowHeight: 320                      // Pixels
  property color backgroundColor: "#18181b"                // Shown if the wallpaper is missing

  // ── Font ──
  property string fontFamily: "Segoe UI Variable"          // Must be installed system-wide
  property int fontWeight: Font.DemiBold
  property real letterSpacing: 2
  property bool uppercase: true

  // ── Size ──
  property int margin: 64
  property int clockSize: 96
  property int dateSize: 16
  property int labelSize: 18
  property int buttonSize: 13
  property int buttonHeight: 32
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

  // ── Power buttons (bottom right, after the session button) ──
  property var actions: [
    { label: "Restart", command: "systemctl reboot" },
    { label: "Shut Down", command: "systemctl poweroff" }
  ]
}
