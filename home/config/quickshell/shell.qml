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

ShellRoot {
    id: root
    readonly property color background: "#0E0E12"
    readonly property color foreground: "#cbd0ec"
    readonly property color muted: "#6c7086"
    readonly property color empty: "#414456"
    readonly property color accent: "#bfc9f4"
    readonly property color highlight: "#cba6f7"
    readonly property real menuScale: 1.0
    readonly property real menuFontScale: 1.2

    property string activeDesktop: "1"
    property string activeTitle: "Desktop"
    property string audioStatus: ""
    property string networkStatus: ""
    property string bluetoothStatus: ""
    property string audioDetail: "Default sink"
    property string networkDetail: "Disconnected"
    property string bluetoothDetail: "No connected devices"
    property var currentPlayer: null
    property var wallpapers: []
    property string selectedWallpaper: ""
    property string settingsPage: "Audio"
    property string bspLayout: "tiled"
    property real volumeLevel: 50
    property bool launcherVisible: false
    property string tailscaleState: "Stopped"
    property var tailscaleNodes: []
    property var exitNodes: []
    property string bestExitNode: ""
    property string activeExitNodeName: ""
    property string activeExitNodeAddress: ""
    property string publicIp: ""
    property string networkInterface: ""
    property string networkType: ""
    property string networkIp: ""
    property double networkDownloadMbps: 0
    property double networkUploadMbps: 0
    property double previousRxBytes: -1
    property double previousTxBytes: -1
    property real micVolumeLevel: 0
    property bool micMuted: false
    property bool outputMuted: false
    property string micName: "Default microphone"
    property var audioSinks: []
    property var audioSources: []
    property var bluetoothDevices: []
    property var networkDevices: []
    property var displays: []
    property bool bluetoothScanning: false
    property bool networkScanning: false
    property string defaultSinkName: ""
    property string defaultSourceName: ""
    property var workspaceStates: []
    property int batteryCapacity: -1
    property string batteryStatus: ""
    property var toastNotification: null
    readonly property var powerActions: [
        { label: "󰗼  Logout", command: ["bspc", "quit"] },
        { label: "󰐥  Shutdown", command: ["systemctl", "poweroff"] },
        { label: "󰜉  Reboot", command: ["systemctl", "reboot"] },
        { label: "󰌾  Lock", command: ["xsecurelock"] }
    ]
    property int powerIndex: 0
    property int screenshotIndex: 0
    readonly property var screenshotActions: [
        { label: "󰍹  Fullscreen", mode: "fullscreen" },
        { label: "󰩭  Region", mode: "region" },
        { label: "󰖯  Window", mode: "window" }
    ]
    property int calendarYear: new Date().getFullYear()
    property int calendarMonth: new Date().getMonth()
    property string activeWindowId: ""
    property bool popupsReady: false

    Component.onCompleted: {
        popupsReady = true
        refreshNowPlaying()
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
            root.showNotificationToast(notification)
        }
    }

    PolkitAgent {
        id: polkitAgent
    }

    function updateBspwm(output) {
        const fields = output.split("\n").map(field => field.trim())
        if (fields.length > 0 && fields[0].length > 0)
            activeDesktop = fields[0]
    }

    function showNotificationToast(notification) {
        toastNotification = notification
        notificationToast.visible = true
        notificationToastTimer.restart()
    }

    function updateWorkspaces(output) {
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

    function updateBattery(output) {
        const fields = output.trim().split("\n")
        batteryCapacity = fields.length > 0 && !isNaN(Number(fields[0])) ? Number(fields[0]) : -1
        batteryStatus = fields.length > 1 ? fields[1] : ""
    }

    function updateActiveTitle(output) {
        const title = output.trim()
        activeTitle = title.length > 0 ? title : "Desktop"
    }

    function updateStatus(output) {
        const fields = output.trim().split("\n")
        audioStatus = fields.length > 0 ? fields[0].trim() : ""
        outputMuted = fields.length > 7 && fields[7].trim() === "yes"
        networkStatus = fields.length > 1 ? fields[1].trim() : ""
        bluetoothStatus = fields.length > 2 ? fields[2].trim() : ""
        if (fields.length > 3 && !isNaN(Number(fields[3].trim())))
            volumeLevel = Number(fields[3].trim())
        audioDetail = fields.length > 4 ? fields[4].trim() : "Default sink"
        defaultSinkName = fields.length > 4 ? fields[4].trim() : ""
        networkDetail = fields.length > 5 ? fields[5].trim() : "Disconnected"
        bluetoothDetail = fields.length > 6 ? fields[6].trim() : "No connected devices"
    }

    function updateNetworkMetrics(output) {
        const fields = output.trim().split("\n")
        const rxBytes = fields.length > 5 ? Number(fields[5]) : 0
        const txBytes = fields.length > 6 ? Number(fields[6]) : 0
        if (previousRxBytes >= 0 && rxBytes >= previousRxBytes)
            networkDownloadMbps = (rxBytes - previousRxBytes) * 8 / 1000000
        if (previousTxBytes >= 0 && txBytes >= previousTxBytes)
            networkUploadMbps = (txBytes - previousTxBytes) * 8 / 1000000
        previousRxBytes = rxBytes
        previousTxBytes = txBytes
        networkInterface = fields.length > 0 ? fields[0] : ""
        networkType = fields.length > 1 ? fields[1] : ""
        networkIp = fields.length > 3 ? fields[3] : ""
        if (networkInterface.length === 0) {
            networkDownloadMbps = 0
            networkUploadMbps = 0
        }
    }

    function refreshNowPlaying() {
        const players = Mpris.players.values
        currentPlayer = null
        for (let i = 0; i < players.length; i++) {
            if (players[i] && players[i].isPlaying) {
                currentPlayer = players[i]
                return
            }
        }
        if (players.length > 0)
            currentPlayer = players[0]
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

    function floatActiveWindow(width, height, x, y) {
        run(["sh", "-c", "sleep 0.1; id=$(xdotool getactivewindow 2>/dev/null); [ -n \"$id\" ] && bspc node -t floating && xdotool windowsize \"$id\" " + width + " " + height + " && xdotool windowmove \"$id\" " + x + " " + y])
    }

    function setVolume(value) {
        volumeLevel = value * 100
        run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", Math.round(volumeLevel) + "%"])
    }

    function setMicVolume(value) {
        micVolumeLevel = value * 100
        run(["pactl", "set-source-volume", "@DEFAULT_SOURCE@", Math.round(micVolumeLevel) + "%"])
    }

    function toggleMicMute() {
        run(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"])
        micMuted = !micMuted
    }

    function applyWallpaper(path) {
        selectedWallpaper = path
        run(["feh", "--bg-fill", path])
    }

    function openSettings(page) {
        settingsPage = page
        refreshAudioDevices()
        refreshBluetoothDevices()
        refreshDisplays()
        settingsWindow.visible = true
        settingsWindow.requestActivate()
    }

    function applyBspLayout(layout) {
        bspLayout = layout
        run(["bsp-layout", "set", layout])
        layoutPopup.visible = false
    }

    function layoutIcon(layout) {
        return layout === "tall" ? "▮▯" : layout === "monocle" ? "▣" : "⊞"
    }

    function connectBluetooth(address) {
        run(["bluetoothctl", "connect", address])
        refreshBluetoothDevices()
    }

    function connectNetwork(ssid) {
        run(["nmcli", "connection", "up", ssid])
    }

    function updateDisplays(output) {
        const result = []
        for (const line of output.trim().split("\n")) {
            const fields = line.split("\t")
            if (fields.length < 5)
                continue
            let display = result.find(item => item.name === fields[0])
            if (!display) {
                display = { name: fields[0], state: fields[1], primary: fields[2] === "primary", mode: fields[3], refresh: fields[4], modes: [] }
                result.push(display)
            }
            const option = { label: fields[3] + "  @  " + fields[4] + " Hz", mode: fields[3], refresh: fields[4], selected: fields[5] === "selected" }
            display.modes.push(option)
            if (option.selected) {
                display.mode = option.mode
                display.refresh = option.refresh
            }
        }
        displays = result
    }

    function refreshDisplays() {
        if (!displayQuery.running)
            displayQuery.running = true
    }

    function setPrimaryDisplay(name) {
        run(["xrandr", "--output", name, "--primary"])
        for (const display of displays)
            display.primary = display.name === name
        persistDisplayLayout()
        refreshDisplays()
    }

    function setDisplayMode(name, mode, refresh) {
        for (const display of displays) {
            if (display.name === name) {
                display.mode = mode
                display.refresh = refresh
                for (const option of display.modes)
                    option.selected = option.mode === mode && option.refresh === refresh
            }
        }
        run(["xrandr", "--output", name, "--mode", mode, "--rate", refresh])
        persistDisplayLayout()
        refreshDisplays()
    }

    function shellQuote(value) {
        return "'" + value.replace(/'/g, "'\\''") + "'"
    }

    function persistDisplayLayout() {
        const commands = ["#!/usr/bin/env sh"]
        for (const display of displays) {
            if (display.state !== "connected")
                continue
            commands.push("xrandr --output " + shellQuote(display.name) + " --mode " + shellQuote(display.mode) + " --rate " + shellQuote(display.refresh))
            if (display.primary)
                commands.push("xrandr --output " + shellQuote(display.name) + " --primary")
        }
        const script = commands.join("\n") + "\n"
        run(["sh", "-c", "mkdir -p \"$HOME/.config/bspwm\"; printf '%s' " + shellQuote(script) + " > \"$HOME/.config/bspwm/display-layout.sh\"; chmod +x \"$HOME/.config/bspwm/display-layout.sh\""])
    }

    function updateMicStatus(output) {
        const fields = output.trim().split("\n")
        if (fields.length > 0 && !isNaN(Number(fields[0])))
            micVolumeLevel = Number(fields[0])
        micMuted = fields.length > 1 && fields[1] === "yes"
        micName = fields.length > 2 && fields[2].length > 0 ? fields[2] : "Default microphone"
        defaultSourceName = fields.length > 2 ? fields[2] : ""
    }

    function updateAudioDevices(output, isSource) {
        try {
            const devices = JSON.parse(output)
            if (isSource)
                audioSources = devices
            else
                audioSinks = devices
        } catch (error) {
            if (isSource)
                audioSources = []
            else
                audioSinks = []
        }
    }

    function deviceLabel(device) {
        const label = device.description || device.name || "Unknown device"
        return label.replace(/^(alsa_output|alsa_input)\.[^ ]+\s*/, "").replace(/\s+\([^)]*\)$/, "")
    }

    function updateBluetoothDevices(output) {
        const devices = []
        for (const line of output.trim().split("\n")) {
            const fields = line.split("\t")
            if (fields.length >= 2 && fields[0].length > 0)
                devices.push({ address: fields[0], name: fields.slice(1).join("\t") })
        }
        bluetoothDevices = devices
    }

    function updateNetworkDevices(output) {
        const devices = []
        for (const line of output.trim().split("\n")) {
            const fields = line.split("\t")
            if (fields.length >= 4 && fields[1].length > 0)
                devices.push({ active: fields[0] === "*", ssid: fields[1], signal: fields[2], security: fields[3] || "Open" })
        }
        networkDevices = devices
    }

    function setDefaultSink(name) {
        run(["pactl", "set-default-sink", name])
        defaultSinkName = name
    }

    function setDefaultSource(name) {
        run(["pactl", "set-default-source", name])
        defaultSourceName = name
    }

    function refreshAudioDevices() {
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

    function scanNetworks() {
        networkScanning = true
        if (!networkDevicesQuery.running)
            networkDevicesQuery.running = true
    }

    function closePopups() {
        if (!popupsReady)
            return
        volumePopup.visible = false
        networkPopup.visible = false
        bluetoothPopup.visible = false
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
    }

    function togglePopup(popup) {
        const shouldOpen = !popup.visible
        closePopups()
        popup.visible = shouldOpen
        if (shouldOpen && popup === exitNodePopup)
            refreshExitSuggestion()
    }

    function openExitNodePopup() {
        networkPopup.visible = true
        exitNodePopup.visible = true
        refreshExitSuggestion()
    }

    function updateActiveWindow(id) {
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

    function updateTailscale(output) {
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
        run(["tailscale", "set", "--exit-node", address])
        exitNodePopup.visible = false
        networkPopup.visible = true
    }

    function refreshExitSuggestion() {
        if (!bestExitNodeQuery.running)
            bestExitNodeQuery.running = true
    }

    function updateExitConfig(output) {
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
        run(["tailscale", "set", "--exit-node", ""])
        exitNodePopup.visible = false
        networkPopup.visible = true
    }

    function calendarMonthName() {
        return ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][calendarMonth]
    }

    function calendarDaysInMonth() {
        return new Date(calendarYear, calendarMonth + 1, 0).getDate()
    }

    function calendarFirstWeekday() {
        return new Date(calendarYear, calendarMonth, 1).getDay()
    }

    function changeCalendarMonth(amount) {
        const date = new Date(calendarYear, calendarMonth + amount, 1)
        calendarYear = date.getFullYear()
        calendarMonth = date.getMonth()
    }

    function takeScreenshot(mode) {
        const capture = mode === "fullscreen" ? "maim -u \"$output\"" : mode === "region" ? "maim -s -u \"$output\"" : "maim -s -b 2 -c 0.3,0.6,1.0,1 -f png \"$output\""
        run(["sh", "-c", "sleep 0.3; mkdir -p \"$HOME/Pictures/Screenshots\"; output=\"$HOME/Pictures/Screenshots/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png\"; " + capture + "; if [ -f \"$output\" ]; then command -v xclip >/dev/null 2>&1 && xclip -selection clipboard -target image/png -i \"$output\"; command -v notify-send >/dev/null 2>&1 && notify-send \"Screenshot saved\" \"$output\" --icon=\"$output\" --expire-time=4000; fi"])
        screenshotPopup.visible = false
    }

    Process {
        id: bspwmQuery
        command: ["bspc", "query", "-D", "-d", "--names"]
        running: true
        stdout: StdioCollector {
            id: bspwmOutput
            onStreamFinished: root.updateBspwm(bspwmOutput.text)
        }
        onExited: running = true
    }

    Process {
        id: workspaceQuery
        command: ["sh", "-c", "printf '%s\\n---\\n%s\\n---\\n%s\\n' \"$(bspc query -D --names 2>/dev/null)\" \"$(bspc query -D .occupied --names 2>/dev/null)\" \"$(bspc query -D .urgent --names 2>/dev/null)\""]
        running: true
        stdout: StdioCollector {
            id: workspaceOutput
            onStreamFinished: root.updateWorkspaces(workspaceOutput.text)
        }
        onExited: running = true
    }

    Process {
        id: batteryQuery
        command: ["sh", "-c", "battery=; for dir in /sys/class/power_supply/BAT*; do if [ -d \"$dir\" ]; then battery=\"$dir\"; break; fi; done; if [ -n \"$battery\" ]; then cat \"$battery/capacity\"; cat \"$battery/status\"; else printf '%s\\n' -1 unavailable; fi"]
        running: true
        stdout: StdioCollector {
            id: batteryOutput
            onStreamFinished: root.updateBattery(batteryOutput.text)
        }
        onExited: running = true
    }

    Process {
        id: windowTitleQuery
        command: ["sh", "-c", "id=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $5}'); title=; if [ -n \"$id\" ] && [ \"$id\" != \"0x0\" ]; then title=$(xprop -id \"$id\" _NET_WM_NAME 2>/dev/null | cut -d '\"' -f2); [ -z \"$title\" ] && title=$(xprop -id \"$id\" WM_NAME 2>/dev/null | cut -d '\"' -f2); fi; printf '%s\\n' \"$title\""]
        running: true
        stdout: StdioCollector {
            id: windowTitleOutput
            onStreamFinished: root.updateActiveTitle(windowTitleOutput.text)
        }
        onExited: {
            root.updateActiveTitle(windowTitleOutput.text)
            running = true
        }
    }

    Process {
        id: statusQuery
        command: ["sh", "-c", "volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk 'NR==1 {gsub(/%/,\"\",$5); print $5}'); mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}'); [ \"$mute\" = yes ] && audio='󰝟' || audio='󰕾'; sink=$(pactl get-default-sink 2>/dev/null); [ -z \"$sink\" ] && sink='Default sink'; network=$(nmcli -t -f GENERAL.STATE device show 2>/dev/null | head -n1 | cut -d: -f2-); connection=$(nmcli -t -f GENERAL.CONNECTION device show 2>/dev/null | sed -n 's/^GENERAL.CONNECTION://p' | head -n1); [ -z \"$connection\" ] && connection='Disconnected'; case \"$network\" in 100*) network='󰀂';; *) network='󰤮';; esac; powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}'); devices=$(bluetoothctl devices Connected 2>/dev/null | sed 's/^Device [^ ]* //' | paste -sd ', ' -); [ -z \"$devices\" ] && devices='No connected devices'; [ \"$powered\" = yes ] && bluetooth='󰂯' || bluetooth='󰂲'; printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' \"$audio\" \"$network\" \"$bluetooth\" \"$volume\" \"$sink\" \"$connection\" \"$devices\" \"$mute\""]
        running: true
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: root.updateStatus(statusCollector.text)
        }
        onExited: running = true
    }

    Process {
        id: micStatusQuery
        command: ["sh", "-c", "volume=$(pactl get-source-volume @DEFAULT_SOURCE@ 2>/dev/null | awk 'NR==1 {gsub(/%/,\"\",$5); print $5}'); mute=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}'); name=$(pactl get-default-source 2>/dev/null); printf '%s\\n%s\\n%s\\n' \"${volume:-0}\" \"${mute:-no}\" \"${name:-Default microphone}\""]
        running: true
        stdout: StdioCollector {
            id: micStatusOutput
            onStreamFinished: root.updateMicStatus(micStatusOutput.text)
        }
        onExited: running = true
    }

    Process {
        id: wallpaperQuery
        command: ["sh", "-c", "find /home/array/nux/wallpapers -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -print 2>/dev/null | sort"]
        running: true
        stdout: StdioCollector {
            id: wallpaperOutput
            onStreamFinished: root.wallpapers = wallpaperOutput.text.trim().length > 0 ? wallpaperOutput.text.trim().split("\n") : []
        }
        onExited: running = true
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
        id: bluetoothDevicesQuery
        command: ["sh", "-c", "timeout 8 bluetoothctl scan on >/dev/null 2>&1; bluetoothctl devices 2>/dev/null | while read -r _ address name; do printf '%s\\t%s\\n' \"$address\" \"$name\"; done"]
        stdout: StdioCollector {
            id: bluetoothDevicesOutput
            onStreamFinished: root.updateBluetoothDevices(bluetoothDevicesOutput.text)
        }
        onExited: root.bluetoothScanning = false
    }

    Process {
        id: networkDevicesQuery
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "yes"]
        stdout: StdioCollector {
            id: networkDevicesOutput
            onStreamFinished: root.updateNetworkDevices(networkDevicesOutput.text)
        }
        onExited: root.networkScanning = false
    }

    Process {
        id: displayQuery
        command: ["sh", "-c", "xrandr --query 2>/dev/null | awk '$2 == \"connected\" { name=$1; primary=($3 == \"primary\" ? \"primary\" : \"secondary\"); next } name && $1 ~ /^[0-9]+x[0-9]+$/ { mode=$1; for (i=2; i<=NF; i++) { rate=$i; selected=(rate ~ /\\*/ ? \"selected\" : \"available\"); gsub(/[^0-9.]/, \"\", rate); if (rate ~ /[0-9]/) print name \"\\tconnected\\t\" primary \"\\t\" mode \"\\t\" rate \"\\t\" selected } name=\"\" }'"]
        stdout: StdioCollector {
            id: displayOutput
            onStreamFinished: root.updateDisplays(displayOutput.text)
        }
    }

    Process {
        id: networkMetricsQuery
        command: ["sh", "-c", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i=1; i<=NF; i++) if ($i==\"dev\") {print $(i+1); exit}}'); [ -z \"$iface\" ] && iface=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null | awk -F: '$3==\"connected\" && $1!=\"lo\" {print $1; exit}'); type=$(nmcli -g GENERAL.TYPE device show \"$iface\" 2>/dev/null | head -n1); connection=$(nmcli -g GENERAL.CONNECTION device show \"$iface\" 2>/dev/null | head -n1); ip=$(nmcli -g IP4.ADDRESS device show \"$iface\" 2>/dev/null | cut -d/ -f1 | head -n1); rx=0; tx=0; [ -n \"$iface\" ] && rx=$(cat /sys/class/net/\"$iface\"/statistics/rx_bytes 2>/dev/null || printf 0); [ -n \"$iface\" ] && tx=$(cat /sys/class/net/\"$iface\"/statistics/tx_bytes 2>/dev/null || printf 0); printf '%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n%s\\n' \"$iface\" \"$type\" \"$connection\" \"$ip\" \"$network\" \"$rx\" \"$tx\""]
        running: true
        stdout: StdioCollector {
            id: networkMetricsOutput
            onStreamFinished: root.updateNetworkMetrics(networkMetricsOutput.text)
        }
        onExited: running = true
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
        onExited: running = true
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
        running: true
        stdout: StdioCollector {
            id: publicIpOutput
            onStreamFinished: root.publicIp = publicIpOutput.text.trim()
        }
    }

    Process {
        id: activeWindowQuery
        command: ["sh", "-c", "id=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $5}'); if [ -n \"$id\" ] && [ \"$id\" != \"0x0\" ]; then printf '%s\\n' \"$id\"; xprop -id \"$id\" _NET_WM_PID 2>/dev/null | awk '{print $3}'; fi"]
        stdout: StdioCollector {
            id: activeWindowOutput
            onStreamFinished: root.updateActiveWindow(activeWindowOutput.text)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (!bspwmQuery.running)
                bspwmQuery.running = true
            if (!workspaceQuery.running)
                workspaceQuery.running = true
            if (!windowTitleQuery.running)
                windowTitleQuery.running = true
            if (!statusQuery.running)
                statusQuery.running = true
            if (!micStatusQuery.running)
                micStatusQuery.running = true
            if (!networkMetricsQuery.running)
                networkMetricsQuery.running = true
            if (!tailscaleQuery.running)
                tailscaleQuery.running = true
            if (!exitConfigQuery.running)
                exitConfigQuery.running = true
            if (!activeWindowQuery.running)
                activeWindowQuery.running = true
            root.refreshNowPlaying()
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        onTriggered: {
            if (!publicIpQuery.running)
                publicIpQuery.running = true
            if (!batteryQuery.running)
                batteryQuery.running = true
        }
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
        target: "settings"
        function toggle(): void {
            if (settingsWindow.visible)
                settingsWindow.visible = false
            else
                root.openSettings("Audio")
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

    PanelWindow {
        id: bar
        anchors { top: true; left: true; right: true }
        implicitHeight: 32
        exclusiveZone: 32
        color: background
        aboveWindows: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 10
            spacing: 8

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 10

                Repeater {
                    model: root.workspaceStates

                    delegate: Rectangle {
                        required property var modelData
                        implicitWidth: 9.4
                        implicitHeight: 9.4
                        radius: 1
                        color: modelData.active ? foreground : (modelData.urgent ? "#f38ba8" : "transparent")
                        border.width: modelData.occupied && !modelData.active ? 1 : 0
                        border.color: accent

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.name
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: run(["bspc", "desktop", "-f", modelData.name])
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                text: activeTitle.length > 48 ? activeTitle.slice(0, 48) + "..." : (activeTitle || "Desktop")
                color: foreground
                elide: Text.ElideRight
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            RowLayout {
                Layout.rightMargin: 8
                spacing: 30

                Text {
                    visible: root.batteryCapacity >= 0
                    text: (root.batteryStatus === "Charging" ? "󰂄" : root.batteryCapacity <= 15 ? "󰁺" : root.batteryCapacity <= 35 ? "󰁼" : root.batteryCapacity <= 65 ? "󰁾" : "󰂀") + " " + root.batteryCapacity + "%"
                    color: root.batteryCapacity <= 15 ? "#f38ba8" : foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.run(["wezterm", "-e", "btop"])
                    }
                }

                RowLayout {
                    spacing: 4

                    Repeater {
                        model: SystemTray.items

                        delegate: Item {
                            required property var modelData
                            implicitWidth: 19
                            implicitHeight: 19

                            Image {
                                anchors.centerIn: parent
                                source: modelData.icon
                                sourceSize.width: 13
                                sourceSize.height: 13
                                width: 13
                                height: 13
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

                Text {
                    text: audioStatus
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16

                    MouseArea {
                        id: audioMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: event => {
                            if (event.button === Qt.RightButton)
                                root.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                            else
                                root.togglePopup(volumePopup)
                        }
                        onWheel: event => {
                            const amount = event.angleDelta.y > 0 ? "+5%" : "-5%"
                            root.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", amount])
                        }
                    }
                }

                Text {
                    text: networkStatus
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16
                    MouseArea {
                        id: networkMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.togglePopup(networkPopup)
                        onPressAndHold: root.run(["wezterm", "-e", "nmtui"])
                    }
                }

                Text {
                    text: bluetoothStatus
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16
                    MouseArea {
                        id: bluetoothMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.togglePopup(bluetoothPopup)
                        onPressAndHold: root.run(["wezterm", "-e", "bluetui"])
                    }
                }

                Text {
                    text: root.layoutIcon(root.bspLayout)
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.togglePopup(layoutPopup)
                    }
                }

                Text {
                    text: "󰂚"
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    MouseArea {
                        id: notificationMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.togglePopup(notificationPopup)
                    }
                }

            }
        }

        Text {
            id: clock
            anchors.centerIn: parent
            text: Qt.formatDateTime(new Date(), "ddd dd  HH:mm")
            color: foreground
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: parent.text = Qt.formatDateTime(new Date(), "ddd dd  HH:mm")
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.togglePopup(calendarPopup)
            }
        }
    }

    PopupWindow {
        id: layoutPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - 180
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 180
        implicitHeight: 160

        Rectangle {
            anchors.fill: parent
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                Text {
                    text: root.layoutIcon(root.bspLayout) + "  Layout  •  " + root.bspLayout
                    color: accent
                    font.family: "JetBrains Mono"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: ["tall", "monocle", "tiled"]
                    delegate: Button {
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: 30
                        text: root.layoutIcon(modelData) + "  " + modelData
                        onClicked: root.applyBspLayout(modelData)
                        contentItem: Text {
                            text: parent.text
                            color: parent.hovered ? foreground : muted
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#252536" : "transparent"
                            radius: 0
                        }
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
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 330 * menuScale
        implicitHeight: 370 * menuScale

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: accent
            radius: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        implicitWidth: 34
                        implicitHeight: 34
                        text: "‹"
                        onClicked: root.changeCalendarMonth(-1)
                        contentItem: Text {
                            text: parent.text
                            color: parent.hovered ? background : foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 22
                        }
                        background: Rectangle {
                            radius: 9
                            color: parent.pressed ? accent : (parent.hovered ? "#252536" : "#171820")
                            border.width: 1
                            border.color: parent.hovered ? accent : "#373b41"
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
                        implicitWidth: 34
                        implicitHeight: 34
                        text: "›"
                        onClicked: root.changeCalendarMonth(1)
                        contentItem: Text {
                            text: parent.text
                            color: parent.hovered ? background : foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 22
                        }
                        background: Rectangle {
                            radius: 9
                            color: parent.pressed ? accent : (parent.hovered ? "#252536" : "#171820")
                            border.width: 1
                            border.color: parent.hovered ? accent : "#373b41"
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 4
                    rowSpacing: 4

                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
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

    PopupWindow {
        id: volumePopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - volumePopup.implicitWidth - 10
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 360 * menuScale
        implicitHeight: 300 * menuScale

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 0

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
                            text: "󰕾"
                            color: background
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17 * root.menuFontScale
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Output volume"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13 * root.menuFontScale
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.audioDetail
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9 * root.menuFontScale
                            maximumLineCount: 1
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                            Layout.maximumWidth: 175
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: Math.round(root.volumeLevel) + "%"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15 * root.menuFontScale
                        font.weight: Font.DemiBold
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                        }
                    }

                    Button {
                        implicitWidth: 28
                        implicitHeight: 28
                        text: "󰒓"
                        onClicked: root.openSettings("Audio")
                        contentItem: Text {
                            text: parent.text
                            color: parent.hovered ? accent : foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 16 * root.menuFontScale
                        }
                        background: Rectangle { radius: 1; color: parent.hovered ? "#252536" : "transparent" }
                    }
                }

                Rectangle {
                    visible: root.currentPlayer !== null
                    Layout.fillWidth: true
                    Layout.preferredHeight: 66
                    color: "#171820"
                    radius: 8
                    border.width: 1
                    border.color: "#373b41"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 6
                            color: "#252536"
                            clip: true

                            Image {
                                id: artImage
                                anchors.fill: parent
                                visible: root.currentPlayer !== null && root.currentPlayer.trackArtUrl.length > 0
                                source: root.currentPlayer ? root.currentPlayer.trackArtUrl : ""
                                fillMode: Image.PreserveAspectCrop
                                cache: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !artImage.visible
                                text: root.currentPlayer && root.currentPlayer.isPlaying ? "󰐊" : "󰏤"
                                color: accent
                                font.family: "JetBrains Mono"
                                font.pixelSize: 16 * root.menuFontScale
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: root.currentPlayer ? (root.currentPlayer.trackTitle || "Unknown track") : ""
                                color: foreground
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11 * root.menuFontScale
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.currentPlayer ? (root.currentPlayer.trackArtist || root.currentPlayer.trackAlbum || "Unknown artist") : ""
                                color: muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9 * root.menuFontScale
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                Layout.preferredHeight: 3
                                radius: 2
                                color: "#373b41"

                                Rectangle {
                                    width: root.currentPlayer && root.currentPlayer.length > 0 ? parent.width * Math.min(1, root.currentPlayer.position / root.currentPlayer.length) : 0
                                    height: parent.height
                                    radius: 2
                                    color: accent
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: root.currentPlayer ? root.formatTrackTime(root.currentPlayer.position) : "0:00"
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: root.currentPlayer ? root.formatTrackTime(root.currentPlayer.length) : "0:00"
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 8
                                }
                            }
                        }

                        Button {
                            implicitWidth: 24
                            implicitHeight: 28
                            enabled: root.currentPlayer !== null && root.currentPlayer.canGoPrevious
                            text: "󰒮"
                            onClicked: root.currentPlayer.previous()
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? foreground : muted
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "JetBrains Mono"
                                font.pixelSize: 14
                            }
                            background: Rectangle {
                                radius: 5
                                color: parent.hovered ? "#252536" : "transparent"
                            }
                        }

                        Button {
                            implicitWidth: 24
                            implicitHeight: 28
                            enabled: root.currentPlayer !== null && (root.currentPlayer.canTogglePlaying || root.currentPlayer.canPlay || root.currentPlayer.canPause)
                            text: root.currentPlayer && root.currentPlayer.isPlaying ? "󰏤" : "󰐊"
                            onClicked: root.currentPlayer.togglePlaying()
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? accent : muted
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "JetBrains Mono"
                                font.pixelSize: 14
                            }
                            background: Rectangle {
                                radius: 5
                                color: parent.hovered ? "#252536" : "transparent"
                            }
                        }

                        Button {
                            implicitWidth: 24
                            implicitHeight: 28
                            enabled: root.currentPlayer !== null && root.currentPlayer.canGoNext
                            text: "󰒭"
                            onClicked: root.currentPlayer.next()
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? foreground : muted
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "JetBrains Mono"
                                font.pixelSize: 14
                            }
                            background: Rectangle {
                                radius: 5
                                color: parent.hovered ? "#252536" : "transparent"
                            }
                        }
                    }
                }

                Rectangle {
                    id: volumeTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    color: "transparent"

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 5
                        radius: 3
                        color: "#373b41"

                        Rectangle {
                            width: parent.width * root.volumeLevel / 100
                            height: parent.height
                            radius: 3
                            color: accent
                        }
                    }

                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - width, parent.width * root.volumeLevel / 100 - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: foreground
                        border.width: 3
                        border.color: accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        function updateVolume(mouseX) {
                            root.setVolume(Math.max(0, Math.min(1, mouseX / width)))
                        }
                        onPressed: event => updateVolume(event.x)
                        onPositionChanged: event => {
                            if (pressed)
                                updateVolume(event.x)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "󰍬"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 17 * root.menuFontScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "Microphone"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13 * root.menuFontScale
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: root.micName
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 9 * root.menuFontScale
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: root.micMuted ? "Muted" : Math.round(root.micVolumeLevel) + "%"
                        color: root.micMuted ? "#f38ba8" : accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13 * root.menuFontScale
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.toggleMicMute()
                        }
                    }
                }

                Rectangle {
                    id: micTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    color: "transparent"

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 5
                        radius: 3
                        color: "#373b41"

                        Rectangle {
                            width: parent.width * root.micVolumeLevel / 100
                            height: parent.height
                            radius: 3
                            color: root.micMuted ? muted : accent
                        }
                    }

                    Rectangle {
                        x: Math.max(0, Math.min(parent.width - width, parent.width * root.micVolumeLevel / 100 - width / 2))
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: 8
                        color: foreground
                        border.width: 3
                        border.color: root.micMuted ? muted : accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        function updateMic(mouseX) {
                            root.setMicVolume(Math.max(0, Math.min(1, mouseX / width)))
                        }
                        onPressed: event => updateMic(event.x)
                        onPositionChanged: event => {
                            if (pressed)
                                updateMic(event.x)
                        }
                    }
                }

            }
        }
    }

    PopupWindow {
        id: audioSettingsPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - audioSettingsPopup.implicitWidth - 10
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 400
        implicitHeight: 520

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: accent
            radius: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 8

                Text {
                    text: "Audio devices"
                    color: foreground
                    font.family: "JetBrains Mono"
                    font.pixelSize: 15 * root.menuFontScale
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Output sinks"
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10 * root.menuFontScale
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 145
                    clip: true
                    spacing: 4
                    model: root.audioSinks

                    delegate: Rectangle {
                        required property var modelData
                        width: parent ? parent.width : 0
                        height: 38
                        radius: 1
                        color: modelData.name === root.defaultSinkName ? "#252536" : "#171820"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 1

                            Text {
                                text: modelData.description || modelData.name
                                color: foreground
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10 * root.menuFontScale
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.name
                                color: muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 8 * root.menuFontScale
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.setDefaultSink(modelData.name)
                        }
                    }
                }

                Text {
                    text: "Microphone sources"
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10 * root.menuFontScale
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.audioSources

                    delegate: Rectangle {
                        required property var modelData
                        width: parent ? parent.width : 0
                        height: 38
                        radius: 1
                        color: modelData.name === root.defaultSourceName ? "#252536" : "#171820"

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            text: modelData.description || modelData.name
                            color: foreground
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10 * root.menuFontScale
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.setDefaultSource(modelData.name)
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: networkPopup
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - networkPopup.implicitWidth - 10
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 300 * menuScale
        implicitHeight: 560 * menuScale

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 1

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
        anchor.rect.x: bar.width - tailscalePopup.implicitWidth - 10
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 300 * menuScale
        implicitHeight: 140 * menuScale

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 1

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
                        }
                    }
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
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - exitNodePopup.implicitWidth - 10
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 340 * menuScale
        implicitHeight: 420 * menuScale

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 1

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
        anchor.rect.x: bar.width - bluetoothPopup.implicitWidth - 10
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 300 * menuScale
        implicitHeight: 360 * menuScale

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 1

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
        anchor.rect.y: bar.height + 2
        grabFocus: true
        color: "transparent"
        implicitWidth: 420 * menuScale
        implicitHeight: 480 * menuScale

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
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
                        required property var modelData
                        width: notificationList.width
                        height: Math.max(92, notificationBody.implicitHeight + 64)
                        radius: 8
                        color: "#171820"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.appName || "Notification"
                                    color: accent
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10 * root.menuFontScale
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "×"
                                    color: muted
                                    font.pixelSize: 16 * root.menuFontScale
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: modelData.dismiss()
                                    }
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
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
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
        interval: toastNotification && toastNotification.expireTimeout > 0 ? toastNotification.expireTimeout : 5000
        repeat: false
        onTriggered: {
            notificationToast.visible = false
            toastNotification = null
        }
    }

    PopupWindow {
        id: notificationToast
        visible: false
        anchor.window: bar
        anchor.rect.x: bar.width - width - 12
        anchor.rect.y: bar.height + 12
        color: "transparent"
        implicitWidth: 380
        implicitHeight: toastNotification && toastNotification.actions.length > 0 ? 180 : 128

        Rectangle {
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: accent
            radius: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: toastNotification && toastNotification.appName ? toastNotification.appName : "Notification"
                        color: accent
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.menuFontScale
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "×"
                        color: muted
                        font.pixelSize: 16 * root.menuFontScale

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (toastNotification)
                                    toastNotification.dismiss()
                                notificationToastTimer.stop()
                                notificationToast.visible = false
                            }
                        }
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
                }

                Text {
                    text: toastNotification ? toastNotification.body : ""
                    color: muted
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10 * root.menuFontScale
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
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
                            implicitHeight: 30
                            text: modelData.text
                            onClicked: {
                                modelData.invoke()
                                notificationToastTimer.stop()
                                notificationToast.visible = false
                            }
                            contentItem: Text {
                                text: parent.text
                                color: foreground
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: "JetBrains Mono"
                                font.pixelSize: 9 * root.menuFontScale
                                elide: Text.ElideRight
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
        x: (Screen.width - width) / 2
        y: (Screen.height - height) / 2
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        width: 290 * menuScale
        height: 330 * menuScale

        onVisibleChanged: {
            if (visible) {
                powerIndex = 0
                powerFocusTimer.restart()
            }
        }

        onActiveChanged: {
            if (active) {
                powerFocusTimer.restart()
            }
        }

        function activatePowerMenu() {
            requestActivate()
            root.floatActiveWindow(290 * root.menuScale, 330 * root.menuScale, 786, 342)
            powerContent.forceActiveFocus(Qt.OtherFocusReason)
        }

        Timer {
            id: powerFocusTimer
            interval: 50
            repeat: false
            onTriggered: powerPopup.activatePowerMenu()
        }

        Rectangle {
            id: powerContent
            anchors.fill: parent
            anchors.margins: 0
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 1
            focus: true

            Keys.onPressed: event => {
                switch (event.key) {
                case Qt.Key_Up:
                    powerIndex = (powerIndex + root.powerActions.length - 1) % root.powerActions.length
                    event.accepted = true
                    break
                case Qt.Key_Down:
                case Qt.Key_Tab:
                    powerIndex = (powerIndex + 1) % root.powerActions.length
                    event.accepted = true
                    break
                case Qt.Key_Return:
                case Qt.Key_Enter:
                    root.closePopups()
                    root.run(root.powerActions[powerIndex].command)
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

                    Text {
                        text: "Power menu"
                    color: foreground
                    font.family: "JetBrains Mono"
                        font.pixelSize: 15 * root.menuFontScale
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.powerActions

                    delegate: Button {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 34
                        text: modelData.label
                        focusPolicy: Qt.NoFocus
                        readonly property bool selected: index === root.powerIndex
                        onClicked: {
                            root.powerIndex = index
                            root.closePopups()
                            root.run(modelData.command)
                        }
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
                            color: parent.hovered || parent.selected ? "#252536" : "#171820"
                            border.width: 1
                            border.color: "#373b41"
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    text: "󰅖  Cancel"
                    onClicked: root.closePopups()
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

    Window {
        id: screenshotPopup
        visible: false
        title: "Screenshot"
        x: (Screen.width - width) / 2
        y: (Screen.height - height) / 2
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        width: 300 * menuScale
        height: 260 * menuScale

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
            root.floatActiveWindow(300 * root.menuScale, 260 * root.menuScale, 780, 384)
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
            border.color: accent
            radius: 1
            focus: true

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
                    root.takeScreenshot(root.screenshotActions[screenshotIndex].mode)
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

                    Text {
                        text: "Screenshot"
                    color: foreground
                    font.family: "JetBrains Mono"
                        font.pixelSize: 15 * root.menuFontScale
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.screenshotActions

                    delegate: Button {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 38
                        text: modelData.label
                        onClicked: root.takeScreenshot(modelData.mode)
                        contentItem: Text {
                            text: parent.text
                            color: foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        background: Rectangle {
                            radius: 7
                            color: parent.hovered || index === root.screenshotIndex ? "#252536" : "#171820"
                            border.width: 1
                            border.color: "#373b41"
                        }
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    text: "󰅖  Cancel"
                    onClicked: root.closePopups()
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

    Window {
        id: polkitWindow
        title: "Authentication Required"
        visible: polkitAgent.isActive
        x: (Screen.width - width) / 2
        y: (Screen.height - height) / 2
        flags: Qt.Dialog | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        modality: Qt.ApplicationModal
        color: "transparent"
        width: 390 * menuScale
        height: 250 * menuScale

        onVisibleChanged: {
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
                root.floatActiveWindow(390 * root.menuScale, 250 * root.menuScale, 726, 390)
                response.forceActiveFocus(Qt.OtherFocusReason)
                response.selectAll()
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 1
            color: background
            border.width: 1
            border.color: accent

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 9

                    Text {
                        text: polkitAgent.flow ? polkitAgent.flow.message : "Authentication required"
                    color: foreground
                    font.family: "JetBrains Mono"
                        font.pixelSize: 14 * root.menuFontScale
                    font.weight: Font.DemiBold
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                    Text {
                        text: polkitAgent.flow ? polkitAgent.flow.supplementaryMessage : ""
                    color: polkitAgent.flow && polkitAgent.flow.supplementaryIsError ? "#f38ba8" : muted
                    font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.menuFontScale
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                    Layout.fillWidth: true
                }

                    Text {
                        text: polkitAgent.flow ? polkitAgent.flow.inputPrompt : "Password"
                    color: muted
                    font.family: "JetBrains Mono"
                        font.pixelSize: 10 * root.menuFontScale
                    visible: polkitAgent.flow ? polkitAgent.flow.isResponseRequired : true
                }

                TextField {
                    id: response
                    Layout.fillWidth: true
                    echoMode: polkitAgent.flow && polkitAgent.flow.responseVisible ? TextInput.Normal : TextInput.Password
                    placeholderText: "Enter password"
                    color: foreground
                    selectionColor: highlight
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    background: Rectangle {
                        color: "#171820"
                        radius: 7
                        border.width: 1
                        border.color: response.active ? accent : muted
                    }
                    Keys.onReturnPressed: if (submitButton.enabled) submitButton.clicked()
                    Keys.onEscapePressed: if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10

                    Button {
                        implicitWidth: 88
                        implicitHeight: 32
                        text: "Cancel"
                        onClicked: if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
                        contentItem: Text {
                            text: parent.text
                            color: foreground
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                        background: Rectangle {
                            radius: 7
                            color: parent.pressed ? "#313244" : (parent.hovered ? "#252536" : "#171820")
                            border.width: 1
                            border.color: parent.hovered ? muted : "#373b41"
                        }
                    }

                    Button {
                        id: submitButton
                        implicitWidth: 132
                        implicitHeight: 32
                        text: "Authenticate"
                        highlighted: true
                        enabled: response.text.length > 0 && polkitAgent.flow !== null
                        onClicked: if (polkitAgent.flow) polkitAgent.flow.submit(response.text)
                        contentItem: Text {
                            text: parent.text
                            color: root.background
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                        background: Rectangle {
                            radius: 7
                            color: parent.pressed ? foreground : (parent.hovered ? foreground : accent)
                            border.width: 1
                            border.color: accent
                        }
                    }
                }
            }
        }
    }

    Window {
        id: settingsWindow
        visible: false
        title: "Settings"
        x: (Screen.width - width) / 2
        y: (Screen.height - height) / 2
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        width: 900
        height: 620

        onVisibleChanged: if (visible) requestActivate()
        Keys.onEscapePressed: visible = false

        Rectangle {
            anchors.fill: parent
            color: background
            border.width: 1
            border.color: "#373b41"
            radius: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 18

                ColumnLayout {
                    Layout.preferredWidth: 180
                    Layout.fillHeight: true
                    spacing: 6

                    Text {
                        text: "Settings"
                        color: foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 18 * root.menuFontScale
                        font.weight: Font.DemiBold
                        Layout.bottomMargin: 12
                    }

                    Repeater {
                        model: [
                            { label: "󰕾  Audio", page: "Audio" },
                            { label: "󰤨  Network", page: "Network" },
                            { label: "󰂯  Bluetooth", page: "Bluetooth" },
                            { label: "󰍹  Displays", page: "Displays" }
                        ]

                        delegate: Button {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 38
                            text: modelData.label
                            onClicked: root.settingsPage = modelData.page
                            contentItem: Text {
                                text: parent.text
                                color: root.settingsPage === modelData.page ? background : foreground
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12
                                font.family: "JetBrains Mono"
                                font.pixelSize: 11 * root.menuFontScale
                            }
                            background: Rectangle {
                                radius: 1
                                color: root.settingsPage === modelData.page ? accent : (parent.hovered ? "#252536" : "transparent")
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "Esc to close"
                        color: muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: "#373b41"
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.settingsPage === "Audio" ? 0 : root.settingsPage === "Network" ? 1 : root.settingsPage === "Bluetooth" ? 2 : 3

                    ColumnLayout {
                        spacing: 12

                        Text {
                            text: "Audio devices"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 16 * root.menuFontScale
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: "Select the default output and microphone."
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }

                        Text { text: "Output sinks"; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 10 * root.menuFontScale }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            clip: true
                            spacing: 5
                            model: root.audioSinks
                            delegate: Rectangle {
                                required property var modelData
                                width: parent ? parent.width : 0
                                height: 44
                                radius: 1
                                color: modelData.name === root.defaultSinkName ? "#252536" : "#171820"
                                border.width: modelData.name === root.defaultSinkName ? 1 : 0
                                border.color: accent
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: (modelData.name === root.defaultSinkName ? "●  " : "○  ") + root.deviceLabel(modelData)
                                    color: foreground
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10 * root.menuFontScale
                                    elide: Text.ElideRight
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.setDefaultSink(modelData.name) }
                            }
                        }

                        Text { text: "Microphone sources"; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 10 * root.menuFontScale }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 5
                            model: root.audioSources
                            delegate: Rectangle {
                                required property var modelData
                                width: parent ? parent.width : 0
                                height: 44
                                radius: 1
                                color: modelData.name === root.defaultSourceName ? "#252536" : "#171820"
                                border.width: modelData.name === root.defaultSourceName ? 1 : 0
                                border.color: accent
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: (modelData.name === root.defaultSourceName ? "●  " : "○  ") + root.deviceLabel(modelData)
                                    color: foreground
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10 * root.menuFontScale
                                    elide: Text.ElideRight
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.setDefaultSource(modelData.name) }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 12
                        Text { text: "Network"; color: foreground; font.family: "JetBrains Mono"; font.pixelSize: 16 * root.menuFontScale; font.weight: Font.DemiBold }
                        Text { text: "Current connection"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 150
                            color: "#171820"
                            radius: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text { text: root.networkDetail; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 14 * root.menuFontScale; font.weight: Font.DemiBold }
                                Text { text: "Interface:  " + (root.networkInterface || "unavailable"); color: foreground; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                Text { text: "Address:    " + (root.networkIp || "unavailable"); color: foreground; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                Text { text: "Download:   " + root.networkDownloadMbps.toFixed(1) + " Mbps"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                Text { text: "Upload:     " + root.networkUploadMbps.toFixed(1) + " Mbps"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                            }
                        }
                        Button {
                            text: "Open NetworkManager"
                            onClicked: root.run(["wezterm", "-e", "nmtui"])
                            contentItem: Text { text: parent.text; color: foreground; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                            background: Rectangle { implicitHeight: 34; color: parent.hovered ? "#252536" : "#171820"; border.width: 1; border.color: "#373b41"; radius: 1 }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Wi-Fi networks"; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 10 * root.menuFontScale }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: root.networkScanning ? "Scanning..." : "Scan"
                                enabled: !root.networkScanning
                                onClicked: root.scanNetworks()
                                contentItem: Text { text: parent.text; color: foreground; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                background: Rectangle { implicitWidth: 58; implicitHeight: 26; color: parent.hovered ? "#252536" : "#171820"; border.width: 1; border.color: "#373b41"; radius: 1 }
                            }
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            clip: true
                            spacing: 4
                            model: root.networkDevices
                            delegate: Rectangle {
                                required property var modelData
                                width: parent ? parent.width : 0
                                height: 36
                                color: modelData.active ? "#252536" : "#171820"
                                radius: 1
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    Text { text: modelData.active ? "●" : "○"; color: modelData.active ? accent : muted; font.pixelSize: 10 }
                                    Text { text: modelData.ssid; color: foreground; Layout.fillWidth: true; elide: Text.ElideRight; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                                    Text { text: modelData.signal + "%  " + modelData.security; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.connectNetwork(modelData.ssid) }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !root.networkScanning && root.networkDevices.length === 0
                                text: "No networks found"
                                color: muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        spacing: 12
                        Text { text: "Bluetooth"; color: foreground; font.family: "JetBrains Mono"; font.pixelSize: 16 * root.menuFontScale; font.weight: Font.DemiBold }
                        Text { text: "Device management"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 90
                            color: "#171820"
                            radius: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                Text { text: root.bluetoothDetail; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 13 * root.menuFontScale; font.weight: Font.DemiBold }
                                Text { text: "Use bluetui for pairing, connecting, and removing devices."; color: muted; wrapMode: Text.Wrap; Layout.fillWidth: true; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Nearby devices"; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 10 * root.menuFontScale }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: root.bluetoothScanning ? "Scanning..." : "Scan"
                                enabled: !root.bluetoothScanning
                                onClicked: root.refreshBluetoothDevices()
                                contentItem: Text { text: parent.text; color: foreground; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                background: Rectangle { implicitWidth: 58; implicitHeight: 26; color: parent.hovered ? "#252536" : "#171820"; border.width: 1; border.color: "#373b41"; radius: 1 }
                            }
                        }
                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 230
                            clip: true
                            spacing: 4
                            model: root.bluetoothDevices
                            delegate: Rectangle {
                                required property var modelData
                                width: parent ? parent.width : 0
                                height: 38
                                color: "#171820"
                                radius: 1
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 1
                                    Text { text: modelData.name || "Unknown device"; color: foreground; font.family: "JetBrains Mono"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: modelData.address; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 8 }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.connectBluetooth(modelData.address) }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !root.bluetoothScanning && root.bluetoothDevices.length === 0
                                text: "No Bluetooth devices found"
                                color: muted
                                font.family: "JetBrains Mono"
                                font.pixelSize: 10
                            }
                        }
                        Button {
                            text: "Open Bluetui"
                            onClicked: root.run(["wezterm", "-e", "bluetui"])
                            contentItem: Text { text: parent.text; color: foreground; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "JetBrains Mono"; font.pixelSize: 10 }
                            background: Rectangle { implicitHeight: 34; color: parent.hovered ? "#252536" : "#171820"; border.width: 1; border.color: "#373b41"; radius: 1 }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    ColumnLayout {
                        spacing: 12
                        Text { text: "Displays"; color: foreground; font.family: "JetBrains Mono"; font.pixelSize: 16 * root.menuFontScale; font.weight: Font.DemiBold }
                        Text { text: "Choose the primary monitor and manage connected outputs."; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 10 }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 6
                            model: root.displays
                            delegate: Rectangle {
                                required property var modelData
                                width: parent ? parent.width : 0
                                height: 78
                                radius: 1
                                color: modelData.primary ? "#252536" : "#171820"
                                border.width: modelData.primary ? 1 : 0
                                border.color: accent

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 12
                                    Text { text: modelData.primary ? "󰍹" : "󰹙"; color: modelData.primary ? accent : muted; font.pixelSize: 22 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: modelData.name + (modelData.primary ? "  •  Primary" : ""); color: foreground; font.family: "JetBrains Mono"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        Text { text: modelData.mode + "  •  " + modelData.refresh + " Hz"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                    }
                                    Button {
                                        text: modelData.primary ? "Primary" : "Set primary"
                                        enabled: !modelData.primary
                                        onClicked: root.setPrimaryDisplay(modelData.name)
                                        contentItem: Text { text: parent.text; color: parent.enabled ? foreground : muted; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                                        background: Rectangle { implicitWidth: 82; implicitHeight: 28; color: parent.hovered ? "#373b41" : "#171820"; border.width: 1; border.color: "#373b41"; radius: 1 }
                                    }
                                    ComboBox {
                                        Layout.preferredWidth: 170
                                        Layout.preferredHeight: 30
                                        model: modelData.modes
                                        textRole: "label"
                                        currentIndex: Math.max(0, modelData.modes.findIndex(option => option.selected))
                                        contentItem: Text {
                                            leftPadding: 12
                                            rightPadding: 28
                                            text: parent.currentText
                                            color: foreground
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 9
                                        }
                                        indicator: Text {
                                            x: parent.width - width - 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰅀"
                                            color: accent
                                            font.pixelSize: 13
                                        }
                                        background: Rectangle {
                                            color: parent.hovered ? "#252536" : "#171820"
                                            border.width: 1
                                            border.color: parent.activeFocus ? accent : "#373b41"
                                            radius: 8
                                        }
                                        onActivated: index => {
                                            const option = modelData.modes[index]
                                            root.setDisplayMode(modelData.name, option.mode, option.refresh)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.displays.length === 0
                            text: "No connected displays found"
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }

    Window {
        id: wallpaperViewer
        visible: false
        title: "Wallpaper Viewer"
        x: (Screen.width - width) / 2
        y: (Screen.height - height) / 2
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        width: 820
        height: 600

        onVisibleChanged: if (visible) requestActivate()

        Keys.onEscapePressed: visible = false

        Rectangle {
            anchors.fill: parent
            color: background
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
                        color: foreground
                        font.family: "JetBrains Mono"
                        font.pixelSize: 16 * root.menuFontScale
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Click an image to apply  •  Esc to close"
                        color: muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    color: accent
                }

                GridView {
                    id: wallpaperGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: 250
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
                            border.color: root.selectedWallpaper === modelData ? accent : (wallpaperMouse.containsMouse ? foreground : "#373b41")
                            radius: 1
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
                                color: "#0E0E12"
                                opacity: wallpaperMouse.containsMouse || root.selectedWallpaper === modelData ? 0.9 : 0.72

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    text: modelData.split("/").pop()
                                    color: foreground
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
                                onClicked: root.applyWallpaper(modelData)
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.wallpapers.length === 0
                        text: "No wallpapers found"
                        color: muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    Window {
        id: launcher
        visible: false
        title: "Launcher"
        x: (Screen.width - width) / 2
        y: (Screen.height - height) / 2
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
        color: "transparent"
        width: 640 * menuScale
        height: 560 * menuScale

        onVisibleChanged: {
            if (visible)
                focusTimer.restart()
        }

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
                    launcherVisible = false
                    launcher.visible = false
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 0
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
                        color: accent
                        Text {
                            anchors.centerIn: parent
                            text: "󰣆"
                            color: background
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Applications"
                            color: foreground
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "Launch something"
                            color: muted
                            font.family: "JetBrains Mono"
                            font.pixelSize: 10
                        }
                    }

                    Text {
                        text: "ESC"
                        color: muted
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                    }
                }

                TextField {
                    id: search
                    Layout.fillWidth: true
                    implicitHeight: 50
                    placeholderText: "Search applications..."
                    color: foreground
                    placeholderTextColor: muted
                    selectionColor: highlight
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                    leftPadding: 18
                    rightPadding: 18
                    onTextChanged: apps.selectFirst()
                    background: Rectangle {
                        color: "#171820"
                        radius: 10
                        border.width: 1
                        border.color: search.activeFocus ? accent : "#373b41"
                    }

                    Keys.onEscapePressed: {
                        launcherVisible = false
                        launcher.visible = false
                    }
                    Keys.onPressed: event => {
                        switch (event.key) {
                        case Qt.Key_Up:
                            apps.moveSelection(-1)
                            event.accepted = true
                            break
                        case Qt.Key_Down:
                        case Qt.Key_Tab:
                            apps.moveSelection(1)
                            event.accepted = true
                            break
                        case Qt.Key_PageUp:
                            apps.moveSelection(-Math.max(1, Math.floor(apps.height / 48)))
                            event.accepted = true
                            break
                        case Qt.Key_PageDown:
                            apps.moveSelection(Math.max(1, Math.floor(apps.height / 48)))
                            event.accepted = true
                            break
                        case Qt.Key_Home:
                            apps.selectFirst()
                            event.accepted = true
                            break
                        case Qt.Key_End:
                            apps.selectLast()
                            event.accepted = true
                            break
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            apps.launchCurrent()
                            event.accepted = true
                            break
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
                        if (count === 0)
                            return

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
                            if (item && item.matches) {
                                currentIndex = i
                                positionViewAtIndex(i, ListView.Beginning)
                                return
                            }
                        }
                    }

                    function selectLast() {
                        for (let i = count - 1; i >= 0; i--) {
                            const item = itemAtIndex(i)
                            if (item && item.matches) {
                                currentIndex = i
                                positionViewAtIndex(i, ListView.End)
                                return
                            }
                        }
                    }

                    function launchCurrent() {
                        if (currentItem && currentItem.entry && currentItem.matches) {
                            currentItem.entry.execute()
                            launcherVisible = false
                            launcher.visible = false
                        }
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        property var entry: modelData
                        readonly property bool valid: entry !== null && entry !== undefined
                        readonly property string searchText: {
                            if (!valid)
                                return ""
                            const keywords = Array.isArray(entry.keywords) ? entry.keywords.join(" ") : (entry.keywords || "")
                            return ((entry.name || "") + " " + (entry.genericName || "") + " " + (entry.comment || "") + " " + keywords + " " + (entry.id || "")).toLowerCase()
                        }
                        readonly property bool matches: valid && (search.text.trim().length === 0 || searchText.indexOf(search.text.trim().toLowerCase()) !== -1)

                        width: apps.width
                        height: matches ? 48 : 0
                        visible: matches
                        color: ListView.isCurrentItem ? "#252536" : "transparent"
                        border.width: ListView.isCurrentItem ? 1 : 0
                        border.color: accent
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
                                Text {
                                    text: entry ? entry.name : ""
                                    color: foreground
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: entry ? (entry.genericName || entry.comment) : ""
                                    color: muted
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 10
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
                            onClicked: {
                                if (!parent.matches)
                                    return
                                apps.currentIndex = parent.index
                                apps.launchCurrent()
                            }
                        }
                    }

                    Keys.onUpPressed: decrementCurrentIndex()
                    Keys.onDownPressed: incrementCurrentIndex()
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "↑↓  Navigate"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                    Text { text: "↵  Launch"; color: muted; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                    Item { Layout.fillWidth: true }
                    Text { text: "󰘳  Super + Space"; color: accent; font.family: "JetBrains Mono"; font.pixelSize: 9 }
                }
            }
        }
    }
}
