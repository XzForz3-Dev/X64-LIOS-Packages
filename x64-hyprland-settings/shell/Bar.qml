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
    property bool calendarOpen: false
    property bool telemetryOpen: false
    property bool networkOpen: false
    property bool audioOpen: false
    property bool notifCenterOpen: false
    property bool controlCenterOpen: false
    property bool powerMenuOpen: false
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
    signal toggleNotifications()
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
            implicitWidth: navRow.implicitWidth + 8
            radius: 15
            color: Theme.bgCapsule
            border.color: Theme.borderGlass
            border.width: 1

                RowLayout {
                    id: navRow
                    anchors.centerIn: parent
                    spacing: 6

                    // Brand Icon & Badge (Launcher on Left Click, Kitty on Right Click)
                    Rectangle {
                        id: brandPill
                        implicitWidth: brandRow.implicitWidth + 12
                        implicitHeight: 24
                        radius: 12
                        color: brandArea.containsMouse ? Theme.bgHover : "transparent"
                        scale: brandArea.pressed ? 0.94 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }

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
                                color: brandArea.containsMouse ? Theme.accent : Theme.textPrimary
                                Behavior on color { ColorAnimation { duration: 140 } }
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
                        implicitHeight: 12
                        radius: 0.5
                        color: "#1cffffff"
                    }

                    // Morphic Geometric Workspaces (Always 1..7 + dynamic 8..10 when occupied/active)
                    Item {
                        id: wsContainer
                        implicitWidth: wsLayout.implicitWidth
                        implicitHeight: 24

                        readonly property var visibleWorkspaces: {
                            var list = [1, 2, 3, 4, 5, 6, 7];
                            var extras = {};
                            if (barWindow.monitorActiveWsId > 7 && barWindow.monitorActiveWsId <= 10) {
                                extras[barWindow.monitorActiveWsId] = true;
                            }
                            if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id > 7 && Hyprland.focusedWorkspace.id <= 10) {
                                extras[Hyprland.focusedWorkspace.id] = true;
                            }
                            if (Hyprland.workspaces && Hyprland.workspaces.values) {
                                var wsList = Hyprland.workspaces.values;
                                for (var i = 0; i < wsList.length; i++) {
                                    var wid = wsList[i].id;
                                    if (wid > 7 && wid <= 10) extras[wid] = true;
                                }
                            }
                            for (var id = 8; id <= 10; id++) {
                                if (extras[id]) list.push(id);
                            }
                            return list;
                        }

                        RowLayout {
                            id: wsLayout
                            anchors.fill: parent
                            spacing: 5

                            Repeater {
                                model: wsContainer.visibleWorkspaces

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
                        implicitHeight: 12
                        radius: 0.5
                        color: "#1cffffff"
                        visible: navRow.winTitle !== ""
                    }

                    Rectangle {
                        id: titleBox
                        visible: navRow.winTitle !== ""
                        implicitWidth: Math.min(188, titleRow.implicitWidth + 12)
                        implicitHeight: 24
                        radius: 12
                        Layout.maximumWidth: 188
                        color: titleArea.containsMouse ? Theme.bgHover : "transparent"
                        scale: titleArea.pressed ? 0.95 : 1.0
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        RowLayout {
                            id: titleRow
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 5

                            Text {
                                text: ""
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: titleArea.containsMouse ? Theme.accent : Theme.textSecondary
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: navRow.winTitle
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: titleArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                Behavior on color { ColorAnimation { duration: 140 } }
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
                    implicitWidth: Math.min(220, mprisRow.implicitWidth + 18)
                    radius: 15
                    color: mprisArea.containsMouse ? Theme.bgHover : Theme.bgCapsule
                    border.color: mprisArea.containsMouse ? Theme.borderAccent : Theme.borderGlass
                    border.width: 1
                    scale: mprisArea.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

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
                    color: (barWindow.calendarOpen || clockArea.containsMouse) ? Theme.bgHover : Theme.bgCapsule
                    border.color: (barWindow.calendarOpen || clockArea.containsMouse) ? Theme.borderAccent : Theme.borderGlass
                    border.width: 1
                    scale: clockArea.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

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
                    border.color: Theme.borderAccent
                    border.width: 1
                    scale: recArea.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        id: recRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            id: recDot
                            text: "󰑊"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: recArea.containsMouse ? Theme.accentFg : Theme.accent

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
                            color: recArea.containsMouse ? Theme.accentFg : Theme.textPrimary
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
                    border.color: Theme.borderAccent
                    border.width: 1
                    scale: gameArea.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        id: gameRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰊴"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: gameArea.containsMouse ? Theme.accentFg : Theme.accent
                        }

                        Text {
                            text: "GAME"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.7
                            color: gameArea.containsMouse ? Theme.accentFg : Theme.textPrimary
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
                    color: (barWindow.telemetryOpen || teleArea.containsMouse) ? Theme.bgHover : Theme.bgCapsule
                    border.color: (barWindow.telemetryOpen || teleArea.containsMouse) ? Theme.borderAccent : Theme.borderGlass
                    border.width: 1
                    scale: teleArea.pressed ? 0.96 : 1.0
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        id: telemetryRow
                        anchors.centerIn: parent
                        spacing: 6

                        // CPU (Threshold-aware: neutral silver at rest, amber >=65%, crit red >=85%)
                        Text {
                            text: "󰻠"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: barWindow.cpuUsage >= 85 ? Theme.statusCrit : (barWindow.cpuUsage >= 65 ? Theme.statusWarn : ((barWindow.telemetryOpen || teleArea.containsMouse) ? Theme.accent : Theme.textSecondary))
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Text {
                            text: barWindow.cpuUsage + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: barWindow.cpuUsage >= 85 ? Theme.statusCrit : (barWindow.cpuUsage >= 65 ? Theme.statusWarn : Theme.textPrimary)
                        }

                        // Divider
                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                        }

                        // RAM
                        Text {
                            text: "󰍛"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: (barWindow.telemetryOpen || teleArea.containsMouse) ? Theme.accent : Theme.textSecondary
                            Behavior on color { ColorAnimation { duration: 140 } }
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
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                        }

                        // CPU Temperature (Threshold-aware: neutral <65°C, amber >=65°C, crit red >=78°C)
                        Text {
                            text: "󰔏"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: barWindow.cpuTemp >= 78 ? Theme.statusCrit : (barWindow.cpuTemp >= 65 ? Theme.statusWarn : ((barWindow.telemetryOpen || teleArea.containsMouse) ? Theme.accent : Theme.textSecondary))
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Text {
                            text: barWindow.cpuTemp + "°C"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: barWindow.cpuTemp >= 78 ? Theme.statusCrit : (barWindow.cpuTemp >= 65 ? Theme.statusWarn : Theme.textPrimary)
                        }

                        // Divider (GPU)
                        Rectangle {
                            visible: barWindow.gpuCount > 0
                            implicitWidth: 1
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                        }

                        // Dedicated GPU (Threshold-aware: neutral <65°C, amber >=65°C, crit red >=78°C)
                        Text {
                            visible: barWindow.gpuCount > 0
                            text: "󰢮"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: barWindow.gpuTemp >= 78 ? Theme.statusCrit : (barWindow.gpuTemp >= 65 ? Theme.statusWarn : ((barWindow.telemetryOpen || teleArea.containsMouse) ? Theme.accent : Theme.textSecondary))
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Text {
                            visible: barWindow.gpuCount > 0
                            text: barWindow.gpuTemp + "°C"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: barWindow.gpuTemp >= 78 ? Theme.statusCrit : (barWindow.gpuTemp >= 65 ? Theme.statusWarn : Theme.textPrimary)
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
                // Concentric inner pills (24px, r=12) with unified smooth hover & accent icon glow
                Rectangle {
                    id: systemCapsule
                    implicitHeight: 30
                    implicitWidth: systemRow.implicitWidth + 8
                    radius: 15
                    color: Theme.bgCapsule
                    border.color: (barWindow.networkOpen || barWindow.audioOpen) ? Theme.borderAccent : Theme.borderGlass
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 140 } }

                    readonly property var defaultSink: Pipewire.defaultAudioSink
                    readonly property real sinkVol: (defaultSink && defaultSink.audio) ? defaultSink.audio.volume : 0.0
                    readonly property bool sinkMuted: (defaultSink && defaultSink.audio) ? defaultSink.audio.muted : false

                    readonly property var defaultSource: Pipewire.defaultAudioSource
                    readonly property real micVol: (defaultSource && defaultSource.audio) ? defaultSource.audio.volume : 0.0
                    readonly property bool micMuted: (defaultSource && defaultSource.audio) ? defaultSource.audio.muted : true

                    RowLayout {
                        id: systemRow
                        anchors.centerIn: parent
                        spacing: 3

                        // [0] Active Quick-Toggle Indicators (Unified State Badges)
                        Rectangle {
                            visible: barWindow.caffeineActive
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: cafBarArea.containsMouse ? Theme.accent : Theme.accentDim
                            scale: cafBarArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰅶"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: cafBarArea.containsMouse ? Theme.accentFg : Theme.accent
                                Behavior on color { ColorAnimation { duration: 140 } }
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
                            implicitWidth: 24
                            implicitHeight: 24
                            radius: 12
                            color: nlBarArea.containsMouse ? Theme.accent : Theme.accentDim
                            scale: nlBarArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰖔"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: nlBarArea.containsMouse ? Theme.accentFg : Theme.accent
                                Behavior on color { ColorAnimation { duration: 140 } }
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
                            visible: barWindow.caffeineActive || barWindow.nightlightActive
                            implicitWidth: 1
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                        }

                        // [A] Keyboard Layout Indicator (Clean Monospace Code US <-> ES)
                        Rectangle {
                            id: kbItem
                            implicitWidth: kbLabel.implicitWidth + 12
                            implicitHeight: 24
                            radius: 12
                            color: kbArea.containsMouse ? Theme.bgHover : "transparent"
                            scale: kbArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Text {
                                id: kbLabel
                                anchors.centerIn: parent
                                text: barWindow.kbLayout
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: kbArea.containsMouse ? Theme.accent : Theme.textSecondary
                                Behavior on color { ColorAnimation { duration: 140 } }
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
                        Rectangle { implicitWidth: 1; implicitHeight: 12; radius: 0.5; color: "#1cffffff" }

                        // [B] Network Indicator
                        Rectangle {
                            id: netItem
                            implicitWidth: netRow.implicitWidth + 12
                            implicitHeight: 24
                            radius: 12
                            color: barWindow.networkOpen ? Theme.accentDim : (netArea.containsMouse ? Theme.bgHover : "transparent")
                            scale: netArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            RowLayout {
                                id: netRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: barWindow.netType === "WIFI" ? "󰤨" : (barWindow.netType === "NONE" ? "󰤮" : "󰈀")
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: barWindow.netType === "NONE" ? Theme.statusCrit : ((barWindow.networkOpen || netArea.containsMouse) ? Theme.accent : Theme.textSecondary)
                                    Behavior on color { ColorAnimation { duration: 140 } }
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
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                        }

                        // [C] Smart Microphone Control
                        Rectangle {
                            id: micItem
                            visible: systemCapsule.defaultSource !== null
                            implicitWidth: micRow.implicitWidth + 12
                            implicitHeight: 24
                            radius: 12
                            color: micArea.containsMouse ? Theme.bgHover : "transparent"
                            scale: micArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            RowLayout {
                                id: micRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: systemCapsule.micMuted ? "󰍭" : "󰍬"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    color: systemCapsule.micMuted ? Theme.accent : (micArea.containsMouse ? Theme.accent : Theme.textSecondary)
                                    Behavior on color { ColorAnimation { duration: 140 } }
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
                        Rectangle { implicitWidth: 1; implicitHeight: 12; radius: 0.5; color: "#1cffffff" }

                        // [D] Master Volume Control
                        Rectangle {
                            id: volItem
                            implicitWidth: volRow.implicitWidth + 12
                            implicitHeight: 24
                            radius: 12
                            color: barWindow.audioOpen ? Theme.accentDim : (volArea.containsMouse ? Theme.bgHover : "transparent")
                            scale: volArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            RowLayout {
                                id: volRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: systemCapsule.sinkMuted ? "󰝟" : (systemCapsule.sinkVol <= 0.01 ? "󰕿" : (systemCapsule.sinkVol < 0.5 ? "󰖀" : "󰕾"))
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: (systemCapsule.sinkMuted || systemCapsule.sinkVol > 1.0 || barWindow.audioOpen || volArea.containsMouse) ? Theme.accent : Theme.textSecondary
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                Text {
                                    text: systemCapsule.sinkMuted ? "MUT" : Math.round(systemCapsule.sinkVol * 100) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: (systemCapsule.sinkMuted || systemCapsule.sinkVol > 1.0) ? Theme.accent : Theme.textPrimary
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

                        // [D3] Smart Battery Indicator (Auto-shows only when physical battery is present)
                        Rectangle {
                            visible: barWindow.hasBattery
                            implicitWidth: 1
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                        }

                        Rectangle {
                            id: batItem
                            visible: barWindow.hasBattery
                            implicitWidth: batRow.implicitWidth + 12
                            implicitHeight: 24
                            radius: 12
                            color: batArea.containsMouse ? Theme.bgHover : "transparent"
                            scale: batArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

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
                                    color: barWindow.batPct <= 15 ? Theme.statusCrit : (batArea.containsMouse ? Theme.accent : Theme.textSecondary)
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }

                                Text {
                                    text: barWindow.batPct + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: barWindow.batPct <= 15 ? Theme.statusCrit : Theme.textPrimary
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
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                        }

                        RowLayout {
                            visible: trayRepeater.count > 0
                            spacing: 2

                            Rectangle {
                                implicitWidth: 22
                                implicitHeight: 24
                                radius: 12
                                color: trayToggleArea.containsMouse ? Theme.bgHover : "transparent"
                                scale: trayToggleArea.pressed ? 0.94 : 1.0
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: barWindow.trayExpanded ? "❯" : "❮"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: trayToggleArea.containsMouse ? Theme.accent : Theme.textMuted
                                    Behavior on color { ColorAnimation { duration: 140 } }
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
                                implicitHeight: 24

                                Behavior on implicitWidth {
                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }

                                RowLayout {
                                    id: trayItemsRow
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Repeater {
                                        id: trayRepeater
                                        model: SystemTray.items

                                        Rectangle {
                                            id: trayIconBtn
                                            required property var modelData
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 12
                                            color: trayIconArea.containsMouse ? Theme.bgHover : "transparent"
                                            scale: trayIconArea.pressed ? 0.94 : 1.0
                                            Behavior on color { ColorAnimation { duration: 140 } }
                                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

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

                // [F] Unified Action Dock Capsule (Notifications | Control Center | Power)
                // Concentric inner pills (28x24, r=12 inside r=15), calm monochrome at rest
                Rectangle {
                    id: actionDockCapsule
                    implicitWidth: actionDockRow.implicitWidth + 6
                    implicitHeight: 30
                    radius: 15
                    color: Theme.bgCapsule
                    border.color: (barWindow.notifCenterOpen || barWindow.controlCenterOpen || barWindow.powerMenuOpen)
                        ? Theme.borderAccent
                        : Theme.borderGlass
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: actionDockRow
                        anchors.centerIn: parent
                        spacing: 2

                        // 1. Notification Center Bell (Fixed width + crisp 6px unread micro-dot + Right-Click DND)
                        Rectangle {
                            id: notifBtn
                            readonly property int unread: NotifState.unreadCount
                            implicitWidth: 28
                            implicitHeight: 24
                            radius: 12
                            color: barWindow.notifCenterOpen
                                ? Theme.accentDim
                                : (notifArea.containsMouse ? Theme.bgHover : "transparent")
                            scale: notifArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: barWindow.dndActive ? "󰪑" : "󰂜"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: (barWindow.notifCenterOpen || barWindow.dndActive || notifArea.containsMouse)
                                    ? Theme.accent
                                    : Theme.textPrimary
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            // Subtle iOS/macOS corner unread indicator dot (zero capsule stretching)
                            Rectangle {
                                visible: notifBtn.unread > 0
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 3
                                anchors.rightMargin: 4
                                width: 7
                                height: 7
                                radius: 3.5
                                color: Theme.accent
                                border.color: Theme.bgCapsule
                                border.width: 1.5
                            }

                            MouseArea {
                                id: notifArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        var nextDnd = !barWindow.dndActive;
                                        SysState.guardToggle();
                                        SysState.dndActive = nextDnd;
                                        barWindow.runCtl(["dnd", nextDnd ? "on" : "off"]);
                                    } else {
                                        barWindow.toggleNotifications();
                                    }
                                }
                            }
                        }

                        // 2. Control Center (Crisp QML Vector Sliders with Tactile Hover/Active Motion)
                        Rectangle {
                            id: ctrlBtn
                            readonly property bool isLit: barWindow.controlCenterOpen || ctrlArea.containsMouse
                            implicitWidth: 28
                            implicitHeight: 24
                            radius: 12
                            color: barWindow.controlCenterOpen
                                ? Theme.accentDim
                                : (ctrlArea.containsMouse ? Theme.bgHover : "transparent")
                            scale: ctrlArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Item {
                                anchors.centerIn: parent
                                width: 13
                                height: 11

                                // Top slider track
                                Rectangle {
                                    x: 0; y: 2
                                    width: 13; height: 1.5
                                    radius: 0.75
                                    color: ctrlBtn.isLit ? Theme.accent : Theme.textSecondary
                                    opacity: 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                                // Top slider knob
                                Rectangle {
                                    x: ctrlBtn.isLit ? 5.5 : 7.5
                                    y: 0.25
                                    width: 5; height: 5
                                    radius: 2.5
                                    color: Theme.bgCapsule
                                    border.color: ctrlBtn.isLit ? Theme.accent : Theme.textPrimary
                                    border.width: 1.5
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }
                                }

                                // Bottom slider track
                                Rectangle {
                                    x: 0; y: 7.5
                                    width: 13; height: 1.5
                                    radius: 0.75
                                    color: ctrlBtn.isLit ? Theme.accent : Theme.textSecondary
                                    opacity: 0.75
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                                // Bottom slider knob
                                Rectangle {
                                    x: ctrlBtn.isLit ? 2.5 : 0.5
                                    y: 5.75
                                    width: 5; height: 5
                                    radius: 2.5
                                    color: Theme.bgCapsule
                                    border.color: ctrlBtn.isLit ? Theme.accent : Theme.textPrimary
                                    border.width: 1.5
                                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation { duration: 140 } }
                                }
                            }

                            MouseArea {
                                id: ctrlArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: barWindow.toggleControl()
                            }
                        }

                        // Subtle micro-divider separating panels from power/session
                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 12
                            radius: 0.5
                            color: "#1cffffff"
                            Layout.leftMargin: 1
                            Layout.rightMargin: 1
                        }

                        // 3. Power / Session Action Pill (Clean transparent at rest; soft crimson on Hover/Open)
                        Rectangle {
                            id: pwrBtn
                            readonly property bool isLit: barWindow.powerMenuOpen || pwrArea.containsMouse
                            implicitWidth: 28
                            implicitHeight: 24
                            radius: 12
                            color: pwrBtn.isLit
                                ? Qt.rgba(Theme.statusCrit.r, Theme.statusCrit.g, Theme.statusCrit.b, 0.20)
                                : "transparent"
                            scale: pwrArea.pressed ? 0.94 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰐥"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: pwrBtn.isLit ? Theme.statusCrit : Theme.textPrimary
                                Behavior on color { ColorAnimation { duration: 140 } }
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
        }
    }
