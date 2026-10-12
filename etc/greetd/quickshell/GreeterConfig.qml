import QtQuick

// All greeter settings. Edit values only; greeter.qml reads them as `config.<name>`.
QtObject {
  // ── Login ──
  property string user: ""                           // "" = first regular account (UID 1000-59999)
  property var sessionCommand: ["mango"]             // Command greetd starts after login
  property var sessionEnvironment: []                // Extra "KEY=value" strings

  // ── Look ──
  property string wallpaperDir: ""                   // "" = <home of user>/Pictures/Wallpapers; else absolute path
  property var wallpaperExtensions: ["gif", "png", "jpg", "jpeg", "webp"]
  property string background: "lockscreen.png"           // Fallback: file name inside wallpaperDir, or absolute path; "" = none
  property real overlayOpacity: 0.25                 // Black layer over the background
  property real uiScale: 1.0                         // 1.0 matches the reference layout
  property bool showInfo: false                      // Show window and wallpaper size at the bottom (debug)
  property string fontFamily: "JetBrainsMono Nerd Font"
  property color colorText: "#e5e7eb"
  property color colorError: "#e06c75"

  // ── Timing (milliseconds) ──
  property int fadeOutDuration: 300                  // Fade before launching the session
  property int retryDelay: 800                       // Wait before a new login attempt

  // ── Power buttons (bottom right) ──
  property var powerActions: [
    { label: "Restart", command: ["systemctl", "reboot"] },
    { label: "Shut Down", command: ["systemctl", "poweroff"] }
  ]
}
