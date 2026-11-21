import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris

PanelWindow {
    id: barWindow

    property bool isPrimaryBar: true
    readonly property var hyprMon: barWindow.screen ? Hyprland.monitorFor(barWindow.screen) : null
    readonly property int monitorActiveWsId: (hyprMon && hyprMon.activeWorkspace) ? hyprMon.activeWorkspace.id : (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)
    readonly property bool monitorFocused: hyprMon ? Boolean(hyprMon.focused) : true

    signal toggleLauncher()
    signal toggleCalendar()
    signal toggleControl()
    signal togglePower()
    signal toggleTelemetry()
    signal toggleNetwork()
    signal toggleAudio(string tab)
    signal brightnessChangedOsd(int val)

    property bool trayExpanded: false

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 0
        left: 0
        right: 0
    }

    implicitHeight: 40
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 40
    WlrLayershell.namespace: "quickshell"

    // Native Wayland Idle Inhibitor (zwp_idle_inhibit_manager_v1) for Modo Café (single instance on primary bar)
    IdleInhibitor {
        enabled: barWindow.isPrimaryBar && barWindow.caffeineActive
        window: barWindow
    }

    // Track PipeWire default audio devices so Quickshell activates volume & mute telemetry
    PwObjectTracker {
        objects: {
            var list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
            return list;
        }
    }

    // =========================================================================
    // SYSTEM TELEMETRY & BACKGROUND MONITORS (Backed by SysState Singleton)
    // =========================================================================

    readonly property int cpuUsage: SysState.cpuUsage
    readonly property string ramUsage: SysState.ramUsed
    readonly property int cpuTemp: SysState.cpuTemp
    readonly property bool caffeineActive: SysState.caffeineActive
    readonly property bool nightlightActive: SysState.nightlightActive
    readonly property bool dndActive: SysState.dndActive
    readonly property bool isRecording: SysState.isRecording
    readonly property string recTime: SysState.recTime
    readonly property bool gamingModeActive: SysState.gamingModeActive
    readonly property bool hasBattery: SysState.hasBattery
    readonly property int batPct: SysState.batPct
    readonly property string batStatus: SysState.batStatus
    readonly property int brightnessVal: SysState.brightnessVal
    readonly property int gpuCount: SysState.gpuCount
    readonly property int gpuTemp: SysState.gpuTemp
    readonly property int gpuUtil: SysState.gpuUtil
    readonly property var gpus: SysState.gpus
    readonly property string kbLayout: SysState.kbLayout
    readonly property string netType: SysState.netType
    readonly property string netName: SysState.netName
    readonly property string timeStr: SysState.timeStr
    readonly property string dateStr: SysState.dateStr

    function runCtl(args) {
        SysState.runCtl(args);
    }

    Process {
        id: appSpawnProc
    }

    function spawnApp(cmdStr) {
        if (appSpawnProc.running) {
            appSpawnProc.running = false;
        }
        appSpawnProc.command = ["bash", "-c", "nohup " + cmdStr + " >/dev/null 2>&1 &"];
        appSpawnProc.running = true;
    }

    // =========================================================================
    // BAR BACKGROUND SURFACE (AERODYNAMIC SATIN OBSIDIAN GLASS)
    // =========================================================================

    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: Theme.bgBar

        // Top 1px specular highlight line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#18ffffff"
        }

        // Bottom 1px razor-sharp theme accent neon glow line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Theme.accentGlowLine
        }

        // =====================================================================
        // THREE INDEPENDENTLY ANCHORED LUXURY SECTIONS (Zero Drift Architecture)
        // =====================================================================

        // -----------------------------------------------------------------
        // 1. LEFT CAPSULE: SOBERANA NAVEGACIÓN (Brand + Workspaces + Title)
        // -----------------------------------------------------------------
        Rectangle {
            id: navCapsule
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: 30
            implicitWidth: navRow.implicitWidth + 10
            radius: 15
            color: Theme.bgCapsule
            border.color: "#1affffff"
            border.width: 1

                RowLayout {
                    id: navRow
                    anchors.centerIn: parent
                    spacing: 7

                    // Brand Icon & Badge (Launcher on Left Click, Kitty on Right Click)
                    Rectangle {
                        id: brandPill
                        implicitWidth: brandRow.implicitWidth + 10
                        implicitHeight: 24
                        radius: 12
                        color: brandArea.containsMouse ? Theme.accentSubtle : "transparent"
                        scale: brandArea.pressed ? 0.90 : (brandArea.containsMouse ? 1.05 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: brandRow
                            anchors.centerIn: parent
                            spacing: 6

                            Image {
                                source: Qt.resolvedUrl("x64-logo-bar.png")
                                width: 17
                                height: 17
                                Layout.preferredWidth: 17
                                Layout.preferredHeight: 17
                                smooth: true
                                fillMode: Image.PreserveAspectFit
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "X64 LIOS"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.textPrimary
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: brandArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    barWindow.toggleLauncher();
                                } else if (mouse.button === Qt.RightButton) {
                                    barWindow.spawnApp("kitty");
                                }
                            }
                        }
                    }

                    // Subtle Hairline Divider
                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 14
                        color: "#1affffff"
                    }

                    // Morphic Geometric Workspaces (Reactive Pills & Dots)
                    Item {
                        id: wsContainer
                        implicitWidth: wsLayout.implicitWidth
                        implicitHeight: 24

                        RowLayout {
                            id: wsLayout
                            anchors.fill: parent
                            spacing: 5

                            Repeater {
                                model: [1, 2, 3, 4, 5, 6, 7]

                                Item {
                                    id: wsItem
                                    required property int modelData

                                    readonly property bool isMonitorActive: barWindow.monitorActiveWsId === modelData
                                    readonly property bool isGlobalFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                                    readonly property bool isFocused: isMonitorActive
                                    readonly property bool isOccupied: {
                                        if (!Hyprland.workspaces) return false;
                                        var list = Hyprland.workspaces.values;
                                        for (var i = 0; i < list.length; i++) {
                                            if (list[i].id === modelData) return true;
                                        }
                                        return false;
                                    }

                                    implicitWidth: wsIndicator.width + 6
                                    implicitHeight: 24

                                    Rectangle {
                                        id: wsIndicator
                                        anchors.centerIn: parent

                                        // Dynamic morphic pill: elongated glowing bar for this monitor's active ws
                                        width: {
                                            if (wsItem.isFocused) return wsArea.containsMouse ? 24 : 20;
                                            if (wsArea.containsMouse) return 10;
                                            return wsItem.isOccupied ? 6 : 5;
                                        }
                                        height: wsItem.isFocused ? 6 : (wsItem.isOccupied ? 6 : 5)
                                        radius: height / 2

                                        color: {
                                            if (wsItem.isFocused) return (barWindow.monitorFocused || wsItem.isGlobalFocused) ? Theme.accent : Theme.accentHalf;
                                            if (wsArea.containsMouse) return "#ffffff";
                                            if (wsItem.isOccupied) return "#c0c0d0";
                                            return "#404050";
                                        }

                                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }

                                    MouseArea {
                                        id: wsArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsItem.modelData + " })")
                                    }
                                }
                            }
                        }

                        // Mouse wheel over workspaces to cycle
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0) {
                                    Hyprland.dispatch('hl.dsp.focus({ workspace = "r-1" })');
                                } else if (wheel.angleDelta.y < 0) {
                                    Hyprland.dispatch('hl.dsp.focus({ workspace = "r+1" })');
                                }
                            }
                        }
                    }

                    // Active Window Title Pill (Fade in when a window is focused)
                    readonly property var activeTop: ToplevelManager.activeToplevel
                    readonly property string winTitle: activeTop ? (activeTop.title || activeTop.appId || "") : ""

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 14
                        color: "#1affffff"
                        visible: navRow.winTitle !== ""
                    }

                    Item {
                        id: titleBox
                        visible: navRow.winTitle !== ""
                        implicitWidth: Math.min(180, titleRow.implicitWidth)
                        implicitHeight: 24
                        Layout.maximumWidth: 180

                        RowLayout {
                            id: titleRow
                            anchors.fill: parent
                            spacing: 5

                            Text {
                                text: ""
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.accent
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: navRow.winTitle
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: titleArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: titleArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (!navRow.activeTop) return;
                                if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
                                    navRow.activeTop.close();
                                } else {
                                    navRow.activeTop.activate();
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 2. CENTER SECTION: NOW-PLAYING MPRIS + CHRONOS MASTER CAPSULE
            // Mathematically pinned to absolute screen center (Zero Drift)
            // -----------------------------------------------------------------
            RowLayout {
                id: centerSection
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // MPRIS Media Capsule (Shows dynamically when track is playing)
                Rectangle {
                    id: mprisCapsule
                    readonly property var players: Mpris.players ? Mpris.players.values : []
                    readonly property var activePlayer: {
                        for (var i = 0; i < players.length; i++) {
                            if (players[i].isPlaying) return players[i];
                        }
                        return players.length > 0 ? players[0] : null;
                    }
                    readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.trackArtist !== "")
                    visible: hasMedia

                    implicitHeight: 30
                    implicitWidth: Math.min(220, mprisRow.implicitWidth + 16)
                    radius: 15
                    color: mprisArea.containsMouse ? Theme.bgHover : Theme.bgCapsule
                    border.color: mprisArea.containsMouse ? Theme.accent : "#1affffff"
                    border.width: 1

                    RowLayout {
                        id: mprisRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: (mprisCapsule.activePlayer && mprisCapsule.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.accent
                        }

                        Text {
                            text: {
                                if (!mprisCapsule.activePlayer) return "";
                                var t = mprisCapsule.activePlayer.trackTitle || "";
                                var a = mprisCapsule.activePlayer.trackArtist || "";
                                return a !== "" ? (t + " • " + a) : t;
                            }
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.maximumWidth: 160
                        }
                    }

                    MouseArea {
                        id: mprisArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (!mprisCapsule.activePlayer) return;
                            if (mouse.button === Qt.LeftButton) mprisCapsule.activePlayer.playPause();
                            else if (mouse.button === Qt.RightButton) mprisCapsule.activePlayer.next();
                        }
                        onWheel: (wheel) => {
                            if (!mprisCapsule.activePlayer) return;
                            if (wheel.angleDelta.y > 0) mprisCapsule.activePlayer.next();
                            else mprisCapsule.activePlayer.previous();
                        }
                    }
                }

                // Chronos Master Capsule (Clock & Date -> Dropdown Calendar Popup)
                Rectangle {
                    id: clockCapsule
                    implicitHeight: 30
                    implicitWidth: clockRow.implicitWidth + 24
                    radius: 15
                    color: clockArea.containsMouse ? Theme.bgHover : Theme.bgCapsule
                    border.color: clockArea.containsMouse ? Theme.borderAccent : Theme.borderGlass
                    border.width: 1
                    scale: clockArea.pressed ? 0.94 : (clockArea.containsMouse ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: barWindow.timeStr
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Rectangle {
                            implicitWidth: 5
                            implicitHeight: 5
                            radius: 3
                            color: Theme.accent
                        }

                        Text {
                            text: barWindow.dateStr
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.4
                            color: Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: clockArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWindow.toggleCalendar()
                    }
                }

                // Live Screen Recording Capsule (Omarchy-style 1-click stop)
                Rectangle {
                    id: recCapsule
                    visible: barWindow.isRecording
                    implicitHeight: 30
                    implicitWidth: recRow.implicitWidth + 16
                    radius: 15
                    color: recArea.containsMouse ? Theme.accent : Theme.accentPillBg
                    border.color: Theme.accent
                    border.width: 1

                    RowLayout {
                        id: recRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            id: recDot
                            text: "󰑊"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: recArea.containsMouse ? "#ffffff" : Theme.accent

                            SequentialAnimation on opacity {
                                running: barWindow.isRecording
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.25; duration: 600 }
                                NumberAnimation { from: 0.25; to: 1.0; duration: 600 }
                            }
                        }

                        Text {
                            text: "REC " + barWindow.recTime
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: recArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SysState.isRecording = false;
                            barWindow.runCtl(["record", "stop"]);
                        }
                    }
                }

                // Compact Gaming Mode Indicator Capsule (visible only when active; 1-click disable)
                Rectangle {
                    id: gameCapsule
                    visible: barWindow.gamingModeActive
                    implicitHeight: 30
                    implicitWidth: gameRow.implicitWidth + 16
                    radius: 15
                    color: gameArea.containsMouse ? Theme.accent : Theme.accentPillBg
                    border.color: Theme.accent
                    border.width: 1
                    scale: gameArea.pressed ? 0.94 : (gameArea.containsMouse ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: gameRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰊴"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: gameArea.containsMouse ? "#ffffff" : Theme.accent
                        }

                        Text {
                            text: "GAME"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.7
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        id: gameArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SysState.guardToggle();
                            SysState.gamingModeActive = false;
                            barWindow.runCtl(["gamemode", "off"]);
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. RIGHT SECTION: MONOCHROMATIC LUXURY CAPSULES (Color = State)
            // Anchored to right bezel (Zero Drift)
            // -----------------------------------------------------------------
            RowLayout {
                id: rightSection
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Island 3A: Hardware Telemetry Capsule (CPU%, RAM & Temp °C)
                Rectangle {
                    id: telemetryCapsule
                    implicitHeight: 30
                    implicitWidth: telemetryRow.implicitWidth + 20
                    radius: 15
                    color: teleArea.containsMouse ? Theme.bgHover : Theme.bgCapsule
                    border.color: teleArea.containsMouse ? Theme.borderAccent : Theme.borderGlass
                    border.width: 1
                    scale: teleArea.pressed ? 0.94 : (teleArea.containsMouse ? 1.02 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: telemetryRow
                        anchors.centerIn: parent
                        spacing: 6

                        // CPU (Threshold-aware: neutral silver at rest, amber >=65%, crimson >=85%)
                        Text {
                            text: "󰻠"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: barWindow.cpuUsage >= 85 ? Theme.accent : (barWindow.cpuUsage >= 65 ? Theme.statusWarn : Theme.textSecondary)
                        }

                        Text {
                            text: barWindow.cpuUsage + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: barWindow.cpuUsage >= 85 ? Theme.accent : (barWindow.cpuUsage >= 65 ? Theme.statusWarn : Theme.textPrimary)
                        }

                        // Divider
                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 14
                            color: "#16ffffff"
                        }

                        // RAM (Monochromatic neutral silver icon + bone white text)
                        Text {
                            text: "󰍛"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: Theme.textSecondary
                        }

                        Text {
                            text: barWindow.ramUsage + "G"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        // Divider
                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 14
                            color: "#16ffffff"
                        }

                        // CPU Temperature (Threshold-aware: neutral silver <65°C, amber >=65°C, crimson >=78°C)
                        Text {
                            text: "󰔏"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: barWindow.cpuTemp >= 78 ? Theme.accent : (barWindow.cpuTemp >= 65 ? Theme.statusWarn : Theme.textSecondary)
                        }

                        Text {
                            text: barWindow.cpuTemp + "°C"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: barWindow.cpuTemp >= 78 ? Theme.accent : (barWindow.cpuTemp >= 65 ? Theme.statusWarn : Theme.textPrimary)
                        }

                        // Divider (GPU)
                        Rectangle {
                            visible: barWindow.gpuCount > 0
                            implicitWidth: 1
                            implicitHeight: 14
                            color: "#16ffffff"
                        }

                        // Dedicated GPU (Threshold-aware: neutral silver <65°C, amber >=65°C, crimson >=78°C)
                        Text {
                            visible: barWindow.gpuCount > 0
                            text: "󰢮"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: barWindow.gpuTemp >= 78 ? Theme.accent : (barWindow.gpuTemp >= 65 ? Theme.statusWarn : Theme.textSecondary)
                        }

                        Text {
                            visible: barWindow.gpuCount > 0
                            text: barWindow.gpuTemp + "°C"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: barWindow.gpuTemp >= 78 ? Theme.accent : (barWindow.gpuTemp >= 65 ? Theme.statusWarn : Theme.textPrimary)
                        }
                    }

                    MouseArea {
                        id: teleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                barWindow.spawnApp("kitty -e btop");
                            } else {
                                barWindow.toggleTelemetry();
                            }
                        }
                    }
                }

                // Island 3B: System Status Capsule (KB, Network, Audio, Brightness, Battery, Tray)
                Rectangle {
                    id: systemCapsule
                    implicitHeight: 30
                    implicitWidth: systemRow.implicitWidth + 16
                    radius: 15
                    color: Theme.bgCapsule
                    border.color: Theme.borderGlass
                    border.width: 1

                    readonly property var defaultSink: Pipewire.defaultAudioSink
                    readonly property real sinkVol: (defaultSink && defaultSink.audio) ? defaultSink.audio.volume : 0.0
                    readonly property bool sinkMuted: (defaultSink && defaultSink.audio) ? defaultSink.audio.muted : false

                    readonly property var defaultSource: Pipewire.defaultAudioSource
                    readonly property real micVol: (defaultSource && defaultSource.audio) ? defaultSource.audio.volume : 0.0
                    readonly property bool micMuted: (defaultSource && defaultSource.audio) ? defaultSource.audio.muted : true

                    RowLayout {
                        id: systemRow
                        anchors.centerIn: parent
                        spacing: 6

                        // [0] Active Quick-Toggle Indicators (Unified Crimson State Badges)
                        Rectangle {
                            visible: barWindow.caffeineActive
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: cafBarArea.containsMouse ? Theme.accent : Theme.accentDim
                            Text {
                                anchors.centerIn: parent
                                text: "󰅶"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: cafBarArea.containsMouse ? "#ffffff" : Theme.accent
                            }
                            MouseArea {
                                id: cafBarArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SysState.guardToggle();
                                    SysState.caffeineActive = false;
                                    barWindow.runCtl(["caffeine", "off"]);
                                }
                            }
                        }

                        Rectangle {
                            visible: barWindow.nightlightActive
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: nlBarArea.containsMouse ? Theme.accent : Theme.accentDim
                            Text {
                                anchors.centerIn: parent
                                text: "󰖔"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: nlBarArea.containsMouse ? "#ffffff" : Theme.accent
                            }
                            MouseArea {
                                id: nlBarArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SysState.guardToggle();
                                    SysState.nightlightActive = false;
                                    barWindow.runCtl(["nightlight", "off"]);
                                }
                            }
                        }

                        Rectangle {
                            visible: barWindow.dndActive
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 11
                            color: dndBarArea.containsMouse ? Theme.accent : Theme.accentDim
                            Text {
                                anchors.centerIn: parent
                                text: "󰂛"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: dndBarArea.containsMouse ? "#ffffff" : Theme.accent
                            }
                            MouseArea {
                                id: dndBarArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SysState.guardToggle();
                                    SysState.dndActive = false;
                                    barWindow.runCtl(["dnd", "off"]);
                                }
                            }
                        }

                        Rectangle {
                            visible: barWindow.caffeineActive || barWindow.nightlightActive || barWindow.dndActive
                            implicitWidth: 1
                            implicitHeight: 14
                            color: "#16ffffff"
                        }

                        // [A] Keyboard Layout Indicator (Clean Monospace Code US <-> ES)
                        Rectangle {
                            id: kbItem
                            implicitWidth: kbLabel.implicitWidth + 8
                            implicitHeight: 22
                            radius: 11
                            color: kbArea.containsMouse ? "#1affffff" : "transparent"

                            Text {
                                id: kbLabel
                                anchors.centerIn: parent
                                text: barWindow.kbLayout
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: kbArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            }

                            MouseArea {
                                id: kbArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SysState.switchKeyboardLayout()
                            }
                        }

                        // Divider
                        Rectangle { implicitWidth: 1; implicitHeight: 14; color: "#16ffffff" }

                        // [B] Network Indicator (Clean Icon in Monochromatic Bone/Silver; Crimson only if offline)
                        Rectangle {
                            id: netItem
                            implicitWidth: netRow.implicitWidth + 8
                            implicitHeight: 22
                            radius: 11
                            color: netArea.containsMouse ? "#1affffff" : "transparent"
                            scale: netArea.pressed ? 0.90 : (netArea.containsMouse ? 1.06 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }

                            RowLayout {
                                id: netRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: barWindow.netType === "WIFI" ? "󰤨" : (barWindow.netType === "NONE" ? "󰤮" : "󰈀")
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: barWindow.netType === "NONE" ? Theme.accent : (netArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                                }

                                Text {
                                    visible: barWindow.netType === "WIFI"
                                    text: barWindow.netName
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textPrimary
                                    Layout.maximumWidth: 68
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: netArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        barWindow.spawnApp("nm-connection-editor");
                                    } else {
                                        barWindow.toggleNetwork();
                                    }
                                }
                            }
                        }

                        // Divider (Only visible when physical Microphone is present)
                        Rectangle {
                            visible: systemCapsule.defaultSource !== null
                            implicitWidth: 1
                            implicitHeight: 10
                            color: "#16ffffff"
                        }

                        // [C] Smart Microphone Control
                        Rectangle {
                            id: micItem
                            visible: systemCapsule.defaultSource !== null
                            implicitWidth: micRow.implicitWidth + 8
                            implicitHeight: 22
                            radius: 11
                            color: micArea.containsMouse ? "#1affffff" : "transparent"

                            RowLayout {
                                id: micRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: systemCapsule.micMuted ? "󰍭" : "󰍬"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    color: systemCapsule.micMuted ? Theme.accent : Theme.textSecondary
                                }

                                Text {
                                    text: systemCapsule.micMuted ? "MUT" : Math.round(systemCapsule.micVol * 100) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: systemCapsule.micMuted ? Theme.accent : Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: micArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        barWindow.toggleAudio("sources");
                                    } else {
                                        if (systemCapsule.defaultSource && systemCapsule.defaultSource.audio) {
                                            systemCapsule.defaultSource.audio.muted = !systemCapsule.defaultSource.audio.muted;
                                        }
                                    }
                                }
                                onWheel: (wheel) => {
                                    if (systemCapsule.defaultSource && systemCapsule.defaultSource.audio) {
                                        var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                        systemCapsule.defaultSource.audio.volume = Math.max(0.0, Math.min(1.0, systemCapsule.defaultSource.audio.volume + step));
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle { implicitWidth: 1; implicitHeight: 14; color: "#16ffffff" }

                        // [D] Master Volume Control
                        Rectangle {
                            id: volItem
                            implicitWidth: volRow.implicitWidth + 8
                            implicitHeight: 22
                            radius: 11
                            color: volArea.containsMouse ? "#1affffff" : "transparent"

                            RowLayout {
                                id: volRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: systemCapsule.sinkMuted ? "󰝟" : (systemCapsule.sinkVol <= 0.01 ? "󰕿" : (systemCapsule.sinkVol < 0.5 ? "󰖀" : "󰕾"))
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: systemCapsule.sinkMuted ? Theme.accent : (systemCapsule.sinkVol > 1.0 ? Theme.accent : Theme.textSecondary)
                                }

                                Text {
                                    text: systemCapsule.sinkMuted ? "MUT" : Math.round(systemCapsule.sinkVol * 100) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: systemCapsule.sinkMuted ? Theme.accent : (systemCapsule.sinkVol > 1.0 ? Theme.accent : Theme.textPrimary)
                                }
                            }

                            MouseArea {
                                id: volArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        barWindow.toggleAudio("sinks");
                                    } else {
                                        if (systemCapsule.defaultSink && systemCapsule.defaultSink.audio) {
                                            systemCapsule.defaultSink.audio.muted = !systemCapsule.defaultSink.audio.muted;
                                        }
                                    }
                                }
                                onWheel: (wheel) => {
                                    if (systemCapsule.defaultSink && systemCapsule.defaultSink.audio) {
                                        var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                        systemCapsule.defaultSink.audio.volume = Math.max(0.0, Math.min(1.5, systemCapsule.defaultSink.audio.volume + step));
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle { implicitWidth: 1; implicitHeight: 14; color: "#16ffffff" }

                        // [D2] Display Brightness Control (Neutral silver icon, bone-white text)
                        Rectangle {
                            id: brItem
                            implicitWidth: brRow.implicitWidth + 8
                            implicitHeight: 22
                            radius: 11
                            color: brArea.containsMouse ? "#1affffff" : "transparent"

                            RowLayout {
                                id: brRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "󰃠"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: Theme.textSecondary
                                }

                                Text {
                                    text: barWindow.brightnessVal + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: brArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: barWindow.toggleControl()
                                onWheel: (wheel) => {
                                    SysState.guardBrightness();
                                    var step = wheel.angleDelta.y > 0 ? 5 : -5;
                                    var nextBr = Math.max(15, Math.min(100, SysState.brightnessVal + step));
                                    SysState.brightnessVal = nextBr;
                                    barWindow.brightnessChangedOsd(nextBr);
                                    barWindow.runCtl(["brightness", "set", String(nextBr)]);
                                }
                            }
                        }

                        // [D3] Smart Battery Indicator (Auto-shows only when physical battery is present)
                        Rectangle {
                            visible: barWindow.hasBattery
                            implicitWidth: 1
                            implicitHeight: 10
                            color: "#16ffffff"
                        }

                        Rectangle {
                            id: batItem
                            visible: barWindow.hasBattery
                            implicitWidth: batRow.implicitWidth + 8
                            implicitHeight: 22
                            radius: 11
                            color: batArea.containsMouse ? "#1affffff" : "transparent"

                            RowLayout {
                                id: batRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: {
                                        if (barWindow.batStatus === "Charging" || barWindow.batStatus === "Full") return "󰂄";
                                        if (barWindow.batPct >= 85) return "󰁹";
                                        if (barWindow.batPct >= 60) return "󰂀";
                                        if (barWindow.batPct >= 35) return "󰁾";
                                        if (barWindow.batPct >= 15) return "󰁻";
                                        return "󰂃";
                                    }
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    color: barWindow.batPct <= 15 ? Theme.accent : Theme.textSecondary
                                }

                                Text {
                                    text: barWindow.batPct + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: barWindow.batPct <= 15 ? Theme.accent : Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: batArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: barWindow.toggleControl()
                            }
                        }

                        // [E] System Tray Collapsible Drawer (Only shown if tray items exist)
                        Rectangle {
                            visible: trayRepeater.count > 0
                            implicitWidth: 1
                            implicitHeight: 10
                            color: "#16ffffff"
                        }

                        RowLayout {
                            visible: trayRepeater.count > 0
                            spacing: 2

                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 18
                                radius: 7
                                color: trayToggleArea.containsMouse ? "#1affffff" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: barWindow.trayExpanded ? "❯" : "❮"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: trayToggleArea.containsMouse ? Theme.textPrimary : Theme.textMuted
                                }

                                MouseArea {
                                    id: trayToggleArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: barWindow.trayExpanded = !barWindow.trayExpanded
                                }
                            }

                            Item {
                                id: trayContainer
                                clip: true
                                implicitWidth: barWindow.trayExpanded ? trayItemsRow.implicitWidth : 0
                                implicitHeight: 18

                                Behavior on implicitWidth {
                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }

                                RowLayout {
                                    id: trayItemsRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3

                                    Repeater {
                                        id: trayRepeater
                                        model: SystemTray.items

                                        Rectangle {
                                            id: trayIconBtn
                                            required property var modelData
                                            implicitWidth: 22
                                            implicitHeight: 22
                                            radius: 6
                                            color: trayIconArea.containsMouse ? "#25ffffff" : "transparent"

                                            Image {
                                                anchors.centerIn: parent
                                                width: 15
                                                height: 15
                                                sourceSize.width: 15
                                                sourceSize.height: 15
                                                source: trayIconBtn.modelData.icon || ""
                                                fillMode: Image.PreserveAspectFit
                                            }

                                            MouseArea {
                                                id: trayIconArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: (mouse) => {
                                                    if (mouse.button === Qt.LeftButton) {
                                                        trayIconBtn.modelData.activate();
                                                    } else if (mouse.button === Qt.RightButton && trayIconBtn.modelData.hasMenu) {
                                                        trayIconBtn.modelData.secondaryActivate();
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // [F] Standalone Control Center Pill Button (Sliders Icon)
                Rectangle {
                    id: ctrlBtn
                    implicitWidth: 32
                    implicitHeight: 30
                    radius: 15
                    color: ctrlArea.containsMouse ? Theme.accentDim : Theme.bgCapsule
                    border.color: ctrlArea.containsMouse ? Theme.borderAccent : Theme.borderGlass
                    border.width: 1
                    scale: ctrlArea.pressed ? 0.90 : (ctrlArea.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰒓"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: ctrlArea.containsMouse ? Theme.accent : Theme.textPrimary
                    }

                    MouseArea {
                        id: ctrlArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWindow.toggleControl()
                    }
                }

                // [G] Standalone Power / Fast Exit Pill Button
                Rectangle {
                    id: pwrBtn
                    implicitWidth: 32
                    implicitHeight: 30
                    radius: 15
                    color: pwrArea.containsMouse ? Theme.accent : Theme.bgCapsule
                    border.color: pwrArea.containsMouse ? Theme.accentLight : Theme.borderGlass
                    border.width: 1
                    scale: pwrArea.pressed ? 0.90 : (pwrArea.containsMouse ? 1.06 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: pwrArea.containsMouse ? "#ffffff" : Theme.accent
                    }

                    MouseArea {
                        id: pwrArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWindow.togglePower()
                    }
                }
            }
        }
    }
