import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Window {
    id: clipboardViewer
    property var root
    visible: false
    title: "Clipboard"
    x: root.centerX(width)
    y: root.centerY(height)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    width: root.primaryScreen() ? Math.max(1, Math.min(640 * root.menuScale, root.primaryScreen().width - 32)) : 640 * root.menuScale
    height: root.primaryScreen() ? Math.max(1, Math.min(560 * root.menuScale, root.primaryScreen().height - 48)) : 560 * root.menuScale
    property int focusAttempts: 0

    onVisibleChanged: {
        if (visible) {
            dismissTimer.stop()
            search.text = ""
            root.fetchCopyqHistory()
            activateViewer()
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

    function activateViewer() {
        requestActivate()
        focusAttempts = 0
        focusTimer.restart()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: {
            search.text = ""
            clipboardViewer.visible = false
        }
    }

    Timer {
        id: focusTimer
        interval: 40
        repeat: true
        onTriggered: {
            if (!clipboardViewer.visible) {
                stop()
                return
            }
            clipboardViewer.requestActivate()
            search.forceActiveFocus(Qt.OtherFocusReason)
            if (search.activeFocus) {
                search.selectAll()
                stop()
            } else {
                clipboardViewer.focusAttempts++
                if (clipboardViewer.focusAttempts >= 8)
                    stop()
            }
        }
    }

    Timer {
        id: dismissTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (!clipboardViewer.active && clipboardViewer.visible) {
                search.text = ""
                clipboardViewer.visible = false
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

        opacity: clipboardViewer.visible ? 1.0 : 0.0
        scale: clipboardViewer.visible ? 1.0 : 0.97
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
                        text: "󰅍"
                        color: root.background
                        font.family: "JetBrains Mono"
                        font.pixelSize: Math.round(19 * root.displayFontScale)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "Clipboard History"
                        color: root.foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: Math.round(15 * root.displayFontScale)
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: (root.copyqHistory.length) + " items in CopyQ • Click or Enter to copy • Del to remove"
                        color: root.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: Math.round(10 * root.displayFontScale)
                    }
                }
            }

            TextField {
                id: search
                Layout.fillWidth: true
                implicitHeight: 50 * root.menuScale
                placeholderText: "Search clipboard history..."
                color: root.foreground
                placeholderTextColor: root.muted
                selectionColor: root.highlight
                font.family: "JetBrains Mono"
                font.pixelSize: Math.round(13 * root.displayFontScale)
                leftPadding: 18 * root.menuScale
                rightPadding: 62 * root.menuScale
                onTextChanged: Qt.callLater(() => itemsList.selectFirst())
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
                    clipboardViewer.visible = false
                }
                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Up: itemsList.moveSelection(-1); event.accepted = true; break
                    case Qt.Key_Backtab: itemsList.moveSelection(-1); event.accepted = true; break
                    case Qt.Key_Down: itemsList.moveSelection(1); event.accepted = true; break
                    case Qt.Key_Tab: itemsList.moveSelection(1); event.accepted = true; break
                    case Qt.Key_PageUp: itemsList.moveSelection(-Math.max(1, Math.floor(itemsList.height / 48))); event.accepted = true; break
                    case Qt.Key_PageDown: itemsList.moveSelection(Math.max(1, Math.floor(itemsList.height / 48))); event.accepted = true; break
                    case Qt.Key_Home: itemsList.selectFirst(); event.accepted = true; break
                    case Qt.Key_End: itemsList.selectLast(); event.accepted = true; break
                    case Qt.Key_Delete: itemsList.deleteCurrent(); event.accepted = true; break
                    case Qt.Key_Return:
                    case Qt.Key_Enter: itemsList.launchCurrent(); event.accepted = true; break
                    }
                }
            }

            ScriptModel {
                id: filteredItems
                values: {
                    const query = search.text.trim().toLowerCase()
                    const history = root.copyqHistory || []
                    if (query.length === 0) return history
                    return history.filter(item => item && item.text && String(item.text).toLowerCase().indexOf(query) !== -1)
                }
            }

            ListView {
                id: itemsList
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
                function deleteCurrent() {
                    if (currentIndex < 0 || currentIndex >= count) return
                    const item = filteredItems.values[currentIndex]
                    if (item && item.row !== undefined) {
                        root.deleteCopyqItem(item.row)
                    }
                }
                function launchCurrent() {
                    if (currentIndex < 0 || currentIndex >= count) return
                    const item = filteredItems.values[currentIndex]
                    if (item && item.row !== undefined) {
                        root.selectCopyqItem(item.row)
                        clipboardViewer.visible = false
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    property var copyqItem: modelData
                    property string clipText: copyqItem ? String(copyqItem.text || "") : ""
                    width: itemsList.width
                    height: 48 * root.menuScale
                    color: ListView.isCurrentItem ? root.settingsRaised : "transparent"
                    border.width: ListView.isCurrentItem ? 1 : 0
                    border.color: root.accent
                    radius: 8
                    Accessible.role: Accessible.ListItem
                    Accessible.name: clipText
                    Accessible.focused: ListView.isCurrentItem

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.menuScale
                        anchors.rightMargin: 12 * root.menuScale
                        spacing: 14 * root.menuScale

                        Rectangle {
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

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: clipText.replace(/\n/g, " ↵ ").slice(0, 100)
                                color: root.foreground
                                font.family: "JetBrains Mono"
                                font.pixelSize: Math.round(13 * root.displayFontScale)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "#" + (copyqItem ? copyqItem.row : 0) + " • " + clipText.length + " chars • Click or Enter to copy"
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
                        onEntered: itemsList.currentIndex = parent.index
                        onPressed: itemsList.currentIndex = parent.index
                        onClicked: { itemsList.currentIndex = parent.index; itemsList.launchCurrent() }
                    }
                }
                Keys.onUpPressed: decrementCurrentIndex()
                Keys.onDownPressed: incrementCurrentIndex()

                Text {
                    anchors.centerIn: parent
                    visible: itemsList.count === 0
                    text: search.text.trim().length > 0 ? "No matching CopyQ items" : "No CopyQ history items found"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: Math.round(11 * root.displayFontScale)
                }
            }
        }
    }
}
