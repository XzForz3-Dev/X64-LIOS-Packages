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

    signal toggleLauncher()
    signal toggleCalendar()
    signal toggleControl()
    signal togglePower()

    property bool trayExpanded: true

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

    implicitHeight: 32
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 32
    WlrLayershell.namespace: "quickshell"

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
    // SYSTEM TELEMETRY & BACKGROUND MONITORS
    // =========================================================================

    property int cpuUsage: 0
    property string ramUsage: "0.0"

    Process {
        id: teleProcess
        command: ["sh", "-c", "awk '{printf \"%.0f\", $1*25}' /proc/loadavg 2>/dev/null || echo 0; awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{if(t>0) printf \"%.1f\", (t-a)/1048576; else print 0}' /proc/meminfo 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            id: teleCollector
            onStreamFinished: {
                if (!teleCollector.text) return;
                var lines = teleCollector.text.trim().split("\n");
                if (lines.length >= 2) {
                    barWindow.cpuUsage = parseInt(lines[0]) || 0;
                    barWindow.ramUsage = lines[1] || "0";
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (teleProcess.running) return;
            teleProcess.running = true;
        }
    }

    // Active Keyboard Layout Detector
    property string kbLayout: "US"
    Process {
        id: kbProcess
        command: ["sh", "-c", "export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr/ 2>/dev/null | head -n1); hyprctl devices -j 2>/dev/null | jq -r '.keyboards[] | select(.main == true) | .active_keymap' 2>/dev/null | head -n1 || echo 'English'"]
        stdout: StdioCollector {
            id: kbCollector
            onStreamFinished: {
                if (!kbCollector.text) return;
                var text = kbCollector.text.trim().toLowerCase();
                if (text.indexOf("span") !== -1 || text.indexOf("es") !== -1) {
                    barWindow.kbLayout = "ES";
                } else {
                    barWindow.kbLayout = "US";
                }
            }
        }
    }

    // Network Connectivity Detector
    property string netType: "LAN"
    property string netName: "Cable"
    Process {
        id: netProcess
        command: ["sh", "-c", "route=$(ip route get 1.1.1.1 2>/dev/null | head -n1); if [ -n \"$route\" ]; then dev=$(echo \"$route\" | awk '{print $5}'); if [ -d \"/sys/class/net/$dev/wireless\" ]; then ssid=$(iw dev \"$dev\" link 2>/dev/null | awk -F': ' '/SSID/{print $2}'); echo \"WIFI|${ssid:-Wi-Fi}\"; else echo \"LAN|Cable\"; fi; else echo \"NONE|Desconectado\"; fi"]
        stdout: StdioCollector {
            id: netCollector
            onStreamFinished: {
                if (!netCollector.text) return;
                var parts = netCollector.text.trim().split("|");
                barWindow.netType = parts[0] || "LAN";
                barWindow.netName = parts[1] || "Cable";
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!kbProcess.running) kbProcess.running = true;
            if (!netProcess.running) netProcess.running = true;
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!event || !event.name) return;
            var name = String(event.name);
            if (name.indexOf("activelayout") !== -1 || name === "configreloaded") {
                if (!kbProcess.running) kbProcess.running = true;
            }
        }
    }

    // Real-time Clock Strings
    property string timeStr: "00:00"
    property string dateStr: "LUN 01 ENE"

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date();
            var h = String(now.getHours()).padStart(2, '0');
            var m = String(now.getMinutes()).padStart(2, '0');
            barWindow.timeStr = h + ":" + m;

            var days = ["DOM", "LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB"];
            var months = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"];
            var dName = days[now.getDay()];
            var dNum = String(now.getDate()).padStart(2, '0');
            var mName = months[now.getMonth()];
            barWindow.dateStr = dName + " " + dNum + " " + mName;
        }
    }

    // =========================================================================
    // BAR BACKGROUND SURFACE (AERODYNAMIC SATIN OBSIDIAN GLASS)
    // =========================================================================

    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: "#0a0b10e6" // Deep obsidian OLED glass

        // Top 1px specular highlight line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#18ffffff"
        }

        // Bottom 1px razor-sharp crimson neon glow line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: "#44ff2b2b"
        }

        // =====================================================================
        // MASTER THREE-SECTION FLEXIBLE BAR LAYOUT
        // =====================================================================

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // -----------------------------------------------------------------
            // 1. LEFT CAPSULE: SOBERANA NAVEGACIÓN (Brand + Workspaces + Title)
            // -----------------------------------------------------------------
            Rectangle {
                id: navCapsule
                implicitHeight: 24
                implicitWidth: navRow.implicitWidth + 8
                radius: 12
                color: "#12131add"
                border.color: "#1affffff"
                border.width: 1

                RowLayout {
                    id: navRow
                    anchors.centerIn: parent
                    spacing: 6

                    // Brand Icon & Badge (Launcher on Left Click, Kitty on Right Click)
                    Rectangle {
                        id: brandPill
                        implicitWidth: brandRow.implicitWidth + 8
                        implicitHeight: 20
                        radius: 10
                        color: brandArea.containsMouse ? "#22ff2b2b" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: brandRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰣇"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.accent
                            }

                            Text {
                                text: "X64"
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: Theme.textPrimary
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
                                    Hyprland.dispatch('hl.dsp.exec_cmd("kitty")');
                                }
                            }
                        }
                    }

                    // Subtle Hairline Divider
                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 12
                        color: "#1affffff"
                    }

                    // Morphic Geometric Workspaces (Reactive Pills & Dots)
                    Item {
                        id: wsContainer
                        implicitWidth: wsLayout.implicitWidth
                        implicitHeight: 20

                        RowLayout {
                            id: wsLayout
                            anchors.fill: parent
                            spacing: 4

                            Repeater {
                                model: [1, 2, 3, 4, 5, 6, 7]

                                Item {
                                    id: wsItem
                                    required property int modelData

                                    readonly property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                                    readonly property bool isOccupied: {
                                        if (!Hyprland.workspaces) return false;
                                        var list = Hyprland.workspaces.values;
                                        for (var i = 0; i < list.length; i++) {
                                            if (list[i].id === modelData) return true;
                                        }
                                        return false;
                                    }

                                    implicitWidth: wsIndicator.width + 4
                                    implicitHeight: 20

                                    Rectangle {
                                        id: wsIndicator
                                        anchors.centerIn: parent

                                        // Dynamic morphic pill: elongated glowing bar for active, dot for occupied/empty
                                        width: {
                                            if (wsItem.isFocused) return wsArea.containsMouse ? 20 : 16;
                                            if (wsArea.containsMouse) return 8;
                                            return wsItem.isOccupied ? 5 : 4;
                                        }
                                        height: wsItem.isFocused ? 5 : (wsItem.isOccupied ? 5 : 4)
                                        radius: height / 2

                                        color: {
                                            if (wsItem.isFocused) return Theme.accent;
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
                                        onClicked: Hyprland.dispatch("workspace " + wsItem.modelData)
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
                                    Hyprland.dispatch("workspace e-1");
                                } else if (wheel.angleDelta.y < 0) {
                                    Hyprland.dispatch("workspace e+1");
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
                        color: "#1affffff"
                        visible: navRow.winTitle !== ""
                    }

                    Item {
                        id: titleBox
                        visible: navRow.winTitle !== ""
                        implicitWidth: Math.min(160, titleRow.implicitWidth)
                        implicitHeight: 20
                        Layout.maximumWidth: 160

                        RowLayout {
                            id: titleRow
                            anchors.fill: parent
                            spacing: 4

                            Text {
                                text: ""
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.accent
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: navRow.winTitle
                                font.family: Theme.fontSans
                                font.pixelSize: 10
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

            // Left Expanding Spacer
            Item { Layout.fillWidth: true }

            // -----------------------------------------------------------------
            // 2. CENTER SECTION: NOW-PLAYING MPRIS + CHRONOS MASTER CAPSULE
            // -----------------------------------------------------------------
            RowLayout {
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

                    implicitHeight: 24
                    implicitWidth: Math.min(200, mprisRow.implicitWidth + 12)
                    radius: 12
                    color: mprisArea.containsMouse ? "#1c1d26dd" : "#12131add"
                    border.color: mprisArea.containsMouse ? Theme.accent : "#1affffff"
                    border.width: 1

                    RowLayout {
                        id: mprisRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: (mprisCapsule.activePlayer && mprisCapsule.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
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
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.maximumWidth: 150
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
                    implicitHeight: 24
                    implicitWidth: clockRow.implicitWidth + 16
                    radius: 12
                    color: clockArea.containsMouse ? "#1e1f2bdd" : "#12131add"
                    border.color: clockArea.containsMouse ? Theme.accent : "#1affffff"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰸗"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: clockArea.containsMouse ? Theme.accentLight : Theme.accent
                        }

                        Text {
                            text: barWindow.timeStr
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        Rectangle {
                            implicitWidth: 3
                            implicitHeight: 3
                            radius: 1.5
                            color: Theme.accent
                        }

                        Text {
                            text: barWindow.dateStr
                            font.family: Theme.fontSans
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            font.letterSpacing: 0.5
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
            }

            // Right Expanding Spacer
            Item { Layout.fillWidth: true }

            // -----------------------------------------------------------------
            // 3. RIGHT SECTION: TWO STREAMLINED LUXURY ISLANDS
            // -----------------------------------------------------------------
            RowLayout {
                spacing: 6

                // Island 3A: Hardware Telemetry Capsule (CPU% & RAM)
                Rectangle {
                    id: telemetryCapsule
                    implicitHeight: 24
                    implicitWidth: telemetryRow.implicitWidth + 12
                    radius: 12
                    color: teleArea.containsMouse ? "#1c1d26dd" : "#12131add"
                    border.color: teleArea.containsMouse ? Theme.borderAccent : "#1affffff"
                    border.width: 1

                    RowLayout {
                        id: telemetryRow
                        anchors.centerIn: parent
                        spacing: 5

                        // CPU
                        Text {
                            text: "󰻠"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.accent
                        }

                        Text {
                            text: barWindow.cpuUsage + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        // Divider
                        Rectangle {
                            implicitWidth: 1
                            implicitHeight: 10
                            color: "#1affffff"
                        }

                        // RAM
                        Text {
                            text: "󰍛"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: "#00e5ff"
                        }

                        Text {
                            text: barWindow.ramUsage + "G"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: teleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch('hl.dsp.exec_cmd("kitty -e btop")')
                    }
                }

                // Island 3B: Unified System Status & Control Suite (One Continuous Capsule)
                Rectangle {
                    id: systemCapsule
                    implicitHeight: 24
                    implicitWidth: systemRow.implicitWidth + 10
                    radius: 12
                    color: "#12131add"
                    border.color: "#1affffff"
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
                        spacing: 5

                        // [A] Keyboard Layout Indicator (Click switches layout)
                        Rectangle {
                            id: kbItem
                            implicitWidth: kbRow.implicitWidth + 4
                            implicitHeight: 18
                            radius: 9
                            color: kbArea.containsMouse ? "#20ffffff" : "transparent"

                            RowLayout {
                                id: kbRow
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    text: "󰌌"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: "#888899"
                                }

                                Text {
                                    text: barWindow.kbLayout
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: kbArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("switchxkblayout all next")
                            }
                        }

                        // Divider
                        Rectangle { implicitWidth: 1; implicitHeight: 10; color: "#1affffff" }

                        // [B] Network Indicator (Click opens nm-connection-editor)
                        Rectangle {
                            id: netItem
                            implicitWidth: netRow.implicitWidth + 4
                            implicitHeight: 18
                            radius: 9
                            color: netArea.containsMouse ? "#20ffffff" : "transparent"

                            RowLayout {
                                id: netRow
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    text: barWindow.netType === "WIFI" ? "󰤨" : "󰈀"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: barWindow.netType === "NONE" ? "#ff4d4d" : Theme.textPrimary
                                }

                                Text {
                                    text: barWindow.netType === "WIFI" ? barWindow.netName : "LAN"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                    color: Theme.textSecondary
                                    Layout.maximumWidth: 60
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: netArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch('hl.dsp.exec_cmd("nm-connection-editor")')
                            }
                        }

                        // Divider
                        Rectangle { implicitWidth: 1; implicitHeight: 10; color: "#1affffff" }

                        // [C] Microphone Control (Click mutes, Wheel changes gain)
                        Rectangle {
                            id: micItem
                            implicitWidth: micRow.implicitWidth + 4
                            implicitHeight: 18
                            radius: 9
                            color: micArea.containsMouse ? "#20ffffff" : "transparent"

                            RowLayout {
                                id: micRow
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    text: systemCapsule.micMuted ? "󰍭" : "󰍬"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: systemCapsule.micMuted ? Theme.textMuted : Theme.accent
                                }

                                Text {
                                    text: systemCapsule.micMuted ? "MUT" : Math.round(systemCapsule.micVol * 100) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: systemCapsule.micMuted ? Theme.textMuted : Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: micArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (systemCapsule.defaultSource && systemCapsule.defaultSource.audio) {
                                        systemCapsule.defaultSource.audio.muted = !systemCapsule.defaultSource.audio.muted;
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
                        Rectangle { implicitWidth: 1; implicitHeight: 10; color: "#1affffff" }

                        // [D] Master Volume Control (Click mutes, Wheel changes volume, Right click opens Control Center)
                        Rectangle {
                            id: volItem
                            implicitWidth: volRow.implicitWidth + 4
                            implicitHeight: 18
                            radius: 9
                            color: volArea.containsMouse ? "#20ffffff" : "transparent"

                            RowLayout {
                                id: volRow
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    text: systemCapsule.sinkMuted ? "󰝟" : (systemCapsule.sinkVol <= 0.01 ? "󰕿" : (systemCapsule.sinkVol < 0.5 ? "󰖀" : "󰕾"))
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: systemCapsule.sinkMuted ? Theme.accent : Theme.textPrimary
                                }

                                Text {
                                    text: systemCapsule.sinkMuted ? "MUT" : Math.round(systemCapsule.sinkVol * 100) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: systemCapsule.sinkMuted ? Theme.accent : Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: volArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.LeftButton) {
                                        if (systemCapsule.defaultSink && systemCapsule.defaultSink.audio) {
                                            systemCapsule.defaultSink.audio.muted = !systemCapsule.defaultSink.audio.muted;
                                        }
                                    } else if (mouse.button === Qt.RightButton) {
                                        barWindow.toggleControl();
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
                        Rectangle { implicitWidth: 1; implicitHeight: 10; color: "#1affffff" }

                        // [E] System Tray Collapsible Drawer (Chevron toggle)
                        RowLayout {
                            spacing: 1

                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 18
                                radius: 7
                                color: trayToggleArea.containsMouse ? "#20ffffff" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: barWindow.trayExpanded ? "❯" : "❮"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: trayToggleArea.containsMouse ? Theme.accent : Theme.textMuted
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
                                        model: SystemTray.items

                                        Rectangle {
                                            id: trayIconBtn
                                            required property var modelData
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            radius: 6
                                            color: trayIconArea.containsMouse ? "#25ffffff" : "transparent"

                                            Image {
                                                anchors.centerIn: parent
                                                width: 13
                                                height: 13
                                                sourceSize.width: 13
                                                sourceSize.height: 13
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

                        // Divider
                        Rectangle { implicitWidth: 1; implicitHeight: 10; color: "#1affffff" }

                        // [F] Control Center Trigger Button
                        Rectangle {
                            id: ctrlBtn
                            implicitWidth: 20
                            implicitHeight: 18
                            radius: 9
                            color: ctrlArea.containsMouse ? "#25ffffff" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰍜"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
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

                        // Divider
                        Rectangle { implicitWidth: 1; implicitHeight: 10; color: "#1affffff" }

                        // [G] Power / Fast Exit Trigger Button
                        Rectangle {
                            id: pwrBtn
                            implicitWidth: 20
                            implicitHeight: 18
                            radius: 9
                            color: pwrArea.containsMouse ? Theme.accent : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰐥"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
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
        }
    }
}
