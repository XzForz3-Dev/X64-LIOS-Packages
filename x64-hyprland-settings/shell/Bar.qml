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

    // Track PipeWire default audio devices so Quickshell activates volume & mute telemetry
    PwObjectTracker {
        objects: {
            var list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
            return list;
        }
    }

    // Background Surface with Cyberpunk Glass & Subtle Crimson Accent (Edge to Edge)
    Rectangle {
        id: barBackground
        anchors.fill: parent
        radius: 0
        color: Theme.bgGlass

        // Bottom 1px Border Separator
        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: Theme.borderGlass
        }

        // Bottom Subtle Crimson Neon Glow Line
        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                leftMargin: 40
                rightMargin: 40
            }
            height: 1
            color: Theme.accentGlow
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 6

            // =============================================================
            // LEFT SECTION: X64 BRAND + WORKSPACES + ACTIVE TITLE
            // =============================================================

            // X64 Launcher Trigger (Click: Menu, Right Click: Terminal)
            Rectangle {
                id: brandBtn
                implicitWidth: 58
                implicitHeight: 24
                radius: Theme.radiusSm
                color: brandArea.containsMouse ? Theme.accentDim : Theme.bgCard
                border.color: brandArea.containsMouse ? Theme.accent : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: brandArea.containsMouse ? Theme.textPrimary : Theme.accent
                    }

                    Text {
                        text: "X64"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.bold: true
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
                            Hyprland.dispatch("exec kitty");
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderSubtle
            }

            // Hyprland Workspaces (Dynamic, animated pills + Wheel Navigation)
            RowLayout {
                id: workspacesLayout
                spacing: 3

                function workspaceById(wsId) {
                    if (!Hyprland.workspaces || !Hyprland.workspaces.values) return null;
                    for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                        if (Hyprland.workspaces.values[i].id === wsId) {
                            return Hyprland.workspaces.values[i];
                        }
                    }
                    return null;
                }

                Repeater {
                    model: [1, 2, 3, 4, 5, 6, 7]

                    Rectangle {
                        id: wsItem
                        required property int modelData
                        readonly property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                        readonly property var wsObj: workspacesLayout.workspaceById(modelData)
                        readonly property bool isOccupied: wsObj && wsObj.toplevels && wsObj.toplevels.values && wsObj.toplevels.values.length > 0

                        implicitWidth: isFocused ? 28 : 22
                        implicitHeight: 22
                        radius: Theme.radiusSm

                        color: isFocused ? Theme.accent : (isOccupied ? Theme.bgCard : (wsArea.containsMouse ? Theme.bgHover : "transparent"))
                        border.color: isFocused ? Theme.accentLight : (isOccupied ? Theme.borderSubtle : "transparent")
                        border.width: 1

                        Behavior on implicitWidth {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: String(wsItem.modelData)
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: wsItem.isFocused || wsItem.isOccupied
                            color: wsItem.isFocused ? "#ffffff" : (wsItem.isOccupied ? Theme.textPrimary : (wsArea.containsMouse ? Theme.textSecondary : Theme.textMuted))
                            opacity: wsItem.isFocused || wsItem.isOccupied ? 1.0 : (wsArea.containsMouse ? 0.9 : 0.45)
                        }

                        MouseArea {
                            id: wsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + wsItem.modelData)
                            onWheel: (wheel) => {
                                if (wheel.angleDelta.y > 0) {
                                    Hyprland.dispatch("workspace e-1");
                                } else {
                                    Hyprland.dispatch("workspace e+1");
                                }
                            }
                        }
                    }
                }
            }

            // Active Window Title Pill (via Wayland ToplevelManager + Click to Close)
            Item {
                id: activeTitleBox
                implicitWidth: Math.min(240, activeTitleContent.implicitWidth)
                implicitHeight: 24
                Layout.maximumWidth: 240
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: 24
                readonly property var activeTop: ToplevelManager.activeToplevel
                readonly property string winTitle: activeTop ? (activeTop.title || activeTop.appId || "") : ""
                visible: winTitle !== ""

                RowLayout {
                    id: activeTitleContent
                    anchors.fill: parent
                    spacing: 5

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 14
                        color: Theme.borderSubtle
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: ""
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.accent
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        id: activeTitleText
                        text: activeTitleBox.winTitle
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: activeTitleArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: activeTitleArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (!activeTitleBox.activeTop) return;
                        if (mouse.button === Qt.MiddleButton || mouse.button === Qt.RightButton) {
                            activeTitleBox.activeTop.close();
                        } else {
                            activeTitleBox.activeTop.activate();
                        }
                    }
                }
            }

            // Spacer pushing Center and Right
            Item {
                Layout.fillWidth: true
            }

            // =============================================================
            // CENTER SECTION: CLOCK & DATE + NOW-PLAYING MPRIS
            // =============================================================

            // MPRIS Media Player Widget (Visible only when music is active)
            RowLayout {
                id: mprisBox
                readonly property var players: Mpris.players ? Mpris.players.values : []
                readonly property var activePlayer: {
                    for (var i = 0; i < players.length; i++) {
                        if (players[i].isPlaying) return players[i];
                    }
                    return players.length > 0 ? players[0] : null;
                }
                readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.trackArtist !== "")
                visible: hasMedia

                Rectangle {
                    implicitHeight: 24
                    implicitWidth: Math.min(220, mprisContent.implicitWidth + 12)
                    radius: Theme.radiusSm
                    color: mprisArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        id: mprisContent
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: (mprisBox.activePlayer && mprisBox.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.accent
                        }

                        Text {
                            text: {
                                if (!mprisBox.activePlayer) return "";
                                var t = mprisBox.activePlayer.trackTitle || "";
                                var a = mprisBox.activePlayer.trackArtist || "";
                                return a !== "" ? (t + " • " + a) : t;
                            }
                            font.family: Theme.fontSans
                            font.pixelSize: 10
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
                            if (!mprisBox.activePlayer) return;
                            if (mouse.button === Qt.LeftButton) {
                                mprisBox.activePlayer.playPause();
                            } else if (mouse.button === Qt.RightButton) {
                                mprisBox.activePlayer.next();
                            }
                        }
                        onWheel: (wheel) => {
                            if (!mprisBox.activePlayer) return;
                            if (wheel.angleDelta.y > 0) mprisBox.activePlayer.previous();
                            else mprisBox.activePlayer.next();
                        }
                    }
                }
            }

            // Digital Clock & Date Button
            Rectangle {
                id: clockBox
                implicitHeight: 24
                implicitWidth: clockLayout.implicitWidth + 14
                radius: Theme.radiusSm
                color: clockArea.containsMouse ? Theme.bgCard : "transparent"
                border.color: clockArea.containsMouse ? Theme.borderSubtle : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: clockLayout
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: timeLabel
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        text: "•"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        color: Theme.accent
                    }

                    Text {
                        id: dateLabel
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: false
                        color: Theme.textSecondary
                    }
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        var now = new Date();
                        var h = String(now.getHours()).padStart(2, "0");
                        var m = String(now.getMinutes()).padStart(2, "0");
                        timeLabel.text = h + ":" + m;

                        var days = ["DOM", "LUN", "MAR", "MIÉ", "JUE", "VIE", "SÁB"];
                        var months = ["ENE", "FEB", "MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV", "DIC"];
                        dateLabel.text = days[now.getDay()] + " " + String(now.getDate()).padStart(2, "0") + " " + months[now.getMonth()];
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

            // Spacer pushing Right
            Item {
                Layout.fillWidth: true
            }

            // =============================================================
            // RIGHT SECTION: TELEMETRY + KEYBOARD + NET + AUDIO + TRAY
            // =============================================================

            // Mini Telemetry (CPU & RAM)
            Rectangle {
                id: telemetryBox
                implicitHeight: 22
                implicitWidth: telemetryLayout.implicitWidth + 12
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                RowLayout {
                    id: telemetryLayout
                    anchors.centerIn: parent
                    spacing: 8

                    // CPU Metric
                    RowLayout {
                        spacing: 3
                        Text {
                            text: "󰻠"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: cpuText.isHigh ? Theme.accent : Theme.textMuted
                        }
                        Text {
                            id: cpuText
                            property bool isHigh: false
                            text: "0%"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: isHigh ? Theme.accent : Theme.textSecondary
                        }
                    }

                    // RAM Metric
                    RowLayout {
                        spacing: 3
                        Text {
                            text: "󰍛"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                        Text {
                            id: ramText
                            text: "0G"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.textSecondary
                        }
                    }
                }

                // Shell Process to poll CPU and RAM every 2 seconds
                Process {
                    id: teleProc
                    command: [
                        "bash", "-c",
                        "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf \"%.1fG\\n\", (t-a)/1024/1024}' /proc/meminfo; awk '{printf \"%.0f%%\\n\", $1*25}' /proc/loadavg"
                    ]
                    stdout: StdioCollector {
                        id: teleCollector
                        waitForEnd: true
                        onStreamFinished: {
                            var t = teleCollector.text;
                            if (!t) return;
                            var lines = t.trim().split("\n");
                            if (lines.length >= 1) {
                                ramText.text = lines[0].trim();
                            }
                            if (lines.length >= 2) {
                                var cpuVal = parseInt(lines[1]) || 0;
                                cpuText.text = cpuVal + "%";
                                cpuText.isHigh = cpuVal > 80;
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
                        if (teleProc.running) return;
                        teleProc.running = true;
                    }
                }
            }

            // Keyboard Layout Selector (US / ES)
            Rectangle {
                id: kbdBox
                property string activeLayout: "US"

                implicitWidth: kbdLayout.implicitWidth + 8
                implicitHeight: 22
                radius: Theme.radiusSm
                color: kbdArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                RowLayout {
                    id: kbdLayout
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        text: "󰌌"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.accent
                    }

                    Text {
                        text: kbdBox.activeLayout
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                Process {
                    id: kbdProc
                    command: [
                        "bash", "-c",
                        "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' 2>/dev/null | head -n1"
                    ]
                    stdout: StdioCollector {
                        id: kbdCollector
                        waitForEnd: true
                        onStreamFinished: {
                            if (!kbdCollector.text) return;
                            var text = kbdCollector.text.trim().toLowerCase();
                            if (text.indexOf("spanish") !== -1 || text.indexOf("es") !== -1) {
                                kbdBox.activeLayout = "ES";
                            } else {
                                kbdBox.activeLayout = "US";
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
                        if (!kbdProc.running) kbdProc.running = true;
                    }
                }

                Connections {
                    target: Hyprland
                    function onRawEvent(event) {
                        if (!event || !event.name) return;
                        var name = String(event.name);
                        if (name.indexOf("activelayout") !== -1 || name === "configreloaded") {
                            if (!kbdProc.running) kbdProc.running = true;
                        }
                    }
                }

                MouseArea {
                    id: kbdArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("switchxkblayout all next");
                        kbdTimer.restart();
                    }
                }

                Timer {
                    id: kbdTimer
                    interval: 300
                    onTriggered: if (!kbdProc.running) kbdProc.running = true;
                }
            }

            // Network Connectivity Indicator (Wi-Fi / Ethernet)
            Rectangle {
                id: netBox
                property string netType: "eth"
                property string netName: ""

                implicitWidth: netLayout.implicitWidth + 8
                implicitHeight: 22
                radius: Theme.radiusSm
                color: netArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                RowLayout {
                    id: netLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: netBox.netType === "wifi" ? "󰤨" : (netBox.netType === "eth" ? "󰈀" : "󰤭")
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: netBox.netType === "none" ? Theme.textMuted : Theme.accent
                    }

                    Text {
                        text: netBox.netType === "wifi" ? (netBox.netName || "Wi-Fi") : (netBox.netType === "eth" ? "LAN" : "OFF")
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.textSecondary
                    }
                }

                Process {
                    id: netProc
                    command: [
                        "bash", "-c",
                        "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5}'); if [[ -z \"$iface\" ]]; then echo 'none'; elif [[ \"$iface\" =~ ^wl ]]; then echo 'wifi'; iw dev \"$iface\" link 2>/dev/null | awk -F': ' '/SSID/ {print $2}'; else echo 'eth'; fi"
                    ]
                    stdout: StdioCollector {
                        id: netCollector
                        waitForEnd: true
                        onStreamFinished: {
                            if (!netCollector.text) return;
                            var lines = netCollector.text.trim().split("\n");
                            if (lines.length >= 1) {
                                netBox.netType = lines[0].trim();
                            }
                            if (lines.length >= 2) {
                                netBox.netName = lines[1].trim();
                            }
                        }
                    }
                }

                Timer {
                    interval: 6000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        if (!netProc.running) netProc.running = true;
                    }
                }

                MouseArea {
                    id: netArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("exec nm-connection-editor")
                }
            }

            // Microphone Volume / Mute Indicator
            Rectangle {
                id: micBox
                readonly property var source: Pipewire.defaultAudioSource
                readonly property real micVol: (source && source.audio) ? source.audio.volume : 0.0
                readonly property bool micMuted: (source && source.audio) ? source.audio.muted : true

                implicitWidth: micLayout.implicitWidth + 8
                implicitHeight: 22
                radius: Theme.radiusSm
                color: micArea.containsMouse ? Theme.bgHover : (micBox.micMuted ? Theme.bgCard : Theme.accentDim)
                border.color: micBox.micMuted ? Theme.borderSubtle : Theme.accent
                border.width: 1

                RowLayout {
                    id: micLayout
                    anchors.centerIn: parent
                    spacing: 3

                    Text {
                        text: micBox.micMuted ? "󰍭" : "󰍬"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: micBox.micMuted ? Theme.textMuted : Theme.accent
                    }

                    Text {
                        text: micBox.micMuted ? "MUT" : Math.round(micBox.micVol * 100) + "%"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: micBox.micMuted ? Theme.textMuted : Theme.textPrimary
                    }
                }

                MouseArea {
                    id: micArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (micBox.source && micBox.source.audio) {
                            micBox.source.audio.muted = !micBox.source.audio.muted;
                        }
                    }
                    onWheel: (wheel) => {
                        if (micBox.source && micBox.source.audio) {
                            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            micBox.source.audio.volume = Math.max(0.0, Math.min(1.0, micBox.source.audio.volume + delta));
                        }
                    }
                }
            }

            // Audio Output Module (PipeWire)
            Rectangle {
                id: audioBox
                readonly property var sink: Pipewire.defaultAudioSink
                readonly property real vol: (sink && sink.audio) ? sink.audio.volume : 0.0
                readonly property bool muted: (sink && sink.audio) ? sink.audio.muted : false

                implicitWidth: audioLayout.implicitWidth + 10
                implicitHeight: 24
                radius: Theme.radiusSm
                color: audioArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: audioArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: audioLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: audioBox.muted ? "󰝟" : (audioBox.vol <= 0.01 ? "󰕿" : (audioBox.vol < 0.5 ? "󰖀" : "󰕾"))
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: audioBox.muted ? Theme.accent : (audioBox.vol > 1.0 ? Theme.accentHover : Theme.textPrimary)
                    }

                    Text {
                        text: audioBox.muted ? "MUTE" : Math.round(audioBox.vol * 100) + "%"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: audioBox.muted ? Theme.accent : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: audioArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (audioBox.sink && audioBox.sink.audio) {
                                audioBox.sink.audio.muted = !audioBox.sink.audio.muted;
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            barWindow.toggleControl();
                        }
                    }
                    onWheel: (wheel) => {
                        if (audioBox.sink && audioBox.sink.audio) {
                            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            audioBox.sink.audio.volume = Math.max(0.0, Math.min(1.5, audioBox.sink.audio.volume + delta));
                        }
                    }
                }
            }

            // System Tray with Collapsible Drawer (Chevron Toggle)
            RowLayout {
                spacing: 2

                // Chevron Drawer Toggle
                Rectangle {
                    implicitWidth: 16
                    implicitHeight: 22
                    radius: Theme.radiusSm
                    color: trayToggleArea.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: barWindow.trayExpanded ? "❯" : "❮"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }

                    MouseArea {
                        id: trayToggleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWindow.trayExpanded = !barWindow.trayExpanded
                    }
                }

                // Tray items container with animated width
                Item {
                    id: trayContainer
                    clip: true
                    implicitWidth: barWindow.trayExpanded ? trayRow.implicitWidth : 0
                    implicitHeight: 22

                    Behavior on implicitWidth {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    RowLayout {
                        id: trayRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Repeater {
                            model: SystemTray.items

                            Rectangle {
                                id: trayBtn
                                required property var modelData
                                implicitWidth: 20
                                implicitHeight: 20
                                radius: Theme.radiusSm
                                color: trayArea.containsMouse ? Theme.bgHover : "transparent"

                                Image {
                                    anchors.centerIn: parent
                                    width: 14
                                    height: 14
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    source: trayBtn.modelData.icon || ""
                                    fillMode: Image.PreserveAspectFit
                                }

                                MouseArea {
                                    id: trayArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.LeftButton) {
                                            trayBtn.modelData.activate();
                                        } else if (mouse.button === Qt.RightButton && trayBtn.modelData.hasMenu) {
                                            trayBtn.modelData.secondaryActivate();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 14
                color: Theme.borderSubtle
            }

            // Control Center Trigger
            Rectangle {
                id: controlBtn
                implicitWidth: 26
                implicitHeight: 24
                radius: Theme.radiusSm
                color: controlArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: controlArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰍜"
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    color: controlArea.containsMouse ? Theme.accent : Theme.textPrimary
                }

                MouseArea {
                    id: controlArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleControl()
                }
            }

            // Power Session Trigger (Fast Exit)
            Rectangle {
                id: powerBtn
                implicitWidth: 26
                implicitHeight: 24
                radius: Theme.radiusSm
                color: powerArea.containsMouse ? Theme.accent : Theme.bgCard
                border.color: powerArea.containsMouse ? Theme.accentLight : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: powerArea.containsMouse ? Theme.textPrimary : Theme.accent
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.togglePower()
                }
            }
        }
    }
}
