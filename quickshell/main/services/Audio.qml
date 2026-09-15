pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || Translation.tr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    function toggleMicMute() {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    function incrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
    }
    
    function decrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume -= step;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    function playSoundCandidates(paths, volume = 100) {
        const percent = Math.round(Math.max(0, Math.min(100, Number(volume))));
        if (!Number.isFinite(percent) || percent === 0) return;
        // Pick one existing file. Paths are arguments, never interpolated into shell code.
        Quickshell.execDetached([
            "sh", "-c", `
                sound_volume="$1"
                shift
                for sound_file in "$@"; do
                    if [ -f "$sound_file" ] && [ -r "$sound_file" ]; then
                        exec ffplay -nodisp -autoexit -loglevel error -nostats -volume "$sound_volume" -protocol_whitelist file -i "$sound_file"
                    fi
                done
                exit 1
            `, "quickshell-sound", String(percent), ...paths
        ]);
    }

    function playSoundFile(filePath, volume = 100) {
        if (typeof filePath !== "string") return;
        let path = filePath;
        if (path.startsWith("file://")) {
            try {
                path = decodeURIComponent(path.slice(7));
            } catch (error) {
                return;
            }
        }
        // Notification sounds must be local files, not remote media URLs.
        if (!path.startsWith("/")) return;
        root.playSoundCandidates([path], volume);
    }

    function playSystemSound(soundName, volume = 100) {
        if (typeof soundName !== "string" || !/^[a-zA-Z0-9_-]+$/.test(soundName)) return;
        const themes = root.audioTheme === "freedesktop" ? [root.audioTheme] : [root.audioTheme, "freedesktop"];
        const soundRoots = [
            FileUtils.trimFileProtocol(`${Directories.home}/.local/share/sounds`),
            "/usr/share/sounds",
        ];
        const paths = [];
        for (const soundRoot of soundRoots) {
            for (const theme of themes) {
                for (const extension of ["oga", "ogg", "wav"]) {
                    paths.push(`${soundRoot}/${theme}/stereo/${soundName}.${extension}`);
                }
            }
        }
        root.playSoundCandidates(paths, volume);
    }
}
