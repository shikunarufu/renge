import QtQuick
import Quickshell

// All user settings live here. Edit values only; shell.qml reads them as `config.<name>`.
// Colors are the defaults; with themeFromWallpaper they are replaced after each wallpaper change.
QtObject {
  // ── Animation (milliseconds) ──
  property int animationDuration: 200
  property int colorTransitionDuration: 500

  // ── Theme from wallpaper ──
  property bool themeFromWallpaper: true
  property int themeSampleSize: 48              // Wallpaper is scaled to NxN before reading colors
  property int themePaletteSize: 8              // Number of dominant colors considered
  property real themeBarLightness: 0.10         // 0 = black, 1 = white
  property real themeBarMaxSaturation: 0.3
  property real themeTextLightness: 0.90
  property real themeTextSaturation: 0.15
  property real themeAccentLightness: 0.68
  property real themeAccentMinSaturation: 0.45
  property real themeAccentMaxSaturation: 0.8

  // ── Color ──
  property color colorText: "#e5e7eb"
  property color colorAccent: "#e2a97b"
  property color colorAccentText: "#18181b"
  property color colorInput: Qt.rgba(1, 1, 1, 0.07)  // Launcher search box background

  // ── Font ──
  property string fontFamily: "Segoe UI Variable"
  property int fontSize: 12
  property int fontWeight: Font.DemiBold

  property string iconFontFamily: "JetBrainsMono Nerd Font"
  property int iconSize: 16

  // ── Bar ──
  property color barColor: "#18181b"
  property int barHeight: 35
  property int barItemSpacing: 16
  property int barPadding: 44
  property int barRadius: 22
  property int barSlideDuration: 500

  // ── Power Menu ──
  property int powerMenuWidth: 95
  property int powerMenuMargin: 8
  property int powerMenuRadius: 8
  property int powerMenuPopupRadius: 12
  property string powerMenuIcon: "\udb82\udcc7"
  property var powerMenuActions: [
    { label: "Shut Down", command: "systemctl poweroff" },
    { label: "Restart", command: "systemctl reboot" },
    { label: "Sleep", command: "systemctl suspend" },
    { label: "Lock", command: "loginctl lock-session" },
    { label: "Log Out", command: "loginctl terminate-session self" }
  ]

  // ── Workspace ──
  property int workspaceHeight: 16
  property int workspaceWidth: 16
  property int workspacePadding: 8
  property int workspaceRadius: 4
  property int workspaceSpacing: 8

  // ── App Launcher ──
  property int appLauncherWidth: 360
  property int appLauncherMaxVisible: 7
  property int appLauncherItemHeight: 42
  property string appLauncherIcon: "\uf002"

  // ── Layouts (order used when clicking the layout button) ──
  property var layoutCycle: ["tile", "monocle", "grid", "scroller"]

  // ── Focus Window ──
  property string focusWindowGlyph: "\uf2d0"

  // ── App Icon ──
  property var focusWindowIcons: ({
    "foot": "\uf489",
    "zen": "\udb83\ude95"
  })

  // ── Window Title ──
  property string focusWindowPlaceholder: "Desktop"
  property var focusWindowNames: ({
    "foot": "Foot",
    "zen": "Zen"
  })

  // ── Wallpaper ──
  property string wallpaperIcon: "\udb80\udeeb"
  property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
  property var wallpaperFormats: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
  property bool wallpaperRandomOnStart: true

  // ── Volume ──
  property real volumeStep: 0.05
  property string volumeIconHigh: "\uf028"
  property string volumeIconLow: "\uf027"
  property string volumeIconMuted: "\ueee8"

  // ── System Tray ──
  property int trayIconSize: 16
  property int trayIconSpacing: 8
  property int trayPopupMargin: 6
  property int trayPopupPadding: 10
  property int trayPopupRadius: 12
  property string trayIconCollapse: "\uf0d8"
  property string trayIconExpand: "\uf0d7"

  // ── Network ──
  property int networkPollInterval: 3000
  property real networkDisconnectedOpacity: 0.5
  property string networkIconEthernet: "\uef44"
  property string networkIconWifi: "\uf1eb"

  // ── Notifications ──
  property int notificationWidth: 360
  property int notificationMargin: 8
  // Distance from the bar: clears the tray popup (margin + height) plus a gap.
  property int notificationTop: trayPopupMargin + trayIconSize + trayPopupPadding * 2 + notificationMargin
  property int notificationSpacing: 8
  property int notificationPadding: 12
  property int notificationRadius: 12
  property int notificationRadiusButton: 8
  property int notificationIconSize: 32
  property int notificationMax: 1
  property int notificationTimeout: 5000
  property int notificationSlideDuration: 500

  // ── Now Playing ──
  property int nowPlayingMaxLength: 45
  property string nowPlayingSeparator: " - "

  // ── Visualizer ──
  property int visualizerBars: 10
  property int visualizerBarGap: 4
  property int visualizerBarWidth: 2
  property int visualizerFramerate: 60
  property int visualizerHeight: 12
  property int visualizerMaxFreq: 10000
  property int visualizerMinFreq: 20

  // ── Color transitions ──
  Behavior on barColor { ColorAnimation { duration: colorTransitionDuration } }
  Behavior on colorAccent { ColorAnimation { duration: colorTransitionDuration } }
  Behavior on colorAccentText { ColorAnimation { duration: colorTransitionDuration } }
  Behavior on colorText { ColorAnimation { duration: colorTransitionDuration } }
}
