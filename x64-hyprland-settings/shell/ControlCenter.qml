import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Io

PanelWindow {
    id: controlWindow

    signal closeRequested()
    signal lockRequested()
    signal dndToggled(bool active)
    signal nightlightToggled(bool active)
    signal brightnessChangedOsd(int val)

    property bool caffeineActive: false
    property bool nightlightActive: false
    property bool dndActive: false
    property bool isRecording: false
    property string recTime: "00:00"
    property bool recMenuOpen: false
    property string recScope: "fullscreen"
    property string recAudio: "desktop"
    property bool hasBattery: false
    property int batPct: 100
    property string batStatus: "AC"
    property string powerProfile: "balanced"
    property int brightnessVal: 100

    property real morphProgress: 0.0
    property real cardY: 14
    property real cardScale: 0.2

    anchors {
        top: true
        right: true
    }

    margins {
        top: 4
        right: 6
    }

    implicitWidth: 388
    implicitHeight: Math.min(((controlWindow.recMenuOpen && !controlWindow.isRecording) ? 790 : 730) + 38, (screen ? screen.height : 1080) - 20)

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"

    HyprlandFocusGrab {
        active: controlWindow.visible
        windows: [controlWindow]
        onCleared: controlWindow.closeAnimated()
    }

    function closeAnimated() {
        if (closeAnim.running) return;
        closeAnim.restart();
    }

    ParallelAnimation {
        id: openAnim
        running: false
        NumberAnimation {
            target: controlWindow
            property: "morphProgress"
            from: 0.0
            to: 1.0
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.35
        }
        NumberAnimation {
            target: controlWindow
            property: "cardY"
            from: 14
            to: 34
            duration: 320
            easing.type: Easing.OutBack
            easing.overshoot: 1.35
        }
        NumberAnimation {
            target: controlWindow
            property: "cardScale"
            from: 0.2
            to: 1.0
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }
        NumberAnimation {
            target: card
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim
        running: false
        NumberAnimation {
            target: controlWindow
            property: "morphProgress"
            to: 0.0
            duration: 180
            easing.type: Easing.InBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: controlWindow
            property: "cardY"
            to: 14
            duration: 180
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: controlWindow
            property: "cardScale"
            to: 0.2
            duration: 180
            easing.type: Easing.InBack
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0.0
            duration: 140
            easing.type: Easing.InQuad
        }
        onFinished: {
            controlWindow.closeRequested();
        }
    }

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
        wpSectionCard.detectCurrentWp();
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
                    if (d.brightness !== undefined) {
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
            controlWindow.morphProgress = 0.0;
            controlWindow.cardScale = 0.2;
            controlWindow.cardY = 14;
            card.opacity = 0.0;
            openAnim.restart();
        } else {
            controlWindow.morphProgress = 0.0;
            controlWindow.cardScale = 1.0;
            controlWindow.cardY = 34;
            card.opacity = 1.0;
        }
    }

    Component.onCompleted: {
        controlWindow.refreshAll();
    }

    // -------------------------------------------------------------------------
    // PILL SLIDER REUSABLE COMPONENT (ERdynamic Capsule)
    // -------------------------------------------------------------------------
    component PillSlider: Rectangle {
        id: pillRoot
        property string iconText: ""
        property string labelText: ""
        property real value: 0.0
        property real from: 0.0
        property real to: 1.0
        property color activeColor: Theme.accent
        property bool isDragging: false
        signal moved(real val)

        implicitHeight: 36
        radius: Theme.radiusPill
        color: Theme.bgPillTrack
        border.color: pillMouseArea.containsMouse ? Theme.borderAccent : Theme.borderGlass
        border.width: 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Filled level capsule
        Rectangle {
            id: fillLevel
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(parent.height, Math.min(parent.width, parent.width * ((pillRoot.value - pillRoot.from) / (pillRoot.to - pillRoot.from))))
            radius: Theme.radiusPill
            color: pillRoot.activeColor

            Behavior on width {
                enabled: !pillRoot.isDragging
                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
            }
        }

        // Mouse Drag / Click Handler
        MouseArea {
            id: pillMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function updateFromMouse(mouse) {
                var ratio = Math.max(0.0, Math.min(1.0, mouse.x / pillRoot.width));
                var newVal = pillRoot.from + ratio * (pillRoot.to - pillRoot.from);
                pillRoot.moved(newVal);
            }

            onPressed: (mouse) => {
                pillRoot.isDragging = true;
                updateFromMouse(mouse);
            }
            onPositionChanged: (mouse) => {
                if (pressed) updateFromMouse(mouse);
            }
            onReleased: {
                pillRoot.isDragging = false;
            }
        }

        // Overlay Labels & Icon
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            spacing: 8

            Text {
                text: pillRoot.iconText
                font.family: Theme.fontMono
                font.pixelSize: 14
                font.bold: true
                color: "#ffffff"
            }

            Text {
                text: pillRoot.labelText
                font.family: Theme.fontSans
                font.pixelSize: 11
                font.bold: true
                color: "#ffffff"
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Math.round(pillRoot.value * 100) + "%"
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                color: "#ffffff"
            }
        }
    }

    // Gooey liquid neck connecting the bar capsule to the card
    GooeyBridge {
        id: bridge
        anchors.fill: parent
        originX: card.width - 42
        originY: 24
        botY: card.y + 4
        topHalfW: 24
        botHalfW: 48
        morphProgress: controlWindow.morphProgress
        visible: controlWindow.visible && card.opacity > 0.01
    }

    // Control Center Card pinned to top right with Frosted Glass & Elastic Physics
    Rectangle {
        id: card
        x: 0
        y: controlWindow.cardY
        width: parent.width
        height: parent.height - 38
        transformOrigin: Item.TopRight
        scale: controlWindow.cardScale
        opacity: 0.0
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1
        clip: true

        Flickable {
            id: scrollFlick
            anchors.fill: parent
            anchors.margins: 12
            contentWidth: width
            contentHeight: contentCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: contentCol
                width: scrollFlick.width
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: I18n.controlCenterTitle
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
                            onClicked: controlWindow.closeAnimated()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderSubtle
                }

                // -------------------------------------------------------------
                // 1. QUICK SYSTEM TOGGLES (Caffeine, Nightlight, DND)
                // -------------------------------------------------------------
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
                                text: I18n.caffeine
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
                                text: I18n.nightLight
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
                                controlWindow.nightlightToggled(controlWindow.nightlightActive);
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
                                text: I18n.dnd
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
                                controlWindow.dndToggled(controlWindow.dndActive);
                                controlWindow.runCtl(["dnd", controlWindow.dndActive ? "on" : "off"]);
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 2. SCREEN CAPTURE & RECORDING SUITE
                // -------------------------------------------------------------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Capture Region (Recortar)
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
                            Text { text: I18n.crop; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                        }

                        MouseArea {
                            id: shotRegArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlWindow.recMenuOpen = false;
                                controlWindow.closeRequested();
                                controlWindow.runCtl(["screenshot", "region"]);
                            }
                        }
                    }

                    // Capture Fullscreen (Pantalla)
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
                            Text { text: I18n.screen; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                        }

                        MouseArea {
                            id: shotFullArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlWindow.recMenuOpen = false;
                                controlWindow.closeRequested();
                                controlWindow.runCtl(["screenshot", "full"]);
                            }
                        }
                    }

                    // Screen Record Button
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Theme.radiusSm
                        color: controlWindow.isRecording ? Theme.accent : (controlWindow.recMenuOpen ? Theme.accentDim : (recBtnArea.containsMouse ? Theme.bgHover : Theme.bgCard))
                        border.color: controlWindow.isRecording ? Theme.accentLight : ((controlWindow.recMenuOpen || recBtnArea.containsMouse) ? Theme.accent : Theme.borderSubtle)
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: controlWindow.isRecording ? "󰓛" : "󰑊"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: (controlWindow.isRecording || controlWindow.recMenuOpen) ? "#ffffff" : Theme.accent
                            }
                            Text {
                                text: controlWindow.isRecording ? (I18n.recordStop + controlWindow.recTime) : (controlWindow.recMenuOpen ? (I18n.record + " ▴") : (I18n.record + " ▾"))
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.bold: controlWindow.isRecording || controlWindow.recMenuOpen
                                color: Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: recBtnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (controlWindow.isRecording) {
                                    controlWindow.isRecording = false;
                                    controlWindow.recMenuOpen = false;
                                    controlWindow.runCtl(["record", "stop"]);
                                } else if (mouse.button === Qt.RightButton) {
                                    controlWindow.recMenuOpen = false;
                                    controlWindow.isRecording = true;
                                    controlWindow.closeRequested();
                                    controlWindow.runCtl(["record", "start", controlWindow.recScope, controlWindow.recAudio]);
                                } else {
                                    controlWindow.recMenuOpen = !controlWindow.recMenuOpen;
                                }
                            }
                        }
                    }
                }

                // Recording Drawer
                Rectangle {
                    id: recDrawer
                    visible: controlWindow.recMenuOpen && !controlWindow.isRecording
                    Layout.fillWidth: true
                    implicitHeight: 98
                    radius: Theme.radiusSm
                    color: Theme.bgCard
                    border.color: Theme.borderAccent
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Repeater {
                                model: [
                                    { id: "fullscreen", label: I18n.scopeFullscreen },
                                    { id: "region",     label: I18n.scopeRegion }
                                ]

                                Rectangle {
                                    id: scopePill
                                    Layout.fillWidth: true
                                    implicitHeight: 24
                                    radius: Theme.radiusSm
                                    readonly property bool isSel: controlWindow.recScope === modelData.id
                                    color: isSel ? Theme.accentDim : (scopeArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                    border.color: isSel ? Theme.accent : (scopeArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: scopePill.isSel ? "#ffffff" : Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: scopeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: controlWindow.recScope = modelData.id
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Repeater {
                                model: [
                                    { id: "none",    label: I18n.audioNone },
                                    { id: "desktop", label: I18n.audioDesktop },
                                    { id: "both",    label: I18n.audioBoth }
                                ]

                                Rectangle {
                                    id: audPill
                                    Layout.fillWidth: true
                                    implicitHeight: 24
                                    radius: Theme.radiusSm
                                    readonly property bool isSel: controlWindow.recAudio === modelData.id
                                    color: isSel ? Theme.accentDim : (audArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                    border.color: isSel ? Theme.accent : (audArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: audPill.isSel ? "#ffffff" : Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: audArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: controlWindow.recAudio = modelData.id
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: Theme.radiusSm
                            color: startRecArea.containsMouse ? Theme.accentLight : Theme.accent
                            border.color: Theme.accentLight
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "󰑊"; font.family: Theme.fontMono; font.pixelSize: 12; color: "#ffffff" }
                                Text { text: I18n.startRecordingNow; font.family: Theme.fontSans; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                            }

                            MouseArea {
                                id: startRecArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    controlWindow.recMenuOpen = false;
                                    controlWindow.isRecording = true;
                                    controlWindow.closeRequested();
                                    controlWindow.runCtl(["record", "start", controlWindow.recScope, controlWindow.recAudio]);
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 3. QUICK APP ACTIONS (2x2 Grid)
                // -------------------------------------------------------------
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
                            Text { text: I18n.termKitty; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
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
                            Text { text: I18n.filesDolphin; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
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
                            Text { text: I18n.x64Hello; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
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
                            Text { text: I18n.monitorBtop; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
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

                // -------------------------------------------------------------
                // 4. MPRIS NATIVE MEDIA PLAYER CARD
                // -------------------------------------------------------------
                Rectangle {
                    id: mprisCard
                    Layout.fillWidth: true
                    implicitHeight: activePlayer ? 66 : 34
                    radius: Theme.radiusSm
                    color: activePlayer ? Theme.bgCardSolid : Theme.bgContainer
                    border.color: activePlayer ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1
                    clip: true

                    readonly property var activePlayer: {
                        var list = Mpris.players.values;
                        if (!list || list.length === 0) return null;
                        for (var i = 0; i < list.length; i++) {
                            if (list[i].playbackState === MprisPlaybackState.Playing) return list[i];
                        }
                        return list[0];
                    }

                    readonly property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing

                    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                    // Active Player View
                    RowLayout {
                        visible: mprisCard.activePlayer !== null
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        // Album Art / Thumbnail
                        Rectangle {
                            width: 50
                            height: 50
                            radius: Theme.radiusSm
                            color: "#181924"
                            clip: true
                            border.color: Theme.borderGlass
                            border.width: 1

                            Image {
                                id: albumArtImg
                                anchors.fill: parent
                                source: (mprisCard.activePlayer && mprisCard.activePlayer.trackArtUrl) ? mprisCard.activePlayer.trackArtUrl : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰎆"
                                font.family: Theme.fontMono
                                font.pixelSize: 20
                                color: Theme.accent
                                visible: !albumArtImg.visible
                            }
                        }

                        // Title & Artist
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: (mprisCard.activePlayer && mprisCard.activePlayer.trackTitle) ? mprisCard.activePlayer.trackTitle : I18n.mediaNowPlaying
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (mprisCard.activePlayer && mprisCard.activePlayer.trackArtist) ? mprisCard.activePlayer.trackArtist : (mprisCard.activePlayer ? mprisCard.activePlayer.identity : "")
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                            }
                        }

                        // Playback Controls
                        RowLayout {
                            spacing: 4

                            // Previous
                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.radiusPill
                                color: prevArea.containsMouse ? Theme.bgHover : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒮"; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.textPrimary }
                                MouseArea {
                                    id: prevArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (mprisCard.activePlayer && mprisCard.activePlayer.canGoPrevious) mprisCard.activePlayer.previous()
                                }
                            }

                            // Play / Pause
                            Rectangle {
                                width: 32
                                height: 32
                                radius: Theme.radiusPill
                                color: playArea.containsMouse ? Theme.accentLight : Theme.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: mprisCard.isPlaying ? "󰏤" : "󰐊"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 14
                                    color: "#ffffff"
                                }
                                MouseArea {
                                    id: playArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (mprisCard.activePlayer) {
                                            if (mprisCard.activePlayer.canTogglePlaying) {
                                                mprisCard.activePlayer.togglePlaying();
                                            } else if (mprisCard.isPlaying && mprisCard.activePlayer.canPause) {
                                                mprisCard.activePlayer.pause();
                                            } else if (mprisCard.activePlayer.canPlay) {
                                                mprisCard.activePlayer.play();
                                            }
                                        }
                                    }
                                }
                            }

                            // Next
                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.radiusPill
                                color: nextArea.containsMouse ? Theme.bgHover : "transparent"
                                Text { anchors.centerIn: parent; text: "󰒭"; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.textPrimary }
                                MouseArea {
                                    id: nextArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (mprisCard.activePlayer && mprisCard.activePlayer.canGoNext) mprisCard.activePlayer.next()
                                }
                            }
                        }
                    }

                    // Fallback when no active playback
                    RowLayout {
                        visible: mprisCard.activePlayer === null
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Text {
                            text: "󰎆"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: Theme.textMuted
                        }

                        Text {
                            text: I18n.mediaNoActive
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }
                }

                // -------------------------------------------------------------
                // 5. MODERN PILL SLIDERS (VOLUME & BRIGHTNESS)
                // -------------------------------------------------------------
                Rectangle {
                    id: slidersContainer
                    Layout.fillWidth: true
                    implicitHeight: 96
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
                        spacing: 8

                        // Master Volume Pill Slider
                        PillSlider {
                            Layout.fillWidth: true
                            iconText: slidersContainer.isMuted ? "󰝟" : (slidersContainer.vol > 0.5 ? "󰕾" : (slidersContainer.vol > 0 ? "󰖀" : "󰕿"))
                            labelText: slidersContainer.isMuted ? I18n.audioMuted : I18n.masterVolume
                            value: slidersContainer.vol
                            from: 0.0
                            to: 1.0
                            activeColor: slidersContainer.isMuted ? Theme.accentDim : Theme.accent
                            onMoved: (val) => {
                                if (slidersContainer.sink && slidersContainer.sink.audio) {
                                    slidersContainer.sink.audio.volume = val;
                                }
                            }
                        }

                        // Display Brightness Pill Slider
                        PillSlider {
                            Layout.fillWidth: true
                            iconText: "󰃠"
                            labelText: I18n.displayBrightness
                            value: controlWindow.brightnessVal / 100.0
                            from: 0.05
                            to: 1.0
                            activeColor: "#ffaa00"
                            onMoved: (val) => {
                                var pct = Math.round(val * 100);
                                controlWindow.brightnessVal = pct;
                                controlWindow.brightnessChangedOsd(pct);
                                controlWindow.runCtl(["brightness", "set", pct.toString()]);
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 6. INTERACTIVE WALLPAPER SELECTOR SLIDER (6 OFFICIAL WALLPAPERS)
                // -------------------------------------------------------------
                Rectangle {
                    id: wpSectionCard
                    Layout.fillWidth: true
                    implicitHeight: 108
                    radius: Theme.radiusSm
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    property string currentWp: "01-monolith.jpg"

                    function detectCurrentWp() {
                        wpGetProc.running = true;
                    }

                    Process {
                        id: wpGetProc
                        command: ["x64-hyprland-ctl", "wallpaper", "get"]
                        stdout: StdioCollector {
                            onStreamFinished: {
                                if (text && text.trim().length > 0) {
                                    var p = text.trim();
                                    var fn = p.substring(p.lastIndexOf('/') + 1);
                                    if (fn) wpSectionCard.currentWp = fn;
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        // Section Title
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: I18n.wallpapersTitle
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textSecondary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: wpSectionCard.currentWp
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.accent
                            }
                        }

                        // Horizontal Flickable Carousel
                        Flickable {
                            Layout.fillWidth: true
                            implicitHeight: 66
                            contentWidth: wpRow.implicitWidth
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            Row {
                                id: wpRow
                                spacing: 8

                                Repeater {
                                    model: [
                                        { id: "01-monolith",     name: "01 Monolith", file: "01-monolith.jpg" },
                                        { id: "02-v3-carbon",    name: "02 Carbon",   file: "02-v3-carbon.jpg" },
                                        { id: "03-v2-shield",    name: "03 Shield",   file: "03-v2-shield.jpg" },
                                        { id: "04-hybrid-plate", name: "04 Hybrid",   file: "04-hybrid-plate.jpg" },
                                        { id: "05-faceted-armor",name: "05 Armor",    file: "05-faceted-armor.jpg" },
                                        { id: "06-stealth-dark", name: "06 Stealth",  file: "06-stealth-dark.jpg" }
                                    ]

                                    Rectangle {
                                        id: wpCard
                                        width: 104
                                        height: 62
                                        radius: Theme.radiusSm
                                        color: "#0a0a0f"
                                        clip: true
                                        readonly property bool isCur: wpSectionCard.currentWp === modelData.file
                                        border.color: isCur ? Theme.accent : (wpCardArea.containsMouse ? Theme.accentLight : Theme.borderSubtle)
                                        border.width: isCur ? 2 : 1
                                        scale: wpCardArea.containsMouse ? 1.04 : 1.0

                                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                                        Behavior on border.color { ColorAnimation { duration: 140 } }

                                        Image {
                                            anchors.fill: parent
                                            source: "file:///usr/share/backgrounds/x64-lios/" + modelData.file
                                            sourceSize: Qt.size(208, 124)
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }

                                        // Scrim overlay
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 22
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: "transparent" }
                                                GradientStop { position: 1.0; color: "#dd000000" }
                                            }
                                        }

                                        // Label
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 3
                                            text: modelData.name
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: wpCard.isCur ? Theme.accent : "#ffffff"
                                        }

                                        // Active checkmark
                                        Rectangle {
                                            visible: wpCard.isCur
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            width: 14
                                            height: 14
                                            radius: Theme.radiusPill
                                            color: Theme.accent

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰄬"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: "#ffffff"
                                            }
                                        }

                                        MouseArea {
                                            id: wpCardArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                wpSectionCard.currentWp = modelData.file;
                                                controlWindow.runCtl(["wallpaper", "set", modelData.file]);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 7. POWER PROFILES (Smart Battery Aware)
                // -------------------------------------------------------------
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 62
                    radius: Theme.radiusSm
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: I18n.powerProfile
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textSecondary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: controlWindow.hasBattery ? (controlWindow.batPct + "% (" + controlWindow.batStatus + ")") : I18n.acDirect
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: controlWindow.hasBattery ? (controlWindow.batPct < 20 ? Theme.accent : "#4ade80") : Theme.textMuted
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // Performance
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: Theme.radiusSm
                                readonly property bool isAct: controlWindow.powerProfile === "performance"
                                color: isAct ? Theme.accentDim : (perfArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                border.color: isAct ? Theme.accent : (perfArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: I18n.profilePerformance
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: parent.isAct ? "#ffffff" : Theme.textSecondary
                                }

                                MouseArea {
                                    id: perfArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        controlWindow.powerProfile = "performance";
                                        controlWindow.runCtl(["power", "set", "performance"]);
                                    }
                                }
                            }

                            // Balanced
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: Theme.radiusSm
                                readonly property bool isAct: controlWindow.powerProfile === "balanced"
                                color: isAct ? "#443b82f6" : (balArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                border.color: isAct ? "#3b82f6" : (balArea.containsMouse ? "#883b82f6" : Theme.borderSubtle)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: I18n.profileBalanced
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: parent.isAct ? "#ffffff" : Theme.textSecondary
                                }

                                MouseArea {
                                    id: balArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        controlWindow.powerProfile = "balanced";
                                        controlWindow.runCtl(["power", "set", "balanced"]);
                                    }
                                }
                            }

                            // Power Saver
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: Theme.radiusSm
                                readonly property bool isAct: controlWindow.powerProfile === "power-saver"
                                color: isAct ? "#4410b981" : (ecoArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                border.color: isAct ? "#10b981" : (ecoArea.containsMouse ? "#8810b981" : Theme.borderSubtle)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: I18n.profilePowerSaver
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: parent.isAct ? "#ffffff" : Theme.textSecondary
                                }

                                MouseArea {
                                    id: ecoArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        controlWindow.powerProfile = "power-saver";
                                        controlWindow.runCtl(["power", "set", "power-saver"]);
                                    }
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 8. DISPLAY & FRACTIONAL MONITOR SCALING
                // -------------------------------------------------------------
                Rectangle {
                    id: displayCard
                    Layout.fillWidth: true
                    implicitHeight: 62
                    radius: Theme.radiusSm
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    property real currentScale: 1.0
                    property string currentMonitor: "Virtual-1"
                    property bool isAutoScale: false

                    function refreshScale() {
                        scaleProc.running = true;
                    }

                    function applyScale(targetScale, autoMode) {
                        displayCard.isAutoScale = autoMode;
                        if (!autoMode) displayCard.currentScale = targetScale;
                        var cmd = autoMode ? ["x64-hyprland-scale", "auto"] : ["x64-hyprland-scale", "set", targetScale.toString()];
                        scaleApplyProc.command = cmd;
                        scaleApplyProc.running = true;
                    }

                    Process {
                        id: scaleApplyProc
                        onExited: displayCard.refreshScale()
                    }

                    Process {
                        id: scaleProc
                        command: ["x64-hyprland-scale", "get"]
                        stdout: StdioCollector {
                            id: scaleCollector
                            onStreamFinished: {
                                if (!scaleCollector.text) return;
                                try {
                                    var data = JSON.parse(scaleCollector.text.trim());
                                    displayCard.currentScale = data.scale || 1.0;
                                    displayCard.currentMonitor = data.monitor || "Virtual-1";
                                    displayCard.isAutoScale = Boolean(data.auto);
                                } catch (e) {}
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: I18n.displayScaling
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textSecondary
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

                // -------------------------------------------------------------
                // 9. SESSION / POWER CONTROLS
                // -------------------------------------------------------------
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
                            Text { text: I18n.lock; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
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
                            Text { text: I18n.reboot; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
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
                            Text { text: I18n.powerOff; font.family: Theme.fontSans; font.pixelSize: 11; font.bold: true; color: offArea.containsMouse ? Theme.textPrimary : Theme.accent }
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
}
