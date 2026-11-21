pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// =============================================================================
// X64 LIOS - Centralized System Telemetry & State Singleton (SysState.qml)
// Single source of truth shared by Bar, ControlCenter, TelemetryPopup,
// ScreenFilter and NotificationPopup.
// - Zero duplicate x64-hyprland-ctl status processes.
// - Adaptive polling: 2.5s lite in Bar, 1.2s full when popup open, 1.0s during REC.
// - Automatic pause in Fullscreen (0 spawns / 0 GPU wakeups during gaming).
// =============================================================================
QtObject {
    id: sys

    // Visibility / Demand flags bound by shell.qml
    property bool telemetryOpen: false
    property bool controlOpen: false
    property bool brightnessDragging: false
    property bool fullscreenActive: false
    property double lastFullRefreshMs: 0
    property double lastLiteRefreshMs: 0

    readonly property bool detailedMode: telemetryOpen || controlOpen
    readonly property bool shouldPoll: detailedMode || isRecording || !fullscreenActive
    readonly property int pollInterval: {
        if (detailedMode) return 1200;
        if (isRecording) return 1000;
        if (gamingModeActive) return 5000;
        return 2500;
    }

    // Core Telemetry (Lite + Full)
    property int cpuUsage: 0
    property int cpuTemp: 40
    property string ramUsed: "0.0"

    // Expanded Telemetry (Full mode — TelemetryPopup)
    property string cpuModel: "X64 Processor"
    property int cpuCores: 4
    property string cpuFreq: "3.60 GHz"
    property string loadAvg: "0.10"
    property var cpuCoresLoad: [0, 0, 0, 0, 0, 0, 0, 0]
    property var cpuHistory: [4, 6, 5, 8, 7, 10, 6, 5, 9, 7, 6, 8, 5, 7, 6, 8, 10, 7, 6, 5]

    property string ramTotal: "8.0"
    property int ramPct: 0
    property string ramCached: "0.0"
    property string swapUsed: "0.0"
    property string swapTotal: "0.0"

    property string diskUsed: "0G"
    property string diskTotal: "0G"
    property string diskFree: "0G"
    property string diskFs: "BTRFS"
    property int diskPct: 0

    property string netDown: "0 KB/s"
    property string netUp: "0 KB/s"
    property string netIp: "127.0.0.1"
    property string netIface: "eth0"

    property string kernelVer: "Linux"
    property string uptimeStr: "0m"
    property var topList: []

    // Multi-GPU Telemetry (NVIDIA SLI + AMD / Intel DRM)
    property int gpuCount: 0
    property int gpuTemp: 0
    property int gpuUtil: 0
    property var gpus: []

    // Toggles, Power, Recording & Display State
    property bool caffeineActive: false
    property bool nightlightActive: false
    property bool dndActive: false
    property bool isRecording: false
    property string recTime: "00:00"
    property bool hasBattery: false
    property int batPct: 100
    property string batStatus: "AC"
    property string powerProfile: "balanced"
    property int brightnessVal: 100
    property string aiEngine: "opencode"
    property bool zoomEnabled: false
    property string zoomFactor: "1.0"
    property bool gamingModeActive: false
    property bool autoGamingEnabled: true
    property bool autoGameDetected: false

    // Shared Multi-Monitor Bar State (single instance across all connected displays)
    property string kbLayout: "ES"
    property string netType: "LAN"
    property string netName: "Cable"
    property string timeStr: "00:00"
    property string dateStr: "LUN 01 ENE"

    signal topListUpdated(var list)

    function _buildStatusCmd(forceFull) {
        if (forceFull || sys.detailedMode) {
            return ["/usr/bin/x64-hyprland-ctl", "status"];
        }
        if (sys.isRecording || sys.gamingModeActive) {
            return ["/usr/bin/x64-hyprland-ctl", "status-lite", "--no-gpu"];
        }
        return ["/usr/bin/x64-hyprland-ctl", "status-lite"];
    }

    function refreshNow(forceFull, bypassCooldown) {
        if (statusProc.running) return;
        var wantFull = Boolean(forceFull) || sys.detailedMode;
        var now = Date.now();
        if (!bypassCooldown) {
            if (wantFull && (now - sys.lastFullRefreshMs) < 1200) return;
            if (!wantFull && (now - sys.lastLiteRefreshMs) < 800) return;
        }
        if (wantFull) {
            sys.lastFullRefreshMs = now;
        } else {
            sys.lastLiteRefreshMs = now;
        }
        statusProc.command = _buildStatusCmd(wantFull);
        statusProc.running = true;
    }

    function guardToggle() {
        toggleGuardTimer.restart();
    }

    function guardBrightness() {
        brGuardTimer.restart();
    }

    function runCtl(args) {
        toggleGuardTimer.restart();
        if (ctlActionProc.running) {
            ctlActionProc.running = false;
        }
        ctlActionProc.command = ["/usr/bin/x64-hyprland-ctl"].concat(args);
        ctlActionProc.running = true;
    }

    function syncFromExternal() {
        toggleGuardTimer.stop();
        refreshNow(sys.detailedMode, true);
    }

    function switchKeyboardLayout() {
        kbGuardTimer.restart();
        if (!kbSwitchProc.running) kbSwitchProc.running = true;
    }

    function _updateClock() {
        var now = new Date();
        var h = String(now.getHours()).padStart(2, '0');
        var m = String(now.getMinutes()).padStart(2, '0');
        sys.timeStr = h + ":" + m;

        var days = I18n.dayShortNames;
        var months = I18n.monthShortNames;
        var dName = days[now.getDay()];
        var dNum = String(now.getDate()).padStart(2, '0');
        var mName = months[now.getMonth()];
        sys.dateStr = dName + " " + dNum + " " + mName;
    }

    onDetailedModeChanged: {
        if (detailedMode) {
            refreshNow(true, false);
        }
    }

    onFullscreenActiveChanged: {
        if (!fullscreenActive && shouldPoll) {
            refreshNow(false, false);
        }
    }

    // Automatic 0%-overhead video wallpaper pause in Fullscreen / Gaming Mode + Battery Poster guard
    readonly property bool shouldPauseVideo: fullscreenActive || gamingModeActive
    readonly property bool onBatteryDischarging: hasBattery && batStatus === "Discharging"

    onShouldPauseVideoChanged: {
        if (ThemeState.anyLiveVideo) {
            if (videoPauseProc.running) videoPauseProc.running = false;
            videoPauseProc.command = ["/usr/bin/x64-theme", "pause-video", shouldPauseVideo ? "on" : "off"];
            videoPauseProc.running = true;
        }
    }

    onOnBatteryDischargingChanged: {
        if (ThemeState.videoEnabled && ThemeState.batteryPoster) {
            if (videoBatteryProc.running) videoBatteryProc.running = false;
            videoBatteryProc.command = ["/usr/bin/x64-theme", "restore"];
            videoBatteryProc.running = true;
        }
    }

    readonly property Process _videoPauseProc: Process {
        id: videoPauseProc
    }

    readonly property Process _videoBatteryProc: Process {
        id: videoBatteryProc
    }

    readonly property Timer _toggleGuardTimer: Timer {
        id: toggleGuardTimer
        interval: 900
        repeat: false
    }

    readonly property Timer _brGuardTimer: Timer {
        id: brGuardTimer
        interval: 900
        repeat: false
    }

    readonly property Timer _pollTimer: Timer {
        id: pollTimer
        interval: sys.pollInterval
        running: sys.shouldPoll
        repeat: true
        triggeredOnStart: true
        onTriggered: sys.refreshNow(false, true)
    }

    readonly property Process _ctlActionProc: Process {
        id: ctlActionProc
        onExited: {
            toggleGuardTimer.stop();
            sys.refreshNow(sys.detailedMode, true);
        }
    }

    readonly property Process _statusProc: Process {
        id: statusProc
        command: ["/usr/bin/x64-hyprland-ctl", "status-lite"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                if (!statusCollector.text) return;
                try {
                    var d = JSON.parse(statusCollector.text.trim());
                    if (d.cpu !== undefined) {
                        var c = d.cpu || 0;
                        sys.cpuUsage = c;
                        if (sys.telemetryOpen) {
                            var hist = sys.cpuHistory.slice(1);
                            hist.push(Math.max(4, Math.min(100, c)));
                            sys.cpuHistory = hist;
                        }
                    }
                    if (d.ramUsed !== undefined) sys.ramUsed = d.ramUsed;
                    if (d.temp !== undefined) sys.cpuTemp = d.temp;

                    // GPU summary (preserved when --no-gpu omits refresh)
                    if (d.gpuCount !== undefined && d.gpuCount >= 0) sys.gpuCount = d.gpuCount;
                    if (d.gpuTemp !== undefined && d.gpuTemp >= 0) sys.gpuTemp = d.gpuTemp;
                    if (d.gpuUtil !== undefined && d.gpuUtil >= 0) sys.gpuUtil = d.gpuUtil;
                    if (d.gpus !== undefined) sys.gpus = d.gpus;

                    // Expanded fields (only present in full status)
                    if (d.cpuModel) sys.cpuModel = d.cpuModel;
                    if (d.cpuCores !== undefined) sys.cpuCores = d.cpuCores;
                    if (d.cpuFreq) sys.cpuFreq = d.cpuFreq;
                    if (d.loadAvg) sys.loadAvg = d.loadAvg;
                    if (d.cpuCoresLoad && d.cpuCoresLoad.length > 0) sys.cpuCoresLoad = d.cpuCoresLoad;
                    if (d.ramTotal !== undefined) sys.ramTotal = d.ramTotal;
                    if (d.ramPct !== undefined) sys.ramPct = d.ramPct;
                    if (d.ramCached !== undefined) sys.ramCached = d.ramCached;
                    if (d.swapUsed !== undefined) sys.swapUsed = d.swapUsed;
                    if (d.swapTotal !== undefined) sys.swapTotal = d.swapTotal;
                    if (d.diskUsed !== undefined) sys.diskUsed = d.diskUsed;
                    if (d.diskTotal !== undefined) sys.diskTotal = d.diskTotal;
                    if (d.diskFree !== undefined) sys.diskFree = d.diskFree;
                    if (d.diskFs !== undefined) sys.diskFs = d.diskFs;
                    if (d.diskPct !== undefined) sys.diskPct = d.diskPct;
                    if (d.netDown !== undefined) sys.netDown = d.netDown;
                    if (d.netUp !== undefined) sys.netUp = d.netUp;
                    if (d.netIp !== undefined) sys.netIp = d.netIp;
                    if (d.netIface !== undefined) sys.netIface = d.netIface;
                    if (d.kernel) sys.kernelVer = d.kernel;
                    if (d.uptime !== undefined) sys.uptimeStr = d.uptime;
                    if (d.topList && d.topList.length > 0) {
                        sys.topList = d.topList;
                        sys.topListUpdated(d.topList);
                    }

                    // Toggles (protected by optimistic guard window)
                    if (!toggleGuardTimer.running) {
                        if (d.caffeine !== undefined) sys.caffeineActive = Boolean(d.caffeine);
                        if (d.nightlight !== undefined) sys.nightlightActive = Boolean(d.nightlight);
                        if (d.dnd !== undefined) sys.dndActive = Boolean(d.dnd);
                        if (d.powerProfile) sys.powerProfile = d.powerProfile;
                        if (d.aiEngine) sys.aiEngine = d.aiEngine;
                        if (d.zoomEnabled !== undefined) sys.zoomEnabled = Boolean(d.zoomEnabled);
                        if (d.zoomFactor) sys.zoomFactor = String(d.zoomFactor);
                        if (d.gamingMode !== undefined) sys.gamingModeActive = Boolean(d.gamingMode);
                        if (d.autoGaming !== undefined) sys.autoGamingEnabled = Boolean(d.autoGaming);
                    }

                    if (d.recording !== undefined) sys.isRecording = Boolean(d.recording);
                    if (d.recTime !== undefined) sys.recTime = d.recTime;
                    if (d.hasBattery !== undefined) sys.hasBattery = Boolean(d.hasBattery);
                    if (d.batPct !== undefined) sys.batPct = d.batPct;
                    if (d.batStatus !== undefined) sys.batStatus = d.batStatus;

                    if (!brGuardTimer.running && !sys.brightnessDragging && d.brightness !== undefined) {
                        sys.brightnessVal = d.brightness;
                    }
                } catch (e) {}
            }
        }
    }

    // Event-driven Fullscreen & Auto-Gaming Detector (0 polling; reacts purely to Hyprland IPC events)
    readonly property Process _fsCheckProc: Process {
        id: fsCheckProc
        command: ["/usr/bin/x64-hyprland-ctl", "fullscreen-state"]
        stdout: StdioCollector {
            id: fsCollector
            onStreamFinished: {
                var raw = (fsCollector.text || "").trim();
                var parts = raw.split("|");
                if (parts.length >= 1 && (parts[0] === "1" || parts[0] === "0")) {
                    sys.fullscreenActive = (parts[0] === "1");
                }
                if (parts.length >= 2 && (parts[1] === "1" || parts[1] === "0")) {
                    var gameNow = (parts[1] === "1");
                    var prevGame = sys.autoGameDetected;
                    sys.autoGameDetected = gameNow;
                    if (gameNow && !prevGame && sys.autoGamingEnabled && !sys.gamingModeActive) {
                        sys.gamingModeActive = true;
                        sys.runCtl(["gamemode", "auto-on"]);
                    } else if (!gameNow && prevGame) {
                        sys.runCtl(["gamemode", "auto-off"]);
                    }
                }
            }
        }
    }

    readonly property Timer _fsCheckDebounce: Timer {
        id: fsCheckDebounce
        interval: 160
        repeat: false
        onTriggered: {
            if (!fsCheckProc.running) fsCheckProc.running = true;
        }
    }

    Component.onCompleted: {
        sys._updateClock();
        fsCheckDebounce.restart();
    }

    // Shared Keyboard Layout, Network Capsule & Clock (0 duplication on multi-monitor bars)
    readonly property Timer _clockTimer: Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sys._updateClock()
    }

    readonly property Timer _kbGuardTimer: Timer {
        id: kbGuardTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (!kbProcess.running) kbProcess.running = true;
        }
    }

    readonly property Process _kbProcess: Process {
        id: kbProcess
        command: ["/usr/bin/x64-hyprland-ctl", "keyboard", "get"]
        stdout: StdioCollector {
            id: kbCollector
            onStreamFinished: {
                if (!kbCollector.text || kbGuardTimer.running) return;
                var val = kbCollector.text.trim();
                if (val.length > 0) sys.kbLayout = val;
            }
        }
    }

    readonly property Process _kbSwitchProc: Process {
        id: kbSwitchProc
        command: ["/usr/bin/x64-hyprland-ctl", "keyboard", "next"]
        stdout: StdioCollector {
            id: kbSwitchCollector
            onStreamFinished: {
                if (!kbSwitchCollector.text) return;
                var val = kbSwitchCollector.text.trim();
                if (val.length > 0) sys.kbLayout = val;
            }
        }
        onExited: {
            kbGuardTimer.stop();
            if (!kbProcess.running) kbProcess.running = true;
        }
    }

    readonly property Process _netProcess: Process {
        id: netProcess
        command: ["sh", "-c", "route=$(ip route get 1.1.1.1 2>/dev/null | head -n1); if [ -n \"$route\" ]; then dev=$(echo \"$route\" | awk '{print $5}'); if [ -d \"/sys/class/net/$dev/wireless\" ]; then ssid=$(iw dev \"$dev\" link 2>/dev/null | awk -F': ' '/SSID/{print $2}'); echo \"WIFI|${ssid:-Wi-Fi}\"; else echo \"LAN|Cable\"; fi; else echo \"NONE|Desconectado\"; fi"]
        stdout: StdioCollector {
            id: netCollector
            onStreamFinished: {
                if (!netCollector.text) return;
                var parts = netCollector.text.trim().split("|");
                sys.netType = parts[0] || "LAN";
                sys.netName = parts[1] || "Cable";
            }
        }
    }

    readonly property Timer _kbNetTimer: Timer {
        id: kbNetTimer
        interval: 4000
        running: !sys.fullscreenActive
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!kbProcess.running) kbProcess.running = true;
            if (!netProcess.running) netProcess.running = true;
        }
    }

    readonly property Connections _hyprConn: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event || !event.name) return;
            var name = String(event.name);
            if (name.indexOf("activelayout") !== -1 || name === "configreloaded") {
                if (!kbProcess.running) kbProcess.running = true;
            }
            if (name === "fullscreen") {
                var data = String(event.data || "").trim();
                if (data === "1" || data === "0") {
                    sys.fullscreenActive = (data === "1");
                }
                if (sys.autoGamingEnabled || sys.autoGameDetected || (data !== "1" && data !== "0")) {
                    fsCheckDebounce.restart();
                }
            } else if (name === "workspace" || name === "workspacev2" || name === "focusedmon" || name === "closewindow" || name === "movewindow") {
                fsCheckDebounce.restart();
            } else if (name === "activewindow" && (sys.fullscreenActive || sys.autoGameDetected)) {
                fsCheckDebounce.restart();
            }
        }
    }
}
