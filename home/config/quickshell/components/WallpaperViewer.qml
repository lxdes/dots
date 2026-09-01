import QtQuick
import QtQuick.Layouts
import Quickshell

Window {
    id: wallpaperViewer
    property var root
    visible: false
    title: "Wallpaper Viewer"
    x: root.centerX(width)
    y: root.centerY(height)
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    width: root.primaryScreen() ? Math.max(1, Math.min(760, root.primaryScreen().width - 32)) : 760
    height: root.primaryScreen() ? Math.max(1, Math.min(600, root.primaryScreen().height - 48)) : 600

    onVisibleChanged: if (visible) {
        requestActivate()
        wallpaperGrid.forceActiveFocus(Qt.OtherFocusReason)
    }
    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: wallpaperViewer.visible = false
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

        opacity: wallpaperViewer.visible ? 1.0 : 0.0
        scale: wallpaperViewer.visible ? 1.0 : 0.97
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
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Wallpapers"
                    color: root.foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 18 * root.uiFontScale
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Click or Enter to apply  •  Esc to close  •  Arrows to navigate"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: root.accent
            }

            GridView {
                id: wallpaperGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: width / Math.max(1, Math.floor(width / 220))
                cellHeight: Math.max(150, cellWidth * 0.78)
                model: root.wallpapers
                currentIndex: count > 0 ? 0 : -1
                focus: true

                Keys.onReturnPressed: if (currentIndex >= 0) root.applyWallpaper(root.wallpapers[currentIndex])
                Keys.onEnterPressed: if (currentIndex >= 0) root.applyWallpaper(root.wallpapers[currentIndex])

                delegate: Item {
                    required property string modelData
                    width: wallpaperGrid.cellWidth - 10
                    height: wallpaperGrid.cellHeight - 10
                    Accessible.role: Accessible.Button
                    Accessible.name: "Apply wallpaper " + modelData.split("/").pop()

                    Rectangle {
                        anchors.fill: parent
                        color: "#171820"
                        border.width: root.selectedWallpaper === modelData || wallpaperMouse.containsMouse ? 2 : 1
                        border.color: root.selectedWallpaper === modelData ? root.accent : (wallpaperMouse.containsMouse ? root.foreground : "#373b41")
                        clip: true

                        Image {
                            id: thumbnail
                            anchors.fill: parent
                            source: modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize.width: Math.ceil(width)
                            sourceSize.height: Math.ceil(height)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: thumbnail.status === Image.Error
                            text: "Preview unavailable"
                            color: root.muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 28
                            color: root.background
                            opacity: wallpaperMouse.containsMouse || root.selectedWallpaper === modelData ? 0.9 : 0.72
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                text: modelData.split("/").pop()
                                color: root.foreground
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9
                                elide: Text.ElideMiddle
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: wallpaperMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                wallpaperGrid.currentIndex = index
                                root.applyWallpaper(modelData)
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.wallpapers.length === 0
                    text: "No wallpapers found"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                }
            }
        }
    }
}
