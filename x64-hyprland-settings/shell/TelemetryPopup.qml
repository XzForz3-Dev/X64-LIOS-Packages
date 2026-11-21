import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: teleWindow

    signal closeRequested()

    readonly property int cpuUsage: SysState.cpuUsage
    readonly property int cpuTemp: SysState.cpuTemp
    readonly property string cpuModel: SysState.cpuModel
    readonly property int cpuCores: SysState.cpuCores
    readonly property string cpuFreq: SysState.cpuFreq
    readonly property string loadAvg: SysState.loadAvg
    readonly property var cpuHistory: SysState.cpuHistory

    readonly property string ramUsed: SysState.ramUsed
    readonly property string ramTotal: SysState.ramTotal
    readonly property int ramPct: SysState.ramPct
    readonly property string ramCached: SysState.ramCached
    readonly property string swapUsed: SysState.swapUsed
    readonly property string swapTotal: SysState.swapTotal

    readonly property string diskUsed: SysState.diskUsed
    readonly property string diskTotal: SysState.diskTotal
    readonly property string diskFree: SysState.diskFree
    readonly property string diskFs: SysState.diskFs
    readonly property int diskPct: SysState.diskPct

    readonly property string netDown: SysState.netDown
    readonly property string netUp: SysState.netUp
    readonly property string netIp: SysState.netIp
    readonly property string netIface: SysState.netIface

    readonly property var cpuCoresLoad: SysState.cpuCoresLoad

    readonly property string kernelVer: SysState.kernelVer
    readonly property string uptimeStr: SysState.uptimeStr
    readonly property int gpuCount: SysState.gpuCount
    readonly property int gpuTemp: SysState.gpuTemp
    readonly property int gpuUtil: SysState.gpuUtil
    readonly property var gpus: SysState.gpus
    property var topList: []

    anchors {
        top: true
        right: true
    }

    margins {
        top: 44
        right: 175
    }

    implicitWidth: 430
    implicitHeight: cardLayout.implicitHeight + 30

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"

    property bool lockClose: false

    HyprlandFocusGrab {
        id: focusGrab
        active: teleWindow.visible && !teleWindow.lockClose
        windows: [teleWindow]
        onCleared: {
            if (!teleWindow.lockClose && teleWindow.visible) {
                teleWindow.closeAnimated();
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
        onFinished: teleWindow.closeRequested()
    }

    Process {
        id: teleAppProc
    }

    function launchApp(cmdStr) {
        teleWindow.closeRequested();
        if (teleAppProc.running) {
            teleAppProc.running = false;
        }
        teleAppProc.command = ["bash", "-c", "nohup " + cmdStr + " >/dev/null 2>&1 &"];
        teleAppProc.running = true;
    }

    Connections {
        target: SysState
        function onTopListUpdated(list) {
            if (!teleWindow.visible) return;
            if (typeof procListView !== "undefined" && procListView && procListView.applyNewList) {
                procListView.applyNewList(list);
            } else {
                teleWindow.topList = list;
            }
        }
    }

    onVisibleChanged: {
        SysState.telemetryOpen = visible;
        if (visible) {
            if (SysState.topList && SysState.topList.length > 0) {
                teleWindow.topList = SysState.topList;
            }
            card.scale = 0.82;
            card.y = -24;
            card.opacity = 0.0;
            openAnim.restart();
        } else {
            card.scale = 1.0;
            card.y = 0;
            card.opacity = 1.0;
            if (typeof procListView !== "undefined" && procListView) {
                procListView.stickyY = 0;
                procListView.contentY = 0;
            }
        }
    }

    // Telemetry Cockpit Card pinned below Island 3A with Jelly / Elastic Physics
    Rectangle {
        id: card
        anchors.fill: parent
        transformOrigin: Item.TopRight
        layer.enabled: openAnim.running || closeAnim.running
        layer.smooth: true
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

                            Shape {
                                id: cpuGaugeCanvas
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                property int val: teleWindow.cpuUsage

                                ShapePath {
                                    strokeWidth: 4.5
                                    strokeColor: "#14ffffff"
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    PathAngleArc {
                                        centerX: 27; centerY: 27
                                        radiusX: 22; radiusY: 22
                                        startAngle: 0; sweepAngle: 360
                                    }
                                }

                                ShapePath {
                                    strokeWidth: 4.5
                                    strokeColor: cpuGaugeCanvas.val >= 85 ? Theme.accent : (cpuGaugeCanvas.val >= 65 ? Theme.statusWarn : "#d8d6d0")
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    PathAngleArc {
                                        centerX: 27; centerY: 27
                                        radiusX: 22; radiusY: 22
                                        startAngle: -90
                                        sweepAngle: Math.max(7.2, Math.min(360, cpuGaugeCanvas.val * 3.6))
                                    }
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

                            Shape {
                                id: ramGaugeCanvas
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                property int val: teleWindow.ramPct

                                ShapePath {
                                    strokeWidth: 4.5
                                    strokeColor: "#14ffffff"
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    PathAngleArc {
                                        centerX: 27; centerY: 27
                                        radiusX: 22; radiusY: 22
                                        startAngle: 0; sweepAngle: 360
                                    }
                                }

                                ShapePath {
                                    strokeWidth: 4.5
                                    strokeColor: ramGaugeCanvas.val >= 85 ? Theme.accent : (ramGaugeCanvas.val >= 70 ? Theme.statusWarn : "#d8d6d0")
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    PathAngleArc {
                                        centerX: 27; centerY: 27
                                        radiusX: 22; radiusY: 22
                                        startAngle: -90
                                        sweepAngle: Math.max(7.2, Math.min(360, ramGaugeCanvas.val * 3.6))
                                    }
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

                            Shape {
                                id: diskGaugeCanvas
                                anchors.fill: parent
                                preferredRendererType: Shape.CurveRenderer
                                property int val: teleWindow.diskPct

                                ShapePath {
                                    strokeWidth: 4.5
                                    strokeColor: "#14ffffff"
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    PathAngleArc {
                                        centerX: 27; centerY: 27
                                        radiusX: 22; radiusY: 22
                                        startAngle: 0; sweepAngle: 360
                                    }
                                }

                                ShapePath {
                                    strokeWidth: 4.5
                                    strokeColor: diskGaugeCanvas.val >= 90 ? Theme.accent : (diskGaugeCanvas.val >= 75 ? Theme.statusWarn : "#d8d6d0")
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    PathAngleArc {
                                        centerX: 27; centerY: 27
                                        radiusX: 22; radiusY: 22
                                        startAngle: -90
                                        sweepAngle: Math.max(7.2, Math.min(360, diskGaugeCanvas.val * 3.6))
                                    }
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
            // 2. PROCESSOR DETAIL & REAL-TIME PER-CORE MONITOR
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 84
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

                    // Per-Core Realtime Load Bars (C1..Cn)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: teleWindow.cpuCoresLoad.length > 0 ? teleWindow.cpuCoresLoad : teleWindow.cpuCores
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                spacing: 2

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 2
                                    color: Theme.bgElevated

                                    Rectangle {
                                        width: parent.width
                                        height: Math.max(2, parent.height * (Math.min(100, (typeof modelData === "number" ? modelData : 0)) / 100.0))
                                        anchors.bottom: parent.bottom
                                        radius: 2
                                        color: modelData >= 85 ? Theme.accent : (modelData >= 65 ? Theme.statusWarn : "#c8c6c0")
                                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "C" + (index + 1)
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    color: Theme.textMuted
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 2B. DEDICATED GRAPHICS & VRAM (MULTI-GPU / SLI ENGINE)
            // =========================================================
            Rectangle {
                visible: teleWindow.gpuCount > 0
                Layout.fillWidth: true
                implicitHeight: gpuInnerCol.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    id: gpuInnerCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Card Header: Icon, Label & SLI Badge
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "󰢮"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: Theme.textSecondary
                        }

                        Text {
                            text: teleWindow.gpuCount > 1 ? (I18n.isEs ? "GRÁFICOS DUAL (SLI)" : "DUAL GPU (SLI)") : (I18n.isEs ? "GRÁFICOS DEDICADOS" : "DEDICATED GPU")
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1.0
                            color: Theme.textSecondary
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: teleWindow.gpuCount > 1
                            implicitHeight: 18
                            implicitWidth: sliBadgeRow.implicitWidth + 10
                            radius: 9
                            color: Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1

                            RowLayout {
                                id: sliBadgeRow
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: "2x SLI"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: Theme.textSecondary
                                }
                            }
                        }
                    }

                    // Multi-GPU (Dual/SLI) Grid: 2 columns
                    RowLayout {
                        id: gpuLayoutMulti
                        visible: teleWindow.gpuCount > 1
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: teleWindow.gpus
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 58
                                radius: Theme.radiusSm
                                color: Theme.bgElevated
                                border.color: (modelData.temp >= 78 || modelData.util >= 85) ? Theme.borderAccent : Theme.borderSubtle
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 5

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "GPU " + modelData.index + (modelData.index === 0 ? " (Master)" : " (Slave)")
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.textPrimary
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: modelData.temp + "°C"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: modelData.temp >= 78 ? Theme.accent : (modelData.temp >= 65 ? Theme.statusWarn : Theme.textSecondary)
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: (I18n.isEs ? "Carga: " : "Load: ") + modelData.util + "%"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: modelData.util >= 85 ? Theme.accent : (modelData.util >= 65 ? Theme.statusWarn : Theme.textMuted)
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: "VRAM: " + modelData.vramUsed + (modelData.vramTotal ? (" / " + modelData.vramTotal) : "")
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textMuted
                                        }
                                    }

                                    // VRAM Usage Progress Bar (Monochromatic neutral silver at rest)
                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 4
                                        radius: 2
                                        color: "#20ffffff"

                                        Rectangle {
                                            width: Math.max(3, parent.width * (Math.min(100, modelData.vramPct) / 100.0))
                                            height: parent.height
                                            radius: 2
                                            color: modelData.vramPct >= 85 ? Theme.accent : (modelData.vramPct >= 65 ? Theme.statusWarn : "#c8c6c0")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Single GPU Layout (if 1 GPU)
                    ColumnLayout {
                        id: gpuLayoutSingle
                        visible: teleWindow.gpuCount === 1
                        Layout.fillWidth: true
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: teleWindow.gpus.length > 0 ? teleWindow.gpus[0].name : "NVIDIA GPU"
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: (teleWindow.gpus.length > 0 ? teleWindow.gpus[0].temp : 0) + "°C • " + (teleWindow.gpus.length > 0 ? teleWindow.gpus[0].util : 0) + "% Load"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: teleWindow.gpuTemp >= 78 ? Theme.accent : (teleWindow.gpuTemp >= 65 ? Theme.statusWarn : Theme.textSecondary)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "VRAM: " + (teleWindow.gpus.length > 0 ? (teleWindow.gpus[0].vramUsed + " / " + teleWindow.gpus[0].vramTotal) : "0 GB")
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: (teleWindow.gpus.length > 0 ? teleWindow.gpus[0].vramPct : 0) + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.textMuted
                            }
                        }

                        // VRAM Progress Bar (Monochromatic neutral silver at rest)
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: "#20ffffff"

                            Rectangle {
                                width: Math.max(3, parent.width * (Math.min(100, (teleWindow.gpus.length > 0 ? teleWindow.gpus[0].vramPct : 0)) / 100.0))
                                height: parent.height
                                radius: 2
                                color: (teleWindow.gpus.length > 0 && teleWindow.gpus[0].vramPct >= 85) ? Theme.accent : ((teleWindow.gpus.length > 0 && teleWindow.gpus[0].vramPct >= 65) ? Theme.statusWarn : "#c8c6c0")
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 3. TOP 5 ACTIVE PROCESSES TABLE (Clean Monochromatic)
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: topProcCol.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    id: topProcCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.rightMargin: 6
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

                    ListView {
                        id: procListView
                        Layout.fillWidth: true
                        implicitHeight: 147
                        clip: true
                        spacing: 3
                        boundsBehavior: Flickable.StopAtBounds
                        model: teleWindow.topList

                        property real stickyY: 0
                        property bool updatingModel: false

                        onContentYChanged: {
                            if (!updatingModel) {
                                stickyY = Math.max(0, contentY);
                            }
                        }

                        function applyNewList(newList) {
                            if (procScrollBar && procScrollBar.pressed) {
                                return;
                            }
                            if (moving || dragging || flicking) {
                                return;
                            }
                            updatingModel = true;
                            let savedY = stickyY;
                            teleWindow.topList = newList;
                            contentY = Math.min(savedY, Math.max(0, contentHeight - height));
                            Qt.callLater(() => {
                                contentY = Math.min(savedY, Math.max(0, contentHeight - height));
                                updatingModel = false;
                            });
                        }

                        ScrollBar.vertical: ScrollBar {
                            id: procScrollBar
                            policy: procListView.count > 6 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            implicitWidth: 4
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: procScrollBar.pressed ? Theme.accent : (procScrollBar.hovered ? Theme.textPrimary : Theme.textMuted)
                            }
                            background: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: Theme.borderSubtle
                            }
                        }

                        delegate: Item {
                            width: procListView.width - (procScrollBar.visible ? 8 : 0)
                            height: 22

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: (index + 1) + "."
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                    Layout.preferredWidth: 22
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
                                    Layout.preferredWidth: 46
                                    horizontalAlignment: Text.AlignRight
                                }
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
                        teleWindow.launchApp("kitty -e btop");
                    }
                }
            }
        }
    }
}
