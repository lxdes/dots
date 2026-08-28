import QtQuick
import QtQuick.Controls

Switch {
    id: control
    implicitWidth: 46
    implicitHeight: 32
    indicator: Rectangle {
        x: control.width - width
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 42
        implicitHeight: 24
        radius: 12
        color: control.checked ? "blue" : "white"
        border.width: control.activeFocus ? 1 : 0
        border.color: "white"
        Rectangle {
            x: control.checked ? parent.width - width - 4 : 4
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: control.checked ? "black" : "gray"
            Behavior on x { enabled: true; NumberAnimation { duration: 110 } }
        }
    }
    contentItem: Item {}
}
