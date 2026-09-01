import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: batteryPopup
    required property var root
    required property var bar
    visible: false
    anchor.window: bar
    anchor.rect.x: Math.max(10, bar.width - batteryPopup.implicitWidth - 10)
    anchor.rect.y: bar.height + 8
    grabFocus: true
    color: "transparent"
    implicitWidth: Math.min(290 * root.menuScale, bar.width - 40)
    implicitHeight: batteryCard.implicitHeight

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: batteryPopup.visible = false
    }

    Rectangle {
        id: batteryCard
        anchors.fill: parent
        color: root.background
        border.width: 1
        border.color: root.settingsOutline
        radius: 12 * root.menuScale
        clip: true
        antialiasing: true
        smooth: true
        implicitHeight: contentColumn.implicitHeight + 32 * root.menuScale

        opacity: batteryPopup.visible ? 1.0 : 0.0
        scale: batteryPopup.visible ? 1.0 : 0.97
        Behavior on opacity {
            enabled: !root.reducedMotion
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            enabled: !root.reducedMotion
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16 * root.menuScale
            spacing: 12 * root.menuScale

            // --- Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * root.menuScale

                Rectangle {
                    implicitWidth: 36 * root.menuScale
                    implicitHeight: 36 * root.menuScale
                    radius: 10 * root.menuScale
                    color: root.settingsRaised
                    border.width: 1
                    border.color: root.settingsOutline

                    Text {
                        anchors.centerIn: parent
                        text: root.batteryStatus === "Charging" ? "󰂄" : root.batteryCapacity <= 15 ? "󰁺" : root.batteryCapacity <= 35 ? "󰁼" : root.batteryCapacity <= 65 ? "󰁾" : "󰂀"
                        color: root.batteryStatus === "Charging" ? "#a6e3a1" : (root.batteryCapacity <= 15 ? "#f38ba8" : root.accent)
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 18 * root.displayFontScale
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.batteryCapacity >= 0 ? root.batteryCapacity + "% Charged" : "No Battery"
                        color: root.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13 * root.displayFontScale
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.batteryTimeRemaining.length > 0 ? root.batteryTimeRemaining : (root.batteryStatus.length > 0 ? root.batteryStatus : "Estimating...")
                        color: root.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                    }
                }
            }

            // --- Progress Gauge ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 8 * root.menuScale
                radius: 4 * root.menuScale
                color: root.settingsSurface
                border.width: 1
                border.color: root.settingsOutline

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 1
                    radius: 3 * root.menuScale
                    width: Math.max(0, Math.min(parent.width - 2, (parent.width - 2) * (Math.max(0, root.batteryCapacity) / 100)))
                    color: root.batteryStatus === "Charging" ? "#a6e3a1" : (root.batteryCapacity <= 15 ? "#f38ba8" : (root.batteryCapacity <= 30 ? "#fab387" : root.accent))

                    Behavior on width {
                        enabled: !root.reducedMotion
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }
                }
            }

            // --- Stats Card ---
            Rectangle {
                Layout.fillWidth: true
                radius: 8 * root.menuScale
                color: root.settingsRaised
                border.width: 1
                border.color: root.settingsOutline
                implicitHeight: statsGrid.implicitHeight + 16 * root.menuScale

                GridLayout {
                    id: statsGrid
                    anchors.fill: parent
                    anchors.margins: 8 * root.menuScale
                    columns: 2
                    rowSpacing: 8 * root.menuScale
                    columnSpacing: 12 * root.menuScale

                    Text {
                        text: "Status"
                        color: root.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                    }
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: root.batteryStatus.length > 0 ? root.batteryStatus : "Unknown"
                        color: root.batteryStatus === "Charging" ? "#a6e3a1" : root.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Power Rate"
                        color: root.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        visible: root.batteryPowerWatts > 0
                    }
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: root.batteryPowerWatts.toFixed(1) + " W"
                        color: root.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        font.weight: Font.DemiBold
                        visible: root.batteryPowerWatts > 0
                    }

                    Text {
                        text: "Battery Health"
                        color: root.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        visible: root.batteryHealth > 0
                    }
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: root.batteryHealth + "%"
                        color: root.batteryHealth >= 80 ? "#a6e3a1" : (root.batteryHealth >= 60 ? "#fab387" : "#f38ba8")
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        font.weight: Font.DemiBold
                        visible: root.batteryHealth > 0
                    }

                    Text {
                        text: "Cycle Count"
                        color: root.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        visible: root.batteryCycleCount >= 0
                    }
                    Text {
                        Layout.alignment: Qt.AlignRight
                        text: root.batteryCycleCount.toString()
                        color: root.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        font.weight: Font.DemiBold
                        visible: root.batteryCycleCount >= 0
                    }
                }
            }

            // --- Power Settings Link Button ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30 * root.menuScale
                radius: 6 * root.menuScale
                color: btnMouse.containsMouse ? root.settingsRaised : "transparent"
                border.width: 1
                border.color: btnMouse.containsMouse ? root.accent : root.settingsOutline

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6 * root.menuScale

                    Text {
                        text: "󰒓"
                        color: root.accent
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 13 * root.displayFontScale
                    }
                    Text {
                        text: "Open Power Settings"
                        color: root.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.displayFontScale
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        batteryPopup.visible = false
                        root.openSettings("Session")
                    }
                }
            }
        }
    }
}
