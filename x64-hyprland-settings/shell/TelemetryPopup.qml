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
    property string cpuModel: "X64 Processor"
    property int cpuCores: 4
    property string cpuFreq: "3.60 GHz"
    property string loadAvg: "0.10"
    property var cpuHistory: [4, 6, 5, 8, 7, 10, 6, 5, 9, 7, 6, 8, 5, 7, 6, 8, 10, 7, 6, 5]

    property string ramUsed: "0.0"
    property string ramTotal: "8.0"
    property int ramPct: 0
    property string ramCached: "0.0"
    property string swapUsed: "0.0"
    property string swapTotal: "0.0"

    property string diskUsed: "0G"
    property string diskTotal: "0G"
    property string diskFree: "0G"
    property string diskFs: "BTRFS"
    property int diskPct: 0

    property string netDown: "0 KB/s"
    property string netUp: "0 KB/s"
    property string netIp: "127.0.0.1"
    property string netIface: "eth0"

    property string kernelVer: "Linux"
    property string uptimeStr: "0m"
    property var topList: [
        { "name": "quickshell", "cpu": "1.2%", "mem": "115 MB" },
        { "name": "Hyprland",   "cpu": "0.8%", "mem": "92 MB" },
        { "name": "systemd",    "cpu": "0.1%", "mem": "24 MB" }
    ]

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
                    var c = data.cpu || 0;
                    teleWindow.cpuUsage = c;
                    teleWindow.cpuTemp = data.temp || 40;
                    if (data.cpuModel) teleWindow.cpuModel = data.cpuModel;
                    if (data.cpuCores) teleWindow.cpuCores = data.cpuCores;
                    if (data.cpuFreq) teleWindow.cpuFreq = data.cpuFreq;
                    if (data.loadAvg) teleWindow.loadAvg = data.loadAvg;

                    // Update rolling 20-sample sparkline history
                    var hist = teleWindow.cpuHistory.slice(1);
                    hist.push(Math.max(4, Math.min(100, c)));
                    teleWindow.cpuHistory = hist;

                    teleWindow.ramUsed = data.ramUsed || "0.0";
                    teleWindow.ramTotal = data.ramTotal || "0.0";
                    teleWindow.ramPct = data.ramPct || 0;
                    teleWindow.ramCached = data.ramCached || "0.0";
                    teleWindow.swapUsed = data.swapUsed || "0.0";
                    teleWindow.swapTotal = data.swapTotal || "0.0";

                    teleWindow.diskUsed = data.diskUsed || "0G";
                    teleWindow.diskTotal = data.diskTotal || "0G";
                    teleWindow.diskFree = data.diskFree || "0G";
                    teleWindow.diskFs = data.diskFs || "BTRFS";
                    teleWindow.diskPct = data.diskPct || 0;

                    teleWindow.netDown = data.netDown || "0 KB/s";
                    teleWindow.netUp = data.netUp || "0 KB/s";
                    teleWindow.netIp = data.netIp || "Local";
                    teleWindow.netIface = data.netIface || "LAN";

                    if (data.kernel) teleWindow.kernelVer = data.kernel;
                    teleWindow.uptimeStr = data.uptime || "0m";
                    if (data.topList && data.topList.length > 0) {
                        teleWindow.topList = data.topList;
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 1200
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

    // Telemetry Cockpit Card pinned below Island 3A
    Rectangle {
        id: card
        width: 370
        height: cardLayout.implicitHeight + 30
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 4
            rightMargin: 175
        }
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        // Consume inside clicks
        MouseArea {
            anchors.fill: parent
        }

        // Top Neon Crimson Accent Line
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: 24
                rightMargin: 24
            }
            height: 2
            radius: 1
            color: Theme.accent
        }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 15
            spacing: 9

            // =========================================================
            // HEADER: TITLE, KERNEL BADGE & UPTIME
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "󰻠 TELEMETRÍA X64"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.accent
                    }
                    Text {
                        text: "󰣇 Kernel " + teleWindow.kernelVer
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitHeight: 22
                    implicitWidth: upRow.implicitWidth + 14
                    radius: 11
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        id: upRow
                        anchors.centerIn: parent
                        spacing: 5
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

            // =========================================================
            // 1. CPU, CORES/FREQ, TEMPERATURE & LIVE SPARKLINE
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 84
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

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

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: teleWindow.cpuModel
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: teleWindow.cpuCores + " Cores • " + teleWindow.cpuFreq + " • Load " + teleWindow.loadAvg
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        // Main CPU progress bar
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

                        // 20-Sample Live History Sparkline Bars
                        Row {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter
                            Repeater {
                                model: teleWindow.cpuHistory
                                delegate: Rectangle {
                                    width: 3
                                    height: 14
                                    radius: 1
                                    color: "#1a1b24"

                                    Rectangle {
                                        width: parent.width
                                        height: Math.max(2, parent.height * (modelData / 100.0))
                                        anchors.bottom: parent.bottom
                                        radius: 1
                                        color: modelData > 75 ? "#ff2b2b" : Theme.accent
                                        opacity: 0.45 + 0.55 * (index / 20.0)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 2. RAM MEMORY + ZRAM / SWAP & CACHE
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

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

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "ZRAM / Swap: " + teleWindow.swapUsed + "G / " + teleWindow.swapTotal + "G"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Caché: " + teleWindow.ramCached + "G"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
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

            // =========================================================
            // 3. NVMe ROOT STORAGE + FILESYSTEM & FREE SPACE
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

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

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Sistema: " + teleWindow.diskFs
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: teleWindow.diskFree + " disponibles"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textSecondary
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

            // =========================================================
            // 4. LIVE NETWORK THROUGHPUT (RX / TX) & IP ADDRESS
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: "󰈀 Red (" + teleWindow.netIface + ")"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: "IP: " + teleWindow.netIp
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Download Pill
                    Rectangle {
                        implicitHeight: 22
                        implicitWidth: rxRow.implicitWidth + 12
                        radius: 6
                        color: "#1410b981"
                        border.color: "#3310b981"
                        border.width: 1
                        RowLayout {
                            id: rxRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "󰇚"; font.family: Theme.fontMono; font.pixelSize: 10; color: "#10b981" }
                            Text { text: teleWindow.netDown; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: "#10b981" }
                        }
                    }

                    // Upload Pill
                    Rectangle {
                        implicitHeight: 22
                        implicitWidth: txRow.implicitWidth + 12
                        radius: 6
                        color: "#1438bdf8"
                        border.color: "#3338bdf8"
                        border.width: 1
                        RowLayout {
                            id: txRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "󰕒"; font.family: Theme.fontMono; font.pixelSize: 10; color: "#38bdf8" }
                            Text { text: teleWindow.netUp; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: "#38bdf8" }
                        }
                    }
                }
            }

            // =========================================================
            // 5. TOP 3 ACTIVE PROCESSES TABLE (CPU % + RAM MB)
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 86
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "PROCESOS ACTIVOS (TOP RECURSOS)"
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "RAM   •   CPU"
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.textMuted
                        }
                    }

                    Repeater {
                        model: teleWindow.topList
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: (index + 1) + "."
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accent
                            }

                            Text {
                                text: modelData.name || "proc"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.mem || "0 MB"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: "#00e5ff"
                            }

                            Text {
                                text: modelData.cpu || "0.0%"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accent
                                Layout.preferredWidth: 38
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 6. LAUNCH BTOP BUTTON
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
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
