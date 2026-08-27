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
    width: root.primaryScreen() ? Math.max(1, Math.min(640 * root.menuScale, root.primaryScreen().width - 32)) : 640 * root.menuScale
    height: root.primaryScreen() ? Math.max(1, Math.min(560 * root.menuScale, root.primaryScreen().height - 48)) : 560 * root.menuScale
    property string launchError: ""

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

    function searchableText(entry) {
        const keywords = Array.isArray(entry.keywords) ? entry.keywords.join(" ") : (entry.keywords || "")
        return ((entry.name || "") + " " + (entry.genericName || "") + " " + (entry.comment || "") + " " + keywords + " " + (entry.id || "")).toLowerCase()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            root.launcherVisible = false
            launcher.visible = false
        }
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
            anchors.margins: 24 * root.menuScale
            spacing: 14 * root.menuScale

            RowLayout {
                Layout.fillWidth: true
                Rectangle {
                    Layout.preferredWidth: 36 * root.menuScale
                    Layout.preferredHeight: 36 * root.menuScale
                    radius: 10 * root.menuScale
                    color: root.accent
                    Text {
                        anchors.centerIn: parent
                        text: "󰣆"
                        color: root.background
                        font.family: "JetBrains Mono"
                        font.pixelSize: 19 * root.displayFontScale
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: "Applications"; color: root.foreground; font.family: "JetBrains Mono"; font.pixelSize: 15 * root.displayFontScale; font.weight: Font.DemiBold }
                    Text { text: "Launch something"; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 10 * root.displayFontScale }
                }
            }

            TextField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 50 * root.menuScale
                placeholderText: "Search applications..."
                color: root.foreground
                placeholderTextColor: root.muted
                selectionColor: root.highlight
                font.family: "JetBrains Mono"
                font.pixelSize: 13 * root.displayFontScale
                leftPadding: 18 * root.menuScale
                rightPadding: 62 * root.menuScale
                onTextChanged: Qt.callLater(() => apps.selectFirst())
                background: Rectangle { color: "#171820"; radius: 10; border.width: 1; border.color: search.activeFocus ? root.accent : "#373b41" }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * root.menuScale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ESC"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9 * root.displayFontScale
                }
                Keys.onEscapePressed: {
                    root.launcherVisible = false
                    launcher.visible = false
                }
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Up: apps.moveSelection(-1); event.accepted = true; break
                    case Qt.Key_Backtab: apps.moveSelection(-1); event.accepted = true; break
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

            ScriptModel {
                id: filteredApps
                values: {
                    const query = search.text.trim().toLowerCase()
                    const entries = DesktopEntries.applications.values.filter(entry => query.length === 0 || launcher.searchableText(entry).indexOf(query) !== -1)
                    return entries.sort((left, right) => (left.name || "").localeCompare(right.name || ""))
                }
            }

            ListView {
                id: apps
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6 * root.menuScale
                model: filteredApps
                currentIndex: count > 0 ? 0 : -1

                function moveSelection(direction) {
                    if (count === 0) return
                    currentIndex = ((Math.max(0, currentIndex) + direction) % count + count) % count
                    positionViewAtIndex(currentIndex, ListView.Contain)
                }
                function selectFirst() {
                    currentIndex = count > 0 ? 0 : -1
                    if (currentIndex >= 0) positionViewAtBeginning()
                }
                function selectLast() {
                    currentIndex = count - 1
                    if (currentIndex >= 0) positionViewAtEnd()
                }
                function launchCurrent() {
                    if (currentItem && currentItem.entry) {
                        try {
                            currentItem.entry.execute()
                            root.launcherVisible = false
                            launcher.visible = false
                        } catch (error) {
                            launcher.launchError = "Unable to launch this application"
                        }
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    property var entry: modelData
                    width: apps.width
                    height: 48 * root.menuScale
                    color: ListView.isCurrentItem ? "#252536" : "transparent"
                    border.width: ListView.isCurrentItem ? 1 : 0
                    border.color: root.accent
                    radius: 8
                    Accessible.role: Accessible.ListItem
                    Accessible.name: entry ? entry.name : "Application"
                    Accessible.focused: ListView.isCurrentItem

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.menuScale
                        anchors.rightMargin: 12 * root.menuScale
                        spacing: 14 * root.menuScale
                        Image {
                            Layout.preferredWidth: 32 * root.menuScale
                            Layout.preferredHeight: 32 * root.menuScale
                            source: entry && entry.icon && entry.icon.length > 0 ? Quickshell.iconPath(entry.icon, true) : ""
                            sourceSize.width: 32 * root.menuScale
                            sourceSize.height: 32 * root.menuScale
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: entry ? entry.name : ""; color: root.foreground; font.family: "JetBrains Mono"; font.pixelSize: 13 * root.displayFontScale; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: entry ? (entry.genericName || entry.comment) : ""; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 10 * root.displayFontScale; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: apps.currentIndex = parent.index
                        onPressed: apps.currentIndex = parent.index
                        onClicked: { apps.currentIndex = parent.index; apps.launchCurrent() }
                    }
                }
                Keys.onUpPressed: decrementCurrentIndex()
                Keys.onDownPressed: incrementCurrentIndex()

                Text {
                    anchors.centerIn: parent
                    visible: apps.count === 0
                    text: search.text.trim().length > 0 ? "No matching applications" : "No applications found"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11 * root.displayFontScale
                }
            }

            Text {
                visible: launcher.launchError.length > 0
                Layout.fillWidth: true
                text: launcher.launchError
                color: "#f38ba8"
                font.family: "JetBrains Mono"
                font.pixelSize: 10 * root.displayFontScale
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "↑↓  Navigate"; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 9 * root.displayFontScale }
                Text { text: "↵  Launch"; color: root.muted; font.family: "JetBrains Mono"; font.pixelSize: 9 * root.displayFontScale }
                Item { Layout.fillWidth: true }
                Text { text: "󰘳  Super + Space"; color: root.accent; font.family: "JetBrains Mono"; font.pixelSize: 9 * root.displayFontScale }
            }
        }
    }
}
