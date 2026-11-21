pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// X64 LIOS - Live Reactive Theme & Wallpaper State Singleton (ThemeState.qml)
// Watches ~/.config/x64-theme/palette.json via FileView and reacts immediately
// to IPC `quickshell ipc call theme reload` for zero-restart live recoloring
// and GPU wallpaper / mpvpaper orchestration.
// =============================================================================
QtObject {
    id: state

    // Metadata & Wallpaper Config
    property string themeId: "x64-lios-crimson"
    property string themeName: "X64 Crimson"
    property string mode: "dark"
    property string accentOverride: ""
    property string backgroundPath: "/usr/share/backgrounds/x64-lios/01-monolith.jpg"
    property string backgroundPoster: "/usr/share/backgrounds/x64-lios/01-monolith.jpg"
    property bool backgroundIsVideo: false
    property bool liveVideoGlobal: false
    property bool videoEnabled: false
    property bool batteryPoster: true
    property string transition: "wave"
    property var perMonitorBg: ({})
    property int wallpaperRev: 0

    // Normalized origin (0..1) for signature GPU circular wave reveal
    property real waveOriginX: 0.5
    property real waveOriginY: 0.5

    readonly property bool anyLiveVideo: {
        if (!videoEnabled) return false;
        if (liveVideoGlobal) return true;
        if (perMonitorBg) {
            for (var k in perMonitorBg) {
                if (perMonitorBg[k] && perMonitorBg[k].liveVideo) return true;
            }
        }
        return false;
    }

    // Core Obsidian & Crimson Defaults (exact pixel parity on clean boot)
    property color bgDark: "#0b0c10"
    property color bgCard: "#13151c"
    property color bgElevated: "#1a1d26"
    property color bgHover: "#222530"
    property color bgActive: "#2c303e"
    property color bgBar: "#0a0b10"
    property color bgCapsule: "#12131a"

    property color accent: "#ff2b2b"
    property color accentHover: "#ff4747"
    property color accentText: "#ff9494"
    property color accentPillBg: "#2a0b0f"

    property color statusOk: "#34d399"
    property color statusWarn: "#f5a524"

    property color textPrimary: "#ebe8e3"
    property color textSecondary: "#8e909a"
    property color textMuted: "#565863"

    signal paletteReloaded(string themeId)

    function _toFileUrl(p) {
        if (!p || p === "") return "";
        if (p.indexOf("file://") === 0) return p;
        return "file://" + p;
    }

    function wallpaperUrlFor(monName) {
        if (monName && perMonitorBg && perMonitorBg[monName]) {
            var entry = perMonitorBg[monName];
            var p = entry.poster || entry.path || "";
            if (p !== "") return _toFileUrl(p);
        }
        var g = backgroundPoster || backgroundPath || "/usr/share/backgrounds/x64-lios/01-monolith.jpg";
        return _toFileUrl(g);
    }

    function isLiveVideoFor(monName) {
        if (!videoEnabled) return false;
        if (monName && perMonitorBg && perMonitorBg[monName]) {
            return Boolean(perMonitorBg[monName].liveVideo);
        }
        return Boolean(liveVideoGlobal);
    }

    function setWaveOrigin(nx, ny) {
        var x = parseFloat(nx);
        var y = parseFloat(ny);
        if (!isNaN(x)) state.waveOriginX = Math.max(0.0, Math.min(1.0, x));
        if (!isNaN(y)) state.waveOriginY = Math.max(0.0, Math.min(1.0, y));
    }

    function _applyJson(raw) {
        if (!raw || raw.trim() === "") return;
        try {
            var d = JSON.parse(raw.trim());
            if (d.theme) state.themeId = String(d.theme);
            if (d.name) state.themeName = String(d.name);
            if (d.mode) state.mode = String(d.mode);
            if (d.accentOverride !== undefined) state.accentOverride = String(d.accentOverride);
            if (d.background) state.backgroundPath = String(d.background);
            if (d.backgroundPoster) state.backgroundPoster = String(d.backgroundPoster);
            if (d.backgroundIsVideo !== undefined) state.backgroundIsVideo = Boolean(d.backgroundIsVideo);
            if (d.liveVideoGlobal !== undefined) state.liveVideoGlobal = Boolean(d.liveVideoGlobal);
            if (d.videoEnabled !== undefined) state.videoEnabled = Boolean(d.videoEnabled);
            if (d.batteryPoster !== undefined) state.batteryPoster = Boolean(d.batteryPoster);
            if (d.transition) state.transition = String(d.transition);
            if (d.perMonitorBg !== undefined) state.perMonitorBg = d.perMonitorBg || ({});

            if (d.bgDark) state.bgDark = d.bgDark;
            if (d.bgCard) state.bgCard = d.bgCard;
            if (d.bgElevated) state.bgElevated = d.bgElevated;
            if (d.bgHover) state.bgHover = d.bgHover;
            if (d.bgActive) state.bgActive = d.bgActive;
            if (d.bgBar) state.bgBar = d.bgBar;
            if (d.bgCapsule) state.bgCapsule = d.bgCapsule;

            if (d.accent) state.accent = d.accent;
            if (d.accentHover) state.accentHover = d.accentHover;
            if (d.accentText) state.accentText = d.accentText;
            if (d.accentPillBg) state.accentPillBg = d.accentPillBg;

            if (d.statusOk) state.statusOk = d.statusOk;
            if (d.statusWarn) state.statusWarn = d.statusWarn;

            if (d.textPrimary) state.textPrimary = d.textPrimary;
            if (d.textSecondary) state.textSecondary = d.textSecondary;
            if (d.textMuted) state.textMuted = d.textMuted;

            state.wallpaperRev = state.wallpaperRev + 1;
            state.paletteReloaded(state.themeId);
        } catch (e) {}
    }

    function reload() {
        paletteFile.reload();
        var fresh = paletteFile.text();
        if (fresh && fresh.trim() !== "") {
            state._applyJson(fresh);
        }
    }

    readonly property FileView _paletteFile: FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.config/x64-theme/palette.json"
        watchChanges: true
        blockLoading: true
        printErrors: false
        onLoaded: state._applyJson(paletteFile.text())
        onFileChanged: state.reload()
    }

    Component.onCompleted: {
        var initial = paletteFile.text();
        if (initial && initial.trim() !== "") {
            state._applyJson(initial);
        }
    }
}
