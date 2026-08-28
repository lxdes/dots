import QtQuick
import Quickshell

pragma Singleton

Singleton {
    id: style
    
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
    property real uiFontScale: 1.2
    property real panelFontScale: 1.0
    property int panelHeight: 32
    property real reducedMotion: 0.0
}
