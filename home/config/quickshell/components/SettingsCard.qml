import QtQuick
import QtQuick.Layouts

Rectangle {
    default property alias contents: body.data
    implicitHeight: body.implicitHeight + 28
    color: "white"
    border.width: 1
    border.color: "white"
    radius: 12
    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8
    }
}
