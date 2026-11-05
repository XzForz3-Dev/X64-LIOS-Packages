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
        right: true
    }

    margins {
        top: 36
        right: 175
    }

    implicitWidth: 370
    implicitHeight: cardLayout.implicitHeight + 30

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"

    HyprlandFocusGrab {
        active: teleWindow.visible
        windows: [teleWindow]
        onCleared: teleWindow.closeAnimated()
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
        onFinished: teleWindow.closeRequested()
    }

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

    onVisibleChanged: {
        if (visible) {
            if (!statusProc.running) statusProc.running = true;
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

    // Telemetry Cockpit Card pinned below Island 3A with Jelly / Elastic Physics
    Rectangle {
        id: card
        anchors.fill: parent
        transformOrigin: Item.TopRight
        scale: 1.0
        opacity: 1.0
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

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
                    RowLayout {
                        spacing: 6
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.accent
                        }
                        Text {
                            text: I18n.isEs ? "TELEMETRÍA" : "TELEMETRY"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.1
                            color: Theme.textSecondary
                        }
                    }
                    Text {
                        text: "Kernel " + teleWindow.kernelVer
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
                        Text { text: "󰅐"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textSecondary }
                        Text { text: teleWindow.uptimeStr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textSecondary }
                    }
                }
            }

            // =========================================================
            // 1. THREE CIRCULAR RING GAUGES (CPU, RAM, DISCO)
            // Monochromatic Silver at rest; Amber/Crimson only on high load
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // --- Ring 1: CPU ---
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 106
                    radius: Theme.radiusMd
                    color: Theme.bgCard
                    border.color: teleWindow.cpuUsage >= 85 ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: 54
                            height: 54

                            Canvas {
                                id: cpuGaugeCanvas
                                anchors.fill: parent
                                property int val: teleWindow.cpuUsage
                                onValChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var cx = width / 2;
                                    var cy = height / 2;
                                    var r = 22;
                                    ctx.lineWidth = 4.5;
                                    ctx.lineCap = "round";

                                    // Background ring
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                                    ctx.strokeStyle = "rgba(255, 255, 255, 0.08)";
                                    ctx.stroke();

                                    // Value arc
                                    var pct = Math.max(0.02, Math.min(1.0, val / 100.0));
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (Math.PI * 2 * pct);
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, startAngle, endAngle);
                                    ctx.strokeStyle = val >= 85 ? "#ff2b2b" : (val >= 65 ? "#f5a524" : "#d8d6d0");
                                    ctx.stroke();
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: teleWindow.cpuUsage + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: teleWindow.cpuUsage >= 85 ? Theme.accent : (teleWindow.cpuUsage >= 65 ? Theme.statusWarn : Theme.textPrimary)
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "CPU"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: teleWindow.cpuTemp + "°C"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: teleWindow.cpuTemp >= 78 ? Theme.accent : (teleWindow.cpuTemp >= 65 ? Theme.statusWarn : Theme.textMuted)
                        }
                    }
                }

                // --- Ring 2: RAM ---
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 106
                    radius: Theme.radiusMd
                    color: Theme.bgCard
                    border.color: teleWindow.ramPct >= 85 ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: 54
                            height: 54

                            Canvas {
                                id: ramGaugeCanvas
                                anchors.fill: parent
                                property int val: teleWindow.ramPct
                                onValChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var cx = width / 2;
                                    var cy = height / 2;
                                    var r = 22;
                                    ctx.lineWidth = 4.5;
                                    ctx.lineCap = "round";

                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                                    ctx.strokeStyle = "rgba(255, 255, 255, 0.08)";
                                    ctx.stroke();

                                    var pct = Math.max(0.02, Math.min(1.0, val / 100.0));
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (Math.PI * 2 * pct);
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, startAngle, endAngle);
                                    ctx.strokeStyle = val >= 85 ? "#ff2b2b" : (val >= 70 ? "#f5a524" : "#d8d6d0");
                                    ctx.stroke();
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: teleWindow.ramPct + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: teleWindow.ramPct >= 85 ? Theme.accent : (teleWindow.ramPct >= 70 ? Theme.statusWarn : Theme.textPrimary)
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "RAM"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: teleWindow.ramUsed + " / " + teleWindow.ramTotal + "G"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }
                }

                // --- Ring 3: DISCO ---
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 106
                    radius: Theme.radiusMd
                    color: Theme.bgCard
                    border.color: teleWindow.diskPct >= 90 ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: 54
                            height: 54

                            Canvas {
                                id: diskGaugeCanvas
                                anchors.fill: parent
                                property int val: teleWindow.diskPct
                                onValChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var cx = width / 2;
                                    var cy = height / 2;
                                    var r = 22;
                                    ctx.lineWidth = 4.5;
                                    ctx.lineCap = "round";

                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                                    ctx.strokeStyle = "rgba(255, 255, 255, 0.08)";
                                    ctx.stroke();

                                    var pct = Math.max(0.02, Math.min(1.0, val / 100.0));
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (Math.PI * 2 * pct);
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, startAngle, endAngle);
                                    ctx.strokeStyle = val >= 90 ? "#ff2b2b" : (val >= 75 ? "#f5a524" : "#d8d6d0");
                                    ctx.stroke();
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: teleWindow.diskPct + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: teleWindow.diskPct >= 90 ? Theme.accent : (teleWindow.diskPct >= 75 ? Theme.statusWarn : Theme.textPrimary)
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.isEs ? "DISCO" : "DISK"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: teleWindow.diskUsed + " / " + teleWindow.diskTotal
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }
                }
            }

            // =========================================================
            // 2. PROCESSOR DETAIL & LIVE SPARKLINE CARD
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: teleWindow.cpuModel
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
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

                    // 20-Sample Live History Sparkline Bars (Full Width)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Repeater {
                            model: teleWindow.cpuHistory
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                radius: 2
                                color: Theme.bgElevated

                                Rectangle {
                                    width: parent.width
                                    height: Math.max(3, parent.height * (modelData / 100.0))
                                    anchors.bottom: parent.bottom
                                    radius: 2
                                    color: modelData >= 80 ? Theme.accent : (modelData >= 60 ? Theme.statusWarn : "#c8c6c0")
                                    opacity: 0.35 + 0.65 * (index / 20.0)
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 3. LIVE NETWORK THROUGHPUT (RX / TX) & IP ADDRESS
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰈀"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }

                    Text {
                        text: teleWindow.netIface + " • " + teleWindow.netIp
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    // Download Badge (Monochromatic)
                    Rectangle {
                        implicitHeight: 22
                        implicitWidth: rxRow.implicitWidth + 12
                        radius: 6
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1
                        RowLayout {
                            id: rxRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "↓"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textSecondary }
                            Text { text: teleWindow.netDown; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textPrimary }
                        }
                    }

                    // Upload Badge (Monochromatic)
                    Rectangle {
                        implicitHeight: 22
                        implicitWidth: txRow.implicitWidth + 12
                        radius: 6
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1
                        RowLayout {
                            id: txRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "↑"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                            Text { text: teleWindow.netUp; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textSecondary }
                        }
                    }
                }
            }

            // =========================================================
            // 4. TOP 3 ACTIVE PROCESSES TABLE (Clean Monochromatic)
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 88
                radius: Theme.radiusMd
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
                            text: I18n.teleActiveProcesses
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textMuted
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "RAM   •   CPU"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
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
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }

                            Text {
                                text: modelData.name || "proc"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.mem || "0 MB"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textSecondary
                            }

                            Text {
                                text: modelData.cpu || "0.0%"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.preferredWidth: 42
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 5. LAUNCH BTOP BUTTON
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 10
                color: btopArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: btopArea.containsMouse ? "#28ffffff" : Theme.borderSubtle
                border.width: 1
                Behavior on color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰍛"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: btopArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                    Text {
                        text: I18n.teleOpenBtop
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: btopArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
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
