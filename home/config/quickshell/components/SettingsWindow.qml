import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Window {
    id: window

    required property var root

    readonly property bool compactNavigation: width < 760
    readonly property color background: root.background
    readonly property color foreground: root.foreground
    readonly property color muted: root.muted
    readonly property color accent: root.accent
    readonly property color surface: root.settingsSurface
    readonly property color raised: root.settingsRaised
    readonly property color outline: root.settingsOutline
    readonly property real fontScale: root.menuFontScale

    visible: false
    title: "Settings"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    color: "transparent"
    width: {
        const screen = root.primaryScreen()
        return screen ? Math.max(1, Math.min(1040, screen.width - 32)) : 980
    }
    height: {
        const screen = root.primaryScreen()
        return screen ? Math.max(1, Math.min(720, screen.height - 48)) : 680
    }
    x: root.centerX(width)
    y: root.centerY(height)

    onVisibleChanged: if (visible) requestActivate()

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: window.visible = false
    }

    component UiText: Text {
        color: window.foreground
        font.family: "Noto Sans"
        font.pixelSize: 11 * window.fontScale
        verticalAlignment: Text.AlignVCenter
    }

    component DataText: Text {
        color: window.muted
        font.family: "JetBrains Mono"
        font.pixelSize: 9 * window.fontScale
        verticalAlignment: Text.AlignVCenter
    }

    component UiButton: Button {
        id: control
        property bool primary: false

        implicitHeight: 36
        leftPadding: 13
        rightPadding: 13
        contentItem: Text {
            text: control.text
            color: !control.enabled ? window.muted
                : control.primary ? window.background : window.foreground
            font.family: "JetBrains Mono"
            font.pixelSize: 9 * window.fontScale
            font.weight: control.primary ? Font.DemiBold : Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 9
            color: !control.enabled ? Qt.rgba(window.raised.r, window.raised.g, window.raised.b, 0.35)
                : control.primary ? (control.down ? Qt.darker(window.accent, 1.12) : window.accent)
                : control.down ? Qt.lighter(window.raised, 1.12)
                : control.hovered ? window.raised : Qt.rgba(window.surface.r, window.surface.g, window.surface.b, 0.55)
            border.width: 1
            border.color: control.activeFocus ? window.accent : window.outline
        }
    }

    component UiSlider: Slider {
        id: control
        implicitHeight: 32
        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            width: control.availableWidth
            height: 4
            radius: 2
            color: window.outline
            Rectangle {
                width: parent.width * control.visualPosition
                height: parent.height
                radius: parent.radius
                color: control.enabled ? window.accent : window.muted
            }
        }
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            implicitWidth: 18
            implicitHeight: 18
            radius: 9
            color: control.pressed ? window.foreground : window.accent
            border.width: 3
            border.color: window.surface
        }
    }

    component UiSwitch: Switch {
        id: control
        implicitWidth: 46
        implicitHeight: 32
        indicator: Rectangle {
            x: control.width - width
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: 42
            implicitHeight: 24
            radius: 12
            color: control.checked ? window.accent : window.outline
            border.width: control.activeFocus ? 1 : 0
            border.color: window.foreground
            Rectangle {
                x: control.checked ? parent.width - width - 4 : 4
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                radius: 8
                color: control.checked ? window.background : window.muted
                Behavior on x { NumberAnimation { duration: 110 } }
            }
        }
        contentItem: Item {}
    }

    component UiCombo: ComboBox {
        id: control
        implicitHeight: 36
        implicitWidth: 180
        leftPadding: 12
        rightPadding: 32
        contentItem: DataText {
            text: control.displayText
            color: window.foreground
            elide: Text.ElideRight
        }
        indicator: DataText {
            x: control.width - width - 11
            anchors.verticalCenter: parent.verticalCenter
            text: "󰅀"
            color: window.accent
            font.pixelSize: 12
        }
        background: Rectangle {
            radius: 9
            color: control.hovered ? window.raised : window.surface
            border.width: 1
            border.color: control.activeFocus ? window.accent : window.outline
        }
        delegate: ItemDelegate {
            required property var modelData
            width: control.width
            height: 34
            contentItem: DataText {
                text: control.textRole ? modelData[control.textRole] : modelData
                color: highlighted ? window.background : window.foreground
                elide: Text.ElideRight
            }
            background: Rectangle {
                color: highlighted ? window.accent : (hovered ? window.raised : window.surface)
            }
        }
        popup: Popup {
            y: control.height + 4
            width: control.width
            implicitHeight: Math.min(contentItem.implicitHeight + 8, 260)
            padding: 4
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.popup.visible ? control.delegateModel : null
                currentIndex: control.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator {}
            }
            background: Rectangle {
                color: window.surface
                border.width: 1
                border.color: window.outline
                radius: 9
            }
        }
    }

    component SettingsCard: Rectangle {
        default property alias contents: body.data
        implicitHeight: body.implicitHeight + 28
        color: window.surface
        border.width: 1
        border.color: window.outline
        radius: 12
        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
        }
    }

    component PageHeader: ColumnLayout {
        property string title
        property string description
        spacing: 3
        UiText {
            text: parent.title
            font.pixelSize: 22 * window.fontScale
            font.weight: Font.DemiBold
        }
        DataText {
            Layout.fillWidth: true
            text: parent.description
            color: window.muted
            wrapMode: Text.Wrap
        }
    }

    component EmptyState: Rectangle {
        property string message: "Nothing here"
        implicitHeight: 76
        color: "transparent"
        border.width: 1
        border.color: window.outline
        radius: 10
        DataText {
            anchors.centerIn: parent
            width: parent.width - 24
            text: parent.message
            color: window.muted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    component PageScroll: ScrollView {
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
    }

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: window.background
        border.width: 1
        border.color: window.outline
        clip: true

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            color: window.accent
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14

            Rectangle {
                Layout.preferredWidth: window.compactNavigation ? 62 : 214
                Layout.fillHeight: true
                color: window.surface
                border.width: 1
                border.color: window.outline
                radius: 13

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        UiText {
                            visible: !window.compactNavigation
                            Layout.fillWidth: true
                            text: "SETTINGS"
                            font.pixelSize: 15 * window.fontScale
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.4
                        }
                        UiButton {
                            Layout.preferredWidth: 38
                            text: "×"
                            onClicked: window.visible = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        Layout.bottomMargin: 5
                        color: window.outline
                    }

                    Repeater {
                        model: [
                            { icon: "󰕾", label: "Audio", page: "Audio" },
                            { icon: "󰤨", label: "Network", page: "Network" },
                            { icon: "󰂯", label: "Bluetooth", page: "Bluetooth" },
                            { icon: "󰍹", label: "Displays", page: "Displays" },
                            { icon: "󰏘", label: "Appearance", page: "Appearance" },
                            { icon: "󰐥", label: "Session", page: "Session" }
                        ]
                        delegate: Button {
                            id: navButton
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 44
                            ToolTip.visible: window.compactNavigation && hovered
                            ToolTip.text: modelData.label
                            onClicked: root.selectSettingsPage(modelData.page)
                            contentItem: RowLayout {
                                spacing: 11
                                DataText {
                                    Layout.preferredWidth: window.compactNavigation ? 40 : 24
                                    text: navButton.modelData.icon
                                    color: root.settingsPage === navButton.modelData.page ? window.background : window.accent
                                    font.pixelSize: 16
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                UiText {
                                    visible: !window.compactNavigation
                                    Layout.fillWidth: true
                                    text: navButton.modelData.label
                                    color: root.settingsPage === navButton.modelData.page ? window.background : window.foreground
                                    font.weight: root.settingsPage === navButton.modelData.page ? Font.DemiBold : Font.Normal
                                }
                            }
                            background: Rectangle {
                                radius: 10
                                color: root.settingsPage === navButton.modelData.page ? window.accent
                                    : navButton.hovered ? window.raised : "transparent"
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    UiButton {
                        Layout.fillWidth: true
                        text: window.compactNavigation ? "󰸉" : "󰸉  Wallpaper"
                        ToolTip.visible: window.compactNavigation && hovered
                        ToolTip.text: "Wallpaper"
                        onClicked: root.openWallpaperViewer()
                    }
                    UiButton {
                        Layout.fillWidth: true
                        text: window.compactNavigation ? "󰄀" : "󰄀  Screenshot"
                        ToolTip.visible: window.compactNavigation && hovered
                        ToolTip.text: "Screenshot"
                        onClicked: root.openScreenshotMenu()
                    }
                    DataText {
                        visible: !window.compactNavigation
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 3
                        text: "ESC  CLOSE"
                        font.pixelSize: 8
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.settingsPage === "Network" ? 1
                    : root.settingsPage === "Bluetooth" ? 2
                    : root.settingsPage === "Displays" ? 3
                    : root.settingsPage === "Appearance" ? 4
                    : root.settingsPage === "Session" ? 5 : 0

                PageScroll {
                    id: audioPage
                    ColumnLayout {
                        width: audioPage.availableWidth
                        spacing: 12
                        PageHeader {
                            Layout.fillWidth: true
                            title: "Sound"
                            description: "Volume, mute state, and default PipeWire devices."
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Item { Layout.fillWidth: true }
                            UiButton {
                                text: root.audioSinksLoading || root.audioSourcesLoading ? "Refreshing..." : "󰑐  Refresh devices"
                                enabled: !root.audioSinksLoading && !root.audioSourcesLoading
                                onClicked: root.refreshAudioDevices()
                            }
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: audioPage.availableWidth < 610 ? 1 : 2
                            columnSpacing: 10
                            rowSpacing: 10
                            SettingsCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 130
                                RowLayout {
                                    Layout.fillWidth: true
                                    DataText { text: root.outputMuted ? "󰝟  OUTPUT MUTED" : "󰕾  OUTPUT"; color: window.accent; font.weight: Font.DemiBold }
                                    Item { Layout.fillWidth: true }
                                    UiButton { text: root.outputMuted ? "Unmute" : "Mute"; onClicked: root.toggleOutputMute() }
                                }
                                DataText { Layout.fillWidth: true; text: Math.round(root.volumeLevel) + "%  /  " + root.audioDetail; elide: Text.ElideMiddle }
                                UiSlider { Layout.fillWidth: true; from: 0; to: 1; value: root.volumeLevel / 100; onMoved: root.setVolume(value) }
                            }
                            SettingsCard {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 130
                                RowLayout {
                                    Layout.fillWidth: true
                                    DataText { text: root.micMuted ? "󰍭  MICROPHONE MUTED" : "󰍬  MICROPHONE"; color: window.accent; font.weight: Font.DemiBold }
                                    Item { Layout.fillWidth: true }
                                    UiButton { text: root.micMuted ? "Unmute" : "Mute"; onClicked: root.toggleMicMute() }
                                }
                                DataText { Layout.fillWidth: true; text: Math.round(root.micVolumeLevel) + "%  /  " + root.micName; elide: Text.ElideMiddle }
                                UiSlider { Layout.fillWidth: true; from: 0; to: 1; value: root.micVolumeLevel / 100; onMoved: root.setMicVolume(value) }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            DataText { text: "DEFAULT DEVICES"; color: window.accent; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            UiButton { text: "󰓃  Open Wiremix"; onClicked: root.run(["wezterm", "-e", "wiremix"]) }
                        }
                        DataText { text: "OUTPUT" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: root.audioSinks
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 44
                                    radius: 10
                                    color: modelData.name === root.defaultSinkName ? window.raised : window.surface
                                    border.width: 1
                                    border.color: modelData.name === root.defaultSinkName ? window.accent : window.outline
                                    DataText {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        text: (parent.modelData.name === root.defaultSinkName ? "●  " : "○  ") + root.deviceLabel(parent.modelData)
                                        color: window.foreground
                                        elide: Text.ElideRight
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setDefaultSink(parent.modelData.name) }
                                }
                            }
                            EmptyState {
                                Layout.fillWidth: true
                                visible: root.audioSinks.length === 0
                                message: root.audioSinksLoading ? "Loading output devices..." : (root.audioSinksError || "No output devices found")
                            }
                        }
                        DataText { text: "MICROPHONE" }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: root.audioSources
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 44
                                    radius: 10
                                    color: modelData.name === root.defaultSourceName ? window.raised : window.surface
                                    border.width: 1
                                    border.color: modelData.name === root.defaultSourceName ? window.accent : window.outline
                                    DataText {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        text: (parent.modelData.name === root.defaultSourceName ? "●  " : "○  ") + root.deviceLabel(parent.modelData)
                                        color: window.foreground
                                        elide: Text.ElideRight
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setDefaultSource(parent.modelData.name) }
                                }
                            }
                            EmptyState {
                                Layout.fillWidth: true
                                visible: root.audioSources.length === 0
                                message: root.audioSourcesLoading ? "Loading microphones..." : (root.audioSourcesError || "No microphones found")
                            }
                        }
                        Item { Layout.preferredHeight: 2 }
                    }
                }

                PageScroll {
                    id: networkPage
                    ColumnLayout {
                        width: networkPage.availableWidth
                        spacing: 12
                        RowLayout {
                            Layout.fillWidth: true
                            PageHeader { Layout.fillWidth: true; title: "Network"; description: "Connectivity, wireless devices, and private networks." }
                            UiButton { text: "󰑐  Refresh"; onClicked: root.scanNetworks() }
                        }
                        SettingsCard {
                            Layout.fillWidth: true
                            DataText { text: "CURRENT CONNECTION"; color: window.accent; font.weight: Font.DemiBold }
                            UiText { Layout.fillWidth: true; text: root.networkDetail || "Disconnected"; font.pixelSize: 16 * window.fontScale; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: networkPage.availableWidth < 560 ? 1 : 2
                                DataText { Layout.fillWidth: true; text: "INTERFACE  " + (root.networkInterface || "unavailable") }
                                DataText { Layout.fillWidth: true; text: "ADDRESS    " + (root.networkIp || "unavailable") }
                                DataText { Layout.fillWidth: true; text: "↓ DOWN     " + root.networkDownloadMbps.toFixed(2) + " Mbps"; color: window.foreground }
                                DataText { Layout.fillWidth: true; text: "↑ UP       " + root.networkUploadMbps.toFixed(2) + " Mbps"; color: window.foreground }
                            }
                        }

                        SettingsCard {
                            Layout.fillWidth: true
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    UiText { text: "Wi-Fi"; font.weight: Font.DemiBold }
                                    DataText {
                                        text: !root.wifiAvailable ? "No wireless adapter detected"
                                            : root.wifiEnabled ? "Enabled on " + root.wifiDevice : "Radio disabled"
                                        color: root.wifiAvailable && root.wifiEnabled ? window.accent : window.muted
                                    }
                                }
                                UiSwitch {
                                    visible: root.wifiAvailable
                                    checked: root.wifiEnabled
                                    onToggled: root.setWifiEnabled(checked)
                                }
                            }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: window.outline }
                            RowLayout {
                                Layout.fillWidth: true
                                DataText { text: "AVAILABLE NETWORKS"; color: window.accent; font.weight: Font.DemiBold }
                                Item { Layout.fillWidth: true }
                                UiButton { text: "Open nmtui"; onClicked: root.run(["wezterm", "-e", "nmtui"]) }
                                UiButton {
                                    text: root.networkScanning ? "Scanning..." : "󰑐  Scan"
                                    enabled: root.wifiAvailable && root.wifiEnabled && !root.networkScanning
                                    onClicked: root.scanNetworks()
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Repeater {
                                    model: root.networkDevices
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        implicitHeight: 46
                                        radius: 10
                                        color: modelData.active ? window.raised : Qt.rgba(window.raised.r, window.raised.g, window.raised.b, 0.35)
                                        border.width: 1
                                        border.color: modelData.active ? window.accent : window.outline
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 11
                                            DataText { text: parent.parent.modelData.active ? "●" : "○"; color: parent.parent.modelData.active ? window.accent : window.muted }
                                            UiText { Layout.fillWidth: true; text: parent.parent.modelData.ssid; elide: Text.ElideRight }
                                            DataText { text: parent.parent.modelData.signal + "%  " + parent.parent.modelData.security }
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.connectNetwork(parent.modelData.ssid) }
                                    }
                                }
                                EmptyState {
                                    Layout.fillWidth: true
                                    visible: root.networkDevices.length === 0
                                    message: !root.wifiAvailable ? "This system has no Wi-Fi adapter. Wired networking and VPN controls remain available."
                                        : !root.wifiEnabled ? "Enable Wi-Fi to scan for networks."
                                        : root.networkScanning ? "Scanning for wireless networks..." : "No wireless networks found."
                                }
                            }
                        }

                        DataText { text: "PRIVATE NETWORKS"; color: window.accent; font.weight: Font.DemiBold; Layout.topMargin: 4 }
                        SettingsCard {
                            Layout.fillWidth: true
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    UiText { text: "Tailscale"; font.weight: Font.DemiBold }
                                    DataText { text: root.tailscaleState + "  ·  " + root.tailscaleNodes.length + " peers"; color: root.tailscaleState === "Running" ? "#a6e3a1" : window.muted }
                                }
                                UiButton { text: "󰑐"; ToolTip.visible: hovered; ToolTip.text: "Refresh VPN status"; onClicked: root.refreshVpnSettings() }
                                UiSwitch { checked: root.tailscaleState === "Running"; onToggled: root.setTailscaleEnabled(checked) }
                            }
                            GridLayout {
                                Layout.fillWidth: true
                                columns: networkPage.availableWidth < 560 ? 1 : 2
                                DataText { Layout.fillWidth: true; text: "PUBLIC IP  " + (root.publicIp || "unavailable") }
                                DataText { Layout.fillWidth: true; text: "EXIT NODE  " + (root.activeExitNodeName || "Direct connection") }
                                DataText { Layout.fillWidth: true; text: "SUGGESTED  " + (root.bestExitNode || "unavailable") }
                                DataText { Layout.fillWidth: true; text: "TAILNET    " + root.tailscaleNodes.filter(node => node.online).length + " online" }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            DataText { text: "MULLVAD EXIT NODES"; color: window.accent; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            UiButton { text: "Use direct connection"; enabled: root.activeExitNodeAddress.length > 0; onClicked: root.clearExitNode() }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: root.exitNodes
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 46
                                    radius: 10
                                    color: modelData.address === root.activeExitNodeAddress ? window.raised : window.surface
                                    border.width: 1
                                    border.color: modelData.address === root.activeExitNodeAddress ? window.accent : window.outline
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 11
                                        DataText { text: parent.parent.modelData.address === root.activeExitNodeAddress ? "●" : "○"; color: parent.parent.modelData.address === root.activeExitNodeAddress ? window.accent : window.muted }
                                        UiText { Layout.fillWidth: true; text: parent.parent.modelData.name; elide: Text.ElideRight }
                                        DataText { text: parent.parent.modelData.online ? "ONLINE" : "OFFLINE"; color: parent.parent.modelData.online ? "#a6e3a1" : window.muted }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; enabled: parent.modelData.online; onClicked: root.selectExitNode(parent.modelData.address) }
                                }
                            }
                            EmptyState { Layout.fillWidth: true; visible: root.exitNodes.length === 0; message: "No Mullvad exit nodes are available for this tailnet." }
                        }

                        DataText { text: "TAILSCALE PEERS"; color: window.accent; font.weight: Font.DemiBold }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: root.tailscaleNodes
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 46
                                    radius: 10
                                    color: window.surface
                                    border.width: 1
                                    border.color: window.outline
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 11
                                        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 8; radius: 4; color: parent.parent.modelData.online ? "#a6e3a1" : window.muted }
                                        UiText { Layout.fillWidth: true; text: parent.parent.modelData.name; elide: Text.ElideRight }
                                        DataText { text: parent.parent.modelData.address; color: window.accent }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.copyTailscaleAddress(parent.modelData.address) }
                                }
                            }
                            EmptyState { Layout.fillWidth: true; visible: root.tailscaleNodes.length === 0; message: "No Tailscale peers found." }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            DataText { text: "NETWORKMANAGER VPN PROFILES"; color: window.accent; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            DataText { text: root.vpnProfiles.length + " configured" }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: root.vpnProfiles
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 48
                                    radius: 10
                                    color: modelData.active ? window.raised : window.surface
                                    border.width: 1
                                    border.color: modelData.active ? window.accent : window.outline
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 11
                                        DataText { text: "󰖂"; color: parent.parent.modelData.active ? window.accent : window.muted; font.pixelSize: 15 }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            UiText { text: parent.parent.parent.modelData.name; font.weight: Font.DemiBold }
                                            DataText { text: parent.parent.parent.modelData.type + (parent.parent.parent.modelData.active ? "  ·  " + parent.parent.parent.modelData.device : "") }
                                        }
                                        UiButton { text: parent.parent.modelData.active ? "Disconnect" : "Connect"; onClicked: root.toggleVpnProfile(parent.parent.modelData.name, parent.parent.modelData.active) }
                                    }
                                }
                            }
                            EmptyState { Layout.fillWidth: true; visible: root.vpnProfiles.length === 0; message: "No NetworkManager VPN or WireGuard profiles configured." }
                        }
                        Item { Layout.preferredHeight: 2 }
                    }
                }

                PageScroll {
                    id: bluetoothPage
                    ColumnLayout {
                        width: bluetoothPage.availableWidth
                        spacing: 12
                        PageHeader { Layout.fillWidth: true; title: "Bluetooth"; description: "Discover nearby devices and hand off pairing to bluetui." }
                        SettingsCard {
                            Layout.fillWidth: true
                            DataText { text: "STATUS"; color: window.accent; font.weight: Font.DemiBold }
                            UiText { Layout.fillWidth: true; text: root.bluetoothDetail || "No connected devices"; font.pixelSize: 16 * window.fontScale; font.weight: Font.DemiBold; wrapMode: Text.Wrap }
                            DataText { Layout.fillWidth: true; text: "Select a device to connect. Use bluetui to pair or remove devices."; wrapMode: Text.Wrap }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            DataText { text: "NEARBY DEVICES"; color: window.accent; font.weight: Font.DemiBold }
                            Item { Layout.fillWidth: true }
                            UiButton { text: "Open bluetui"; onClicked: root.run(["wezterm", "-e", "bluetui"]) }
                            UiButton { text: root.bluetoothScanning ? "Scanning..." : "󰑐  Scan"; enabled: !root.bluetoothScanning; onClicked: root.refreshBluetoothDevices() }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            Repeater {
                                model: root.bluetoothDevices
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 52
                                    radius: 10
                                    color: window.surface
                                    border.width: 1
                                    border.color: window.outline
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 11
                                        DataText { text: "󰂯"; color: window.accent; font.pixelSize: 16 }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            UiText { Layout.fillWidth: true; text: parent.parent.parent.modelData.name || "Unknown device"; elide: Text.ElideRight }
                                            DataText { text: parent.parent.parent.modelData.address }
                                        }
                                        DataText { text: "CONNECT  ›"; color: window.accent }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.connectBluetooth(parent.modelData.address) }
                                }
                            }
                            EmptyState {
                                Layout.fillWidth: true
                                visible: root.bluetoothDevices.length === 0
                                message: root.bluetoothScanning ? "Scanning for Bluetooth devices..." : "No Bluetooth devices found"
                            }
                        }
                        Item { Layout.preferredHeight: 2 }
                    }
                }

                PageScroll {
                    id: displaysPage
                    ColumnLayout {
                        width: displaysPage.availableWidth
                        spacing: 12
                        PageHeader { Layout.fillWidth: true; title: "Displays"; description: "Choose the primary monitor and configure connected outputs." }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Repeater {
                                model: root.displays
                                delegate: SettingsCard {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    border.color: modelData.primary ? window.accent : window.outline
                                    RowLayout {
                                        Layout.fillWidth: true
                                        DataText { text: modelData.primary ? "󰍹" : "󰹙"; color: modelData.primary ? window.accent : window.muted; font.pixelSize: 22 }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            UiText { Layout.fillWidth: true; text: modelData.name + (modelData.primary ? "  ·  Primary" : ""); font.weight: Font.DemiBold; elide: Text.ElideRight }
                                            DataText { text: modelData.mode + "  /  " + modelData.refresh + " Hz" }
                                        }
                                    }
                                    GridLayout {
                                        Layout.fillWidth: true
                                        columns: displaysPage.availableWidth < 550 ? 1 : 2
                                        columnSpacing: 8
                                        rowSpacing: 8
                                        UiButton {
                                            Layout.fillWidth: true
                                            text: modelData.primary ? "Primary display" : "Set as primary"
                                            enabled: !modelData.primary
                                            onClicked: root.setPrimaryDisplay(modelData.name)
                                        }
                                        UiCombo {
                                            Layout.fillWidth: true
                                            model: modelData.modes
                                            textRole: "label"
                                            currentIndex: Math.max(0, modelData.modes.findIndex(option => option.selected))
                                            onActivated: index => {
                                                const option = modelData.modes[index]
                                                root.setDisplayMode(modelData.name, option.mode, option.refresh)
                                            }
                                        }
                                    }
                                }
                            }
                            EmptyState { Layout.fillWidth: true; visible: root.displays.length === 0; message: "No connected displays found" }
                        }
                        Item { Layout.preferredHeight: 2 }
                    }
                }

                PageScroll {
                    id: appearancePage
                    ColumnLayout {
                        width: appearancePage.availableWidth
                        spacing: 12
                        PageHeader { Layout.fillWidth: true; title: "Appearance"; description: "Choose toolkit themes and Quickshell interface density." }
                        SettingsCard {
                            Layout.fillWidth: true
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    UiText { text: "GTK theme"; font.weight: Font.DemiBold }
                                    DataText { text: "GTK 3 applications and toolkit chrome" }
                                }
                                UiCombo {
                                    model: root.gtkThemes
                                    currentIndex: Math.max(0, model.indexOf(root.currentGtkTheme))
                                    onActivated: root.setGtkTheme(currentText)
                                }
                            }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: window.outline }
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    UiText { text: "Icon theme"; font.weight: Font.DemiBold }
                                    DataText { text: "Used by GTK applications" }
                                }
                                UiCombo {
                                    model: ["Papirus-Dark", "Papirus", "Adwaita", "hicolor"]
                                    currentIndex: Math.max(0, model.indexOf(root.currentIconTheme))
                                    onActivated: root.setIconTheme(currentText)
                                }
                            }
                        }
                        SettingsCard {
                            Layout.fillWidth: true
                            DataText { text: "QUICKSHELL INTERFACE"; color: window.accent; font.weight: Font.DemiBold }
                            RowLayout {
                                Layout.fillWidth: true
                                UiText { text: "Panel height" }
                                Item { Layout.fillWidth: true }
                                DataText { text: root.panelHeight + " px"; color: window.accent }
                            }
                            UiSlider { Layout.fillWidth: true; from: 24; to: 48; stepSize: 1; value: root.panelHeight; onMoved: root.setPanelHeight(value) }
                            RowLayout {
                                Layout.fillWidth: true
                                UiText { text: "Text scale" }
                                Item { Layout.fillWidth: true }
                                DataText { text: root.menuFontScale.toFixed(1) + "x"; color: window.accent }
                            }
                            UiSlider { Layout.fillWidth: true; from: 0.9; to: 1.5; stepSize: 0.1; value: root.menuFontScale; onMoved: root.setMenuFontScale(value) }
                        }
                        DataText { Layout.fillWidth: true; text: "BSPWM gaps, borders, and compositor behavior remain managed by their configuration files."; wrapMode: Text.Wrap }
                        Item { Layout.preferredHeight: 2 }
                    }
                }

                PageScroll {
                    id: sessionPage
                    ColumnLayout {
                        width: sessionPage.availableWidth
                        spacing: 12
                        PageHeader { Layout.fillWidth: true; title: "Session"; description: "Power controls and local hardware preferences." }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: sessionPage.availableWidth < 580 ? 1 : 3
                            columnSpacing: 8
                            rowSpacing: 8
                            UiButton { Layout.fillWidth: true; Layout.preferredHeight: 56; text: "󰌾  Lock"; onClicked: root.lockScreen() }
                            UiButton { Layout.fillWidth: true; Layout.preferredHeight: 56; text: "󰑓  Reload desktop"; onClicked: root.run(["sh", "-c", "$HOME/.config/bspwm/scripts/reload.sh"]) }
                            UiButton { Layout.fillWidth: true; Layout.preferredHeight: 56; text: "󰐥  Power options"; primary: true; onClicked: root.openPowerMenu() }
                        }
                        SettingsCard {
                            Layout.fillWidth: true
                            DataText { text: "HARDWARE"; color: window.accent; font.weight: Font.DemiBold }
                            RowLayout {
                                Layout.fillWidth: true
                                UiText { text: "Brightness" }
                                Item { Layout.fillWidth: true }
                                DataText { text: root.brightnessAvailable ? Math.round(root.brightnessLevel) + "%" : "Unavailable"; color: root.brightnessAvailable ? window.accent : window.muted }
                            }
                            UiSlider { Layout.fillWidth: true; enabled: root.brightnessAvailable; opacity: enabled ? 1 : 0.4; from: 5; to: 100; value: root.brightnessLevel; onMoved: root.setBrightness(value) }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: window.outline }
                            RowLayout {
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    UiText { text: "Touchpad" }
                                    DataText { text: root.touchpadAvailable ? (root.touchpadEnabled ? "Enabled" : "Disabled") : "Unavailable" }
                                }
                                UiSwitch { visible: root.touchpadAvailable; checked: root.touchpadEnabled; onToggled: root.toggleTouchpad(checked) }
                            }
                        }
                        SettingsCard {
                            Layout.fillWidth: true
                            DataText { text: "KEYBOARD REPEAT"; color: window.accent; font.weight: Font.DemiBold }
                            RowLayout {
                                Layout.fillWidth: true
                                UiText { text: "Delay" }
                                Item { Layout.fillWidth: true }
                                DataText { text: root.keyboardRepeatDelay + " ms" }
                            }
                            UiSlider { Layout.fillWidth: true; from: 150; to: 1000; stepSize: 10; value: root.keyboardRepeatDelay; onMoved: root.setKeyboardRepeat(value, root.keyboardRepeatRate) }
                            RowLayout {
                                Layout.fillWidth: true
                                UiText { text: "Rate" }
                                Item { Layout.fillWidth: true }
                                DataText { text: root.keyboardRepeatRate + " / sec" }
                            }
                            UiSlider { Layout.fillWidth: true; from: 10; to: 60; stepSize: 1; value: root.keyboardRepeatRate; onMoved: root.setKeyboardRepeat(root.keyboardRepeatDelay, value) }
                        }
                        Item { Layout.preferredHeight: 2 }
                    }
                }
            }
        }
    }
}
