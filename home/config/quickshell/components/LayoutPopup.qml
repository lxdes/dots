import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: layoutPopup
    required property var root
    required property var bar
    visible: false
    anchor.window: bar
    anchor.rect.x: Math.max(0, bar.width - implicitWidth)
    anchor.rect.y: bar.height + 2
    grabFocus: true
    color: "transparent"
    implicitWidth: Math.min(180, bar.width)
    implicitHeight: 160

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: layoutPopup.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: root.background
        border.width: 1
        border.color: "#373b41"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: root.layoutIcon(root.bspLayout) + "  Layout  •  " + root.bspLayout
                color: root.accent
                font.family: "JetBrains Mono"
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                visible: root.layoutActionError.length > 0
                Layout.fillWidth: true
                text: root.layoutActionError
                color: "#f38ba8"
                wrapMode: Text.Wrap
                font.family: "JetBrains Mono"
                font.pixelSize: 9
            }

            Repeater {
                model: ["tall", "monocle", "tiled"]
                delegate: Button {
                    id: layoutButton
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: 30
                    enabled: !root.layoutActionBusy
                    text: root.layoutIcon(modelData) + "  " + modelData
                    onClicked: root.applyBspLayout(modelData)
                    contentItem: Text {
                        text: layoutButton.text
                        color: layoutButton.hovered ? root.foreground : root.muted
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                    }
                    background: Rectangle {
                        color: layoutButton.hovered ? "#252536" : "transparent"
                    }
                }
            }
        }
    }
}
