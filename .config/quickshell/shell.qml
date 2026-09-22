import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets

ShellRoot {
    // ==========================================
    // THEME PALETTE: Okinami (Catppuccin Mocha Style)
    // ==========================================
    readonly property var colors: {
        "bg": "#1e1e2e",       // Base background
        "crust": "#11111b",    // Darker contrast sections
        "wave1": "#89b4fa",    // Soft Blue Wave
        "wave2": "#f5c2e7",    // Mauve/Pink Wave
        "text": "#cdd6f4",     // Main text color
        "subtext": "#a6adc8"   // Dimmed text color
    }

    // ==========================================
    // DATA TIMERS (For dynamic updates)
    // ==========================================
    property string currentTime: "00:00 AM"

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            currentTime = new Date().toLocaleTimeString(Qt.locale(), "hh:mm A")
        }
    }

    // ==========================================
    // BAR WINDOW CONFIGURATION
    // ==========================================
    PanelWindow {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        
        // Transparent base allows our custom inner borders/shapes to look flawless
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: colors.bg

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ==========================================
                // LEFT SECTION: Workspaces / Tags
                // ==========================================
                Row {
                    Layout.fillHeight: true
                    spacing: 12
                    leftPadding: 15
                    rightPadding: 15

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "              " 
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pointSize: 11
                        color: colors.text
                    }
                }

                // Flexible Spacer
                Item { Layout.fillWidth: true }

                // ==========================================
                // CENTER SECTION: Clock & Date with Okinami Curve
                // ==========================================
                Rectangle {
                    Layout.fillHeight: true
                    width: 140
                    color: colors.crust
                    clip: false // Allows the wave accent to bleed outward naturally

                    // Left Transition: Smooth Bezier Wave 
                    Shape {
                        width: 16
                        height: parent.height
                        anchors.right: parent.left
                        
                        ShapePath {
                            fillColor: colors.crust
                            strokeColor: "transparent"
                            startX: 16; startY: 0
                            PathCubic {
                                x: 0; y: parent.height
                                control1X: 8; control1Y: 0
                                control2X: 8; control2Y: parent.height
                            }
                            PathLine { x: 16; y: parent.height }
                            PathLine { x: 16; y: 0 }
                        }
                    }

                    // Right Transition: Symmetrical Wave Cap
                    Shape {
                        width: 16
                        height: parent.height
                        anchors.left: parent.right
                        
                        ShapePath {
                            fillColor: colors.crust
                            strokeColor: "transparent"
                            startX: 0; startY: 0
                            PathCubic {
                                x: 16; y: parent.height
                                control1X: 8; control1Y: 0
                                control2X: 8; control2Y: parent.height
                            }
                            PathLine { x: 0; y: parent.height }
                            PathLine { x: 0; y: 0 }
                        }
                    }

                    // Displaying Live Time String
                    Text {
                        anchors.centerIn: parent
                        text: currentTime
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.bold: true
                        font.pointSize: 10
                        color: colors.wave1
                    }
                }

                // Flexible Spacer
                Item { Layout.fillWidth: true }

                // ==========================================
                // RIGHT SECTION: Hard-coded System Status Capsule
                // ==========================================
                Row {
                    Layout.fillHeight: true
                    rightPadding: 0 
                    
                    // Container for system stats
                    Rectangle {
                        height: parent.height
                        width: 180
                        color: colors.wave2

                        // Left entry wave logic for the capsule edge
                        Shape {
                            width: 16
                            height: parent.height
                            anchors.right: parent.left
                            
                            ShapePath {
                                fillColor: colors.wave2
                                strokeColor: "transparent"
                                startX: 16; startY: 0
                                PathCubic {
                                    x: 0; y: parent.height
                                    control1X: 8; control1Y: 0
                                    control2X: 8; control2Y: parent.height
                                }
                                PathLine { x: 16; y: parent.height }
                                PathLine { x: 16; y: 0 }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "   42%     80%     100%"
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.bold: true
                            font.pointSize: 9
                            color: colors.bg // High contrast dark text on bright accent base
                        }
                    }
                }

            }
        }
    }
}
