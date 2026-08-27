import QtQuick
import QtQuick.Controls

Button {
    id: control

    property color foregroundColor: "white"
    property color mutedColor: "#777777"
    property color accentColor: "#aaaaaa"
    property color hoverColor: "#222222"
    property bool accent: false
    property real scaleFactor: 1

    implicitWidth: 32 * scaleFactor
    implicitHeight: 32 * scaleFactor
    padding: 0

    contentItem: Text {
        text: control.text
        color: !control.enabled ? control.mutedColor : (control.accent ? control.accentColor : control.foregroundColor)
        font.family: "JetBrains Mono"
        font.pixelSize: 15 * control.scaleFactor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: 7 * control.scaleFactor
        color: control.down ? Qt.lighter(control.hoverColor, 1.12) : (control.hovered || control.activeFocus ? control.hoverColor : "transparent")
        border.width: control.activeFocus ? 1 : 0
        border.color: control.accentColor
    }
}
