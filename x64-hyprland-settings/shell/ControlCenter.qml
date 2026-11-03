import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Io

PanelWindow {
    id: controlWindow

    signal closeRequested()
    signal lockRequested()
    signal brightnessChangedOsd(int val)

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

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 32
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"

    PwObjectTracker {
        objects: {
            var list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
            return list;
        }
    }

    function runCtl(args) {
        ctlGuardTimer.restart();
        ctlExecProc.command = ["x64-hyprland-ctl"].concat(args);
        ctlExecProc.running = true;
    }

    Timer {
        id: ctlGuardTimer
        interval: 900
        repeat: false
    }

    function refreshAll() {
        displayCard.refreshScale();
        if (!ctlStatusProc.running) ctlStatusProc.running = true;
    }

    Process {
        id: ctlExecProc
        onExited: {
            if (!ctlStatusProc.running) ctlStatusProc.running = true;
        }
    }

    Process {
        id: ctlStatusProc
        command: ["x64-hyprland-ctl", "status"]
        stdout: StdioCollector {
            id: ctlCollector
            onStreamFinished: {
                if (!ctlCollector.text) return;
                try {
                    var d = JSON.parse(ctlCollector.text.trim());
                    if (!ctlGuardTimer.running) {
                        controlWindow.caffeineActive = Boolean(d.caffeine);
                        controlWindow.nightlightActive = Boolean(d.nightlight);
                        controlWindow.dndActive = Boolean(d.dnd);
                        controlWindow.powerProfile = d.powerProfile || "balanced";
                    }
                    controlWindow.isRecording = Boolean(d.recording);
                    controlWindow.recTime = d.recTime || "00:00";
                    controlWindow.hasBattery = Boolean(d.hasBattery);
                    controlWindow.batPct = d.batPct !== undefined ? d.batPct : 100;
                    controlWindow.batStatus = d.batStatus || "AC";
                    if (!brSlider.pressed && d.brightness !== undefined) {
                        controlWindow.brightnessVal = d.brightness;
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1200
        running: controlWindow.visible
        repeat: true
        onTriggered: {
            if (!ctlStatusProc.running) ctlStatusProc.running = true;
        }
    }

    onVisibleChanged: {
        if (visible) {
            controlWindow.refreshAll();
        }
    }

    Component.onCompleted: {
        controlWindow.refreshAll();
    }

    // Outside click dismiss backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: controlWindow.closeRequested()
    }

    // Control Center Card pinned to top right
    Rectangle {
        id: card
        width: 372
        height: Math.min(586, parent.height - 10)
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 4
            rightMargin: 8
        }
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        // Consume inside clicks so clicking empty card padding does not dismiss
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "CENTRO DE CONTROL"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.accent
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰅖"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: Theme.textMuted
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: controlWindow.closeRequested()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            // -----------------------------------------------------------------
            // 1. OMARCHY-STYLE QUICK SYSTEM TOGGLES (Caffeine, Nightlight, DND)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Modo Café (Idle Inhibitor)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: controlWindow.caffeineActive ? Theme.accentDim : (cafArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.caffeineActive ? Theme.accent : (cafArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰅶"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: controlWindow.caffeineActive ? "#ffffff" : Theme.accent
                        }
                        Text {
                            text: "Modo Café"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: controlWindow.caffeineActive
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: cafArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.caffeineActive = !controlWindow.caffeineActive;
                            controlWindow.runCtl(["caffeine", controlWindow.caffeineActive ? "on" : "off"]);
                        }
                    }
                }

                // Luz Nocturna (4200K Filter)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: controlWindow.nightlightActive ? "#55ffaa00" : (nlArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.nightlightActive ? "#ffaa00" : (nlArea.containsMouse ? "#88ffaa00" : Theme.borderSubtle)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰖔"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: controlWindow.nightlightActive ? "#ffffff" : "#ffaa00"
                        }
                        Text {
                            text: "Luz Noche"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: controlWindow.nightlightActive
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: nlArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.nightlightActive = !controlWindow.nightlightActive;
                            controlWindow.runCtl(["nightlight", controlWindow.nightlightActive ? "on" : "off"]);
                        }
                    }
                }

                // Modo No Molestar (DND)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: controlWindow.dndActive ? "#44a855f7" : (dndArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.dndActive ? "#a855f7" : (dndArea.containsMouse ? "#88a855f7" : Theme.borderSubtle)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "󰂛"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: controlWindow.dndActive ? "#ffffff" : "#c084fc"
                        }
                        Text {
                            text: "No Molestar"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: controlWindow.dndActive
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: dndArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.dndActive = !controlWindow.dndActive;
                            controlWindow.runCtl(["dnd", controlWindow.dndActive ? "on" : "off"]);
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 2. SCREEN CAPTURE & LIVE SCREEN RECORDING SUITE
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Capture Region
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: shotRegArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: shotRegArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰆞"; font.family: Theme.fontMono; font.pixelSize: 12; color: Theme.accent }
                        Text { text: "Región"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: shotRegArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.closeRequested();
                            Hyprland.dispatch('hl.dsp.exec_cmd("x64-hyprland-ctl screenshot region")');
                        }
                    }
                }

                // Capture Fullscreen
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: shotFullArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: shotFullArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text { text: "󰄀"; font.family: Theme.fontMono; font.pixelSize: 12; color: Theme.accent }
                        Text { text: "Capturar"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: shotFullArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.closeRequested();
                            Hyprland.dispatch('hl.dsp.exec_cmd("x64-hyprland-ctl screenshot full")');
                        }
                    }
                }

                // Screen Record Toggle
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: controlWindow.isRecording ? Theme.accent : (recBtnArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.isRecording ? Theme.accentLight : (recBtnArea.containsMouse ? Theme.accent : Theme.borderSubtle)
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: controlWindow.isRecording ? "󰓛" : "󰑊"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: controlWindow.isRecording ? "#ffffff" : Theme.accent
                        }
                        Text {
                            text: controlWindow.isRecording ? ("Fin " + controlWindow.recTime) : "Grabar"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: controlWindow.isRecording
                            color: Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: recBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var nextRec = !controlWindow.isRecording;
                            controlWindow.isRecording = nextRec;
                            controlWindow.runCtl(["record", nextRec ? "start" : "stop"]);
                            if (nextRec) {
                                controlWindow.closeRequested();
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. QUICK APP ACTIONS (2x2 Grid)
            // -----------------------------------------------------------------
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 6

                // Kitty Terminal
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: termArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: termArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8
                        Text { text: "󰄛"; font.family: Theme.fontMono; font.pixelSize: 14; color: Theme.accent }
                        Text { text: "Terminal Kitty"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: termArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.exec_cmd("kitty")');
                            controlWindow.closeRequested();
                        }
                    }
                }

                // Dolphin File Manager
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: dolphArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: dolphArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8
                        Text { text: "󰉋"; font.family: Theme.fontMono; font.pixelSize: 14; color: Theme.accent }
                        Text { text: "Archivos"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: dolphArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.exec_cmd("dolphin")');
                            controlWindow.closeRequested();
                        }
                    }
                }

                // X64 Hello
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: helloArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: helloArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8
                        Text { text: "󰍜"; font.family: Theme.fontMono; font.pixelSize: 14; color: Theme.accent }
                        Text { text: "X64 Hello"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: helloArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.exec_cmd("x64-hello")');
                            controlWindow.closeRequested();
                        }
                    }
                }

                // Btop System Monitor
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Theme.radiusSm
                    color: monArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: monArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8
                        Text { text: "󰍛"; font.family: Theme.fontMono; font.pixelSize: 14; color: Theme.accent }
                        Text { text: "Monitor Btop"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: monArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.exec_cmd("kitty -e btop")');
                            controlWindow.closeRequested();
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 4. UNIFIED AUDIO & DISPLAY BRIGHTNESS SLIDERS CARD
            // -----------------------------------------------------------------
            Rectangle {
                id: slidersCard
                Layout.fillWidth: true
                implicitHeight: 110
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                readonly property var sink: Pipewire.defaultAudioSink
                readonly property real vol: sink && sink.audio ? sink.audio.volume : 0.0
                readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    // Master Volume Row
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: slidersCard.isMuted ? "󰝟 Audio Silenciado" : "󰕾 Volumen Principal"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: slidersCard.isMuted ? Theme.accent : Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: slidersCard.isMuted ? "MUTE" : Math.round(slidersCard.vol * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accent
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        implicitHeight: 22
                        from: 0.0
                        to: 1.0
                        value: slidersCard.vol
                        onMoved: {
                            if (slidersCard.sink && slidersCard.sink.audio) {
                                slidersCard.sink.audio.volume = value;
                            }
                        }
                    }

                    // Display Brightness Row
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰃠 Brillo de Pantalla"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: controlWindow.brightnessVal + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: "#ffaa00"
                        }
                    }

                    Slider {
                        id: brSlider
                        Layout.fillWidth: true
                        implicitHeight: 22
                        from: 15
                        to: 100
                        stepSize: 1
                        value: controlWindow.brightnessVal
                        onMoved: {
                            var v = Math.round(value);
                            controlWindow.brightnessVal = v;
                            controlWindow.brightnessChangedOsd(v);
                            brApplyDebounce.restart();
                        }
                    }

                    Timer {
                        id: brApplyDebounce
                        interval: 90
                        repeat: false
                        onTriggered: {
                            controlWindow.runCtl(["brightness", "set", String(controlWindow.brightnessVal)]);
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 5. POWER PROFILES & SMART BATTERY CARD
            // -----------------------------------------------------------------
            Rectangle {
                id: powerProfileCard
                Layout.fillWidth: true
                implicitHeight: 68
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰾅 Perfil de Energía"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: controlWindow.hasBattery ? ("󰁹 " + controlWindow.batPct + "% (" + controlWindow.batStatus + ")") : "󰚥 AC Directo"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: controlWindow.hasBattery && controlWindow.batPct <= 15 ? Theme.accent : Theme.textSecondary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "performance", label: "󰓅 Rendimiento" },
                                { id: "balanced",    label: "󰾅 Equilibrado" },
                                { id: "power-saver", label: "󰌪 Ahorro" }
                            ]

                            Rectangle {
                                id: profBtn
                                Layout.fillWidth: true
                                implicitHeight: 24
                                radius: Theme.radiusSm
                                readonly property bool isActive: controlWindow.powerProfile === modelData.id
                                color: isActive ? Theme.accentDim : (profArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                border.color: isActive ? Theme.accent : (profArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: profBtn.isActive ? Theme.textPrimary : Theme.textSecondary
                                }

                                MouseArea {
                                    id: profArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        controlWindow.powerProfile = modelData.id;
                                        controlWindow.runCtl(["power", "set", modelData.id]);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 6. DISPLAY & MONITOR SCALING CARD (Sovereign Scaling Engine)
            // -----------------------------------------------------------------
            Rectangle {
                id: displayCard
                Layout.fillWidth: true
                implicitHeight: 68
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                property real currentScale: 1.0
                property string currentMonitor: "Virtual-1"
                property bool isAutoScale: true

                Process {
                    id: scaleStatusProc
                    command: ["x64-hyprland-scale", "status"]
                    stdout: StdioCollector {
                        id: scaleStatusCollector
                        onStreamFinished: {
                            if (!scaleStatusCollector.text) return;
                            var parts = scaleStatusCollector.text.trim().split("|");
                            if (parts.length >= 3) {
                                if (parts[0] !== "") displayCard.currentMonitor = parts[0];
                                var s = parseFloat(parts[1]);
                                if (!isNaN(s) && s > 0) displayCard.currentScale = s;
                                displayCard.isAutoScale = (parts[2] === "true");
                            }
                        }
                    }
                }

                Process {
                    id: scaleApplyProc
                    onExited: {
                        scaleRefreshTimer.restart();
                    }
                }

                Timer {
                    id: scaleRefreshTimer
                    interval: 350
                    repeat: false
                    onTriggered: displayCard.refreshScale()
                }

                function refreshScale() {
                    if (!scaleStatusProc.running) scaleStatusProc.running = true;
                }

                function applyScale(sVal, autoMode) {
                    displayCard.isAutoScale = Boolean(autoMode);
                    if (autoMode) {
                        scaleApplyProc.command = ["x64-hyprland-scale", "auto"];
                    } else {
                        displayCard.currentScale = sVal;
                        scaleApplyProc.command = ["x64-hyprland-scale", String(sVal)];
                    }
                    scaleApplyProc.running = true;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰍹 Pantalla & Escalado"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: displayCard.currentMonitor + (displayCard.isAutoScale ? (" (AUTO • " + Math.round(displayCard.currentScale * 100) + "%)") : (" (" + Math.round(displayCard.currentScale * 100) + "%)"))
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accent
                        }
                    }

                    // Quick Scale Preset Pills (AUTO + Manual Fractional Presets)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: [
                                { label: "AUTO", val: 0.0,  isAuto: true },
                                { label: "100%", val: 1.0,  isAuto: false },
                                { label: "125%", val: 1.25, isAuto: false },
                                { label: "150%", val: 1.5,  isAuto: false },
                                { label: "200%", val: 2.0,  isAuto: false }
                            ]

                            Rectangle {
                                id: scaleBtn
                                Layout.fillWidth: true
                                implicitHeight: 24
                                radius: Theme.radiusSm
                                readonly property bool isActive: modelData.isAuto ? displayCard.isAutoScale : (!displayCard.isAutoScale && Math.abs(displayCard.currentScale - modelData.val) < 0.05)
                                color: isActive ? Theme.accentDim : (scaleBtnArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                border.color: isActive ? Theme.accent : (scaleBtnArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: scaleBtn.isActive ? Theme.textPrimary : (scaleBtnArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                                }

                                MouseArea {
                                    id: scaleBtnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: displayCard.applyScale(modelData.val, modelData.isAuto)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // -----------------------------------------------------------------
            // 7. SESSION / POWER BUTTONS
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Lock
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: lockArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰌾"; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.textPrimary }
                        Text { text: "Bloquear"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: lockArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.closeRequested();
                            controlWindow.lockRequested();
                        }
                    }
                }

                // Reboot
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: rebootArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰑓"; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.textPrimary }
                        Text { text: "Reiniciar"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: rebootArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.exec_cmd("systemctl reboot")');
                            controlWindow.closeRequested();
                        }
                    }
                }

                // Power Off
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Theme.radiusSm
                    color: offArea.containsMouse ? Theme.accent : Theme.bgCard
                    border.color: offArea.containsMouse ? Theme.accentLight : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰐥"; font.family: Theme.fontMono; font.pixelSize: 13; color: offArea.containsMouse ? Theme.textPrimary : Theme.accent }
                        Text { text: "Apagar"; font.family: Theme.fontSans; font.pixelSize: 11; font.bold: true; color: offArea.containsMouse ? Theme.textPrimary : Theme.accent }
                    }

                    MouseArea {
                        id: offArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.exec_cmd("systemctl poweroff")');
                            controlWindow.closeRequested();
                        }
                    }
                }
            }
        }
    }
}
