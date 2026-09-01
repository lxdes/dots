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
    implicitWidth: Math.min(400 * shellRoot.menuScale, barWindow.width - 16)
    implicitHeight: Math.min(content.implicitHeight + 28, barWindow.screen.height - barWindow.height - 12)

    onVisibleChanged: {
        if (visible) {
            shellRoot.refreshAudioDevices()
            if (shellRoot.currentPlayer)
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

        ScrollView {
            anchors.fill: parent
            anchors.margins: 14 * shellRoot.menuScale
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 12 * shellRoot.menuScale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9 * shellRoot.menuScale

                    Rectangle {
                        Layout.preferredWidth: 34 * shellRoot.menuScale
                        Layout.preferredHeight: 34 * shellRoot.menuScale
                        radius: 9 * shellRoot.menuScale
                        color: popup.accent
                        Text {
                            anchors.centerIn: parent
                            text: shellRoot.outputMuted ? "󰝟" : "󰕾"
                            color: popup.background
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17 * popup.fontScale
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Sound"
                            color: popup.foreground
                            font.family: "Noto Sans"
                            font.pixelSize: 14 * popup.fontScale
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: shellRoot.audioDetail || "Default output"
                            color: popup.muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 8 * popup.fontScale
                            elide: Text.ElideMiddle
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

                Rectangle {
                    visible: shellRoot.currentPlayer !== null
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90 * shellRoot.menuScale
                    color: popup.surface
                    radius: 12 * shellRoot.menuScale
                    border.width: 1
                    border.color: popup.outline
                    clip: true

                    Image {
                        anchors.fill: parent
                        visible: shellRoot.currentPlayer !== null && (shellRoot.currentPlayer.trackArtUrl || "").length > 0
                        source: shellRoot.currentPlayer ? (shellRoot.currentPlayer.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.14
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10 * shellRoot.menuScale
                        spacing: 10 * shellRoot.menuScale

                        Rectangle {
                            Layout.preferredWidth: 60 * shellRoot.menuScale
                            Layout.preferredHeight: 60 * shellRoot.menuScale
                            radius: 10 * shellRoot.menuScale
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
                                font.pixelSize: 22
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
                                font.pixelSize: 11 * popup.fontScale
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: shellRoot.currentPlayer ? (shellRoot.currentPlayer.trackArtist || shellRoot.currentPlayer.trackAlbum || "Unknown artist") : ""
                                color: popup.muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8 * popup.fontScale
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                Layout.preferredHeight: 4
                                radius: 2
                                color: popup.outline
                                Rectangle {
                                    width: popup.currentTrackLength > 0 ? parent.width * Math.min(1, Math.max(0, popup.currentTrackPosition / popup.currentTrackLength)) : 0
                                    height: parent.height
                                    radius: 2
                                    color: popup.accent

                                    Behavior on width {
                                        enabled: !shellRoot.reducedMotion && popup.isTrackPlaying
                                        NumberAnimation { duration: 950; easing.type: Easing.Linear }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: popup.currentTrackLength > 0
                                Text {
                                    text: shellRoot.formatTrackTime(popup.currentTrackPosition)
                                    color: popup.muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 7 * popup.fontScale
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: shellRoot.formatTrackTime(popup.currentTrackLength)
                                    color: popup.muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 7 * popup.fontScale
                                }
                            }
                        }

                        RowLayout {
                            spacing: 4 * shellRoot.menuScale

                            PopupIconButton {
                                scaleFactor: shellRoot.menuScale
                                text: "󰒮"
                                enabled: shellRoot.currentPlayer !== null && shellRoot.currentPlayer.canGoPrevious
                                foregroundColor: popup.foreground
                                mutedColor: popup.muted
                                accentColor: popup.accent
                                hoverColor: popup.raised
                                Accessible.name: "Previous track"
                                onClicked: shellRoot.currentPlayer.previous()
                            }
                            PopupIconButton {
                                scaleFactor: shellRoot.menuScale
                                text: shellRoot.currentPlayer && shellRoot.currentPlayer.isPlaying ? "󰏤" : "󰐊"
                                enabled: shellRoot.currentPlayer !== null && (shellRoot.currentPlayer.canTogglePlaying || shellRoot.currentPlayer.canPlay || shellRoot.currentPlayer.canPause)
                                accent: true
                                foregroundColor: popup.foreground
                                mutedColor: popup.muted
                                accentColor: popup.accent
                                hoverColor: popup.raised
                                Accessible.name: shellRoot.currentPlayer && shellRoot.currentPlayer.isPlaying ? "Pause" : "Play"
                                onClicked: shellRoot.currentPlayer.togglePlaying()
                            }
                            PopupIconButton {
                                scaleFactor: shellRoot.menuScale
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

                AudioSection {
                    Layout.fillWidth: true
                    theme: popup
                    title: "Output"
                    icon: shellRoot.outputMuted ? "󰝟" : "󰕾"
                    mutedState: shellRoot.outputMuted
                    level: shellRoot.volumeLevel
                    devices: shellRoot.audioSinks
                    defaultDeviceName: shellRoot.defaultSinkName
                    emptyText: shellRoot.audioSinksLoading ? "Loading outputs..." : "No output devices"
                    muteAccessibleName: shellRoot.outputMuted ? "Unmute output" : "Mute output"
                    onLevelMoved: value => shellRoot.setVolume(value)
                    onMuteClicked: shellRoot.toggleOutputMute()
                    onDeviceSelected: name => shellRoot.setDefaultSink(name)
                }

                AudioSection {
                    Layout.fillWidth: true
                    theme: popup
                    title: "Microphone"
                    icon: shellRoot.micMuted ? "󰍭" : "󰍬"
                    mutedState: shellRoot.micMuted
                    level: shellRoot.micVolumeLevel
                    devices: shellRoot.audioSources
                    defaultDeviceName: shellRoot.defaultSourceName
                    emptyText: shellRoot.audioSourcesLoading ? "Loading microphones..." : "No microphones"
                    muteAccessibleName: shellRoot.micMuted ? "Unmute microphone" : "Mute microphone"
                    onLevelMoved: value => shellRoot.setMicVolume(value)
                    onMuteClicked: shellRoot.toggleMicMute()
                    onDeviceSelected: name => shellRoot.setDefaultSource(name)
                }

                Text {
                    visible: shellRoot.audioActionError.length > 0
                    Layout.fillWidth: true
                    text: shellRoot.audioActionError
                    color: "#f38ba8"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8 * popup.fontScale
                    wrapMode: Text.Wrap
                }
            }
        }
    }

    component AudioSection: Rectangle {
        id: section

        required property string title
        required property var theme
        required property string icon
        required property bool mutedState
        required property real level
        required property var devices
        required property string defaultDeviceName
        required property string emptyText
        required property string muteAccessibleName
        signal levelMoved(real value)
        signal muteClicked()
        signal deviceSelected(string name)

        implicitHeight: sectionBody.implicitHeight + 20 * section.theme.shellRoot.menuScale
        color: section.theme.surface
        radius: 10 * section.theme.shellRoot.menuScale
        border.width: 1
        border.color: section.theme.outline

        ColumnLayout {
            id: sectionBody
            anchors.fill: parent
            anchors.margins: 10 * section.theme.shellRoot.menuScale
            spacing: 6 * section.theme.shellRoot.menuScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: section.icon
                    color: section.mutedState ? "#f38ba8" : section.theme.accent
                    font.family: "JetBrains Mono"
                    font.pixelSize: 17 * section.theme.fontScale
                }
                Text {
                    Layout.fillWidth: true
                    text: section.title
                    color: section.theme.foreground
                    font.family: "Noto Sans"
                    font.pixelSize: 11 * section.theme.fontScale
                    font.weight: Font.DemiBold
                }
                Text {
                    text: section.mutedState ? "Muted" : Math.round(section.level) + "%"
                    color: section.mutedState ? "#f38ba8" : section.theme.accent
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10 * section.theme.fontScale
                    font.weight: Font.DemiBold
                }
                PopupIconButton {
                    scaleFactor: section.theme.shellRoot.menuScale
                    text: section.mutedState ? "󰖁" : "󰕾"
                    foregroundColor: section.theme.foreground
                    mutedColor: section.theme.muted
                    accentColor: section.mutedState ? "#f38ba8" : section.theme.accent
                    hoverColor: section.theme.raised
                    accent: section.mutedState
                    Accessible.name: section.muteAccessibleName
                    ToolTip.visible: hovered
                    ToolTip.text: Accessible.name
                    onClicked: section.muteClicked()
                }
            }

            PopupSlider {
                scaleFactor: section.theme.shellRoot.menuScale
                Layout.fillWidth: true
                from: 0
                to: 1
                value: section.level / 100
                enabled: !section.mutedState
                trackColor: section.theme.outline
                accentColor: section.theme.accent
                handleColor: section.theme.foreground
                surfaceColor: section.theme.surface
                Accessible.name: section.title + " volume"
                Accessible.description: Math.round(section.level) + " percent"
                onMoved: section.levelMoved(value)
            }

            PopupComboBox {
                id: deviceSelector
                scaleFactor: section.theme.shellRoot.menuScale
                Layout.fillWidth: true
                model: section.devices
                textRole: "description"
                valueRole: "name"
                enabled: section.devices.length > 0 && !shellRoot.audioActionBusy
                displayText: {
                    if (section.devices.length === 0)
                        return section.emptyText
                    const selected = section.devices.find(device => device.name === section.defaultDeviceName)
                    return selected ? shellRoot.deviceLabel(selected) : shellRoot.deviceLabel(section.devices[0])
                }
                foregroundColor: section.theme.foreground
                mutedColor: section.theme.muted
                accentColor: section.theme.accent
                surfaceColor: section.theme.background
                raisedColor: section.theme.raised
                outlineColor: section.theme.outline
                Accessible.name: section.title + " device"
                onActivated: index => {
                    if (index >= 0 && index < section.devices.length)
                        section.deviceSelected(section.devices[index].name)
                }
            }
        }
    }
}
