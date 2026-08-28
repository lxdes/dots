import QtQuick
import QtQuick.Controls

ComboBox {
    id: control
    implicitHeight: 36
    implicitWidth: 180
    leftPadding: 12
    rightPadding: 32
    contentItem: DataText {
        text: control.displayText
        color: "white"
        elide: Text.ElideRight
    }
    indicator: DataText {
        x: control.width - width - 11
        anchors.verticalCenter: parent.verticalCenter
        text: "󰅀"
        color: "blue"
        font.pixelSize: 12
    }
    background: Rectangle {
        radius: 9
        color: control.hovered ? "gray" : "white"
        border.width: 1
        border.color: control.activeFocus ? "blue" : "white"
    }
    delegate: ItemDelegate {
        required property var modelData
        width: control.width
        height: 34
        contentItem: DataText {
            text: control.textRole ? modelData[control.textRole] : modelData
            color: highlighted ? "black" : "white"
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: highlighted ? "blue" : (hovered ? "gray" : "white")
        }
    }
    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, 260)
        padding: 4
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle {
            color: "white"
            border.width: 1
            border.color: "white"
            radius: 9
        }
        closePolicy: Popup.CloseOnPressOutside
    }
}
