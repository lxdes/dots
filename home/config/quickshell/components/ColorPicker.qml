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
    property string errorMessage: ""
    property real pendingX: 0
    property real pendingY: 0
    readonly property string capturePath: {
        const runtimeDirectory = String(Quickshell.env("XDG_RUNTIME_DIR") || "")
        const directory = runtimeDirectory.length > 0 ? runtimeDirectory : String(Quickshell.env("HOME")) + "/.cache"
        return directory + "/quickshell-color-picker-" + Quickshell.processId + ".png"
    }

    onVisibleChanged: {
        if (visible) {
            requestActivate()
            captureReady = false
            errorMessage = "Capturing screen..."
            screenCapture.command = ["maim", "-u", "-g", width + "x" + height + (x >= 0 ? "+" : "") + x + (y >= 0 ? "+" : "") + y, capturePath]
            screenCapture.running = true
        } else {
            screenCapture.running = false
            colorSample.running = false
            clickSample.running = false
            sampleTimer.stop()
            root.run(["rm", "-f", capturePath])
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: picker.visible = false
    }

    Process {
        id: screenCapture
        command: ["maim", "-u", picker.capturePath]
        stderr: StdioCollector { id: captureError }
        onExited: (exitCode, exitStatus) => {
            captureReady = exitCode === 0
            errorMessage = exitCode === 0 ? "" : (captureError.text.trim() || "Screen capture failed")
        }
    }

    Process {
        id: colorSample
        command: ["convert", picker.capturePath, "-crop", "1x1+0+0", "-format", "#%[hex:p{0,0}]", "info:"]
        stdout: StdioCollector {
            id: colorSampleOutput
            onStreamFinished: {
                const value = colorSampleOutput.text.trim()
                if (/^#[0-9a-fA-F]{6,8}$/.test(value)) {
                    colorHex = value
                    errorMessage = ""
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                picker.errorMessage = "Unable to sample this pixel"
        }
    }

    Process {
        id: clickSample
        stdout: StdioCollector {
            id: clickSampleOutput
            onStreamFinished: {
                const value = clickSampleOutput.text.trim()
                if (!/^#[0-9a-fA-F]{6,8}$/.test(value)) {
                    picker.errorMessage = "Unable to sample this pixel"
                    return
                }
                picker.colorHex = value
                picker.root.run(["sh", "-c", "printf '%s' \"$1\" | xclip -selection clipboard && notify-send 'Color copied' \"$1\"", "quickshell-color", value])
                picker.visible = false
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                picker.errorMessage = "Unable to copy this pixel"
        }
    }

    Timer {
        id: sampleTimer
        interval: 75
        repeat: false
        onTriggered: picker.sampleColor(picker.pendingX, picker.pendingY)
    }

    function sampleColor(x, y) {
        if (!captureReady || colorSample.running)
            return
        colorSample.command = ["convert", capturePath, "-crop", "1x1+" + Math.round(x) + "+" + Math.round(y), "-format", "#%[hex:p{0,0}]", "info:"]
        colorSample.running = true
    }

    function queueSample(x, y) {
        pendingX = Math.max(0, Math.min(width - 1, Math.round(x)))
        pendingY = Math.max(0, Math.min(height - 1, Math.round(y)))
        sampleTimer.restart()
    }

    function copyPixel(x, y) {
        if (!captureReady || clickSample.running)
            return
        const sampleX = Math.max(0, Math.min(width - 1, Math.round(x)))
        const sampleY = Math.max(0, Math.min(height - 1, Math.round(y)))
        clickSample.command = ["convert", capturePath, "-crop", "1x1+" + sampleX + "+" + sampleY, "-format", "#%[hex:p{0,0}]", "info:"]
        clickSample.running = true
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
            text: errorMessage || colorHex
            color: root.foreground
            font.family: "JetBrains Mono"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        enabled: picker.captureReady
        onPositionChanged: event => picker.queueSample(event.x, event.y)
        onClicked: event => picker.copyPixel(event.x, event.y)
    }
}
