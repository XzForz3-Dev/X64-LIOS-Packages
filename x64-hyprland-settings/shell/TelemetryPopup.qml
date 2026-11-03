import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: teleWindow

    signal closeRequested()

    property int cpuUsage: 0
    property int cpuTemp: 40
    property string ramUsed: "0.0"
    property string ramTotal: "8.0"
    property int ramPct: 0
    property string diskUsed: "0G"
    property string diskTotal: "0G"
    property int diskPct: 0
    property string uptimeStr: "0m"
    property string topProcs: "Hyprland • quickshell"

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

    Process {
        id: statusProc
        command: ["x64-hyprland-ctl", "status"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: {
                if (!statusCollector.text) return;
                try {
                    var data = JSON.parse(statusCollector.text.trim());
                    teleWindow.cpuUsage = data.cpu || 0;
                    teleWindow.cpuTemp = data.temp || 40;
                    teleWindow.ramUsed = data.ramUsed || "0.0";
                    teleWindow.ramTotal = data.ramTotal || "0.0";
                    teleWindow.ramPct = data.ramPct || 0;
                    teleWindow.diskUsed = data.diskUsed || "0G";
                    teleWindow.diskTotal = data.diskTotal || "0G";
                    teleWindow.diskPct = data.diskPct || 0;
                    teleWindow.uptimeStr = data.uptime || "0m";
                    teleWindow.topProcs = data.topProcs || "Sistema inactivo";
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1500
        running: teleWindow.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statusProc.running) statusProc.running = true;
        }
    }

    // Outside click dismiss backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: teleWindow.closeRequested()
    }

    // Telemetry Card pinned below Island 3A
    Rectangle {
        id: card
        width: 340
        height: 368
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 4
            rightMargin: 190
        }
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        // Consume inside clicks
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "󰻠 TELEMETRÍA X64"
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.accent
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitHeight: 20
                    implicitWidth: upRow.implicitWidth + 12
                    radius: 10
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        id: upRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "󰅐"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.accent }
                        Text { text: teleWindow.uptimeStr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textSecondary }
                    }
                }

                Text {
                    text: "󰅖"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: Theme.textMuted
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: teleWindow.closeRequested()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            // 1. CPU & Temperature Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 62
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
                            text: "󰻠 Procesador (CPU)"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "󰔏 " + teleWindow.cpuTemp + "°C"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: teleWindow.cpuTemp >= 78 ? "#ff2b2b" : (teleWindow.cpuTemp >= 65 ? "#ffaa00" : "#ff7744")
                        }
                        Text {
                            text: " • " + teleWindow.cpuUsage + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accent
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#1a1b24"

                        Rectangle {
                            width: Math.max(4, parent.width * Math.min(1.0, teleWindow.cpuUsage / 100.0))
                            height: parent.height
                            radius: 3
                            color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // 2. RAM Memory Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 62
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
                            text: "󰍛 Memoria RAM"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: teleWindow.ramUsed + "G / " + teleWindow.ramTotal + "G (" + teleWindow.ramPct + "%)"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: "#00e5ff"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#1a1b24"

                        Rectangle {
                            width: Math.max(4, parent.width * Math.min(1.0, teleWindow.ramPct / 100.0))
                            height: parent.height
                            radius: 3
                            color: "#00e5ff"
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // 3. NVMe Root Storage Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 62
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
                            text: "󰋊 Disco del Sistema (/)"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: teleWindow.diskUsed + " / " + teleWindow.diskTotal + " (" + teleWindow.diskPct + "%)"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: "#a855f7"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 6
                        radius: 3
                        color: "#1a1b24"

                        Rectangle {
                            width: Math.max(4, parent.width * Math.min(1.0, teleWindow.diskPct / 100.0))
                            height: parent.height
                            radius: 3
                            color: "#a855f7"
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // 4. Top Processes Strip
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    Text {
                        text: "PROCESOS ACTIVOS (TOP CPU)"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: Theme.textMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: teleWindow.topProcs
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                    }
                }
            }

            // 5. Launch Btop Button
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: Theme.radiusSm
                color: btopArea.containsMouse ? Theme.accent : Theme.bgCard
                border.color: btopArea.containsMouse ? Theme.accentLight : Theme.borderAccent
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰍛"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: btopArea.containsMouse ? "#ffffff" : Theme.accent
                    }
                    Text {
                        text: "Abrir Monitor Completo (Btop)"
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                MouseArea {
                    id: btopArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch('hl.dsp.exec_cmd("kitty -e btop")');
                        teleWindow.closeRequested();
                    }
                }
            }
        }
    }
}

