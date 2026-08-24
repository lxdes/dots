import QtQuick
import Quickshell
import Quickshell.Io

Window {
    id: picker
    property var root
    visible: false
    title: "Color Picker"
    x: root.primaryScreen() ? root.primaryScreen().x : 0
    y: root.primaryScreen() ? root.primaryScreen().y : 0
    width: root.primaryScreen() ? root.primaryScreen().width : Screen.width
    height: root.primaryScreen() ? root.primaryScreen().height : Screen.height
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    property string colorHex: root.background
    property bool captureReady: false

    onVisibleChanged: {
        if (visible) {
            requestActivate()
            captureReady = false
            screenCapture.running = true
        }
    }
    Keys.onEscapePressed: visible = false

    Process {
        id: screenCapture
        command: ["maim", "-u", "/tmp/quickshell-color-picker.png"]
        onExited: captureReady = true
    }

    Process {
        id: colorSample
        command: ["convert", "/tmp/quickshell-color-picker.png", "-crop", "1x1+0+0", "-format", "#%[hex:p{0,0}]", "info:"]
        stdout: StdioCollector {
            id: colorSampleOutput
            onStreamFinished: {
                const value = colorSampleOutput.text.trim()
                if (value.length > 0)
                    colorHex = value
            }
        }
    }

    function sampleColor(x, y) {
        if (!captureReady || colorSample.running)
            return
        colorSample.command = ["convert", "/tmp/quickshell-color-picker.png", "-crop", "1x1+" + Math.round(x) + "+" + Math.round(y), "-format", "#%[hex:p{0,0}]", "info:"]
        colorSample.running = true
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 24
        width: colorLabel.implicitWidth + 28
        height: 36
        color: root.background
        border.width: 1
        border.color: root.foreground
        radius: 8
        Text {
            id: colorLabel
            anchors.centerIn: parent
            text: colorHex
            color: root.foreground
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onPositionChanged: event => picker.sampleColor(event.x, event.y)
        onClicked: {
            root.run(["sh", "-c", "printf '%s' '" + colorHex + "' | xclip -selection clipboard; notify-send 'Color copied' '" + colorHex + "'"])
            picker.visible = false
        }
    }
}
