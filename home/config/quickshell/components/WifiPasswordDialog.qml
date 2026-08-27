import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Window {
    id: dialog

    required property var shellRoot
    property string ssid: ""

    visible: false
    title: "Connect to Wi-Fi"
    flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    modality: Qt.ApplicationModal
    color: "transparent"
    width: shellRoot.primaryScreen() ? Math.min(380, shellRoot.primaryScreen().width - 24) : 380
    height: 190
    x: shellRoot.centerX(width)
    y: shellRoot.centerY(height)

    function openForNetwork(networkName) {
        ssid = networkName
        passwordField.clear()
        passwordField.echoMode = TextInput.Password
        visible = true
        focusTimer.restart()
    }

    Timer {
        id: focusTimer
        interval: 40
        onTriggered: {
            dialog.requestActivate()
            passwordField.forceActiveFocus(Qt.OtherFocusReason)
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: dialog.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: shellRoot.background
        border.width: 1
        border.color: shellRoot.accent
        radius: 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 9

            Text {
                Layout.fillWidth: true
                text: "Join " + dialog.ssid
                color: shellRoot.foreground
                font.family: "Noto Sans"
                font.pixelSize: 15 * shellRoot.menuFontScale
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
            }
            Text {
                Layout.fillWidth: true
                text: "Enter the network password. It will be stored by NetworkManager."
                color: shellRoot.muted
                font.family: "JetBrains Mono"
                font.pixelSize: 8 * shellRoot.menuFontScale
                wrapMode: Text.Wrap
            }
            TextField {
                id: passwordField
                Layout.fillWidth: true
                implicitHeight: 40
                placeholderText: "Password"
                color: shellRoot.foreground
                placeholderTextColor: shellRoot.muted
                selectionColor: shellRoot.highlight
                echoMode: TextInput.Password
                leftPadding: 11
                rightPadding: 40
                Accessible.name: "Wi-Fi password"
                background: Rectangle {
                    color: shellRoot.settingsSurface
                    radius: 8
                    border.width: 1
                    border.color: passwordField.activeFocus ? shellRoot.accent : shellRoot.settingsOutline
                }
                Keys.onReturnPressed: if (connectButton.enabled) connectButton.clicked()
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Button {
                    text: "Cancel"
                    onClicked: dialog.visible = false
                }
                Button {
                    id: connectButton
                    text: shellRoot.networkActionBusy ? "Connecting..." : "Connect"
                    enabled: passwordField.text.length > 0 && !shellRoot.networkActionBusy
                    highlighted: true
                    onClicked: {
                        shellRoot.connectNetworkWithPassword(dialog.ssid, passwordField.text)
                        dialog.visible = false
                    }
                }
            }
        }
    }
}
