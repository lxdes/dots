//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import Quickshell.Services.Polkit
import Quickshell.Services.Mpris
import "components"

ShellRoot {
    id: root
    property color background: "#0e0e12"
    property color foreground: "#cbd0ec"
    property color muted: "#6c7086"
    property color empty: "#414456"
    property color accent: "#bfc9f4"
    property color highlight: "#cba6f7"
    readonly property color settingsSurface: Qt.darker(background, 0.82)
    readonly property color settingsRaised: Qt.lighter(settingsSurface, 1.16)
    readonly property color settingsOutline: Qt.lighter(background, 1.34)
    property real menuScale: 1.0
    Behavior on menuScale {
        enabled: !root.reducedMotion
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    readonly property string configDirectory: {
        let directory = String(Quickshell.shellDir || "")
        if (directory.startsWith("file://"))
            directory = directory.slice(7)
        return directory
    }
    property real menuFontScale: 1.2
    Behavior on menuFontScale {
        enabled: !root.reducedMotion
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    property alias uiFontScale: root.menuFontScale
    readonly property real displayFontScale: menuFontScale / 1.2
    property int panelHeight: 32
    readonly property int effectivePanelHeight: Math.round(panelHeight * menuScale)
    property bool reducedMotion: false
    property string currentIconTheme: "Papirus-Dark"
    property string currentGtkTheme: "Adwaita"
    property var gtkThemes: ["Adwaita", "Adwaita-dark"]

    property string activeDesktop: WmState.activeDesktop || "1"
    property bool quickNoteCentered: false
    property string activeTitle: WmState.activeTitle
    readonly property var defaultSinkAudio: audioService.defaultSinkAudio
    readonly property var defaultSourceAudio: audioService.defaultSourceAudio
    readonly property string audioStatus: outputMuted ? "" : (volumeLevel < 33 ? "" : (volumeLevel < 67 ? "" : ""))
    property string networkStatus: ""
    property string bluetoothStatus: ""
    property string audioDetail: "Default sink"
    property string networkDetail: "Disconnected"
    property string bluetoothDetail: "No connected devices"
    property var currentPlayer: {
        const players = Mpris.players.values
        for (const player of players) {
            if (player && player.isPlaying)
                return player
        }
        return players.length > 0 ? players[0] : null
    }
    property var wallpapers: []
    property string selectedWallpaper: ""
    property string settingsPage: "Audio"
    property string bspLayout: "tiled"
    property bool layoutActionBusy: false
    property string layoutActionError: ""
    property real volumeLevel: audioService.outputLevel
    property real pendingVolumeLevel: 50
    property bool volumeAdjusting: false
    property bool launcherVisible: false
    property string tailscaleState: "Stopped"
    property var tailscaleNodes: []
    property var exitNodes: []
    property string bestExitNode: ""
    property string activeExitNodeName: ""
    property string activeExitNodeAddress: ""
    property real lastWallpaperUpdate: 0
    property real lastTailscaleUpdate: 0
    property real lastExitConfigUpdate: 0
    property real lastPublicIpUpdate: 0
    property real lastAudioSinksUpdate: 0
    property real lastAudioSourcesUpdate: 0
    property real lastNetworkDevicesUpdate: 0
    property real lastBluetoothUpdate: 0
    property real lastBatteryUpdate: 0
    property real lastActiveWindowUpdate: 0
    property real lastDisplayUpdate: 0
    property real lastAgendaUpdate: 0
    property real lastPrivacyUpdate: 0
    property real lastMetricsUpdate: 0
    property real lastNetworkMetricsUpdate: 0
    property string publicIp: ""
    property string networkInterface: ""
    property string networkType: ""
    property int networkSignal: -1
    property string networkIp: ""
    property double networkDownloadMbps: 0
    property double networkUploadMbps: 0
    property double previousRxBytes: -1
    property double previousTxBytes: -1
    property double previousNetworkSampleMs: 0
    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property string wifiDevice: ""
    property var vpnProfiles: []
    property real micVolumeLevel: audioService.inputLevel
    property real pendingMicVolumeLevel: 0
    property bool micVolumeAdjusting: false
    property bool micMuted: audioService.inputMuted
    property bool outputMuted: audioService.outputMuted
    property string micName: "Default microphone"
    property var audioSinks: []
    property var audioSources: []
    property bool audioSinksLoading: false
    property bool audioSourcesLoading: false
    property string audioSinksError: ""
    property string audioSourcesError: ""
    property bool audioActionBusy: false
    property string audioActionError: ""
    property var bluetoothDevices: []
    property var networkDevices: []
    property var wifiProfiles: ({})
    property var displays: []
    property string primaryDisplayName: ""
    property bool bluetoothScanning: false
    property bool bluetoothPopupExplicitlyOpened: false
    property bool networkScanning: false
    property string defaultSinkName: ""
    property string defaultSourceName: ""
    property var workspaceStates: WmState.workspaces
    property int batteryCapacity: -1
    property string batteryStatus: ""
    property real brightnessLevel: 60
    property bool brightnessAvailable: false
    property bool touchpadEnabled: true
    property bool touchpadAvailable: false
    property int keyboardRepeatDelay: 300
    property int keyboardRepeatRate: 40
    property var toastNotification: null
    property var toastRetainedNotification: null
    property var notificationQueue: []
    property var notificationTimes: ({})
    property bool toastClearing: false
    property bool doNotDisturb: false
    readonly property var powerActions: [
        { icon: "󰗼", label: "Logout", command: ["bspc", "quit"] },
        { icon: "󰐥", label: "Shutdown", command: ["systemctl", "poweroff"] },
        { icon: "󰜉", label: "Reboot", command: ["systemctl", "reboot"] },
        { icon: "󰅖", label: "Cancel", command: null }
    ]
    property int powerIndex: 0
    property int screenshotIndex: 0
    readonly property var screenshotActions: [
        { icon: "󰍹", label: "Fullscreen", mode: "fullscreen" },
        { icon: "󰩭", label: "Region", mode: "region" },
        { icon: "󰖯", label: "Window", mode: "window" },
        { icon: "󰅖", label: "Cancel", mode: "" }
    ]
    property int calendarYear: new Date().getFullYear()
    property int calendarMonth: new Date().getMonth()
    property string activeWindowId: ""
    property string pendingActiveWindowId: ""
    property bool popupsReady: false
    property bool noteSaving: false
    property string noteSaveError: ""
    property string pendingNoteContent: ""
    property bool networkActionBusy: false
    property string networkActionError: ""
    property bool bluetoothActionBusy: false
    property string bluetoothActionError: ""
    property bool bluetoothAvailable: false
    property bool bluetoothEnabled: false
    property bool displayActionBusy: false
    property string displayActionError: ""
    property string displayRollbackScript: ""
    property bool displayRefreshAfterCurrent: false
    property bool displayRefreshPending: false
    property int pendingPowerIndex: -1
    property bool agendaConfigured: false
    property string agendaError: ""
    property var agendaEvents: []
    property bool microphoneActive: false
    property bool recordingActive: false
    property bool screenShareActive: false
    property real cpuPercent: -1
    property real memoryPercent: -1
    property real temperatureC: -1
    property real gpuPercent: -1
    property string powerProfile: "unknown"
    property string operationErrorTitle: ""
    property string operationErrorMessage: ""

    onLayoutActionErrorChanged: if (layoutActionError.length > 0) showOperationError("Layout operation failed", layoutActionError)
    onAudioActionErrorChanged: if (audioActionError.length > 0) showOperationError("Audio operation failed", audioActionError)
    onNetworkActionErrorChanged: if (networkActionError.length > 0) showOperationError("Network operation failed", networkActionError)
    onBluetoothActionErrorChanged: if (bluetoothActionError.length > 0) showOperationError("Bluetooth operation failed", bluetoothActionError)
    onDisplayActionErrorChanged: if (displayActionError.length > 0) showOperationError("Display operation failed", displayActionError)

    Component.onCompleted: {
        popupsReady = true
        bluetoothStatus = "󰂯"
        refreshDisplays()
        run(["bspc", "rule", "-r", "Launcher"])
        run(["bspc", "rule", "-a", "Launcher", "state=floating", "center=true"])
    }

    NotificationServer {
        id: notificationServer
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: notification => {
            notification.tracked = true
            const times = Object.assign({}, root.notificationTimes)
            times[notification.id] = Date.now()
            root.notificationTimes = times
            if (!root.doNotDisturb || notification.urgency === 2)
                root.showNotificationToast(notification)
            Qt.callLater(root.pruneNotifications)
        }
    }

    AudioService {
        id: audioService
    }

    PolkitAgent {
        id: polkitAgent
    }

    RetainableLock {
        id: toastNotificationLock
        object: root.toastRetainedNotification
        locked: object !== null
    }

    Connections {
        target: root.toastRetainedNotification
        function onClosed() {
            if (!root.toastClearing)
                root.finishNotificationToast()
        }
    }

    function updateBspwm(output) {
        root.lastMetricsUpdate = Date.now()
        const fields = output.split("\n").map(field => field.trim())
        if (fields.length > 0 && fields[0].length > 0)
            activeDesktop = fields[0]
    }

    function showNotificationToast(notification) {
        if (toastNotification) {
            notificationQueue = notificationQueue.concat([notificationSnapshot(notification, false)])
            return
        }
        toastRetainedNotification = notification
        toastNotification = notificationSnapshot(notification, true)
        displayNotificationToast()
    }

    function notificationSnapshot(notification, includeActions) {
        return {
            id: notification.id,
            appName: notification.appName || "Notification",
            summary: notification.summary || "",
            body: notification.body || "",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            urgency: notification.urgency,
            receivedAt: notificationTimes[notification.id] || Date.now(),
            expireTimeout: notification.expireTimeout,
            actions: includeActions ? notification.actions : []
        }
    }

    function showOperationError(title, message) {
        operationErrorTitle = title
        operationErrorMessage = message
    }

    function notificationTime(id) {
        const timestamp = notificationTimes[id]
        return timestamp ? Qt.formatDateTime(new Date(timestamp), "HH:mm") : "now"
    }

    function notificationImage(notification) {
        if (!notification)
            return ""
        if (notification.image && notification.image.length > 0)
            return notification.image
        return notification.appIcon && notification.appIcon.length > 0 ? Quickshell.iconPath(notification.appIcon, true) : ""
    }

    function displayNotificationToast() {
        notificationToast.visible = true
        if (toastNotification.expireTimeout >= 0)
            notificationToastTimer.restart()
        else
            notificationToastTimer.stop()
    }

    function clearNotificationToast(reason) {
        if (toastClearing)
            return
        if (toastRetainedNotification && reason === "dismiss") {
            toastClearing = true
            toastRetainedNotification.dismiss()
            toastClearing = false
            finishNotificationToast()
            return
        }
        if (toastRetainedNotification && reason === "expire") {
            toastClearing = true
            toastRetainedNotification.expire()
            toastClearing = false
            finishNotificationToast()
            return
        }
        finishNotificationToast()
    }

    function finishNotificationToast() {
        notificationToastTimer.stop()
        notificationToast.visible = false
        toastRetainedNotification = null
        toastNotification = null
        while (notificationQueue.length > 0) {
            const next = notificationQueue[0]
            notificationQueue = notificationQueue.slice(1)
            const notification = notificationServer.trackedNotifications.values.find(item => item.id === next.id)
            if (notification) {
                showNotificationToast(notification)
                break
            }
        }
    }

    function invokeToastAction(action) {
        if (toastClearing)
            return
        toastClearing = true
        action.invoke()
        toastClearing = false
        finishNotificationToast()
    }

    function pruneNotifications() {
        const notifications = notificationServer.trackedNotifications.values
        const times = {}
        for (const notification of notifications)
            times[notification.id] = notificationTimes[notification.id] || Date.now()
        notificationTimes = times
        if (notifications.length > 100)
            notifications[0].dismiss()
    }

    function updateWorkspaces(output) {
        root.lastMetricsUpdate = Date.now()
        const sections = output.split("\n---\n")
        const names = sections.length > 0 ? sections[0].trim().split("\n").filter(name => name.length > 0) : []
        const occupied = sections.length > 1 ? sections[1].trim().split("\n") : []
        const urgent = sections.length > 2 ? sections[2].trim().split("\n") : []
        workspaceStates = names.map(name => ({
            name: name,
            occupied: occupied.indexOf(name) !== -1,
            urgent: urgent.indexOf(name) !== -1,
            active: name === activeDesktop
        }))
    }

    function setActiveWorkspace(name) {
        activeDesktop = name
    }

    function focusWorkspace(name) {
        run(["bspc", "desktop", "-f", name])
    }

    function cycleWorkspace(step) {
        if (workspaceStates.length === 0)
            return
        let current = workspaceStates.findIndex(workspace => workspace.name === activeDesktop)
        if (current < 0)
            current = 0
        const next = (current + step + workspaceStates.length) % workspaceStates.length
        focusWorkspace(workspaceStates[next].name)
    }

    function updateBattery(output) {
        root.lastBatteryUpdate = Date.now()
        const fields = output.trim().split("\n")
        batteryCapacity = fields.length > 0 && !isNaN(Number(fields[0])) ? Number(fields[0]) : -1
        batteryStatus = fields.length > 1 ? fields[1] : ""
    }

    function updateActiveTitle(output) {
        root.lastActiveWindowUpdate = Date.now()
        const title = output.trim()
        activeTitle = title.length > 0 ? title : "Desktop"
    }

    function updateStatus(output) {
        root.lastMetricsUpdate = Date.now()
        const fields = output.trim().split("\n")
        audioStatus = fields.length > 0 ? fields[0].trim() : ""
        outputMuted = fields.length > 7 && fields[7].trim() === "yes"
        bluetoothStatus = fields.length > 2 ? fields[2].trim() : ""
        if (!volumeAdjusting && fields.length > 3 && !isNaN(Number(fields[3].trim())))
            volumeLevel = Number(fields[3].trim())
        audioDetail = fields.length > 4 ? fields[4].trim() : "Default sink"
        defaultSinkName = fields.length > 4 ? fields[4].trim() : ""
        bluetoothDetail = fields.length > 6 ? fields[6].trim() : "No connected devices"
    }

    function updateNetworkMetrics(output) {
        root.lastNetworkMetricsUpdate = Date.now()
        const fields = output.trim().split("\n")
        const nextInterface = fields.length > 0 ? fields[0] : ""
        if (nextInterface !== networkInterface) {
            previousRxBytes = -1
            previousTxBytes = -1
            previousNetworkSampleMs = 0
            networkDownloadMbps = 0
            networkUploadMbps = 0
        }
        const rxBytes = fields.length > 5 ? Number(fields[5]) : 0
        const txBytes = fields.length > 6 ? Number(fields[6]) : 0
        const sampleMs = Date.now()
        const elapsedMs = previousNetworkSampleMs > 0 ? sampleMs - previousNetworkSampleMs : 0
        networkDownloadMbps = 0
        networkUploadMbps = 0
        if (elapsedMs > 0 && previousRxBytes >= 0 && rxBytes >= previousRxBytes)
            networkDownloadMbps = (rxBytes - previousRxBytes) * 8 / (elapsedMs * 1000)
        if (elapsedMs > 0 && previousTxBytes >= 0 && txBytes >= previousTxBytes)
            networkUploadMbps = (txBytes - previousTxBytes) * 8 / (elapsedMs * 1000)
        previousRxBytes = rxBytes
        previousTxBytes = txBytes
        previousNetworkSampleMs = sampleMs
        networkInterface = nextInterface
        networkType = fields.length > 1 ? fields[1] : ""
        networkDetail = fields.length > 2 && fields[2].length > 0 ? fields[2] : "Disconnected"
        networkSignal = fields.length > 4 && !isNaN(Number(fields[4])) ? Number(fields[4]) : -1
        if (networkInterface.length === 0)
            networkStatus = "󰤮"
        else if (networkType === "wifi" || networkType === "802-11-wireless")
            networkStatus = networkSignal < 0 ? "󰤯" : networkSignal < 20 ? "󰤯" : networkSignal < 40 ? "󰤟" : networkSignal < 60 ? "󰤢" : networkSignal < 80 ? "󰤥" : "󰤨"
        else if (networkType === "ethernet")
            networkStatus = "󰀂"
        else
            networkStatus = "󰀂"
        networkIp = fields.length > 3 ? fields[3] : ""
        if (networkInterface.length === 0) {
        networkDownloadMbps = 0
            networkUploadMbps = 0
        }
    }

    function refreshNowPlaying() {
        // MPRIS player state is exposed through reactive bindings.
    }

    function formatTrackTime(seconds) {
        const value = Math.max(0, Math.floor(seconds || 0))
        const minutes = Math.floor(value / 60)
        const remainder = value % 60
        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    }

    function run(command) {
        Quickshell.execDetached(command)
    }

    function lockScreen() {
        settingsWindow.visible = false
        closePopups()
        run(["sh", "-c", "if command -v betterlockscreen >/dev/null 2>&1; then exec betterlockscreen -l; elif command -v i3lock >/dev/null 2>&1; then exec i3lock -c 0e0e12; else notify-send 'Screen locker unavailable' 'Install i3lock or betterlockscreen'; fi"])
    }

    function toggleQuickNote(centered) {
        const shouldOpen = !quickNotePopup.visible
        closePopups()
        if (shouldOpen)
            quickNoteCentered = centered === true
        quickNotePopup.visible = shouldOpen
        if (shouldOpen)
            quickNoteFocusTimer.restart()
    }

    function saveQuickNote() {
        if (noteSaving)
            return
        const title = quickNoteTitle.text.trim() || "Quick note"
        const body = quickNoteBody.text.trim()
        if (title === "Quick note" && body.length === 0)
            return
        const timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd ddd HH:mm")
        const content = "* " + title + "\n  :PROPERTIES:\n  :CREATED: [" + timestamp + "]\n  :END:" + (body.length > 0 ? "\n  " + body.replace(/\n/g, "\n  ") : "")
        pendingNoteContent = content
        noteSaveError = ""
        noteSaving = true
        noteSaveProcess.command = ["sh", "-c", "mkdir -p \"$HOME/org\" && printf '\\n%s\\n' \"$1\" >> \"$HOME/org/inbox.org\"", "quickshell-note", content]
        noteSaveProcess.running = true
    }

    function setVolume(value) {
        pendingVolumeLevel = Math.round(value * 100)
        audioService.setOutputVolume(value)
    }

    function setMicVolume(value) {
        pendingMicVolumeLevel = Math.round(value * 100)
        audioService.setInputVolume(value)
    }

    function toggleOutputMute() {
        audioService.toggleOutputMute()
    }

    function toggleMicMute() {
        audioService.toggleInputMute()
    }

    function applyWallpaper(path) {
        if (wallpaperApplyProcess.running)
            return
        wallpaperApplyProcess.pendingPath = path
        wallpaperApplyProcess.command = ["feh", "--bg-fill", path]
        wallpaperApplyProcess.running = true
    }

    function setIconTheme(theme) {
        currentIconTheme = theme
        run(["gsettings", "set", "org.gnome.desktop.interface", "icon-theme", theme])
    }

    function setGtkTheme(theme) {
        currentGtkTheme = theme
        const dark = theme.toLowerCase().indexOf("dark") !== -1
        run(["gsettings", "set", "org.gnome.desktop.interface", "gtk-theme", theme])
        run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", dark ? "prefer-dark" : "default"])
    }

    function selectSettingsPage(page) {
        settingsPage = page
        if (page === "Audio")
            refreshAudioDevices()
        else if (page === "Network")
            scanNetworks()
        else if (page === "Bluetooth")
            refreshBluetoothDevices()
        else if (page === "Displays")
            refreshDisplays()
        else if (page === "Appearance")
            refreshAppearanceSettings()
        else if (page === "Session") {
            refreshHardwareSettings()
            if (!metricsQuery.running)
                metricsQuery.running = true
        }
    }

    function openSettings(page) {
        const wasVisible = settingsWindow.visible
        closePopups()
        selectSettingsPage(page)
        settingsWindow.visible = true
        settingsWindow.raise()
        if (!wasVisible)
            settingsWindow.requestActivate()
    }

    function openPowerMenu() {
        settingsWindow.visible = false
        closePopups()
        powerPopup.visible = true
    }

    function openScreenshotMenu() {
        settingsWindow.visible = false
        closePopups()
        screenshotPopup.visible = true
    }

    function openWallpaperViewer() {
        settingsWindow.visible = false
        closePopups()
        wallpaperViewer.visible = true
        wallpaperViewer.requestActivate()
    }

    function applyBspLayout(layout) {
        if (layoutActionProcess.running)
            return
        layoutActionError = ""
        layoutActionBusy = true
        layoutActionProcess.pendingLayout = layout
        layoutActionProcess.command = ["bsp-layout", "set", layout]
        layoutActionProcess.running = true
    }

    function setPanelHeight(value) {
        panelHeight = Math.round(value)
        run(["bspc", "config", "top_padding", String(effectivePanelHeight)])
        interfacePersistTimer.restart()
    }

    function setMenuFontScale(value) {
        menuFontScale = Math.max(0.75, Math.min(2.5, value))
        interfacePersistTimer.restart()
    }

    function setUiFontScale(value) {
        setMenuFontScale(value)
    }

    function setMenuScale(value) {
        menuScale = Math.max(0.75, Math.min(2.5, value))
        run(["bspc", "config", "top_padding", String(effectivePanelHeight)])
        interfacePersistTimer.restart()
    }

    function applyInterfacePreset(scale) {
        menuScale = scale
        menuFontScale = Math.max(0.75, Math.min(2.5, 1.2 * scale))
        panelHeight = 32
        run(["bspc", "config", "top_padding", String(effectivePanelHeight)])
        interfacePersistTimer.restart()
    }

    function setReducedMotion(enabled) {
        reducedMotion = enabled
        interfacePersistTimer.restart()
    }

    function setBrightness(value) {
        if (!brightnessAvailable)
            return
        brightnessLevel = Math.round(value)
        run(["brightnessctl", "-c", "backlight", "set", Math.round(value) + "%"])
    }

    function setKeyboardRepeat(delay, rate) {
        keyboardRepeatDelay = Math.round(delay)
        keyboardRepeatRate = Math.round(rate)
        run(["xset", "r", "rate", String(delay), String(rate)])
        hardwarePersistTimer.restart()
    }

    function toggleTouchpad(enabled) {
        if (!touchpadAvailable)
            return
        touchpadEnabled = enabled
        run(["sh", "-c", "command -v xinput >/dev/null && xinput list --id-only '.*[Tt]ouchpad.*' | xargs -r -n1 xinput --set-prop {} 'Device Enabled' " + (enabled ? "1" : "0")])
        hardwarePersistTimer.restart()
    }

    function updateHardwareSettings(output) {
        root.lastMetricsUpdate = Date.now()
        const fields = output.split("\n")
        brightnessAvailable = fields.length > 0 && fields[0].length > 0 && !isNaN(Number(fields[0]))
        if (brightnessAvailable)
            brightnessLevel = Number(fields[0])
        touchpadAvailable = fields.length > 1 && (fields[1] === "0" || fields[1] === "1")
        if (touchpadAvailable)
            touchpadEnabled = fields[1] === "1"
        if (fields.length > 2 && !isNaN(Number(fields[2])))
            keyboardRepeatDelay = Number(fields[2])
        if (fields.length > 3 && !isNaN(Number(fields[3])))
            keyboardRepeatRate = Number(fields[3])
    }

    function refreshHardwareSettings() {
        if (!hardwareSettingsQuery.running)
            hardwareSettingsQuery.running = true
    }

    function updateAppearanceSettings(output) {
        root.lastMetricsUpdate = Date.now()
        const fields = output.trim().split("\n")
        if (fields.length > 0 && fields[0].length > 0)
            currentIconTheme = fields[0]
        if (fields.length > 1 && fields[1].length > 0)
            currentGtkTheme = fields[1]
    }

    function updateGtkThemes(output) {
        root.lastMetricsUpdate = Date.now()
        const themes = output.trim().split("\n").filter(theme => theme.length > 0)
        if (themes.indexOf(currentGtkTheme) === -1)
            themes.unshift(currentGtkTheme)
        gtkThemes = themes
    }

    function refreshAppearanceSettings() {
        if (!appearanceSettingsQuery.running)
            appearanceSettingsQuery.running = true
        if (!gtkThemesQuery.running)
            gtkThemesQuery.running = true
    }

    function layoutIcon(layout) {
        return layout === "tall" ? "▮▯" : layout === "monocle" ? "▣" : "⊞"
    }

    function primaryScreen() {
        for (const screen of Quickshell.screens) {
            if (screen.name === primaryDisplayName)
                return screen
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function centerX(width) {
        const screen = primaryScreen()
        return screen ? screen.x + Math.max(0, (screen.width - width) / 2) : Math.max(0, (Screen.width - width) / 2)
    }

    function centerY(height) {
        const screen = primaryScreen()
        return screen ? screen.y + Math.max(0, (screen.height - height) / 2) : Math.max(0, (Screen.height - height) / 2)
    }

    function runBluetoothAction(command) {
        if (bluetoothActionProcess.running)
            return
        bluetoothActionError = ""
        bluetoothActionBusy = true
        bluetoothActionProcess.command = command
        bluetoothActionProcess.running = true
    }

    function connectBluetooth(address, connected, paired) {
        if (connected) {
            runBluetoothAction(["bluetoothctl", "disconnect", address])
        } else if (paired) {
            runBluetoothAction(["bluetoothctl", "connect", address])
        } else {
            runBluetoothAction(["sh", "-c", "bluetoothctl pair \"$1\" && bluetoothctl trust \"$1\" && bluetoothctl connect \"$1\"", "quickshell-bluetooth", address])
        }
    }

    function setBluetoothEnabled(enabled) {
        runBluetoothAction(["bluetoothctl", "power", enabled ? "on" : "off"])
    }

    function runNetworkAction(command) {
        if (networkActionProcess.running)
            return
        networkActionError = ""
        networkActionBusy = true
        networkActionProcess.command = command
        networkActionProcess.running = true
    }

    function connectNetwork(ssid, security, active, profileUuid) {
        if (active || networkActionBusy)
            return
        if (profileUuid && profileUuid.length > 0) {
            runNetworkAction(["nmcli", "connection", "up", "uuid", profileUuid])
            return
        }
        if (security && security !== "Open" && security !== "--") {
            wifiPasswordDialog.openForNetwork(ssid)
            return
        }
        runNetworkAction(["nmcli", "device", "wifi", "connect", ssid])
    }

    function connectNetworkWithPassword(ssid, password) {
        runNetworkAction(["nmcli", "device", "wifi", "connect", ssid, "password", password])
    }

    function updateWifiState(output) {
        root.lastNetworkDevicesUpdate = Date.now()
        const fields = output.trim().split("\n")
        wifiEnabled = fields.length > 0 && fields[0] === "enabled"
        wifiDevice = fields.length > 1 ? fields[1] : ""
        wifiAvailable = wifiDevice.length > 0
    }

    function setWifiEnabled(enabled) {
        runNetworkAction(["nmcli", "radio", "wifi", enabled ? "on" : "off"])
    }

    function updateVpnProfiles(output) {
        root.lastNetworkDevicesUpdate = Date.now()
        const profiles = []
        for (const line of output.trim().split("\n")) {
            const fields = line.split("\t")
            if (fields.length < 3 || fields[0].length === 0)
                continue
            profiles.push({ name: fields[0], type: fields[1], active: fields[2] !== "--" && fields[2].length > 0, device: fields[2] })
        }
        vpnProfiles = profiles
    }

    function toggleVpnProfile(name, active) {
        runNetworkAction(["nmcli", "connection", active ? "down" : "up", name])
    }

    function setTailscaleEnabled(enabled) {
        runNetworkAction(["tailscale", enabled ? "up" : "down"])
    }

    function refreshVpnSettings() {
        if (!vpnProfilesQuery.running)
            vpnProfilesQuery.running = true
        if (!tailscaleQuery.running)
            tailscaleQuery.running = true
        if (!exitConfigQuery.running)
            exitConfigQuery.running = true
        if (!publicIpQuery.running)
            publicIpQuery.running = true
        refreshExitSuggestion()
    }

    function updateDisplays(output) {
        root.lastDisplayUpdate = Date.now()
        const result = []
        for (const line of output.trim().split("\n")) {
            const fields = line.split("\t")
            if (fields.length < 5)
                continue
            let display = result.find(item => item.name === fields[0])
            if (!display) {
                const geometry = fields.length > 6 ? fields[6] : ""
                const position = geometry.match(/^[0-9]+x[0-9]+([+-][0-9]+)([+-][0-9]+)$/)
                display = { name: fields[0], state: fields[1], active: false, primary: fields[2] === "primary", mode: "", refresh: "", x: position ? Number(position[1]) : 0, y: position ? Number(position[2]) : 0, rotation: fields.length > 7 ? fields[7] : "normal", modes: [] }
                result.push(display)
            }
            const option = { label: fields[3] + "  @  " + fields[4] + " Hz", mode: fields[3], refresh: fields[4], selected: fields[5] === "selected" }
            display.modes.push(option)
            if (option.selected) {
                display.active = true
                display.mode = option.mode
                display.refresh = option.refresh
            }
        }
        primaryDisplayName = ""
        displays = result
        for (const display of result) {
            if (display.primary) {
                primaryDisplayName = display.name
                break
            }
        }
    }

    function refreshDisplays() {
        if (!displayQuery.running)
            displayQuery.running = true
    }

    function setPrimaryDisplay(name) {
        if (displayActionBusy || !displays.some(display => display.name === name))
            return
        displayActionError = ""
        displayRollbackScript = buildDisplayScript()
        displayActionBusy = true
        displayActionProcess.command = ["xrandr", "--output", name, "--primary"]
        displayActionProcess.running = true
    }

    function setDisplayMode(name, mode, refresh) {
        const display = displays.find(item => item.name === name)
        if (displayActionBusy || !display || !display.modes.some(option => option.mode === mode && option.refresh === refresh))
            return
        displayActionError = ""
        displayRollbackScript = buildDisplayScript()
        displayActionBusy = true
        displayActionProcess.command = ["xrandr", "--output", name, "--mode", mode, "--rate", refresh]
        displayActionProcess.running = true
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function persistDisplayLayout() {
        const script = buildDisplayScript()
        run(["sh", "-c", "target=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/display-layout.sh\"; mkdir -p \"$(dirname \"$target\")\"; temporary=\"$target.tmp.$$\"; printf '%s' \"$1\" > \"$temporary\" && chmod +x \"$temporary\" && mv -f \"$temporary\" \"$target\"", "quickshell-display", script])
    }

    function buildDisplayScript() {
        const commands = ["#!/usr/bin/env sh", "set -eu"]
        let layoutCommand = "xrandr"
        for (const display of displays) {
            if (display.state !== "connected")
                continue
            if (!display.active || display.mode.length === 0) {
                layoutCommand += " --output " + shellQuote(display.name) + " --off"
                continue
            }
            layoutCommand += " --output " + shellQuote(display.name) + " --mode " + shellQuote(display.mode) + " --rate " + shellQuote(display.refresh) + " --pos " + shellQuote(display.x + "x" + display.y) + " --rotate " + shellQuote(display.rotation || "normal")
            if (display.primary)
                layoutCommand += " --primary"
        }
        commands.push(layoutCommand)
        return commands.join("\n") + "\n"
    }

    function keepDisplayLayout() {
        if (displayQuery.running || displayRefreshPending)
            return
        displayRollbackTimer.stop()
        displayConfirmation.visible = false
        displayRollbackScript = ""
        persistDisplayLayout()
    }

    function revertDisplayLayout() {
        displayRollbackTimer.stop()
        displayConfirmation.visible = false
        if (displayRollbackScript.length === 0)
            return
        displayRollbackProcess.command = ["sh", "-c", "$1", "quickshell-display-rollback", displayRollbackScript]
        displayRollbackProcess.running = true
    }

    function updateMicStatus(output) {
        root.lastAudioSourcesUpdate = Date.now()
        const fields = output.trim().split("\n")
        if (!micVolumeAdjusting && fields.length > 0 && !isNaN(Number(fields[0])))
            micVolumeLevel = Number(fields[0])
        micMuted = fields.length > 1 && fields[1] === "yes"
        micName = fields.length > 2 && fields[2].length > 0 ? fields[2] : "Default microphone"
        defaultSourceName = fields.length > 2 ? fields[2] : ""
    }

    function updateAudioDevices(output, isSource) {
        if (isSource)
            root.lastAudioSourcesUpdate = Date.now()
        else
            root.lastAudioSinksUpdate = Date.now()
        try {
            const devices = JSON.parse(output)
            if (!Array.isArray(devices))
                throw new Error("Unexpected audio response")
            const visibleDevices = isSource ? devices.filter(device => !(device.name || "").endsWith(".monitor")) : devices
            if (isSource) {
                audioSources = visibleDevices
                audioSourcesError = visibleDevices.length === 0 ? "No microphone sources found" : ""
            } else {
                audioSinks = visibleDevices
                audioSinksError = visibleDevices.length === 0 ? "No output devices found" : ""
            }
        } catch (error) {
            if (isSource) {
                audioSources = []
                audioSourcesError = "Unable to query microphones"
            } else {
                audioSinks = []
                audioSinksError = "Unable to query output devices"
            }
        }
        if (isSource)
            audioSourcesLoading = false
        else
            audioSinksLoading = false
    }

    function deviceLabel(device) {
        const label = device.description || device.name || "Unknown device"
        return label.replace(/^(alsa_output|alsa_input)\.[^ ]+\s*/, "").replace(/\s+\([^)]*\)$/, "")
    }

    function updateBluetoothDevices(output) {
        root.lastBluetoothUpdate = Date.now()
        const devices = []
        const lines = output.trim().split("\n")
        if (lines.length > 0 && lines[0].startsWith("@adapter\t")) {
            const adapter = lines.shift().split("\t")
            bluetoothAvailable = adapter.length > 1 && adapter[1] === "available"
            bluetoothEnabled = adapter.length > 2 && adapter[2] === "yes"
        }
        for (const line of lines) {
            const fields = line.split("\t")
            if (fields.length >= 2 && fields[0].length > 0)
                devices.push({
                    address: fields[0],
                    name: fields[1],
                    connected: fields.length > 2 && fields[2] === "yes",
                    paired: fields.length > 3 && fields[3] === "yes",
                    trusted: fields.length > 4 && fields[4] === "yes",
                    icon: fields.length > 5 ? fields[5] : "",
                    battery: fields.length > 6 && !isNaN(Number(fields[6])) ? Number(fields[6]) : -1
                })
        }
        bluetoothDevices = devices
        const connectedNames = devices.filter(device => device.connected).map(device => device.name)
        bluetoothDetail = connectedNames.length > 0 ? connectedNames.join(", ") : "No connected devices"
        bluetoothStatus = bluetoothAvailable && bluetoothEnabled ? "󰂯" : "󰂲"
    }

    function updateNetworkDevices(output) {
        root.lastNetworkDevicesUpdate = Date.now()
        const bySsid = {}
        for (const line of output.trim().split("\n")) {
            const fields = splitNmcliFields(line)
            if (fields.length < 4)
                continue
            const active = fields.shift() === "*"
            const security = fields.pop() || "Open"
            const signal = fields.pop()
            const ssid = fields.join(":")
            const strength = Number(signal)
            if (ssid.length > 0 && !isNaN(strength)) {
                const profile = wifiProfiles[ssid]
                const item = { active: active, ssid: ssid, signal: strength, security: security, profileUuid: profile ? profile.uuid : "", profileName: profile ? profile.name : "" }
                if (!bySsid[ssid] || active || strength > bySsid[ssid].signal)
                    bySsid[ssid] = item
            }
        }
        networkDevices = Object.keys(bySsid).map(key => bySsid[key]).sort((left, right) => Number(right.active) - Number(left.active) || right.signal - left.signal)
    }

    function updateWifiProfiles(output) {
        root.lastNetworkDevicesUpdate = Date.now()
        const profiles = {}
        for (const line of output.trim().split("\n")) {
            const fields = line.split("\t")
            if (fields.length >= 3 && fields[0].length > 0 && fields[2].length > 0)
                profiles[fields[2]] = { uuid: fields[0], name: fields[1] || fields[2] }
        }
        wifiProfiles = profiles
        networkDevices = networkDevices.map(device => {
            const profile = profiles[device.ssid]
            return Object.assign({}, device, { profileUuid: profile ? profile.uuid : "", profileName: profile ? profile.name : "" })
        })
    }

    function splitNmcliFields(line) {
        const fields = []
        let field = ""
        let escaped = false
        for (const character of line) {
            if (escaped) {
                field += character
                escaped = false
            } else if (character === "\\") {
                escaped = true
            } else if (character === ":") {
                fields.push(field)
                field = ""
            } else {
                field += character
            }
        }
        if (escaped)
            field += "\\"
        fields.push(field)
        return fields
    }

    function setDefaultSink(name) {
        if (audioActionProcess.running)
            return
        audioActionBusy = true
        audioActionError = ""
        audioActionProcess.command = ["pactl", "set-default-sink", name]
        audioActionProcess.running = true
    }

    function setDefaultSource(name) {
        if (audioActionProcess.running)
            return
        audioActionBusy = true
        audioActionError = ""
        audioActionProcess.command = ["pactl", "set-default-source", name]
        audioActionProcess.running = true
    }

    function refreshAudioDevices() {
        audioSinksLoading = true
        audioSourcesLoading = true
        audioSinksError = ""
        audioSourcesError = ""
        if (!audioSinksQuery.running)
            audioSinksQuery.running = true
        if (!audioSourcesQuery.running)
            audioSourcesQuery.running = true
    }

    function refreshBluetoothDevices() {
        bluetoothScanning = true
        if (!bluetoothDevicesQuery.running)
            bluetoothDevicesQuery.running = true
    }

    function refreshBluetoothSnapshot() {
        if (!bluetoothSnapshotQuery.running)
            bluetoothSnapshotQuery.running = true
    }

    function scanNetworks() {
        networkScanning = true
        if (!wifiProfilesQuery.running)
            wifiProfilesQuery.running = true
        if (!wifiStateQuery.running)
            wifiStateQuery.running = true
        refreshVpnSettings()
    }

    function closePopups() {
        volumePopup.visible = false
        networkPopup.visible = false
        bluetoothPopup.visible = false
        root.bluetoothPopupExplicitlyOpened = false
        tailscalePopup.visible = false
        if (typeof exitNodePopup !== "undefined")
            exitNodePopup.visible = false
        if (typeof trayPopup !== "undefined")
            trayPopup.visible = false
        if (typeof notificationPopup !== "undefined")
            notificationPopup.visible = false
        if (typeof powerPopup !== "undefined")
            powerPopup.visible = false
        if (typeof screenshotPopup !== "undefined")
            screenshotPopup.visible = false
        if (typeof calendarPopup !== "undefined")
            calendarPopup.visible = false
        if (typeof layoutPopup !== "undefined")
            layoutPopup.visible = false
        if (typeof quickNotePopup !== "undefined")
            quickNotePopup.visible = false
    }

    function closeWindows() {
        closePopups()
        if (typeof settingsWindow !== "undefined")
            settingsWindow.visible = false
        if (typeof launcher !== "undefined")
            launcher.visible = false
        if (typeof displayConfirmation !== "undefined")
            displayConfirmation.visible = false
        if (typeof polkitWindow !== "undefined")
            polkitWindow.visible = false
    }

    function togglePopup(popup) {
        const shouldOpen = !popup.visible
        closePopups()
        popup.visible = shouldOpen
        if (shouldOpen && popup === calendarPopup && !agendaQuery.running)
            agendaQuery.running = true
        if (shouldOpen && popup === exitNodePopup)
            refreshExitSuggestion()
    }

    function openExitNodePopup() {
        networkPopup.visible = true
        exitNodePopup.visible = true
        refreshExitSuggestion()
    }

    function updateActiveWindow(id) {
        root.lastActiveWindowUpdate = Date.now()
        const fields = id.trim().split("\n")
        id = fields[0]
        if (id.length === 0)
            return
        if (fields.length > 1 && fields[1] === String(Quickshell.processId))
            return
        if (activeWindowId.length > 0 && id !== activeWindowId)
            closePopups()
        activeWindowId = id
    }

    function startActiveWindowQuery() {
        if (activeWindowQuery.running || pendingActiveWindowId.length === 0)
            return
        activeWindowQuery.queryId = pendingActiveWindowId
        activeWindowQuery.command = ["sh", "-c", "printf '%s\\n' \"$1\"; xprop -id \"$1\" _NET_WM_PID 2>/dev/null | awk '{print $3}'", "quickshell-window", activeWindowQuery.queryId]
        activeWindowQuery.running = true
    }

    function activatePowerAction(index) {
        const action = powerActions[index]
        powerIndex = index
        if (!action.command) {
            closePopups()
            return
        }
        if (pendingPowerIndex !== index) {
            pendingPowerIndex = index
            return
        }
        pendingPowerIndex = -1
        closePopups()
        run(action.command)
    }

    function updateTailscale(output) {
        root.lastTailscaleUpdate = Date.now()
        try {
            const data = JSON.parse(output)
            const peers = data.Peer || {}
            const nodes = []
            const exits = []
            Object.keys(peers).forEach(key => {
                const peer = peers[key]
                const node = {
                    name: peer.HostName || peer.DNSName || key,
                    address: peer.TailscaleIPs && peer.TailscaleIPs.length > 0 ? peer.TailscaleIPs[0] : "",
                    online: peer.Online === true,
                    os: peer.OS || "",
                    active: peer.ExitNode === true
                }
                if (peer.ExitNodeOption === true)
                    exits.push(node)
                else
                    nodes.push(node)
            })
            nodes.sort((a, b) => Number(b.online) - Number(a.online) || a.name.localeCompare(b.name))
            exits.sort((a, b) => a.name.localeCompare(b.name))
            tailscaleState = data.BackendState || "Stopped"
            tailscaleNodes = nodes
            exitNodes = exits
            root.resolveActiveExitNode()
        } catch (error) {
            tailscaleState = "Unavailable"
            tailscaleNodes = []
            exitNodes = []
            activeExitNodeName = ""
            activeExitNodeAddress = ""
        }
    }

    function copyTailscaleAddress(address) {
        run(["sh", "-c", "printf '%s' \"$1\" | xclip -selection clipboard", "quickshell", address])
    }

    function selectExitNode(address) {
        const returnToPopup = exitNodePopup.visible
        runNetworkAction(["tailscale", "set", "--exit-node", address])
        exitNodePopup.visible = false
        if (returnToPopup)
            networkPopup.visible = true
    }

    function refreshExitSuggestion() {
        if (!bestExitNodeQuery.running)
            bestExitNodeQuery.running = true
    }

    function updateExitConfig(output) {
        root.lastExitConfigUpdate = Date.now()
        try {
            const prefs = JSON.parse(output)
            activeExitNodeAddress = prefs.ExitNodeIP || ""
            root.resolveActiveExitNode()
        } catch (error) {
            activeExitNodeAddress = ""
            activeExitNodeName = ""
        }
    }

    function resolveActiveExitNode() {
        activeExitNodeName = ""
        if (activeExitNodeAddress.length === 0)
            return
        for (let i = 0; i < exitNodes.length; i++) {
            if (exitNodes[i].address === activeExitNodeAddress) {
                activeExitNodeName = exitNodes[i].name
                return
            }
        }
    }

    function clearExitNode() {
        const returnToPopup = exitNodePopup.visible
        runNetworkAction(["tailscale", "set", "--exit-node", ""])
        exitNodePopup.visible = false
        if (returnToPopup)
            networkPopup.visible = true
    }

    function calendarMonthName() {
        return new Date(calendarYear, calendarMonth, 1).toLocaleString(Qt.locale(), "MMMM")
    }

    function calendarDaysInMonth() {
        return new Date(calendarYear, calendarMonth + 1, 0).getDate()
    }

    function calendarFirstWeekday() {
        const localeStart = Number(Qt.locale().firstDayOfWeek) % 7
        return (new Date(calendarYear, calendarMonth, 1).getDay() - localeStart + 7) % 7
    }

    function calendarWeekdayNames() {
        const names = []
        const localeStart = Number(Qt.locale().firstDayOfWeek) % 7
        for (let index = 0; index < 7; index++)
            names.push(new Date(1970, 0, 4 + localeStart + index).toLocaleString(Qt.locale(), "ddd"))
        return names
    }

    function resetCalendar() {
        const today = new Date()
        calendarYear = today.getFullYear()
        calendarMonth = today.getMonth()
    }

    function changeCalendarMonth(amount) {
        const date = new Date(calendarYear, calendarMonth + amount, 1)
        calendarYear = date.getFullYear()
        calendarMonth = date.getMonth()
    }

    function takeScreenshot(mode) {
        const capture = mode === "fullscreen" ? "maim -u \"$output\"" : mode === "region" ? "maim -s -u \"$output\"" : "window=$(bspc query -N -n focused 2>/dev/null); [ -n \"$window\" ] && maim -u -i \"$window\" \"$output\""
        run(["sh", "-c", "sleep 0.3; mkdir -p \"$HOME/Pictures/Screenshots\"; output=\"$HOME/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png\"; " + capture + "; if [ -f \"$output\" ]; then command -v xclip >/dev/null 2>&1 && xclip -selection clipboard -target image/png -i \"$output\"; command -v notify-send >/dev/null 2>&1 && notify-send \"Screenshot saved\" \"$output\" --icon=\"$output\" --expire-time=4000; fi"])
        screenshotPopup.visible = false
    }

    function updateAgenda(output) {
        root.lastAgendaUpdate = Date.now()
        try {
            const data = JSON.parse(output)
            agendaConfigured = data.configured === true
            agendaError = data.error || ""
            agendaEvents = Array.isArray(data.events) ? data.events : []
        } catch (error) {
            agendaError = "Unable to load agenda"
            agendaEvents = []
        }
    }

    function updatePrivacyStatus(output) {
        root.lastPrivacyUpdate = Date.now()
        try {
            const data = JSON.parse(output)
            microphoneActive = data.microphoneActive === true
            recordingActive = data.recordingProcess === true
            screenShareActive = data.screenShareActive === true
        } catch (error) {
            microphoneActive = false
            recordingActive = false
            screenShareActive = false
        }
    }

    function updateSystemMetrics(output) {
        root.lastMetricsUpdate = Date.now()
        try {
            const data = JSON.parse(output)
            cpuPercent = data.cpuPercent === null ? -1 : Number(data.cpuPercent)
            memoryPercent = data.memoryPercent === null ? -1 : Number(data.memoryPercent)
            temperatureC = data.temperatureC === null ? -1 : Number(data.temperatureC)
            gpuPercent = data.gpuPercent === null ? -1 : Number(data.gpuPercent)
            powerProfile = data.powerProfile || "unknown"
        } catch (error) {
            cpuPercent = memoryPercent = temperatureC = gpuPercent = -1
            powerProfile = "unknown"
        }
    }

    Timer {
        id: interfacePersistTimer
        interval: 250
        repeat: false
        onTriggered: root.run(["sh", "-c", "directory=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell\"; mkdir -p \"$directory\"; temporary=\"$directory/interface-state.tmp.$$\"; printf '%s\\n%s\\n%s\\n%s\\n' \"$1\" \"$2\" \"$3\" \"$4\" > \"$temporary\" && mv -f \"$temporary\" \"$directory/interface-state\"", "quickshell-interface", String(root.panelHeight), String(root.menuFontScale), root.reducedMotion ? "1" : "0", String(root.menuScale)])
    }

    Timer {
        id: hardwarePersistTimer
        interval: 250
        repeat: false
        onTriggered: {
            const script = "#!/usr/bin/env sh\nset -eu\nxset r rate " + root.keyboardRepeatDelay + " " + root.keyboardRepeatRate + "\nif command -v xinput >/dev/null 2>&1; then xinput list --id-only '.*[Tt]ouchpad.*' | xargs -r -n1 xinput --set-prop {} 'Device Enabled' " + (root.touchpadEnabled ? "1" : "0") + "\nfi\n"
            root.run(["sh", "-c", "target=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/hardware-state.sh\"; mkdir -p \"$(dirname \"$target\")\"; temporary=\"$target.tmp.$$\"; printf '%s' \"$1\" > \"$temporary\" && chmod +x \"$temporary\" && mv -f \"$temporary\" \"$target\"", "quickshell-hardware", script])
        }
    }

    Process {
        command: ["sh", "-c", "state=\"${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/interface-state\"; [ -r \"$state\" ] && cat \"$state\""]
        running: true
        stdout: StdioCollector {
            id: interfaceStateOutput
            onStreamFinished: {
                const values = interfaceStateOutput.text.trim().split("\n")
                if (values.length > 1 && !isNaN(Number(values[1])))
                    root.menuFontScale = Math.max(0.75, Math.min(2.5, Number(values[1])))
                if (values.length > 2)
                    root.reducedMotion = values[2] === "1"
                if (values.length > 3 && !isNaN(Number(values[3])))
                    root.menuScale = Math.max(0.75, Math.min(2.5, Number(values[3])))
                root.run(["bspc", "config", "top_padding", String(root.effectivePanelHeight)])
            }
        }
    }

    Connections {
        target: WmState
        function onActiveWindowIdChanged() {
            if (WmState.activeWindowId.length === 0)
                return
            root.pendingActiveWindowId = WmState.activeWindowId
            root.startActiveWindowQuery()
        }
        function onActiveFullscreenChanged() {
            if (WmState.activeFullscreen)
                root.closePopups()
        }
    }

    Process {
        id: noteSaveProcess
        stderr: StdioCollector { id: noteSaveErrorOutput }
        onExited: (exitCode, exitStatus) => {
            root.noteSaving = false
            if (exitCode === 0) {
                quickNoteTitle.clear()
                quickNoteBody.clear()
                quickNotePopup.visible = false
                root.run(["notify-send", "Org note saved", "~/org/inbox.org"])
            } else {
                root.noteSaveError = noteSaveErrorOutput.text.trim() || "Unable to save the note"
            }
        }
    }

    Process {
        id: layoutActionProcess
        property string pendingLayout: ""
        stderr: StdioCollector { id: layoutActionErrorOutput }
        onExited: (exitCode, exitStatus) => {
            root.layoutActionBusy = false
            if (exitCode === 0) {
                root.bspLayout = pendingLayout
                root.layoutActionError = ""
                layoutPopup.visible = false
            } else {
                root.layoutActionError = layoutActionErrorOutput.text.trim() || "Unable to change layout"
            }
        }
    }

    Process {
        id: audioActionProcess
        stderr: StdioCollector { id: audioActionErrorOutput }
        onExited: (exitCode, exitStatus) => {
            root.audioActionBusy = false
            if (exitCode === 0) {
                root.audioActionError = ""
                if (!audioDefaultsQuery.running)
                    audioDefaultsQuery.running = true
                root.refreshAudioDevices()
            } else {
                root.audioActionError = audioActionErrorOutput.text.trim() || "Audio operation failed"
            }
        }
    }

    Process {
        id: wallpaperApplyProcess
        property string pendingPath: ""
        stderr: StdioCollector { id: wallpaperApplyError }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.selectedWallpaper = pendingPath
                root.run(["notify-send", "Wallpaper applied", pendingPath.split("/").pop()])
            } else {
                root.run(["notify-send", "Wallpaper failed", wallpaperApplyError.text.trim() || "Unable to apply wallpaper"])
            }
        }
    }

    Process {
        id: agendaQuery
        command: [root.configDirectory + "/scripts/agenda.py"]
        stdout: StdioCollector {
            id: agendaOutput
            onStreamFinished: root.updateAgenda(agendaOutput.text)
        }
    }

    Process {
        id: privacyQuery
        command: [root.configDirectory + "/scripts/privacy-status.sh"]
        running: true
        stdout: StdioCollector {
            id: privacyOutput
            onStreamFinished: root.updatePrivacyStatus(privacyOutput.text)
        }
    }

    Process {
        id: metricsQuery
        command: [root.configDirectory + "/scripts/system-metrics.sh"]
        stdout: StdioCollector {
            id: metricsOutput
            onStreamFinished: root.updateSystemMetrics(metricsOutput.text)
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: {
            if (!privacyQuery.running)
                privacyQuery.running = true
            if (settingsWindow.visible && root.settingsPage === "Session" && !metricsQuery.running)
                metricsQuery.running = true
        }
    }

    Process {
        id: networkActionProcess
        stderr: StdioCollector { id: networkActionErrorOutput }
        onExited: (exitCode, exitStatus) => {
            root.networkActionBusy = false
            if (exitCode === 0) {
                root.networkActionError = ""
                wifiRefreshTimer.restart()
                vpnRefreshTimer.restart()
            } else {
                root.networkActionError = networkActionErrorOutput.text.trim() || "Network operation failed"
            }
        }
    }

    Process {
        id: bluetoothActionProcess
        stderr: StdioCollector { id: bluetoothActionErrorOutput }
        onExited: (exitCode, exitStatus) => {
            root.bluetoothActionBusy = false
            if (exitCode === 0) {
                root.bluetoothActionError = ""
                root.refreshBluetoothDevices()
            } else {
                root.bluetoothActionError = bluetoothActionErrorOutput.text.trim() || "Bluetooth operation failed"
            }
        }
    }

    Process {
        id: displayActionProcess
        stderr: StdioCollector { id: displayActionErrorOutput }
        onExited: (exitCode, exitStatus) => {
            root.displayActionBusy = false
            if (exitCode === 0) {
                root.displayActionError = ""
                root.displayRefreshPending = true
                if (displayQuery.running)
                    root.displayRefreshAfterCurrent = true
                else
                    root.refreshDisplays()
                displayConfirmation.visible = true
                displayConfirmation.requestActivate()
                displayRollbackTimer.restart()
            } else {
                root.displayActionError = displayActionErrorOutput.text.trim() || "Display operation failed"
            }
        }
    }

    Process {
        id: displayRollbackProcess
        stderr: StdioCollector { id: displayRollbackError }
        onExited: (exitCode, exitStatus) => {
            root.displayRollbackScript = ""
            if (exitCode !== 0)
                root.displayActionError = displayRollbackError.text.trim() || "Unable to restore the previous display layout"
            root.refreshDisplays()
        }
    }

    Timer {
        id: displayRollbackTimer
        interval: 15000
        repeat: false
        onTriggered: root.revertDisplayLayout()
    }

    Process {
        id: batteryQuery
        command: ["sh", "-c", "battery=; for dir in /sys/class/power_supply/BAT*; do if [ -d \"$dir\" ]; then battery=\"$dir\"; break; fi; done; if [ -n \"$battery\" ]; then cat \"$battery/capacity\"; cat \"$battery/status\"; else printf '%s\\n' -1 unavailable; fi"]
        running: true
        stdout: StdioCollector {
            id: batteryOutput
            onStreamFinished: root.updateBattery(batteryOutput.text)
        }
    }

    Process {
        id: wallpaperQuery
        command: ["sh", "-c", "find \"$HOME/nux/wallpapers\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print 2>/dev/null | sort"]
        running: true
        stdout: StdioCollector {
            id: wallpaperOutput
            onStreamFinished: root.wallpapers = wallpaperOutput.text.trim().length > 0 ? wallpaperOutput.text.trim().split("\n") : []
        }
    }

    Process {
        id: audioSinksQuery
        command: ["pactl", "-f", "json", "list", "sinks"]
        stdout: StdioCollector {
            id: audioSinksOutput
            onStreamFinished: root.updateAudioDevices(audioSinksOutput.text, false)
        }
    }

    Process {
        id: audioSourcesQuery
        command: ["pactl", "-f", "json", "list", "sources"]
        stdout: StdioCollector {
            id: audioSourcesOutput
            onStreamFinished: root.updateAudioDevices(audioSourcesOutput.text, true)
        }
    }

    Process {
        id: audioDefaultsQuery
        command: ["sh", "-c", "pactl get-default-sink 2>/dev/null; pactl get-default-source 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            id: audioDefaultsOutput
            onStreamFinished: {
                const fields = audioDefaultsOutput.text.trim().split("\n")
                root.defaultSinkName = fields.length > 0 ? fields[0] : ""
                root.defaultSourceName = fields.length > 1 ? fields[1] : ""
                root.audioDetail = root.defaultSinkName || "Default sink"
                root.micName = root.defaultSourceName || "Default microphone"
            }
        }
    }

    Process {
        id: bluetoothDevicesQuery
        command: ["sh", "-c", "controller=$(bluetoothctl show 2>/dev/null); if [ -n \"$controller\" ]; then available=available; powered=$(printf '%s\\n' \"$controller\" | awk '/Powered:/ {print $2; exit}'); else available=unavailable; powered=no; fi; printf '@adapter\\t%s\\t%s\\n' \"$available\" \"$powered\"; bluetoothctl devices 2>/dev/null | while read -r _ address name; do info=$(bluetoothctl info \"$address\" 2>/dev/null); connected=$(printf '%s\\n' \"$info\" | awk '/Connected:/ {print $2; exit}'); paired=$(printf '%s\\n' \"$info\" | awk '/Paired:/ {print $2; exit}'); trusted=$(printf '%s\\n' \"$info\" | awk '/Trusted:/ {print $2; exit}'); icon=$(printf '%s\\n' \"$info\" | awk '/Icon:/ {print $2; exit}'); battery=$(printf '%s\\n' \"$info\" | awk '/Battery Percentage:/ {value=$NF; gsub(/[()]/, \"\", value); print value; exit}'); printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$address\" \"$name\" \"${connected:-no}\" \"${paired:-no}\" \"${trusted:-no}\" \"$icon\" \"${battery:--1}\"; done"]
        stdout: StdioCollector {
            id: bluetoothDevicesOutput
            onStreamFinished: root.updateBluetoothDevices(bluetoothDevicesOutput.text)
        }
        onExited: root.bluetoothScanning = false
    }

    Process {
        id: bluetoothSnapshotQuery
        command: ["sh", "-c", "controller=$(bluetoothctl show 2>/dev/null); if [ -n \"$controller\" ]; then available=available; powered=$(printf '%s\\n' \"$controller\" | awk '/Powered:/ {print $2; exit}'); else available=unavailable; powered=no; fi; printf '@adapter\\t%s\\t%s\\n' \"$available\" \"$powered\"; bluetoothctl devices 2>/dev/null | while read -r _ address name; do info=$(bluetoothctl info \"$address\" 2>/dev/null); connected=$(printf '%s\\n' \"$info\" | awk '/Connected:/ {print $2; exit}'); paired=$(printf '%s\\n' \"$info\" | awk '/Paired:/ {print $2; exit}'); trusted=$(printf '%s\\n' \"$info\" | awk '/Trusted:/ {print $2; exit}'); icon=$(printf '%s\\n' \"$info\" | awk '/Icon:/ {print $2; exit}'); battery=$(printf '%s\\n' \"$info\" | awk '/Battery Percentage:/ {value=$NF; gsub(/[()]/, \"\", value); print value; exit}'); printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$address\" \"$name\" \"${connected:-no}\" \"${paired:-no}\" \"${trusted:-no}\" \"$icon\" \"${battery:--1}\"; done"]
        stdout: StdioCollector {
            id: bluetoothSnapshotOutput
            onStreamFinished: root.updateBluetoothDevices(bluetoothSnapshotOutput.text)
        }
    }

    Process {
        id: bluetoothMonitor
        command: ["bluetoothctl", "--monitor"]
        stdout: SplitParser {
            onRead: line => bluetoothMonitorRefresh.restart()
        }
        onExited: bluetoothMonitorRestart.restart()
    }

    Process {
        id: networkDevicesQuery
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            id: networkDevicesOutput
            onStreamFinished: root.updateNetworkDevices(networkDevicesOutput.text)
        }
        onExited: root.networkScanning = false
    }

    Process {
        id: wifiProfilesQuery
        command: ["sh", "-c", "nmcli -t -f UUID,TYPE connection show 2>/dev/null | while IFS=: read -r uuid type; do [ \"$type\" = 802-11-wireless ] || [ \"$type\" = wifi ] || continue; values=$(nmcli --escape no -g connection.id,802-11-wireless.ssid connection show uuid \"$uuid\" 2>/dev/null); name=$(printf '%s\\n' \"$values\" | sed -n '1p'); ssid=$(printf '%s\\n' \"$values\" | sed -n '2p'); printf '%s\\t%s\\t%s\\n' \"$uuid\" \"$name\" \"$ssid\"; done"]
        stdout: StdioCollector {
            id: wifiProfilesOutput
            onStreamFinished: root.updateWifiProfiles(wifiProfilesOutput.text)
        }
    }

    Process {
        id: wifiStateQuery
        command: ["sh", "-c", "radio=$(nmcli radio wifi 2>/dev/null); device=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2 == \"wifi\" {print $1; exit}'); printf '%s\\n%s\\n' \"$radio\" \"$device\""]
        stdout: StdioCollector {
            id: wifiStateOutput
            onStreamFinished: root.updateWifiState(wifiStateOutput.text)
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && root.wifiAvailable && root.wifiEnabled && !networkDevicesQuery.running)
                networkDevicesQuery.running = true
            else
                root.networkScanning = false
        }
    }

    Process {
        id: networkMonitor
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: line => networkMonitorRefresh.restart()
        }
        onExited: networkMonitorRestart.restart()
    }

    Process {
        id: vpnProfilesQuery
        command: ["sh", "-c", "nmcli -t --escape no -f NAME,TYPE,DEVICE connection show 2>/dev/null | awk -F: '$2 == \"vpn\" || $2 == \"wireguard\" {printf \"%s\\t%s\\t%s\\n\", $1, $2, ($3 == \"\" ? \"--\" : $3)}'"]
        stdout: StdioCollector {
            id: vpnProfilesOutput
            onStreamFinished: root.updateVpnProfiles(vpnProfilesOutput.text)
        }
    }

    Process {
        id: displayQuery
        command: ["sh", "-c", "xrandr --query 2>/dev/null | awk '$2 == \"connected\" { name=$1; primary=($3 == \"primary\" ? \"primary\" : \"secondary\"); geometry=\"\"; rotation=\"normal\"; for (i=3; i<=NF; i++) { if ($i ~ /^[0-9]+x[0-9]+[+-][0-9]+[+-][0-9]+/) geometry=$i; if ($i == \"left\" || $i == \"right\" || $i == \"inverted\") rotation=$i } next } $2 == \"disconnected\" { name=\"\"; next } name && $1 ~ /^[0-9]+x[0-9]+$/ { mode=$1; for (i=2; i<=NF; i++) { rate=$i; selected=(rate ~ /\\*/ ? \"selected\" : \"available\"); gsub(/[^0-9.]/, \"\", rate); if (rate ~ /[0-9]/) print name \"\\tconnected\\t\" primary \"\\t\" mode \"\\t\" rate \"\\t\" selected \"\\t\" geometry \"\\t\" rotation } }'"]
        stdout: StdioCollector {
            id: displayOutput
            onStreamFinished: root.updateDisplays(displayOutput.text)
        }
        onExited: {
            if (root.displayRefreshAfterCurrent) {
                root.displayRefreshAfterCurrent = false
                Qt.callLater(root.refreshDisplays)
            } else {
                root.displayRefreshPending = false
            }
        }
    }

    Process {
        id: hardwareSettingsQuery
        command: ["sh", "-c", "brightness=$(brightnessctl -c backlight -m 2>/dev/null | awk -F, 'NR == 1 {gsub(/%/, \"\", $4); print $4}'); touchpad=; touchpad_id=$(xinput list --id-only '.*[Tt]ouchpad.*' 2>/dev/null | head -n1); [ -n \"$touchpad_id\" ] && touchpad=$(xinput list-props \"$touchpad_id\" 2>/dev/null | awk -F: '/Device Enabled/ {gsub(/[[:space:]]/, \"\", $2); print $2; exit}'); repeat=$(xset q 2>/dev/null | awk '/auto repeat delay/ {print $4; print $7; exit}'); printf '%s\n%s\n%s\n' \"$brightness\" \"$touchpad\" \"$repeat\""]
        stdout: StdioCollector {
            id: hardwareSettingsOutput
            onStreamFinished: root.updateHardwareSettings(hardwareSettingsOutput.text)
        }
    }

    Process {
        id: appearanceSettingsQuery
        command: ["sh", "-c", "icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d \"'\"); gtk=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d \"'\"); printf '%s\\n%s\\n' \"$icons\" \"$gtk\""]
        stdout: StdioCollector {
            id: appearanceSettingsOutput
            onStreamFinished: root.updateAppearanceSettings(appearanceSettingsOutput.text)
        }
    }

    Process {
        id: gtkThemesQuery
        command: ["sh", "-c", "for dir in /usr/share/themes \"$HOME/.local/share/themes\" \"$HOME/.themes\" \"$HOME/.nix-profile/share/themes\"; do [ -d \"$dir\" ] && find \"$dir\" -mindepth 1 -maxdepth 1 -type d -printf '%f\\n'; done | sort -u"]
        stdout: StdioCollector {
            id: gtkThemesOutput
            onStreamFinished: root.updateGtkThemes(gtkThemesOutput.text)
        }
    }

    Process {
        id: networkMetricsQuery
        command: ["sh", "-c", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i=1; i<=NF; i++) if ($i==\"dev\") {print $(i+1); exit}}'); [ -z \"$iface\" ] && iface=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$3==\"connected\" && $1!=\"lo\" {print $1; exit}'); type=$(nmcli -g GENERAL.TYPE device show \"$iface\" 2>/dev/null | head -n1); connection=$(nmcli -g GENERAL.CONNECTION device show \"$iface\" 2>/dev/null | head -n1); ip=$(nmcli -g IP4.ADDRESS device show \"$iface\" 2>/dev/null | cut -d/ -f1 | head -n1); signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list 2>/dev/null | awk -F: '$1==\"*\" {print $2; exit}'); rx=0; tx=0; [ -n \"$iface\" ] && rx=$(cat /sys/class/net/\"$iface\"/statistics/rx_bytes 2>/dev/null || printf 0); [ -n \"$iface\" ] && tx=$(cat /sys/class/net/\"$iface\"/statistics/tx_bytes 2>/dev/null || printf 0); printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' \"$iface\" \"$type\" \"$connection\" \"$ip\" \"$signal\" \"$rx\" \"$tx\""]
        running: true
        stdout: StdioCollector {
            id: networkMetricsOutput
            onStreamFinished: root.updateNetworkMetrics(networkMetricsOutput.text)
        }
    }

    Process {
        id: tailscaleQuery
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            id: tailscaleOutput
            onStreamFinished: root.updateTailscale(tailscaleOutput.text)
        }
    }

    Process {
        id: exitConfigQuery
        command: ["tailscale", "debug", "prefs"]
        running: true
        stdout: StdioCollector {
            id: exitConfigOutput
            onStreamFinished: root.updateExitConfig(exitConfigOutput.text)
        }
    }

    Process {
        id: bestExitNodeQuery
        command: ["sh", "-c", "tailscale exit-node suggest 2>/dev/null | sed -n 's/^Suggested exit node: //p'"]
        stdout: StdioCollector {
            id: bestExitNodeOutput
            onStreamFinished: root.bestExitNode = bestExitNodeOutput.text.trim()
        }
    }

    Process {
        id: publicIpQuery
        command: ["sh", "-c", "curl -4 -fsS --max-time 3 https://api.ipify.org 2>/dev/null"]
        stdout: StdioCollector {
            id: publicIpOutput
            onStreamFinished: root.publicIp = publicIpOutput.text.trim()
        }
    }

    Process {
        id: activeWindowQuery
        property string queryId: ""
        stdout: StdioCollector {
            id: activeWindowOutput
            onStreamFinished: root.updateActiveWindow(activeWindowOutput.text)
        }
        onExited: {
            if (queryId !== root.pendingActiveWindowId)
                Qt.callLater(root.startActiveWindowQuery)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: if (!networkMetricsQuery.running) networkMetricsQuery.running = true
    }

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            if (!batteryQuery.running)
                batteryQuery.running = true
            if (settingsWindow.visible && root.settingsPage === "Network")
                root.refreshVpnSettings()
        }
    }

    Timer {
        id: wifiRefreshTimer
        interval: 700
        repeat: false
        onTriggered: root.scanNetworks()
    }

    Timer {
        id: vpnRefreshTimer
        interval: 900
        repeat: false
        onTriggered: root.refreshVpnSettings()
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcherVisible = !launcherVisible
            if (launcherVisible) {
                launcherOpenDelay.restart()
            } else {
                launcherOpenDelay.stop()
                launcher.visible = false
            }
        }
    }

    IpcHandler {
        target: "volume"
        function toggle(): void {
            root.togglePopup(volumePopup)
        }
    }

    Timer {
        id: launcherOpenDelay
        interval: 100
        repeat: false
        onTriggered: {
            launcher.visible = true
            launcher.activateLauncher()
        }
    }

    IpcHandler {
        target: "network"
        function toggle(): void {
            root.togglePopup(networkPopup)
        }
    }

    IpcHandler {
        target: "bluetooth"
        function toggle(): void {
            root.togglePopup(bluetoothPopup)
        }
    }

    IpcHandler {
        target: "tailscale"
        function toggle(): void {
            root.togglePopup(tailscalePopup)
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void {
            root.togglePopup(notificationPopup)
        }
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void {
            wallpaperViewer.visible = !wallpaperViewer.visible
            if (wallpaperViewer.visible)
                wallpaperViewer.requestActivate()
        }
    }

    IpcHandler {
        target: "lock"
        function toggle(): void {
            root.lockScreen()
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void {
            if (settingsWindow.visible)
                settingsWindow.visible = false
            else
                root.openSettings("Audio")
        }
        function open(page: string): void {
            root.openSettings(page)
        }
    }

    IpcHandler {
        target: "colorpicker"
        function toggle(): void {
            colorPicker.visible = !colorPicker.visible
            if (colorPicker.visible)
                colorPicker.requestActivate()
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): void {
            root.togglePopup(powerPopup)
        }
    }

    IpcHandler {
        target: "screenshot"
        function toggle(): void {
            root.togglePopup(screenshotPopup)
        }
    }

    IpcHandler {
        target: "note"
        function toggle(): void {
            root.toggleQuickNote(false)
        }
        function center(): void {
            root.toggleQuickNote(true)
        }
    }

    PanelWindow {
        id: bar
        visible: !WmState.activeFullscreen
        screen: root.primaryScreen()
        anchors { top: true; left: true; right: true }
        implicitHeight: root.effectivePanelHeight
        exclusiveZone: root.effectivePanelHeight
        color: background
        aboveWindows: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16 * root.menuScale
            anchors.rightMargin: 10 * root.menuScale
            spacing: 8 * root.menuScale

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Repeater {
                    model: root.workspaceStates

                    delegate: Item {
                        required property var modelData
                        implicitWidth: 19.4 * root.menuScale
                        implicitHeight: root.effectivePanelHeight
                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: "Workspace " + modelData.name
                        Keys.onReturnPressed: root.focusWorkspace(modelData.name)
                        Keys.onEnterPressed: root.focusWorkspace(modelData.name)

                        Rectangle {
                            anchors.centerIn: parent
                            width: 9.4 * root.menuScale
                            height: 9.4 * root.menuScale
                            radius: 1
                            color: root.activeDesktop === modelData.name ? foreground : (modelData.urgent ? "#f38ba8" : (workspaceMouse.containsMouse ? root.settingsRaised : "transparent"))
                            border.width: 0

                            Behavior on color {
                                ColorAnimation { duration: 120 }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.activeDesktop !== modelData.name && !modelData.urgent
                                text: modelData.name
                                color: modelData.occupied ? foreground : root.muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 13 * root.displayFontScale
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: workspaceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.focusWorkspace(modelData.name)
                            onWheel: wheel => {
                                root.cycleWorkspace(wheel.angleDelta.y > 0 ? -1 : 1)
                                wheel.accepted = true
                            }
                        }
                    }

                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 8 * root.menuScale
                Layout.maximumWidth: Math.max(0, Math.min(360 * root.menuScale, bar.width / 2 - clock.width / 2 - 16 * root.menuScale - x - 8 * root.menuScale))
                spacing: 6 * root.menuScale

                Text {
                    text: "•"
                    color: root.muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11 * root.displayFontScale
                }

                Text {
                    Layout.fillWidth: true
                    text: root.activeTitle || "Desktop"
                    color: foreground
                    elide: Text.ElideRight
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13 * root.displayFontScale
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                Layout.rightMargin: 8 * root.menuScale
                spacing: 12 * root.menuScale

                Rectangle {
                    visible: root.batteryCapacity >= 0
                    implicitWidth: batteryLayout.implicitWidth + 10 * root.menuScale
                    implicitHeight: 24 * root.menuScale
                    radius: 6
                    color: batteryMouse.containsMouse ? root.settingsRaised : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: batteryLayout
                        anchors.centerIn: parent
                        spacing: 4 * root.menuScale

                        Text {
                            text: root.batteryStatus === "Charging" ? "󰂄" : root.batteryCapacity <= 15 ? "󰁺" : root.batteryCapacity <= 35 ? "󰁼" : root.batteryCapacity <= 65 ? "󰁾" : "󰂀"
                            color: root.batteryStatus === "Charging" ? "#a6e3a1" : (root.batteryCapacity <= 15 ? "#f38ba8" : foreground)
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13 * root.displayFontScale
                        }
                        Text {
                            text: root.batteryCapacity + "%"
                            color: root.batteryCapacity <= 15 ? "#f38ba8" : foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11 * root.displayFontScale
                            font.weight: Font.DemiBold
                        }
                    }

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: "Battery " + root.batteryCapacity + " percent. Open session settings"
                    Keys.onReturnPressed: root.openSettings("Session")

                    MouseArea {
                        id: batteryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.openSettings("Session")
                    }
                }

                RowLayout {
                    spacing: 4 * root.menuScale

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            required property var modelData
                            implicitWidth: 19 * root.menuScale
                            implicitHeight: 19 * root.menuScale
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.title || "System tray item"

                            Image {
                                anchors.centerIn: parent
                                source: modelData.icon
                                sourceSize.width: 13 * root.menuScale
                                sourceSize.height: 13 * root.menuScale
                                width: 13 * root.menuScale
                                height: 13 * root.menuScale
                            }

                            MouseArea {
                                id: panelTrayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (modelData.hasMenu && (event.button === Qt.RightButton || modelData.onlyMenu)) {
                                        trayPopup.visible = true
                                        trayPopup.anchor.rect.x = bar.width - 10
                                        modelData.display(trayPopup, 0, 0)
                                    } else
                                        modelData.activate()
                                }
                            }

                        }
                    }
                }

                Rectangle {
                    implicitWidth: 26 * root.menuScale
                    implicitHeight: 24 * root.menuScale
                    radius: 6
                    color: audioMouseArea.containsMouse ? root.settingsRaised : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: audioStatus
                        color: root.outputMuted ? root.muted : foreground
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 16 * root.displayFontScale
                    }

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: root.outputMuted ? "Audio muted" : "Audio " + Math.round(root.volumeLevel) + " percent"
                    Keys.onReturnPressed: root.togglePopup(volumePopup)

                    MouseArea {
                        id: audioMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: event => {
                            if (event.button === Qt.RightButton)
                                root.toggleOutputMute()
                            else
                                root.togglePopup(volumePopup)
                        }
                        onWheel: event => {
                            root.setVolume(Math.max(0, Math.min(1, root.volumeLevel / 100 + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
                        }
                    }
                }

                Rectangle {
                    visible: bar.width >= 850 * root.menuScale
                    implicitWidth: 26 * root.menuScale
                    implicitHeight: 24 * root.menuScale
                    radius: 6
                    color: networkMouseArea.containsMouse ? root.settingsRaised : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: networkStatus
                        color: foreground
                        font.family: "Symbols Nerd Font Mono"
                        font.pixelSize: 13 * root.displayFontScale
                    }

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: "Network " + root.networkDetail
                    Keys.onReturnPressed: root.togglePopup(networkPopup)
                    MouseArea {
                        id: networkMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.togglePopup(networkPopup)
                        onPressAndHold: root.run(["wezterm", "-e", "nmtui"])
                    }
                }

                Rectangle {
                    visible: bar.width >= 1000 * root.menuScale
                    implicitWidth: 26 * root.menuScale
                    implicitHeight: 24 * root.menuScale
                    radius: 6
                    color: bluetoothMouseArea.containsMouse ? root.settingsRaised : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: bluetoothStatus
                        color: foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16 * root.displayFontScale
                    }

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: "Bluetooth " + root.bluetoothDetail
                    Keys.onReturnPressed: root.togglePopup(bluetoothPopup)
                    MouseArea {
                        id: bluetoothMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                                onClicked: root.togglePopup(bluetoothPopup), root.bluetoothPopupExplicitlyOpened = true
                        onPressAndHold: root.run(["wezterm", "-e", "bluetui"])
                    }
                }

                Rectangle {
                    visible: bar.width >= 700 * root.menuScale
                    implicitWidth: 26 * root.menuScale
                    implicitHeight: 24 * root.menuScale
                    radius: 6
                    color: notificationMouseArea.containsMouse ? root.settingsRaised : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: "󰂚"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14 * root.displayFontScale
                        }
                        Rectangle {
                            visible: notificationServer.trackedNotifications.values.length > 0
                            width: 4
                            height: 4
                            radius: 2
                            color: root.accent
                        }
                    }

                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: notificationServer.trackedNotifications.values.length + " notifications"
                    Keys.onReturnPressed: root.togglePopup(notificationPopup)
                    MouseArea {
                        id: notificationMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.togglePopup(notificationPopup)
                    }
                }

            }
        }

        Rectangle {
            id: clock
            anchors.centerIn: parent
            implicitWidth: clockText.implicitWidth + 16 * root.menuScale
            implicitHeight: 24 * root.menuScale
            radius: 6
            color: clockMouse.containsMouse ? root.settingsRaised : "transparent"

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: clockText
                anchors.centerIn: parent
                text: Qt.formatDateTime(new Date(), "ddd dd  HH:mm")
                color: foreground
                font.family: "JetBrains Mono"
                font.pixelSize: 13 * root.displayFontScale
                font.weight: Font.DemiBold
            }

            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Open calendar"
            Keys.onReturnPressed: root.togglePopup(calendarPopup)
            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: clockText.text = Qt.formatDateTime(new Date(), "ddd dd  HH:mm")
            }

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.togglePopup(calendarPopup)
            }
        }
    }

    LayoutPopup { id: layoutPopup; root: root; bar: bar }
    OperationToast { shellRoot: root; barWindow: bar }
    WifiPasswordDialog { id: wifiPasswordDialog; shellRoot: root }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        onActivated: root.closeWindows()
    }

    Window {
        id: quickNotePopup
        visible: false
        title: "Quick Org note"
        x: root.quickNoteCentered ? root.centerX(width) : (root.primaryScreen() ? root.primaryScreen().x + root.primaryScreen().width - width - 10 : Screen.width - width - 10)
        y: root.quickNoteCentered ? root.centerY(height) : (root.primaryScreen() ? root.primaryScreen().y + root.effectivePanelHeight + 8 : root.effectivePanelHeight + 8)
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Dialog
        color: "transparent"
        width: root.primaryScreen() ? Math.max(1, Math.min(430 * menuScale, root.primaryScreen().width - 24)) : 430 * menuScale
        height: root.primaryScreen() ? Math.max(1, Math.min(330 * menuScale, root.primaryScreen().height - root.effectivePanelHeight - 24)) : 330 * menuScale

        onVisibleChanged: if (visible) quickNoteFocusTimer.restart()

        Timer {
            id: quickNoteFocusTimer
            interval: 50
            repeat: false
            onTriggered: {
                quickNotePopup.requestActivate()
                quickNoteTitle.forceActiveFocus(Qt.OtherFocusReason)
            }
        }

        Rectangle {
            anchors.fill: parent
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true

            opacity: quickNotePopup.visible ? 1.0 : 0.0
            scale: quickNotePopup.visible ? 1.0 : 0.97
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
                anchors.margins: 16
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 10
                        color: accent
                        Text { anchors.centerIn: parent; text: "󰎜"; color: background; font.family: "JetBrains Mono"; font.pixelSize: 17 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text { text: "Quick Org note"; color: foreground; font.family: "Noto Sans"; font.pixelSize: 14 * root.menuFontScale; font.weight: Font.DemiBold }
                        Text { text: "~/org/inbox.org"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                    }
                    Button {
                        implicitWidth: 32
                        implicitHeight: 32
                        text: "×"
                        onClicked: quickNotePopup.visible = false
                        contentItem: Text { text: parent.text; color: muted; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 20 }
                        background: Rectangle { radius: 8; color: parent.hovered ? settingsRaised : "transparent" }
                    }
                }

                TextField {
                    id: quickNoteTitle
                    Layout.fillWidth: true
                    implicitHeight: 40
                    placeholderText: "Title (optional)"
                    color: foreground
                    placeholderTextColor: muted
                    selectionColor: highlight
                    font.family: "Noto Sans"
                    font.pixelSize: 11 * root.menuFontScale
                    leftPadding: 12
                    rightPadding: 12
                    background: Rectangle { color: settingsSurface; border.width: 1; border.color: quickNoteTitle.activeFocus ? accent : settingsOutline; radius: 9 }
                    Keys.onReturnPressed: event => {
                        if (event.modifiers & Qt.ControlModifier)
                            root.saveQuickNote()
                        else
                            quickNoteBody.forceActiveFocus(Qt.TabFocusReason)
                    }
                    Keys.onEscapePressed: quickNotePopup.visible = false
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    TextArea {
                        id: quickNoteBody
                        placeholderText: "Write a note..."
                        color: foreground
                        placeholderTextColor: muted
                        selectionColor: highlight
                        wrapMode: TextEdit.Wrap
                        font.family: "Noto Sans"
                        font.pixelSize: 11 * root.menuFontScale
                        leftPadding: 12
                        rightPadding: 12
                        topPadding: 10
                        bottomPadding: 10
                        background: Rectangle { color: settingsSurface; border.width: 1; border.color: quickNoteBody.activeFocus ? accent : settingsOutline; radius: 9 }
                        Keys.onPressed: event => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (event.modifiers & Qt.ControlModifier)) {
                                root.saveQuickNote()
                                event.accepted = true
                            }
                        }
                        Keys.onEscapePressed: quickNotePopup.visible = false
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: quickNoteBody.length + " characters"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                    Item { Layout.fillWidth: true }
                    Text { text: root.noteSaveError || (root.noteSaving ? "Saving..." : "Ctrl+Enter to save"); color: root.noteSaveError.length > 0 ? "#f38ba8" : muted; font.family: "JetBrains Mono"; font.pixelSize: 8; elide: Text.ElideRight; Layout.maximumWidth: 220 }
                    Button {
                        implicitWidth: 78
                        implicitHeight: 34
                        text: root.noteSaving ? "Saving..." : "Save"
                        enabled: !root.noteSaving && (quickNoteTitle.text.trim().length > 0 || quickNoteBody.text.trim().length > 0)
                        onClicked: root.saveQuickNote()
                        contentItem: Text { text: parent.text; color: parent.enabled ? background : muted; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "JetBrains Mono"; font.pixelSize: 9; font.weight: Font.DemiBold }
                        background: Rectangle { radius: 9; color: parent.enabled ? (parent.down ? foreground : accent) : settingsSurface; border.width: 1; border.color: parent.enabled ? accent : settingsOutline }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: calendarPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: (bar.width - width) / 2
        anchor.rect.y: bar.height + 8
        grabFocus: true
        color: "transparent"
        implicitWidth: Math.min(330 * menuScale, bar.width - 16)
        implicitHeight: 320

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true

            opacity: calendarPopup.visible ? 1.0 : 0.0
            scale: calendarPopup.visible ? 1.0 : 0.97
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
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        id: calendarPreviousButton
                        implicitWidth: 34
                        implicitHeight: 34
                        text: "‹"
                        onClicked: root.changeCalendarMonth(-1)
                        contentItem: Text {
                            text: calendarPreviousButton.text
                            color: calendarPreviousButton.down ? background : foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 22
                        }
                        background: Rectangle {
                            radius: 9
                            color: calendarPreviousButton.down ? accent : (calendarPreviousButton.hovered ? settingsRaised : settingsSurface)
                            border.width: 1
                            border.color: calendarPreviousButton.activeFocus || calendarPreviousButton.hovered ? accent : settingsOutline
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.calendarMonthName() + " " + root.calendarYear
                        color: foreground
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Button {
                        id: calendarTodayButton
                        implicitWidth: 54
                        implicitHeight: 30
                        text: "Today"
                        onClicked: root.resetCalendar()
                        contentItem: Text {
                            text: calendarTodayButton.text
                            color: calendarTodayButton.down ? background : foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9 * root.uiFontScale
                            font.weight: Font.DemiBold
                        }
                        background: Rectangle {
                            radius: 9
                            color: calendarTodayButton.down ? accent : (calendarTodayButton.hovered ? settingsRaised : settingsSurface)
                            border.width: 1
                            border.color: calendarTodayButton.activeFocus || calendarTodayButton.hovered ? accent : settingsOutline
                        }
                    }

                    Button {
                        id: calendarNextButton
                        implicitWidth: 34
                        implicitHeight: 34
                        text: "›"
                        onClicked: root.changeCalendarMonth(1)
                        contentItem: Text {
                            text: calendarNextButton.text
                            color: calendarNextButton.down ? background : foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 22
                        }
                        background: Rectangle {
                            radius: 9
                            color: calendarNextButton.down ? accent : (calendarNextButton.hovered ? settingsRaised : settingsSurface)
                            border.width: 1
                            border.color: calendarNextButton.activeFocus || calendarNextButton.hovered ? accent : settingsOutline
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 4
                    rowSpacing: 4

                    Repeater {
                        model: root.calendarWeekdayNames()
                        delegate: Text {
                            required property string modelData
                            Layout.fillWidth: true
                            text: modelData
                            color: muted
                            horizontalAlignment: Text.AlignHCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }

                    Repeater {
                        model: 42
                        delegate: Rectangle {
                            required property int index
                            readonly property int dayNumber: index - root.calendarFirstWeekday() + 1
                            readonly property bool inMonth: dayNumber > 0 && dayNumber <= root.calendarDaysInMonth()
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 7
                            color: inMonth && dayNumber === new Date().getDate() && root.calendarMonth === new Date().getMonth() && root.calendarYear === new Date().getFullYear() ? accent : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: parent.inMonth ? parent.dayNumber : ""
                                color: parent.color === accent ? background : foreground
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }

    VolumePopup {
        id: volumePopup
        shellRoot: root
        barWindow: bar
    }

    PopupWindow {
        id: networkPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - networkPopup.implicitWidth - 10
        anchor.rect.y: bar.height + 8
        grabFocus: true
        color: "transparent"
        implicitWidth: Math.min(300 * menuScale, bar.width - 40)
        implicitHeight: Math.min(562 * menuScale, bar.screen.height - bar.height - 12)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true

            opacity: networkPopup.visible ? 1.0 : 0.0
            scale: networkPopup.visible ? 1.0 : 0.97
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
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: accent
                        Text {
                            anchors.centerIn: parent
                            text: "󰀂"
                            color: background
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Network"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13 * root.menuFontScale
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.networkDetail
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10 * root.menuFontScale
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 8
                    color: "#171820"
                    border.width: 1
                    border.color: "#373b41"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        spacing: 3

                        Text {
                            text: root.networkInterface.length > 0 ? (root.networkType === "wifi" ? "Wi-Fi" : root.networkType === "ethernet" ? "Ethernet" : root.networkType) + "  •  " + root.networkInterface : "Disconnected"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10 * root.menuFontScale
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "IP " + (root.networkIp || "-")
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9 * root.menuFontScale
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "↓ " + root.networkDownloadMbps.toFixed(1) + " Mbps  ↑ " + root.networkUploadMbps.toFixed(1) + " Mbps"
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9 * root.menuFontScale
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    text: "󰖩  Open Network Manager"
                    onClicked: root.run(["wezterm", "-e", "nmtui"])
                    contentItem: Text {
                        text: parent.text
                        color: foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                    }
                    background: Rectangle {
                        radius: 7
                        color: parent.hovered ? "#252536" : "#171820"
                        border.width: 1
                        border.color: "#373b41"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#373b41"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: accent
                        Text {
                            anchors.centerIn: parent
                            text: "󱨈"
                            color: background
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Tailscale"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13 * root.menuFontScale
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: tailscaleState + "  •  " + tailscaleNodes.length + " nodes"
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10 * root.menuFontScale
                        }
                    }
                }

                ListView {
                    id: networkTailscaleList
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    clip: true
                    spacing: 4
                    model: root.tailscaleNodes

                    delegate: Rectangle {
                        required property var modelData
                        width: networkTailscaleList.width
                        height: 44
                        radius: 7
                        color: modelData.online ? "#171820" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 4
                                color: modelData.online ? "#a6e3a1" : muted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: modelData.name
                                    color: foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.address + (modelData.os.length > 0 ? "  " + modelData.os : "")
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.copyTailscaleAddress(modelData.address)
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    text: "󰫚  Mullvad"
                    onClicked: root.openExitNodePopup()
                    contentItem: Text {
                        text: parent.text
                        color: foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                    }
                    background: Rectangle {
                        radius: 7
                        color: parent.hovered ? "#252536" : "#171820"
                        border.width: 1
                        border.color: "#373b41"
                    }
                }
            }
        }
    }

    PopupWindow {
        id: bluetoothPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - bluetoothPopup.implicitWidth - 10
        anchor.rect.y: bar.height + 8
        grabFocus: true
        color: "transparent"
        implicitWidth: Math.min(300 * menuScale, bar.width - 40)
        implicitHeight: Math.min(392 * menuScale, bar.screen.height - bar.height - 12)

        onVisibleChanged: if (visible && bluetoothPopupExplicitlyOpened) root.refreshBluetoothDevices()

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true

            opacity: bluetoothPopup.visible ? 1.0 : 0.0
            scale: bluetoothPopup.visible ? 1.0 : 0.97
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
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: accent
                        Text {
                            anchors.centerIn: parent
                            text: "󰂯"
                            color: background
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Bluetooth"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13 * root.menuFontScale
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.bluetoothDetail
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10 * root.menuFontScale
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    PopupIconButton {
                        text: root.bluetoothEnabled ? "󰂲" : "󰂯"
                        enabled: root.bluetoothAvailable && !root.bluetoothActionBusy
                        foregroundColor: foreground
                        mutedColor: muted
                        accentColor: accent
                        hoverColor: settingsRaised
                        Accessible.name: root.bluetoothEnabled ? "Disable Bluetooth" : "Enable Bluetooth"
                        onClicked: root.setBluetoothEnabled(!root.bluetoothEnabled)
                    }
                }

                ListView {
                    id: bluetoothPopupList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 5
                    model: root.bluetoothDevices

                    delegate: Rectangle {
                        id: popupBluetoothDevice
                        required property var modelData
                        width: bluetoothPopupList.width
                        height: 48
                        radius: 8
                        color: modelData.connected ? settingsRaised : settingsSurface
                        border.width: 1
                        border.color: modelData.connected ? accent : settingsOutline

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 9
                            Text { text: modelData.connected ? "󰂱" : "󰂯"; color: modelData.connected ? accent : muted; font.family: "JetBrains Mono"; font.pixelSize: 15 }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text { Layout.fillWidth: true; text: popupBluetoothDevice.modelData.name || "Unknown device"; color: foreground; font.family: "Noto Sans"; font.pixelSize: 10 * root.menuFontScale; elide: Text.ElideRight }
                                Text {
                                    text: (popupBluetoothDevice.modelData.battery >= 0 ? popupBluetoothDevice.modelData.battery + "%  ·  " : "")
                                        + (popupBluetoothDevice.modelData.connected ? "Connected" : popupBluetoothDevice.modelData.paired ? "Paired" : "Ready to pair")
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8 * root.menuFontScale
                                }
                            }
                            Text { text: modelData.connected ? "Disconnect" : modelData.paired ? "Connect" : "Pair"; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 8 * root.menuFontScale }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.bluetoothActionBusy
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.connectBluetooth(popupBluetoothDevice.modelData.address, popupBluetoothDevice.modelData.connected, popupBluetoothDevice.modelData.paired)
                        }
                    }
                }

                Text {
                    visible: root.bluetoothDevices.length === 0
                    Layout.fillWidth: true
                    text: root.bluetoothScanning ? "Scanning for devices..." : root.bluetoothEnabled ? "No Bluetooth devices found" : "Bluetooth is disabled"
                    color: muted
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9 * root.menuFontScale
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    text: "󰂱  Open Bluetooth Manager"
                    onClicked: root.run(["wezterm", "-e", "bluetui"])
                    contentItem: Text {
                        text: parent.text
                        color: foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                    }
                    background: Rectangle {
                        radius: 7
                        color: parent.hovered ? "#252536" : "#171820"
                        border.width: 1
                        border.color: "#373b41"
                    }
                }
            }
        }
    }

    PopupWindow {
        id: tailscalePopup
        visible: root.tailscaleState === "Running"
        anchor.window: bar
        anchor.rect.x: bar.width - tailscalePopup.implicitWidth - 10
        anchor.rect.y: bar.height + 8
        grabFocus: true
        color: "transparent"
        implicitWidth: Math.min(340 * menuScale, bar.width - 16)
        implicitHeight: Math.min(420 * menuScale, bar.screen.height - bar.height - 12)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true

            opacity: tailscalePopup.visible ? 1.0 : 0.0
            scale: tailscalePopup.visible ? 1.0 : 0.97
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
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        radius: 17
                        color: accent
                        Text {
                            anchors.centerIn: parent
                            text: "󱨈"
                            color: background
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Tailscale"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: tailscaleState + "  •  " + tailscaleNodes.length + " nodes"
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }
                }

                ListView {
                    id: tailscaleList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.tailscaleNodes

                    delegate: Rectangle {
                        required property var modelData
                        width: tailscaleList.width
                        height: 44
                        radius: 7
                        color: modelData.online ? "#171820" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 4
                                color: modelData.online ? "#a6e3a1" : muted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: modelData.name
                                    color: foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.address + (modelData.os.length > 0 ? "  " + modelData.os : "")
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.copyTailscaleAddress(modelData.address)
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: exitNodePopup
        visible: false
        anchor.window: networkPopup
        anchor.rect.x: networkPopup.width - exitNodePopup.implicitWidth
        anchor.rect.y: networkPopup.height + 4
        grabFocus: true
        color: "transparent"
        implicitWidth: Math.min(300 * menuScale, bar.width - 16)
        implicitHeight: Math.min(360 * menuScale, bar.screen.height - bar.height - 12)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true

            opacity: exitNodePopup.visible ? 1.0 : 0.0
            scale: exitNodePopup.visible ? 1.0 : 0.97
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

                Text {
                    text: "󰫚  Mullvad"
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Route internet traffic through Tailscale"
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                }

                Button {
                    visible: root.bestExitNode.length > 0
                    Layout.fillWidth: true
                    implicitHeight: 34
                    text: "󰒓  Use suggested exit node"
                    onClicked: root.selectExitNode(root.bestExitNode)
                    contentItem: Text {
                        text: parent.text
                        color: foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideMiddle
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                    }
                    background: Rectangle {
                        radius: 7
                        color: parent.hovered ? "#252536" : "#171820"
                        border.width: 1
                        border.color: parent.hovered ? accent : "#373b41"
                    }
                }

                Text {
                    visible: root.bestExitNode.length > 0
                    text: "Suggested: " + root.bestExitNode
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    text: "󰅖  Disconnect exit node"
                    onClicked: root.clearExitNode()
                    contentItem: Text {
                        text: parent.text
                        color: foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11
                    }
                    background: Rectangle {
                        radius: 7
                        color: parent.hovered ? "#252536" : "#171820"
                        border.width: 1
                        border.color: "#373b41"
                    }
                }

                ListView {
                    id: exitNodeList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.exitNodes

                    delegate: Rectangle {
                        required property var modelData
                        width: exitNodeList.width
                        height: 44
                        radius: 7
                            color: modelData.active ? "#252536" : (modelData.online ? "#171820" : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 8
                                Layout.preferredHeight: 8
                                radius: 4
                                color: modelData.online ? "#a6e3a1" : muted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: modelData.name + (modelData.active ? "  (active)" : "")
                                    color: foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.address
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 9
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.selectExitNode(modelData.address)
                        }
                    }
                }

                Text {
                    visible: root.exitNodes.length === 0
                    text: "No Mullvad exit nodes available"
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                }
            }
        }
    }

    PopupWindow {
        id: trayPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - trayPopup.implicitWidth - 10
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 1
        implicitHeight: 1
    }

    PopupWindow {
        id: notificationPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - notificationPopup.implicitWidth - 10
        anchor.rect.y: bar.height + 8
        grabFocus: true
        color: "transparent"
        implicitWidth: Math.min(420 * menuScale, bar.width - 16)
        implicitHeight: Math.min(620 * menuScale, bar.screen.height - bar.height - 12)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true

            opacity: notificationPopup.visible ? 1.0 : 0.0
            scale: notificationPopup.visible ? 1.0 : 0.97
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
                        text: "Notifications"
                        color: foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15 * root.menuFontScale
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: notificationServer.trackedNotifications.values.length
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13 * root.menuFontScale
                    }

                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    text: "Clear all"
                    onClicked: {
                        const notifications = notificationServer.trackedNotifications.values.slice()
                        for (const notification of notifications)
                            notification.dismiss()
                    }
                    contentItem: Text {
                        text: parent.text
                        color: foreground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: "JetBrains Mono"
                        font.pixelSize: 11 * root.menuFontScale
                    }
                    background: Rectangle {
                        radius: 7
                        color: parent.hovered ? "#252536" : "#171820"
                        border.width: 1
                        border.color: "#373b41"
                    }
                }

                ListView {
                    id: notificationList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: notificationServer.trackedNotifications

                    delegate: Rectangle {
                        id: notificationCard
                        required property var modelData
                        readonly property color urgencyColor: modelData.urgency === 2 ? "#f38ba8" : (modelData.urgency === 0 ? muted : accent)
                        width: notificationList.width
                        height: notificationCardContent.implicitHeight + 24
                        radius: 8
                        color: "#171820"
                        border.width: 1
                        border.color: urgencyColor
                        clip: true

                        ColumnLayout {
                            id: notificationCardContent
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    radius: 7
                                    color: settingsRaised
                                    clip: true
                                    Image {
                                        id: notificationIcon
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        source: root.notificationImage(modelData)
                                        visible: source.toString().length > 0
                                        fillMode: Image.PreserveAspectFit
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        visible: !notificationIcon.visible || notificationIcon.status === Image.Error
                                        text: "󰂚"
                                        color: notificationCard.urgencyColor
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 13
                                    }
                                }
                                Text {
                                    text: modelData.appName || "Notification"
                                    color: notificationCard.urgencyColor
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10 * root.menuFontScale
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: root.notificationTime(modelData.id)
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8 * root.menuFontScale
                                }
                                PopupIconButton {
                                    text: "×"
                                    implicitWidth: 26
                                    implicitHeight: 26
                                    foregroundColor: foreground
                                    mutedColor: muted
                                    accentColor: notificationCard.urgencyColor
                                    hoverColor: settingsRaised
                                    Accessible.name: "Dismiss notification"
                                    onClicked: modelData.dismiss()
                                }
                            }

                            Text {
                                text: modelData.summary
                                color: foreground
                                font.family: "JetBrains Mono"
                                font.pixelSize: 12 * root.menuFontScale
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                id: notificationBody
                                text: modelData.body
                                color: muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10 * root.menuFontScale
                                textFormat: Text.PlainText
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                maximumLineCount: 5
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.minimumHeight: 18
                            }
                        }
                    }
                }

                Text {
                    visible: notificationServer.trackedNotifications.values.length === 0
                    text: "No notifications"
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11 * root.menuFontScale
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Timer {
        id: notificationToastTimer
        interval: toastNotification && toastNotification.expireTimeout > 0 ? toastNotification.expireTimeout * 1000 : 5000
        repeat: false
        onTriggered: root.clearNotificationToast("expire")
    }

    PopupWindow {
        id: notificationToast
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - width - 12
        anchor.rect.y: bar.height + 12
        color: "transparent"
        implicitWidth: Math.min(380, bar.width - 24)
        implicitHeight: notificationToastContent.implicitHeight + 28

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: accent
            radius: 1
            clip: true

            ColumnLayout {
                id: notificationToastContent
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 7
                        color: settingsRaised
                        clip: true
                        Image {
                            id: toastIcon
                            anchors.fill: parent
                            anchors.margins: 4
                            source: root.notificationImage(toastNotification)
                            visible: source.toString().length > 0
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !toastIcon.visible || toastIcon.status === Image.Error
                            text: "󰂚"
                            color: toastNotification && toastNotification.urgency === 2 ? "#f38ba8" : accent
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                    }

                    Text {
                        text: toastNotification && toastNotification.appName ? toastNotification.appName : "Notification"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.menuFontScale
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: toastNotification ? Qt.formatDateTime(new Date(toastNotification.receivedAt), "HH:mm") : ""
                        color: muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 8 * root.menuFontScale
                    }

                    PopupIconButton {
                        text: "×"
                        implicitWidth: 26
                        implicitHeight: 26
                        foregroundColor: foreground
                        mutedColor: muted
                        accentColor: accent
                        hoverColor: settingsRaised
                        Accessible.name: "Dismiss notification"
                        onClicked: root.clearNotificationToast("dismiss")
                    }
                }

                Text {
                    text: toastNotification ? toastNotification.summary : ""
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12 * root.menuFontScale
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                }

                Text {
                    text: toastNotification ? toastNotification.body : ""
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10 * root.menuFontScale
                    textFormat: Text.PlainText
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    Layout.fillWidth: true
                    Layout.minimumHeight: 0
                    Layout.preferredHeight: implicitHeight
                }

                RowLayout {
                    visible: toastNotification !== null && toastNotification.actions.length > 0
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: toastNotification ? toastNotification.actions : []

                        delegate: Button {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            text: modelData.text
                            onClicked: {
                                root.invokeToastAction(modelData)
                            }
                            contentItem: Text {
                                text: parent.text
                                color: foreground
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9 * root.menuFontScale
                                elide: Text.ElideRight
                                clip: true
                            }
                            background: Rectangle {
                                radius: 1
                                color: parent.hovered ? "#252536" : "#171820"
                                border.width: 1
                                border.color: "#373b41"
                            }
                        }
                    }
                }
            }
        }
    }

    Window {
        id: powerPopup
        visible: false
        title: "Power Menu"
        x: root.centerX(width)
        y: root.centerY(height)
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool | Qt.BypassWindowManagerHint
        color: "transparent"
        width: root.primaryScreen() ? Math.max(1, Math.min(560 * menuScale, root.primaryScreen().width - 32)) : 560 * menuScale
        height: 180 * menuScale

        onVisibleChanged: {
            if (visible) {
                powerIndex = 0
                pendingPowerIndex = -1
                powerFocusTimer.restart()
            }
        }

        onActiveChanged: {
            if (active) {
                powerDismissTimer.stop()
                powerFocusTimer.restart()
            } else if (visible) {
                powerDismissTimer.restart()
            }
        }

        function activatePowerMenu() {
            requestActivate()
            powerContent.forceActiveFocus(Qt.OtherFocusReason)
        }

        Timer {
            id: powerFocusTimer
            interval: 50
            repeat: false
            onTriggered: powerPopup.activatePowerMenu()
        }

        Timer {
            id: powerDismissTimer
            interval: 100
            repeat: false
            onTriggered: {
                if (!powerPopup.active)
                    powerPopup.visible = false
            }
        }

        Rectangle {
            id: powerContent
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true
            focus: true

            opacity: powerPopup.visible ? 1.0 : 0.0
            scale: powerPopup.visible ? 1.0 : 0.97
            Behavior on opacity {
                enabled: !root.reducedMotion
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                enabled: !root.reducedMotion
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Up:
                case Qt.Key_Left:
                    powerIndex = (powerIndex + root.powerActions.length - 1) % root.powerActions.length
                    event.accepted = true
                    break
                case Qt.Key_Down:
                case Qt.Key_Right:
                case Qt.Key_Tab:
                    powerIndex = (powerIndex + 1) % root.powerActions.length
                    event.accepted = true
                    break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.activatePowerAction(powerIndex)
                    event.accepted = true
                    break
                case Qt.Key_Escape:
                    root.closePopups()
                    event.accepted = true
                    break
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    spacing: 8
                    Text {
                        text: "󰐥"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 17 * root.menuFontScale
                    }
                    Text {
                        text: "Power menu"
                        color: foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15 * root.menuFontScale
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.powerActions

                        delegate: Button {
                            id: powerButton
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 92
                            focusPolicy: Qt.NoFocus
                            readonly property bool selected: index === root.powerIndex
                            Accessible.name: root.pendingPowerIndex === index ? "Confirm " + modelData.label : modelData.label
                            onClicked: root.activatePowerAction(index)
                            contentItem: ColumnLayout {
                                spacing: 6
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: powerButton.selected ? accent : foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 24
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.pendingPowerIndex === index ? "Confirm " + modelData.label : modelData.label
                                    color: foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                }
                            }
                            background: Rectangle {
                                radius: 8
                                color: parent.hovered || parent.selected ? "#252536" : "#171820"
                                border.width: 1
                                border.color: parent.selected ? accent : "#373b41"
                            }
                        }
                    }
                }
            }
        }
    }

    Window {
        id: screenshotPopup
        visible: false
        title: "Screenshot"
        x: root.centerX(width)
        y: root.centerY(height)
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
        color: "transparent"
        width: 560 * menuScale
        height: 180 * menuScale

        onVisibleChanged: {
            if (visible) {
                screenshotIndex = 0
                screenshotFocusTimer.restart()
            }
        }

        onActiveChanged: {
            if (active) {
                screenshotDismissTimer.stop()
                screenshotFocusTimer.restart()
            } else if (visible) {
                screenshotDismissTimer.restart()
            }
        }

        function activateScreenshotMenu() {
            requestActivate()
            screenshotContent.forceActiveFocus(Qt.OtherFocusReason)
        }

        Timer {
            id: screenshotFocusTimer
            interval: 50
            repeat: false
            onTriggered: screenshotPopup.activateScreenshotMenu()
        }

        Timer {
            id: screenshotDismissTimer
            interval: 100
            repeat: false
            onTriggered: {
                if (!screenshotPopup.active)
                    screenshotPopup.visible = false
            }
        }

        Rectangle {
            id: screenshotContent
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: settingsOutline
            radius: 12
            clip: true
            focus: true

            opacity: screenshotPopup.visible ? 1.0 : 0.0
            scale: screenshotPopup.visible ? 1.0 : 0.97
            Behavior on opacity {
                enabled: !root.reducedMotion
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                enabled: !root.reducedMotion
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Up:
                case Qt.Key_Left:
                    screenshotIndex = (screenshotIndex + root.screenshotActions.length - 1) % root.screenshotActions.length
                    event.accepted = true
                    break
                case Qt.Key_Down:
                case Qt.Key_Right:
                case Qt.Key_Tab:
                    screenshotIndex = (screenshotIndex + 1) % root.screenshotActions.length
                    event.accepted = true
                    break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    const screenshotAction = root.screenshotActions[screenshotIndex]
                    if (screenshotAction.mode.length > 0)
                        root.takeScreenshot(screenshotAction.mode)
                    else
                        root.closePopups()
                    event.accepted = true
                    break
                case Qt.Key_Escape:
                    screenshotPopup.visible = false
                    event.accepted = true
                    break
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    spacing: 8
                    Text {
                        text: "󰄀"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 17 * root.menuFontScale
                    }
                    Text {
                        text: "Screenshot"
                        color: foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15 * root.menuFontScale
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: root.screenshotActions

                        delegate: Button {
                            id: screenshotButton
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 92
                            focusPolicy: Qt.NoFocus
                            readonly property bool selected: index === root.screenshotIndex
                            onClicked: {
                                root.screenshotIndex = index
                                if (modelData.mode.length > 0)
                                    root.takeScreenshot(modelData.mode)
                                else
                                    root.closePopups()
                            }
                            contentItem: ColumnLayout {
                                spacing: 6
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.icon
                                    color: screenshotButton.selected ? accent : foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 24
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
                                }
                            }
                            background: Rectangle {
                                radius: 8
                                color: parent.hovered || parent.selected ? "#252536" : "#171820"
                                border.width: 1
                                border.color: parent.selected ? accent : "#373b41"
                            }
                        }
                    }
                }
            }
        }
    }

    Window {
        id: displayConfirmation
        visible: false
        title: "Confirm display settings"
        x: root.centerX(width)
        y: root.centerY(height)
        width: root.primaryScreen() ? Math.min(390, root.primaryScreen().width - 24) : 390
        height: 160
        flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        modality: Qt.ApplicationModal
        color: "transparent"

        Shortcut { sequence: "Escape"; context: Qt.WindowShortcut; onActivated: root.revertDisplayLayout() }

        Rectangle {
            anchors.fill: parent
            color: background
            border.width: 1
            border.color: accent
            radius: 12
            clip: true

            opacity: displayConfirmation.visible ? 1.0 : 0.0
            scale: displayConfirmation.visible ? 1.0 : 0.97
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
                spacing: 10
                Text { Layout.fillWidth: true; text: "Keep these display settings?"; color: foreground; font.family: "Noto Sans"; font.pixelSize: 16 * root.menuFontScale; font.weight: Font.DemiBold }
                Text { Layout.fillWidth: true; text: "The previous layout will be restored automatically in 15 seconds."; color: muted; wrapMode: Text.Wrap; font.family: "JetBrains Mono"; font.pixelSize: 9 * root.menuFontScale }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8
                    Button { text: "Revert"; onClicked: root.revertDisplayLayout() }
                    Button { text: displayQuery.running || root.displayRefreshPending ? "Reading layout..." : "Keep changes"; enabled: !displayQuery.running && !root.displayRefreshPending; highlighted: true; onClicked: root.keepDisplayLayout() }
                }
            }
        }
    }

    Window {
        id: polkitWindow
        title: "Authentication Required"
        visible: polkitAgent.isActive
        x: root.centerX(width)
        y: root.centerY(height)
        flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        modality: Qt.ApplicationModal
        color: "transparent"
        width: 320 * menuScale
        height: 200 * menuScale

        onVisibleChanged: {
            response.clear()
            if (visible)
                polkitFocusTimer.restart()
        }

        onActiveChanged: {
            if (active)
                polkitFocusTimer.restart()
        }

        Timer {
            id: polkitFocusTimer
            interval: 50
            repeat: false
            onTriggered: {
                polkitWindow.requestActivate()
                response.forceActiveFocus(Qt.OtherFocusReason)
                response.selectAll()
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: background
            border.width: 1
            border.color: accent
            clip: true

            opacity: polkitWindow.visible ? 1.0 : 0.0
            scale: polkitWindow.visible ? 1.0 : 0.97
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
                anchors.margins: 12
                spacing: 6

                Text {
                    text: polkitAgent.flow ? polkitAgent.flow.message : "Authentication required"
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12 * root.menuFontScale
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Text {
                    text: polkitAgent.flow ? polkitAgent.flow.supplementaryMessage : ""
                    color: polkitAgent.flow && polkitAgent.flow.supplementaryIsError ? "#f38ba8" : muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9 * root.menuFontScale
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                    Layout.fillWidth: true
                }

                Text {
                    text: polkitAgent.flow ? polkitAgent.flow.inputPrompt : "Password"
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 9 * root.menuFontScale
                    visible: polkitAgent.flow ? polkitAgent.flow.isResponseRequired : true
                }

                TextField {
                    id: response
                    visible: polkitAgent.flow ? polkitAgent.flow.isResponseRequired : true
                    Layout.fillWidth: true
                    echoMode: polkitAgent.flow && polkitAgent.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    placeholderTextColor: muted
                    placeholderText: "Enter password"
                    color: foreground
                    selectionColor: highlight
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    background: Rectangle {
                        color: "#171820"
                        radius: 5
                        border.width: 1
                        border.color: response.activeFocus ? accent : muted
                    }
                    Keys.onReturnPressed: if (submitButton.enabled) submitButton.clicked()
                    Keys.onEscapePressed: if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    Button {
                        implicitWidth: 70
                        implicitHeight: 28
                        text: "Cancel"
                        onClicked: if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
                        contentItem: Text {
                            text: parent.text
                            color: foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                        }
                        background: Rectangle {
                            radius: 5
                            color: parent.pressed ? "#313244" : (parent.hovered ? "#252536" : "#171820")
                            border.width: 1
                            border.color: parent.hovered ? muted : "#373b41"
                        }
                    }

                    Button {
                        id: submitButton
                        implicitWidth: 110
                        implicitHeight: 28
                        text: "Authenticate"
                        highlighted: true
                        enabled: polkitAgent.flow !== null && (!polkitAgent.flow.isResponseRequired || response.text.length > 0)
                        onClicked: if (polkitAgent.flow) polkitAgent.flow.submit(response.text)
                        contentItem: Text {
                            text: parent.text
                            color: root.background
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                        background: Rectangle {
                            radius: 5
                            color: parent.pressed ? foreground : (parent.hovered ? foreground : accent)
                            border.width: 1
                            border.color: accent
                        }
                    }
                }
            }
        }
    }

    SettingsWindow { id: settingsWindow; root: root }

    WallpaperViewer { id: wallpaperViewer; root: root }

    Launcher { id: launcher; root: root }

    ColorPicker { id: colorPicker; root: root }
}
