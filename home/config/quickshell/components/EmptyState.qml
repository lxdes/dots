import QtQuick

Rectangle {
    property string message: "Nothing here"
    implicitHeight: 76
    color: "transparent"
    border.width: 1
    border.color: "white"
    radius: 10
    DataText {
        anchors.centerIn: parent
        width: parent.width - 24
        text: parent.message
        color: "gray"
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }
}
