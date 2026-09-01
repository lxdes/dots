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
    property string mode: "apps"
    property string launchError: ""
    property int focusAttempts: 0

    onVisibleChanged: {
        if (visible) {
            dismissTimer.stop()
            search.text = ""
            activateLauncher()
        } else {
            search.text = ""
            focusTimer.stop()
            dismissTimer.stop()
        }
    }

    onActiveChanged: {
        if (active) {
            dismissTimer.stop()
            search.forceActiveFocus(Qt.OtherFocusReason)
            search.selectAll()
        } else if (visible) {
            dismissTimer.restart()
        }
    }

    function activateLauncher() {
        requestActivate()
        focusAttempts = 0
        focusTimer.restart()
    }

    function searchableText(entry) {
        const keywords = Array.isArray(entry.keywords) ? entry.keywords.join(" ") : (entry.keywords || "")
        return ((entry.name || "") + " " + (entry.genericName || "") + " " + (entry.comment || "") + " " + keywords + " " + (entry.id || "")).toLowerCase()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            search.text = ""
            root.launcherVisible = false
            launcher.visible = false
        }
    }

    Timer {
        id: focusTimer
        interval: 40
        repeat: true
        onTriggered: {
            if (!launcher.visible) {
                stop()
                return
            }
            launcher.requestActivate()
            search.forceActiveFocus(Qt.OtherFocusReason)
            if (search.activeFocus) {
                search.selectAll()
                stop()
            } else {
                launcher.focusAttempts++
                if (launcher.focusAttempts >= 8)
                    stop()
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (!launcher.active && launcher.visible) {
                search.text = ""
                root.launcherVisible = false
                launcher.visible = false
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.background
        border.width: 1
        border.color: root.settingsOutline
        radius: 12
        clip: true
        antialiasing: true
        smooth: true

        opacity: launcher.visible ? 1.0 : 0.0
        scale: launcher.visible ? 1.0 : 0.97
        Behavior on opacity {
            enabled: !root.reducedMotion
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            enabled: !root.reducedMotion
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24 * root.menuScale
            spacing: 14 * root.menuScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * root.menuScale

                Rectangle {
                    Layout.preferredWidth: 36 * root.menuScale
                    Layout.preferredHeight: 36 * root.menuScale
                    radius: 10 * root.menuScale
                    color: root.accent
                    Text {
                        anchors.centerIn: parent
                        text: launcher.mode === "clipboard" ? "󰅍" : "󰣆"
                        color: root.background
                        font.family: "JetBrains Mono"
                        font.pixelSize: Math.round(19 * root.displayFontScale)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: launcher.mode === "clipboard" ? "Clipboard History" : "Applications"
                        color: root.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: Math.round(15 * root.displayFontScale)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: launcher.mode === "clipboard" ? (root.clipboardHistory.length + " saved entries • Press Tab or click to switch") : "Launch something • Press Tab to view clipboard"
                        color: root.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: Math.round(10 * root.displayFontScale)
                    }
                }

                RowLayout {
                    spacing: 6 * root.menuScale

                    Rectangle {
                        implicitWidth: 80 * root.menuScale
                        implicitHeight: 28 * root.menuScale
                        radius: 6
                        color: launcher.mode === "apps" ? root.settingsRaised : "transparent"
                        border.width: 1
                        border.color: launcher.mode === "apps" ? root.accent : root.settingsOutline

                        Text {
                            anchors.centerIn: parent
                            text: "Apps"
                            color: launcher.mode === "apps" ? root.foreground : root.muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: Math.round(11 * root.displayFontScale)
                            font.weight: launcher.mode === "apps" ? Font.Bold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { launcher.mode = "apps"; search.forceActiveFocus() }
                        }
                    }

                    Rectangle {
                        implicitWidth: 80 * root.menuScale
                        implicitHeight: 28 * root.menuScale
                        radius: 6
                        color: launcher.mode === "clipboard" ? root.settingsRaised : "transparent"
                        border.width: 1
                        border.color: launcher.mode === "clipboard" ? root.accent : root.settingsOutline

                        Text {
                            anchors.centerIn: parent
                            text: "Clipboard"
                            color: launcher.mode === "clipboard" ? root.foreground : root.muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: Math.round(11 * root.displayFontScale)
                            font.weight: launcher.mode === "clipboard" ? Font.Bold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { launcher.mode = "clipboard"; search.forceActiveFocus() }
                        }
                    }
                }
            }

            TextField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 50 * root.menuScale
                placeholderText: launcher.mode === "clipboard" ? "Search clipboard history..." : "Search applications..."
                color: root.foreground
                placeholderTextColor: root.muted
                selectionColor: root.highlight
                font.family: "JetBrains Mono"
                font.pixelSize: Math.round(13 * root.displayFontScale)
                leftPadding: 18 * root.menuScale
                rightPadding: 62 * root.menuScale
                onTextChanged: Qt.callLater(() => apps.selectFirst())
                background: Rectangle { color: root.settingsSurface; radius: 10; border.width: 1; border.color: search.activeFocus ? root.accent : root.settingsOutline }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * root.menuScale
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ESC"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: Math.round(9 * root.displayFontScale)
                }
                Keys.onEscapePressed: {
                    root.launcherVisible = false
                    launcher.visible = false
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab && search.text.length === 0) {
                        launcher.mode = launcher.mode === "apps" ? "clipboard" : "apps"
                        event.accepted = true
                        return
                    }
                    switch (event.key) {
                    case Qt.Key_Up: apps.moveSelection(-1); event.accepted = true; break
                    case Qt.Key_Backtab: apps.moveSelection(-1); event.accepted = true; break
                    case Qt.Key_Down: apps.moveSelection(1); event.accepted = true; break
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
                id: filteredItems
                values: {
                    const query = search.text.trim().toLowerCase()
                    if (launcher.mode === "clipboard") {
                        const history = root.clipboardHistory || []
                        if (query.length === 0) return history
                        return history.filter(item => String(item).toLowerCase().indexOf(query) !== -1)
                    } else {
                        const entries = DesktopEntries.applications.values.filter(entry => query.length === 0 || launcher.searchableText(entry).indexOf(query) !== -1)
                        return entries.sort((left, right) => (left.name || "").localeCompare(right.name || ""))
                    }
                }
            }

            ListView {
                id: apps
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6 * root.menuScale
                model: filteredItems
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
                    if (currentIndex < 0 || currentIndex >= count) return
                    if (launcher.mode === "clipboard") {
                        const text = filteredItems.values[currentIndex]
                        if (text) {
                            root.copyToClipboard(text)
                            root.launcherVisible = false
                            launcher.visible = false
                        }
                    } else {
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
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    property var entry: launcher.mode === "apps" ? modelData : null
                    property string clipText: launcher.mode === "clipboard" ? String(modelData) : ""
                    width: apps.width
                    height: 48 * root.menuScale
                    color: ListView.isCurrentItem ? root.settingsRaised : "transparent"
                    border.width: ListView.isCurrentItem ? 1 : 0
                    border.color: root.accent
                    radius: 8
                    Accessible.role: Accessible.ListItem
                    Accessible.name: launcher.mode === "clipboard" ? clipText : (entry ? entry.name : "Application")
                    Accessible.focused: ListView.isCurrentItem

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.menuScale
                        anchors.rightMargin: 12 * root.menuScale
                        spacing: 14 * root.menuScale

                        Rectangle {
                            visible: launcher.mode === "clipboard"
                            Layout.preferredWidth: 32 * root.menuScale
                            Layout.preferredHeight: 32 * root.menuScale
                            radius: 6
                            color: root.settingsSurface
                            Text {
                                anchors.centerIn: parent
                                text: "󰅍"
                                color: root.accent
                                font.family: "JetBrains Mono"
                                font.pixelSize: Math.round(14 * root.displayFontScale)
                            }
                        }

                        Image {
                            visible: launcher.mode === "apps"
                            Layout.preferredWidth: 32 * root.menuScale
                            Layout.preferredHeight: 32 * root.menuScale
                            source: entry && entry.icon && entry.icon.length > 0 ? Quickshell.iconPath(entry.icon, true) : ""
                            sourceSize.width: 32 * root.menuScale
                            sourceSize.height: 32 * root.menuScale
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: launcher.mode === "clipboard" ? (clipText.replace(/\n/g, " ↵ ").slice(0, 100)) : (entry ? entry.name : "")
                                color: root.foreground
                                font.family: "JetBrains Mono"
                                font.pixelSize: Math.round(13 * root.displayFontScale)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: launcher.mode === "clipboard" ? (clipText.length + " chars • Click to copy") : (entry ? (entry.genericName || entry.comment) : "")
                                color: root.muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: Math.round(10 * root.displayFontScale)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
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
                    text: launcher.mode === "clipboard" ? (search.text.trim().length > 0 ? "No matching clipboard entries" : "No clipboard history yet") : (search.text.trim().length > 0 ? "No matching applications" : "No applications found")
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: Math.round(11 * root.displayFontScale)
                }
            }

            Text {
                visible: launcher.launchError.length > 0
                Layout.fillWidth: true
                text: launcher.launchError
                color: "#f38ba8"
                font.family: "JetBrains Mono"
                font.pixelSize: Math.round(10 * root.displayFontScale)
            }
        }
    }
}
