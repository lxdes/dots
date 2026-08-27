pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string activeDesktop: ""
    property string activeWindowId: ""
    property string activeTitle: "Desktop"
    property var workspaces: []

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
            workspaces = desktops
            activeDesktop = focusedDesktop
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
}
