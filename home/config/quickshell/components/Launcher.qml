import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Window {
    id: launcher
    property var root
    visible: false
    title: "Launcher"
    x: root.centerX(width)
    y: root.centerY(height)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    width: 640 * root.menuScale
    height: 560 * root.menuScale

    onVisibleChanged: if (visible) focusTimer.restart()
    onActiveChanged: {
        if (active) {
            dismissTimer.stop()
            focusTimer.restart()
        } else if (visible) {
            dismissTimer.restart()
        }
    }

    function activateLauncher() {
        requestActivate()
        search.forceActiveFocus(Qt.OtherFocusReason)
        if (search.activeFocus)
            search.selectAll()
    }

    Timer {
        id: focusTimer
        interval: 50
        repeat: false
        onTriggered: launcher.activateLauncher()
    }

    Timer {
        id: dismissTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (!launcher.active) {
                root.launcherVisible = false
                launcher.visible = false
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#101116"
        border.width: 1
        border.color: "#373b41"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 10
                    color: root.accent
                    Text {
                        anchors.centerIn: parent
                        text: "󰣆"
                        color: root.background
                        font.family: "JetBrains Mono"
                        font.pixelSize: 19
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: "Applications"; color: root.foreground; font.family: "JetBrains Mono"; font.pixelSize: 15; font.weight: Font.DemiBold }
                    Text { text: "Launch something"; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                }
                Text { text: "ESC"; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
            }

            TextField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 50
                placeholderText: "Search applications..."
                color: root.foreground
                placeholderTextColor: root.muted
                selectionColor: root.highlight
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                leftPadding: 18
                rightPadding: 18
                onTextChanged: apps.selectFirst()
                background: Rectangle { color: "#171820"; radius: 10; border.width: 1; border.color: search.activeFocus ? root.accent : "#373b41" }
                Keys.onEscapePressed: {
                    root.launcherVisible = false
                    launcher.visible = false
                }
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Up: apps.moveSelection(-1); event.accepted = true; break
                    case Qt.Key_Down:
                    case Qt.Key_Tab: apps.moveSelection(1); event.accepted = true; break
                    case Qt.Key_PageUp: apps.moveSelection(-Math.max(1, Math.floor(apps.height / 48))); event.accepted = true; break
                    case Qt.Key_PageDown: apps.moveSelection(Math.max(1, Math.floor(apps.height / 48))); event.accepted = true; break
                    case Qt.Key_Home: apps.selectFirst(); event.accepted = true; break
                    case Qt.Key_End: apps.selectLast(); event.accepted = true; break
                    case Qt.Key_Return:
                    case Qt.Key_Enter: apps.launchCurrent(); event.accepted = true; break
                    }
                }
            }

            ListView {
                id: apps
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                model: DesktopEntries.applications
                currentIndex: 0

                function moveSelection(direction) {
                    if (count === 0) return
                    let candidate = currentIndex
                    for (let i = 0; i < count; i++) {
                        candidate = (candidate + direction + count) % count
                        const item = itemAtIndex(candidate)
                        if (item && item.matches) {
                            currentIndex = candidate
                            positionViewAtIndex(candidate, ListView.Contain)
                            return
                        }
                    }
                }
                function selectFirst() {
                    for (let i = 0; i < count; i++) {
                        const item = itemAtIndex(i)
                        if (item && item.matches) { currentIndex = i; positionViewAtIndex(i, ListView.Beginning); return }
                    }
                }
                function selectLast() {
                    for (let i = count - 1; i >= 0; i--) {
                        const item = itemAtIndex(i)
                        if (item && item.matches) { currentIndex = i; positionViewAtIndex(i, ListView.End); return }
                    }
                }
                function launchCurrent() {
                    if (currentItem && currentItem.entry && currentItem.matches) {
                        currentItem.entry.execute()
                        root.launcherVisible = false
                        launcher.visible = false
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    property var entry: modelData
                    readonly property bool valid: entry !== null && entry !== undefined
                    readonly property string searchText: {
                        if (!valid) return ""
                        const keywords = Array.isArray(entry.keywords) ? entry.keywords.join(" ") : (entry.keywords || "")
                        return ((entry.name || "") + " " + (entry.genericName || "") + " " + (entry.comment || "") + " " + keywords + " " + (entry.id || "")).toLowerCase()
                    }
                    readonly property bool matches: valid && (search.text.trim().length === 0 || searchText.indexOf(search.text.trim().toLowerCase()) !== -1)
                    width: apps.width
                    height: matches ? 48 : 0
                    visible: matches
                    color: ListView.isCurrentItem ? "#252536" : "transparent"
                    border.width: ListView.isCurrentItem ? 1 : 0
                    border.color: root.accent
                    radius: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 14
                        Image {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            source: entry && entry.icon && entry.icon.length > 0 ? Quickshell.iconPath(entry.icon, true) : ""
                            sourceSize.width: 32
                            sourceSize.height: 32
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: entry ? entry.name : ""; color: root.foreground; font.family: "JetBrains Mono"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: entry ? (entry.genericName || entry.comment) : ""; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: apps.currentIndex = parent.index
                        onPressed: apps.currentIndex = parent.index
                        onClicked: { if (!parent.matches) return; apps.currentIndex = parent.index; apps.launchCurrent() }
                    }
                }
                Keys.onUpPressed: decrementCurrentIndex()
                Keys.onDownPressed: incrementCurrentIndex()
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "↑↓  Navigate"; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                Text { text: "↵  Launch"; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                Item { Layout.fillWidth: true }
                Text { text: "󰘳  Super + Space"; color: root.accent; font.family: "JetBrains Mono"; font.pixelSize: 9 }
            }
        }
    }
}
