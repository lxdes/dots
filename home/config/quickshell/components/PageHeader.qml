import QtQuick
import QtQuick.Layouts

ColumnLayout {
    property string title
    property string description
    spacing: 3
    UiText {
        text: parent.title
        font.pixelSize: 22
        font.weight: Font.DemiBold
        wrapMode: Text.Wrap
    }
    DataText {
        Layout.fillWidth: true
        text: parent.description
        color: "gray"
        wrapMode: Text.Wrap
    }
}
