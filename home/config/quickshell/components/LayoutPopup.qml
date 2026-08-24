import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: layoutPopup
    property var root
    property var bar
    visible: false
    anchor.window: bar
    anchor.rect.x: bar.width - 180
    anchor.rect.y: bar.height + 2
    grabFocus: true
    color: "transparent"
    implicitWidth: 180
    implicitHeight: 160

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

            Repeater {
                model: ["tall", "monocle", "tiled"]
                delegate: Button {
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: root.layoutIcon(modelData) + "  " + modelData
                    onClicked: root.applyBspLayout(modelData)
                    contentItem: Text {
                        text: parent.text
                        color: parent.hovered ? root.foreground : root.muted
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                    }
                    background: Rectangle {
                        color: parent.hovered ? "#252536" : "transparent"
                    }
                }
            }
        }
    }
}
