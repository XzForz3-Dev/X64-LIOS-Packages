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
    signal dndToggled(bool active)
    signal nightlightToggled(bool active)
    signal brightnessChangedOsd(int val)

    readonly property bool caffeineActive: SysState.caffeineActive
    readonly property bool nightlightActive: SysState.nightlightActive
    readonly property bool dndActive: SysState.dndActive
    readonly property bool isRecording: SysState.isRecording
    readonly property string recTime: SysState.recTime
    property bool recMenuOpen: false
    property string recScope: "fullscreen"
    property string recAudio: "desktop"
    readonly property bool hasBattery: SysState.hasBattery
    readonly property int batPct: SysState.batPct
    readonly property string batStatus: SysState.batStatus
    readonly property string powerProfile: SysState.powerProfile
    readonly property int brightnessVal: SysState.brightnessVal
    readonly property string aiEngine: SysState.aiEngine
    readonly property bool zoomEnabled: SysState.zoomEnabled
    readonly property string zoomFactor: SysState.zoomFactor
    readonly property bool gamingModeActive: SysState.gamingModeActive
    readonly property bool autoGamingEnabled: SysState.autoGamingEnabled

    anchors {
        top: true
        right: true
    }

    margins {
        top: 44
        right: 8
    }

    implicitWidth: 400
    implicitHeight: Math.min(Math.max(600, mainCol.implicitHeight + 30), (screen ? screen.height : 1080) - 52)

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"

    property bool lockClose: false

    HyprlandFocusGrab {
        id: focusGrab
        active: controlWindow.visible && !controlWindow.lockClose
        windows: [controlWindow]
        onCleared: {
            if (!controlWindow.lockClose && controlWindow.visible) {
                controlWindow.closeAnimated();
            }
        }
    }

    function closeAnimated() {
        if (closeAnim.running) return;
        closeAnim.restart();
    }

    ParallelAnimation {
        id: openAnim
        running: false
        NumberAnimation {
            target: card
            property: "scale"
            from: 0.82
            to: 1.0
            duration: 270
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
        NumberAnimation {
            target: card
            property: "y"
            from: -24
            to: 0
            duration: 270
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
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
            target: card
            property: "scale"
            to: 0.86
            duration: 150
            easing.type: Easing.InBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: card
            property: "y"
            to: -18
            duration: 150
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0.0
            duration: 130
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
        SysState.runCtl(args);
    }

    Process {
        id: appLauncherProc
    }

    function launchApp(cmdStr) {
        controlWindow.closeRequested();
        if (appLauncherProc.running) {
            appLauncherProc.running = false;
        }
        appLauncherProc.command = ["bash", "-c", "nohup " + cmdStr + " >/dev/null 2>&1 &"];
        appLauncherProc.running = true;
    }

    function refreshAll() {
        displayCard.refreshScale();
        SysState.refreshNow(true);
    }

    onVisibleChanged: {
        SysState.controlOpen = visible;
        if (visible) {
            if (controlWindow.screen && controlWindow.screen.name) {
                displayCard.selectedMonitorName = controlWindow.screen.name;
            }
            cardScroll.contentY = 0;
            displayCard.refreshScale(false);
            card.scale = 0.82;
            card.y = -24;
            card.opacity = 0.0;
            openAnim.restart();
        } else {
            card.scale = 1.0;
            card.y = 0;
            card.opacity = 1.0;
        }
    }

    Component.onCompleted: {
        displayCard.refreshScale();
    }

    // Control Center Card pinned to top right with Jelly / Elastic Physics
    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(mainCol.implicitHeight + 30, parent.height)
        clip: true
        transformOrigin: Item.TopRight
        layer.enabled: openAnim.running || closeAnim.running
        layer.smooth: true
        scale: 1.0
        opacity: 1.0
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        Flickable {
            id: cardScroll
            anchors.fill: parent
            contentWidth: width
            contentHeight: mainCol.implicitHeight + 30
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            ColumnLayout {
                id: mainCol
                x: 15
                y: 15
                width: cardScroll.width - 30
                spacing: 10

            // =================================================================
            // HEADER: TITLE, SUBTITLE & TOP-RIGHT CIRCULAR SESSION ACTIONS
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ColumnLayout {
                    spacing: 1
                    RowLayout {
                        spacing: 6
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.accent
                        }
                        Text {
                            text: I18n.controlCenterTitle
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.1
                            color: Theme.textSecondary
                        }
                    }
                    Text {
                        text: I18n.isEs ? "X64 LIOS v28 • Sesión activa" : "X64 LIOS v28 • Active session"
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // Top-Right Circular Session Buttons (Clipboard History, Shortcuts Help, Lock, Reboot, Power Off)
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: clipArea.containsMouse ? Theme.accentDim : Theme.bgCard
                    border.color: clipArea.containsMouse ? Theme.accentBorder : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on border.color { ColorAnimation { duration: 130 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅍"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: clipArea.containsMouse ? Theme.accent : Theme.textSecondary
                    }

                    MouseArea {
                        id: clipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.launchApp("quickshell ipc call clipboard toggle");
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: helpArea.containsMouse ? Theme.accentDim : Theme.bgCard
                    border.color: helpArea.containsMouse ? Theme.accentBorder : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on border.color { ColorAnimation { duration: 130 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰌌"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: helpArea.containsMouse ? Theme.accent : Theme.textSecondary
                    }

                    MouseArea {
                        id: helpArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.launchApp("quickshell ipc call shortcuts toggle");
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: lockArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: lockArea.containsMouse ? "#33ffffff" : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 130 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰌾"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: lockArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
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

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: rebootArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: rebootArea.containsMouse ? "#33ffffff" : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 130 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑓"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: rebootArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }

                    MouseArea {
                        id: rebootArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.launchApp("systemctl reboot");
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: offArea.containsMouse ? Theme.accent : "#1fff2b2b"
                    border.color: offArea.containsMouse ? Theme.accentLight : Theme.borderAccent
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 130 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰐥"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: offArea.containsMouse ? "#ffffff" : Theme.accent
                    }

                    MouseArea {
                        id: offArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            controlWindow.launchApp("systemctl poweroff");
                        }
                    }
                }
            }

            // =================================================================
            // 1. STATE TOGGLE TILES (Color = State: Crimson ONLY when Active)
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Modo Café (Idle Inhibitor)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: Theme.radiusMd
                    color: controlWindow.caffeineActive ? Theme.accentDim : (cafArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.caffeineActive ? Theme.accentBorder : (cafArea.containsMouse ? "#28ffffff" : Theme.borderSubtle)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 2

                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 6
                            color: controlWindow.caffeineActive ? "#28ff2b2b" : "#0fffffff"
                            Text {
                                anchors.centerIn: parent
                                text: "󰅶"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: controlWindow.caffeineActive ? Theme.accent : Theme.textSecondary
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: I18n.caffeine
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            text: controlWindow.caffeineActive ? (I18n.isEs ? "Activo" : "Active") : (I18n.isEs ? "Apagado" : "Off")
                            font.family: Theme.fontSans
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: controlWindow.caffeineActive ? "#ff9494" : Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: cafArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SysState.guardToggle();
                            var next = !SysState.caffeineActive;
                            SysState.caffeineActive = next;
                            controlWindow.runCtl(["caffeine", next ? "on" : "off"]);
                        }
                    }
                }

                // Luz Noche (4200K Filter — Unified Crimson State)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: Theme.radiusMd
                    color: controlWindow.nightlightActive ? Theme.accentDim : (nlArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.nightlightActive ? Theme.accentBorder : (nlArea.containsMouse ? "#28ffffff" : Theme.borderSubtle)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 2

                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 6
                            color: controlWindow.nightlightActive ? "#28ff2b2b" : "#0fffffff"
                            Text {
                                anchors.centerIn: parent
                                text: "󰖔"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: controlWindow.nightlightActive ? Theme.accent : Theme.textSecondary
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: I18n.nightLight
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            text: controlWindow.nightlightActive ? "4200K" : (I18n.isEs ? "Apagado" : "Off")
                            font.family: Theme.fontSans
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: controlWindow.nightlightActive ? "#ff9494" : Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: nlArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SysState.guardToggle();
                            var next = !SysState.nightlightActive;
                            SysState.nightlightActive = next;
                            controlWindow.nightlightToggled(next);
                            controlWindow.runCtl(["nightlight", next ? "on" : "off"]);
                        }
                    }
                }

                // No Molestar (DND — Unified Crimson State)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: Theme.radiusMd
                    color: controlWindow.dndActive ? Theme.accentDim : (dndArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.dndActive ? Theme.accentBorder : (dndArea.containsMouse ? "#28ffffff" : Theme.borderSubtle)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 2

                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 6
                            color: controlWindow.dndActive ? "#28ff2b2b" : "#0fffffff"
                            Text {
                                anchors.centerIn: parent
                                text: "󰂛"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: controlWindow.dndActive ? Theme.accent : Theme.textSecondary
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: I18n.dnd
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            text: controlWindow.dndActive ? (I18n.isEs ? "Activo" : "Active") : (I18n.isEs ? "Apagado" : "Off")
                            font.family: Theme.fontSans
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: controlWindow.dndActive ? "#ff9494" : Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: dndArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            SysState.guardToggle();
                            var next = !SysState.dndActive;
                            SysState.dndActive = next;
                            controlWindow.dndToggled(next);
                            controlWindow.runCtl(["dnd", next ? "on" : "off"]);
                        }
                    }
                }

                // Lupa Zoom (Live Magnifier On/Off — SUPER + CTRL + Wheel)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 74
                    radius: Theme.radiusMd
                    color: controlWindow.zoomEnabled ? Theme.accentDim : (zoomArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: controlWindow.zoomEnabled ? Theme.accentBorder : (zoomArea.containsMouse ? "#28ffffff" : Theme.borderSubtle)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 9
                        spacing: 2

                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 6
                            color: controlWindow.zoomEnabled ? "#28ff2b2b" : "#0fffffff"
                            Text {
                                anchors.centerIn: parent
                                text: "󰍉"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: controlWindow.zoomEnabled ? Theme.accent : Theme.textSecondary
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: I18n.isEs ? "Lupa Zoom" : "Live Zoom"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            text: controlWindow.zoomEnabled
                                ? ((controlWindow.zoomFactor !== "1.0" && controlWindow.zoomFactor !== "1.00") ? (controlWindow.zoomFactor + "x") : (I18n.isEs ? "ALT+Rueda" : "ALT+Wheel"))
                                : (I18n.isEs ? "Apagado" : "Off")
                            font.family: Theme.fontSans
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: controlWindow.zoomEnabled ? "#ff9494" : Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: zoomArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            SysState.guardToggle();
                            if (mouse.button === Qt.RightButton) {
                                SysState.zoomFactor = "1.0";
                                controlWindow.runCtl(["zoom", "reset"]);
                            } else {
                                var next = !SysState.zoomEnabled;
                                SysState.zoomEnabled = next;
                                if (!next) SysState.zoomFactor = "1.0";
                                controlWindow.runCtl(["zoom", next ? "on" : "off"]);
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 2. UNIFIED 3-SEGMENT SCREEN CAPTURE & SMOOTH ACCORDION RECORDING
            // =================================================================
            Column {
                Layout.fillWidth: true
                spacing: 0

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 2

                        // Segment 1: Crop Region (Recortar)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 7
                            color: shotRegArea.containsMouse ? Theme.bgHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 130 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: "󰆞"; font.family: Theme.fontMono; font.pixelSize: 12; color: shotRegArea.containsMouse ? Theme.textPrimary : Theme.textSecondary }
                                Text { text: I18n.crop; font.family: Theme.fontSans; font.pixelSize: 11; font.weight: Font.Medium; color: shotRegArea.containsMouse ? Theme.textPrimary : Theme.textSecondary }
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

                        Rectangle { implicitWidth: 1; implicitHeight: 16; color: Theme.borderSubtle }

                        // Segment 2: Fullscreen Capture (Pantalla)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 7
                            color: shotFullArea.containsMouse ? Theme.bgHover : "transparent"
                            Behavior on color { ColorAnimation { duration: 130 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: "󰄀"; font.family: Theme.fontMono; font.pixelSize: 12; color: shotFullArea.containsMouse ? Theme.textPrimary : Theme.textSecondary }
                                Text { text: I18n.screen; font.family: Theme.fontSans; font.pixelSize: 11; font.weight: Font.Medium; color: shotFullArea.containsMouse ? Theme.textPrimary : Theme.textSecondary }
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

                        Rectangle { implicitWidth: 1; implicitHeight: 16; color: Theme.borderSubtle }

                        // Segment 3: Screen Record (Grabar)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 7
                            color: controlWindow.isRecording ? Theme.accent : (controlWindow.recMenuOpen ? Theme.accentDim : (recBtnArea.containsMouse ? Theme.bgHover : "transparent"))
                            Behavior on color { ColorAnimation { duration: 160 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: controlWindow.isRecording ? "󰓛" : "󰑊"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: controlWindow.isRecording ? "#ffffff" : Theme.accent
                                }
                                Text {
                                    text: controlWindow.isRecording ? (I18n.recordStop + controlWindow.recTime) : I18n.record
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.weight: (controlWindow.isRecording || controlWindow.recMenuOpen) ? Font.Bold : Font.Medium
                                    color: (controlWindow.isRecording || controlWindow.recMenuOpen || recBtnArea.containsMouse) ? Theme.textPrimary : Theme.textSecondary
                                }
                                Text {
                                    visible: !controlWindow.isRecording
                                    text: "󰅀"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: (controlWindow.recMenuOpen || recBtnArea.containsMouse) ? Theme.textPrimary : Theme.textMuted
                                    rotation: controlWindow.recMenuOpen ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
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
                                        SysState.isRecording = false;
                                        controlWindow.recMenuOpen = false;
                                        controlWindow.runCtl(["record", "stop"]);
                                    } else if (mouse.button === Qt.RightButton) {
                                        controlWindow.recMenuOpen = false;
                                        SysState.isRecording = true;
                                        controlWindow.closeRequested();
                                        controlWindow.runCtl(["record", "start", controlWindow.recScope, controlWindow.recAudio]);
                                    } else {
                                        controlWindow.recMenuOpen = !controlWindow.recMenuOpen;
                                    }
                                }
                            }
                        }
                    }
                }

                // Smooth Accordion Container for Recording Options Drawer
                Item {
                    id: recDrawerClip
                    readonly property bool isOpen: controlWindow.recMenuOpen && !controlWindow.isRecording
                    width: parent.width
                    height: isOpen ? 106 : 0
                    clip: true

                    Behavior on height {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: recDrawer
                        width: parent.width
                        height: 98
                        y: recDrawerClip.isOpen ? 8 : -12
                        opacity: recDrawerClip.isOpen ? 1.0 : 0.0
                        scale: recDrawerClip.isOpen ? 1.0 : 0.96
                        transformOrigin: Item.Top
                        radius: Theme.radiusMd
                        color: Theme.bgCard
                        border.color: Theme.borderAccent
                        border.width: 1

                        Behavior on y {
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 5

                            // Row 1: Scope Selector
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
                                        radius: 6
                                        readonly property bool isSel: controlWindow.recScope === modelData.id
                                        color: isSel ? Theme.accentDim : (scopeArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                                        border.color: isSel ? Theme.accentBorder : Theme.borderSubtle
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: scopePill.isSel ? Theme.textPrimary : Theme.textSecondary
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

                            // Row 2: Audio Source Selector
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
                                        radius: 6
                                        readonly property bool isSel: controlWindow.recAudio === modelData.id
                                        color: isSel ? Theme.accentDim : (audArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                                        border.color: isSel ? Theme.accentBorder : Theme.borderSubtle
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: audPill.isSel ? Theme.textPrimary : Theme.textSecondary
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

                            // Row 3: Start Recording Action Button
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: 6
                                color: startRecArea.containsMouse ? Theme.accentLight : Theme.accent
                                Behavior on color { ColorAnimation { duration: 140 } }

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
                                        SysState.isRecording = true;
                                        controlWindow.closeRequested();
                                        controlWindow.runCtl(["record", "start", controlWindow.recScope, controlWindow.recAudio]);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. TACTILE PILL SLIDERS CARD (Master Volume & Display Brightness)
            // =================================================================
            Rectangle {
                id: slidersCard
                Layout.fillWidth: true
                implicitHeight: 102
                radius: Theme.radiusMd
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

                    // --- Pill 1: Master Volume ---
                    Rectangle {
                        id: volPillTrack
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 10
                        color: Theme.bgElevated
                        border.color: volDragArea.containsMouse ? "#28ffffff" : Theme.borderSubtle
                        border.width: 1
                        clip: true

                        // Filled Volume Progress Bar
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, parent.width * Math.min(1.0, slidersCard.vol)))
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: slidersCard.isMuted ? "#14ffffff" : "#38ff2b2b" }
                                GradientStop { position: 1.0; color: slidersCard.isMuted ? "#24ffffff" : "#80ff2b2b" }
                            }

                            // Subtle vertical thumb line at right edge of fill
                            Rectangle {
                                visible: slidersCard.vol > 0.03
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 18
                                radius: 1.5
                                color: slidersCard.isMuted ? Theme.textMuted : "#ccffffff"
                            }
                        }

                        // Foreground Content (Icon + Label + Value)
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 16
                            spacing: 8

                            Text {
                                text: slidersCard.isMuted ? "󰝟" : (slidersCard.vol <= 0.01 ? "󰕿" : (slidersCard.vol < 0.5 ? "󰖀" : "󰕾"))
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                color: slidersCard.isMuted ? Theme.accent : Theme.textPrimary
                            }

                            Text {
                                text: I18n.isEs ? "Volumen" : "Volume"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: slidersCard.isMuted ? Theme.textSecondary : Theme.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: slidersCard.isMuted ? "MUTE" : Math.round(slidersCard.vol * 100) + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: slidersCard.isMuted ? Theme.accent : Theme.textPrimary
                            }
                        }

                        // Drag / Click / Wheel Handler
                        MouseArea {
                            id: volDragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            function setVolFromX(mx) {
                                if (!slidersCard.sink || !slidersCard.sink.audio) return;
                                var ratio = Math.max(0.0, Math.min(1.0, mx / volPillTrack.width));
                                slidersCard.sink.audio.volume = ratio;
                                if (slidersCard.sink.audio.muted && ratio > 0.01) {
                                    slidersCard.sink.audio.muted = false;
                                }
                            }
                            onPressed: (mouse) => {
                                if (mouse.x < 34) {
                                    if (slidersCard.sink && slidersCard.sink.audio) {
                                        slidersCard.sink.audio.muted = !slidersCard.sink.audio.muted;
                                    }
                                } else {
                                    setVolFromX(mouse.x);
                                }
                            }
                            onPositionChanged: (mouse) => {
                                if (pressed && mouse.x >= 34) {
                                    setVolFromX(mouse.x);
                                }
                            }
                            onWheel: (wheel) => {
                                if (slidersCard.sink && slidersCard.sink.audio) {
                                    var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                    slidersCard.sink.audio.volume = Math.max(0.0, Math.min(1.0, slidersCard.sink.audio.volume + step));
                                }
                            }
                        }
                    }

                    // --- Pill 2: Display Brightness ---
                    Rectangle {
                        id: brSlider
                        property bool pressed: brDragArea.pressed
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 10
                        color: Theme.bgElevated
                        border.color: brDragArea.containsMouse ? "#28ffffff" : Theme.borderSubtle
                        border.width: 1
                        clip: true

                        // Filled Brightness Progress Bar (Warm Pearl / Silver)
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, parent.width * (controlWindow.brightnessVal / 100.0)))
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#18ffffff" }
                                GradientStop { position: 1.0; color: "#36ffffff" }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 18
                                radius: 1.5
                                color: "#ccffffff"
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 16
                            spacing: 8

                            Text {
                                text: "󰃠"
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                color: Theme.textPrimary
                            }

                            Text {
                                text: I18n.isEs ? "Brillo" : "Brightness"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: controlWindow.brightnessVal + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: brDragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressedChanged: SysState.brightnessDragging = pressed
                            function setBrFromX(mx) {
                                SysState.guardBrightness();
                                var ratio = Math.max(0.15, Math.min(1.0, mx / brSlider.width));
                                var v = Math.round(ratio * 100);
                                SysState.brightnessVal = v;
                                controlWindow.brightnessChangedOsd(v);
                                brApplyDebounce.restart();
                            }
                            onPressed: (mouse) => setBrFromX(mouse.x)
                            onPositionChanged: (mouse) => {
                                if (pressed) setBrFromX(mouse.x);
                            }
                            onWheel: (wheel) => {
                                SysState.guardBrightness();
                                var step = wheel.angleDelta.y > 0 ? 5 : -5;
                                var v = Math.max(15, Math.min(100, SysState.brightnessVal + step));
                                SysState.brightnessVal = v;
                                controlWindow.brightnessChangedOsd(v);
                                brApplyDebounce.restart();
                            }
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

            // =================================================================
            // 3B. MODO GAMING / LATENCIA CERO (SUPER + G + AUTO FULLSCREEN)
            // =================================================================
            Rectangle {
                id: gamingCard
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.radiusMd
                color: controlWindow.gamingModeActive ? Theme.accentDim : Theme.bgCard
                border.color: controlWindow.gamingModeActive ? Theme.accentBorder : Theme.borderSubtle
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                MouseArea {
                    id: gamingCardArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SysState.guardToggle();
                        var next = !SysState.gamingModeActive;
                        SysState.gamingModeActive = next;
                        controlWindow.runCtl(["gamemode", next ? "on" : "off"]);
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Rectangle {
                        implicitWidth: 26
                        implicitHeight: 26
                        radius: 7
                        color: controlWindow.gamingModeActive ? "#33ff2b2b" : "#0fffffff"
                        Text {
                            anchors.centerIn: parent
                            text: "󰊴"
                            font.family: Theme.fontMono
                            font.pixelSize: 15
                            color: controlWindow.gamingModeActive ? Theme.accent : Theme.textSecondary
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: I18n.isEs ? "MODO GAMING • LATENCIA CERO" : "GAMING MODE • ZERO LATENCY"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.6
                            color: controlWindow.gamingModeActive ? Theme.accent : Theme.textSecondary
                        }

                        Text {
                            text: controlWindow.gamingModeActive
                                ? (I18n.isEs ? "Activo (Sin blur/sombras • DND • CPU Max)" : "Active (No blur/shadows • DND • Max CPU)")
                                : (controlWindow.autoGamingEnabled
                                    ? (I18n.isEs ? "Apagado (SUPER + G • Auto juegos ON)" : "Off (SUPER + G • Auto games ON)")
                                    : (I18n.isEs ? "Apagado (SUPER + G • Solo manual)" : "Off (SUPER + G • Manual only)"))
                            font.family: Theme.fontSans
                            font.pixelSize: 9
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            color: controlWindow.gamingModeActive ? "#ff9494" : Theme.textMuted
                        }
                    }

                    // Compact Auto-Gaming Toggle Pill
                    Rectangle {
                        id: autoGameChip
                        implicitHeight: 20
                        implicitWidth: autoGameLabel.implicitWidth + 12
                        radius: 10
                        color: controlWindow.autoGamingEnabled
                            ? (autoGameArea.containsMouse ? "#40ff2b2b" : "#26ff2b2b")
                            : (autoGameArea.containsMouse ? "#22ffffff" : "#12ffffff")
                        border.color: controlWindow.autoGamingEnabled ? Theme.accentBorder : Theme.borderSubtle
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Text {
                            id: autoGameLabel
                            anchors.centerIn: parent
                            text: "AUTO"
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            font.letterSpacing: 0.5
                            color: controlWindow.autoGamingEnabled ? Theme.accent : Theme.textMuted
                        }

                        MouseArea {
                            id: autoGameArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SysState.guardToggle();
                                var next = !SysState.autoGamingEnabled;
                                SysState.autoGamingEnabled = next;
                                controlWindow.runCtl(["auto-gaming", next ? "on" : "off"]);
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 18
                        radius: 9
                        color: controlWindow.gamingModeActive ? Theme.accent : "#22ffffff"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            implicitWidth: 14
                            implicitHeight: 14
                            radius: 7
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                            x: controlWindow.gamingModeActive ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }

            // =================================================================
            // 4. POWER PROFILES & SMART BATTERY SEGMENTED CARD
            // =================================================================
            Rectangle {
                id: powerProfileCard
                Layout.fillWidth: true
                implicitHeight: 68
                radius: Theme.radiusMd
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
                            text: I18n.isEs ? "󰾅 PERFIL DE ENERGÍA" : "󰾅 POWER PROFILE"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.6
                            color: Theme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: controlWindow.hasBattery ? ("󰁹 " + controlWindow.batPct + "% (" + controlWindow.batStatus + ")") : I18n.acDirect
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: controlWindow.hasBattery && controlWindow.batPct <= 15 ? Theme.accent : Theme.textSecondary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 8
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2

                            Repeater {
                                model: [
                                    { id: "performance", label: I18n.isEs ? "Rendimiento" : "Performance" },
                                    { id: "balanced",    label: I18n.isEs ? "Equilibrado" : "Balanced" },
                                    { id: "power-saver", label: I18n.isEs ? "Ahorro" : "Power Saver" }
                                ]

                                Rectangle {
                                    id: profBtn
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    readonly property bool isActive: controlWindow.powerProfile === modelData.id
                                    color: isActive ? Theme.accentDim : (profArea.containsMouse ? Theme.bgHover : "transparent")
                                    border.color: isActive ? Theme.accentBorder : "transparent"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: profBtn.isActive
                                        color: profBtn.isActive ? Theme.textPrimary : Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: profArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            SysState.guardToggle();
                                            SysState.powerProfile = modelData.id;
                                            controlWindow.runCtl(["power", "set", modelData.id]);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 5. DISPLAY & MONITOR SCALING SEGMENTED CARD
            // =================================================================
            // 5. MULTI-MONITOR DISPLAY CONTROL (MONITOR, SCALE, HZ & VRR)
            // =================================================================
            Rectangle {
                id: displayCard
                Layout.fillWidth: true
                implicitHeight: displayCol.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                property var monitorsList: []
                property string selectedMonitorName: ""
                property int vrrMode: 1 // 0=Off, 1=On, 2=Fullscreen
                property double lastScaleRefreshMs: 0

                readonly property var activeMon: {
                    if (!monitorsList || monitorsList.length === 0) return null;
                    if (selectedMonitorName !== "") {
                        for (var i = 0; i < monitorsList.length; i++) {
                            if (monitorsList[i].name === selectedMonitorName) return monitorsList[i];
                        }
                    }
                    var scrName = (controlWindow.screen && controlWindow.screen.name) ? controlWindow.screen.name : "";
                    if (scrName !== "") {
                        for (var j = 0; j < monitorsList.length; j++) {
                            if (monitorsList[j].name === scrName) return monitorsList[j];
                        }
                    }
                    for (var k = 0; k < monitorsList.length; k++) {
                        if (monitorsList[k].focused) return monitorsList[k];
                    }
                    return monitorsList[0];
                }

                readonly property string currentMonitor: activeMon ? activeMon.name : ((controlWindow.screen && controlWindow.screen.name) ? controlWindow.screen.name : "Display")
                readonly property real currentScale: activeMon ? Number(activeMon.scale || 1.0) : 1.0
                readonly property bool isAutoScale: activeMon ? Boolean(activeMon.isAuto) : false
                readonly property int currentRefresh: activeMon ? Number(activeMon.refresh || 60) : 60
                readonly property string currentResStr: activeMon ? (activeMon.width + "×" + activeMon.height) : ""
                readonly property var currentRates: (activeMon && activeMon.rates && activeMon.rates.length > 0) ? activeMon.rates : [{ label: currentRefresh + " Hz", hz: currentRefresh, mode: "preferred" }]

                Process {
                    id: scaleStatusProc
                    command: ["/usr/bin/x64-hyprland-scale", "list"]
                    stdout: StdioCollector {
                        id: scaleStatusCollector
                        onStreamFinished: {
                            if (!scaleStatusCollector.text) return;
                            try {
                                var d = JSON.parse(scaleStatusCollector.text.trim());
                                if (d.vrr !== undefined) displayCard.vrrMode = Number(d.vrr);
                                if (d.monitors && d.monitors.length > 0) {
                                    displayCard.monitorsList = d.monitors;
                                    // Validate current selection still exists (hotplug-safe)
                                    var found = false;
                                    for (var i = 0; i < d.monitors.length; i++) {
                                        if (d.monitors[i].name === displayCard.selectedMonitorName) {
                                            found = true;
                                            break;
                                        }
                                    }
                                    if (!found) {
                                        var pref = (controlWindow.screen && controlWindow.screen.name) ? controlWindow.screen.name : "";
                                        var picked = "";
                                        for (var j = 0; j < d.monitors.length; j++) {
                                            if (d.monitors[j].name === pref) { picked = pref; break; }
                                        }
                                        if (picked === "") {
                                            for (var k = 0; k < d.monitors.length; k++) {
                                                if (d.monitors[k].focused) { picked = d.monitors[k].name; break; }
                                            }
                                        }
                                        displayCard.selectedMonitorName = picked !== "" ? picked : d.monitors[0].name;
                                    }
                                }
                            } catch (e) {}
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
                    onTriggered: displayCard.refreshScale(true)
                }

                function refreshScale(force) {
                    if (scaleStatusProc.running) return;
                    var now = Date.now();
                    if (!force && (now - displayCard.lastScaleRefreshMs) < 1000) return;
                    displayCard.lastScaleRefreshMs = now;
                    scaleStatusProc.running = true;
                }

                function applyScale(sVal, autoMode) {
                    var mon = displayCard.currentMonitor;
                    if (!mon) return;
                    if (scaleApplyProc.running) scaleApplyProc.running = false;
                    scaleApplyProc.command = ["/usr/bin/x64-hyprland-scale", "set-scale", mon, autoMode ? "auto" : String(sVal)];
                    scaleApplyProc.running = true;
                }

                function applyRate(modeStr) {
                    var mon = displayCard.currentMonitor;
                    if (!mon || !modeStr) return;
                    if (scaleApplyProc.running) scaleApplyProc.running = false;
                    scaleApplyProc.command = ["/usr/bin/x64-hyprland-scale", "set-rate", mon, String(modeStr)];
                    scaleApplyProc.running = true;
                }

                function cycleVrr() {
                    var nextVrr = (displayCard.vrrMode + 1) % 3;
                    displayCard.vrrMode = nextVrr;
                    if (scaleApplyProc.running) scaleApplyProc.running = false;
                    scaleApplyProc.command = ["/usr/bin/x64-hyprland-scale", "set-vrr", String(nextVrr)];
                    scaleApplyProc.running = true;
                }

                ColumnLayout {
                    id: displayCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 6

                    // Header: Title + Active Monitor Summary
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: I18n.isEs ? "󰍹 PANTALLA & MONITOR" : "󰍹 DISPLAY & MONITOR"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.6
                            color: Theme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: displayCard.currentMonitor
                                + (displayCard.currentResStr !== "" ? (" • " + displayCard.currentResStr) : "")
                                + " • " + displayCard.currentRefresh + "Hz • " + Math.round(displayCard.currentScale * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textSecondary
                        }
                    }

                    // Row 1: Monitor Selector Pills (visible only when >1 display connected)
                    Rectangle {
                        visible: displayCard.monitorsList.length > 1
                        Layout.fillWidth: true
                        implicitHeight: 26
                        radius: 8
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2

                            Repeater {
                                model: displayCard.monitorsList

                                Rectangle {
                                    id: monBtn
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    readonly property bool isSel: modelData.name === displayCard.currentMonitor
                                    color: isSel ? Theme.accentDim : (monBtnArea.containsMouse ? Theme.bgHover : "transparent")
                                    border.color: isSel ? Theme.accentBorder : "transparent"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Rectangle {
                                            visible: Boolean(modelData.focused)
                                            implicitWidth: 5
                                            implicitHeight: 5
                                            radius: 3
                                            color: Theme.accent
                                        }

                                        Text {
                                            text: modelData.name + " (" + modelData.refresh + "Hz)"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: monBtn.isSel ? Theme.textPrimary : Theme.textSecondary
                                        }
                                    }

                                    MouseArea {
                                        id: monBtnArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: displayCard.selectedMonitorName = modelData.name
                                    }
                                }
                            }
                        }
                    }

                    // Row 2: Per-Monitor Scale Presets
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 8
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2

                            Repeater {
                                model: [
                                    { label: "AUTO", val: 0.0,  isAuto: true },
                                    { label: "100%", val: 1.0,  isAuto: false },
                                    { label: "125%", val: 1.25, isAuto: false },
                                    { label: "150%", val: 1.5,  isAuto: false },
                                    { label: "175%", val: 1.75, isAuto: false },
                                    { label: "200%", val: 2.0,  isAuto: false }
                                ]

                                Rectangle {
                                    id: scaleBtn
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    readonly property bool isActive: modelData.isAuto ? displayCard.isAutoScale : (!displayCard.isAutoScale && Math.abs(displayCard.currentScale - modelData.val) < 0.05)
                                    color: isActive ? Theme.accentDim : (scaleBtnArea.containsMouse ? Theme.bgHover : "transparent")
                                    border.color: isActive ? Theme.accentBorder : "transparent"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: scaleBtn.isActive ? Theme.textPrimary : Theme.textSecondary
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

                    // Row 3: Per-Monitor Refresh Rate (Hz) + VRR Mode
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 8
                            color: Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 2
                                spacing: 2

                                Repeater {
                                    model: displayCard.currentRates

                                    Rectangle {
                                        id: rateBtn
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 6
                                        readonly property bool isActive: Math.abs(displayCard.currentRefresh - Number(modelData.hz)) <= 1
                                        color: isActive ? Theme.accentDim : (rateBtnArea.containsMouse ? Theme.bgHover : "transparent")
                                        border.color: isActive ? Theme.accentBorder : "transparent"
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: rateBtn.isActive ? Theme.textPrimary : Theme.textSecondary
                                        }

                                        MouseArea {
                                            id: rateBtnArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: displayCard.applyRate(modelData.mode)
                                        }
                                    }
                                }
                            }
                        }

                        // Compact VRR 3-state selector (OFF / ON / FULL)
                        Rectangle {
                            id: vrrBtn
                            implicitHeight: 26
                            implicitWidth: vrrLbl.implicitWidth + 16
                            radius: 8
                            readonly property bool vrrOn: displayCard.vrrMode > 0
                            color: vrrOn ? Theme.accentDim : (vrrArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                            border.color: vrrOn ? Theme.accentBorder : Theme.borderSubtle
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            Text {
                                id: vrrLbl
                                anchors.centerIn: parent
                                text: displayCard.vrrMode === 0 ? "VRR OFF" : (displayCard.vrrMode === 1 ? "VRR ON" : "VRR FULL")
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: vrrBtn.vrrOn ? Theme.accent : Theme.textSecondary
                            }

                            MouseArea {
                                id: vrrArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: displayCard.cycleVrr()
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 5B. X64 AI HUB & SCRATCHPAD ENGINE SELECTOR (SUPER + S / SUPER + A)
            // =================================================================
            Rectangle {
                id: aiEngineCard
                Layout.fillWidth: true
                implicitHeight: 68
                radius: Theme.radiusMd
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
                            text: I18n.isEs ? "󰚩 AGENTE IA SCRATCHPAD" : "󰚩 AI SCRATCHPAD AGENT"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.6
                            color: Theme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            implicitWidth: openAiLbl.implicitWidth + 10
                            implicitHeight: 16
                            radius: 5
                            color: openAiArea.containsMouse ? Theme.accentDim : Theme.bgElevated
                            border.color: openAiArea.containsMouse ? Theme.accentBorder : Theme.borderSubtle
                            border.width: 1

                            Text {
                                id: openAiLbl
                                anchors.centerIn: parent
                                text: I18n.isEs ? "Abrir (SUPER+S) 󰁔" : "Open (SUPER+S) 󰁔"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: openAiArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            }

                            MouseArea {
                                id: openAiArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    controlWindow.closeRequested();
                                    controlWindow.runCtl(["scratchpad"]);
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 8
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: 2

                            Repeater {
                                model: [
                                    { id: "opencode", label: "OpenCode" },
                                    { id: "chatgpt",  label: "ChatGPT" },
                                    { id: "claude",   label: "Claude" },
                                    { id: "gemini",   label: "Gemini" },
                                    { id: "deepseek", label: "DeepSeek" },
                                    { id: "terminal", label: "Kitty" }
                                ]

                                Rectangle {
                                    id: aiBtn
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    readonly property bool isActive: controlWindow.aiEngine === modelData.id
                                    color: isActive ? Theme.accentDim : (aiBtnArea.containsMouse ? Theme.bgHover : "transparent")
                                    border.color: isActive ? Theme.accentBorder : "transparent"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 140 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme.fontSans
                                        font.pixelSize: 9
                                        font.bold: aiBtn.isActive
                                        color: aiBtn.isActive ? Theme.textPrimary : Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: aiBtnArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            SysState.guardToggle();
                                            SysState.aiEngine = modelData.id;
                                            controlWindow.runCtl(["ai-engine", "set", modelData.id]);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 6. COMPACT 4-COLUMN QUICK APP LAUNCHER ROW
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { icon: "󰄛", label: "Terminal", cmd: "kitty" },
                        { icon: "󰉋", label: I18n.filesDolphin, cmd: "dolphin" },
                        { icon: "󰍛", label: "Btop", cmd: "kitty -e btop" },
                        { icon: "󰍜", label: "Hello", cmd: "x64-hello" }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 46
                        radius: 10
                        color: appArea.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: appArea.containsMouse ? "#28ffffff" : Theme.borderSubtle
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 130 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                color: appArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.label
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: appArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: appArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlWindow.launchApp(modelData.cmd);
                            }
                        }
                    }
                }
            }
            }
        }
    }
}
