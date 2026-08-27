import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    property color foregroundColor: "white"
    property color mutedColor: "#777777"
    property color accentColor: "#aaaaaa"
    property color surfaceColor: "#181818"
    property color raisedColor: "#242424"
    property color outlineColor: "#383838"
    property real scaleFactor: 1

    implicitHeight: 36 * scaleFactor
    leftPadding: 11 * scaleFactor
    rightPadding: 30 * scaleFactor

    contentItem: Text {
        text: control.displayText
        color: control.enabled ? control.foregroundColor : control.mutedColor
        font.family: "JetBrains Mono"
        font.pixelSize: 9 * control.scaleFactor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: control.width - width - 10 * control.scaleFactor
        anchors.verticalCenter: parent.verticalCenter
        text: "󰅀"
        color: control.enabled ? control.accentColor : control.mutedColor
        font.family: "JetBrains Mono"
        font.pixelSize: 12 * control.scaleFactor
    }

    background: Rectangle {
        radius: 8 * control.scaleFactor
        color: control.hovered ? control.raisedColor : control.surfaceColor
        border.width: 1
        border.color: control.activeFocus ? control.accentColor : control.outlineColor
    }

    delegate: ItemDelegate {
        required property var modelData
        width: control.width
        height: 34 * control.scaleFactor
        contentItem: Text {
            text: control.textRole ? modelData[control.textRole] : modelData
            color: highlighted ? control.surfaceColor : control.foregroundColor
            font.family: "JetBrains Mono"
            font.pixelSize: 9 * control.scaleFactor
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: highlighted ? control.accentColor : (hovered ? control.raisedColor : control.surfaceColor)
        }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8 * control.scaleFactor, 220 * control.scaleFactor)
        padding: 4 * control.scaleFactor
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle {
            color: control.surfaceColor
            border.width: 1
            border.color: control.outlineColor
            radius: 8 * control.scaleFactor
        }
    }
}
