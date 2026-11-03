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

    PwObjectTracker {
        objects: {
            var list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
            return list;
        }
    }

    onVisibleChanged: {
        if (visible) {
            displayCard.refreshScale();
        }
    }

    Component.onCompleted: {
        displayCard.refreshScale();
    }

    // Outside click dismiss backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: controlWindow.closeRequested()
    }

    // Control Center Card pinned to top right
    Rectangle {
        id: card
        width: 360
        height: 560
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
            anchors.margins: 18
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "CENTRO DE CONTROL"
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.accent
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "󰅖"
                    font.family: Theme.fontMono
                    font.pixelSize: 15
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

            // Quick App Actions
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // Kitty Terminal
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Theme.radiusSm
                    color: termArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: termArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text { text: "󰄛"; font.family: Theme.fontMono; font.pixelSize: 16; color: Theme.accent }
                        Text { text: "Terminal Kitty"; font.family: Theme.fontSans; font.pixelSize: 12; color: Theme.textPrimary }
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
                    implicitHeight: 44
                    radius: Theme.radiusSm
                    color: dolphArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: dolphArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text { text: "󰉋"; font.family: Theme.fontMono; font.pixelSize: 16; color: Theme.accent }
                        Text { text: "Archivos"; font.family: Theme.fontSans; font.pixelSize: 12; color: Theme.textPrimary }
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
                    implicitHeight: 44
                    radius: Theme.radiusSm
                    color: helloArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: helloArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text { text: "󰍜"; font.family: Theme.fontMono; font.pixelSize: 16; color: Theme.accent }
                        Text { text: "X64 Hello"; font.family: Theme.fontSans; font.pixelSize: 12; color: Theme.textPrimary }
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
                    implicitHeight: 44
                    radius: Theme.radiusSm
                    color: monArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: monArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text { text: "󰍛"; font.family: Theme.fontMono; font.pixelSize: 16; color: Theme.accent }
                        Text { text: "Monitor Btop"; font.family: Theme.fontSans; font.pixelSize: 12; color: Theme.textPrimary }
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

            // Pipewire Audio Slider Card
            Rectangle {
                id: audioCard
                Layout.fillWidth: true
                implicitHeight: 76
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                readonly property var sink: Pipewire.defaultAudioSink
                readonly property real vol: sink && sink.audio ? sink.audio.volume : 0.0
                readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: audioCard.isMuted ? "󰝟 Audio Silenciado" : "󰕾 Volumen Principal"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: true
                            color: audioCard.isMuted ? Theme.accent : Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: audioCard.isMuted ? "MUTE" : Math.round(audioCard.vol * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: Theme.accent
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        value: audioCard.vol
                        onMoved: {
                            if (audioCard.sink && audioCard.sink.audio) {
                                audioCard.sink.audio.volume = value;
                            }
                        }
                    }
                }
            }

            // Display & Monitor Scaling Card (Sovereign Scaling Engine)
            Rectangle {
                id: displayCard
                Layout.fillWidth: true
                implicitHeight: 88
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                property real currentScale: 1.0
                property string currentMonitor: "Virtual-1"

                Process {
                    id: scaleQueryProc
                    command: ["x64-hyprland-scale", "current"]
                    stdout: StdioCollector {
                        id: scaleCollector
                        onStreamFinished: {
                            if (!scaleCollector.text) return;
                            var s = parseFloat(scaleCollector.text.trim());
                            if (!isNaN(s) && s > 0) displayCard.currentScale = s;
                        }
                    }
                }

                Process {
                    id: monQueryProc
                    command: ["x64-hyprland-scale", "monitor"]
                    stdout: StdioCollector {
                        id: monCollector
                        onStreamFinished: {
                            if (!monCollector.text) return;
                            var m = monCollector.text.trim();
                            if (m !== "") displayCard.currentMonitor = m;
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
                    if (!scaleQueryProc.running) scaleQueryProc.running = true;
                    if (!monQueryProc.running) monQueryProc.running = true;
                }

                function applyScale(sVal) {
                    displayCard.currentScale = sVal;
                    scaleApplyProc.command = ["x64-hyprland-scale", String(sVal)];
                    scaleApplyProc.running = true;
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "󰍹 Pantalla & Escalado"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: displayCard.currentMonitor + " (" + Math.round(displayCard.currentScale * 100) + "%)"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accent
                        }
                    }

                    // Quick Scale Preset Pills
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "100%", val: 1.0 },
                                { label: "125%", val: 1.25 },
                                { label: "150%", val: 1.5 },
                                { label: "200%", val: 2.0 }
                            ]

                            Rectangle {
                                id: scaleBtn
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Theme.radiusSm
                                readonly property bool isActive: Math.abs(displayCard.currentScale - modelData.val) < 0.05
                                color: isActive ? Theme.accentDim : (scaleBtnArea.containsMouse ? Theme.bgHover : Theme.bgGlass)
                                border.color: isActive ? Theme.accent : (scaleBtnArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle)
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: scaleBtn.isActive ? Theme.textPrimary : (scaleBtnArea.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                                }

                                MouseArea {
                                    id: scaleBtnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: displayCard.applyScale(modelData.val)
                                }
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Session / Power Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Lock
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: lockArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰌾"; font.family: Theme.fontMono; font.pixelSize: 14; color: Theme.textPrimary }
                        Text { text: "Bloquear"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.textPrimary }
                    }

                    MouseArea {
                        id: lockArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.exec_cmd("loginctl lock-session")');
                            controlWindow.closeRequested();
                        }
                    }
                }

                // Reboot
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: rebootArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰑓"; font.family: Theme.fontMono; font.pixelSize: 14; color: Theme.textPrimary }
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
                    implicitHeight: 38
                    radius: Theme.radiusSm
                    color: offArea.containsMouse ? Theme.accent : Theme.bgCard
                    border.color: offArea.containsMouse ? Theme.accentLight : Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "󰐥"; font.family: Theme.fontMono; font.pixelSize: 14; color: offArea.containsMouse ? Theme.textPrimary : Theme.accent }
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
