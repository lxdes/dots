import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: popup

    required property var shellRoot
    required property var barWindow

    readonly property color background: shellRoot.background
    readonly property color foreground: shellRoot.foreground
    readonly property color muted: shellRoot.muted
    readonly property color accent: shellRoot.accent
    readonly property color surface: shellRoot.settingsSurface
    readonly property color raised: shellRoot.settingsRaised
    readonly property color outline: shellRoot.settingsOutline
    readonly property real fontScale: shellRoot.uiFontScale
    property real currentTrackPosition: 0
    readonly property real currentTrackLength: shellRoot.currentPlayer ? (shellRoot.currentPlayer.length || 0) : 0
    readonly property bool isTrackPlaying: shellRoot.currentPlayer ? shellRoot.currentPlayer.isPlaying : false

    Timer {
        id: trackPositionTimer
        interval: 1000
        repeat: true
        running: popup.visible && popup.isTrackPlaying
        triggeredOnStart: true
        onTriggered: {
            if (shellRoot.currentPlayer)
                popup.currentTrackPosition = shellRoot.currentPlayer.position
        }
    }

    Connections {
        target: shellRoot.currentPlayer
        ignoreUnknownSignals: true
        function onTrackTitleChanged() {
            if (shellRoot.currentPlayer)
                popup.currentTrackPosition = shellRoot.currentPlayer.position
        }
        function onPositionChanged() {
            if (shellRoot.currentPlayer)
                popup.currentTrackPosition = shellRoot.currentPlayer.position
        }
        function onPlaybackStateChanged() {
            if (shellRoot.currentPlayer)
                popup.currentTrackPosition = shellRoot.currentPlayer.position
        }
        function onIsPlayingChanged() {
            if (shellRoot.currentPlayer)
                popup.currentTrackPosition = shellRoot.currentPlayer.position
        }
    }

    visible: false
    anchor.window: barWindow
    anchor.rect.x: barWindow.width - implicitWidth - 10
    anchor.rect.y: barWindow.height + 8
    grabFocus: true
    color: "transparent"
    implicitWidth: Math.min(360 * shellRoot.menuScale, barWindow.width - 16)
    implicitHeight: content.implicitHeight + 28 * shellRoot.menuScale

    onVisibleChanged: {
        if (visible && shellRoot.currentPlayer) {
            popup.currentTrackPosition = shellRoot.currentPlayer.position
        }
    }

    onIsTrackPlayingChanged: {
        if (shellRoot.currentPlayer)
            popup.currentTrackPosition = shellRoot.currentPlayer.position
    }

    Rectangle {
        anchors.fill: parent
        color: popup.background
        border.width: 1
        border.color: popup.outline
        radius: 12
        clip: true
        antialiasing: true
        smooth: true

        opacity: popup.visible ? 1.0 : 0.0
        scale: popup.visible ? 1.0 : 0.97
        Behavior on opacity {
            enabled: !shellRoot.reducedMotion
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            enabled: !shellRoot.reducedMotion
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 14 * shellRoot.menuScale
            spacing: 14 * shellRoot.menuScale

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * shellRoot.menuScale

                Rectangle {
                    Layout.preferredWidth: 32 * shellRoot.menuScale
                    Layout.preferredHeight: 32 * shellRoot.menuScale
                    radius: 8 * shellRoot.menuScale
                    color: popup.accent
                    Text {
                        anchors.centerIn: parent
                        text: "󰝚"
                        color: popup.background
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16 * popup.fontScale
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "Music Control"
                        color: popup.foreground
                        font.family: "Noto Sans"
                        font.pixelSize: 13 * popup.fontScale
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: shellRoot.currentPlayer ? (shellRoot.currentPlayer.identity || "Media Player") : "No media playing"
                        color: popup.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9 * popup.fontScale
                        elide: Text.ElideRight
                    }
                }

                PopupIconButton {
                    scaleFactor: shellRoot.menuScale
                    text: "󰒓"
                    foregroundColor: popup.foreground
                    mutedColor: popup.muted
                    accentColor: popup.accent
                    hoverColor: popup.raised
                    Accessible.name: "Open sound settings"
                    ToolTip.visible: hovered
                    ToolTip.text: Accessible.name
                    onClicked: shellRoot.openSettings("Audio")
                }
            }

            // Player Body / Empty State
            Item {
                Layout.fillWidth: true
                visible: shellRoot.currentPlayer === null
                implicitHeight: 120 * shellRoot.menuScale

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8 * shellRoot.menuScale

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰝛"
                        color: popup.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 32 * popup.fontScale
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No active media playback"
                        color: popup.foreground
                        font.family: "Noto Sans"
                        font.pixelSize: 12 * popup.fontScale
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Play a track on Spotify, browser, or media player"
                        color: popup.muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9 * popup.fontScale
                    }
                }
            }

            // Media Card when Player Active
            Rectangle {
                visible: shellRoot.currentPlayer !== null
                Layout.fillWidth: true
                implicitHeight: 200 * shellRoot.menuScale
                color: popup.surface
                radius: 10 * shellRoot.menuScale
                border.width: 1
                border.color: popup.outline
                clip: true

                // Background artwork blur effect
                Image {
                    anchors.fill: parent
                    visible: shellRoot.currentPlayer !== null && (shellRoot.currentPlayer.trackArtUrl || "").length > 0
                    source: shellRoot.currentPlayer ? (shellRoot.currentPlayer.trackArtUrl || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.12
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12 * shellRoot.menuScale
                    spacing: 10 * shellRoot.menuScale

                    // Art + Track details row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12 * shellRoot.menuScale

                        Rectangle {
                            Layout.preferredWidth: 64 * shellRoot.menuScale
                            Layout.preferredHeight: 64 * shellRoot.menuScale
                            radius: 8 * shellRoot.menuScale
                            color: popup.raised
                            border.width: 1
                            border.color: popup.outline
                            clip: true

                            Image {
                                id: artImage
                                anchors.fill: parent
                                visible: shellRoot.currentPlayer !== null && (shellRoot.currentPlayer.trackArtUrl || "").length > 0
                                source: shellRoot.currentPlayer ? (shellRoot.currentPlayer.trackArtUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !artImage.visible
                                text: "󰝚"
                                color: popup.accent
                                font.family: "JetBrains Mono"
                                font.pixelSize: 24
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: shellRoot.currentPlayer ? (shellRoot.currentPlayer.trackTitle || "Unknown track") : ""
                                color: popup.foreground
                                font.family: "Noto Sans"
                                font.pixelSize: 13 * popup.fontScale
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: shellRoot.currentPlayer ? (shellRoot.currentPlayer.trackArtist || shellRoot.currentPlayer.trackAlbum || "Unknown artist") : ""
                                color: popup.muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10 * popup.fontScale
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: shellRoot.currentPlayer && shellRoot.currentPlayer.trackAlbum && shellRoot.currentPlayer.trackAlbum.length > 0 && shellRoot.currentPlayer.trackAlbum !== shellRoot.currentPlayer.trackTitle
                                text: shellRoot.currentPlayer ? shellRoot.currentPlayer.trackAlbum : ""
                                color: popup.muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8 * popup.fontScale
                                opacity: 0.7
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // Progress Scrubber Bar
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 6 * shellRoot.menuScale
                            radius: 3
                            color: popup.outline

                            Rectangle {
                                width: popup.currentTrackLength > 0 ? parent.width * Math.min(1, Math.max(0, popup.currentTrackPosition / popup.currentTrackLength)) : 0
                                height: parent.height
                                radius: 3
                                color: popup.accent

                                Behavior on width {
                                    enabled: !shellRoot.reducedMotion && popup.isTrackPlaying
                                    NumberAnimation { duration: 950; easing.type: Easing.Linear }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: mouse => {
                                    if (shellRoot.currentPlayer && popup.currentTrackLength > 0) {
                                        const targetPos = (mouse.x / width) * popup.currentTrackLength
                                        popup.currentTrackPosition = targetPos
                                        try {
                                            shellRoot.currentPlayer.position = targetPos
                                        } catch (e) {}
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: shellRoot.formatTrackTime(popup.currentTrackPosition)
                                color: popup.muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8 * popup.fontScale
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: shellRoot.formatTrackTime(popup.currentTrackLength)
                                color: popup.muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8 * popup.fontScale
                            }
                        }
                    }

                    // Transport Controls
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16 * shellRoot.menuScale

                        PopupIconButton {
                            scaleFactor: shellRoot.menuScale * 1.1
                            text: "󰒮"
                            enabled: shellRoot.currentPlayer !== null && shellRoot.currentPlayer.canGoPrevious
                            foregroundColor: popup.foreground
                            mutedColor: popup.muted
                            accentColor: popup.accent
                            hoverColor: popup.raised
                            Accessible.name: "Previous track"
                            onClicked: shellRoot.currentPlayer.previous()
                        }

                        Rectangle {
                            implicitWidth: 38 * shellRoot.menuScale
                            implicitHeight: 38 * shellRoot.menuScale
                            radius: 19 * shellRoot.menuScale
                            color: popup.accent

                            Text {
                                anchors.centerIn: parent
                                text: shellRoot.currentPlayer && shellRoot.currentPlayer.isPlaying ? "󰏤" : "󰐊"
                                color: popup.background
                                font.family: "JetBrains Mono"
                                font.pixelSize: 18 * popup.fontScale
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (shellRoot.currentPlayer)
                                        shellRoot.currentPlayer.togglePlaying()
                                }
                            }
                        }

                        PopupIconButton {
                            scaleFactor: shellRoot.menuScale * 1.1
                            text: "󰒭"
                            enabled: shellRoot.currentPlayer !== null && shellRoot.currentPlayer.canGoNext
                            foregroundColor: popup.foreground
                            mutedColor: popup.muted
                            accentColor: popup.accent
                            hoverColor: popup.raised
                            Accessible.name: "Next track"
                            onClicked: shellRoot.currentPlayer.next()
                        }
                    }
                }
            }

            // Volume Control Slider Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * shellRoot.menuScale

                Text {
                    text: shellRoot.outputMuted ? "󰝟" : "󰕾"
                    color: shellRoot.outputMuted ? "#f38ba8" : popup.accent
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14 * popup.fontScale
                }

                PopupSlider {
                    scaleFactor: shellRoot.menuScale
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: shellRoot.volumeLevel / 100
                    enabled: !shellRoot.outputMuted
                    trackColor: popup.outline
                    accentColor: popup.accent
                    handleColor: popup.foreground
                    surfaceColor: popup.surface
                    Accessible.name: "Master volume"
                    onMoved: shellRoot.setVolume(value)
                }

                Text {
                    text: shellRoot.outputMuted ? "Muted" : Math.round(shellRoot.volumeLevel) + "%"
                    color: shellRoot.outputMuted ? "#f38ba8" : popup.foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10 * popup.fontScale
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
