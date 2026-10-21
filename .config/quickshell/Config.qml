import QtQuick
import Quickshell

QtObject {
  // ── Performance ──
  property bool visualizerEnabled: true
  property bool networkEnabled: true
  property bool inputMethodEnabled: true
  property int inputMethodPollInterval: 500
  
  // ── Animation ──
  property int animationDuration: 200
  property int colorTransitionDuration: 500
  
  // ── Theme ──
  property bool themeFromWallpaper: true
  property int themeSampleSize: 48
  property int themePaletteSize: 8
  property real themeBarLightness: 0.1
  property real themeBarMaxSaturation: 0.3
  property real themeTextLightness: 0.9
  property real themeTextSaturation: 0.15
  property real themeAccentLightness: 0.68
  property real themeAccentMinSaturation: 0.45
  property real themeAccentMaxSaturation: 0.8
  
  // ── Color ──
  property color colorText: "#e5e7eb"
  property color colorAccent: "#e2a97b"
  property color colorAccentText: "#18181b"
  property color colorInput: Qt.rgba(1, 1, 1, 0.07)
  
  // ── Font ──
  property string fontFamily: "Segoe UI Variable"
  property int fontSize: 12
  property int fontWeight: Font.Bold
  property string iconFontFamily: "JetBrainsMono Nerd Font"
  property int iconSize: 16
  
  // ── Bar ──
  property color barColor: "#18181b"
  property int barHeight: 35
  property int barItemSpacing: 16
  property int barPadding: 44
  property int barRadius: 22
  property int barSlideDuration: 500
  property string barClockFormat: "ddd, d MMM   HH:mm"
  property var cornerHiddenLayouts: ["S"]
  
  // ── Power Menu ──
  property int powerMenuWidth: 95
  property int powerMenuMargin: 8
  property int powerMenuPadding: 8
  property int powerMenuSpacing: 2
  property int powerMenuItemHeight: 28
  property int powerMenuRadius: 8
  property int powerMenuPopupRadius: 12
  property string powerMenuIcon: "\udb82\udcc7"
  property var powerMenuActions: [{
    "label": "Shut Down",
    "command": "systemctl poweroff"
  }, {
    "label": "Restart",
    "command": "systemctl reboot"
  }, {
    "label": "Sleep",
    "command": "systemctl suspend"
  }, {
    "label": "Lock",
    "command": "qs ipc call lock lock"
  }, {
    "label": "Log Out",
    "command": "loginctl terminate-session self"
  }]
  
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
  property int appLauncherPadding: 8
  property int appLauncherSearchHeight: 32
  property int appLauncherIconSize: 24
  property int appLauncherRecentMax: 12
  property string appLauncherIcon: "\uf002"
  property string appLauncherPlaceholder: "Search"
  property string appLauncherEmpty: "No apps found"
  property var appLauncherTerminal: ["foot", "-e"]
  
  // ── Layout ──
  property var layoutCycle: ["tile", "monocle", "grid", "scroller"]
  
  // ── Focus Window ──
  property string focusWindowGlyph: "\uf2d0"
  
  // ── App Icon ──
  property var focusWindowIcons: ({
    "anki": "\uf005",
    "broken": "\uf1b6",
    "com.github.wwmm.easyeffects": "\ue690",
    "com.obsproject.studio": "\ueba7",
    "foot": "\uf489",
    "goverlay": "\ueea8",
    "heroic": "\udb86\udcbe",
    "io.github.ilya_zlobintsev.lact": "\udb82\udcae",
    "org.openrgb.openrgb": "\uf400",
    "org.qbittorrent.qbittorrent": "\udb83\udc1c",
    "puddletag": "\udb80\udd5f",
    "steam": "\uf1b6",
    "thunar": "\uf07b",
    "thunar-volman-settings": "\udb81\udd53",
    "zen": "\udb83\ude95"
  })
  
  // ── Window Title ──
  property string focusWindowPlaceholder: "Desktop"
  property var focusWindowNames: ({
    "anki": "Anki",
    "broken": "Steam",
    "com.github.wwmm.easyeffects": "Easy Effects",
    "com.obsproject.studio": "OBS Studio",
    "foot": "Foot",
    "goverlay": "Goverlay",
    "heroic": "Heroic",
    "io.github.ilya_zlobintsev.lact": "LACT",
    "org.openrgb.openrgb": "OpenRGB",
    "org.qbittorrent.qbittorrent": "qBittorrent",
    "puddletag": "Puddletag",
    "steam": "Steam",
    "thunar": "Thunar",
    "thunar-volman-settings": "Removable Drives and Media",
    "xdg-desktop-portal-gtk": "XDG Desktop Portal",
    "zen": "Zen",
    "zenity": "Zenity"
  })
  
  // ── Wallpaper ──
  property string wallpaperIcon: "\udb80\udeeb"
  property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
  property var wallpaperFormats: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
  property bool wallpaperRandomOnStart: true
  property color wallpaperFallbackColor: "#18181b"
  
  // ── Volume ──
  property real volumeStep: 0.05
  property string volumeIconHigh: "\uf028"
  property string volumeIconLow: "\uf027"
  property string volumeIconMuted: "\ueee8"
  
  // ── System Tray ──
  property int trayIconSize: 16
  property int trayIconSpacing: 8
  property int trayPopupMargin: powerMenuMargin
  property int trayPopupPadding: 10
  property int trayPopupRadius: 12
  property int trayPopupExtent: trayPopupMargin + trayIconSize + trayPopupPadding * 2
  property string trayIconCollapse: "\uf0d8"
  property string trayIconExpand: "\uf0d7"
  
  // ── Network ──
  property int networkPollInterval: 3000
  property real networkDisconnectedOpacity: 0.5
  property string networkIconEthernet: "\uef44"
  property string networkIconWifi: "\uf1eb"
  property var networkCommand: ["foot", "-e", "nmtui"]
  
  // ── Input Method ──
  property string inputMethodLatin: "keyboard-us"
  property string inputMethodJapanese: "mozc"
  property string inputMethodLabelLatin: "en"
  property string inputMethodLabelJapanese: "jp"
  
  // ── Notification ──
  property int notificationWidth: 360
  property int notificationMargin: 8
  property int notificationSpacing: 8
  property int notificationPadding: 12
  property int notificationRadius: 12
  property int notificationRadiusButton: 14
  property int notificationButtonHeight: 28
  property int notificationIconSize: 32
  property int notificationMax: 1
  property int notificationTimeout: 5000
  property int notificationSlideDuration: 500
  
  // ── Now Playing ──
  property int nowPlayingMaxLength: 45
  property string nowPlayingSeparator: "   ·   "
  
  // ── Visualizer ──
  property int visualizerBars: 10
  property int visualizerBarGap: 4
  property int visualizerBarWidth: 2
  property int visualizerFramerate: 30
  property int visualizerHeight: 12
  property int visualizerMaxFreq: 10000
  property int visualizerMinFreq: 20
  
  // ── Lock Screen ──
  property string lockWallpaper: ""
  property real lockDim: 0
  property string lockFontFamily: fontFamily
  property int lockFontWeight: fontWeight
  property real lockLetterSpacing: 2
  property bool lockUppercase: true
  property int lockMargin: 64
  property int lockSpacing: 12
  property int lockClockSize: 96
  property int lockDateSize: 16
  property int lockLabelSize: 18
  property int lockButtonSize: 13
  property int lockButtonHeight: 32
  property int lockButtonBorder: 2
  property int lockButtonPadding: 24
  property int lockLoginPadding: 32
  property int lockInputWidth: 360
  property int lockInputHeight: 36
  property real lockShadow: 0.75
  property real lockShadowHeight: 0.5
  property real lockClockShadow: 0.75
  property int lockClockShadowWidth: 1920
  property int lockClockShadowHeight: 540
  property real lockPlayingShadow: 0.75
  property int lockPlayingShadowWidth: 1920
  property int lockPlayingShadowHeight: 540
  property string lockClockFormat: "HH:mm"
  property string lockDateFormat: "dddd, MMMM d"
  property string lockUsername: Quickshell.env("USER")
  property string lockLoginLabel: "Login"
  property string lockErrorLabel: "Wrong password"
  property color lockColorText: colorText
  property color lockColorDate: colorAccent
  property color lockColorAccent: colorAccent
  property color lockColorAccentText: colorAccentText
  property color lockColorBorder: Qt.rgba(colorText.r, colorText.g, colorText.b, 0.35)
  property color lockColorError: "#f38ba8"
  property var lockActions: [{
    "label": "Sleep",
    "command": "systemctl suspend"
  }, {
    "label": "Restart",
    "command": "systemctl reboot"
  }, {
    "label": "Shut Down",
    "command": "systemctl poweroff"
  }]
  
  // ── Color Animation ──
  Behavior on barColor {
    ColorAnimation {
      duration: colorTransitionDuration
    }
  }
  
  Behavior on colorAccent {
    ColorAnimation {
      duration: colorTransitionDuration
    }
  }
  
  Behavior on colorAccentText {
    ColorAnimation {
      duration: colorTransitionDuration
    }
  }
  
  Behavior on colorText {
    ColorAnimation {
      duration: colorTransitionDuration
    }
  }
}
