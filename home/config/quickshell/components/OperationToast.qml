import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: toast

    required property var shellRoot
    required property var barWindow

    visible: shellRoot.operationErrorMessage.length > 0
    anchor.window: barWindow
    anchor.rect.x: barWindow.width - implicitWidth - 12
    anchor.rect.y: barWindow.height + 12
    color: "transparent"
    implicitWidth: Math.min(380, barWindow.width - 24)
    implicitHeight: content.implicitHeight + 24

    Connections {
        target: shellRoot
        function onOperationErrorMessageChanged() {
            if (shellRoot.operationErrorMessage.length > 0)
                dismissTimer.restart()
        }
    }

    Timer {
        id: dismissTimer
        interval: 6000
        onTriggered: shellRoot.operationErrorMessage = ""
    }

    Rectangle {
        anchors.fill: parent
        color: shellRoot.background
        border.width: 1
        border.color: "#f38ba8"
        radius: 8

        RowLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: "󰅚"
                color: "#f38ba8"
                font.family: "JetBrains Mono"
                font.pixelSize: 18
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: shellRoot.operationErrorTitle
                    color: shellRoot.foreground
                    font.family: "Noto Sans"
                    font.pixelSize: 11 * shellRoot.uiFontScale
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: shellRoot.operationErrorMessage
                    color: shellRoot.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8 * shellRoot.uiFontScale
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
            PopupIconButton {
                scaleFactor: shellRoot.menuScale
                text: "×"
                foregroundColor: shellRoot.foreground
                mutedColor: shellRoot.muted
                accentColor: "#f38ba8"
                hoverColor: shellRoot.settingsRaised
                Accessible.name: "Dismiss error"
                onClicked: shellRoot.operationErrorMessage = ""
            }
        }
    }
}
