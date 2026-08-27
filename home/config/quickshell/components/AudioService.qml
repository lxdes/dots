import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Scope {
    readonly property var defaultSinkAudio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var defaultSourceAudio: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
    readonly property real outputLevel: defaultSinkAudio ? Math.round(defaultSinkAudio.volume * 100) : 0
    readonly property real inputLevel: defaultSourceAudio ? Math.round(defaultSourceAudio.volume * 100) : 0
    readonly property bool outputMuted: defaultSinkAudio ? defaultSinkAudio.muted : false
    readonly property bool inputMuted: defaultSourceAudio ? defaultSourceAudio.muted : false

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    function setOutputVolume(value) {
        if (!defaultSinkAudio)
            return
        defaultSinkAudio.muted = false
        defaultSinkAudio.volume = Math.max(0, Math.min(1, value))
    }

    function setInputVolume(value) {
        if (defaultSourceAudio)
            defaultSourceAudio.volume = Math.max(0, Math.min(1, value))
    }

    function toggleOutputMute() {
        if (defaultSinkAudio)
            defaultSinkAudio.muted = !defaultSinkAudio.muted
    }

    function toggleInputMute() {
        if (defaultSourceAudio)
            defaultSourceAudio.muted = !defaultSourceAudio.muted
    }
}
