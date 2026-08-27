import QtQuick
import QtQuick.Controls

Slider {
    id: control

    property color trackColor: "#333333"
    property color accentColor: "#aaaaaa"
    property color handleColor: "white"
    property color surfaceColor: "#111111"
    property real scaleFactor: 1

    implicitHeight: 32 * scaleFactor
    stepSize: 0.01
    snapMode: Slider.NoSnap

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 5 * control.scaleFactor
        radius: 3
        color: control.trackColor

        Rectangle {
            width: parent.width * control.visualPosition
            height: parent.height
            radius: parent.radius
            color: control.enabled ? control.accentColor : control.trackColor
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 18 * control.scaleFactor
        implicitHeight: 18 * control.scaleFactor
        radius: 9 * control.scaleFactor
        color: control.pressed ? control.accentColor : control.handleColor
        border.width: 3
        border.color: control.activeFocus ? control.handleColor : control.accentColor
    }
}
