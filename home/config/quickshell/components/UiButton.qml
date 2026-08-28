import QtQuick
import QtQuick.Controls

Button {
    id: control
    property bool primary: false
    implicitHeight: 36
    leftPadding: 13
    rightPadding: 13
    contentItem: Text {
        text: control.text
        color: !control.enabled ? "gray"
            : control.primary ? "black" : "white"
        font.family: "JetBrains Mono"
        font.pixelSize: 9
        font.weight: control.primary ? Font.DemiBold : Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 9
        color: !control.enabled ? Qt.rgba(1, 1, 1, 0.35)
            : control.primary ? (control.down ? Qt.darker("blue", 1.12) : "blue")
            : control.down ? Qt.lighter("gray", 1.12)
            : control.hovered ? "gray" : Qt.rgba(1, 1, 1, 0.55)
        border.width: 1
        border.color: control.activeFocus ? "blue" : "white"
    }
}
