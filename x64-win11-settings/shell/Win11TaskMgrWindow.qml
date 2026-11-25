import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 980
    height: 650
    color: "#191919"
    focus: true

    property string activeTab: (typeof initialArg !== "undefined" && (initialArg === "startup" || initialArg === "performance")) ? initialArg : "processes" // "processes" | "performance" | "startup"
    property string perfSubTab: "cpu"      // "cpu" | "ram" | "disk" | "net" | "gpu_0" | "gpu_1" ...
    property bool cpuShowPerCore: false
    property int historyTick: 0
    property bool telemetryPaused: false
    property string procFilter: ""
    property string procSortKey: "cpu"     // "cpu" | "mem" | "name" | "pid" | "threads"
    property bool procSortDesc: true
    property string selectedPid: ""
    property var selectedProcObj: null
    property bool newTaskBarOpen: false
    property bool procCtxOpen: false
    property real procCtxX: 200
    property real procCtxY: 200
    property bool procPropsOpen: false
    property var procPropsObj: null

    // Startup Apps State
    property var startupApps: []
    property string startupFilter: ""
    property string startupSortKey: "status" // "name" | "publisher" | "status" | "impact"
    property bool startupSortAsc: true
    property string selectedStartupId: ""
    property var selectedStartupObj: null
    property bool startupCtxOpen: false
    property real startupCtxX: 200
    property real startupCtxY: 200
    property bool startupAddOpen: false
    property bool startupPropsOpen: false
    property var startupPropsObj: null
    property var installedAppsList: []
    property string statusToastText: ""

    property var sysInfo: ({
        "cpu": "Procesador x86_64",
        "cpuCores": 8,
        "cpuPhysCores": 4,
        "cpuPerCore": [4, 4, 4, 4],
        "cpuGhz": "3.20 GHz",
        "cpuMaxGhz": "4.00 GHz",
        "cpuTemp": "—",
        "cpuCache": "—",
        "cpuVirt": "Habilitada",
        "cpuPct": 6,
        "ram": "4.0 / 16.0 GB (25%)",
        "ramShort": "4.0/16 GB",
        "ramPct": 25,
        "ramUsedGb": 4.0,
        "ramTotalGb": 16.0,
        "ramAvailGb": 12.0,
        "ramCachedGb": 1.2,
        "swapUsedGb": 0.0,
        "swapTotalGb": 8.0,
        "swapPct": 0,
        "uptime": "0:01:00:00",
        "procCount": 180,
        "threadCount": 720,
        "sched": "scx_lavd",
        "kernel": "Linux",
        "disks": [
            { "id": "disk_0", "blk": "nvme0n1", "label": "Disco 0 (C:)", "titleLabel": "Disco 0 (C:) — SSD", "model": "Unidad del sistema", "type": "SSD", "fs": "BTRFS", "ioSched": "adios", "totalGb": 256.0, "freeGb": 100.0, "freeStr": "100.0 GB", "usedPct": 18, "activePct": 0, "readStr": "0.0 MB/s", "writeStr": "0.0 MB/s", "mounted": true, "subUsage": "18% ocupado" }
        ],
        "diskLabel": "Disco 0 (C:) — SSD",
        "diskModel": "Unidad del sistema",
        "diskType": "SSD",
        "diskFs": "BTRFS",
        "diskIoSched": "adios",
        "diskPct": 18,
        "diskActivePct": 0,
        "diskReadStr": "0.0 MB/s",
        "diskWriteStr": "0.0 MB/s",
        "diskFreeGb": 100.0,
        "diskTotalGb": 256.0,
        "diskInfo": "Unidad del sistema",
        "netIface": "wlan0",
        "netType": "Wi-Fi",
        "netIp": "—",
        "netMac": "—",
        "netRecvKbs": 0,
        "netSendKbs": 0,
        "netRecvStr": "0 KB/s",
        "netSendStr": "0 KB/s",
        "netPct": 0,
        "netTotalRecvStr": "0.00 GB",
        "netTotalSentStr": "0.00 GB",
        "gpus": [
            { "id": "gpu_0", "label": "GPU 0", "name": "Adaptador gráfico", "pct": 0, "temp": "—", "vramUsedMb": 0, "vramTotalMb": 0, "vramPct": 0, "vramStr": "Compartida", "driver": "DRM/KMS", "busId": "—" }
        ],
        "gpuName": "Adaptador gráfico",
        "gpuPct": 0,
        "gpuTemp": "—",
        "gpuVramUsedMb": 0,
        "gpuVramTotalMb": 0,
        "gpuVramStr": "Compartida",
        "gpuDriver": "DRM/KMS",
        "procs": []
    })

    property var cpuHistory: [2, 3, 4, 3, 4, 3, 2, 3, 4, 3, 3, 4, 3, 2, 3, 4, 3, 3, 4, 3]
    property var ramHistory: [20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20]
    property var diskHistories: ({ "disk_0": [0, 0, 1, 0, 0, 2, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0] })
    property var netRecvHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var netSendHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property var gpuHistories: ({ "gpu_0": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] })

    readonly property bool isDiskPerfTab: root.perfSubTab === "disk" || root.perfSubTab.indexOf("disk_") === 0
    readonly property var activeDiskObj: {
        var list = root.sysInfo.disks || [];
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === root.perfSubTab) return list[i];
        }
        return list.length > 0 ? list[0] : ({ id: "disk_0", label: "Disco 0 (C:)", titleLabel: "Disco 0 (C:) — SSD", model: "Unidad del sistema", type: "SSD", fs: "BTRFS", ioSched: "adios", totalGb: 0, freeStr: "—", usedPct: 0, activePct: 0, readStr: "0.0 MB/s", writeStr: "0.0 MB/s", mounted: true, subUsage: "—" });
    }

    readonly property bool isGpuPerfTab: root.perfSubTab.indexOf("gpu_") === 0
    readonly property var activeGpuObj: {
        var list = root.sysInfo.gpus || [];
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === root.perfSubTab) return list[i];
        }
        return list.length > 0 ? list[0] : ({ id: "gpu_0", label: "GPU 0", name: "Adaptador gráfico", pct: 0, temp: "—", vramUsedMb: 0, vramTotalMb: 0, vramPct: 0, vramStr: "Compartida", driver: "DRM/KMS", busId: "—" });
    }

    readonly property bool compactRail: root.width < 760

    Timer {
        id: toastTimer
        interval: 2600; repeat: false
        onTriggered: root.statusToastText = ""
    }

    function showToast(msg) {
        statusToastText = msg;
        toastTimer.restart();
    }

    Keys.onPressed: (event) => {
        if (tmSearch.activeFocus || newTaskInput.activeFocus || startupSearch.activeFocus || addNameIn.activeFocus || addCmdIn.activeFocus) return;
        if (event.key === Qt.Key_Delete && activeTab === "processes" && selectedPid !== "") {
            execProcCtxAction("kill");
            event.accepted = true;
        } else if (event.key === Qt.Key_F5) {
            refreshTelemetry();
            if (activeTab === "startup") refreshStartupApps();
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N && activeTab === "processes") {
            newTaskBarOpen = true;
            newTaskInput.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            procCtxOpen = false;
            startupCtxOpen = false;
            procPropsOpen = false;
            startupPropsOpen = false;
            startupAddOpen = false;
            newTaskBarOpen = false;
            event.accepted = true;
        }
    }

    component WinSvg : Image {
        property string iconFile: "taskmgr.svg"
        property string iconUrl: ""
        Layout.preferredWidth: width
        Layout.preferredHeight: height
        Layout.maximumWidth: width
        Layout.maximumHeight: height
        source: iconUrl !== "" ? iconUrl : (assetDirUrl + iconFile)
        sourceSize.width: Math.max(24, Math.round(width * 2))
        sourceSize.height: Math.max(24, Math.round(height * 2))
        fillMode: Image.PreserveAspectFit
        mipmap: true
        smooth: true
        antialiasing: true
    }

    readonly property var sortedFilteredProcs: {
        var src = (root.sysInfo.procs || []).slice();
        var q = root.procFilter.trim().toLowerCase();
        if (q !== "") {
            var tmp = [];
            for (var i = 0; i < src.length; i++) {
                var p = src[i];
                if (String(p.name || "").toLowerCase().indexOf(q) !== -1 ||
                    String(p.pid || "").indexOf(q) !== -1 ||
                    String(p.cmdline || "").toLowerCase().indexOf(q) !== -1) {
                    tmp.push(p);
                }
            }
            src = tmp;
        }
        var mul = root.procSortDesc ? 1 : -1;
        if (root.procSortKey === "mem") {
            src.sort(function(a, b) { return mul * ((b.memNum || 0) - (a.memNum || 0)); });
        } else if (root.procSortKey === "name") {
            src.sort(function(a, b) { return (root.procSortDesc ? -1 : 1) * String(a.name || "").localeCompare(String(b.name || "")); });
        } else if (root.procSortKey === "pid") {
            src.sort(function(a, b) { return mul * (Number(b.pid || 0) - Number(a.pid || 0)); });
        } else if (root.procSortKey === "threads") {
            src.sort(function(a, b) { return mul * (Number(b.threads || 0) - Number(a.threads || 0)); });
        } else {
            src.sort(function(a, b) { return mul * ((b.cpuNum || 0) - (a.cpuNum || 0)); });
        }
        return src;
    }

    readonly property var sortedFilteredStartup: {
        var src = (root.startupApps || []).slice();
        var q = root.startupFilter.trim().toLowerCase();
        if (q !== "") {
            var out = [];
            for (var i = 0; i < src.length; i++) {
                var s = src[i];
                if (String(s.name || "").toLowerCase().indexOf(q) !== -1 ||
                    String(s.execCmd || "").toLowerCase().indexOf(q) !== -1) {
                    out.push(s);
                }
            }
            src = out;
        }
        var mul = root.startupSortAsc ? 1 : -1;
        if (root.startupSortKey === "name") {
            src.sort(function(a, b) { return mul * String(a.name || "").localeCompare(String(b.name || "")); });
        } else if (root.startupSortKey === "publisher") {
            src.sort(function(a, b) { return mul * String(a.publisher || "").localeCompare(String(b.publisher || "")); });
        } else if (root.startupSortKey === "impact") {
            var rank = { "Alto": 3, "Medio": 2, "Bajo": 1, "No medido": 0 };
            src.sort(function(a, b) { return mul * ((rank[b.impact] || 0) - (rank[a.impact] || 0)); });
        } else {
            src.sort(function(a, b) {
                if (Boolean(a.enabled) !== Boolean(b.enabled)) return mul * (a.enabled ? -1 : 1);
                return String(a.name || "").localeCompare(String(b.name || ""));
            });
        }
        return src;
    }

    readonly property int enabledStartupCount: {
        var c = 0;
        var arr = root.startupApps || [];
        for (var i = 0; i < arr.length; i++) if (arr[i].enabled) c++;
        return c;
    }

    function toggleProcSort(key) {
        if (procSortKey === key) {
            procSortDesc = !procSortDesc;
        } else {
            procSortKey = key;
            procSortDesc = (key !== "name");
        }
    }

    function toggleStartupSort(key) {
        if (startupSortKey === key) {
            startupSortAsc = !startupSortAsc;
        } else {
            startupSortKey = key;
            startupSortAsc = true;
        }
    }

    function refreshStartupApps() {
        try {
            startupApps = JSON.parse(bridge.getStartupAppsJson());
            if (selectedStartupId !== "") {
                var found = null;
                for (var i = 0; i < startupApps.length; i++) {
                    if (startupApps[i].id === selectedStartupId) { found = startupApps[i]; break; }
                }
                selectedStartupObj = found;
                if (!found) selectedStartupId = "";
            }
        } catch (e) {}
    }

    function toggleStartupItem(itemObj) {
        if (!itemObj || !itemObj.id) return;
        var nextEn = !Boolean(itemObj.enabled);
        if (bridge.setStartupAppEnabled(itemObj.id, nextEn)) {
            refreshStartupApps();
            showToast(itemObj.name + (nextEn ? " habilitada en el inicio" : " deshabilitada en el inicio"));
        }
    }

    function execProcCtxAction(act) {
        var obj = selectedProcObj;
        var pid = selectedPid;
        procCtxOpen = false;
        if (!pid) return;
        if (act === "kill") {
            if (bridge.killProcess(pid)) {
                showToast("Proceso finalizado (" + (obj ? obj.name : pid) + ")");
                selectedPid = "";
                selectedProcObj = null;
                refreshTelemetry();
            } else {
                showToast("No se puede finalizar un proceso crítico del sistema");
            }
        } else if (act === "kill_tree") {
            if (bridge.killProcessTree(pid)) {
                showToast("Árbol de procesos finalizado (" + (obj ? obj.name : pid) + ")");
                selectedPid = "";
                selectedProcObj = null;
                refreshTelemetry();
            } else {
                showToast("No se puede finalizar un proceso protegido");
            }
        } else if (act === "open_loc") {
            if (!bridge.openProcessLocation(pid)) {
                showToast("No se pudo abrir la ubicación del ejecutable");
            }
        } else if (act === "copy_pid") {
            bridge.copyTextToClipboard(String(pid));
            showToast("PID " + pid + " copiado");
        } else if (act === "copy_cmd" && obj) {
            bridge.copyTextToClipboard(String(obj.cmdline || obj.name || ""));
            showToast("Comando copiado al portapapeles");
        } else if (act === "props" && obj) {
            procPropsObj = obj;
            procPropsOpen = true;
        }
    }

    function execStartupCtxAction(act) {
        var obj = selectedStartupObj;
        startupCtxOpen = false;
        if (!obj) return;
        if (act === "toggle") {
            toggleStartupItem(obj);
        } else if (act === "open_loc" && obj.filePath) {
            var parentDir = String(obj.filePath).replace(/\/[^\/]+$/, "");
            bridge.launchRealApp("/usr/bin/x64-win11-app explorer '" + parentDir.replace(/'/g, "'\\''") + "'");
        } else if (act === "remove" && obj.canRemove) {
            if (bridge.removeStartupApp(obj.id)) {
                selectedStartupId = "";
                selectedStartupObj = null;
                refreshStartupApps();
                showToast("Aplicación quitada del inicio");
            }
        } else if (act === "props") {
            startupPropsObj = obj;
            startupPropsOpen = true;
        }
    }

    function refreshTelemetry() {
        try {
            var data = JSON.parse(bridge.getSystemTelemetryJson());
            sysInfo = data;

            var ch = cpuHistory.slice(Math.max(0, cpuHistory.length - 59));
            ch.push(Number(data.cpuPct || 1));
            cpuHistory = ch;

            var rh = ramHistory.slice(Math.max(0, ramHistory.length - 59));
            rh.push(Number(data.ramPct || 10));
            ramHistory = rh;

            var nextDiskHist = Object.assign({}, diskHistories);
            var dList = data.disks || [];
            for (var di = 0; di < dList.length; di++) {
                var did = dList[di].id || ("disk_" + di);
                var prevD = nextDiskHist[did] ? nextDiskHist[did].slice(Math.max(0, nextDiskHist[did].length - 59)) : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                prevD.push(Number(dList[di].activePct || 0));
                nextDiskHist[did] = prevD;
            }
            diskHistories = nextDiskHist;

            var nrh = netRecvHistory.slice(Math.max(0, netRecvHistory.length - 59));
            nrh.push(Math.min(100, Math.round((Number(data.netRecvKbs || 0) / 1024.0) * 100.0)));
            netRecvHistory = nrh;

            var nsh = netSendHistory.slice(Math.max(0, netSendHistory.length - 59));
            nsh.push(Math.min(100, Math.round((Number(data.netSendKbs || 0) / 1024.0) * 100.0)));
            netSendHistory = nsh;

            var nextGpuHist = Object.assign({}, gpuHistories);
            var gList = data.gpus || [];
            for (var gi = 0; gi < gList.length; gi++) {
                var gid = gList[gi].id || ("gpu_" + gi);
                var prevArr = nextGpuHist[gid] ? nextGpuHist[gid].slice(Math.max(0, nextGpuHist[gid].length - 59)) : [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                prevArr.push(Number(gList[gi].pct || 0));
                nextGpuHist[gid] = prevArr;
            }
            gpuHistories = nextGpuHist;
            historyTick += 1;

            if (selectedPid !== "") {
                var arr = data.procs || [];
                for (var i = 0; i < arr.length; i++) {
                    if (arr[i].pid === selectedPid) { selectedProcObj = arr[i]; break; }
                }
            }

            perfCanvas.requestPaint();
            miniCpuCanvas.requestPaint();
            miniRamCanvas.requestPaint();
            miniNetCanvas.requestPaint();
        } catch (e) {}
    }

    Component.onCompleted: {
        refreshStartupApps();
        refreshTelemetry();
        try { installedAppsList = JSON.parse(bridge.getInstalledAppsJson()); } catch (e) {}
    }

    Timer {
        interval: 1500
        running: !root.telemetryPaused
        repeat: true
        onTriggered: root.refreshTelemetry()
    }

    // Reusable Mini Sparkline Canvas component for Performance Sidebar Cards
    component MiniSpark : Canvas {
        property var series: []
        property int repaintTick: 0
        property string strokeColor: "#4cc2ff"
        property string fillColor: "rgba(76, 194, 255, 0.22)"
        width: 56; height: 34
        onRepaintTickChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = "#121212";
            ctx.fillRect(0, 0, width, height);
            ctx.strokeStyle = "rgba(255,255,255,0.12)";
            ctx.lineWidth = 1;
            ctx.strokeRect(0.5, 0.5, width - 1, height - 1);
            if (!series || series.length < 2) return;
            var n = Math.min(24, series.length);
            var start = series.length - n;
            ctx.beginPath();
            for (var i = 0; i < n; i++) {
                var x = (i / Math.max(1, n - 1)) * (width - 2) + 1;
                var v = Math.max(0, Math.min(100, Number(series[start + i] || 0)));
                var y = height - 2 - (v / 100.0) * (height - 4);
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = 1.5;
            ctx.stroke();
            ctx.lineTo(width - 1, height - 1);
            ctx.lineTo(1, height - 1);
            ctx.closePath();
            ctx.fillStyle = fillColor;
            ctx.fill();
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // [A] Responsive Windows 11 26H2 Left Navigation Rail
        Rectangle {
            Layout.preferredWidth: root.compactRail ? 58 : 204
            Layout.fillHeight: true
            color: "#202020"
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                // App Identity Header (Authentic Task Manager Pulse Icon!)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    Layout.leftMargin: root.compactRail ? 8 : 10
                    spacing: 10
                    WinSvg { width: 22; height: 22; iconFile: "taskmgr.svg" }
                    Text {
                        visible: !root.compactRail
                        text: "Admin. tareas"
                        color: "#f5f5f5"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#16ffffff" }
                Item { height: 2 }

                Repeater {
                    model: [
                        { id: "processes",   label: "Procesos",               icon: "fluent-apps-list.svg" },
                        { id: "performance", label: "Rendimiento",            icon: "fluent-task-manager.svg" },
                        { id: "startup",     label: "Aplicaciones de inicio", icon: "fluent-sparkle.svg" }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 6
                        color: root.activeTab === modelData.id ? "#2d2d2d" : (railHov.containsMouse ? "#262626" : "transparent")

                        Rectangle {
                            visible: root.activeTab === modelData.id
                            x: 2; anchors.verticalCenter: parent.verticalCenter
                            width: 3; height: 16; radius: 1.5; color: "#4cc2ff"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.compactRail ? 12 : 12
                            anchors.rightMargin: 8
                            spacing: 12
                            WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                            Text {
                                visible: !root.compactRail
                                text: modelData.label
                                color: "#f2f2f2"
                                font.pixelSize: 12
                                font.weight: root.activeTab === modelData.id ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: railHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = modelData.id;
                                root.procCtxOpen = false;
                                root.startupCtxOpen = false;
                                if (modelData.id === "startup") root.refreshStartupApps();
                                if (modelData.id === "performance") perfCanvas.requestPaint();
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#1cffffff" }

                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 6
                    color: tmCfgHov.containsMouse ? "#262626" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; spacing: 12
                        WinSvg { width: 17; height: 17; iconFile: "fluent-settings.svg" }
                        Text { visible: !root.compactRail; text: "Configuración"; color: "#d8d8d8"; font.pixelSize: 12; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: tmCfgHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app settings 'Sistema'")
                    }
                }
            }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1cffffff" }

        // [B] Main Content Surface
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#191919"
            clip: true

            // =================================================================
            // TAB 1: PROCESOS (Responsive Search + Full Controls + Right-Click Context Menu)
            // =================================================================
            ColumnLayout {
                visible: root.activeTab === "processes"
                anchors.fill: parent
                spacing: 0

                // Top Header & Responsive Command Bar (NEVER overflows search text!)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    color: "#202020"

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 14; spacing: 10

                        Text {
                            visible: root.width >= 660
                            text: "Procesos"
                            color: "#f5f5f5"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }

                        // Clipped Responsive Search Box ("Buscar nombre o PID")
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 120
                            Layout.preferredWidth: 240
                            Layout.maximumWidth: 300
                            height: 32
                            radius: 5
                            clip: true
                            color: tmSearch.activeFocus ? "#161616" : "#2b2b2b"
                            border.color: tmSearch.activeFocus ? "#4cc2ff" : "#22ffffff"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 8; spacing: 7
                                WinSvg { width: 14; height: 14; iconFile: "fluent-search.svg"; opacity: 0.8 }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    Text {
                                        visible: tmSearch.text === ""
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Buscar nombre o PID"
                                        color: "#9a9a9a"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    TextInput {
                                        id: tmSearch
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        selectByMouse: true
                                        clip: true
                                        onTextChanged: root.procFilter = text
                                        Keys.onEscapePressed: { text = ""; root.forceActiveFocus(); }
                                    }
                                }
                                WinSvg {
                                    visible: tmSearch.text !== ""
                                    width: 12; height: 12
                                    iconFile: "fluent-dismiss.svg"
                                    opacity: 0.8
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: tmSearch.text = ""
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true; Layout.minimumWidth: 4 }

                        // Pause / Resume Refresh Toggle
                        Rectangle {
                            width: 32; height: 32; radius: 5
                            color: root.telemetryPaused ? "#384cc2ff" : (pauseHov.containsMouse ? "#363636" : "#2b2b2b")
                            border.color: root.telemetryPaused ? "#4cc2ff" : "#22ffffff"; border.width: 1
                            WinSvg {
                                anchors.centerIn: parent; width: 14; height: 14
                                iconFile: root.telemetryPaused ? "fluent-play-filled.svg" : "fluent-refresh.svg"
                            }
                            MouseArea {
                                id: pauseHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.telemetryPaused = !root.telemetryPaused;
                                    root.showToast(root.telemetryPaused ? "Actualización en pausa" : "Actualización en vivo reanudada");
                                }
                            }
                        }

                        // "Ejecutar nueva tarea" Button (auto-compacts on small windows)
                        Rectangle {
                            readonly property bool compactBtn: root.width < 800
                            width: compactBtn ? 106 : 154; height: 32; radius: 5
                            color: runNewHov.containsMouse ? "#363636" : "#2b2b2b"
                            border.color: "#24ffffff"; border.width: 1
                            RowLayout {
                                anchors.centerIn: parent; spacing: 6
                                WinSvg { width: 14; height: 14; iconFile: "fluent-add.svg" }
                                Text { text: parent.parent.compactBtn ? "Nueva tarea" : "Ejecutar nueva tarea"; color: "#f2f2f2"; font.pixelSize: 12 }
                            }
                            MouseArea {
                                id: runNewHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.newTaskBarOpen = !root.newTaskBarOpen;
                                    if (root.newTaskBarOpen) newTaskInput.forceActiveFocus();
                                }
                            }
                        }

                        // "Finalizar tarea" Button
                        Rectangle {
                            readonly property bool canKill: root.selectedPid !== ""
                            readonly property bool compactBtn: root.width < 800
                            width: compactBtn ? 92 : 122; height: 32; radius: 5
                            color: !canKill ? "#262626" : (endTaskHov.containsMouse ? "#c42b1c" : "#2f2f2f")
                            border.color: canKill ? "#2affffff" : "#18ffffff"; border.width: 1
                            opacity: canKill ? 1.0 : 0.45
                            RowLayout {
                                anchors.centerIn: parent; spacing: 6
                                WinSvg { width: 12; height: 12; iconFile: "fluent-dismiss.svg" }
                                Text { text: parent.parent.compactBtn ? "Finalizar" : "Finalizar tarea"; color: "#ffffff"; font.pixelSize: 12 }
                            }
                            MouseArea {
                                id: endTaskHov; anchors.fill: parent; hoverEnabled: true; enabled: parent.canKill; cursorShape: Qt.PointingHandCursor
                                onClicked: root.execProcCtxAction("kill")
                            }
                        }
                    }
                }

                // Inline "Ejecutar nueva tarea" Bar
                Rectangle {
                    visible: root.newTaskBarOpen
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: "#252525"
                    border.color: "#4cc2ff"; border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 14; spacing: 10
                        Text { text: "Abrir comando:"; color: "#e6e6e6"; font.pixelSize: 12 }
                        Rectangle {
                            Layout.fillWidth: true; height: 28; radius: 4; color: "#151515"; border.color: "#33ffffff"; clip: true
                            TextInput {
                                id: newTaskInput
                                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; clip: true
                                Keys.onEscapePressed: root.newTaskBarOpen = false
                                onAccepted: {
                                    if (text.trim() !== "") {
                                        bridge.launchRealApp(text.trim());
                                        root.showToast("Ejecutando: " + text.trim());
                                    }
                                    text = "";
                                    root.newTaskBarOpen = false;
                                }
                            }
                        }
                        Rectangle {
                            width: 80; height: 28; radius: 4; color: "#4cc2ff"
                            Text { anchors.centerIn: parent; text: "Ejecutar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: newTaskInput.accepted() }
                        }
                        Rectangle {
                            width: 72; height: 28; radius: 4; color: "#323232"
                            Text { anchors.centerIn: parent; text: "Cancelar"; color: "#f0f0f0"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.newTaskBarOpen = false }
                        }
                    }
                }

                // Column Headers with Live Aggregate Utilization Percentages & Bidirectional Sort
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: "#1e1e1e"
                    border.color: "#1cffffff"; border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 0

                        Item {
                            Layout.fillWidth: true; height: 44
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Nombre (" + root.sortedFilteredProcs.length + ")" + (root.procSortKey === "name" ? (root.procSortDesc ? " ▼" : " ▲") : "")
                                color: "#cccccc"; font.pixelSize: 12; font.weight: Font.DemiBold
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleProcSort("name") }
                        }

                        Item {
                            visible: root.width >= 740
                            Layout.preferredWidth: 112; height: 44
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Estado"; color: "#b0b0b0"; font.pixelSize: 11 }
                        }

                        Item {
                            Layout.preferredWidth: 68; height: 44
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
                                text: "PID" + (root.procSortKey === "pid" ? (root.procSortDesc ? " ▼" : " ▲") : "")
                                color: "#b0b0b0"; font.pixelSize: 11
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleProcSort("pid") }
                        }

                        Item {
                            visible: root.width >= 820
                            Layout.preferredWidth: 56; height: 44
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right; anchors.rightMargin: 10
                                text: "Hilos" + (root.procSortKey === "threads" ? (root.procSortDesc ? " ▼" : " ▲") : "")
                                color: "#b0b0b0"; font.pixelSize: 11
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleProcSort("threads") }
                        }

                        Rectangle {
                            Layout.preferredWidth: 92; height: 44
                            color: root.procSortKey === "cpu" ? "#164cc2ff" : "transparent"
                            Column {
                                anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.right: parent.right; text: root.sysInfo.cpuPct + "%"; color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { anchors.right: parent.right; text: "CPU" + (root.procSortKey === "cpu" ? (root.procSortDesc ? " ▼" : " ▲") : ""); color: "#b8b8b8"; font.pixelSize: 10 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleProcSort("cpu") }
                        }

                        Rectangle {
                            Layout.preferredWidth: 108; height: 44
                            color: root.procSortKey === "mem" ? "#164cc2ff" : "transparent"
                            Column {
                                anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                Text { anchors.right: parent.right; text: root.sysInfo.ramPct + "%"; color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { anchors.right: parent.right; text: "Memoria" + (root.procSortKey === "mem" ? (root.procSortDesc ? " ▼" : " ▲") : ""); color: "#b8b8b8"; font.pixelSize: 10 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleProcSort("mem") }
                        }
                    }
                }

                // Scrollable Processes Table with Windows 11 Heat-Map Cell Shading & Right-Click Menu
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: procCol.implicitHeight + 12
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Column {
                        id: procCol
                        width: parent.width
                        spacing: 1

                        Repeater {
                            model: root.sortedFilteredProcs

                            delegate: Rectangle {
                                readonly property bool isSel: root.selectedPid === modelData.pid
                                width: procCol.width
                                height: 34
                                color: isSel ? "#2c3e50" : (pRowHov.containsMouse ? "#242424" : "#1a1a1a")

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 0

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 18; height: 18; iconUrl: modelData.iconUrl || "" }
                                        Text {
                                            text: modelData.name
                                            color: "#f2f2f2"
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        visible: root.width >= 740
                                        text: modelData.state || "En segundo plano"
                                        color: modelData.state === "En ejecución" ? "#4ade80" : "#9a9a9a"
                                        font.pixelSize: 11
                                        Layout.preferredWidth: 112
                                    }

                                    Text {
                                        text: modelData.pid
                                        color: "#9a9a9a"; font.pixelSize: 11
                                        horizontalAlignment: Text.AlignRight
                                        Layout.preferredWidth: 58
                                        Layout.rightMargin: 10
                                    }

                                    Text {
                                        visible: root.width >= 820
                                        text: String(modelData.threads || 1)
                                        color: "#9a9a9a"; font.pixelSize: 11
                                        horizontalAlignment: Text.AlignRight
                                        Layout.preferredWidth: 46
                                        Layout.rightMargin: 10
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 92; height: 34
                                        color: (modelData.cpuNum || 0) > 15 ? "#384cc2ff" : ((modelData.cpuNum || 0) > 2 ? "#1e4cc2ff" : "#0c4cc2ff")
                                        Text {
                                            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.cpu
                                            color: "#f5f5f5"; font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 108; height: 34
                                        color: (modelData.memNum || 0) > 600 ? "#384cc2ff" : ((modelData.memNum || 0) > 150 ? "#1e4cc2ff" : "#0c4cc2ff")
                                        Text {
                                            anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.mem
                                            color: "#f5f5f5"; font.pixelSize: 12
                                        }
                                    }
                                }

                                MouseArea {
                                    id: pRowHov; anchors.fill: parent; hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        root.selectedPid = modelData.pid;
                                        root.selectedProcObj = modelData;
                                        if (mouse.button === Qt.RightButton) {
                                            var gp = mapToItem(root, mouse.x, mouse.y);
                                            root.procCtxX = Math.max(12, Math.min(root.width - 236, gp.x));
                                            root.procCtxY = Math.max(12, Math.min(root.height - 230, gp.y));
                                            root.procCtxOpen = true;
                                        } else {
                                            root.procCtxOpen = false;
                                        }
                                    }
                                    onDoubleClicked: {
                                        root.selectedPid = modelData.pid;
                                        root.selectedProcObj = modelData;
                                        root.procPropsObj = modelData;
                                        root.procPropsOpen = true;
                                    }
                                }
                            }
                        }
                    }
                }

                // Bottom Status Strip
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 28; color: "#1c1c1c"; border.color: "#16ffffff"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 18
                        Text { text: "Procesos: " + root.sysInfo.procCount; color: "#a8a8a8"; font.pixelSize: 11 }
                        Text { text: "Subprocesos: " + root.sysInfo.threadCount; color: "#a8a8a8"; font.pixelSize: 11 }
                        Text { text: "CPU: " + root.sysInfo.cpuPct + "%  (" + root.sysInfo.cpuGhz + ")"; color: "#4cc2ff"; font.pixelSize: 11 }
                        Text { text: "RAM: " + root.sysInfo.ramShort; color: "#c084fc"; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        Text { text: root.statusToastText !== "" ? root.statusToastText : ("Tiempo activo: " + root.sysInfo.uptime); color: root.statusToastText !== "" ? "#4cc2ff" : "#8e8e8e"; font.pixelSize: 11 }
                    }
                }
            }

            // =================================================================
            // TAB 2: RENDIMIENTO (1:1 Windows 11 5-Subsystem Monitor: CPU, RAM, Disk, Net, GPU)
            // =================================================================
            RowLayout {
                visible: root.activeTab === "performance"
                anchors.fill: parent
                spacing: 0

                // Left Resource Selector List with Live Mini-Sparkline Canvases
                Rectangle {
                    Layout.preferredWidth: root.width < 760 ? 186 : 232
                    Layout.fillHeight: true
                    color: "#1c1c1c"

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 10
                        contentWidth: width
                        contentHeight: perfRailCol.implicitHeight + 10
                        clip: true

                        Column {
                            id: perfRailCol
                            width: parent.width
                            spacing: 6

                            Text { text: "Rendimiento"; color: "#f5f5f5"; font.pixelSize: 18; font.weight: Font.DemiBold; leftPadding: 4; bottomPadding: 6 }

                            // 1. CPU Card
                            Rectangle {
                                width: parent.width; height: 62; radius: 6
                                color: root.perfSubTab === "cpu" ? "#2b2b2b" : (cCardH.containsMouse ? "#232323" : "transparent")
                                border.color: root.perfSubTab === "cpu" ? "#4cc2ff" : "#18ffffff"; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 10
                                    MiniSpark { id: miniCpuCanvas; series: root.cpuHistory; strokeColor: "#4cc2ff"; fillColor: "rgba(76, 194, 255, 0.24)" }
                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "CPU"; color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        Text { text: root.sysInfo.cpuPct + "%  " + root.sysInfo.cpuGhz; color: "#4cc2ff"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                        Text { text: root.sysInfo.cpuTemp !== "—" ? ("Temp: " + root.sysInfo.cpuTemp) : (root.sysInfo.cpuCores + " hilos"); color: "#8e8e8e"; font.pixelSize: 10 }
                                    }
                                }
                                MouseArea { id: cCardH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.perfSubTab = "cpu"; perfCanvas.requestPaint(); } }
                            }

                            // 2. Memoria Card
                            Rectangle {
                                width: parent.width; height: 62; radius: 6
                                color: root.perfSubTab === "ram" ? "#2b2b2b" : (rCardH.containsMouse ? "#232323" : "transparent")
                                border.color: root.perfSubTab === "ram" ? "#c084fc" : "#18ffffff"; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 10
                                    MiniSpark { id: miniRamCanvas; series: root.ramHistory; strokeColor: "#c084fc"; fillColor: "rgba(192, 132, 252, 0.24)" }
                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Memoria"; color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        Text { text: root.sysInfo.ramShort; color: "#c084fc"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                        Text { text: root.sysInfo.ramPct + "% en uso"; color: "#8e8e8e"; font.pixelSize: 10 }
                                    }
                                }
                                MouseArea { id: rCardH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.perfSubTab = "ram"; perfCanvas.requestPaint(); } }
                            }

                            // 3+. Dynamic Multi-Disk Cards (Disco 0 (C:), Disco 1 (D:), Disco 2... — ALL NVMe/SATA/HDD/SSD/USB!)
                            Repeater {
                                model: root.sysInfo.disks || []
                                delegate: Rectangle {
                                    id: diskCardDel
                                    readonly property string dId: modelData.id || ("disk_" + index)
                                    width: perfRailCol.width; height: 62; radius: 6
                                    color: (root.perfSubTab === dId || (root.perfSubTab === "disk" && index === 0)) ? "#2b2b2b" : (dCardH.containsMouse ? "#232323" : "transparent")
                                    border.color: (root.perfSubTab === dId || (root.perfSubTab === "disk" && index === 0)) ? "#4ade80" : "#18ffffff"; border.width: 1
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 8; spacing: 10
                                        MiniSpark {
                                            series: root.diskHistories[diskCardDel.dId] || []
                                            repaintTick: root.historyTick
                                            strokeColor: "#4ade80"
                                            fillColor: "rgba(74, 222, 128, 0.24)"
                                        }
                                        Column {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: modelData.label || ("Disco " + index); color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; width: parent.width }
                                            Text { text: (modelData.type || "Disco") + " • " + Number(modelData.activePct || 0) + "%"; color: "#4ade80"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                            Text { text: modelData.subUsage || ""; color: "#8e8e8e"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                        }
                                    }
                                    MouseArea {
                                        id: dCardH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.perfSubTab = diskCardDel.dId; perfCanvas.requestPaint(); }
                                    }
                                }
                            }

                            // 4. Red Card
                            Rectangle {
                                width: parent.width; height: 62; radius: 6
                                color: root.perfSubTab === "net" ? "#2b2b2b" : (nCardH.containsMouse ? "#232323" : "transparent")
                                border.color: root.perfSubTab === "net" ? "#f59e0b" : "#18ffffff"; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 8; spacing: 10
                                    MiniSpark { id: miniNetCanvas; series: root.netRecvHistory; strokeColor: "#f59e0b"; fillColor: "rgba(245, 158, 11, 0.24)" }
                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: root.sysInfo.netType || "Red"; color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        Text { text: "↓ " + root.sysInfo.netRecvStr; color: "#f59e0b"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                        Text { text: "↑ " + root.sysInfo.netSendStr; color: "#8e8e8e"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                    }
                                }
                                MouseArea { id: nCardH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.perfSubTab = "net"; perfCanvas.requestPaint(); } }
                            }

                            // 5+. Dynamic Multi-GPU Cards (GPU 0, GPU 1, GPU 2... — SLI, Hybrid Optimus & Multi-Vendor!)
                            Repeater {
                                model: root.sysInfo.gpus || []
                                delegate: Rectangle {
                                    id: gpuCardDel
                                    readonly property string gId: modelData.id || ("gpu_" + index)
                                    width: perfRailCol.width; height: 62; radius: 6
                                    color: root.perfSubTab === gId ? "#2b2b2b" : (gCardH.containsMouse ? "#232323" : "transparent")
                                    border.color: root.perfSubTab === gId ? "#38bdf8" : "#18ffffff"; border.width: 1
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 8; spacing: 10
                                        MiniSpark {
                                            series: root.gpuHistories[gpuCardDel.gId] || []
                                            repaintTick: root.historyTick
                                            strokeColor: "#38bdf8"
                                            fillColor: "rgba(56, 189, 248, 0.24)"
                                        }
                                        Column {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: modelData.label || ("GPU " + index); color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            Text { text: Number(modelData.pct || 0) + "%  " + (modelData.temp && modelData.temp !== "—" ? modelData.temp : ""); color: "#38bdf8"; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width }
                                            Text { text: modelData.vramStr || "Compartida"; color: "#8e8e8e"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
                                        }
                                    }
                                    MouseArea {
                                        id: gCardH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.perfSubTab = gpuCardDel.gId; perfCanvas.requestPaint(); }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1cffffff" }

                // Right Detailed Telemetry View (Scrollable so nothing ever clips on small windows!)
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: perfDetailCol.implicitHeight + 36
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    ColumnLayout {
                        id: perfDetailCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 12

                        // Title + Hardware Model Header
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Text {
                                text: root.perfSubTab === "cpu" ? "CPU"
                                      : (root.perfSubTab === "ram" ? "Memoria"
                                         : (root.isDiskPerfTab ? (root.activeDiskObj.titleLabel || "Disco 0")
                                            : (root.perfSubTab === "net" ? (root.sysInfo.netType + " (" + root.sysInfo.netIface + ")")
                                               : (root.activeGpuObj.label || "GPU 0"))))
                                color: "#f5f5f5"; font.pixelSize: 22; font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            // CPU Graph Mode Toggle ("Uso general" / "Núcleos lógicos")
                            Rectangle {
                                visible: root.perfSubTab === "cpu"
                                width: 138; height: 28; radius: 5
                                color: cpuViewH.containsMouse ? "#323232" : "#262626"
                                border.color: "#28ffffff"; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: root.cpuShowPerCore ? "Ver uso general" : "Ver núcleos lógicos"
                                    color: "#4cc2ff"; font.pixelSize: 11; font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    id: cpuViewH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.cpuShowPerCore = !root.cpuShowPerCore
                                }
                            }
                            Text {
                                text: root.perfSubTab === "cpu" ? root.sysInfo.cpu
                                      : (root.perfSubTab === "ram" ? (root.sysInfo.ramTotalGb + " GB RAM")
                                         : (root.isDiskPerfTab ? (root.activeDiskObj.model || "Unidad")
                                            : (root.perfSubTab === "net" ? root.sysInfo.netIp
                                               : (root.activeGpuObj.name || "Adaptador gráfico"))))
                                color: "#c4c4c4"; font.pixelSize: 12; elide: Text.ElideRight; Layout.maximumWidth: 340
                            }
                        }

                        // Graph Header Caption
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: root.perfSubTab === "cpu" ? (root.cpuShowPerCore ? "Uso por procesador lógico" : "% de uso")
                                      : (root.perfSubTab === "ram" ? "Uso de memoria física"
                                         : (root.isDiskPerfTab ? "Tiempo de actividad de disco (%)"
                                            : (root.perfSubTab === "net" ? "Rendimiento de red (↓ Recibir / ↑ Enviar)"
                                               : "Uso de GPU 3D (%)")))
                                color: "#9a9a9a"; font.pixelSize: 11
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.perfSubTab === "net" ? "1 MB/s escala" : "100%"
                                color: "#9a9a9a"; font.pixelSize: 11
                            }
                        }

                        // Per-Core Live Bar Grid (when CPU + cpuShowPerCore is ON)
                        Rectangle {
                            visible: root.perfSubTab === "cpu" && root.cpuShowPerCore
                            Layout.fillWidth: true
                            Layout.preferredHeight: 225
                            radius: 6
                            color: "#141414"
                            border.color: "#4cc2ff"; border.width: 1

                            Grid {
                                anchors.fill: parent; anchors.margins: 12
                                columns: (root.sysInfo.cpuPerCore || []).length > 8 ? 4 : ((root.sysInfo.cpuPerCore || []).length > 4 ? 4 : 2)
                                rowSpacing: 8; columnSpacing: 8
                                Repeater {
                                    model: root.sysInfo.cpuPerCore || []
                                    delegate: Rectangle {
                                        readonly property int cols: (root.sysInfo.cpuPerCore || []).length > 4 ? 4 : 2
                                        readonly property int rows: Math.max(1, Math.ceil((root.sysInfo.cpuPerCore || []).length / cols))
                                        width: (parent.width - (cols - 1) * 8) / cols
                                        height: (parent.height - (rows - 1) * 8) / rows
                                        radius: 4; color: "#1b1b1b"; border.color: "#224cc2ff"; border.width: 1
                                        clip: true
                                        Rectangle {
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                            height: Math.max(2, parent.height * (Math.min(100, Number(modelData || 0)) / 100.0))
                                            color: "#384cc2ff"
                                            Behavior on height { NumberAnimation { duration: 300 } }
                                        }
                                        Text {
                                            x: 7; y: 5; text: "CPU " + index; color: "#9a9a9a"; font.pixelSize: 10
                                        }
                                        Text {
                                            anchors.right: parent.right; anchors.rightMargin: 7; y: 5
                                            text: Number(modelData || 0) + "%"; color: "#4cc2ff"; font.pixelSize: 11; font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }
                        }

                        // Live 60-Second Telemetry Canvas Graph
                        Rectangle {
                            visible: !(root.perfSubTab === "cpu" && root.cpuShowPerCore)
                            Layout.fillWidth: true
                            Layout.preferredHeight: 225
                            radius: 6
                            color: "#141414"
                            border.color: root.perfSubTab === "cpu" ? "#4cc2ff"
                                          : (root.perfSubTab === "ram" ? "#c084fc"
                                             : (root.isDiskPerfTab ? "#4ade80"
                                                : (root.perfSubTab === "net" ? "#f59e0b" : "#38bdf8")))
                            border.width: 1
                            clip: true

                            Canvas {
                                id: perfCanvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d");
                                    var w = width;
                                    var h = height;
                                    ctx.clearRect(0, 0, w, h);

                                    // Gridlines
                                    ctx.strokeStyle = "rgba(255, 255, 255, 0.07)";
                                    ctx.lineWidth = 1;
                                    for (var gy = 1; gy < 5; gy++) {
                                        var py = (h / 5) * gy;
                                        ctx.beginPath(); ctx.moveTo(0, py); ctx.lineTo(w, py); ctx.stroke();
                                    }
                                    for (var gx = 1; gx < 10; gx++) {
                                        var px = (w / 10) * gx;
                                        ctx.beginPath(); ctx.moveTo(px, 0); ctx.lineTo(px, h); ctx.stroke();
                                    }

                                    function drawSeries(arr, strokeCol, fillCol, dashed) {
                                        if (!arr || arr.length < 2) return;
                                        var maxPts = 60;
                                        var startX = w - ((arr.length - 1) * (w / (maxPts - 1)));
                                        ctx.save();
                                        if (dashed) ctx.setLineDash([5, 4]);
                                        ctx.beginPath();
                                        for (var i = 0; i < arr.length; i++) {
                                            var x = startX + i * (w / (maxPts - 1));
                                            var y = h - (Math.max(0, Math.min(100, Number(arr[i] || 0))) / 100.0) * (h - 8) - 4;
                                            if (i === 0) ctx.moveTo(x, y);
                                            else ctx.lineTo(x, y);
                                        }
                                        ctx.strokeStyle = strokeCol;
                                        ctx.lineWidth = 2;
                                        ctx.stroke();
                                        if (fillCol !== "") {
                                            ctx.setLineDash([]);
                                            ctx.lineTo(w, h);
                                            ctx.lineTo(startX, h);
                                            ctx.closePath();
                                            ctx.fillStyle = fillCol;
                                            ctx.fill();
                                        }
                                        ctx.restore();
                                    }

                                    if (root.perfSubTab === "cpu") drawSeries(root.cpuHistory, "#4cc2ff", "rgba(76, 194, 255, 0.22)", false);
                                    else if (root.perfSubTab === "ram") drawSeries(root.ramHistory, "#c084fc", "rgba(192, 132, 252, 0.22)", false);
                                    else if (root.isDiskPerfTab) drawSeries(root.diskHistories[root.activeDiskObj.id || "disk_0"] || [], "#4ade80", "rgba(74, 222, 128, 0.22)", false);
                                    else if (root.perfSubTab === "net") {
                                        drawSeries(root.netRecvHistory, "#f59e0b", "rgba(245, 158, 11, 0.20)", false);
                                        drawSeries(root.netSendHistory, "#4cc2ff", "", true);
                                    } else {
                                        drawSeries(root.gpuHistories[root.perfSubTab] || [], "#38bdf8", "rgba(56, 189, 248, 0.22)", false);
                                    }
                                }
                            }
                        }

                        // Dedicated GPU VRAM Utilization Bar (Windows 11 Authentic VRAM Bar)
                        ColumnLayout {
                            visible: root.isGpuPerfTab && Number(root.activeGpuObj.vramTotalMb || 0) > 0
                            Layout.fillWidth: true; spacing: 5
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Uso de memoria dedicada de GPU (VRAM)"; color: "#9a9a9a"; font.pixelSize: 11 }
                                Item { Layout.fillWidth: true }
                                Text { text: (root.activeGpuObj.vramStr || "") + "  (" + Number(root.activeGpuObj.vramPct || 0) + "%)"; color: "#38bdf8"; font.pixelSize: 11; font.weight: Font.DemiBold }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 18; radius: 4; color: "#141414"; border.color: "#3338bdf8"; border.width: 1; clip: true
                                Rectangle {
                                    x: 1; y: 1; height: parent.height - 2; radius: 3
                                    width: Math.max(2, (parent.width - 2) * (Math.min(100, Number(root.activeGpuObj.vramPct || 0)) / 100.0))
                                    color: "#38bdf8"
                                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        // Memory Composition Stacked Bar (Windows 11 Authentic RAM Bar)
                        ColumnLayout {
                            visible: root.perfSubTab === "ram"
                            Layout.fillWidth: true; spacing: 5
                            Text { text: "Composición de memoria"; color: "#9a9a9a"; font.pixelSize: 11 }
                            Rectangle {
                                Layout.fillWidth: true; height: 22; radius: 4; color: "#141414"; border.color: "#33c084fc"; border.width: 1; clip: true
                                Row {
                                    anchors.fill: parent; anchors.margins: 1
                                    Rectangle {
                                        readonly property real tot: Math.max(0.1, Number(root.sysInfo.ramTotalGb || 16))
                                        width: parent.width * Math.min(1.0, Number(root.sysInfo.ramUsedGb || 0) / tot)
                                        height: parent.height; color: "#a855f7"
                                    }
                                    Rectangle {
                                        readonly property real tot: Math.max(0.1, Number(root.sysInfo.ramTotalGb || 16))
                                        width: parent.width * Math.min(1.0 - Math.min(1.0, Number(root.sysInfo.ramUsedGb || 0) / tot), Number(root.sysInfo.ramCachedGb || 0) / tot)
                                        height: parent.height; color: "#55c084fc"
                                    }
                                }
                            }
                            RowLayout {
                                spacing: 14
                                Row { spacing: 5; Rectangle { width: 10; height: 10; radius: 2; color: "#a855f7"; anchors.verticalCenter: parent.verticalCenter } Text { text: "En uso (" + root.sysInfo.ramUsedGb + " GB)"; color: "#b8b8b8"; font.pixelSize: 11 } }
                                Row { spacing: 5; Rectangle { width: 10; height: 10; radius: 2; color: "#55c084fc"; anchors.verticalCenter: parent.verticalCenter } Text { text: "En caché (" + root.sysInfo.ramCachedGb + " GB)"; color: "#b8b8b8"; font.pixelSize: 11 } }
                                Row { spacing: 5; Rectangle { width: 10; height: 10; radius: 2; color: "#262626"; border.color: "#44ffffff"; anchors.verticalCenter: parent.verticalCenter } Text { text: "Disponible (" + root.sysInfo.ramAvailGb + " GB)"; color: "#b8b8b8"; font.pixelSize: 11 } }
                            }
                        }

                        // Subsystem-Specific Live Metrics Grid
                        Grid {
                            Layout.fillWidth: true
                            columns: 3
                            rowSpacing: 14
                            columnSpacing: 22

                            // CPU Metrics
                            Repeater {
                                model: root.perfSubTab === "cpu" ? [
                                    { k: "Uso actual",           v: root.sysInfo.cpuPct + "%", accent: "#4cc2ff" },
                                    { k: "Velocidad actual",     v: root.sysInfo.cpuGhz },
                                    { k: "Temperatura",          v: root.sysInfo.cpuTemp },
                                    { k: "Procesos / Hilos",     v: root.sysInfo.procCount + " / " + root.sysInfo.threadCount },
                                    { k: "Núcleos / Lógicos",    v: root.sysInfo.cpuPhysCores + " / " + root.sysInfo.cpuCores },
                                    { k: "Velocidad máxima",     v: root.sysInfo.cpuMaxGhz },
                                    { k: "Caché L3",             v: root.sysInfo.cpuCache },
                                    { k: "Virtualización",       v: root.sysInfo.cpuVirt },
                                    { k: "Planificador",         v: root.sysInfo.sched, accent: "#4cc2ff" },
                                    { k: "Tiempo activo",        v: root.sysInfo.uptime },
                                    { k: "Kernel",               v: root.sysInfo.kernel }
                                ] : (root.perfSubTab === "ram" ? [
                                    { k: "En uso",               v: root.sysInfo.ramUsedGb + " GB (" + root.sysInfo.ramPct + "%)", accent: "#c084fc" },
                                    { k: "Disponible",           v: root.sysInfo.ramAvailGb + " GB" },
                                    { k: "Total instalada",      v: root.sysInfo.ramTotalGb + " GB" },
                                    { k: "En caché / Búfer",     v: root.sysInfo.ramCachedGb + " GB" },
                                    { k: "Swap / ZRAM usada",    v: root.sysInfo.swapUsedGb + " / " + root.sysInfo.swapTotalGb + " GB" },
                                    { k: "Uso Swap / ZRAM",      v: root.sysInfo.swapPct + "%" }
                                ] : (root.isDiskPerfTab ? [
                                    { k: "Tiempo activo I/O",    v: Number(root.activeDiskObj.activePct || 0) + "%", accent: "#4ade80" },
                                    { k: "Velocidad lectura",    v: root.activeDiskObj.readStr || "0.0 MB/s" },
                                    { k: "Velocidad escritura",  v: root.activeDiskObj.writeStr || "0.0 MB/s" },
                                    { k: "Capacidad total",      v: (root.activeDiskObj.totalGb || 0) + " GB" },
                                    { k: "Espacio libre",        v: root.activeDiskObj.freeStr || "—" },
                                    { k: "Sistema de archivos",  v: root.activeDiskObj.fs || "—" },
                                    { k: "Tipo de unidad",       v: root.activeDiskObj.type || "Disco" },
                                    { k: "Dispositivo / Bloque", v: "/dev/" + (root.activeDiskObj.blk || "—") },
                                    { k: "Planificador I/O",     v: root.activeDiskObj.ioSched || "none", accent: "#4ade80" }
                                ] : (root.perfSubTab === "net" ? [
                                    { k: "Recibir (descarga)",   v: root.sysInfo.netRecvStr, accent: "#f59e0b" },
                                    { k: "Enviar (subida)",      v: root.sysInfo.netSendStr, accent: "#4cc2ff" },
                                    { k: "Interfaz activa",      v: root.sysInfo.netIface + " (" + root.sysInfo.netType + ")" },
                                    { k: "Dirección IPv4",       v: root.sysInfo.netIp },
                                    { k: "Dirección MAC",        v: root.sysInfo.netMac },
                                    { k: "Total recibido",       v: root.sysInfo.netTotalRecvStr },
                                    { k: "Total enviado",        v: root.sysInfo.netTotalSentStr }
                                ] : [
                                    { k: "Uso GPU 3D",           v: Number(root.activeGpuObj.pct || 0) + "%", accent: "#38bdf8" },
                                    { k: "Temperatura GPU",      v: root.activeGpuObj.temp || "—" },
                                    { k: "Memoria VRAM",         v: root.activeGpuObj.vramStr || "Compartida" },
                                    { k: "Controlador activo",   v: root.activeGpuObj.driver || "DRM/KMS" },
                                    { k: "Bus PCI",              v: root.activeGpuObj.busId || "—" },
                                    { k: "GPUs detectadas",      v: String((root.sysInfo.gpus || []).length) + " GPU" + ((root.sysInfo.gpus || []).length === 1 ? "" : "s") }
                                ])))
                                delegate: Column {
                                    width: Math.max(120, (perfDetailCol.width - 44) / 3)
                                    spacing: 2
                                    Text { text: modelData.k; color: "#9a9a9a"; font.pixelSize: 11 }
                                    Text {
                                        width: parent.width
                                        text: String(modelData.v || "—")
                                        color: modelData.accent ? modelData.accent : "#f5f5f5"
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // TAB 3: APLICACIONES DE INICIO (100% Real Enable/Disable, Add, Remove & Properties!)
            // =================================================================
            ColumnLayout {
                visible: root.activeTab === "startup"
                anchors.fill: parent
                spacing: 0

                // Header & Action Command Bar
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 54; color: "#202020"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 14; spacing: 10

                        Text {
                            visible: root.width >= 700
                            text: "Aplicaciones de inicio"
                            color: "#f5f5f5"; font.pixelSize: 17; font.weight: Font.DemiBold
                        }

                        // Clipped Responsive Search Box
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 110
                            Layout.preferredWidth: 210
                            Layout.maximumWidth: 260
                            height: 32; radius: 5; clip: true
                            color: startupSearch.activeFocus ? "#161616" : "#2b2b2b"
                            border.color: startupSearch.activeFocus ? "#4cc2ff" : "#22ffffff"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 8; spacing: 7
                                WinSvg { width: 14; height: 14; iconFile: "fluent-search.svg"; opacity: 0.8 }
                                Item {
                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                    Text {
                                        visible: startupSearch.text === ""
                                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                        text: "Buscar aplicación..."; color: "#9a9a9a"; font.pixelSize: 12; elide: Text.ElideRight
                                    }
                                    TextInput {
                                        id: startupSearch
                                        anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                        color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                                        onTextChanged: root.startupFilter = text
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true; Layout.minimumWidth: 4 }

                        // Enable / Disable Selected Button
                        Rectangle {
                            readonly property bool hasSel: root.selectedStartupObj !== null
                            readonly property bool isEn: hasSel && Boolean(root.selectedStartupObj.enabled)
                            width: 112; height: 32; radius: 5
                            color: !hasSel ? "#252525" : (stTogH.containsMouse ? "#363636" : "#2b2b2b")
                            border.color: hasSel ? "#28ffffff" : "#16ffffff"; border.width: 1
                            opacity: hasSel ? 1.0 : 0.45
                            Text {
                                anchors.centerIn: parent
                                text: parent.isEn ? "Deshabilitar" : "Habilitar"
                                color: "#f2f2f2"; font.pixelSize: 12
                            }
                            MouseArea {
                                id: stTogH; anchors.fill: parent; hoverEnabled: true; enabled: parent.hasSel; cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleStartupItem(root.selectedStartupObj)
                            }
                        }

                        // "+ Agregar" Button
                        Rectangle {
                            width: 102; height: 32; radius: 5
                            color: stAddH.containsMouse ? "#5ecbff" : "#4cc2ff"
                            RowLayout {
                                anchors.centerIn: parent; spacing: 5
                                Text { text: "+"; color: "#000000"; font.pixelSize: 15; font.weight: Font.Bold }
                                Text { text: "Agregar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                            }
                            MouseArea {
                                id: stAddH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    addNameIn.text = "";
                                    addCmdIn.text = "";
                                    root.startupAddOpen = true;
                                    addNameIn.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Sortable Column Headers
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 36; color: "#1e1e1e"; border.color: "#1cffffff"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 8
                        Item {
                            Layout.fillWidth: true; height: 36
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Nombre" + (root.startupSortKey === "name" ? (root.startupSortAsc ? " ▲" : " ▼") : "")
                                color: "#cccccc"; font.pixelSize: 11; font.weight: Font.DemiBold
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleStartupSort("name") }
                        }
                        Item {
                            visible: root.width >= 720
                            Layout.preferredWidth: 94; height: 36
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Origen" + (root.startupSortKey === "publisher" ? (root.startupSortAsc ? " ▲" : " ▼") : "")
                                color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.DemiBold
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleStartupSort("publisher") }
                        }
                        Item {
                            Layout.preferredWidth: 102; height: 36
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Impacto" + (root.startupSortKey === "impact" ? (root.startupSortAsc ? " ▲" : " ▼") : "")
                                color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.DemiBold
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleStartupSort("impact") }
                        }
                        Item {
                            Layout.preferredWidth: 146; height: 36
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Estado" + (root.startupSortKey === "status" ? (root.startupSortAsc ? " ▲" : " ▼") : "")
                                color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.DemiBold
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleStartupSort("status") }
                        }
                    }
                }

                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: width; contentHeight: stCol.implicitHeight + 12; clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Column {
                        id: stCol; width: parent.width; spacing: 1
                        Repeater {
                            model: root.sortedFilteredStartup
                            delegate: Rectangle {
                                readonly property bool isSel: root.selectedStartupId === modelData.id
                                width: stCol.width; height: 46
                                color: isSel ? "#2c3e50" : (stRowH.containsMouse ? "#242424" : (index % 2 === 0 ? "#191919" : "#1c1c1c"))

                                MouseArea {
                                    id: stRowH; anchors.fill: parent; hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        root.selectedStartupId = modelData.id;
                                        root.selectedStartupObj = modelData;
                                        if (mouse.button === Qt.RightButton) {
                                            var gp = mapToItem(root, mouse.x, mouse.y);
                                            root.startupCtxX = Math.max(12, Math.min(root.width - 230, gp.x));
                                            root.startupCtxY = Math.max(12, Math.min(root.height - 180, gp.y));
                                            root.startupCtxOpen = true;
                                        } else {
                                            root.startupCtxOpen = false;
                                        }
                                    }
                                    onDoubleClicked: root.toggleStartupItem(modelData)
                                }

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 22; height: 22; iconUrl: modelData.iconUrl || ""; opacity: modelData.enabled ? 1.0 : 0.45 }
                                        Column {
                                            Layout.fillWidth: true; spacing: 1
                                            Text {
                                                width: parent.width; text: modelData.name
                                                color: modelData.enabled ? "#f5f5f5" : "#8e8e8e"
                                                font.pixelSize: 12; font.weight: Font.Medium; elide: Text.ElideRight
                                            }
                                            Text {
                                                width: parent.width; text: modelData.execCmd || ""
                                                color: "#7a7a7a"; font.pixelSize: 10; elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Text {
                                        visible: root.width >= 720
                                        text: modelData.publisher; color: "#9e9e9e"; font.pixelSize: 11; Layout.preferredWidth: 94
                                    }

                                    Item {
                                        Layout.preferredWidth: 102; height: 24
                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: impTxt.implicitWidth + 14; height: 20; radius: 4
                                            color: modelData.impact === "Alto" ? "#28ef4444" : (modelData.impact === "Medio" ? "#28f59e0b" : "#224ade80")
                                            Text {
                                                id: impTxt; anchors.centerIn: parent
                                                text: modelData.impact
                                                color: modelData.impact === "Alto" ? "#f87171" : (modelData.impact === "Medio" ? "#fbbf24" : "#4ade80")
                                                font.pixelSize: 10; font.weight: Font.DemiBold
                                            }
                                        }
                                    }

                                    // Status Text + Real Working WinUI 3 Toggle Switch
                                    RowLayout {
                                        Layout.preferredWidth: 146; spacing: 10
                                        Text {
                                            text: modelData.status
                                            color: modelData.enabled ? "#4cc2ff" : "#8e8e8e"
                                            font.pixelSize: 11; Layout.fillWidth: true
                                        }
                                        Rectangle {
                                            width: 38; height: 20; radius: 10
                                            color: modelData.enabled ? "#4cc2ff" : "#2e2e2e"
                                            border.color: modelData.enabled ? "#4cc2ff" : "#55ffffff"; border.width: 1
                                            Behavior on color { ColorAnimation { duration: 130 } }
                                            Rectangle {
                                                x: modelData.enabled ? 20 : 4
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 12; height: 12; radius: 6
                                                color: modelData.enabled ? "#000000" : "#cccccc"
                                                Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: root.toggleStartupItem(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Startup Footer
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 28; color: "#1c1c1c"; border.color: "#16ffffff"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 14
                        Text { text: root.startupApps.length + " aplicaciones configuradas"; color: "#a8a8a8"; font.pixelSize: 11 }
                        Text { text: root.enabledStartupCount + " habilitadas"; color: "#4cc2ff"; font.pixelSize: 11 }
                        Text { text: (root.startupApps.length - root.enabledStartupCount) + " deshabilitadas"; color: "#8e8e8e"; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                        Text { text: root.statusToastText; color: "#4cc2ff"; font.pixelSize: 11 }
                    }
                }
            }
        }
    }

    // Click-outside Catcher for Context Menus
    MouseArea {
        visible: root.procCtxOpen || root.startupCtxOpen
        anchors.fill: parent; z: 50
        onClicked: { root.procCtxOpen = false; root.startupCtxOpen = false; }
    }

    // Process Right-Click Context Menu
    Rectangle {
        visible: root.procCtxOpen && root.selectedProcObj !== null
        x: root.procCtxX; y: root.procCtxY
        width: 224; height: pCtxCol.implicitHeight + 10; radius: 8
        color: "#f6282828"; border.color: "#32ffffff"; border.width: 1; z: 60
        MouseArea { anchors.fill: parent }
        Column {
            id: pCtxCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 5; spacing: 2
            Repeater {
                model: [
                    { act: "kill",      label: "Finalizar tarea",             icon: "fluent-dismiss.svg", bold: true },
                    { act: "kill_tree", label: "Finalizar árbol de procesos", icon: "fluent-delete.svg" },
                    { sep: true },
                    { act: "open_loc",  label: "Abrir ubicación del archivo", icon: "folder.svg" },
                    { act: "copy_pid",  label: "Copiar PID",                  icon: "fluent-copy.svg" },
                    { act: "copy_cmd",  label: "Copiar comando",              icon: "fluent-link.svg" },
                    { sep: true },
                    { act: "props",     label: "Propiedades",                 icon: "fluent-info.svg" }
                ]
                delegate: Item {
                    width: 214; height: modelData.sep ? 8 : 30
                    Rectangle { visible: Boolean(modelData.sep); anchors.verticalCenter: parent.verticalCenter; x: 6; width: 202; height: 1; color: "#1effffff" }
                    Rectangle {
                        visible: !modelData.sep; anchors.fill: parent; radius: 5
                        color: pmiH.containsMouse ? "#24ffffff" : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                            WinSvg { width: 15; height: 15; iconFile: modelData.icon || "fluent-info.svg" }
                            Text { text: modelData.label || ""; color: "#f2f2f2"; font.pixelSize: 12; font.weight: modelData.bold ? Font.DemiBold : Font.Normal; Layout.fillWidth: true }
                        }
                        MouseArea { id: pmiH; anchors.fill: parent; hoverEnabled: true; onClicked: root.execProcCtxAction(modelData.act) }
                    }
                }
            }
        }
    }

    // Startup App Right-Click Context Menu
    Rectangle {
        visible: root.startupCtxOpen && root.selectedStartupObj !== null
        x: root.startupCtxX; y: root.startupCtxY
        width: 216; height: sCtxCol.implicitHeight + 10; radius: 8
        color: "#f6282828"; border.color: "#32ffffff"; border.width: 1; z: 60
        MouseArea { anchors.fill: parent }
        readonly property var rows: {
            var o = root.selectedStartupObj;
            if (!o) return [];
            var arr = [
                { act: "toggle", label: o.enabled ? "Deshabilitar" : "Habilitar", icon: "fluent-sparkle.svg", bold: true },
                { act: "open_loc", label: "Abrir ubicación del archivo", icon: "folder.svg" }
            ];
            if (o.canRemove) arr.push({ act: "remove", label: "Quitar del inicio", icon: "fluent-delete.svg" });
            arr.push({ sep: true });
            arr.push({ act: "props", label: "Propiedades", icon: "fluent-info.svg" });
            return arr;
        }
        Column {
            id: sCtxCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 5; spacing: 2
            Repeater {
                model: parent.parent.rows
                delegate: Item {
                    width: 206; height: modelData.sep ? 8 : 30
                    Rectangle { visible: Boolean(modelData.sep); anchors.verticalCenter: parent.verticalCenter; x: 6; width: 194; height: 1; color: "#1effffff" }
                    Rectangle {
                        visible: !modelData.sep; anchors.fill: parent; radius: 5
                        color: smiH.containsMouse ? "#24ffffff" : "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                            WinSvg { width: 15; height: 15; iconFile: modelData.icon || "fluent-info.svg" }
                            Text { text: modelData.label || ""; color: "#f2f2f2"; font.pixelSize: 12; font.weight: modelData.bold ? Font.DemiBold : Font.Normal; Layout.fillWidth: true }
                        }
                        MouseArea { id: smiH; anchors.fill: parent; hoverEnabled: true; onClicked: root.execStartupCtxAction(modelData.act) }
                    }
                }
            }
        }
    }

    // Modal: Process Properties
    Rectangle {
        visible: root.procPropsOpen && root.procPropsObj !== null
        anchors.fill: parent; color: "#66000000"; z: 70
        MouseArea { anchors.fill: parent; onClicked: root.procPropsOpen = false }
        Rectangle {
            anchors.centerIn: parent; width: 420; height: 280; radius: 10
            color: "#f8242424"; border.color: "#34ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 9
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    WinSvg { width: 32; height: 32; iconUrl: root.procPropsObj ? (root.procPropsObj.iconUrl || "") : "" }
                    Column {
                        Layout.fillWidth: true
                        Text { text: root.procPropsObj ? root.procPropsObj.name : ""; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Text { text: "PID " + (root.procPropsObj ? root.procPropsObj.pid : "") + "  •  Usuario: " + (root.procPropsObj ? root.procPropsObj.user : ""); color: "#9e9e9e"; font.pixelSize: 11 }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1effffff" }
                Text { text: "Estado:  " + (root.procPropsObj ? root.procPropsObj.state : ""); color: "#d8d8d8"; font.pixelSize: 12 }
                Text { text: "CPU:  " + (root.procPropsObj ? root.procPropsObj.cpu : "") + "   |   Memoria:  " + (root.procPropsObj ? root.procPropsObj.mem : "") + "   |   Hilos:  " + (root.procPropsObj ? root.procPropsObj.threads : ""); color: "#d8d8d8"; font.pixelSize: 12 }
                Text { text: "PID padre (PPID):  " + (root.procPropsObj ? root.procPropsObj.ppid : ""); color: "#d8d8d8"; font.pixelSize: 12 }
                Text { text: "Comando:  " + (root.procPropsObj ? root.procPropsObj.cmdline : ""); color: "#b8b8b8"; font.pixelSize: 11; wrapMode: Text.WrapAnywhere; maximumLineCount: 3; elide: Text.ElideRight; Layout.fillWidth: true }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 86; height: 30; radius: 5; color: "#4cc2ff"
                        Text { anchors.centerIn: parent; text: "Aceptar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.procPropsOpen = false }
                    }
                }
            }
        }
    }

    // Modal: Startup App Properties
    Rectangle {
        visible: root.startupPropsOpen && root.startupPropsObj !== null
        anchors.fill: parent; color: "#66000000"; z: 70
        MouseArea { anchors.fill: parent; onClicked: root.startupPropsOpen = false }
        Rectangle {
            anchors.centerIn: parent; width: 420; height: 255; radius: 10
            color: "#f8242424"; border.color: "#34ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 9
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    WinSvg { width: 32; height: 32; iconUrl: root.startupPropsObj ? (root.startupPropsObj.iconUrl || "") : "" }
                    Column {
                        Layout.fillWidth: true
                        Text { text: root.startupPropsObj ? root.startupPropsObj.name : ""; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Text { text: (root.startupPropsObj ? root.startupPropsObj.publisher : "") + "  •  " + (root.startupPropsObj ? root.startupPropsObj.status : ""); color: "#4cc2ff"; font.pixelSize: 11 }
                    }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#1effffff" }
                Text { text: "Archivo:  " + (root.startupPropsObj ? root.startupPropsObj.filePath : ""); color: "#d8d8d8"; font.pixelSize: 11; elide: Text.ElideMiddle; Layout.fillWidth: true }
                Text { text: "Comando:  " + (root.startupPropsObj ? root.startupPropsObj.execCmd : ""); color: "#d8d8d8"; font.pixelSize: 11; wrapMode: Text.WrapAnywhere; maximumLineCount: 2; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: "Impacto estimado:  " + (root.startupPropsObj ? root.startupPropsObj.impact : ""); color: "#d8d8d8"; font.pixelSize: 12 }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 86; height: 30; radius: 5; color: "#4cc2ff"
                        Text { anchors.centerIn: parent; text: "Aceptar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.startupPropsOpen = false }
                    }
                }
            }
        }
    }

    // Modal: Add New Startup Application (Pick from Installed Apps or Custom Command)
    Rectangle {
        visible: root.startupAddOpen
        anchors.fill: parent; color: "#66000000"; z: 75
        MouseArea { anchors.fill: parent; onClicked: root.startupAddOpen = false }
        Rectangle {
            anchors.centerIn: parent; width: 440; height: 370; radius: 10
            color: "#f8242424"; border.color: "#34ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 10
                Text { text: "Agregar aplicación de inicio"; color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold }
                Text { text: "Elige una aplicación instalada o escribe un comando personalizado:"; color: "#a8a8a8"; font.pixelSize: 11 }

                // Quick pick installed apps list
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 135; radius: 6; color: "#161616"; border.color: "#22ffffff"; clip: true
                    Flickable {
                        anchors.fill: parent; anchors.margins: 4; contentWidth: width; contentHeight: appPickCol.implicitHeight; clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                        Column {
                            id: appPickCol; width: parent.width; spacing: 2
                            Repeater {
                                model: root.installedAppsList
                                delegate: Rectangle {
                                    width: appPickCol.width; height: 30; radius: 4
                                    color: pickH.containsMouse ? "#28ffffff" : "transparent"
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                        WinSvg { width: 16; height: 16; iconUrl: modelData.iconUrl || "" }
                                        Text { text: modelData.name || ""; color: "#f2f2f2"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                    MouseArea {
                                        id: pickH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { addNameIn.text = modelData.name || ""; addCmdIn.text = modelData.cmd || ""; }
                                    }
                                }
                            }
                        }
                    }
                }

                Text { text: "Nombre:"; color: "#cccccc"; font.pixelSize: 11 }
                Rectangle {
                    Layout.fillWidth: true; height: 30; radius: 5; color: "#151515"; border.color: addNameIn.activeFocus ? "#4cc2ff" : "#30ffffff"; clip: true
                    TextInput {
                        id: addNameIn; anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                    }
                }

                Text { text: "Comando:"; color: "#cccccc"; font.pixelSize: 11 }
                Rectangle {
                    Layout.fillWidth: true; height: 30; radius: 5; color: "#151515"; border.color: addCmdIn.activeFocus ? "#4cc2ff" : "#30ffffff"; clip: true
                    TextInput {
                        id: addCmdIn; anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 82; height: 30; radius: 5; color: "#323232"
                        Text { anchors.centerIn: parent; text: "Cancelar"; color: "#f0f0f0"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.startupAddOpen = false }
                    }
                    Rectangle {
                        width: 92; height: 30; radius: 5; color: "#4cc2ff"
                        Text { anchors.centerIn: parent; text: "Agregar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (bridge.addStartupApp(addNameIn.text, addCmdIn.text, "")) {
                                    root.startupAddOpen = false;
                                    root.refreshStartupApps();
                                    root.showToast("Aplicación agregada al inicio");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
