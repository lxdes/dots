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
    width: 760
    height: 600

    onVisibleChanged: if (visible) requestActivate()
    Keys.onEscapePressed: visible = false

    Rectangle {
        anchors.fill: parent
        color: root.background
        border.width: 1
        border.color: "#373b41"
        radius: 1

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
                    font.pixelSize: 16 * root.menuFontScale
                    font.weight: Font.DemiBold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Click an image to apply  •  Esc to close"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
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
                cellWidth: 230
                cellHeight: 190
                model: root.wallpapers

                delegate: Item {
                    required property string modelData
                    width: wallpaperGrid.cellWidth - 10
                    height: wallpaperGrid.cellHeight - 10

                    Rectangle {
                        anchors.fill: parent
                        color: "#171820"
                        border.width: root.selectedWallpaper === modelData || wallpaperMouse.containsMouse ? 2 : 1
                        border.color: root.selectedWallpaper === modelData ? root.accent : (wallpaperMouse.containsMouse ? root.foreground : "#373b41")
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: modelData
                            fillMode: Image.PreserveAspectCrop
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
                                root.applyWallpaper(modelData)
                                root.run(["notify-send", "Wallpaper applied", modelData.split("/").pop()])
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
