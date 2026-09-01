pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeDesktop: ""
    property string activeWindowId: ""
    property string activeTitle: "Desktop"
    property bool activeFullscreen: false
    property var workspaces: []

    function refreshFullscreen() {
        if (fullscreenStateQuery.running) {
            fullscreenRefreshPending = true
            return
        }
        fullscreenStateQuery.running = true
    }

    property bool fullscreenRefreshPending: false

    function parseReport(line) {
        if (!line.startsWith("W"))
            return

        const desktops = []
        let focusedDesktop = ""
        for (const part of line.slice(1).split(":")) {
            if (part.length < 2 || "OoFfUu".indexOf(part[0]) === -1)
                continue
            const state = part[0]
            const name = part.slice(1)
            const focused = "OFU".indexOf(state) !== -1
            if (focused)
                focusedDesktop = name
            desktops.push({
                name: name,
                active: focused,
                occupied: state === "O" || state === "o",
                urgent: state === "U" || state === "u"
            })
        }
        if (desktops.length > 0) {
            activeDesktop = focusedDesktop
            const structureChanged = workspaces.length !== desktops.length || desktops.some((desktop, index) => {
                const current = workspaces[index]
                return !current || current.name !== desktop.name || current.occupied !== desktop.occupied || current.urgent !== desktop.urgent
            })
            if (structureChanged)
                workspaces = desktops
        }
    }

    function parseTitle(line) {
        const match = line.match(/= "([\s\S]*)"$/)
        if (match)
            activeTitle = match[1].replace(/\\"/g, '"').replace(/\\\\/g, "\\") || "Desktop"
    }

    Process {
        id: reportProcess
        command: ["bspc", "subscribe", "report"]
        running: true
        stdout: SplitParser {
            onRead: line => root.parseReport(line)
        }
        onExited: reportRestart.restart()
    }

    Timer {
        id: reportRestart
        interval: 1500
        repeat: false
        onTriggered: if (!reportProcess.running) reportProcess.running = true
    }

    Process {
        id: activeWindowProcess
        command: ["xprop", "-spy", "-root", "_NET_ACTIVE_WINDOW"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const match = line.match(/window id # (0x[0-9a-fA-F]+)/)
                const nextId = match && match[1] !== "0x0" ? match[1] : ""
                if (nextId === root.activeWindowId)
                    return
                root.activeWindowId = nextId
                root.refreshFullscreen()
                titleSpy.running = false
                if (nextId.length > 0)
                    titleSpy.running = true
                else
                    root.activeTitle = "Desktop"
            }
        }
        onExited: activeWindowRestart.restart()
    }

    Timer {
        id: activeWindowRestart
        interval: 1500
        repeat: false
        onTriggered: if (!activeWindowProcess.running) activeWindowProcess.running = true
    }

    Process {
        id: titleSpy
        command: ["xprop", "-spy", "-id", root.activeWindowId, "_NET_WM_NAME", "WM_NAME"]
        stdout: SplitParser {
            onRead: line => root.parseTitle(line)
        }
        onExited: {
            if (root.activeWindowId.length === 0)
                root.activeTitle = "Desktop"
        }
    }

    Process {
        id: bspwmEventProcess
        command: ["bspc", "subscribe", "node_focus", "node_state", "desktop_focus", "monitor_focus"]
        running: true
        stdout: SplitParser {
            onRead: line => root.refreshFullscreen()
        }
        onExited: bspwmEventRestart.restart()
    }

    Timer {
        id: bspwmEventRestart
        interval: 1500
        repeat: false
        onTriggered: if (!bspwmEventProcess.running) bspwmEventProcess.running = true
    }

    Process {
        id: fullscreenStateQuery
        command: ["sh", "-c", "id=$(bspc query -N -n focused 2>/dev/null) || { printf 'false\\n'; exit; }; if bspc query -N -n focused.fullscreen >/dev/null 2>&1; then printf 'true\\n'; else case $(xprop -id \"$id\" _NET_WM_STATE 2>/dev/null) in *_NET_WM_STATE_FULLSCREEN*) printf 'true\\n' ;; *) printf 'false\\n' ;; esac; fi"]
        stdout: StdioCollector {
            id: fullscreenStateOutput
            onStreamFinished: root.activeFullscreen = fullscreenStateOutput.text.trim() === "true"
        }
        onExited: {
            if (root.fullscreenRefreshPending) {
                root.fullscreenRefreshPending = false
                Qt.callLater(root.refreshFullscreen)
            }
        }
    }

    Component.onCompleted: refreshFullscreen()
}
