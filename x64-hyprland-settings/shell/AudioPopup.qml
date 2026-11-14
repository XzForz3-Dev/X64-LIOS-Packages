import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire

PanelWindow {
    id: audioWindow

    signal closeRequested()

    property string activeTab: "sinks"
    property bool overdrive: false

    property var sinks: []
    property var sources: []
    property var streams: []

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    readonly property real sinkVol: (defaultSink && defaultSink.audio) ? defaultSink.audio.volume : 0.0
    readonly property bool sinkMuted: (defaultSink && defaultSink.audio) ? defaultSink.audio.muted : false

    readonly property real srcVol: (defaultSource && defaultSource.audio) ? defaultSource.audio.volume : 0.0
    readonly property bool srcMuted: (defaultSource && defaultSource.audio) ? defaultSource.audio.muted : false

    // Track default devices for Quickshell telemetry
    PwObjectTracker {
        objects: {
            var list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
            return list;
        }
    }

    // Native Peak Monitor for Mic VU Meter
    PwNodePeakMonitor {
        id: micPeakMon
        node: Pipewire.defaultAudioSource
        enabled: audioWindow.visible && audioWindow.activeTab === "sources"
    }

    anchors {
        top: true
        right: true
    }

    margins {
        top: 36
        right: 48
    }

    implicitWidth: 360
    implicitHeight: Math.min(cardLayout.implicitHeight + 30, (screen ? screen.height : 1080) - 50)

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property bool lockClose: false

    HyprlandFocusGrab {
        id: focusGrab
        active: audioWindow.visible && !audioWindow.lockClose
        windows: [audioWindow]
        onCleared: {
            if (!audioWindow.lockClose && audioWindow.visible) {
                audioWindow.closeAnimated();
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
            duration: 140
            easing.type: Easing.InBack
            easing.overshoot: 1.2
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0.0
            duration: 120
            easing.type: Easing.InQuad
        }
        onFinished: {
            audioWindow.visible = false;
            audioWindow.closeRequested();
        }
    }

    onVisibleChanged: {
        if (visible) {
            card.scale = 0.82;
            card.opacity = 0.0;
            openAnim.restart();
            refreshAudio();
            pollTimer.restart();
        } else {
            pollTimer.stop();
        }
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        running: false
        onTriggered: {
            if (audioWindow.visible && !audioDataProc.running) {
                audioDataProc.running = true;
            }
        }
    }

    Process {
        id: audioDataProc
        command: ["/usr/bin/x64-hyprland-ctl", "audio", "data"]
        stdout: StdioCollector {
            id: audioDataCollector
            onStreamFinished: {
                if (!audioDataCollector.text) return;
                try {
                    let json = JSON.parse(audioDataCollector.text.trim());
                    if (json.sinks) audioWindow.sinks = json.sinks;
                    if (json.sources) audioWindow.sources = json.sources;
                    if (json.streams) audioWindow.streams = json.streams;
                    if (json.overdrive !== undefined) audioWindow.overdrive = Boolean(json.overdrive);
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: audioCmdProc
        stdout: StdioCollector {
            id: audioCmdCollector
            onStreamFinished: {
                audioWindow.refreshAudio();
            }
        }
    }

    Process {
        id: appLaunchProc
        command: ["/bin/sh", "-c"]
        running: false
    }

    function refreshAudio() {
        if (!audioDataProc.running) {
            audioDataProc.running = true;
        }
    }

    function runAudioCmd(args) {
        audioCmdProc.command = ["/usr/bin/x64-hyprland-ctl", "audio"].concat(args);
        audioCmdProc.running = true;
    }

    function launchApp(bin) {
        appLaunchProc.command = ["/bin/sh", "-c", "setsid -f " + bin + " >/dev/null 2>&1 &"];
        appLaunchProc.running = true;
    }

    // Obsidian Glass Container
    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.bgCard
        radius: Theme.radiusLg
        border.color: Theme.borderGlass
        border.width: 1
        clip: true

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // =========================================================
            // 1. TOP HEADER: TITLE, OVERDRIVE SWITCH & REFRESH
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 7
                    height: 7
                    radius: 4
                    color: Theme.statusOk
                }

                Text {
                    text: I18n.audioTitle
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                // Overdrive 150% Boost Pill & Switch
                Rectangle {
                    implicitHeight: 22
                    implicitWidth: boostRow.implicitWidth + 8
                    radius: 11
                    color: audioWindow.overdrive ? Theme.accentDim : Theme.bgElevated
                    border.color: audioWindow.overdrive ? Theme.accentBorder : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        id: boostRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "150%"
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            color: audioWindow.overdrive ? Theme.accent : Theme.textMuted
                        }

                        // Mini Animated Switch Track
                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 14
                            radius: 7
                            color: audioWindow.overdrive ? Theme.accent : "#22242b"

                            Rectangle {
                                width: 10
                                height: 10
                                radius: 5
                                y: 2
                                x: audioWindow.overdrive ? 14 : 2
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            audioWindow.overdrive = !audioWindow.overdrive;
                            audioWindow.runAudioCmd(["toggle-overdrive"]);
                        }
                    }
                }

                // Refresh Button
                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 6
                    color: refArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                    border.color: Theme.borderSubtle
                    border.width: 1

                    Text {
                        id: refIcon
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: audioDataProc.running ? Theme.accent : (refArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                        RotationAnimation {
                            target: refIcon
                            running: audioDataProc.running
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 700
                        }
                    }

                    MouseArea {
                        id: refArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: audioWindow.refreshAudio()
                    }
                }
            }

            // =========================================================
            // 2. TAB SELECTOR PILLS
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { id: "sinks",   icon: "󰕾", label: I18n.audioTabSinks },
                        { id: "sources", icon: "󰍬", label: I18n.audioTabSources },
                        { id: "streams", icon: "󰎆", label: I18n.audioTabStreams, count: audioWindow.streams ? audioWindow.streams.length : 0 }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 26
                        radius: 7
                        readonly property bool isSelected: audioWindow.activeTab === modelData.id
                        color: isSelected ? Theme.accentDim : (tabArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                        border.color: isSelected ? Theme.accentBorder : Theme.borderSubtle
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 140 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: isSelected ? Theme.accent : (tabArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                            }

                            Text {
                                text: modelData.label
                                font.family: Theme.fontSans
                                font.pixelSize: 9
                                font.bold: isSelected
                                color: isSelected ? Theme.textPrimary : Theme.textSecondary
                            }

                            Rectangle {
                                visible: Boolean(modelData.count && modelData.count > 0)
                                implicitWidth: 14
                                implicitHeight: 14
                                radius: 7
                                color: isSelected ? Theme.accent : Theme.bgCard
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.count ? String(modelData.count) : "0"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: isSelected ? "#ffffff" : Theme.textSecondary
                                }
                            }
                        }

                        MouseArea {
                            id: tabArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: audioWindow.activeTab = modelData.id
                        }
                    }
                }
            }

            // =========================================================
            // 3. TAB 1: OUTPUT DEVICES (SINKS)
            // =========================================================
            ColumnLayout {
                visible: audioWindow.activeTab === "sinks"
                Layout.fillWidth: true
                spacing: 10

                // Active Output Master Slider Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 80
                    radius: Theme.radiusMd
                    color: Theme.bgElevated
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: audioWindow.sinkMuted ? "󰝟" : (audioWindow.sinkVol > 1.0 ? "󰓃" : "󰕾")
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                color: audioWindow.sinkMuted ? Theme.accent : (audioWindow.sinkVol > 1.0 ? Theme.accent : Theme.statusOk)
                            }

                            Text {
                                text: audioWindow.defaultSink ? (audioWindow.defaultSink.description || audioWindow.defaultSink.name || "Altavoces") : "Dispositivo de Salida"
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: audioWindow.sinkMuted ? "MUT" : (Math.round(audioWindow.sinkVol * 100) + "%" + (audioWindow.sinkVol > 1.0 ? " BOOST" : ""))
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: audioWindow.sinkMuted ? Theme.accent : (audioWindow.sinkVol > 1.0 ? Theme.accent : Theme.textPrimary)
                            }
                        }

                        // Master Volume Slider Track
                        Rectangle {
                            id: sinkSliderTrack
                            Layout.fillWidth: true
                            implicitHeight: 22
                            radius: 6
                            color: "#0a0b10"
                            border.color: Theme.borderSubtle
                            border.width: 1
                            clip: true

                            // Active Fill
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                readonly property real maxLimit: audioWindow.overdrive ? 1.5 : 1.0
                                width: Math.max(0, Math.min(parent.width, (audioWindow.sinkVol / maxLimit) * parent.width))
                                radius: 5
                                color: audioWindow.sinkMuted ? "#451a1a" : (audioWindow.sinkVol > 1.0 ? Theme.accent : "#34d399")
                                Behavior on width { NumberAnimation { duration: 60 } }
                            }

                            // 100% Mark Line when Overdrive is enabled
                            Rectangle {
                                visible: audioWindow.overdrive
                                width: 1
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                x: Math.round(parent.width * (1.0 / 1.5))
                                color: "#44ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                function setVol(mx) {
                                    let maxL = audioWindow.overdrive ? 1.5 : 1.0;
                                    let ratio = Math.max(0.0, Math.min(maxL, (mx / sinkSliderTrack.width) * maxL));
                                    if (audioWindow.defaultSink && audioWindow.defaultSink.audio) {
                                        audioWindow.defaultSink.audio.volume = ratio;
                                        if (audioWindow.defaultSink.audio.muted && ratio > 0.01) {
                                            audioWindow.defaultSink.audio.muted = false;
                                        }
                                    }
                                }
                                onClicked: (mouse) => setVol(mouse.x)
                                onPositionChanged: (mouse) => {
                                    if (pressed) setVol(mouse.x);
                                }
                                onWheel: (wheel) => {
                                    if (audioWindow.defaultSink && audioWindow.defaultSink.audio) {
                                        let maxL = audioWindow.overdrive ? 1.5 : 1.0;
                                        let step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                                        audioWindow.defaultSink.audio.volume = Math.max(0.0, Math.min(maxL, audioWindow.defaultSink.audio.volume + step));
                                    }
                                }
                            }
                        }
                    }
                }

                // Available Output Devices List
                Text {
                    text: I18n.audioOutputDevices.toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.letterSpacing: 1
                    color: Theme.textMuted
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: audioWindow.sinks

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 7
                            color: modelData.isDefault ? Theme.bgElevated : (sinkRowArea.containsMouse ? Theme.bgHover : "#0affffff")
                            border.color: modelData.isDefault ? Theme.borderGlass : Theme.borderSubtle
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: modelData.icon || "󰕾"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: modelData.isDefault ? Theme.statusOk : Theme.textSecondary
                                }

                                Text {
                                    text: modelData.description || modelData.name
                                    font.family: Theme.fontSans
                                    font.pixelSize: 10
                                    font.bold: modelData.isDefault
                                    color: modelData.isDefault ? Theme.textPrimary : Theme.textSecondary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.volume + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }

                                Item {
                                    implicitWidth: 18
                                    implicitHeight: 18

                                    Text {
                                        visible: modelData.isDefault
                                        anchors.centerIn: parent
                                        text: "󰄬"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.statusOk
                                    }

                                    Text {
                                        visible: !modelData.isDefault && sinkRowArea.containsMouse
                                        anchors.centerIn: parent
                                        text: "󰁕"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: Theme.accent
                                    }
                                }
                            }

                            MouseArea {
                                id: sinkRowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    audioWindow.runAudioCmd(["set-sink", modelData.name]);
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 4. TAB 2: INPUT DEVICES & VU METER (SOURCES)
            // =========================================================
            ColumnLayout {
                visible: audioWindow.activeTab === "sources"
                Layout.fillWidth: true
                spacing: 10

                // Active Mic & Gain Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 110
                    radius: Theme.radiusMd
                    color: Theme.bgElevated
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: audioWindow.srcMuted ? "󰍭" : "󰍬"
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                color: audioWindow.srcMuted ? Theme.accent : Theme.statusOk
                            }

                            Text {
                                text: audioWindow.defaultSource ? (audioWindow.defaultSource.description || audioWindow.defaultSource.name || "Micrófono") : "Micrófono"
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Mute Toggle Button
                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: 44
                                radius: 5
                                color: audioWindow.srcMuted ? Theme.accentDim : Theme.bgCard
                                border.color: audioWindow.srcMuted ? Theme.accentBorder : Theme.borderSubtle
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: audioWindow.srcMuted ? "MUT" : Math.round(audioWindow.srcVol * 100) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: audioWindow.srcMuted ? Theme.accent : Theme.textPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (audioWindow.defaultSource && audioWindow.defaultSource.audio) {
                                            audioWindow.defaultSource.audio.muted = !audioWindow.defaultSource.audio.muted;
                                        }
                                    }
                                }
                            }
                        }

                        // Gain Slider
                        Rectangle {
                            id: srcSliderTrack
                            Layout.fillWidth: true
                            implicitHeight: 20
                            radius: 5
                            color: "#0a0b10"
                            border.color: Theme.borderSubtle
                            border.width: 1
                            clip: true

                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: Math.max(0, Math.min(parent.width, audioWindow.srcVol * parent.width))
                                radius: 4
                                color: audioWindow.srcMuted ? "#451a1a" : "#38bdf8"
                                Behavior on width { NumberAnimation { duration: 60 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                function setVol(mx) {
                                    let ratio = Math.max(0.0, Math.min(1.0, mx / srcSliderTrack.width));
                                    if (audioWindow.defaultSource && audioWindow.defaultSource.audio) {
                                        audioWindow.defaultSource.audio.volume = ratio;
                                        if (audioWindow.defaultSource.audio.muted && ratio > 0.01) {
                                            audioWindow.defaultSource.audio.muted = false;
                                        }
                                    }
                                }
                                onClicked: (mouse) => setVol(mouse.x)
                                onPositionChanged: (mouse) => {
                                    if (pressed) setVol(mouse.x);
                                }
                            }
                        }

                        // Dynamic Real-time Voice VU Meter
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "󰻠 " + I18n.audioVuMeter
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                color: Theme.textMuted
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: audioWindow.srcMuted ? "MUT" : (micPeakMon.peak > 0.85 ? "CLIP" : (micPeakMon.peak > 0.05 ? "ACTIVO" : "SILENCIO"))
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: audioWindow.srcMuted ? Theme.accent : (micPeakMon.peak > 0.85 ? Theme.accent : (micPeakMon.peak > 0.05 ? Theme.statusOk : Theme.textMuted))
                            }
                        }

                        // VU Meter Physical Bar
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 8
                            radius: 4
                            color: "#0a0b10"
                            border.color: Theme.borderSubtle
                            border.width: 1
                            clip: true

                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: Math.max(0, Math.min(parent.width, (micPeakMon.peak * 2.2) * parent.width))
                                radius: 3
                                color: audioWindow.srcMuted ? "transparent" : (micPeakMon.peak > 0.85 ? Theme.accent : (micPeakMon.peak > 0.60 ? "#fbbf24" : Theme.statusOk))
                                Behavior on width { NumberAnimation { duration: 50 } }
                            }
                        }
                    }
                }

                // Available Input Devices List
                Text {
                    text: I18n.audioInputDevices.toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.letterSpacing: 1
                    color: Theme.textMuted
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: audioWindow.sources

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 7
                            color: modelData.isDefault ? Theme.bgElevated : (srcRowArea.containsMouse ? Theme.bgHover : "#0affffff")
                            border.color: modelData.isDefault ? Theme.borderGlass : Theme.borderSubtle
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: modelData.icon || "󰍬"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: modelData.isDefault ? Theme.statusOk : Theme.textSecondary
                                }

                                Text {
                                    text: modelData.description || modelData.name
                                    font.family: Theme.fontSans
                                    font.pixelSize: 10
                                    font.bold: modelData.isDefault
                                    color: modelData.isDefault ? Theme.textPrimary : Theme.textSecondary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.volume + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }

                                Item {
                                    implicitWidth: 18
                                    implicitHeight: 18

                                    Text {
                                        visible: modelData.isDefault
                                        anchors.centerIn: parent
                                        text: "󰄬"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: Theme.statusOk
                                    }

                                    Text {
                                        visible: !modelData.isDefault && srcRowArea.containsMouse
                                        anchors.centerIn: parent
                                        text: "󰁕"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: Theme.accent
                                    }
                                }
                            }

                            MouseArea {
                                id: srcRowArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    audioWindow.runAudioCmd(["set-source", modelData.name]);
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 5. TAB 3: APPLICATION VOLUME STREAMS (MIXER)
            // =========================================================
            ColumnLayout {
                visible: audioWindow.activeTab === "streams"
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: I18n.audioAppMixer.toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.letterSpacing: 1
                    color: Theme.textMuted
                }

                // Empty State
                Rectangle {
                    visible: !audioWindow.streams || audioWindow.streams.length === 0
                    Layout.fillWidth: true
                    implicitHeight: 80
                    radius: Theme.radiusMd
                    color: Theme.bgElevated
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰝟"
                            font.family: Theme.fontMono
                            font.pixelSize: 22
                            color: Theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.audioNoStreams
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            color: Theme.textSecondary
                        }
                    }
                }

                // Active App Streams
                ColumnLayout {
                    visible: audioWindow.streams && audioWindow.streams.length > 0
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: audioWindow.streams

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 56
                            radius: Theme.radiusMd
                            color: Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7

                                    Text {
                                        text: "󰎆"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: modelData.muted ? Theme.accent : Theme.textPrimary
                                    }

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.textPrimary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.muted ? "MUT" : (modelData.volume + "%")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: modelData.muted ? Theme.accent : Theme.textSecondary
                                    }

                                    Rectangle {
                                        implicitWidth: 20
                                        implicitHeight: 20
                                        radius: 4
                                        color: modelData.muted ? Theme.accentDim : Theme.bgCard
                                        border.color: modelData.muted ? Theme.accentBorder : Theme.borderSubtle
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.muted ? "󰝟" : "󰕾"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                            color: modelData.muted ? Theme.accent : Theme.textSecondary
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                audioWindow.runAudioCmd(["toggle-stream-mute", String(modelData.index)]);
                                            }
                                        }
                                    }
                                }

                                // Stream Volume Slider
                                Rectangle {
                                    id: stSliderTrack
                                    Layout.fillWidth: true
                                    implicitHeight: 16
                                    radius: 4
                                    color: "#0a0b10"
                                    border.color: Theme.borderSubtle
                                    border.width: 1
                                    clip: true

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        width: Math.max(0, Math.min(parent.width, (modelData.volume / 100.0) * parent.width))
                                        radius: 3
                                        color: modelData.muted ? "#451a1a" : "#a855f7"
                                        Behavior on width { NumberAnimation { duration: 60 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        function setVol(mx) {
                                            let pct = Math.round(Math.max(0, Math.min(100, (mx / stSliderTrack.width) * 100)));
                                            audioWindow.runAudioCmd(["set-stream-volume", String(modelData.index), String(pct)]);
                                        }
                                        onClicked: (mouse) => setVol(mouse.x)
                                        onPositionChanged: (mouse) => {
                                            if (pressed) setVol(mouse.x);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 6. ADVANCED AUDIO SETTINGS BUTTON (pavucontrol)
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 10
                color: advAudioArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                border.color: advAudioArea.containsMouse ? "#28ffffff" : Theme.borderSubtle
                border.width: 1
                Behavior on color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰒓"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: advAudioArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                    Text {
                        text: I18n.audioAdvancedSettings
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: advAudioArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: advAudioArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        audioWindow.launchApp("pavucontrol");
                    }
                }
            }
        }
    }
}
