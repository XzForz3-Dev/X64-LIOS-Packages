import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1040
    height: 690
    color: "#202020"
    focus: true

    function normalizePageName(raw) {
        var s = String(raw || "").split(":")[0].trim();
        if (s === "" || s === "Inicio") return "Inicio";
        if (s.indexOf("Personalizaci") === 0) return "Personalización";
        if (s.indexOf("Juegos") === 0) return "Juegos";
        if (s.indexOf("Cuenta") === 0) return "Cuentas";
        if (s.indexOf("Hora") === 0 || s.indexOf("Idioma") !== -1) return "Hora e idioma";
        if (s.indexOf("Actualizaci") === 0 || s.indexOf("Update") !== -1 || s.indexOf("Windows") === 0) return "Actualización del sistema";
        if (s === "Sistema" || s === "Bluetooth y dispositivos" || s === "Red e Internet" || s === "Aplicaciones") return s;
        return "Inicio";
    }

    function extractSubPage(raw) {
        var s = String(raw || "");
        var idx = s.indexOf(":");
        if (idx === -1) return "";
        var sub = s.slice(idx + 1).trim();
        if (sub.indexOf("Desinstalar:") === 0) return "Aplicaciones instaladas";
        return sub;
    }

    function extractUninstallTarget(raw) {
        var s = String(raw || "");
        var marker = ":Desinstalar:";
        var idx = s.indexOf(marker);
        return idx !== -1 ? s.slice(idx + marker.length).trim() : "";
    }

    property string settingsPage: normalizePageName(typeof initialArg !== "undefined" ? initialArg : "")
    property string settingsSubPage: extractSubPage(typeof initialArg !== "undefined" ? initialArg : "")
    property string pendingUninstallTarget: extractUninstallTarget(typeof initialArg !== "undefined" ? initialArg : "")
    property var navHistory: [{ page: normalizePageName(typeof initialArg !== "undefined" ? initialArg : ""), sub: extractSubPage(typeof initialArg !== "undefined" ? initialArg : "") }]
    property int navHistIdx: 0
    readonly property bool canGoBack: navHistIdx > 0 || settingsSubPage !== ""
    readonly property bool canGoForward: navHistIdx < (navHistory.length - 1)

    property string navFilter: ""
    property string appSearchFilter: ""
    property string appSourceFilter: "all"
    property string appSortBy: "name"
    property var startupApps: []
    property bool startupAddOpen: false
    property string startupAddErr: ""

    // Native WinUI 3 Graphical Uninstaller Wizard State
    property bool uninstModalOpen: false
    property var uninstTargetApp: null
    property var uninstPlan: null
    property bool uninstCleanUserData: false
    property bool uninstRunning: false
    property int uninstPct: 0
    property string uninstStepText: ""
    property string uninstLog: ""
    property bool uninstShowLog: false
    property string uninstFinishedState: ""
    property string uninstResultMsg: ""

    // Native WinUI 3 Account Modals State (Password, Quick PIN, Add User, Reset Other PW, Delete User)
    property bool pwModalOpen: false
    property string pwModalErr: ""
    property bool pwShowFields: false
    property bool pinModalOpen: false
    property string pinModalErr: ""
    property bool addUserModalOpen: false
    property string addUserModalErr: ""
    property bool addUserIsAdmin: false
    property string resetOtherPwUser: ""
    property string resetOtherPwErr: ""
    property string delUserTarget: ""
    property bool delUserRemoveHome: false
    property string delUserErr: ""
    property bool navExpandedManual: false
    property bool copiedNotice: false
    property bool copiedOsNotice: false
    property string toastMsg: ""
    function formatSpanishDate(dt) {
        var days = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"];
        var months = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
        return days[dt.getDay()] + ", " + dt.getDate() + " de " + months[dt.getMonth()] + " de " + dt.getFullYear();
    }

    function getZonedNow() {
        var now = new Date();
        if (root.tlData && root.tlData.tzOffsetMins !== undefined && Number(root.tlData.tzOffsetMins) > -90000) {
            var deltaMs = (Number(root.tlData.tzOffsetMins) + now.getTimezoneOffset()) * 60000;
            return new Date(now.getTime() + deltaMs);
        }
        return now;
    }

    function refreshDisplayedClock() {
        var now = root.getZonedNow();
        root.clockTimeStr = Boolean(root.cfg.clock12h) ? Qt.formatTime(now, "h:mm:ss AP") : Qt.formatTime(now, "hh:mm:ss");
        root.clockDateStr = root.formatSpanishDate(now);
    }

    property string clockTimeStr: Qt.formatTime(new Date(), "hh:mm:ss")
    property string clockDateStr: formatSpanishDate(new Date())
    property string tzSearchFilter: ""
    property var allTimezones: []
    property int localKbRate: 25
    property int localKbDelay: 600
    property bool kbRateDragging: false
    property bool kbDelayDragging: false
    property string manualDtErr: ""

    // Live Optimistic Slider & Toggle States (prevents 4s poller jitter & instant 144Hz feedback!)
    property int localBrightPct: 100
    property int localVolPct: 80
    property int localMicPct: 50
    property real localMouseSpeed: 0.0
    property real localTpSpeed: 0.0
    property bool brightDragging: false
    property bool volDragging: false
    property bool micDragging: false
    property bool mouseSpeedDragging: false
    property bool tpSpeedDragging: false
    property int localNightStrength: 45
    property bool nightStrDragging: false
    property string expandedMimeRole: ""
    property string selectedMonitorName: ""
    property bool resDropdownOpen: false

    // 15-Second Display Auto-Revert Safety Modal (Authentic Windows 11!)
    property bool dispRevertModalOpen: false
    property int dispRevertSec: 15
    property var dispRevertSnap: ({})

    // Audio Sonido Interactive States (Live 30Hz Throttled Sliders + Real 3s Mic Test + Card Profiles + App Routing)
    property string micTestState: ""
    property string expandedAudioCard: ""
    property string expandedStreamRoute: ""
    property int activeSliderDrags: 0
    property var scrollRevealTarget: null
    property double _lastVolMs: 0
    property double _lastMicMs: 0
    property double _lastBrightMs: 0
    property double _lastStreamMs: 0
    property string _pendingStreamId: ""
    property int _pendingStreamVol: 100

    Timer {
        id: volWriteTimer
        interval: 35; repeat: false
        onTriggered: {
            root._lastVolMs = Date.now();
            bridge.setPipewireVolume(root.localVolPct);
        }
    }

    Timer {
        id: micWriteTimer
        interval: 35; repeat: false
        onTriggered: {
            root._lastMicMs = Date.now();
            bridge.setMicVolume(root.localMicPct);
        }
    }

    Timer {
        id: streamWriteTimer
        interval: 35; repeat: false
        onTriggered: {
            root._lastStreamMs = Date.now();
            if (root._pendingStreamId !== "") bridge.setStreamVolume(root._pendingStreamId, root._pendingStreamVol);
        }
    }

    Timer {
        id: scrollRevealTimer
        interval: 35; repeat: false
        onTriggered: {
            var it = root.scrollRevealTarget;
            if (!it || typeof mainFlick === "undefined" || typeof bodyCol === "undefined") return;
            var pos = it.mapToItem(bodyCol, 0, 0);
            var topY = pos.y;
            var botY = topY + it.height + 28;
            var viewH = mainFlick.height;
            var maxY = Math.max(0, mainFlick.contentHeight - viewH);
            if (botY > mainFlick.contentY + viewH || topY < mainFlick.contentY) {
                var targetY = Math.max(0, Math.min(maxY, Math.min(topY - 16, botY - viewH)));
                flickScrollAnim.stop();
                flickScrollAnim.from = mainFlick.contentY;
                flickScrollAnim.to = targetY;
                flickScrollAnim.start();
            }
        }
    }

    function ensureItemVisible(item) {
        if (!item) return;
        scrollRevealTarget = item;
        scrollRevealTimer.restart();
    }

    function pushVolLive(v) {
        var iv = Math.round(v);
        if (iv === localVolPct && volWriteTimer.running) return;
        localVolPct = iv;
        var now = Date.now();
        if (now - _lastVolMs >= 32) {
            volWriteTimer.stop();
            _lastVolMs = now;
            bridge.setPipewireVolume(iv);
        } else if (!volWriteTimer.running) {
            volWriteTimer.start();
        }
    }

    function pushMicLive(v) {
        var iv = Math.round(v);
        if (iv === localMicPct && micWriteTimer.running) return;
        localMicPct = iv;
        var now = Date.now();
        if (now - _lastMicMs >= 32) {
            micWriteTimer.stop();
            _lastMicMs = now;
            bridge.setMicVolume(iv);
        } else if (!micWriteTimer.running) {
            micWriteTimer.start();
        }
    }

    function pushBrightLive(v) {
        var iv = Math.round(v);
        localBrightPct = iv;
        var now = Date.now();
        if (now - _lastBrightMs >= 55) {
            brightWriteTimer.stop();
            _lastBrightMs = now;
            bridge.runCtlAction("brightness set " + iv);
        } else if (!brightWriteTimer.running) {
            brightWriteTimer.start();
        }
    }

    function pushStreamVolLive(streamId, v) {
        var iv = Math.round(v);
        _pendingStreamId = String(streamId);
        _pendingStreamVol = iv;
        var now = Date.now();
        if (now - _lastStreamMs >= 32) {
            streamWriteTimer.stop();
            _lastStreamMs = now;
            bridge.setStreamVolume(_pendingStreamId, iv);
        } else if (!streamWriteTimer.running) {
            streamWriteTimer.start();
        }
    }

    function audioBusIcon(busType) {
        if (busType === "Bluetooth") return "fluent-bluetooth.svg";
        if (busType === "HDMI") return "fluent-display.svg";
        if (busType === "USB") return "usb-hub-symbolic.svg";
        return "audio-speakers-symbolic.svg";
    }

    function btDeviceIcon(btIcon) {
        var s = String(btIcon || "").toLowerCase();
        if (s.indexOf("audio") !== -1 || s.indexOf("head") !== -1) return "audio-speakers-symbolic.svg";
        if (s.indexOf("gaming") !== -1 || s.indexOf("joystick") !== -1) return "fluent-games.svg";
        if (s.indexOf("mouse") !== -1) return "input-mouse-symbolic.svg";
        if (s.indexOf("keyboard") !== -1) return "fluent-keyboard.svg";
        if (s.indexOf("phone") !== -1) return "fluent-phone.svg";
        return "fluent-bluetooth.svg";
    }

    property bool btScanning: false
    property var btDiscovered: []
    property bool wifiScanning: false
    property bool netPingRunning: false
    property string netPingSummary: ""
    property string netConfirmAction: ""
    property string netConfirmTarget: ""
    property string netConfirmLabel: ""
    readonly property var netData: (root.extData && root.extData.net) ? root.extData.net : ({
        connected: false, activeType: "none", activeName: "Sin conexión", activeIface: "", activeUuid: "",
        hasWifi: false, wifiIface: "", wifiEnabled: false, wifiConnected: false, wifiBand: "", wifiRate: "",
        wifiSignalDbm: "", wifiConName: "", wifiUuid: "", wifiAutoconnect: true, wifiMetered: false,
        wifiIp4: "", wifiIp6: "", wifiGateway: "", wifiMac: "", wifiDns: "", airplaneMode: false,
        knownWifi: [], ethernetDevices: [], vpnProfiles: [], adapters: [],
        totalRxHuman: "0 B", totalTxHuman: "0 B",
        dnsDot: false, ufwActive: false, tcpCongestion: "—", qdisc: "—", wifiPowerSaveOff: false
    })

    readonly property var activeSinkObj: {
        var list = root.extData.sinks || [];
        for (var i = 0; i < list.length; i++) if (list[i].active) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    readonly property var activeSourceObj: {
        var list = root.extData.sources || [];
        for (var i = 0; i < list.length; i++) if (list[i].active) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    // Wi-Fi Password Modal, Rename PC Modal & Power Action Confirm States
    property bool wifiPassModalOpen: false
    property string wifiPassSsid: ""
    property string wifiPassErr: ""
    property bool renamePcModalOpen: false
    property string renamePcErr: ""
    property string powerConfirmAction: ""
    property string storageConfirmAction: ""
    property double powerProfileLockUntil: 0
    property string lockedPowerProfile: ""
    property double cfgWriteGuardUntil: 0

    function applyPowerProfileUi(profId, label) {
        lockedPowerProfile = profId;
        powerProfileLockUntil = Date.now() + 1400;
        var copy = Object.assign({}, hwState);
        copy.powerProfile = profId;
        copy.cpuGovernor = label;
        hwState = copy;
        bridge.runCtlAction("power-profile " + profId);
        powerModeSyncTimer.restart();
        showToast("Modo de energía: " + label);
    }

    Timer {
        id: powerModeSyncTimer
        interval: 380; repeat: false
        onTriggered: root.refreshLiveState(false)
    }

    Timer {
        id: brightWriteTimer
        interval: 65; repeat: false
        onTriggered: bridge.runCtlAction("brightness set " + root.localBrightPct)
    }

    Timer {
        id: dispRevertTimer
        interval: 1000; repeat: true
        onTriggered: {
            if (root.dispRevertSec <= 1) {
                root.revertDisplayChange();
            } else {
                root.dispRevertSec = root.dispRevertSec - 1;
            }
        }
    }

    function beginDisplayConfirm(monName, prevModeArg, prevTransform, desc) {
        dispRevertSnap = { name: monName, prevModeArg: prevModeArg || "", prevTransform: prevTransform || "", desc: desc || "" };
        dispRevertSec = 15;
        dispRevertModalOpen = true;
        dispRevertTimer.restart();
    }

    function keepDisplayChange() {
        dispRevertTimer.stop();
        dispRevertModalOpen = false;
        dispRevertSnap = ({});
        showToast("Configuración de pantalla guardada");
    }

    function revertDisplayChange() {
        dispRevertTimer.stop();
        dispRevertModalOpen = false;
        var s = dispRevertSnap || {};
        dispRevertSnap = ({});
        if (s.name) {
            if (s.prevModeArg) bridge.applyMonitorSetting(s.name, "", s.prevModeArg);
            if (s.prevTransform) bridge.applyMonitorAdvanced(s.name, s.prevTransform, "", "");
            refreshLiveState(false);
            showToast("Configuración anterior restaurada");
        }
    }

    readonly property var selectedMonitor: {
        var mons = root.extData.monitors || [];
        if (mons.length === 0) return null;
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].name === root.selectedMonitorName) return mons[i];
        }
        return mons[0];
    }

    readonly property int selectedMonitorIndex: {
        var mons = root.extData.monitors || [];
        if (!selectedMonitor) return 0;
        for (var i = 0; i < mons.length; i++) {
            if (mons[i].name === selectedMonitor.name) return i;
        }
        return 0;
    }

    readonly property var selectedMonResObj: {
        var m = root.selectedMonitor;
        if (!m || !m.resolutions || m.resolutions.length === 0) return null;
        for (var i = 0; i < m.resolutions.length; i++) {
            if (m.resolutions[i].current || m.resolutions[i].res === m.currentRes) return m.resolutions[i];
        }
        return m.resolutions[0];
    }

    readonly property int enabledMonitorsCount: {
        var mons = root.extData.monitors || [];
        var c = 0;
        for (var i = 0; i < mons.length; i++) if (mons[i].enabled) c++;
        return c;
    }

    // System Update Check State (100% Async QThread via bridge.updatesChecked signal!)
    property bool checkingUpdates: false
    property var updateResult: ({ "count": -1, "pacmanCount": 0, "aurCount": 0, "flatpakCount": 0, "packages": [], "flatpakPackages": [], "checkedAt": "", "error": "" })
    property string updHistFilter: "all"
    property string updHistSearch: ""

    function navigateTo(page, subPage, pushHist) {
        var p = page || "Inicio";
        var s = subPage || "";
        if (pushHist !== false && (p !== settingsPage || s !== settingsSubPage)) {
            var h = navHistory.slice(0, navHistIdx + 1);
            h.push({ page: p, sub: s });
            navHistory = h;
            navHistIdx = h.length - 1;
        }
        settingsPage = p;
        settingsSubPage = s;
        navExpandedManual = false;
        mainFlick.contentY = 0;
        // 0ms non-blocking navigation! Only trigger background worker on pages that need fresh hardware data
        if (p === "Aplicaciones") {
            if (root.installedApps.length === 0) root.reloadInstalledApps();
            if (root.startupApps.length === 0 || s === "Inicio") root.reloadStartupApps();
        }
        if (p === "Cuentas") {
            root.reloadAccountInfo();
        }
        if (p === "Hora e idioma") {
            root.reloadTimeLangInfo();
            if (s === "Fecha y hora" && root.allTimezones.length === 0) {
                try { root.allTimezones = JSON.parse(bridge.getAllTimezonesJson()); } catch (e) {}
            }
        }
        if (p === "Juegos") {
            root.reloadGamingInfo();
        }
        if (p === "Actualización del sistema") {
            root.reloadUpdateInfo();
        }
        bridge.requestAsyncRefresh(s === "Impresoras y escáneres" || s === "Almacenamiento");
    }

    function reloadUpdateInfo() {
        try {
            var u = JSON.parse(bridge.getUpdateInfoJson());
            if (u && typeof u === "object") {
                var exCopy = Object.assign({}, root.extData);
                exCopy.updateInfo = u;
                if (u.pkgCount !== undefined) exCopy.pkgCount = u.pkgCount;
                root.extData = exCopy;
                if (!root.checkingUpdates && u.cachedCheck && u.cachedCheck.count >= 0 && (!root.updateResult.error || String(root.updateResult.error) === "")) {
                    root.updateResult = u.cachedCheck;
                }
            }
        } catch (e) {}
    }

    function reloadGamingInfo() {
        try {
            var gm = JSON.parse(bridge.getGamingInfoJson());
            if (gm && typeof gm === "object") {
                var exCopy = Object.assign({}, root.extData);
                exCopy.gamingStack = gm;
                root.extData = exCopy;
            }
        } catch (e) {}
    }

    function reloadTimeLangInfo() {
        try {
            var tl = JSON.parse(bridge.getTimeLangInfoJson());
            if (tl && typeof tl === "object") {
                var exCopy = Object.assign({}, root.extData);
                exCopy.timeLang = tl;
                root.extData = exCopy;
                if (!root.kbRateDragging && tl.repeatRate !== undefined) root.localKbRate = Number(tl.repeatRate);
                if (!root.kbDelayDragging && tl.repeatDelay !== undefined) root.localKbDelay = Number(tl.repeatDelay);
                root.refreshDisplayedClock();
            }
        } catch (e) {}
    }

    function reloadAccountInfo() {
        try {
            var acc = JSON.parse(bridge.getAccountInfoJson());
            if (acc && typeof acc === "object") {
                var exCopy = Object.assign({}, root.extData);
                exCopy.account = acc;
                root.extData = exCopy;
                if (acc.avatarUrl !== undefined) {
                    var cfgCopy = Object.assign({}, root.cfg);
                    cfgCopy.userAvatarUrl = String(acc.avatarUrl || "");
                    root.cfg = cfgCopy;
                }
                if (typeof dispNameIn !== "undefined" && !dispNameIn.activeFocus) {
                    dispNameIn.text = root.activeDisplayName;
                }
            }
        } catch (e) {}
    }

    function reloadInstalledApps() {
        try { root.installedApps = JSON.parse(bridge.getInstalledAppsJson()); } catch (e) {}
    }

    function reloadStartupApps() {
        try { root.startupApps = JSON.parse(bridge.getStartupAppsJson()); } catch (e) {}
    }

    function openUninstallWizard(appObj) {
        if (!appObj) return;
        root.uninstTargetApp = appObj;
        root.uninstCleanUserData = false;
        root.uninstRunning = false;
        root.uninstPct = 0;
        root.uninstStepText = "";
        root.uninstLog = "";
        root.uninstShowLog = false;
        root.uninstFinishedState = "";
        root.uninstResultMsg = "";
        try {
            root.uninstPlan = JSON.parse(bridge.inspectUninstallPlanJson(
                String(appObj.pkgName || appObj.id || ""),
                String(appObj.source || ""),
                String(appObj.desktopPath || ""),
                String(appObj.name || "")
            ));
        } catch (e) {
            root.uninstPlan = {
                ok: false, canUninstall: false,
                blockedReason: "No se pudo analizar el plan de desinstalación.",
                source: String(appObj.source || ""), sourceLabel: String(appObj.sourceLabel || "Sistema"),
                pkgName: String(appObj.pkgName || ""), appName: String(appObj.name || ""),
                version: String(appObj.version || ""), totalFreeHuman: String(appObj.sizeHuman || "—"),
                removePkgs: [], orphanCount: 0, requiredBy: [], needsRoot: true,
                flatpakScope: "system", userDataPaths: [], userDataSizeHuman: ""
            };
        }
        root.uninstModalOpen = true;
    }

    function openUninstallWizardForTarget(rawTarget) {
        var raw = String(rawTarget || "").trim();
        if (raw === "") return;
        var parts = raw.split("||");
        var tName = String(parts[0] || "").trim().toLowerCase();
        var tCmd = String(parts.length > 1 ? parts[1] : "").trim().toLowerCase();
        var tBin = tCmd !== "" ? tCmd.split(" ")[0].split("/").pop() : "";
        var apps = root.installedApps || [];
        var hit = null;
        for (var i = 0; i < apps.length; i++) {
            var a = apps[i];
            var aid = String(a.id || "").toLowerCase();
            var apkg = String(a.pkgName || "").toLowerCase();
            var anm = String(a.name || "").toLowerCase();
            if (tName !== "" && (aid === tName || apkg === tName || anm === tName)) { hit = a; break; }
        }
        if (!hit && tBin !== "") {
            for (var j = 0; j < apps.length; j++) {
                var b = apps[j];
                var bBin = String(b.cmd || "").toLowerCase().split(" ")[0].split("/").pop();
                if (bBin === tBin || String(b.pkgName || "").toLowerCase() === tBin) { hit = b; break; }
            }
        }
        if (!hit && tName !== "") {
            for (var k = 0; k < apps.length; k++) {
                var c = apps[k];
                if (String(c.name || "").toLowerCase().indexOf(tName) !== -1 || String(c.pkgName || "").toLowerCase().indexOf(tName) !== -1) {
                    hit = c; break;
                }
            }
        }
        if (hit) {
            root.openUninstallWizard(hit);
        } else {
            root.appSearchFilter = parts[0] || "";
            root.showToast("Busca la aplicación en la lista para desinstalarla");
        }
    }

    function goBackNav() {
        if (navHistIdx > 0) {
            navHistIdx -= 1;
            var e = navHistory[navHistIdx];
            navigateTo(e.page, e.sub, false);
        } else if (settingsSubPage !== "") {
            navigateTo(settingsPage, "", false);
        }
    }

    function goForwardNav() {
        if (navHistIdx < navHistory.length - 1) {
            navHistIdx += 1;
            var e = navHistory[navHistIdx];
            navigateTo(e.page, e.sub, false);
        }
    }

    function openRenamePcModal() {
        renamePcErr = "";
        renamePcField.text = String(root.sysInfo.hostname || "");
        renamePcModalOpen = true;
        renamePcField.forceActiveFocus();
        renamePcField.selectAll();
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            if (pwModalOpen) { pwModalOpen = false; event.accepted = true; return; }
            if (pinModalOpen) { pinModalOpen = false; event.accepted = true; return; }
            if (addUserModalOpen) { addUserModalOpen = false; event.accepted = true; return; }
            if (resetOtherPwUser !== "") { resetOtherPwUser = ""; event.accepted = true; return; }
            if (delUserTarget !== "") { delUserTarget = ""; event.accepted = true; return; }
            if (uninstModalOpen && !uninstRunning) { uninstModalOpen = false; event.accepted = true; return; }
            if (netConfirmAction !== "") { netConfirmAction = ""; event.accepted = true; return; }
            if (wifiPassModalOpen) { wifiPassModalOpen = false; event.accepted = true; return; }
            if (renamePcModalOpen) { renamePcModalOpen = false; event.accepted = true; return; }
            if (powerConfirmAction !== "") { powerConfirmAction = ""; event.accepted = true; return; }
            if (storageConfirmAction !== "") { storageConfirmAction = ""; event.accepted = true; return; }
        }
        if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Left) {
            root.goBackNav(); event.accepted = true;
        } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Right) {
            root.goForwardNav(); event.accepted = true;
        }
    }

    Connections {
        target: bridge
        function onMouseBackPressed() { root.goBackNav(); }
        function onMouseForwardPressed() { root.goForwardNav(); }
        function onLiveStateReady(jsonStr) { root.applyLiveBundle(jsonStr); }
        function onUninstallProgress(jsonStr) {
            try {
                var ev = JSON.parse(jsonStr);
                if (ev.step) root.uninstStepText = String(ev.step);
                if (ev.pct !== undefined) root.uninstPct = Math.max(0, Math.min(100, Number(ev.pct)));
                if (ev.logLine) root.uninstLog = root.uninstLog !== "" ? (root.uninstLog + "\n" + ev.logLine) : String(ev.logLine);
            } catch (e) {}
        }
        function onUninstallFinished(jsonStr) {
            root.uninstRunning = false;
            try {
                var res = JSON.parse(jsonStr);
                if (res.log) root.uninstLog = String(res.log);
                if (res.ok) {
                    root.uninstPct = 100;
                    root.uninstFinishedState = "ok";
                    var extra = (res.cleanedDirs && res.cleanedDirs.length > 0) ? (" y se limpiaron sus datos locales.") : ".";
                    root.uninstResultMsg = "«" + (res.appName || res.pkgName || "Aplicación") + "» se ha desinstalado correctamente" + extra;
                    root.reloadInstalledApps();
                    root.reloadStartupApps();
                    root.refreshLiveState(false);
                    root.showToast("Desinstalada: " + (res.appName || res.pkgName || "Aplicación"));
                } else {
                    root.uninstFinishedState = "error";
                    root.uninstResultMsg = String(res.error || "No se pudo completar la desinstalación.");
                }
            } catch (e) {
                root.uninstFinishedState = "error";
                root.uninstResultMsg = "Error inesperado al finalizar la desinstalación.";
            }
        }
        function onHwOsdUpdated(jsonStr) {
            try {
                var ev = JSON.parse(jsonStr);
                if (!ev || !ev.kind) return;
                if (ev.kind === "volume") {
                    if (!root.volDragging) root.localVolPct = Math.round(Number(ev.value !== undefined ? ev.value : root.localVolPct));
                    var hwV = Object.assign({}, root.hwState);
                    hwV.volumePct = root.localVolPct;
                    if (ev.muted !== undefined) hwV.muted = Boolean(ev.muted);
                    root.hwState = hwV;
                } else if (ev.kind === "brightness") {
                    if (!root.brightDragging) root.localBrightPct = Math.round(Number(ev.value !== undefined ? ev.value : root.localBrightPct));
                    var hwB = Object.assign({}, root.hwState);
                    hwB.brightnessPct = root.localBrightPct;
                    root.hwState = hwB;
                } else if (ev.kind === "mic") {
                    if (!root.micDragging && ev.value !== undefined) root.localMicPct = Math.round(Number(ev.value));
                    var exM = Object.assign({}, root.extData);
                    exM.micVol = root.localMicPct;
                    if (ev.muted !== undefined) exM.micMuted = Boolean(ev.muted);
                    root.extData = exM;
                }
            } catch (e) {}
        }
        function onMicTestStateChanged(st) {
            if (st === "recording") {
                root.micTestState = "recording";
                root.showToast("Habla ahora — grabando 3 segundos...");
            } else if (st === "playing") {
                root.micTestState = "playing";
                root.showToast("Reproduciendo grabación de prueba...");
            } else if (st === "done") {
                root.micTestState = "";
                root.showToast("Prueba de micrófono completada");
            } else {
                root.micTestState = "";
                root.showToast(String(st).replace(/^error:/, "") || "Error en prueba de micrófono");
            }
        }
        function onUpdatesChecked(jsonStr) {
            root.checkingUpdates = false;
            try {
                var res = JSON.parse(jsonStr);
                root.updateResult = res;
                if (res.error && String(res.error) !== "") {
                    root.showToast(String(res.error));
                } else {
                    root.showToast(res.count > 0 ? (res.count + " actualizaciones disponibles") : "Todo está actualizado");
                }
            } catch (e) {}
        }
        function onBtScanFinished(jsonStr) {
            root.btScanning = false;
            try {
                var arr = JSON.parse(jsonStr);
                root.btDiscovered = Array.isArray(arr) ? arr : [];
                root.refreshLiveState(false);
                root.showToast(root.btDiscovered.length > 0
                    ? ("Encontrados " + root.btDiscovered.length + " dispositivo(s) Bluetooth cercanos")
                    : "Búsqueda finalizada: no se encontraron nuevos dispositivos cercanos");
            } catch (e) { root.btDiscovered = []; }
        }
        function onWifiScanFinished(st) {
            root.wifiScanning = false;
            root.refreshLiveState(false);
            if (String(st) === "ok") {
                root.showToast("Redes Wi-Fi actualizadas");
            } else {
                root.showToast(String(st).replace(/^error:/, "") || "No se pudo explorar redes");
            }
        }
        function onNetPingFinished(jsonStr) {
            root.netPingRunning = false;
            try {
                var res = JSON.parse(jsonStr);
                root.netPingSummary = String(res.summary || "Sin respuesta");
                root.showToast(res.ok && res.ipMs >= 0 ? ("Internet: " + res.ipMs + " ms") : root.netPingSummary);
            } catch (e) {
                root.netPingSummary = "Error al medir latencia";
            }
        }
    }

    // Responsive Breakpoints (ZERO deformation on small windows + full spacious layout when maximized!)
    readonly property bool compactNav: root.width < 820 && !root.navExpandedManual
    readonly property bool narrowBody: contentPane.width < 560
    readonly property bool wideBody: root.width >= 1260

    property var cfg: ({
        "taskbarCompact": false,
        "taskbarLeftAlign": false,
        "taskbarSearchMode": "box",
        "showTaskViewBtn": true,
        "showWeatherWidget": true,
        "startAllViewMode": "categories",
        "showRecommended": false,
        "showPhoneLink": true,
        "showBatteryPct": true,
        "showDesktopIcons": true,
        "desktopAutoArrange": false,
        "desktopIconSizeMode": "medium",
        "nightLight": false,
        "nightLightStrength": 45,
        "doNotDisturb": false,
        "notifEnabled": true,
        "notifShowBanners": true,
        "notifPlaySound": true,
        "notifBannerSecs": 5,
        "notifMutedApps": ({}),
        "focusDurationMins": 30,
        "wallpaperMode": 0,
        "wallpaperFit": "fill",
        "solidBgColor": "#141923",
        "accentColor": "#4cc2ff",
        "accentOnBorders": true,
        "transparencyEnabled": true,
        "lockWallpaperMode": -1,
        "lockWallpaperUrl": "",
        "lockShowStatus": true,
        "customWallpaperUrl": "",
        "userAvatarUrl": "",
        "phoneMaxFps": 60,
        "phoneBitrate": "8M",
        "phoneAudio": true,
        "phoneTurnScreenOff": false,
        "phoneStayAwake": true,
        "phoneAlwaysOnTop": false,
        "lockRequireAuth": false,
        "clockShowSeconds": false,
        "gameModeAutoDnd": true,
        "screenshotDir": "",
        "screenshotCopyClipboard": true,
        "screenshotNotify": true
    })

    property var sysInfo: ({
        "user": "Usuario",
        "username": "x64",
        "hostname": "x64-pc",
        "userEmail": "x64@x64-pc",
        "cpu": "Procesador x86_64",
        "cpuCores": 8,
        "cpuPhysCores": 4,
        "cpuGhz": "3.40 GHz",
        "ram": "16.0 GB",
        "kernel": "Linux",
        "sched": "scx_lavd",
        "gpus": []
    })

    property var hwState: ({
        "wifiEnabled": true,
        "wifiSsid": "Wi-Fi",
        "wifiNetworks": [],
        "btEnabled": true,
        "brightnessPct": 100,
        "volumePct": 80,
        "muted": false,
        "powerProfile": "balanced",
        "cpuGovernor": "Equilibrado",
        "localIp": "Sin conexión",
        "gpu": "GPU activa",
        "monitors": "1920x1080"
    })

    property var extData: ({
        "monitors": [],
        "hasBacklight": true,
        "sinks": [],
        "sources": [],
        "audioStreams": [],
        "audioCards": [],
        "notifApps": [],
        "micVol": 50,
        "micMuted": false,
        "btAdapter": { "present": true, "powered": true, "discoverable": false, "pairable": false, "alias": "PC", "address": "" },
        "btDevices": [],
        "usbDevices": [],
        "printers": [],
        "cupsActive": true,
        "phoneLink": { "kdeInstalled": true, "kdeRunning": false, "scrcpyInstalled": true, "adbInstalled": true, "kdeDevices": [], "adbDevices": [], "mirrorActive": false, "mirrorMode": "", "mirrorSerial": "" },
        "inputCfg": { "mouseSpeed": 0.0, "mouseAccel": "adaptive", "mouseLeftHanded": false, "mouseNaturalScroll": false, "mouseScrollFactor": 1.0, "mouseMiddleEmulation": false, "mouseHwName": "", "hasTouchpad": true, "touchpadHwName": "", "tpSendEvents": "yes", "tpTap": true, "tpTapAndDrag": true, "tpThreeFingerDrag": false, "tpNaturalScroll": true, "tpDisableTyping": true, "tpClickMethod": "clickfinger", "tpSpeed": 0.0 },
        "netGateway": "—",
        "netDns": "—",
        "netIface": "—",
        "netIsEthernet": false,
        "net": {
            "connected": false, "activeType": "none", "activeName": "Sin conexión", "activeIface": "", "activeUuid": "",
            "hasWifi": false, "wifiIface": "", "wifiEnabled": false, "wifiConnected": false, "wifiBand": "", "wifiRate": "",
            "wifiSignalDbm": "", "wifiConName": "", "wifiUuid": "", "wifiAutoconnect": true, "wifiMetered": false,
            "wifiIp4": "", "wifiIp6": "", "wifiGateway": "", "wifiMac": "", "wifiDns": "", "airplaneMode": false,
            "knownWifi": [], "ethernetDevices": [], "vpnProfiles": [], "adapters": [],
            "totalRxHuman": "0 B", "totalTxHuman": "0 B",
            "dnsDot": false, "ufwActive": false, "tcpCongestion": "—", "qdisc": "—", "wifiPowerSaveOff": false
        },
        "appearance": { "gtkDark": true, "cursorTheme": "breeze_cursors", "cursorSize": 24, "cursorThemes": ["breeze_cursors", "Breeze_Light", "Adwaita"] },
        "battery": { "present": false, "pct": 100, "status": "AC", "acOnline": true, "label": "Conectado a corriente alterna (Escritorio)", "model": "Fuente CA", "tech": "", "healthPct": -1, "whDesign": "", "voltageStr": "", "powerW": "", "cycles": 0 },
        "powerInfo": { "cpuDriver": "intel_pstate", "cpuEpp": "balanced", "cpuFreqGhz": "—", "cpuMaxGhz": "—", "hasLid": false, "lidExtAction": "suspend", "caffeineActive": false },
        "storageExtras": { "trashCount": 0, "trashSize": "0 B", "pacmanCacheSize": "0 B", "pacmanCacheCount": 0, "userCacheSize": "0 B", "userCacheBytes": 0, "journalSize": "0 B", "journalBytes": 0, "userFolders": [] },
        "about": { "vendorModel": "", "boardBios": "", "archLabel": "Sistema operativo de 64 bits, procesador x86_64", "osPretty": "X64 LIOS Linux", "shellVersion": "x64-win11-settings", "compositorInfo": "Wayland • labwc", "uptimeHuman": "—", "hasX64Hello": false },
        "account": { "displayName": "", "username": "", "hostname": "", "homeDir": "", "shell": "/bin/fish", "groups": "", "isAdmin": true, "avatarUrl": "", "hasPin": false, "sddmAutologin": false, "availableShells": [], "otherUsers": [], "adminCount": 1 },
        "timeLang": { "timezone": "Local", "timezoneId": "UTC", "tzOffsetMins": -99999, "ntpActive": true, "synced": true, "localRtc": false, "locale": "es_ES.UTF-8", "installedLocales": [], "kbLayout": "ES", "kbPrimary": "es", "kbSecondary": "us", "kbToggleOpt": "grp:alt_shift_toggle", "repeatRate": 25, "repeatDelay": 600, "numlock": false },
        "defaultApps": [],
        "gamingStack": { "sched": "scx_lavd", "falcond": false, "dmemcg": false, "ananicy": false, "ntsync": false, "hasSteam": false, "hasHeroic": false, "hasLutris": false, "hasGoverlay": false, "hasMangohud": false, "hasGamescope": false, "hasObs": false, "hasX64Hello": false, "adaptiveSync": "yes", "allowTearing": "no", "screenshotDir": "", "screenshotCount": 0, "gamepads": [] },
        "tools": { "hasKdeConnect": false, "hasBlueman": true, "hasPrinterGui": true, "hasNmEditor": true, "hasGnomeDisks": true },
        "updateInfo": { "history": [], "lastUpgradeDate": "", "pkgCount": 0, "repos": [], "ignorePkgs": [], "paccacheTimerEnabled": false, "fstrimTimerEnabled": false, "trayRunning": false, "runningKernel": "", "rebootRequired": false, "installedKernels": [], "snapperConfigs": [], "hasBtrfsAssistant": false, "hasX64Update": true, "hasX64Hello": true, "isUefi": false },
        "recentUpgrades": [],
        "pkgCount": 0
    })

    property var drives: []
    property var installedApps: []

    readonly property var appsStats: {
        var list = root.installedApps || [];
        var pac = 0, fp = 0, loc = 0, uninst = 0, totB = 0;
        for (var i = 0; i < list.length; i++) {
            var a = list[i];
            if (a.source === "pacman") pac++;
            else if (a.source === "flatpak") fp++;
            else if (a.source === "local") loc++;
            if (a.canUninstall) uninst++;
            totB += Number(a.sizeBytes || 0);
        }
        var human = "—";
        if (totB > 0) {
            var mb = totB / (1024 * 1024);
            human = mb >= 1024 ? ((mb / 1024).toFixed(2) + " GB") : (mb.toFixed(1) + " MB");
        }
        return { total: list.length, pacman: pac, flatpak: fp, local: loc, uninstallable: uninst, totalSizeHuman: human };
    }

    readonly property int startupEnabledCount: {
        var arr = root.startupApps || [];
        var c = 0;
        for (var i = 0; i < arr.length; i++) if (arr[i].enabled) c++;
        return c;
    }

    readonly property var filteredInstalledApps: {
        var list = root.installedApps || [];
        var q = root.appSearchFilter.trim().toLowerCase();
        var srcF = root.appSourceFilter;
        var out = [];
        for (var i = 0; i < list.length; i++) {
            var a = list[i];
            if (srcF !== "all" && String(a.source || "") !== srcF) continue;
            if (q !== "") {
                var hay = (String(a.name || "") + " " + String(a.pkgName || "") + " " + String(a.comment || "") + " " + String(a.cmd || "")).toLowerCase();
                if (hay.indexOf(q) === -1) continue;
            }
            out.push(a);
        }
        if (root.appSortBy === "size") {
            out.sort(function(x, y) { return Number(y.sizeBytes || 0) - Number(x.sizeBytes || 0); });
        } else {
            out.sort(function(x, y) { return String(x.name || "").localeCompare(String(y.name || "")); });
        }
        return out;
    }

    readonly property var physicalDrives: {
        var out = [];
        var src = root.drives || [];
        for (var i = 0; i < src.length; i++) {
            if (!src[i].isHomeVolume) out.push(src[i]);
        }
        return out;
    }

    readonly property string activeSinkName: {
        var arr = (root.extData && root.extData.sinks) ? root.extData.sinks : [];
        for (var i = 0; i < arr.length; i++) if (arr[i].active) return arr[i].name;
        return arr.length > 0 ? arr[0].name : "PipeWire predeterminado";
    }

    readonly property string netChipLabel: {
        if (root.extData && root.extData.netIsEthernet && root.hwState.localIp && root.hwState.localIp !== "Sin conexión") {
            return "Ethernet — Conectado";
        }
        if (root.hwState.wifiEnabled && root.hwState.wifiSsid) return root.hwState.wifiSsid;
        return root.hwState.wifiEnabled ? "Wi-Fi activado" : "Sin conexión";
    }

    readonly property string netChipIcon: {
        if (root.extData && root.extData.netIsEthernet && root.hwState.localIp && root.hwState.localIp !== "Sin conexión") {
            return "fluent-ethernet.svg";
        }
        return root.hwState.wifiEnabled ? "fluent-wifi.svg" : "fluent-wifi-off.svg";
    }

    readonly property string accentColor: (root.cfg && root.cfg.accentColor && String(root.cfg.accentColor).indexOf("#") === 0) ? String(root.cfg.accentColor) : "#4cc2ff"
    readonly property var appearanceData: (root.extData && root.extData.appearance) ? root.extData.appearance : ({ gtkDark: true, cursorTheme: "breeze_cursors", cursorSize: 24, cursorThemes: ["breeze_cursors", "Breeze_Light", "Adwaita"] })
    readonly property string activeWallpaperSrc: {
        if (root.cfg.wallpaperMode === 3 && root.cfg.customWallpaperUrl && root.cfg.customWallpaperUrl !== "") {
            return root.cfg.customWallpaperUrl;
        }
        if (root.cfg.wallpaperMode === 1) return wpDirUrl + "win11-bloom-light.jpg";
        if (root.cfg.wallpaperMode === 2) return wpDirUrl + "x64-monolith.jpg";
        return wpDirUrl + "win11-bloom-dark.jpg";
    }
    readonly property string activeLockWallpaperSrc: {
        var lm = (root.cfg.lockWallpaperMode !== undefined) ? Number(root.cfg.lockWallpaperMode) : -1;
        if (lm === 3 && root.cfg.lockWallpaperUrl && root.cfg.lockWallpaperUrl !== "") return root.cfg.lockWallpaperUrl;
        if (lm === 0) return wpDirUrl + "win11-bloom-dark.jpg";
        if (lm === 1) return wpDirUrl + "win11-bloom-light.jpg";
        if (lm === 2) return wpDirUrl + "x64-monolith.jpg";
        return root.activeWallpaperSrc;
    }

    readonly property string activeAvatarUrl: {
        var a = (root.cfg && root.cfg.userAvatarUrl) ? String(root.cfg.userAvatarUrl) : "";
        if (a !== "") return a;
        return (root.extData && root.extData.account && root.extData.account.avatarUrl) ? String(root.extData.account.avatarUrl) : "";
    }

    readonly property var accData: (root.extData && root.extData.account) ? root.extData.account : ({
        displayName: "", username: "", hostname: "", homeDir: "", shell: "/bin/fish", groups: "", isAdmin: true,
        avatarUrl: "", hasPin: false, sddmAutologin: false, availableShells: [], otherUsers: [], adminCount: 1
    })

    readonly property var tlData: (root.extData && root.extData.timeLang) ? root.extData.timeLang : ({
        timezone: "Local", timezoneId: "UTC", tzOffsetMins: -99999, ntpActive: true, synced: true, localRtc: false,
        locale: "es_ES.UTF-8", installedLocales: [], kbLayout: "ES", kbPrimary: "es", kbSecondary: "us",
        kbToggleOpt: "grp:alt_shift_toggle", repeatRate: 25, repeatDelay: 600, numlock: false
    })

    readonly property var gmData: (root.extData && root.extData.gamingStack) ? root.extData.gamingStack : ({
        sched: "scx_lavd", falcond: false, dmemcg: false, ananicy: false, ntsync: false,
        hasSteam: false, hasHeroic: false, hasLutris: false, hasGoverlay: false, hasMangohud: false,
        hasGamescope: false, hasObs: false, hasX64Hello: false, adaptiveSync: "yes", allowTearing: "no",
        screenshotDir: "", screenshotCount: 0, gamepads: [], appIcons: ({})
    })

    readonly property var updData: (root.extData && root.extData.updateInfo) ? root.extData.updateInfo : ({
        history: [], lastUpgradeDate: "", pkgCount: 0, repos: [], ignorePkgs: [],
        hasPaccacheTimer: true, hasFstrimTimer: true,
        paccacheTimerEnabled: false, fstrimTimerEnabled: false, pacmanCacheHuman: "",
        trayRunning: false, trayAutostartEnabled: true, hasUpdateTray: true,
        runningKernel: "", rebootRequired: false, installedKernels: [], snapperConfigs: [],
        hasSnapPac: false, hasLimineSnapper: false,
        hasBtrfsAssistant: false, hasX64Update: true, hasX64Hello: true,
        isUefi: false, canRebootFirmware: false, cachedCheck: null
    })

    readonly property var filteredUpdHistory: {
        var list = (root.updData && root.updData.history) ? root.updData.history : [];
        var f = root.updHistFilter;
        var q = root.updHistSearch.trim().toLowerCase();
        var out = [];
        for (var i = 0; i < list.length; i++) {
            var it = list[i];
            if (f !== "all" && String(it.action || "") !== f) continue;
            if (q !== "" && String(it.entry || "").toLowerCase().indexOf(q) === -1 && String(it.date || "").toLowerCase().indexOf(q) === -1) continue;
            out.push(it);
        }
        return out;
    }

    readonly property var filteredTimezones: {
        var q = root.tzSearchFilter.trim().toLowerCase();
        if (q === "") return [];
        var src = root.allTimezones || [];
        var out = [];
        for (var i = 0; i < src.length; i++) {
            var tz = String(src[i]);
            if (tz.toLowerCase().indexOf(q) !== -1 || tz.replace(/_/g, " ").toLowerCase().indexOf(q) !== -1) {
                out.push(tz);
                if (out.length >= 18) break;
            }
        }
        return out;
    }

    readonly property string activeDisplayName: {
        if (root.accData && root.accData.displayName && String(root.accData.displayName) !== "") return String(root.accData.displayName);
        return root.sysInfo.user || "Usuario";
    }

    readonly property string activeAccountHandle: {
        var u = (root.accData && root.accData.username) ? String(root.accData.username) : String(root.sysInfo.username || "");
        var h = (root.accData && root.accData.hostname) ? String(root.accData.hostname) : String(root.sysInfo.hostname || "");
        if (u !== "" && h !== "") return u + "@" + h;
        return root.sysInfo.userEmail || "";
    }

    Timer {
        id: toastClearTimer
        interval: 2800; repeat: false
        onTriggered: { root.toastMsg = ""; root.copiedNotice = false; root.copiedOsNotice = false; }
    }

    Timer {
        id: wifiRescanT
        interval: 2400; repeat: false
        onTriggered: {
            root.refreshLiveState();
            root.showToast("Redes Wi-Fi actualizadas");
        }
    }

    function showToast(msg) {
        toastMsg = msg;
        toastClearTimer.restart();
    }

    Timer {
        interval: 1000; running: root.settingsPage === "Hora e idioma"; repeat: true
        onTriggered: root.refreshDisplayedClock()
    }

    component WinSvg : Image {
        property string iconFile: "settings.svg"
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

    component UserAvatarBadge : Rectangle {
        property int sz: 42
        width: sz; height: sz; radius: sz / 2
        Layout.preferredWidth: sz; Layout.preferredHeight: sz
        color: "#2f2f2f"
        border.color: "#32ffffff"; border.width: 1
        Image {
            visible: root.activeAvatarUrl !== ""
            anchors.fill: parent; anchors.margins: 1
            source: root.activeAvatarUrl
            sourceSize.width: Math.max(64, sz * 2)
            sourceSize.height: Math.max(64, sz * 2)
            fillMode: Image.PreserveAspectFit
            mipmap: true; smooth: true; cache: false
        }
        WinSvg {
            visible: root.activeAvatarUrl === ""
            anchors.centerIn: parent
            width: Math.round(sz * 0.52); height: Math.round(sz * 0.52)
            iconFile: "fluent-person.svg"
        }
    }

    // Controlled WinUI 3 Switch: clicking emits toggled(!checked) without breaking QML bindings
    component Win11Switch : Item {
        id: wSwitch
        property bool checked: false
        signal toggled(bool isChecked)
        implicitWidth: 40; implicitHeight: 20
        Layout.preferredWidth: 40; Layout.preferredHeight: 20

        Rectangle {
            anchors.fill: parent; radius: 10
            color: wSwitch.checked ? root.accentColor : (swMouse.containsMouse ? "#24ffffff" : "#14000000")
            border.color: wSwitch.checked ? root.accentColor : "#99ffffff"; border.width: 1
            antialiasing: true
            Behavior on color { ColorAnimation { duration: 130 } }
            Rectangle {
                x: wSwitch.checked ? (swMouse.pressed ? 21 : 23) : 4
                anchors.verticalCenter: parent.verticalCenter
                width: swMouse.pressed ? 14 : 12; height: 12; radius: 6
                color: wSwitch.checked ? "#000000" : "#d8d8d8"
                antialiasing: true
                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 90 } }
            }
        }
        MouseArea {
            id: swMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: wSwitch.toggled(!wSwitch.checked)
        }
    }

    component SettingsSlider : Item {
        id: sSlider
        property real from: 0.0
        property real to: 100.0
        property real value: 80.0
        property bool dragging: sMouse.pressed
        signal movedValue(real v)
        signal releasedValue(real v)
        implicitWidth: 170; implicitHeight: 28
        readonly property real ratio: Math.max(0.0, Math.min(1.0, (value - from) / Math.max(0.001, to - from)))

        Item {
            x: 10; anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, sSlider.width - 20); height: 4
            Rectangle { anchors.fill: parent; radius: 2; color: "#707070" }
            Rectangle { width: sSlider.ratio * parent.width; height: 4; radius: 2; color: root.accentColor }
        }
        Item {
            x: sSlider.ratio * Math.max(0, sSlider.width - 20)
            anchors.verticalCenter: parent.verticalCenter
            width: 20; height: 20
            Image { anchors.fill: parent; source: assetDirUrl + "fluent-slider-outer.svg"; sourceSize.width: 80; sourceSize.height: 80; mipmap: true; smooth: true }
            Image {
                anchors.fill: parent; transformOrigin: Item.Center
                scale: sMouse.pressed ? 0.44 : (sMouse.containsMouse ? 0.68 : 0.56)
                Behavior on scale { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }
                source: assetDirUrl + "fluent-slider-inner.svg"; sourceSize.width: 80; sourceSize.height: 80; mipmap: true; smooth: true
            }
        }
        MouseArea {
            id: sMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            preventStealing: true
            acceptedButtons: Qt.LeftButton
            property bool _lockedDrag: false
            function syncX(mx) {
                var r = Math.max(0.0, Math.min(1.0, (mx - 10.0) / Math.max(1.0, sSlider.width - 20.0)));
                var nv = sSlider.from + r * (sSlider.to - sSlider.from);
                sSlider.value = nv;
                sSlider.movedValue(nv);
            }
            onPressed: (mouse) => {
                if (!_lockedDrag) { _lockedDrag = true; root.activeSliderDrags = root.activeSliderDrags + 1; }
                syncX(mouse.x);
            }
            onPositionChanged: (mouse) => { if (pressed) syncX(mouse.x); }
            onReleased: {
                if (_lockedDrag) { _lockedDrag = false; root.activeSliderDrags = Math.max(0, root.activeSliderDrags - 1); }
                sSlider.releasedValue(sSlider.value);
            }
            onCanceled: {
                if (_lockedDrag) { _lockedDrag = false; root.activeSliderDrags = Math.max(0, root.activeSliderDrags - 1); }
            }
        }
    }

    // Reusable WinUI 3 Fluent Action Button
    component FluentBtn : Rectangle {
        id: fBtn
        property string label: ""
        property bool accent: false
        signal clicked()
        implicitWidth: Math.max(88, fBtnTxt.implicitWidth + 28)
        implicitHeight: 35
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        radius: 6
        color: accent ? (fBtnH.containsMouse ? Qt.lighter(root.accentColor, 1.12) : root.accentColor)
                      : (fBtnH.containsMouse ? "#3b3b3b" : "#303030")
        border.color: accent ? root.accentColor : "#26ffffff"
        border.width: 1
        Text {
            id: fBtnTxt; anchors.centerIn: parent
            text: fBtn.label
            color: fBtn.accent ? "#000000" : "#f2f2f2"
            font.pixelSize: 13
            font.weight: fBtn.accent ? Font.DemiBold : Font.Normal
        }
        MouseArea {
            id: fBtnH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: fBtn.clicked()
        }
    }

    // Reusable Auto-Sizing WinUI 3 Setting Toggle Card (authentic Win11 height & readable typography!)
    component ToggleCard : Rectangle {
        id: tCard
        property string iconFile: "fluent-settings.svg"
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled(bool isChecked)
        width: parent ? parent.width : 400
        implicitHeight: Math.max(66, tRow.implicitHeight + 30)
        radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1

        RowLayout {
            id: tRow
            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
            WinSvg { width: 21; height: 21; iconFile: tCard.iconFile }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: tCard.title; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { visible: tCard.subtitle !== ""; text: tCard.subtitle; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            Win11Switch { checked: tCard.checked; onToggled: (v) => tCard.toggled(v) }
        }
    }

    // Reusable WinUI 3 Hub Navigation Card (Windows 11 26H2 Subpage Directory Style!)
    component HubNavCard : Rectangle {
        id: hCard
        property string iconFile: "fluent-settings.svg"
        property string title: ""
        property string subtitle: ""
        property string badge: ""
        signal clicked()
        width: parent ? parent.width : 400
        implicitHeight: Math.max(70, hRow.implicitHeight + 32)
        radius: 7
        color: hCardHov.containsMouse ? "#2e2e2e" : "#262626"
        border.color: hCardHov.containsMouse ? "#2cffffff" : "#1cffffff"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }

        RowLayout {
            id: hRow
            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
            WinSvg { width: 21; height: 21; iconFile: hCard.iconFile }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: hCard.title; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { visible: hCard.subtitle !== ""; text: hCard.subtitle; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            Text {
                visible: hCard.badge !== ""
                text: hCard.badge; color: root.accentColor; font.pixelSize: 12; font.weight: Font.DemiBold
                elide: Text.ElideRight; Layout.maximumWidth: 200
            }
            WinSvg { width: 13; height: 13; iconFile: "fluent-chevron-right.svg"; opacity: 0.75 }
        }
        MouseArea {
            id: hCardHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: hCard.clicked()
        }
    }

    function updateCfg(key, val) {
        cfgWriteGuardUntil = Date.now() + 2500;
        var copy = Object.assign({}, cfg);
        copy[key] = val;
        cfg = copy;
        bridge.setConfigValue(key, JSON.stringify(val));
    }

    function applyPhonePref(key, val, toastTxt) {
        updateCfg(key, val);
        var pl = (extData && extData.phoneLink) ? extData.phoneLink : {};
        if (pl.mirrorActive) {
            bridge.phoneMirrorStart(pl.mirrorSerial || "");
            showToast(toastTxt + " (aplicado en pantalla activa)");
        } else if (toastTxt) {
            showToast(toastTxt);
        }
    }

    function saveInputPatch(patch) {
        var cur = Object.assign({
            mouseSpeed: 0.0, mouseAccel: "adaptive", mouseLeftHanded: false,
            mouseNaturalScroll: false, mouseScrollFactor: 1.0, mouseMiddleEmulation: false,
            tpSendEvents: "yes", tpTap: true, tpTapAndDrag: true, tpThreeFingerDrag: false,
            tpNaturalScroll: true, tpDisableTyping: true, tpClickMethod: "clickfinger", tpSpeed: 0.0
        }, extData.inputCfg || {}, patch || {});
        var extCopy = Object.assign({}, extData);
        extCopy.inputCfg = cur;
        extData = extCopy;
        localMouseSpeed = Number(cur.mouseSpeed || 0.0);
        localTpSpeed = Number(cur.tpSpeed || 0.0);
        var ok = bridge.saveInputConfigJson(JSON.stringify(cur));
        if (!ok) showToast("No se pudo guardar la configuración de entrada");
        return ok;
    }

    function applyLiveBundle(jsonStr) {
        if (activeSliderDrags > 0) return;
        try {
            var data = JSON.parse(jsonStr);
            if (data.cfg && !data.cfgStale && Date.now() >= cfgWriteGuardUntil) {
                cfg = Object.assign({}, cfg, data.cfg);
            }
            if (data.hwState) {
                if (Date.now() < powerProfileLockUntil && lockedPowerProfile !== "") {
                    data.hwState.powerProfile = lockedPowerProfile;
                }
                hwState = data.hwState;
            }
            if (data.drives) drives = data.drives;
            if (data.extData) {
                extData = data.extData;
                if (!checkingUpdates && data.extData.updateInfo && data.extData.updateInfo.cachedCheck && data.extData.updateInfo.cachedCheck.count >= 0 && (!updateResult.error || String(updateResult.error) === "")) {
                    updateResult = data.extData.updateInfo.cachedCheck;
                }
            }
        } catch (e) {}
        if (!brightDragging) localBrightPct = Math.round(Number(hwState.brightnessPct !== undefined ? hwState.brightnessPct : 100));
        if (!volDragging) localVolPct = Math.round(Number(hwState.volumePct !== undefined ? hwState.volumePct : 80));
        if (!micDragging) localMicPct = Math.round(Number(extData.micVol !== undefined ? extData.micVol : 50));
        if (!nightStrDragging && cfg.nightLightStrength !== undefined) localNightStrength = Math.round(Number(cfg.nightLightStrength));
        if (!mouseSpeedDragging && extData.inputCfg && extData.inputCfg.mouseSpeed !== undefined) localMouseSpeed = Number(extData.inputCfg.mouseSpeed);
        if (!tpSpeedDragging && extData.inputCfg && extData.inputCfg.tpSpeed !== undefined) localTpSpeed = Number(extData.inputCfg.tpSpeed);
        if (typeof dispNameIn !== "undefined" && !dispNameIn.activeFocus) {
            dispNameIn.text = activeDisplayName;
        }
        var now = new Date();
        clockTimeStr = Boolean(cfg.clock12h) ? Qt.formatTime(now, "h:mm:ss AP") : Qt.formatTime(now, "hh:mm:ss");
    }

    // 100% Non-Blocking Async Refresh (ZERO UI freeze on tab clicks or background polling!)
    function refreshLiveState(forceSlow) {
        if (Date.now() >= cfgWriteGuardUntil) {
            try { cfg = Object.assign({}, cfg, JSON.parse(bridge.getConfigJson())); } catch (e) {}
        }
        var now = new Date();
        clockTimeStr = Boolean(cfg.clock12h) ? Qt.formatTime(now, "h:mm:ss AP") : Qt.formatTime(now, "hh:mm:ss");
        bridge.requestAsyncRefresh(Boolean(forceSlow));
    }

    function runUpdateCheck() {
        if (checkingUpdates) return;
        checkingUpdates = true;
        bridge.startAsyncUpdateCheck();
    }

    function tryConnectWifi(ssid) {
        var res = bridge.connectWifi(ssid, "");
        if (res === "ok") {
            refreshLiveState(false);
            showToast("Conectado a " + ssid);
        } else if (res === "need_password") {
            wifiPassSsid = ssid;
            wifiPassErr = "";
            wifiPassField.text = "";
            wifiPassModalOpen = true;
            wifiPassField.forceActiveFocus();
        } else {
            showToast(res.replace(/^error:/, "") || "No se pudo conectar");
        }
    }

    Component.onCompleted: {
        try { cfg = Object.assign({}, cfg, JSON.parse(bridge.getConfigJson())); } catch (e) {}
        try { sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
        reloadAccountInfo();
        reloadTimeLangInfo();
        reloadGamingInfo();
        reloadUpdateInfo();
        if (root.settingsPage === "Hora e idioma" && root.settingsSubPage === "Fecha y hora") {
            try { root.allTimezones = JSON.parse(bridge.getAllTimezonesJson()); } catch (e) {}
        }
        bridge.requestAsyncRefresh(false);
        deferAppsTimer.start();
    }

    Timer {
        id: deferAppsTimer
        interval: 180; running: false; repeat: false
        onTriggered: {
            root.reloadInstalledApps();
            root.reloadStartupApps();
            if (root.pendingUninstallTarget !== "") {
                var tgt = root.pendingUninstallTarget;
                root.pendingUninstallTarget = "";
                root.openUninstallWizardForTarget(tgt);
            }
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            var now = new Date();
            root.clockTimeStr = Boolean(root.cfg.clock12h) ? Qt.formatTime(now, "h:mm:ss AP") : Qt.formatTime(now, "hh:mm:ss");
            bridge.requestAsyncRefresh(false);
        }
    }

    readonly property var navCategories: [
        { icon: "fluent-grid.svg",        name: "Inicio",                    kw: "inicio resumen casa home" },
        { icon: "fluent-display.svg",     name: "Sistema",                   kw: "sistema pantalla monitor escala resolucion hz brillo luz nocturna sonido audio volumen microfono energia bateria rendimiento almacenamiento disco acerca especificaciones cpu ram gpu no molestar notificaciones" },
        { icon: "fluent-bluetooth.svg",   name: "Bluetooth y dispositivos",  kw: "bluetooth dispositivos emparejar auriculares mando telefono enlace movil kde connect impresoras escaneres" },
        { icon: "fluent-wifi.svg",        name: "Red e Internet",            kw: "red internet wifi ethernet cable vpn wireguard openvpn avion modo avion ip dns puerta enlace mac adaptadores trafico datos firewall ufw bbr conectar desconectar olvidar" },
        { icon: "fluent-paint-brush.svg", name: "Personalización",           kw: "personalizacion fondo wallpaper tema foto color acento enfasis transparencia oscuro claro barra tareas compacta izquierda buscar vista tareas clima menu inicio bloqueo win+l iconos escritorio cursor puntero" },
        { icon: "fluent-apps-list.svg",   name: "Aplicaciones",              kw: "aplicaciones programas instaladas desinstalar quitar eliminar predeterminadas navegador correo fotos pdf video musica terminal tienda shelly inicio arranque autostart flatpak pacman" },
        { icon: "fluent-person.svg",      name: "Cuentas",                   kw: "cuentas usuario perfil avatar foto imagen nombre contrasena bloquear administrador sddm" },
        { icon: "fluent-keyboard.svg",    name: "Hora e idioma",             kw: "hora fecha reloj 12h 24h segundos idioma region locale teclado escritura distribucion es us latam zona horaria ntp rtc dual boot numlock repeticion" },
        { icon: "fluent-games.svg",       name: "Juegos",                    kw: "juegos gaming modo juego scx lavd falcond dmemcg ananicy ntsync steam heroic lutris fps gpu" },
        { icon: "update.svg",             name: "Actualización del sistema", kw: "actualizacion sistema update paquetes pacman aur flatpak kernel historial comprobar btrfs snapper snapshot copias recuperacion uefi bios paccache fstrim trim repositorios mantenimiento bandeja tray" }
    ]

    function matchesNavFilter(cat) {
        var q = root.navFilter.trim().toLowerCase();
        if (q === "") return true;
        return cat.name.toLowerCase().indexOf(q) !== -1 || String(cat.kw || "").indexOf(q) !== -1;
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // =====================================================================
        // [A] RESPONSIVE LEFT NAVIGATION RAIL (Auto-compacts cleanly on narrow windows!)
        // =====================================================================
        Rectangle {
            Layout.preferredWidth: root.compactNav ? 62 : (root.wideBody ? 280 : 254)
            Layout.fillHeight: true
            color: "#202020"
            Behavior on Layout.preferredWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.compactNav ? 8 : 14
                spacing: 10

                // Hamburger Toggle (visible when window is narrow so user can expand/collapse nav anytime)
                Rectangle {
                    visible: root.width < 820
                    Layout.fillWidth: true; height: 34; radius: 5
                    color: hamHov.containsMouse ? "#2c2c2c" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 10
                        WinSvg { width: 16; height: 16; iconFile: "fluent-apps-list.svg" }
                        Text { visible: !root.compactNav; text: "Menú de configuración"; color: "#e6e6e6"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                    MouseArea {
                        id: hamHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.navExpandedManual = !root.navExpandedManual
                    }
                }

                // User Profile Card (Clicking jumps straight to "Cuentas"!)
                Rectangle {
                    Layout.fillWidth: true
                    height: root.compactNav ? 46 : 60
                    radius: 6
                    color: root.settingsPage === "Cuentas" ? "#2d2d2d" : (accHov.containsMouse ? "#282828" : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.compactNav ? 4 : 8
                        anchors.rightMargin: root.compactNav ? 4 : 8
                        spacing: 12
                        UserAvatarBadge { sz: root.compactNav ? 36 : 44 }
                        ColumnLayout {
                            visible: !root.compactNav
                            Layout.fillWidth: true; spacing: 1
                            Text {
                                text: root.activeDisplayName
                                color: "#f5f5f5"; font.weight: Font.DemiBold; font.pixelSize: 13
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Text {
                                text: (root.sysInfo.username || "usuario") + "@" + (root.sysInfo.hostname || "PC")
                                color: "#9e9e9e"; font.pixelSize: 11
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                        }
                    }
                    MouseArea {
                        id: accHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.navigateTo("Cuentas", "", true)
                    }
                }

                // Clipped WinUI 3 Search Settings Input (hidden in icon-only compact rail)
                Rectangle {
                    visible: !root.compactNav
                    Layout.fillWidth: true
                    height: 34; radius: 5; clip: true
                    color: navSearchIn.activeFocus ? "#161616" : "#2a2a2a"
                    border.color: "#24ffffff"; border.width: 1

                    Rectangle {
                        anchors.bottom: parent.bottom; width: parent.width
                        height: navSearchIn.activeFocus ? 2 : 1
                        color: navSearchIn.activeFocus ? root.accentColor : "#44ffffff"
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 6
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                            Text {
                                visible: navSearchIn.text === ""
                                anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                text: "Buscar una configuración"; color: "#9a9a9a"; font.pixelSize: 12; elide: Text.ElideRight
                            }
                            TextInput {
                                id: navSearchIn
                                anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                                onTextChanged: root.navFilter = text
                                onAccepted: {
                                    var q = text.trim().toLowerCase();
                                    if (q === "") return;
                                    var subHits = [
                                        { kw: ["pantalla", "monitor", "escala", "resolucion", "brillo", "hz", "rotacion", "vrr", "nocturna"], p: "Sistema", s: "Pantalla" },
                                        { kw: ["sonido", "audio", "volumen", "microfono", "altavoz", "pipewire"], p: "Sistema", s: "Sonido" },
                                        { kw: ["notificacion", "molestar", "concentracion"], p: "Sistema", s: "Notificaciones" },
                                        { kw: ["energia", "bateria", "ahorro", "equilibrado"], p: "Sistema", s: "Energía y batería" },
                                        { kw: ["almacenamiento", "disco", "papelera", "espacio", "cache"], p: "Sistema", s: "Almacenamiento" },
                                        { kw: ["acerca", "especificaciones", "hostname", "cpu", "ram", "gpu", "kernel"], p: "Sistema", s: "Acerca de" },
                                        { kw: ["mouse", "raton", "puntero", "aceleracion", "rueda", "zurdo"], p: "Bluetooth y dispositivos", s: "Mouse" },
                                        { kw: ["touchpad", "panel tactil", "tactil", "trackpad"], p: "Bluetooth y dispositivos", s: "Panel táctil" },
                                        { kw: ["usb", "periferico", "dac", "receptor"], p: "Bluetooth y dispositivos", s: "Dispositivos USB" },
                                        { kw: ["impresora", "escaner", "cups"], p: "Bluetooth y dispositivos", s: "Impresoras y escáneres" },
                                        { kw: ["movil", "telefono", "enlace", "scrcpy", "kde connect", "android"], p: "Bluetooth y dispositivos", s: "Dispositivos móviles" },
                                        { kw: ["wifi", "wi-fi", "inalambrica"], p: "Red e Internet", s: "Wi-Fi" },
                                        { kw: ["ethernet", "cable", "rj45"], p: "Red e Internet", s: "Ethernet" },
                                        { kw: ["vpn", "openvpn", "wireguard"], p: "Red e Internet", s: "VPN" },
                                        { kw: ["adaptador", "red avanzada", "bbr", "trafico"], p: "Red e Internet", s: "Configuración de red avanzada" },
                                        { kw: ["fondo", "wallpaper", "imagen", "color solido"], p: "Personalización", s: "Fondo" },
                                        { kw: ["color", "acento", "enfasis", "transparencia", "tema oscuro", "tema claro"], p: "Personalización", s: "Colores" },
                                        { kw: ["barra de tareas", "buscar", "widgets", "clima", "compacta"], p: "Personalización", s: "Barra de tareas" },
                                        { kw: ["menu inicio", "recomendado", "categoria", "cuadricula"], p: "Personalización", s: "Inicio" },
                                        { kw: ["bloqueo", "win+l"], p: "Personalización", s: "Pantalla de bloqueo" },
                                        { kw: ["cursor", "puntero", "iconos escritorio"], p: "Personalización", s: "Escritorio y puntero" },
                                        { kw: ["desinstalar", "quitar programa", "aplicaciones instaladas", "programas", "flatpak"], p: "Aplicaciones", s: "Aplicaciones instaladas" },
                                        { kw: ["predeterminadas", "navegador", "mime", "pdf", "terminal predeterminada", "correo"], p: "Aplicaciones", s: "Aplicaciones predeterminadas" },
                                        { kw: ["autostart", "arranque", "aplicaciones de inicio"], p: "Aplicaciones", s: "Inicio" },
                                        { kw: ["tu informacion", "avatar", "foto de cuenta", "perfil", "shell", "nombre visible"], p: "Cuentas", s: "Tu información" },
                                        { kw: ["inicio de sesion", "contrasena", "contraseña", "pin", "autologin", "sddm"], p: "Cuentas", s: "Opciones de inicio de sesión" },
                                        { kw: ["otros usuarios", "agregar cuenta", "nuevo usuario", "cuentas locales"], p: "Cuentas", s: "Otros usuarios" },
                                        { kw: ["fecha y hora", "zona horaria", "ntp", "reloj", "segundos", "dual boot", "rtc"], p: "Hora e idioma", s: "Fecha y hora" },
                                        { kw: ["idioma y region", "idioma", "region", "locale", "formato regional"], p: "Hora e idioma", s: "Idioma y región" },
                                        { kw: ["escritura", "teclado", "distribucion", "repeticion", "numlock", "bloq num"], p: "Hora e idioma", s: "Escritura y teclado" },
                                        { kw: ["modo de juego", "modo juego", "tearing", "vrr gaming", "falcond", "ntsync", "scx"], p: "Juegos", s: "Modo de juego" },
                                        { kw: ["captura", "capturas", "recorte", "screenshot", "obs", "grabar"], p: "Juegos", s: "Capturas" },
                                        { kw: ["mando", "gamepad", "control", "steam", "heroic", "lutris", "goverlay", "mangohud", "gamescope"], p: "Juegos", s: "Bibliotecas y mandos" },
                                        { kw: ["historial", "pacman.log", "actualizaciones recientes"], p: "Actualización del sistema", s: "Historial de actualizaciones" },
                                        { kw: ["opciones avanzadas", "repositorios", "paccache", "fstrim", "trim", "mantenimiento"], p: "Actualización del sistema", s: "Opciones avanzadas" },
                                        { kw: ["recuperacion", "btrfs", "snapshot", "snapper", "uefi", "bios", "copias"], p: "Actualización del sistema", s: "Recuperación y copias" }
                                    ];
                                    for (var si = 0; si < subHits.length; si++) {
                                        for (var ki = 0; ki < subHits[si].kw.length; ki++) {
                                            if (q.indexOf(subHits[si].kw[ki]) !== -1) {
                                                root.navigateTo(subHits[si].p, subHits[si].s, true);
                                                return;
                                            }
                                        }
                                    }
                                    for (var i = 0; i < root.navCategories.length; i++) {
                                        if (root.matchesNavFilter(root.navCategories[i])) {
                                            root.navigateTo(root.navCategories[i].name, "", true);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        WinSvg {
                            width: 13; height: 13
                            iconFile: navSearchIn.text !== "" ? "fluent-dismiss.svg" : "fluent-search.svg"
                            opacity: 0.8
                            MouseArea {
                                anchors.fill: parent; enabled: navSearchIn.text !== ""
                                cursorShape: Qt.PointingHandCursor
                                onClicked: navSearchIn.text = ""
                            }
                        }
                    }
                }

                // Scrollable 10 Official Categories
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: width; contentHeight: navListCol.implicitHeight + 8
                    clip: true

                    Column {
                        id: navListCol
                        width: parent.width; spacing: 3

                        Repeater {
                            model: root.navCategories
                            delegate: Rectangle {
                                visible: root.compactNav || root.matchesNavFilter(modelData)
                                width: navListCol.width; height: root.wideBody ? 40 : 36; radius: 6
                                color: root.settingsPage === modelData.name ? "#2d2d2d" : (catHov.containsMouse ? "#262626" : "transparent")
                                Rectangle {
                                    visible: root.settingsPage === modelData.name
                                    x: 2; anchors.verticalCenter: parent.verticalCenter
                                    width: 3; height: 18; radius: 1.5; color: root.accentColor
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.compactNav ? 14 : 12
                                    anchors.rightMargin: 8; spacing: 12
                                    WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                                    Text {
                                        visible: !root.compactNav
                                        text: modelData.name; color: "#f2f2f2"; font.pixelSize: root.wideBody ? 13 : 12
                                        font.weight: root.settingsPage === modelData.name ? Font.DemiBold : Font.Normal
                                        Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: catHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.navigateTo(modelData.name, "", true);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // [B] RIGHT MAIN CONTENT SURFACE (Balanced Win11 Proportions + 0-Clip!)
        // =====================================================================
        Rectangle {
            id: contentPane
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1b1b1b"
            radius: 8
            clip: true

            Flickable {
                id: mainFlick
                anchors.fill: parent
                anchors.margins: root.narrowBody ? 16 : (root.wideBody ? 34 : 24)
                contentWidth: width
                contentHeight: bodyCol.implicitHeight + 36
                clip: true
                interactive: root.activeSliderDrags === 0
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                NumberAnimation {
                    id: flickScrollAnim
                    target: mainFlick; property: "contentY"
                    duration: 210; easing.type: Easing.OutCubic
                }

                Column {
                    id: bodyCol
                    // Balanced Win11 26H2 reading width: 1240px for 3-col Home Bento, 1040px for list pages!
                    width: Math.min(parent.width, root.settingsPage === "Inicio" ? 1240 : 1040)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.wideBody ? 18 : 14

                    // Authentic Windows 11 26H2 Breadcrumb Header + Back Button + Live Toast Feedback
                    RowLayout {
                        width: parent.width; spacing: 10
                        Rectangle {
                            visible: root.canGoBack
                            Layout.preferredWidth: 34; Layout.preferredHeight: 34; radius: 6
                            color: hdrBackHov.containsMouse ? "#2cffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-arrow-left.svg" }
                            MouseArea { id: hdrBackHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goBackNav() }
                        }
                        RowLayout {
                            Layout.fillWidth: true; Layout.minimumWidth: 0; spacing: 10
                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: root.settingsSubPage === ""
                                Layout.maximumWidth: root.settingsSubPage !== "" ? (root.narrowBody ? 220 : 380) : 1200
                                text: root.settingsPage
                                color: root.settingsSubPage !== "" ? (bcRootHov.containsMouse ? "#ffffff" : "#a8a8a8") : "#f5f5f5"
                                font.pixelSize: root.narrowBody ? 22 : (root.wideBody ? 28 : 25)
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                MouseArea {
                                    id: bcRootHov; anchors.fill: parent; hoverEnabled: true
                                    enabled: root.settingsSubPage !== ""
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.navigateTo(root.settingsPage, "", true)
                                }
                            }
                            WinSvg {
                                visible: root.settingsSubPage !== ""
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 15; Layout.preferredHeight: 15
                                iconFile: "fluent-chevron-right.svg"; opacity: 0.7
                            }
                            Text {
                                visible: root.settingsSubPage !== ""
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true; Layout.minimumWidth: 60
                                text: root.settingsSubPage
                                color: "#f5f5f5"
                                font.pixelSize: root.narrowBody ? 22 : (root.wideBody ? 28 : 25)
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                        Rectangle {
                            visible: root.toastMsg !== ""
                            Layout.preferredWidth: Math.min(280, toastTxt.implicitWidth + 22)
                            Layout.preferredHeight: 30; radius: 6
                            color: Qt.alpha(root.accentColor, 0.15); border.color: root.accentColor; border.width: 1
                            Text {
                                id: toastTxt; anchors.centerIn: parent
                                width: Math.min(258, implicitWidth)
                                text: root.toastMsg; color: "#ffffff"; font.pixelSize: 12; elide: Text.ElideRight
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 0: INICIO (Windows 11 26H2 Balanced 3-Column Bento Dashboard!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: root.wideBody ? 18 : 14
                        visible: root.settingsPage === "Inicio"

                        // Authentic Win11 Home Device Header (Inline chips when wide -> ZERO dead middle void!)
                        Rectangle {
                            width: parent.width
                            implicitHeight: homeHeroCol.implicitHeight + 36
                            radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1

                            ColumnLayout {
                                id: homeHeroCol
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                anchors.margins: 18; spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 18
                                    // Device identity (clickable -> Sistema › Acerca de)
                                    Rectangle {
                                        Layout.fillWidth: true; implicitHeight: heroIdentRow.implicitHeight
                                        color: "transparent"
                                        RowLayout {
                                            id: heroIdentRow; anchors.left: parent.left; anchors.right: parent.right; spacing: 16
                                            // Exact 16:9 desktop preview frame
                                            Rectangle {
                                                width: root.narrowBody ? 88 : (root.wideBody ? 144 : 112)
                                                height: Math.round(width * 9 / 16)
                                                radius: 6
                                                color: "#000000"; border.color: "#4a4a4a"; border.width: 2; clip: true
                                                Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: root.activeWallpaperSrc; fillMode: Image.PreserveAspectCrop }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 4
                                                Text { text: root.sysInfo.hostname || "Equipo X64"; color: heroIdH.containsMouse ? root.accentColor : "#f5f5f5"; font.pixelSize: root.wideBody ? 21 : 17; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: root.sysInfo.cpu || ""; color: "#b0b0b0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: "X64 LIOS • " + (root.sysInfo.ram || "") + " • " + (root.hwState.monitors || ""); color: root.accentColor; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                            }
                                        }
                                        MouseArea { id: heroIdH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Sistema", "Acerca de", true) }
                                    }

                                    // Inline right-side Quick Action Pills when wide (eliminates horizontal empty void!)
                                    Row {
                                        visible: root.wideBody
                                        spacing: 10
                                        Rectangle {
                                            width: wNetRow.implicitWidth + 24; height: 38; radius: 6
                                            color: wNetH.containsMouse ? "#343434" : "#2d2d2d"; border.color: "#22ffffff"
                                            Row {
                                                id: wNetRow; anchors.centerIn: parent; spacing: 8
                                                WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 17; height: 17; iconFile: root.netChipIcon }
                                                Text { anchors.verticalCenter: parent.verticalCenter; text: root.netChipLabel; color: "#f2f2f2"; font.pixelSize: 13 }
                                            }
                                            MouseArea { id: wNetH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Red e Internet", "", true) }
                                        }
                                        Rectangle {
                                            width: wUpdRow.implicitWidth + 24; height: 38; radius: 6
                                            color: wUpdH.containsMouse ? "#343434" : "#2d2d2d"; border.color: "#22ffffff"
                                            Row {
                                                id: wUpdRow; anchors.centerIn: parent; spacing: 8
                                                WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 17; height: 17; iconFile: "update.svg" }
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: root.updateResult.count > 0 ? ("Actualizaciones (" + root.updateResult.count + ")") : "Actualizaciones"
                                                    color: root.updateResult.count > 0 ? root.accentColor : "#f2f2f2"; font.pixelSize: 13
                                                }
                                            }
                                            MouseArea { id: wUpdH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Actualización del sistema", "", true) }
                                        }
                                        FluentBtn {
                                            height: 38
                                            label: "Cambiar nombre"
                                            onClicked: root.openRenamePcModal()
                                        }
                                    }
                                    FluentBtn {
                                        visible: !root.wideBody && !root.narrowBody
                                        label: "Cambiar nombre"
                                        onClicked: root.openRenamePcModal()
                                    }
                                }

                                // Wrapped status chips on medium / narrow windows
                                Flow {
                                    visible: !root.wideBody
                                    Layout.fillWidth: true; spacing: 8
                                    Rectangle {
                                        width: stNetRow.implicitWidth + 20; height: 34; radius: 6
                                        color: hNetH.containsMouse ? "#323232" : "#2c2c2c"; border.color: "#1effffff"
                                        Row {
                                            id: stNetRow; anchors.centerIn: parent; spacing: 8
                                            WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; iconFile: root.netChipIcon }
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: root.netChipLabel; color: "#f0f0f0"; font.pixelSize: 12 }
                                        }
                                        MouseArea { id: hNetH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Red e Internet", "", true) }
                                    }
                                    Rectangle {
                                        width: stUpdRow.implicitWidth + 20; height: 34; radius: 6
                                        color: hUpdH.containsMouse ? "#323232" : "#2c2c2c"; border.color: "#1effffff"
                                        Row {
                                            id: stUpdRow; anchors.centerIn: parent; spacing: 8
                                            WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; iconFile: "update.svg" }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.updateResult.count > 0 ? ("Actualizaciones (" + root.updateResult.count + ")") : "Actualización del sistema"
                                                color: root.updateResult.count > 0 ? root.accentColor : "#f0f0f0"; font.pixelSize: 12
                                            }
                                        }
                                        MouseArea { id: hUpdH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Actualización del sistema", "", true) }
                                    }
                                    Rectangle {
                                        width: stAccRow.implicitWidth + 20; height: 34; radius: 6
                                        color: hAccH.containsMouse ? "#323232" : "#2c2c2c"; border.color: "#1effffff"
                                        Row {
                                            id: stAccRow; anchors.centerIn: parent; spacing: 8
                                            WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; iconFile: "fluent-person.svg" }
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Cuenta y perfil"; color: "#f0f0f0"; font.pixelSize: 12 }
                                        }
                                        MouseArea { id: hAccH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Cuentas", "", true) }
                                    }
                                }
                            }
                        }

                        // Balanced 3-Column Bento when maximized (>=1320px), 2-Column medium, 1-Column narrow!
                        GridLayout {
                            width: parent.width
                            columns: root.width >= 1320 ? 3 : (root.narrowBody ? 1 : 2)
                            rowSpacing: 16; columnSpacing: 16

                            // Card 1: Configuración recomendada (Tall, generous WinUI 3 rows)
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                implicitHeight: recCol.implicitHeight + 36
                                radius: 8; color: "#262626"; border.color: "#1effffff"; border.width: 1
                                ColumnLayout {
                                    id: recCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 8
                                    Text { text: "Configuración recomendada"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Text { text: "Accesos rápidos frecuentes del equipo"; color: "#9a9a9a"; font.pixelSize: 12 }
                                    Item { height: 4 }
                                    Repeater {
                                        model: [
                                            { icon: "fluent-display.svg",      label: "Pantalla y escala de monitores", page: "Sistema",         sub: "Pantalla" },
                                            { icon: "fluent-speaker-high.svg", label: "Salida de audio PipeWire",       page: "Sistema",         sub: "Sonido" },
                                            { icon: "fluent-person.svg",       label: "Imagen de perfil y cuenta",      page: "Cuentas",         sub: "" },
                                            { icon: "fluent-paint-brush.svg",  label: "Fondo de escritorio y barra",    page: "Personalización", sub: "" }
                                        ]
                                        delegate: Rectangle {
                                            Layout.fillWidth: true; height: 46; radius: 6
                                            color: rLinkH.containsMouse ? "#333333" : "#202020"
                                            border.color: rLinkH.containsMouse ? "#28ffffff" : "#12ffffff"
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                                                WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                                                Text { text: modelData.label; color: "#f2f2f2"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                                WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                            }
                                            MouseArea { id: rLinkH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo(modelData.page, modelData.sub, true) }
                                        }
                                    }
                                }
                            }

                            // Card 2: Personaliza tu dispositivo (2x2 TRUE 16:9 wallpaper grid — NEVER squashed!)
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                implicitHeight: persHomeCol.implicitHeight + 36
                                radius: 8; color: "#262626"; border.color: "#1effffff"; border.width: 1
                                ColumnLayout {
                                    id: persHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Personaliza tu dispositivo"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        Text {
                                            text: "Personalización ›"; color: pMoreH.containsMouse ? "#7cd4ff" : root.accentColor; font.pixelSize: 12; font.weight: Font.Medium
                                            MouseArea { id: pMoreH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Personalización", "", true) }
                                        }
                                    }
                                    GridLayout {
                                        Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 8
                                        Repeater {
                                            model: [
                                                { mode: 0, src: wpDirUrl + "win11-bloom-dark.jpg" },
                                                { mode: 1, src: wpDirUrl + "win11-bloom-light.jpg" },
                                                { mode: 2, src: wpDirUrl + "x64-monolith.jpg" }
                                            ]
                                            delegate: Rectangle {
                                                Layout.fillWidth: true
                                                implicitHeight: Math.max(68, Math.round(width * 9 / 16))
                                                radius: 6; clip: true
                                                border.color: root.cfg.wallpaperMode === modelData.mode ? root.accentColor : "#33ffffff"
                                                border.width: root.cfg.wallpaperMode === modelData.mode ? 2 : 1
                                                Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: modelData.src; fillMode: Image.PreserveAspectCrop }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.updateCfg("wallpaperMode", modelData.mode) }
                                            }
                                        }
                                        // 4th Slot: User's custom photo or "+ Foto" picker (true 16:9!)
                                        Rectangle {
                                            readonly property bool hasCustom: Boolean(root.cfg.customWallpaperUrl && root.cfg.customWallpaperUrl !== "")
                                            Layout.fillWidth: true
                                            implicitHeight: Math.max(68, Math.round(width * 9 / 16))
                                            radius: 6; clip: true; color: "#202020"
                                            border.color: (root.cfg.wallpaperMode === 3 && hasCustom) ? root.accentColor : "#33ffffff"
                                            border.width: (root.cfg.wallpaperMode === 3 && hasCustom) ? 2 : 1
                                            Image {
                                                visible: parent.hasCustom
                                                anchors.fill: parent; anchors.margins: 2; cache: false
                                                source: root.cfg.customWallpaperUrl || ""; fillMode: Image.PreserveAspectCrop
                                            }
                                            Column {
                                                visible: !parent.hasCustom; anchors.centerIn: parent; spacing: 4
                                                WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 18; height: 18; iconFile: "fluent-image.svg"; opacity: 0.78 }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Elegir foto"; color: "#a8a8a8"; font.pixelSize: 11 }
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (parent.hasCustom && root.cfg.wallpaperMode !== 3) {
                                                        root.updateCfg("wallpaperMode", 3);
                                                    } else {
                                                        var u = bridge.pickAndSetWallpaper();
                                                        if (u && u !== "") { root.refreshLiveState(false); root.showToast("Fondo personalizado aplicado"); }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Luz nocturna"; color: "#ececec"; font.pixelSize: 13; Layout.fillWidth: true }
                                        Win11Switch { checked: Boolean(root.cfg.nightLight); onToggled: (v) => root.updateCfg("nightLight", v) }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Barra de tareas compacta"; color: "#ececec"; font.pixelSize: 13; Layout.fillWidth: true }
                                        Win11Switch { checked: Boolean(root.cfg.taskbarCompact); onToggled: (v) => root.updateCfg("taskbarCompact", v) }
                                    }
                                }
                            }

                            // Card 3: Almacenamiento (Disks + Trash/Pacman summary -> balanced height!)
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                implicitHeight: stoHomeCol.implicitHeight + 36
                                radius: 8; color: stoHomeH.containsMouse ? "#2b2b2b" : "#262626"; border.color: "#1effffff"; border.width: 1
                                MouseArea { id: stoHomeH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Sistema", "Almacenamiento", true) }
                                ColumnLayout {
                                    id: stoHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 20; height: 20; iconFile: "drive-c.svg" }
                                        Text { text: "Almacenamiento" + (root.physicalDrives.length > 1 ? (" (" + root.physicalDrives.length + " discos)") : ""); color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                    }
                                    Repeater {
                                        model: root.physicalDrives.slice(0, 2)
                                        delegate: ColumnLayout {
                                            Layout.fillWidth: true; spacing: 5
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: modelData.name; color: "#ececec"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: modelData.mounted ? (Math.round(Number(modelData.usedRatio || 0) * 100) + "%") : "Sin montar"; color: modelData.mounted ? root.accentColor : "#9a9a9a"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; height: 8; radius: 4; color: "#383838"
                                                Rectangle { visible: Boolean(modelData.mounted); width: Math.max(8, parent.width * Number(modelData.usedRatio || 0.04)); height: 8; radius: 4; color: modelData.isCritical ? "#d13438" : root.accentColor }
                                            }
                                            Text { text: modelData.info; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; implicitHeight: stoSumRow.implicitHeight + 18; radius: 6; color: "#202020"; border.color: "#14ffffff"
                                        RowLayout {
                                            id: stoSumRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 10; spacing: 10
                                            WinSvg { width: 16; height: 16; iconFile: "fluent-delete.svg" }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: "Limpieza del sistema"; color: "#e6e6e6"; font.pixelSize: 12; font.weight: Font.Medium }
                                                Text {
                                                    text: "Papelera: " + ((root.extData.storageExtras && root.extData.storageExtras.trashSize) || "0 B")
                                                          + "  •  Caché: " + ((root.extData.storageExtras && root.extData.storageExtras.pacmanCacheSize) || "0 B")
                                                    color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Card 4: Bluetooth y energía (Compact substantial buttons, USB summary!)
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                implicitHeight: btHomeCol.implicitHeight + 36
                                radius: 8; color: "#262626"; border.color: "#1effffff"; border.width: 1
                                ColumnLayout {
                                    id: btHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 20; height: 20; iconFile: "fluent-bluetooth.svg" }
                                        Text {
                                            text: "Bluetooth y energía"; color: btHdrH.containsMouse ? root.accentColor : "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true
                                            MouseArea { id: btHdrH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Bluetooth y dispositivos", "", true) }
                                        }
                                        WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Bluetooth (" + (root.extData.btDevices ? root.extData.btDevices.length : 0) + " vinculados)"; color: "#ececec"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: ((root.extData.usbDevices || []).length) + " dispositivos USB conectados"; color: "#9a9a9a"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                        Win11Switch {
                                            checked: Boolean(root.hwState.btEnabled)
                                            onToggled: (v) => {
                                                var cp = Object.assign({}, root.hwState); cp.btEnabled = v; root.hwState = cp;
                                                bridge.setBluetoothEnabled(v);
                                                root.refreshLiveState(false);
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Modo de energía"; color: "#b0b0b0"; font.pixelSize: 12; Layout.fillWidth: true }
                                        Text {
                                            text: "Energía ›"; color: pwrMoreH.containsMouse ? "#7cd4ff" : root.accentColor; font.pixelSize: 12; font.weight: Font.Medium
                                            MouseArea { id: pwrMoreH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Sistema", "Energía y batería", true) }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "power-saver", label: "Ahorro" },
                                                { id: "balanced",    label: "Equilibrado" },
                                                { id: "performance", label: "Gaming X64" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: root.hwState.powerProfile === modelData.id
                                                Layout.fillWidth: true; height: 36; radius: 6
                                                color: isCur ? root.accentColor : (hpH.containsMouse ? "#383838" : "#202020")
                                                border.color: isCur ? root.accentColor : "#24ffffff"
                                                Text { anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#ececec"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: hpH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.applyPowerProfileUi(modelData.id, modelData.label)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Card 5: Red e Internet (Clean 2x2 network metrics — zero empty pancake space!)
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                implicitHeight: netHomeCol.implicitHeight + 36
                                radius: 8; color: netHomeH.containsMouse ? "#2b2b2b" : "#262626"; border.color: "#1effffff"; border.width: 1
                                MouseArea { id: netHomeH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Red e Internet", "", true) }
                                ColumnLayout {
                                    id: netHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 20; height: 20; iconFile: root.netChipIcon }
                                        Text { text: "Red e Internet"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                    }
                                    Text { text: root.netChipLabel; color: root.accentColor; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                    GridLayout {
                                        Layout.fillWidth: true; columns: 2; rowSpacing: 8; columnSpacing: 12
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "IPv4"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text { text: root.hwState.localIp || "Sin IP"; color: "#e6e6e6"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Interfaz"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text { text: root.extData.netIface || "—"; color: "#e6e6e6"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Puerta de enlace"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text { text: root.extData.netGateway || "—"; color: "#e6e6e6"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "DNS"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text { text: root.extData.netDns || "—"; color: "#e6e6e6"; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                                        }
                                    }
                                }
                            }

                            // Card 6: Estado Gaming X64 (Rich pills + GPU/Scheduler metrics!)
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                implicitHeight: gamHomeCol.implicitHeight + 36
                                radius: 8; color: gamHomeH.containsMouse ? "#2b2b2b" : "#262626"; border.color: "#1effffff"; border.width: 1
                                MouseArea { id: gamHomeH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.navigateTo("Juegos", "", true) }
                                ColumnLayout {
                                    id: gamHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 20; height: 20; iconFile: "fluent-games.svg" }
                                        Text { text: "Rendimiento Gaming X64"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { text: "Planificador: " + (root.sysInfo.sched || "BORE"); color: "#ececec"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: ((root.sysInfo.gpus || []).length || 1) + " GPU" + (((root.sysInfo.gpus || []).length || 1) === 1 ? "" : "s") + " • " + (root.hwState.cpuGovernor || "Equilibrado"); color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { lbl: "FalconD", on: Boolean(root.extData.gamingStack && root.extData.gamingStack.falcond) },
                                                { lbl: "dmemcg",  on: Boolean(root.extData.gamingStack && root.extData.gamingStack.dmemcg) },
                                                { lbl: "Ananicy", on: Boolean(root.extData.gamingStack && root.extData.gamingStack.ananicy) },
                                                { lbl: "NTSYNC",  on: Boolean(root.extData.gamingStack && root.extData.gamingStack.ntsync) }
                                            ]
                                            delegate: Rectangle {
                                                width: gpT.implicitWidth + 20; height: 28; radius: 5
                                                color: modelData.on ? "#244ade80" : "#20ffffff"
                                                border.color: modelData.on ? "#664ade80" : "#22ffffff"
                                                Text { id: gpT; anchors.centerIn: parent; text: modelData.lbl; color: modelData.on ? "#4ade80" : "#888888"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 1: SISTEMA — OPCIÓN A (Hub + 6 Subpáginas Dedicadas Windows 11 26H2!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Sistema"

                        // [1.0] SISTEMA HUB (6 Subpages Directory)
                        Column {
                            width: parent.width; spacing: 8
                            visible: root.settingsSubPage === ""

                            HubNavCard {
                                iconFile: "fluent-display.svg"
                                title: "Pantalla"
                                subtitle: "Monitores, escala, resolución/Hz, rotación, VRR, brillo y luz nocturna"
                                badge: ((root.extData.monitors || []).length) + " monitor" + ((root.extData.monitors || []).length === 1 ? "" : "es")
                                onClicked: root.navigateTo("Sistema", "Pantalla", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-speaker-high.svg"
                                title: "Sonido"
                                subtitle: "Volumen maestro, salidas PipeWire, prueba de audio, micrófono y entradas"
                                badge: root.hwState.muted ? "Silenciado" : (root.localVolPct + "%")
                                onClicked: root.navigateTo("Sistema", "Sonido", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-bell-snooze.svg"
                                title: "Notificaciones"
                                subtitle: "Banners, sonido de avisos, No molestar, Concentración y control por app"
                                badge: root.cfg.notifEnabled === false ? "Desactivadas" : (Boolean(root.cfg.doNotDisturb) ? "No molestar" : "Activas")
                                onClicked: root.navigateTo("Sistema", "Notificaciones", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-plug.svg"
                                title: "Energía y batería"
                                subtitle: "Perfiles de rendimiento, ahorro energético y estado de alimentación"
                                badge: root.hwState.cpuGovernor || "Equilibrado"
                                onClicked: root.navigateTo("Sistema", "Energía y batería", true)
                            }
                            HubNavCard {
                                iconFile: "drive-c.svg"
                                title: "Almacenamiento"
                                subtitle: "Discos físicos, montaje/desmontaje, papelera de reciclaje y caché de paquetes"
                                badge: root.physicalDrives.length + " disco" + (root.physicalDrives.length === 1 ? "" : "s")
                                onClicked: root.navigateTo("Sistema", "Almacenamiento", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-info.svg"
                                title: "Acerca de"
                                subtitle: "Nombre del equipo, CPU, RAM, Multi-GPU, kernel y especificaciones completas"
                                badge: root.sysInfo.hostname || "PC"
                                onClicked: root.navigateTo("Sistema", "Acerca de", true)
                            }
                        }

                        // [1.1] SUBPAGE: SISTEMA › PANTALLA (Audited Windows 11 26H2 Display Center!)
                        Column {
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Pantalla"

                            // [1.1.A] Interactive Multi-Monitor Arrangement Stage + Toolbar
                            Rectangle {
                                visible: (root.extData.monitors || []).length > 0
                                width: parent.width; implicitHeight: monStageOuter.implicitHeight
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1

                                Column {
                                    id: monStageOuter; width: parent.width

                                    // Blueprint Monitor Stage (Ordered left-to-right by real physical posX!)
                                    Rectangle {
                                        width: parent.width; height: 184
                                        radius: 8; color: "#1e1e1e"
                                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 8; color: "#1e1e1e" }

                                        Text {
                                            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 14
                                            text: (root.extData.monitors || []).length > 1
                                                  ? "Haz clic en una pantalla para seleccionarla y configurar sus ajustes debajo"
                                                  : "Pantalla principal detectada"
                                            color: "#8e8e8e"; font.pixelSize: 11
                                        }

                                        Row {
                                            anchors.centerIn: parent; anchors.verticalCenterOffset: 8; spacing: 14
                                            Repeater {
                                                model: root.extData.monitors || []
                                                delegate: Rectangle {
                                                    readonly property bool isSel: root.selectedMonitor && root.selectedMonitor.name === modelData.name
                                                    readonly property bool isVert: modelData.transform === "90" || modelData.transform === "270"
                                                    readonly property bool isOn: Boolean(modelData.enabled)
                                                    width: isVert ? 86 : 172
                                                    height: isVert ? 132 : 102
                                                    radius: 8
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    color: isSel ? "#1b3f5e" : (monBoxH.containsMouse ? "#323232" : "#292929")
                                                    border.color: isSel ? root.accentColor : (isOn ? "#3cffffff" : "#26ffffff")
                                                    border.width: isSel ? 2 : 1
                                                    opacity: isOn ? 1.0 : 0.55
                                                    Behavior on color { ColorAnimation { duration: 110 } }

                                                    // Subtle top accent bar on selected display
                                                    Rectangle {
                                                        visible: isSel; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                                        anchors.topMargin: 5; width: 32; height: 3; radius: 2; color: root.accentColor
                                                    }

                                                    Column {
                                                        anchors.centerIn: parent; spacing: 3
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: String(index + 1)
                                                            color: "#ffffff"; font.pixelSize: 28; font.weight: Font.Bold
                                                        }
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: modelData.name
                                                            color: isSel ? "#bceaff" : "#d8d8d8"; font.pixelSize: 11; font.weight: Font.DemiBold
                                                        }
                                                        Text {
                                                            anchors.horizontalCenter: parent.horizontalCenter
                                                            text: isOn ? (modelData.currentMode || "Activa") : "Desactivada"
                                                            color: isSel ? "#86d6ff" : "#969696"; font.pixelSize: 10
                                                        }
                                                    }
                                                    MouseArea {
                                                        id: monBoxH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            root.selectedMonitorName = modelData.name;
                                                            root.resDropdownOpen = false;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Thin Divider + Arrangement Action Toolbar
                                    Rectangle { width: parent.width; height: 1; color: "#1cffffff" }

                                    RowLayout {
                                        width: parent.width - 32; x: 16
                                        height: 58; spacing: 10

                                        FluentBtn {
                                            label: "Identificar"
                                            onClicked: {
                                                if (bridge.identifyDisplays()) {
                                                    root.showToast("Mostrando número en cada pantalla...");
                                                }
                                            }
                                        }

                                        FluentBtn {
                                            visible: root.enabledMonitorsCount >= 2
                                            label: "Intercambiar izq. ↔ der."
                                            onClicked: {
                                                var r = bridge.swapMonitorOrder();
                                                root.refreshLiveState(false);
                                                root.showToast(r === "ok" ? "Orden de pantallas intercambiado" : r.replace(/^error:/, ""));
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Multi-Monitor Projection Mode Selector (when 2+ monitors exist!)
                                        Row {
                                            visible: (root.extData.monitors || []).length >= 2
                                            spacing: 6
                                            Repeater {
                                                model: {
                                                    var mons = root.extData.monitors || [];
                                                    if (mons.length < 2) return [];
                                                    var arr = [{ id: "extend", label: "Extender", active: root.enabledMonitorsCount >= 2 }];
                                                    for (var i = 0; i < Math.min(2, mons.length); i++) {
                                                        arr.push({
                                                            id: "only:" + mons[i].name,
                                                            label: "Solo " + (i + 1),
                                                            active: root.enabledMonitorsCount === 1 && Boolean(mons[i].enabled)
                                                        });
                                                    }
                                                    return arr;
                                                }
                                                delegate: Rectangle {
                                                    width: pmTxt.implicitWidth + 24; height: 34; radius: 6
                                                    color: modelData.active ? root.accentColor : (pmH.containsMouse ? "#383838" : "#2d2d2d")
                                                    border.color: modelData.active ? root.accentColor : "#24ffffff"
                                                    Text {
                                                        id: pmTxt; anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: modelData.active ? "#000000" : "#ececec"
                                                        font.pixelSize: 12; font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                    }
                                                    MouseArea {
                                                        id: pmH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            var r = bridge.setMultiMonitorMode(modelData.id);
                                                            root.refreshLiveState(false);
                                                            root.showToast(r === "ok" ? ("Modo: " + modelData.label) : r.replace(/^error:/, ""));
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.1.B] Section: Brillo y color
                            Text { text: "Brillo y color"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 4 }

                            // Universal Brightness Card (works on laptops AND desktop monitors via shell overlay!)
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(68, brCol.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: brCol; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 8; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-brightness.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Brillo"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text {
                                                text: root.extData.hasBacklight
                                                      ? "Ajusta la retroiluminación de hardware y el nivel visual de las pantallas"
                                                      : "Ajusta la atenuación visual de la pantalla en tiempo real"
                                                color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: root.narrowBody; spacing: 12
                                        SettingsSlider {
                                            Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 210
                                            from: 10; to: 100; value: root.localBrightPct
                                            onDraggingChanged: root.brightDragging = dragging
                                            onMovedValue: (v) => root.pushBrightLive(v)
                                            onReleasedValue: (v) => {
                                                brightWriteTimer.stop();
                                                root.localBrightPct = Math.round(v);
                                                bridge.runCtlAction("brightness set " + root.localBrightPct);
                                            }
                                        }
                                        Text { text: root.localBrightPct + "%"; color: root.accentColor; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }

                            // Expandable Night Light Card (Switch + Live Warmth Strength Slider!)
                            Rectangle {
                                width: parent.width; implicitHeight: nlCol.implicitHeight + 30
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: nlCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 15; spacing: 14

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-night-light.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Luz nocturna"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Usa tonos cálidos para reducir la luz azul y descansar la vista de noche"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Win11Switch {
                                            checked: Boolean(root.cfg.nightLight)
                                            onToggled: (v) => root.updateCfg("nightLight", v)
                                        }
                                    }

                                    Rectangle { visible: Boolean(root.cfg.nightLight); Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                                    RowLayout {
                                        visible: Boolean(root.cfg.nightLight)
                                        Layout.fillWidth: true; spacing: 14
                                        Text { text: "Intensidad cálida"; color: "#d8d8d8"; font.pixelSize: 13; Layout.fillWidth: true }
                                        SettingsSlider {
                                            Layout.preferredWidth: 210
                                            from: 20; to: 100; value: root.localNightStrength
                                            onDraggingChanged: root.nightStrDragging = dragging
                                            onMovedValue: (v) => { root.localNightStrength = Math.round(v); }
                                            onReleasedValue: (v) => {
                                                var iv = Math.round(v);
                                                root.localNightStrength = iv;
                                                root.updateCfg("nightLightStrength", iv);
                                                root.showToast("Intensidad luz nocturna: " + iv + "%");
                                            }
                                        }
                                        Text { text: root.localNightStrength + "%"; color: "#ffb15e"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }

                            // [1.1.C] Section: Escala y distribución (Selected Monitor Only — Zero Duplicated Walls!)
                            RowLayout {
                                visible: root.selectedMonitor !== null
                                width: parent.width; spacing: 10
                                Text {
                                    text: "Escala y distribución"
                                    color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: root.selectedMonitor ? ("Editando: Pantalla " + (root.selectedMonitorIndex + 1) + " (" + root.selectedMonitor.name + ")") : ""
                                    color: root.accentColor; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 6
                                }
                            }

                            // Selected Monitor Identity & Power Card
                            Rectangle {
                                visible: root.selectedMonitor !== null
                                width: parent.width; implicitHeight: Math.max(70, selMonHdr.implicitHeight + 28)
                                radius: 7; color: "#222a33"; border.color: Qt.alpha(root.accentColor, 0.22); border.width: 1
                                RowLayout {
                                    id: selMonHdr; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    Rectangle {
                                        width: 38; height: 38; radius: 8; color: Qt.alpha(root.accentColor, 0.15); border.color: Qt.alpha(root.accentColor, 0.33)
                                        Text { anchors.centerIn: parent; text: String(root.selectedMonitorIndex + 1); color: "#ffffff"; font.pixelSize: 18; font.weight: Font.Bold }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text {
                                            text: root.selectedMonitor
                                                  ? ("Pantalla " + (root.selectedMonitorIndex + 1) + " — " + root.selectedMonitor.name
                                                     + (root.selectedMonitor.diagInches ? ("  •  " + root.selectedMonitor.diagInches) : ""))
                                                  : ""
                                            color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text: root.selectedMonitor
                                                  ? ((root.selectedMonitor.desc || root.selectedMonitor.name)
                                                     + "  •  " + (root.selectedMonitor.enabled ? (root.selectedMonitor.currentMode || "Activa") : "Desactivada"))
                                                  : ""
                                            color: "#a8c7dc"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                    FluentBtn {
                                        visible: (root.extData.monitors || []).length > 1 && root.selectedMonitor !== null
                                        label: (root.selectedMonitor && root.selectedMonitor.enabled) ? "Desactivar pantalla" : "Activar pantalla"
                                        accent: Boolean(root.selectedMonitor && !root.selectedMonitor.enabled)
                                        onClicked: {
                                            var m = root.selectedMonitor;
                                            if (!m) return;
                                            var r = bridge.applyMonitorAdvanced(m.name, "", "", m.enabled ? "off" : "on");
                                            root.refreshLiveState(false);
                                            root.showToast(r === "ok" ? (m.name + (m.enabled ? " desactivada" : " activada")) : r.replace(/^error:/, ""));
                                        }
                                    }
                                }
                            }

                            // 1. Escala Card (with automatic contiguous --pos repack!)
                            Rectangle {
                                visible: root.selectedMonitor !== null && Boolean(root.selectedMonitor.enabled)
                                width: parent.width; implicitHeight: Math.max(68, scRowLay.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: scRowLay; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-maximize.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Escala"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Cambia el tamaño del texto, las aplicaciones y otros elementos"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                        spacing: 6
                                        Repeater {
                                            model: ["1", "1.25", "1.5", "1.75", "2"]
                                            delegate: Rectangle {
                                                readonly property bool isCurSc: root.selectedMonitor && Math.abs(Number(modelData) - Number(root.selectedMonitor.scale || 1)) < 0.05
                                                width: 56; height: 34; radius: 6
                                                color: isCurSc ? root.accentColor : (scHov.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurSc ? root.accentColor : "#20ffffff"
                                                Text { anchors.centerIn: parent; text: Math.round(Number(modelData) * 100) + "%"; color: parent.isCurSc ? "#000000" : "#ececec"; font.pixelSize: 12; font.weight: parent.isCurSc ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: scHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var m = root.selectedMonitor;
                                                        if (!m || parent.isCurSc) return;
                                                        if (bridge.applyMonitorSetting(m.name, modelData, "")) {
                                                            root.refreshLiveState(false);
                                                            root.showToast("Escala " + Math.round(Number(modelData) * 100) + "% aplicada en " + m.name);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 2. Resolución de pantalla Card (Clean Deduplicated WinUI 3 Dropdown + 15s Auto-Revert!)
                            Rectangle {
                                id: resDropCard
                                visible: root.selectedMonitor !== null && Boolean(root.selectedMonitor.enabled)
                                width: parent.width; implicitHeight: resCardCol.implicitHeight + 30
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: resCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 15; spacing: 12

                                    GridLayout {
                                        id: resGrid
                                        Layout.fillWidth: true; columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                        readonly property bool multiRes: root.selectedMonitor !== null && (root.selectedMonitor.resolutions || []).length > 1
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 16
                                            WinSvg { width: 21; height: 21; iconFile: "fluent-display.svg" }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 3
                                                Text { text: "Resolución de pantalla"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                                Text {
                                                    text: resGrid.multiRes
                                                          ? "Ajusta la nitidez y el área de trabajo de la pantalla seleccionada"
                                                          : "Este panel solo expone su resolución nativa en hardware (EDID). Usa Escala arriba (ej. 150% = área 1280×720)"
                                                    color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                                }
                                            }
                                        }
                                        Rectangle {
                                            Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                            Layout.preferredWidth: Math.max(245, resCurTxt.implicitWidth + 46)
                                            height: 36; radius: 6
                                            color: resGrid.multiRes ? (resBtnH.containsMouse ? "#383838" : "#2f2f2f") : "#222222"
                                            border.color: root.resDropdownOpen ? root.accentColor : (resGrid.multiRes ? "#28ffffff" : "#18ffffff")
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                                                Text {
                                                    id: resCurTxt
                                                    text: resGrid.multiRes
                                                          ? (root.selectedMonResObj ? root.selectedMonResObj.label : (root.selectedMonitor ? root.selectedMonitor.currentRes : "—"))
                                                          : ((root.selectedMonResObj ? root.selectedMonResObj.shortLabel : "1920 × 1080") + " (Nativa única)")
                                                    color: resGrid.multiRes ? "#f5f5f5" : "#b8b8b8"
                                                    font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight
                                                }
                                                WinSvg {
                                                    visible: resGrid.multiRes
                                                    width: 13; height: 13
                                                    iconFile: root.resDropdownOpen ? "fluent-chevron-up.svg" : "fluent-chevron-down.svg"
                                                }
                                            }
                                            MouseArea {
                                                id: resBtnH; anchors.fill: parent; hoverEnabled: true
                                                enabled: resGrid.multiRes
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: {
                                                    root.resDropdownOpen = !root.resDropdownOpen;
                                                    if (root.resDropdownOpen) root.ensureItemVisible(resDropCard);
                                                }
                                            }
                                        }
                                    }

                                    // Clean Expandable Resolution Picker List (Never cluttered with 24Hz/25Hz modes!)
                                    Column {
                                        visible: root.resDropdownOpen && root.selectedMonitor !== null
                                        Layout.fillWidth: true; spacing: 4
                                        Rectangle { width: parent.width; height: 1; color: "#1cffffff" }
                                        Item { width: 1; height: 4 }
                                        Repeater {
                                            model: root.selectedMonitor ? (root.selectedMonitor.resolutions || []) : []
                                            delegate: Rectangle {
                                                readonly property bool isCurR: Boolean(modelData.current)
                                                width: parent.width; height: 38; radius: 6
                                                color: isCurR ? Qt.alpha(root.accentColor, 0.15) : (rOptH.containsMouse ? "#323232" : "#202020")
                                                border.color: isCurR ? Qt.alpha(root.accentColor, 0.33) : "#14ffffff"
                                                RowLayout {
                                                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                                                    Text { text: modelData.label; color: isCurR ? root.accentColor : "#f0f0f0"; font.pixelSize: 13; font.weight: isCurR ? Font.DemiBold : Font.Normal; Layout.fillWidth: true }
                                                    Text { text: (modelData.rates && modelData.rates.length > 0) ? ("hasta " + modelData.rates[0].label) : ""; color: "#8e8e8e"; font.pixelSize: 11 }
                                                }
                                                MouseArea {
                                                    id: rOptH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var m = root.selectedMonitor;
                                                        root.resDropdownOpen = false;
                                                        if (!m || parent.isCurR) return;
                                                        var prevArg = m.currentArg || "";
                                                        if (bridge.applyMonitorSetting(m.name, "", modelData.bestArg)) {
                                                            root.refreshLiveState(false);
                                                            root.beginDisplayConfirm(m.name, prevArg, "", "Resolución " + modelData.shortLabel);
                                                        } else {
                                                            root.showToast("No se pudo aplicar " + modelData.shortLabel);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 3. Frecuencia de actualización (Hz) Card (Cleanly separated from Resolution!)
                            Rectangle {
                                visible: root.selectedMonitor !== null && Boolean(root.selectedMonitor.enabled)
                                width: parent.width; implicitHeight: Math.max(68, hzRowLay.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: hzRowLay; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-refresh.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Frecuencia de actualización"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Frecuencias disponibles para la resolución actual (" + (root.selectedMonitor ? root.selectedMonitor.currentHzExact : "60 Hz") + ")"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                        spacing: 6
                                        Repeater {
                                            model: root.selectedMonResObj ? (root.selectedMonResObj.rates || []) : []
                                            delegate: Rectangle {
                                                readonly property bool isCurHz: Boolean(modelData.current)
                                                width: hzTxt.implicitWidth + 24; height: 34; radius: 6
                                                color: isCurHz ? root.accentColor : (hzH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurHz ? root.accentColor : "#20ffffff"
                                                Text { id: hzTxt; anchors.centerIn: parent; text: modelData.label; color: parent.isCurHz ? "#000000" : "#ececec"; font.pixelSize: 12; font.weight: parent.isCurHz ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: hzH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var m = root.selectedMonitor;
                                                        if (!m || parent.isCurHz) return;
                                                        var prevArg = m.currentArg || "";
                                                        if (bridge.applyMonitorSetting(m.name, "", modelData.arg)) {
                                                            root.refreshLiveState(false);
                                                            root.beginDisplayConfirm(m.name, prevArg, "", "Frecuencia " + modelData.label);
                                                        } else {
                                                            root.showToast("No se pudo cambiar a " + modelData.label);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 4. Orientación de pantalla Card (with contiguous --pos repack + 15s Auto-Revert!)
                            Rectangle {
                                visible: root.selectedMonitor !== null && Boolean(root.selectedMonitor.enabled)
                                width: parent.width; implicitHeight: Math.max(68, orRowLay.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: orRowLay; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-arrow-sort.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Orientación de pantalla"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Cambia entre vista horizontal o vertical (recalcula la posición automáticamente)"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                        Layout.fillWidth: root.narrowBody
                                        Layout.preferredWidth: root.narrowBody ? -1 : 392
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "normal", label: "Horizontal" },
                                                { id: "90",     label: "Vertical (90°)" },
                                                { id: "180",    label: "Volteado" },
                                                { id: "270",    label: "Vertical (270°)" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCurT: root.selectedMonitor && (root.selectedMonitor.transform || "normal") === modelData.id
                                                width: trTxt.implicitWidth + 18; height: 34; radius: 6
                                                color: isCurT ? root.accentColor : (trHov.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurT ? root.accentColor : "#20ffffff"
                                                Text { id: trTxt; anchors.centerIn: parent; text: modelData.label; color: parent.isCurT ? "#000000" : "#ececec"; font.pixelSize: 12; font.weight: parent.isCurT ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: trHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var m = root.selectedMonitor;
                                                        if (!m || parent.isCurT) return;
                                                        var prevTr = m.transform || "normal";
                                                        var r = bridge.applyMonitorAdvanced(m.name, modelData.id, "", "");
                                                        if (r === "ok") {
                                                            root.refreshLiveState(false);
                                                            root.beginDisplayConfirm(m.name, "", prevTr, "Orientación " + modelData.label);
                                                        } else {
                                                            root.showToast(r.replace(/^error:/, ""));
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.1.D] Section: Pantalla avanzada (VRR + Real Hardware Telemetry!)
                            Text {
                                visible: root.selectedMonitor !== null
                                text: "Pantalla avanzada"
                                color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6
                            }

                            // Honest Hardware-Probed VRR / FreeSync Card (only interactive if monitor supports VRR!)
                            Rectangle {
                                id: vrrCard
                                visible: root.selectedMonitor !== null && Boolean(root.selectedMonitor.enabled)
                                readonly property bool vrrCap: Boolean(root.selectedMonitor && root.selectedMonitor.vrrSupported)
                                width: parent.width; implicitHeight: Math.max(66, vrrRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                opacity: vrrCap ? 1.0 : 0.78
                                RowLayout {
                                    id: vrrRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                    WinSvg { width: 21; height: 21; iconFile: "fluent-grid.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Sincronización adaptativa (VRR / FreeSync)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text {
                                            text: vrrCard.vrrCap
                                                  ? "Reduce el desgarro de imagen (tearing) en juegos en esta pantalla"
                                                  : ("No compatible en hardware con " + (root.selectedMonitor ? root.selectedMonitor.name : "esta pantalla") + " (requiere monitor/cable FreeSync o G-Sync)")
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    Rectangle {
                                        visible: !vrrCard.vrrCap
                                        width: vrrNcTxt.implicitWidth + 20; height: 28; radius: 6
                                        color: "#22ffffff"; border.color: "#28ffffff"
                                        Text { id: vrrNcTxt; anchors.centerIn: parent; text: "No compatible"; color: "#b8b8b8"; font.pixelSize: 11; font.weight: Font.Medium }
                                    }
                                    Win11Switch {
                                        visible: vrrCard.vrrCap
                                        checked: Boolean(root.selectedMonitor && root.selectedMonitor.adaptiveSync)
                                        onToggled: (v) => {
                                            var m = root.selectedMonitor;
                                            if (!m) return;
                                            var r = bridge.applyMonitorAdvanced(m.name, "", v ? "enabled" : "disabled", "");
                                            root.refreshLiveState(false);
                                            root.showToast(r === "ok" ? (v ? "VRR activado en " + m.name : "VRR desactivado") : r.replace(/^error:/, ""));
                                        }
                                    }
                                }
                            }

                            // Selected Monitor Hardware Specs Summary Card
                            Rectangle {
                                visible: root.selectedMonitor !== null
                                width: parent.width; implicitHeight: monSpecGrid.implicitHeight + 36
                                radius: 7; color: "#252525"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: monSpecGrid
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 18
                                    columns: root.narrowBody ? 2 : 4; rowSpacing: 12; columnSpacing: 16
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Conector y fabricante"; color: "#8e8e8e"; font.pixelSize: 11 }
                                        Text { text: root.selectedMonitor ? (root.selectedMonitor.name + (root.selectedMonitor.make ? (" • " + root.selectedMonitor.make) : "")) : "—"; color: "#f0f0f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Tamaño físico"; color: "#8e8e8e"; font.pixelSize: 11 }
                                        Text { text: (root.selectedMonitor && root.selectedMonitor.diagInches) ? (root.selectedMonitor.diagInches + " (panel)") : "No reportado"; color: "#f0f0f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Señal activa"; color: "#8e8e8e"; font.pixelSize: 11 }
                                        Text { text: root.selectedMonitor ? (root.selectedMonitor.currentRes + " @ " + root.selectedMonitor.currentHzExact) : "—"; color: "#f0f0f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Espacio lógico"; color: "#8e8e8e"; font.pixelSize: 11 }
                                        Text { text: root.selectedMonitor ? (root.selectedMonitor.logicalW + "×" + root.selectedMonitor.logicalH + " en (" + root.selectedMonitor.position + ")") : "—"; color: "#f0f0f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                }
                            }
                        }

                        // [1.2] SUBPAGE: SISTEMA › SONIDO (Full PipeWire JSON — Ports, Per-App Mixer, Mic Test & BT/USB Profiles!)
                        Column {
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Sonido"

                            // [1.2.A] SALIDA DE AUDIO
                            Text { text: "Salida"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold }

                            // Master Volume + Over-Amplify Card
                            Rectangle {
                                width: parent.width; implicitHeight: sndOutCol.implicitHeight + 30
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: sndOutCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 15; spacing: 14

                                    GridLayout {
                                        Layout.fillWidth: true; columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 14
                                            Rectangle {
                                                width: 38; height: 38; radius: 7
                                                color: root.hwState.muted ? "#38ef4444" : (muteH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: root.hwState.muted ? "#88ef4444" : "#22ffffff"
                                                WinSvg { anchors.centerIn: parent; width: 19; height: 19; iconFile: root.hwState.muted ? "fluent-speaker-mute.svg" : "fluent-speaker-high.svg" }
                                                MouseArea { id: muteH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bridge.toggleAudioMute(); root.refreshLiveState(false); } }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 3
                                                Text { text: "Volumen maestro"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                                Text {
                                                    text: root.hwState.muted
                                                          ? "Silenciado (haz clic en el altavoz para reactivar)"
                                                          : (root.activeSinkObj
                                                             ? (root.activeSinkObj.name + (root.activeSinkObj.activePortLabel ? ("  •  " + root.activeSinkObj.activePortLabel) : ""))
                                                             : root.activeSinkName)
                                                    color: root.hwState.muted ? "#f87171" : "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                                                }
                                            }
                                        }
                                        RowLayout {
                                            Layout.fillWidth: root.narrowBody; Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight; spacing: 10
                                            SettingsSlider {
                                                Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 200
                                                from: 0; to: Boolean(root.cfg.audioOverAmplify) ? 150 : 100
                                                value: Math.min(to, root.localVolPct)
                                                onDraggingChanged: root.volDragging = dragging
                                                onMovedValue: (v) => root.pushVolLive(v)
                                                onReleasedValue: (v) => {
                                                    volWriteTimer.stop();
                                                    root.localVolPct = Math.round(v);
                                                    root._lastVolMs = Date.now();
                                                    bridge.setPipewireVolume(root.localVolPct);
                                                }
                                            }
                                            Text {
                                                text: root.localVolPct + "%"
                                                color: root.localVolPct > 100 ? "#fbbf24" : root.accentColor
                                                font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight
                                            }
                                            FluentBtn {
                                                label: "Probar"
                                                onClicked: {
                                                    if (bridge.playTestSound()) root.showToast("Reproduciendo sonido de prueba...");
                                                    else root.showToast("No se pudo reproducir el tono de prueba");
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Permitir amplificación de volumen (hasta 150%)"; color: "#e6e6e6"; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                            Text { text: "Útil si unos altavoces o auriculares suenan demasiado bajo"; color: "#8e8e8e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Win11Switch {
                                            checked: Boolean(root.cfg.audioOverAmplify)
                                            onToggled: (v) => {
                                                root.updateCfg("audioOverAmplify", v);
                                                if (!v && root.localVolPct > 100) {
                                                    root.localVolPct = 100;
                                                    bridge.setPipewireVolume(100);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Output Devices List (with Bus Type Badge + Live Port Selector: Altavoces vs Auriculares!)
                            Text {
                                visible: (root.extData.sinks || []).length > 0
                                text: "Elegir dónde reproducir el sonido"
                                color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.Medium; topPadding: 2
                            }
                            Repeater {
                                model: root.extData.sinks || []
                                delegate: Rectangle {
                                    id: sinkCard
                                    readonly property var sObj: modelData
                                    width: parent.width; implicitHeight: sinkCardCol.implicitHeight + 26
                                    radius: 7
                                    color: sObj.active ? "#223242" : (sinkH.containsMouse ? "#2d2d2d" : "#262626")
                                    border.color: sObj.active ? root.accentColor : "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: sinkCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 13; spacing: 10
                                        Item {
                                            Layout.fillWidth: true; implicitHeight: sinkHdrRow.implicitHeight
                                            RowLayout {
                                                id: sinkHdrRow; anchors.fill: parent; spacing: 12
                                                Rectangle { width: 12; height: 12; radius: 6; color: sinkCard.sObj.active ? root.accentColor : "transparent"; border.color: sinkCard.sObj.active ? root.accentColor : "#777777"; border.width: 2 }
                                                WinSvg { width: 19; height: 19; iconFile: root.audioBusIcon(sinkCard.sObj.busType) }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 2
                                                    Text { text: sinkCard.sObj.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: sinkCard.sObj.active ? Font.DemiBold : Font.Normal; Layout.fillWidth: true; elide: Text.ElideRight }
                                                    Text {
                                                        text: (sinkCard.sObj.activePortLabel ? ("Puerto: " + sinkCard.sObj.activePortLabel + "  •  ") : "")
                                                              + (sinkCard.sObj.muted ? "Silenciado" : ("Volumen " + (sinkCard.sObj.volume !== undefined ? sinkCard.sObj.volume : 100) + "%"))
                                                        color: sinkCard.sObj.active ? "#9ed8f5" : "#969696"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                }
                                                Rectangle {
                                                    width: sBusT.implicitWidth + 16; height: 22; radius: 4; color: "#1cffffff"; border.color: "#22ffffff"
                                                    Text { id: sBusT; anchors.centerIn: parent; text: sinkCard.sObj.busType || "Audio"; color: "#d4d4d4"; font.pixelSize: 11 }
                                                }
                                                Text { visible: Boolean(sinkCard.sObj.active); text: "Predeterminado"; color: root.accentColor; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            }
                                            MouseArea {
                                                id: sinkH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (bridge.setDefaultAudioSink(sinkCard.sObj.nodeName || sinkCard.sObj.id)) {
                                                        root.refreshLiveState(false);
                                                        root.showToast("Salida: " + sinkCard.sObj.name);
                                                    }
                                                }
                                            }
                                        }

                                        // Inline Port Selector (Altavoces vs Auriculares 3.5 mm!)
                                        Flow {
                                            visible: (sinkCard.sObj.ports || []).length > 1
                                            Layout.fillWidth: true; spacing: 6; Layout.leftMargin: 24
                                            Text { text: "Puerto:"; color: "#9e9e9e"; font.pixelSize: 11; height: 28; verticalAlignment: Text.AlignVCenter }
                                            Repeater {
                                                model: sinkCard.sObj.ports || []
                                                delegate: Rectangle {
                                                    width: spTxt.implicitWidth + 20; height: 28; radius: 5
                                                    color: modelData.active ? root.accentColor : (spH.containsMouse ? "#383838" : "#202020")
                                                    border.color: modelData.active ? root.accentColor : "#22ffffff"
                                                    opacity: modelData.available || modelData.active ? 1.0 : 0.65
                                                    Text {
                                                        id: spTxt; anchors.centerIn: parent
                                                        text: modelData.label + (!modelData.available && !modelData.active ? " (sin conectar)" : "")
                                                        color: modelData.active ? "#000000" : "#e6e6e6"
                                                        font.pixelSize: 11; font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                    }
                                                    MouseArea {
                                                        id: spH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (bridge.setSinkPort(sinkCard.sObj.nodeName, modelData.name)) {
                                                                bridge.setDefaultAudioSink(sinkCard.sObj.nodeName);
                                                                root.refreshLiveState(false);
                                                                root.showToast("Puerto cambiado a " + modelData.label);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.2.B] ENTRADA Y MICRÓFONO
                            Text { text: "Entrada y micrófono"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 8 }

                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(70, sndInRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: sndInRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        Rectangle {
                                            width: 38; height: 38; radius: 7
                                            color: root.extData.micMuted ? "#38ef4444" : (micMuteH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                            border.color: root.extData.micMuted ? "#88ef4444" : "#22ffffff"
                                            WinSvg { anchors.centerIn: parent; width: 19; height: 19; iconFile: root.extData.micMuted ? "audio-input-microphone-muted-symbolic.svg" : "audio-input-microphone-symbolic.svg" }
                                            MouseArea { id: micMuteH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bridge.toggleMicMute(); root.refreshLiveState(false); } }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Volumen de micrófono"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text {
                                                text: root.extData.micMuted
                                                      ? "Micrófono silenciado (clic en el icono para activar)"
                                                      : (root.activeSourceObj
                                                         ? (root.activeSourceObj.name + (root.activeSourceObj.activePortLabel ? ("  •  " + root.activeSourceObj.activePortLabel) : ""))
                                                         : "Sensibilidad de entrada predeterminada")
                                                color: root.extData.micMuted ? "#f87171" : "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: root.narrowBody; Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight; spacing: 10
                                        SettingsSlider {
                                            Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 185
                                            from: 0; to: 100; value: root.localMicPct
                                            onDraggingChanged: root.micDragging = dragging
                                            onMovedValue: (v) => root.pushMicLive(v)
                                            onReleasedValue: (v) => {
                                                micWriteTimer.stop();
                                                root.localMicPct = Math.round(v);
                                                root._lastMicMs = Date.now();
                                                bridge.setMicVolume(root.localMicPct);
                                            }
                                        }
                                        Text { text: root.localMicPct + "%"; color: root.accentColor; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                                        FluentBtn {
                                            label: root.micTestState === "recording" ? "Grabando 3 s..."
                                                   : (root.micTestState === "playing" ? "Reproduciendo..." : "Probar micro")
                                            accent: root.micTestState !== ""
                                            onClicked: {
                                                if (root.micTestState === "") bridge.startMicTest();
                                            }
                                        }
                                    }
                                }
                            }

                            // Real Audio Input Sources List (with Inline Port Selector: Mic interno vs Jack 3.5 mm!)
                            Text {
                                visible: (root.extData.sources || []).length > 0
                                text: "Elegir dispositivo para hablar o grabar"
                                color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.Medium; topPadding: 2
                            }
                            Repeater {
                                model: root.extData.sources || []
                                delegate: Rectangle {
                                    id: srcCard
                                    readonly property var srcObj: modelData
                                    width: parent.width; implicitHeight: srcCardCol.implicitHeight + 26
                                    radius: 7
                                    color: srcObj.active ? "#223242" : (srcH.containsMouse ? "#2d2d2d" : "#262626")
                                    border.color: srcObj.active ? root.accentColor : "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: srcCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 13; spacing: 10
                                        Item {
                                            Layout.fillWidth: true; implicitHeight: srcHdrRow.implicitHeight
                                            RowLayout {
                                                id: srcHdrRow; anchors.fill: parent; spacing: 12
                                                Rectangle { width: 12; height: 12; radius: 6; color: srcCard.srcObj.active ? root.accentColor : "transparent"; border.color: srcCard.srcObj.active ? root.accentColor : "#777777"; border.width: 2 }
                                                WinSvg { width: 19; height: 19; iconFile: srcCard.srcObj.busType === "Bluetooth" ? "fluent-bluetooth.svg" : "audio-input-microphone-symbolic.svg" }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 2
                                                    Text { text: srcCard.srcObj.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: srcCard.srcObj.active ? Font.DemiBold : Font.Normal; Layout.fillWidth: true; elide: Text.ElideRight }
                                                    Text {
                                                        text: (srcCard.srcObj.activePortLabel ? ("Puerto: " + srcCard.srcObj.activePortLabel + "  •  ") : "")
                                                              + (srcCard.srcObj.muted ? "Silenciado" : ("Nivel " + (srcCard.srcObj.volume !== undefined ? srcCard.srcObj.volume : 50) + "%"))
                                                        color: srcCard.srcObj.active ? "#9ed8f5" : "#969696"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                }
                                                Rectangle {
                                                    width: inBusT.implicitWidth + 16; height: 22; radius: 4; color: "#1cffffff"; border.color: "#22ffffff"
                                                    Text { id: inBusT; anchors.centerIn: parent; text: srcCard.srcObj.busType || "Micro"; color: "#d4d4d4"; font.pixelSize: 11 }
                                                }
                                                Text { visible: Boolean(srcCard.srcObj.active); text: "Predeterminado"; color: root.accentColor; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            }
                                            MouseArea {
                                                id: srcH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (bridge.setDefaultAudioSource(srcCard.srcObj.nodeName || srcCard.srcObj.id)) {
                                                        root.refreshLiveState(false);
                                                        root.showToast("Micrófono: " + srcCard.srcObj.name);
                                                    }
                                                }
                                            }
                                        }

                                        // Inline Mic Port Selector (Micrófono interno vs Micrófono externo 3.5 mm!)
                                        Flow {
                                            visible: (srcCard.srcObj.ports || []).length > 1
                                            Layout.fillWidth: true; spacing: 6; Layout.leftMargin: 24
                                            Text { text: "Puerto:"; color: "#9e9e9e"; font.pixelSize: 11; height: 28; verticalAlignment: Text.AlignVCenter }
                                            Repeater {
                                                model: srcCard.srcObj.ports || []
                                                delegate: Rectangle {
                                                    width: mpTxt.implicitWidth + 20; height: 28; radius: 5
                                                    color: modelData.active ? root.accentColor : (mpH.containsMouse ? "#383838" : "#202020")
                                                    border.color: modelData.active ? root.accentColor : "#22ffffff"
                                                    opacity: modelData.available || modelData.active ? 1.0 : 0.65
                                                    Text {
                                                        id: mpTxt; anchors.centerIn: parent
                                                        text: modelData.label + (!modelData.available && !modelData.active ? " (no detectado)" : "")
                                                        color: modelData.active ? "#000000" : "#e6e6e6"
                                                        font.pixelSize: 11; font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                    }
                                                    MouseArea {
                                                        id: mpH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (bridge.setSourcePort(srcCard.srcObj.nodeName, modelData.name)) {
                                                                bridge.setDefaultAudioSource(srcCard.srcObj.nodeName);
                                                                root.refreshLiveState(false);
                                                                root.showToast("Entrada cambiada a " + modelData.label);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.2.C] MEZCLADOR DE VOLUMEN POR APLICACIÓN (Windows 11 Volume Mixer!)
                            Item { width: 1; height: 6 }
                            RowLayout {
                                width: parent.width; spacing: 8
                                WinSvg { width: 17; height: 17; iconFile: "multimedia-equalizer-symbolic.svg" }
                                Text { text: "Mezclador de volumen (por aplicación)"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                Text {
                                    text: ((root.extData.audioStreams || []).length) + " activa" + (((root.extData.audioStreams || []).length) === 1 ? "" : "s")
                                    color: root.accentColor; font.pixelSize: 12; font.weight: Font.Medium
                                }
                            }

                            Rectangle {
                                visible: (root.extData.audioStreams || []).length === 0
                                width: parent.width; implicitHeight: 60; radius: 7; color: "#242424"; border.color: "#18ffffff"
                                Text {
                                    anchors.centerIn: parent
                                    text: "No hay aplicaciones reproduciendo audio en este momento (cuando abras Chrome, Discord o un juego aparecerán aquí)"
                                    color: "#8e8e8e"; font.pixelSize: 12; width: parent.width - 36; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                                }
                            }

                            Repeater {
                                model: root.extData.audioStreams || []
                                delegate: Rectangle {
                                    id: appStrCard
                                    readonly property var stObj: modelData
                                    property int localAppVol: Number(modelData.volume !== undefined ? modelData.volume : 100)
                                    width: parent.width; implicitHeight: appStrCol.implicitHeight + 28
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: appStrCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 14; spacing: 10
                                        GridLayout {
                                            Layout.fillWidth: true; columns: root.narrowBody ? 1 : 2; rowSpacing: 8; columnSpacing: 14
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 12
                                                Rectangle {
                                                    width: 34; height: 34; radius: 6
                                                    color: appStrCard.stObj.muted ? "#38ef4444" : (amH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                    border.color: appStrCard.stObj.muted ? "#88ef4444" : "#20ffffff"
                                                    WinSvg { anchors.centerIn: parent; width: 17; height: 17; iconFile: appStrCard.stObj.muted ? "fluent-speaker-mute.svg" : "fluent-speaker-high.svg" }
                                                    MouseArea { id: amH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bridge.toggleStreamMute(appStrCard.stObj.id); root.refreshLiveState(false); } }
                                                }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 2
                                                    Text { text: appStrCard.stObj.appName; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                    Text {
                                                        text: (appStrCard.stObj.mediaName ? (appStrCard.stObj.mediaName + "  •  ") : "") + (appStrCard.stObj.sinkName || "Predeterminado")
                                                        color: "#969696"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                }
                                            }
                                            RowLayout {
                                                Layout.fillWidth: root.narrowBody; Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight; spacing: 10
                                                SettingsSlider {
                                                    Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 165
                                                    from: 0; to: 100; value: appStrCard.localAppVol
                                                    onMovedValue: (v) => {
                                                        var iv = Math.round(v);
                                                        appStrCard.localAppVol = iv;
                                                        root.pushStreamVolLive(appStrCard.stObj.id, iv);
                                                    }
                                                    onReleasedValue: (v) => {
                                                        streamWriteTimer.stop();
                                                        var iv = Math.round(v);
                                                        appStrCard.localAppVol = iv;
                                                        root._lastStreamMs = Date.now();
                                                        bridge.setStreamVolume(appStrCard.stObj.id, iv);
                                                    }
                                                }
                                                Text { text: appStrCard.localAppVol + "%"; color: root.accentColor; font.pixelSize: 12; font.weight: Font.DemiBold; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                                FluentBtn {
                                                    visible: (root.extData.sinks || []).length > 1
                                                    label: root.expandedStreamRoute === appStrCard.stObj.id ? "Salida ▴" : "Salida ▾"
                                                    onClicked: {
                                                        var opening = root.expandedStreamRoute !== appStrCard.stObj.id;
                                                        root.expandedStreamRoute = opening ? appStrCard.stObj.id : "";
                                                        if (opening) root.ensureItemVisible(appStrCard);
                                                    }
                                                }
                                            }
                                        }

                                        // Per-App Output Routing Picker!
                                        Flow {
                                            visible: root.expandedStreamRoute === appStrCard.stObj.id
                                            Layout.fillWidth: true; spacing: 6
                                            Text { text: "Enviar a:"; color: "#9e9e9e"; font.pixelSize: 11; height: 30; verticalAlignment: Text.AlignVCenter }
                                            Repeater {
                                                model: root.extData.sinks || []
                                                delegate: Rectangle {
                                                    readonly property bool isCurS: modelData.id === appStrCard.stObj.sinkId
                                                    width: Math.min(280, rsTxt.implicitWidth + 20); height: 30; radius: 5
                                                    color: isCurS ? root.accentColor : (rsH.containsMouse ? "#383838" : "#202020")
                                                    border.color: isCurS ? root.accentColor : "#22ffffff"
                                                    Text { id: rsTxt; anchors.centerIn: parent; width: Math.min(260, implicitWidth); text: modelData.name; color: parent.isCurS ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCurS ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
                                                    MouseArea {
                                                        id: rsH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (bridge.moveStreamToSink(appStrCard.stObj.id, modelData.nodeName || modelData.id)) {
                                                                root.expandedStreamRoute = "";
                                                                root.refreshLiveState(false);
                                                                root.showToast(appStrCard.stObj.appName + " → " + modelData.name);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.2.D] AVANZADO: PERFILES DE TARJETAS (A2DP Hi-Fi vs HFP Auriculares Bluetooth / USB DAC!)
                            Text {
                                visible: (root.extData.audioCards || []).length > 0
                                text: "Avanzado — Perfiles de hardware (Bluetooth, DAC USB e interno)"
                                color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 8
                            }

                            Repeater {
                                model: root.extData.audioCards || []
                                delegate: Rectangle {
                                    id: acCard
                                    readonly property var cObj: modelData
                                    readonly property bool isExp: root.expandedAudioCard === modelData.cardName
                                    width: parent.width; implicitHeight: acCol.implicitHeight + 28
                                    radius: 7; color: "#262626"; border.color: isExp ? Qt.alpha(root.accentColor, 0.27) : "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: acCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 14; spacing: 10
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 12
                                            WinSvg { width: 19; height: 19; iconFile: root.audioBusIcon(acCard.cObj.busType) }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: acCard.cObj.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: "Perfil activo: " + (acCard.cObj.activeProfileLabel || acCard.cObj.activeProfile); color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            }
                                            Rectangle {
                                                width: cBusT.implicitWidth + 16; height: 22; radius: 4; color: "#1cffffff"; border.color: "#22ffffff"
                                                Text { id: cBusT; anchors.centerIn: parent; text: acCard.cObj.busType || "Audio"; color: "#d4d4d4"; font.pixelSize: 11 }
                                            }
                                            FluentBtn {
                                                label: acCard.isExp ? "Cerrar ▴" : "Perfil ▾"
                                                onClicked: {
                                                    var opening = !acCard.isExp;
                                                    root.expandedAudioCard = opening ? acCard.cObj.cardName : "";
                                                    if (opening) root.ensureItemVisible(acCard);
                                                }
                                            }
                                        }
                                        Column {
                                            visible: acCard.isExp
                                            Layout.fillWidth: true; spacing: 4
                                            Rectangle { width: parent.width; height: 1; color: "#18ffffff" }
                                            Item { width: 1; height: 3 }
                                            Repeater {
                                                model: acCard.cObj.profiles || []
                                                delegate: Rectangle {
                                                    width: parent.width; height: 34; radius: 5
                                                    color: modelData.active ? Qt.alpha(root.accentColor, 0.15) : (cpH.containsMouse ? "#333333" : "#202020")
                                                    border.color: modelData.active ? Qt.alpha(root.accentColor, 0.33) : "#14ffffff"
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right
                                                        anchors.leftMargin: 12; anchors.rightMargin: 12
                                                        text: modelData.label; color: modelData.active ? root.accentColor : "#ececec"
                                                        font.pixelSize: 12; font.weight: modelData.active ? Font.DemiBold : Font.Normal; elide: Text.ElideRight
                                                    }
                                                    MouseArea {
                                                        id: cpH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (bridge.setCardProfile(acCard.cObj.cardName, modelData.name)) {
                                                                root.expandedAudioCard = "";
                                                                root.refreshLiveState(false);
                                                                root.showToast("Perfil aplicado: " + modelData.label);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // [1.3] SUBPAGE: SISTEMA › NOTIFICACIONES (Full Windows 11 26H2 Notification & Focus Center!)
                        Column {
                            id: notifSubCol
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Notificaciones"
                            readonly property bool notifsOn: root.cfg.notifEnabled !== false

                            // [1.3.A] Notificaciones y comportamiento
                            Text { text: "Notificaciones y comportamiento"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold }

                            // Master Notifications Switch Card
                            ToggleCard {
                                iconFile: "fluent-bell.svg"
                                title: "Notificaciones"
                                subtitle: notifSubCol.notifsOn
                                          ? "Recibe avisos de aplicaciones, navegador y eventos del sistema"
                                          : "Todas las notificaciones emergentes y del centro están desactivadas"
                                checked: notifSubCol.notifsOn
                                onToggled: (v) => {
                                    root.updateCfg("notifEnabled", v);
                                    root.showToast(v ? "Notificaciones activadas" : "Notificaciones desactivadas");
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-bell-snooze.svg"
                                title: "No molestar"
                                subtitle: "Silencia los banners emergentes y sonidos, enviando los avisos directamente al centro (Win + N)"
                                checked: Boolean(root.cfg.doNotDisturb)
                                onToggled: (v) => {
                                    root.updateCfg("doNotDisturb", v);
                                    root.showToast(v ? "No molestar activado" : "No molestar desactivado");
                                }
                            }

                            ToggleCard {
                                visible: notifSubCol.notifsOn
                                iconFile: "fluent-chat.svg"
                                title: "Mostrar banners emergentes"
                                subtitle: "Muestra tarjetas emergentes en la esquina inferior derecha al recibir un aviso"
                                checked: root.cfg.notifShowBanners !== false
                                onToggled: (v) => root.updateCfg("notifShowBanners", v)
                            }

                            // Notification Sound Card (Switch + Test Chime Button!)
                            Rectangle {
                                visible: notifSubCol.notifsOn
                                width: parent.width; implicitHeight: Math.max(66, nsRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: nsRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    WinSvg { width: 21; height: 21; iconFile: "fluent-speaker-high.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Reproducir sonido al recibir notificaciones"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text { text: "Emite un tono suave cuando llega un aviso (se silencia automáticamente en No molestar)"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    FluentBtn {
                                        label: "Probar tono"
                                        onClicked: bridge.runCtlAction("notif-sound")
                                    }
                                    Win11Switch {
                                        checked: root.cfg.notifPlaySound !== false
                                        onToggled: (v) => root.updateCfg("notifPlaySound", v)
                                    }
                                }
                            }

                            // Banner Duration Selector
                            Rectangle {
                                visible: notifSubCol.notifsOn && root.cfg.notifShowBanners !== false
                                width: parent.width; implicitHeight: Math.max(66, ndRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: ndRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-window-apps.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Duración de los banners"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Tiempo que permanece visible cada tarjeta emergente en pantalla"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                        spacing: 6
                                        Repeater {
                                            model: [3, 5, 8, 12]
                                            delegate: Rectangle {
                                                readonly property bool isCurD: Number(root.cfg.notifBannerSecs || 5) === modelData
                                                width: 56; height: 34; radius: 6
                                                color: isCurD ? root.accentColor : (ndH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurD ? root.accentColor : "#20ffffff"
                                                Text { anchors.centerIn: parent; text: modelData + " s"; color: parent.isCurD ? "#000000" : "#ececec"; font.pixelSize: 12; font.weight: parent.isCurD ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: ndH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { root.updateCfg("notifBannerSecs", modelData); root.showToast("Duración de banners: " + modelData + " segundos"); }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.3.B] Sesiones de Concentración (Focus)
                            Text { text: "Concentración (Focus)"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }

                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(70, focRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: focRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-sparkle.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Duración de sesión predeterminada"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Activa No molestar automáticamente durante tus sesiones de concentración desde Win + N"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                        spacing: 6
                                        Repeater {
                                            model: [15, 30, 45, 60, 90]
                                            delegate: Rectangle {
                                                readonly property bool isCurF: Number(root.cfg.focusDurationMins || 30) === modelData
                                                width: 62; height: 34; radius: 6
                                                color: isCurF ? root.accentColor : (fdH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurF ? root.accentColor : "#20ffffff"
                                                Text { anchors.centerIn: parent; text: modelData + " min"; color: parent.isCurF ? "#000000" : "#ececec"; font.pixelSize: 12; font.weight: parent.isCurF ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: fdH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { root.updateCfg("focusDurationMins", modelData); root.showToast("Concentración: " + modelData + " minutos"); }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.3.C] Notificaciones por aplicación y remitentes
                            Text {
                                visible: notifSubCol.notifsOn && (root.extData.notifApps || []).length > 0
                                text: "Notificaciones de aplicaciones y otros remitentes"
                                color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6
                            }

                            Repeater {
                                model: notifSubCol.notifsOn ? (root.extData.notifApps || []) : []
                                delegate: Rectangle {
                                    id: naCard
                                    readonly property bool appAllowed: !(root.cfg.notifMutedApps && root.cfg.notifMutedApps[modelData.key] === true)
                                    width: parent.width; implicitHeight: Math.max(60, naRow.implicitHeight + 24)
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: naRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                        WinSvg { width: 20; height: 20; iconFile: modelData.icon || "fluent-bell.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: naCard.appAllowed ? (modelData.desc || "Banners y centro de notificaciones") : "Silenciada"; color: naCard.appAllowed ? "#969696" : "#f87171"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                        Win11Switch {
                                            checked: naCard.appAllowed
                                            onToggled: (v) => {
                                                var m = Object.assign({}, root.cfg.notifMutedApps || {});
                                                if (v) delete m[modelData.key];
                                                else m[modelData.key] = true;
                                                root.updateCfg("notifMutedApps", m);
                                                root.showToast(v ? (modelData.name + ": notificaciones activadas") : (modelData.name + ": silenciada"));
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.3.D] Pruebas y Centro de notificaciones
                            Text { text: "Pruebas y Centro de notificaciones"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }

                            Rectangle {
                                width: parent.width; implicitHeight: nTestCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: nTestCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 12
                                    Text {
                                        text: "Comprueba en tiempo real cómo se ven y suenan tus notificaciones o administra el historial del centro (Win + N)."
                                        color: "#b4b4b4"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 10
                                        FluentBtn {
                                            label: "Enviar notificación de prueba"
                                            accent: true
                                            onClicked: {
                                                if (root.cfg.notifEnabled === false) {
                                                    root.showToast("Activa 'Notificaciones' arriba para ver avisos");
                                                    return;
                                                }
                                                bridge.sendTestNotification();
                                                if (Boolean(root.cfg.doNotDisturb)) {
                                                    root.showToast("Enviada al centro Win+N (No molestar oculta el banner)");
                                                } else if (root.cfg.notifShowBanners === false) {
                                                    root.showToast("Enviada al centro Win+N (banners desactivados)");
                                                } else {
                                                    root.showToast("Notificación de prueba enviada");
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            label: "Abrir centro (Win + N)"
                                            onClicked: bridge.runCtlAction("toggle-calendar")
                                        }
                                        FluentBtn {
                                            label: "Limpiar centro"
                                            onClicked: {
                                                bridge.runCtlAction("clear-notifs");
                                                root.showToast("Centro de notificaciones vaciado");
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // [1.4] SUBPAGE: SISTEMA › ENERGÍA Y BATERÍA (Full Windows 11 26H2 Power & Battery Telemetry!)
                        Column {
                            id: pwrSubCol
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Energía y batería"
                            readonly property var bat: root.extData.battery || ({})
                            readonly property var pInfo: root.extData.powerInfo || ({})
                            readonly property int exactBatPct: (bat.pct !== undefined && bat.pct !== null) ? Math.max(0, Math.min(100, Number(bat.pct))) : 0

                            // [1.4.A] Battery & Hardware Power Hero Card (Fixes 0||100 bar bug + real 4-col telemetry!)
                            Rectangle {
                                width: parent.width; implicitHeight: batHeroCol.implicitHeight + 36
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                ColumnLayout {
                                    id: batHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 18; spacing: 14

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        Rectangle {
                                            width: 44; height: 44; radius: 8
                                            color: Qt.alpha(root.accentColor, 0.13); border.color: Qt.alpha(root.accentColor, 0.27)
                                            WinSvg { anchors.centerIn: parent; width: 24; height: 24; iconFile: pwrSubCol.bat.present ? "fluent-battery-charge.svg" : "fluent-plug.svg" }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text {
                                                text: pwrSubCol.bat.present ? "Estado de la batería" : "Alimentación de corriente alterna"
                                                color: "#f5f5f5"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                            Text {
                                                text: pwrSubCol.bat.label || "Conectado a corriente alterna"
                                                color: root.accentColor; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                        Text {
                                            visible: Boolean(pwrSubCol.bat.present)
                                            text: pwrSubCol.exactBatPct + "%"
                                            color: pwrSubCol.exactBatPct <= 15 ? "#f87171" : "#ffffff"
                                            font.pixelSize: 28; font.weight: Font.Bold
                                        }
                                    }

                                    // Exact Battery Level Bar (0% genuinely draws 0px — NEVER 100% green!)
                                    Rectangle {
                                        visible: Boolean(pwrSubCol.bat.present)
                                        Layout.fillWidth: true; height: 10; radius: 5; color: "#363636"
                                        Rectangle {
                                            width: parent.width * (pwrSubCol.exactBatPct / 100.0)
                                            height: 10; radius: 5
                                            color: pwrSubCol.exactBatPct <= 20 ? "#f87171" : "#4ade80"
                                            Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                                    // 4-Column Live Power & Battery Specs
                                    GridLayout {
                                        Layout.fillWidth: true; columns: root.narrowBody ? 2 : 4; rowSpacing: 10; columnSpacing: 16
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: pwrSubCol.bat.present ? "Batería" : "Fuente"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text {
                                                text: pwrSubCol.bat.present
                                                      ? ((pwrSubCol.bat.model || "Integrada") + (pwrSubCol.bat.tech ? (" • " + pwrSubCol.bat.tech) : ""))
                                                      : "Corriente CA"
                                                color: "#f0f0f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: pwrSubCol.bat.present ? "Salud y capacidad" : "Planificador"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text {
                                                text: pwrSubCol.bat.present
                                                      ? ((pwrSubCol.bat.healthPct > 0 ? (pwrSubCol.bat.healthPct + "%") : "Normal") + (pwrSubCol.bat.whDesign ? (" • " + pwrSubCol.bat.whDesign) : ""))
                                                      : (root.sysInfo.sched || "BORE")
                                                color: "#f0f0f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Alimentación"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text {
                                                text: (pwrSubCol.bat.acOnline ? "CA activo" : "Batería")
                                                      + (pwrSubCol.bat.voltageStr ? (" • " + pwrSubCol.bat.voltageStr) : "")
                                                      + (pwrSubCol.bat.powerW ? (" • " + pwrSubCol.bat.powerW) : "")
                                                color: "#f0f0f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "CPU y EPP en vivo"; color: "#8e8e8e"; font.pixelSize: 11 }
                                            Text {
                                                text: (pwrSubCol.pInfo.cpuFreqGhz || "—") + " • " + (pwrSubCol.pInfo.cpuEpp || "—")
                                                color: root.accentColor; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.4.B] Modo de energía (3 Visual Selectable Profile Cards!)
                            Text { text: "Modo de energía"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 4 }

                            GridLayout {
                                width: parent.width
                                columns: root.narrowBody ? 1 : 3
                                rowSpacing: 10; columnSpacing: 12
                                Repeater {
                                    model: [
                                        { id: "power-saver", icon: "fluent-battery-saver.svg", label: "Ahorro de energía", desc: "EPP power: menor temperatura, silencio y máxima autonomía" },
                                        { id: "balanced",    icon: "fluent-plug.svg",          label: "Equilibrado",       desc: "EPP balance: rendimiento ágil y consumo optimizado diario" },
                                        { id: "performance", icon: "fluent-games.svg",         label: "Gaming X64",        desc: "EPP performance: frecuencias máximas y mínima latencia" }
                                    ]
                                    delegate: Rectangle {
                                        id: pmCard
                                        readonly property bool isCur: root.hwState.powerProfile === modelData.id
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        implicitHeight: pmCardCol.implicitHeight + 32
                                        radius: 8
                                        color: isCur ? "#1e3a52" : (pModeHov.containsMouse ? "#2e2e2e" : "#262626")
                                        border.color: isCur ? root.accentColor : "#1effffff"; border.width: isCur ? 2 : 1
                                        Behavior on color { ColorAnimation { duration: 110 } }
                                        ColumnLayout {
                                            id: pmCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                            anchors.margins: 16; spacing: 8
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 10
                                                WinSvg { width: 20; height: 20; iconFile: modelData.icon }
                                                Text { text: modelData.label; color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Rectangle {
                                                    visible: pmCard.isCur
                                                    width: 10; height: 10; radius: 5; color: root.accentColor
                                                }
                                            }
                                            Text { text: modelData.desc; color: pmCard.isCur ? "#c8e8fa" : "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        MouseArea {
                                            id: pModeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.applyPowerProfileUi(modelData.id, modelData.label)
                                        }
                                    }
                                }
                            }

                            // [1.4.C] Pantalla, tapa del portátil y suspensión
                            Text { text: "Pantalla, tapa del portátil y suspensión"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }

                            ToggleCard {
                                visible: Boolean(pwrSubCol.bat.present && pwrSubCol.bat.trayVisible !== false)
                                iconFile: "fluent-battery-charge.svg"
                                title: "Mostrar porcentaje de batería en la barra de tareas"
                                subtitle: "Muestra el porcentaje numérico junto al icono de batería en la bandeja del sistema"
                                checked: Boolean(root.cfg.showBatteryPct)
                                onToggled: (v) => root.updateCfg("showBatteryPct", v)
                            }

                            Rectangle {
                                visible: Boolean(pwrSubCol.bat.present && pwrSubCol.bat.trayVisible === false)
                                width: parent.width; implicitHeight: Math.max(60, deadBatRow.implicitHeight + 26)
                                radius: 7; color: "#242424"; border.color: "#18ffffff"; border.width: 1
                                RowLayout {
                                    id: deadBatRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-plug.svg"; opacity: 0.85 }
                                    Text {
                                        text: "Batería sin carga (0%) conectada a corriente directa: el icono de batería se oculta automáticamente en la barra de tareas."
                                        color: "#a4a4a4"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-sparkle.svg"
                                title: "Evitar suspensión automática (Modo Cafeína)"
                                subtitle: "Mantiene un inhibidor real de systemd (idle, suspensión y tapa) activo para descargas largas o compilaciones"
                                checked: Boolean(pwrSubCol.pInfo.caffeineActive)
                                onToggled: (v) => {
                                    if (bridge.setCaffeineEnabled(v)) {
                                        var exC = Object.assign({}, root.extData);
                                        exC.powerInfo = Object.assign({}, exC.powerInfo || {}, { caffeineActive: v });
                                        root.extData = exC;
                                        root.showToast(v ? "Modo Cafeína activado (equipo despierto)" : "Modo Cafeína desactivado");
                                    }
                                }
                            }

                            // Laptop Lid Close Action on External Power / Monitor (real logind.conf.d: both ExternalPower & Docked!)
                            Rectangle {
                                visible: Boolean(pwrSubCol.pInfo.hasLid)
                                width: parent.width; implicitHeight: Math.max(70, lidRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: lidRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 21; height: 21; iconFile: "fluent-display.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Al cerrar la tapa (con corriente / monitor conectado)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                            Text { text: "Aplica tanto a corriente alterna como con monitor externo HDMI/DP (requiere clave de administrador)"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                        spacing: 6
                                        Repeater {
                                            model: [
                                                { id: "suspend", label: "Suspender" },
                                                { id: "ignore",  label: "No hacer nada" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCurL: (pwrSubCol.pInfo.lidExtAction || "suspend") === modelData.id
                                                width: lidTxt.implicitWidth + 22; height: 34; radius: 6
                                                color: isCurL ? root.accentColor : (lidH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurL ? root.accentColor : "#20ffffff"
                                                Text { id: lidTxt; anchors.centerIn: parent; text: modelData.label; color: parent.isCurL ? "#000000" : "#ececec"; font.pixelSize: 12; font.weight: parent.isCurL ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: lidH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (parent.isCurL) return;
                                                        var r = bridge.setLidExternalAction(modelData.id);
                                                        if (r === "ok") {
                                                            root.refreshLiveState(false);
                                                            root.showToast("Acción de tapa: " + modelData.label);
                                                        } else {
                                                            root.showToast(r.replace(/^error:/, ""));
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.4.D] Acciones rápidas de energía
                            Text { text: "Acciones rápidas de energía"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }

                            Rectangle {
                                width: parent.width; implicitHeight: pActCol.implicitHeight + 32
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: pActCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 18; spacing: 12
                                    Text { text: "Ejecuta acciones de sesión o energía de inmediato (Reiniciar y Apagar solicitan confirmación)."; color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 10
                                        FluentBtn { label: "Bloquear pantalla (Win + L)"; onClicked: bridge.triggerPowerAction("lock") }
                                        FluentBtn { label: "Suspender ahora"; onClicked: bridge.triggerPowerAction("suspend") }
                                        FluentBtn { label: "Reiniciar equipo"; onClicked: root.powerConfirmAction = "reboot" }
                                        FluentBtn { label: "Apagar equipo"; onClicked: root.powerConfirmAction = "poweroff" }
                                    }
                                }
                            }
                        }

                        // [1.5] SUBPAGE: SISTEMA › ALMACENAMIENTO (Windows 11 26H2 Storage Sense + Safe Cleanup + Personal Folders!)
                        Column {
                            id: stoSubCol
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Almacenamiento"
                            readonly property var sEx: root.extData.storageExtras || ({ "trashCount": 0, "trashSize": "0 B", "pacmanCacheSize": "0 B", "pacmanCacheCount": 0, "userCacheSize": "0 B", "userCacheBytes": 0, "journalSize": "0 B", "journalBytes": 0, "userFolders": [] })

                            // [1.5.A] Discos y volúmenes físicos
                            RowLayout {
                                width: parent.width; spacing: 10
                                Text { text: "Discos y volúmenes físicos (" + root.physicalDrives.length + ")"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                FluentBtn {
                                    label: "Recalcular tamaños"
                                    onClicked: {
                                        root.refreshLiveState(true);
                                        root.showToast("Recalculando uso de almacenamiento...");
                                    }
                                }
                            }

                            Repeater {
                                model: root.physicalDrives
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: drvCardCol.implicitHeight + 32
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: drvCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 16; spacing: 10
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 12
                                            WinSvg { width: 22; height: 22; iconFile: modelData.icon || "drive-c.svg"; opacity: modelData.mounted ? 1.0 : 0.7 }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: modelData.info; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                            }
                                            Text {
                                                text: modelData.mounted ? (Math.round(Number(modelData.usedRatio || 0) * 100) + "%") : "Sin montar"
                                                color: !modelData.mounted ? "#9e9e9e" : (modelData.isCritical ? "#f87171" : root.accentColor)
                                                font.pixelSize: 13; font.weight: Font.DemiBold
                                            }
                                            FluentBtn {
                                                visible: Boolean(modelData.mounted && modelData.path)
                                                label: "Abrir"
                                                onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer '" + modelData.path + "'")
                                            }
                                            FluentBtn {
                                                visible: !modelData.isSystem
                                                label: modelData.mounted ? "Desmontar" : "Montar"
                                                accent: !modelData.mounted
                                                onClicked: {
                                                    try {
                                                        var r = JSON.parse(modelData.mounted ? bridge.unmountDrive(modelData.device) : bridge.mountDrive(modelData.device));
                                                        root.refreshLiveState(false);
                                                        if (r && r.ok) root.showToast(modelData.mounted ? "Unidad desmontada" : ("Unidad montada: " + modelData.name));
                                                        else root.showToast((r && r.error) ? r.error : "No se pudo completar la operación");
                                                    } catch (e) {}
                                                }
                                            }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 8; radius: 4; color: "#363636"
                                            Rectangle {
                                                visible: Boolean(modelData.mounted)
                                                width: Math.max(8, parent.width * Number(modelData.usedRatio || 0.02)); height: 8; radius: 4
                                                color: modelData.isCritical ? "#d13438" : root.accentColor
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.5.B] Archivos temporales y limpieza segura
                            Text { text: "Archivos temporales y limpieza"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }

                            // 1. Papelera de reciclaje
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(66, trStoRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: trStoRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    WinSvg { width: 21; height: 21; iconFile: "trash.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Papelera de reciclaje"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text {
                                            text: Number(stoSubCol.sEx.trashCount || 0) + " elemento(s)  •  " + (stoSubCol.sEx.trashSize || "0 B")
                                            color: Number(stoSubCol.sEx.trashCount || 0) > 0 ? root.accentColor : "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    Row {
                                        spacing: 8
                                        FluentBtn { label: "Abrir"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer 'Papelera'") }
                                        FluentBtn {
                                            label: "Vaciar papelera"
                                            accent: Number(stoSubCol.sEx.trashCount || 0) > 0
                                            onClicked: {
                                                if (Number(stoSubCol.sEx.trashCount || 0) <= 0) {
                                                    root.showToast("La papelera ya está vacía");
                                                } else {
                                                    root.storageConfirmAction = "trash";
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 2. Caché de paquetes Pacman (/var/cache/pacman/pkg)
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(66, pacStoRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: pacStoRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    WinSvg { width: 21; height: 21; iconFile: "fluent-folder-zip.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Caché de paquetes del sistema (Pacman)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text {
                                            text: (stoSubCol.sEx.pacmanCacheSize || "0 B") + " en " + Number(stoSubCol.sEx.pacmanCacheCount || 0) + " paquetes  •  Conserva 1 versión para reversión segura"
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        label: "Limpiar caché"
                                        accent: Number(stoSubCol.sEx.pacmanCacheCount || 0) > 0
                                        onClicked: root.storageConfirmAction = "pacman"
                                    }
                                }
                            }

                            // 3. Caché temporal de aplicaciones (~/.cache)
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(66, uCacheRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: uCacheRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    WinSvg { width: 21; height: 21; iconFile: "fluent-delete.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Caché temporal de aplicaciones (~/.cache)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text {
                                            text: (stoSubCol.sEx.userCacheSize || "0 B") + "  •  Archivos temporales regenerables (navegador, miniaturas y apps)"
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    Row {
                                        spacing: 8
                                        FluentBtn {
                                            label: "Abrir"
                                            onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer '" + (root.extData.account ? root.extData.account.homeDir : "") + "/.cache'")
                                        }
                                        FluentBtn {
                                            label: "Limpiar caché"
                                            onClicked: root.storageConfirmAction = "usercache"
                                        }
                                    }
                                }
                            }

                            // 4. Registros del sistema (systemd-journald)
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(66, jnRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: jnRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    WinSvg { width: 21; height: 21; iconFile: "fluent-info.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Registros del sistema (journald)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text {
                                            text: (stoSubCol.sEx.journalSize || "0 B") + " en /var/log/journal  •  Conserva los últimos 7 días de diagnóstico"
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        label: "Reducir > 7 días"
                                        onClicked: {
                                            var r = bridge.vacuumJournalLogs();
                                            if (r === "ok") {
                                                root.refreshLiveState(true);
                                                root.showToast("Registros anteriores a 7 días eliminados");
                                            } else {
                                                root.showToast(r.replace(/^error:/, ""));
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.5.C] Carpetas personales (uso real + acceso directo!)
                            Text {
                                visible: (stoSubCol.sEx.userFolders || []).length > 0
                                text: "Carpetas personales"
                                color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6
                            }

                            GridLayout {
                                visible: (stoSubCol.sEx.userFolders || []).length > 0
                                width: parent.width
                                columns: root.narrowBody ? 1 : (root.wideBody ? 3 : 2)
                                columnSpacing: 10; rowSpacing: 10
                                Repeater {
                                    model: stoSubCol.sEx.userFolders || []
                                    delegate: Rectangle {
                                        Layout.fillWidth: true; implicitHeight: 68; radius: 7
                                        color: ufH.containsMouse ? "#2e2e2e" : "#262626"
                                        border.color: ufH.containsMouse ? "#2cffffff" : "#1cffffff"; border.width: 1
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                            WinSvg { width: 22; height: 22; iconFile: modelData.icon || "folder.svg" }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: modelData.size || "0 B"; color: Number(modelData.bytes || 0) > 0 ? root.accentColor : "#8e8e8e"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            }
                                            WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                        }
                                        MouseArea {
                                            id: ufH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer '" + modelData.key + "'")
                                        }
                                    }
                                }
                            }

                            // [1.5.D] Herramientas avanzadas de disco
                            Text { text: "Herramientas avanzadas de disco"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }

                            Rectangle {
                                width: parent.width; implicitHeight: stoToolsCol.implicitHeight + 32
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: stoToolsCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 18; spacing: 12
                                    Text { text: "Inspecciona salud SMART, particiones, formato de unidades USB y puntos de montaje del sistema."; color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 10
                                        FluentBtn {
                                            label: (root.extData.tools && root.extData.tools.hasGnomeDisks) ? "Abrir Discos (SMART y particiones)" : "Instalar gestor de discos"
                                            accent: true
                                            onClicked: {
                                                if (root.extData.tools && root.extData.tools.hasGnomeDisks) {
                                                    bridge.launchRealApp("gnome-disks");
                                                } else {
                                                    bridge.launchRealApp("/usr/bin/shelly-ui");
                                                    root.showToast("Busca 'gnome-disk-utility' en Tienda Shelly");
                                                }
                                            }
                                        }
                                        FluentBtn { label: "Abrir Explorador (Este equipo)"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer 'Este equipo'") }
                                    }
                                }
                            }
                        }

                        // [1.6] SUBPAGE: SISTEMA › ACERCA DE (Windows 11 26H2 Hardware Tiles + Device & OS Spec Tables!)
                        Column {
                            id: abtSubCol
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Acerca de"
                            readonly property var abInfo: root.extData.about || ({ "vendorModel": "", "boardBios": "", "archLabel": "Sistema operativo de 64 bits, procesador x86_64", "osPretty": "X64 LIOS Linux", "shellVersion": "x64-win11-settings", "compositorInfo": "Wayland • labwc", "uptimeHuman": "—", "hasX64Hello": false })
                            readonly property var gpuList: (root.sysInfo.gpus && root.sysInfo.gpus.length > 0) ? root.sysInfo.gpus : [{ label: "GPU 0", name: root.hwState.gpu || "Adaptador gráfico", vramTotalMb: 0, vramStr: "", driver: "" }]
                            readonly property string shortCpuTitle: String(root.sysInfo.cpu || "Procesador").replace(/\(R\)|\(TM\)|CPU\s*@.*$/g, "").replace(/\s+/g, " ").trim()
                            readonly property string primaryGpuSub: {
                                var g0 = gpuList[0];
                                var vGb = Number(g0.vramTotalMb || 0) > 0 ? ((Number(g0.vramTotalMb) / 1024).toFixed(0) + " GB VRAM") : (g0.vramStr || "Compartida");
                                return vGb + (g0.driver ? ("  •  " + g0.driver) : "");
                            }

                            // [1.6.A] Banner del dispositivo
                            Rectangle {
                                width: parent.width; implicitHeight: abtTopRow.implicitHeight + 34
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                RowLayout {
                                    id: abtTopRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                    Rectangle {
                                        width: 108; height: 62; radius: 6; color: "#000000"; border.color: "#4a4a4a"; border.width: 2; clip: true
                                        Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: root.activeWallpaperSrc; fillMode: Image.PreserveAspectCrop }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: root.sysInfo.hostname || "PC"; color: "#ffffff"; font.pixelSize: 20; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text {
                                            text: (abtSubCol.abInfo.vendorModel ? (abtSubCol.abInfo.vendorModel + "  •  ") : "") + (abtSubCol.abInfo.osPretty || "X64 LIOS Linux")
                                            color: root.accentColor; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                    FluentBtn {
                                        label: "Cambiar nombre de este equipo"
                                        accent: true
                                        onClicked: root.openRenamePcModal()
                                    }
                                }
                            }

                            // [1.6.B] Franja de 4 tarjetas resumen estilo Windows 11 26H2
                            GridLayout {
                                width: parent.width
                                columns: root.narrowBody ? 1 : (root.wideBody ? 4 : 2)
                                columnSpacing: 10; rowSpacing: 10

                                // Tile 1: Almacenamiento
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: 84; radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            WinSvg { width: 16; height: 16; iconFile: "drive-c.svg" }
                                            Text { text: "Almacenamiento"; color: "#a4a4a4"; font.pixelSize: 11; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                        Text {
                                            text: (root.sysInfo.diskTotalGb ? (root.sysInfo.diskTotalGb + " GB") : "Disco local")
                                            color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text: (root.sysInfo.diskType || "SSD") + (root.sysInfo.diskFs ? ("  •  " + String(root.sysInfo.diskFs).toUpperCase()) : "")
                                            color: "#969696"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Tile 2: Tarjeta gráfica
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: 84; radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            WinSvg { width: 16; height: 16; iconFile: "fluent-display.svg" }
                                            Text { text: "Tarjeta gráfica"; color: "#a4a4a4"; font.pixelSize: 11; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                        Text {
                                            text: abtSubCol.gpuList[0].name + (abtSubCol.gpuList.length > 1 ? (" (×" + abtSubCol.gpuList.length + ")") : "")
                                            color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text: abtSubCol.primaryGpuSub
                                            color: "#969696"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Tile 3: RAM instalada
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: 84; radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            WinSvg { width: 16; height: 16; iconFile: "taskmgr.svg" }
                                            Text { text: "RAM instalada"; color: "#a4a4a4"; font.pixelSize: 11; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                        Text {
                                            text: root.sysInfo.ramTotalGb ? (root.sysInfo.ramTotalGb + " GB") : (root.sysInfo.ram || "—")
                                            color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text: (root.sysInfo.ramAvailGb ? (root.sysInfo.ramAvailGb + " GB libre") : "") + (Number(root.sysInfo.swapTotalGb || 0) > 0.1 ? ("  •  Swap " + root.sysInfo.swapTotalGb + " GB") : "")
                                            color: "#969696"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                }

                                // Tile 4: Procesador
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: 84; radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 4
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            WinSvg { width: 16; height: 16; iconFile: "fluent-settings.svg" }
                                            Text { text: "Procesador"; color: "#a4a4a4"; font.pixelSize: 11; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                        Text {
                                            text: abtSubCol.shortCpuTitle
                                            color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text: (root.sysInfo.cpuPhysCores || 4) + " núcleos  •  " + (root.sysInfo.cpuCores || 8) + " hilos"
                                            color: "#969696"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            // [1.6.C] Tarjeta 1 — Especificaciones del dispositivo (tabla alineada 2 columnas!)
                            Rectangle {
                                width: parent.width; implicitHeight: specsCol.implicitHeight + 36
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: specsCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 18; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 19; height: 19; iconFile: "fluent-display.svg" }
                                        Text { text: "Especificaciones del dispositivo"; color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        FluentBtn {
                                            label: root.copiedNotice ? "Copiado" : "Copiar"
                                            accent: root.copiedNotice
                                            onClicked: {
                                                var gLines = abtSubCol.gpuList.map(function(g) {
                                                    var vTxt = Number(g.vramTotalMb || 0) > 0 ? ((Number(g.vramTotalMb) / 1024).toFixed(0) + " GB VRAM") : (g.vramStr || "");
                                                    return g.label + ": " + g.name + (vTxt ? (" (" + vTxt + ")") : "") + (g.driver ? (" — Driver " + g.driver) : "");
                                                }).join("\n");
                                                var ramLine = root.sysInfo.ramTotalGb ? (root.sysInfo.ramTotalGb + " GB (" + root.sysInfo.ramAvailGb + " GB disponible)") : root.sysInfo.ram;
                                                var out = "Nombre del dispositivo: " + (root.sysInfo.hostname || "PC")
                                                    + (abtSubCol.abInfo.vendorModel ? ("\nModelo del equipo: " + abtSubCol.abInfo.vendorModel) : "")
                                                    + (abtSubCol.abInfo.boardBios ? ("\nPlaca base y BIOS: " + abtSubCol.abInfo.boardBios) : "")
                                                    + "\nProcesador: " + root.sysInfo.cpu + " (" + (root.sysInfo.cpuPhysCores || 4) + " núcleos, " + (root.sysInfo.cpuCores || 8) + " hilos)"
                                                    + "\nRAM instalada: " + ramLine
                                                    + "\n" + gLines
                                                    + "\nTipo de sistema: " + (abtSubCol.abInfo.archLabel || "64 bits");
                                                bridge.copyTextToClipboard(out);
                                                root.copiedNotice = true;
                                                root.showToast("Especificaciones del dispositivo copiadas");
                                            }
                                        }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                                    // Aligned 2-column Device Spec Rows
                                    Repeater {
                                        model: {
                                            var rows = [
                                                { k: "Nombre del dispositivo", v: root.sysInfo.hostname || "PC" }
                                            ];
                                            if (abtSubCol.abInfo.vendorModel) rows.push({ k: "Modelo del equipo", v: abtSubCol.abInfo.vendorModel });
                                            if (abtSubCol.abInfo.boardBios) rows.push({ k: "Placa base y BIOS", v: abtSubCol.abInfo.boardBios });
                                            var cpuDet = String(root.sysInfo.cpu || "Procesador")
                                                + "  (" + (root.sysInfo.cpuPhysCores || 4) + " núcleos, " + (root.sysInfo.cpuCores || 8) + " hilos"
                                                + (root.sysInfo.cpuCache && root.sysInfo.cpuCache !== "—" ? ("  •  Caché " + root.sysInfo.cpuCache) : "") + ")";
                                            rows.push({ k: "Procesador", v: cpuDet });
                                            if (root.sysInfo.cpuVirt && root.sysInfo.cpuVirt !== "No detectada") {
                                                rows.push({ k: "Virtualización", v: root.sysInfo.cpuVirt });
                                            }
                                            var ramV = root.sysInfo.ramTotalGb
                                                ? (root.sysInfo.ramTotalGb + " GB  (" + root.sysInfo.ramAvailGb + " GB disponible"
                                                   + (Number(root.sysInfo.swapTotalGb || 0) > 0.1 ? ("  •  Swap/ZRAM " + root.sysInfo.swapTotalGb + " GB") : "") + ")")
                                                : (root.sysInfo.ram || "—");
                                            rows.push({ k: "RAM instalada", v: ramV });
                                            for (var i = 0; i < abtSubCol.gpuList.length; i++) {
                                                var g = abtSubCol.gpuList[i];
                                                var gVram = Number(g.vramTotalMb || 0) > 0 ? ((Number(g.vramTotalMb) / 1024).toFixed(0) + " GB VRAM") : (g.vramStr || "Memoria compartida");
                                                var gDesc = g.name + "  •  " + gVram + (g.driver ? ("  •  Driver " + g.driver) : "");
                                                rows.push({ k: g.label || ("GPU " + i), v: gDesc });
                                            }
                                            rows.push({ k: "Tipo de sistema", v: abtSubCol.abInfo.archLabel || "Sistema operativo de 64 bits, procesador x86_64" });
                                            return rows;
                                        }
                                        delegate: RowLayout {
                                            Layout.fillWidth: true; spacing: 14
                                            Text {
                                                text: modelData.k; color: "#a4a4a4"; font.pixelSize: 12; font.weight: Font.Medium
                                                Layout.preferredWidth: root.narrowBody ? 135 : 210
                                                Layout.alignment: Qt.AlignTop
                                                wrapMode: Text.WordWrap
                                            }
                                            Text {
                                                text: modelData.v; color: "#f0f0f0"; font.pixelSize: 12
                                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.6.D] Tarjeta 2 — Especificaciones de X64 LIOS (separada, estilo Windows 11!)
                            Rectangle {
                                width: parent.width; implicitHeight: osSpecsCol.implicitHeight + 36
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: osSpecsCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 18; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        WinSvg { width: 19; height: 19; iconFile: "x64lios.png" }
                                        Text { text: "Especificaciones de X64 LIOS"; color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        FluentBtn {
                                            label: root.copiedOsNotice ? "Copiado" : "Copiar"
                                            accent: root.copiedOsNotice
                                            onClicked: {
                                                var osOut = "Edición: " + (abtSubCol.abInfo.osPretty || "X64 LIOS Linux") + " — Escritorio Windows 11 26H2 Edition"
                                                    + "\nVersión del escritorio: " + (abtSubCol.abInfo.shellVersion || "x64-win11-settings")
                                                    + "\nKernel Linux: " + (root.sysInfo.kernel || "Linux")
                                                    + "\nPlanificador CPU: " + (root.sysInfo.sched || "—")
                                                    + "\nCompositor y shell: " + (abtSubCol.abInfo.compositorInfo || "Wayland • labwc")
                                                    + "\nPaquetes instalados: " + Number(root.extData.pkgCount || 0)
                                                    + "\nTiempo encendido: " + (abtSubCol.abInfo.uptimeHuman || "—");
                                                bridge.copyTextToClipboard(osOut);
                                                root.copiedOsNotice = true;
                                                root.showToast("Especificaciones de X64 LIOS copiadas");
                                            }
                                        }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                                    Repeater {
                                        model: [
                                            { k: "Edición",                v: (abtSubCol.abInfo.osPretty || "X64 LIOS Linux") + " — Escritorio Windows 11 26H2 Edition" },
                                            { k: "Versión del escritorio", v: abtSubCol.abInfo.shellVersion || "x64-win11-settings" },
                                            { k: "Kernel Linux",           v: root.sysInfo.kernel || "Linux" },
                                            { k: "Planificador CPU",       v: root.sysInfo.sched || "Estándar" },
                                            { k: "Compositor y shell",     v: abtSubCol.abInfo.compositorInfo || "Wayland • labwc" },
                                            { k: "Paquetes instalados",    v: Number(root.extData.pkgCount || 0) + " paquetes administrados por Pacman" },
                                            { k: "Tiempo encendido",       v: abtSubCol.abInfo.uptimeHuman || "—" }
                                        ]
                                        delegate: RowLayout {
                                            Layout.fillWidth: true; spacing: 14
                                            Text {
                                                text: modelData.k; color: "#a4a4a4"; font.pixelSize: 12; font.weight: Font.Medium
                                                Layout.preferredWidth: root.narrowBody ? 135 : 210
                                                Layout.alignment: Qt.AlignTop
                                                wrapMode: Text.WordWrap
                                            }
                                            Text {
                                                text: modelData.v; color: "#f0f0f0"; font.pixelSize: 12
                                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }

                            // [1.6.E] Tarjeta 3 — Accesos rápidos relacionados
                            Text { text: "Accesos rápidos relacionados"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 4 }

                            Rectangle {
                                width: parent.width; implicitHeight: abtRelCol.implicitHeight + 32
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: abtRelCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 18; spacing: 10
                                    Flow {
                                        Layout.fillWidth: true; spacing: 10
                                        FluentBtn { label: "Abrir Administrador de tareas"; accent: true; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app taskmgr") }
                                        FluentBtn { label: "Actualización del sistema"; onClicked: root.navigateTo("Actualización del sistema", "", true) }
                                        FluentBtn { label: "Almacenamiento"; onClicked: root.navigateTo("Sistema", "Almacenamiento", true) }
                                        FluentBtn {
                                            visible: Boolean(abtSubCol.abInfo.hasX64Hello)
                                            label: "Asistente X64 Hello"
                                            onClicked: bridge.launchRealApp("x64-hello")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 2: BLUETOOTH Y DISPOSITIVOS — OPCIÓN A (Hub 26H2 + 4 Subpáginas Reales!)
                    // =========================================================
                    Column {
                        id: btPageCol
                        width: parent.width; spacing: 12
                        visible: root.settingsPage === "Bluetooth y dispositivos"
                        readonly property var btAdp: root.extData.btAdapter || ({ "present": true, "powered": false, "discoverable": false, "pairable": false, "alias": "PC", "address": "" })
                        readonly property var inCfg: root.extData.inputCfg || ({})

                        // [2.0] HUB PRINCIPAL
                        Column {
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === ""

                            // Bluetooth Top Control Card (Real Adapter Info + Discoverable + Inline Scan!)
                            Rectangle {
                                width: parent.width; implicitHeight: btTopCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: btTopCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        WinSvg { width: 22; height: 22; iconFile: "fluent-bluetooth.svg"; opacity: btPageCol.btAdp.present ? 1.0 : 0.45 }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Bluetooth"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                            Text {
                                                text: !btPageCol.btAdp.present
                                                      ? "No se detectó un adaptador Bluetooth físico en este equipo"
                                                      : (root.hwState.btEnabled
                                                         ? ("Activado  •  Adaptador «" + (btPageCol.btAdp.alias || root.sysInfo.hostname || "PC") + "»"
                                                            + (btPageCol.btAdp.address ? (" (" + btPageCol.btAdp.address + ")") : "")
                                                            + (btPageCol.btAdp.discoverable ? "  •  Visible" : "  •  Oculto"))
                                                         : "Bluetooth desactivado")
                                                color: !btPageCol.btAdp.present ? "#969696" : (root.hwState.btEnabled ? "#9ed8f5" : "#9e9e9e")
                                                font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                        Win11Switch {
                                            visible: Boolean(btPageCol.btAdp.present)
                                            checked: Boolean(root.hwState.btEnabled)
                                            onToggled: (v) => {
                                                var cp = Object.assign({}, root.hwState); cp.btEnabled = v; root.hwState = cp;
                                                if (!v) root.btDiscovered = [];
                                                bridge.setBluetoothEnabled(v);
                                                root.refreshLiveState(false);
                                                root.showToast(v ? "Bluetooth activado" : "Bluetooth desactivado");
                                            }
                                        }
                                    }

                                    // Real Discoverable / Pairable Toggle Row
                                    Rectangle { visible: Boolean(btPageCol.btAdp.present && root.hwState.btEnabled); Layout.fillWidth: true; height: 1; color: "#18ffffff" }
                                    RowLayout {
                                        visible: Boolean(btPageCol.btAdp.present && root.hwState.btEnabled)
                                        Layout.fillWidth: true; spacing: 14
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Visible para otros dispositivos Bluetooth"; color: "#ececec"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                            Text { text: "Permite que teléfonos, mandos y auriculares encuentren este equipo como «" + (btPageCol.btAdp.alias || root.sysInfo.hostname || "PC") + "»"; color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Win11Switch {
                                            checked: Boolean(btPageCol.btAdp.discoverable)
                                            onToggled: (v) => {
                                                if (bridge.setBluetoothDiscoverable(v)) {
                                                    root.refreshLiveState(false);
                                                    root.showToast(v ? "Equipo visible por Bluetooth" : "Visibilidad Bluetooth oculta");
                                                }
                                            }
                                        }
                                    }

                                    Flow {
                                        visible: Boolean(btPageCol.btAdp.present)
                                        Layout.fillWidth: true; spacing: 10
                                        FluentBtn {
                                            label: root.btScanning ? "Buscando cercanos (7 s)..." : "Buscar dispositivos cercanos"
                                            accent: true
                                            onClicked: {
                                                if (!root.hwState.btEnabled) {
                                                    bridge.setBluetoothEnabled(true);
                                                }
                                                if (!root.btScanning) {
                                                    root.btScanning = true;
                                                    bridge.startBluetoothScan();
                                                    root.showToast("Buscando dispositivos Bluetooth cercanos...");
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            label: (root.extData.tools && root.extData.tools.hasBlueman) ? "Gestor avanzado (Blueman)" : "Instalar gestor Bluetooth"
                                            onClicked: bridge.launchRealApp((root.extData.tools && root.extData.tools.hasBlueman) ? "blueman-manager" : "/usr/bin/shelly-ui")
                                        }
                                        FluentBtn { label: "Actualizar"; onClicked: { root.refreshLiveState(false); root.showToast("Lista Bluetooth actualizada"); } }
                                    }
                                }
                            }

                            // Paired Bluetooth Devices (with Type Icon + Battery % + Conectar/Desconectar + Quitar!)
                            Column {
                                width: parent.width; spacing: 8
                                visible: (root.extData.btDevices || []).length > 0
                                Text { text: "Dispositivos Bluetooth emparejados (" + (root.extData.btDevices ? root.extData.btDevices.length : 0) + ")"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Repeater {
                                    model: root.extData.btDevices || []
                                    delegate: Rectangle {
                                        width: parent.width; implicitHeight: Math.max(66, btDevRow.implicitHeight + 28)
                                        radius: 7; color: modelData.connected ? "#223242" : "#262626"; border.color: modelData.connected ? root.accentColor : "#1cffffff"; border.width: 1
                                        RowLayout {
                                            id: btDevRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 12
                                            WinSvg { width: 20; height: 20; iconFile: root.btDeviceIcon(modelData.btIcon) }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text {
                                                    text: (modelData.connected ? "Conectado" : "Emparejado")
                                                          + (Number(modelData.battery) >= 0 ? ("  •  Batería " + modelData.battery + "%") : "")
                                                          + "  •  " + modelData.mac
                                                    color: modelData.connected ? root.accentColor : "#9a9a9a"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true
                                                }
                                            }
                                            Row {
                                                spacing: 8
                                                FluentBtn {
                                                    label: modelData.connected ? "Desconectar" : "Conectar"
                                                    accent: !modelData.connected
                                                    onClicked: {
                                                        bridge.toggleBluetoothDevice(modelData.mac, !modelData.connected);
                                                        root.showToast((modelData.connected ? "Desconectando " : "Conectando ") + modelData.name + "...");
                                                    }
                                                }
                                                FluentBtn {
                                                    label: "Quitar"
                                                    onClicked: {
                                                        if (bridge.removeBluetoothDevice(modelData.mac)) {
                                                            root.refreshLiveState(false);
                                                            root.showToast("Dispositivo quitado: " + modelData.name);
                                                        } else {
                                                            root.showToast("No se pudo quitar el dispositivo");
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Nearby Discovered Bluetooth Devices from Inline Scan!
                            Column {
                                width: parent.width; spacing: 8
                                visible: (root.btDiscovered || []).length > 0
                                Text { text: "Dispositivos Bluetooth cercanos (" + root.btDiscovered.length + ")"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Repeater {
                                    model: root.btDiscovered || []
                                    delegate: Rectangle {
                                        width: parent.width; implicitHeight: Math.max(64, btNewRow.implicitHeight + 26)
                                        radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                        RowLayout {
                                            id: btNewRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 12
                                            WinSvg { width: 20; height: 20; iconFile: root.btDeviceIcon(modelData.btIcon) }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: "Disponible para emparejar  •  " + modelData.mac; color: "#9a9a9a"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                            }
                                            FluentBtn {
                                                label: "Emparejar"
                                                accent: true
                                                onClicked: {
                                                    var res = bridge.pairBluetoothDevice(modelData.mac);
                                                    if (res === "ok") {
                                                        root.btDiscovered = root.btDiscovered.filter(function(it) { return it.mac !== modelData.mac; });
                                                        root.refreshLiveState(false);
                                                        root.showToast("Emparejado y conectado: " + modelData.name);
                                                    } else {
                                                        root.showToast(res.replace(/^error:/, ""));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 4 Dedicated Device Subpages (Opción A Windows 11 26H2!)
                            Text { text: "Periféricos y dispositivos"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 4 }

                            HubNavCard {
                                iconFile: "input-mouse-symbolic.svg"
                                title: "Mouse"
                                subtitle: (btPageCol.inCfg.mouseHwName ? (btPageCol.inCfg.mouseHwName + "  •  ") : "") + "Velocidad del puntero, aceleración Plana (Gaming) o Adaptativa, botón principal y rueda"
                                badge: btPageCol.inCfg.mouseAccel === "flat" ? "Plana (Gaming)" : "Adaptativa"
                                onClicked: root.navigateTo("Bluetooth y dispositivos", "Mouse", true)
                            }
                            HubNavCard {
                                iconFile: "input-touchpad-symbolic.svg"
                                title: "Panel táctil"
                                subtitle: (btPageCol.inCfg.touchpadHwName ? (btPageCol.inCfg.touchpadHwName + "  •  ") : "") + "Gestos táctiles, desactivar con mouse USB, protección de palma y sensibilidad"
                                badge: !btPageCol.inCfg.hasTouchpad ? "Sin hardware"
                                       : (btPageCol.inCfg.tpSendEvents === "no" ? "Desactivado"
                                          : (btPageCol.inCfg.tpSendEvents === "disabledOnExternalMouse" ? "Auto con mouse"
                                             : (btPageCol.inCfg.tpTap !== false ? "Toque activo" : "Estándar")))
                                onClicked: root.navigateTo("Bluetooth y dispositivos", "Panel táctil", true)
                            }
                            HubNavCard {
                                iconFile: "usb-hub-symbolic.svg"
                                title: "Dispositivos USB"
                                subtitle: "Periféricos, DACs de audio, receptores inalámbricos, cámaras y unidades externas USB"
                                badge: ((root.extData.usbDevices || []).length) + " conectados"
                                onClicked: root.navigateTo("Bluetooth y dispositivos", "Dispositivos USB", true)
                            }
                            HubNavCard {
                                iconFile: "printer-symbolic.svg"
                                title: "Impresoras y escáneres"
                                subtitle: "Administra impresoras locales y de red mediante CUPS" + (root.extData.cupsActive ? " (Servicio activo)" : "")
                                badge: ((root.extData.printers || []).length) > 0 ? ((root.extData.printers || []).length + " configuradas") : "Sin impresoras"
                                onClicked: root.navigateTo("Bluetooth y dispositivos", "Impresoras y escáneres", true)
                            }

                            // Dispositivos móviles y Enlace Móvil (Dedicated Opción A HubNavCard!)
                            HubNavCard {
                                iconFile: "fluent-phone.svg"
                                title: "Dispositivos móviles (Enlace Móvil)"
                                subtitle: "Pantalla táctil del móvil Android en ventana flotante (scrcpy) + notificaciones, batería y archivos (KDE Connect)"
                                badge: {
                                    var pl = root.extData.phoneLink || {};
                                    if (pl.mirrorActive) return "Pantalla activa";
                                    if ((pl.adbDevices || []).length > 0) return "Android listo";
                                    var kd = pl.kdeDevices || [];
                                    for (var i = 0; i < kd.length; i++) if (kd[i].paired && kd[i].reachable) return kd[i].name;
                                    return "KDE Connect + scrcpy";
                                }
                                onClicked: root.navigateTo("Bluetooth y dispositivos", "Dispositivos móviles", true)
                            }
                        }

                        // [2.1] SUBPAGE: BLUETOOTH Y DISPOSITIVOS › MOUSE (100% Real labwc libinput!)
                        Column {
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Mouse"

                            RowLayout {
                                width: parent.width; spacing: 10
                                Text {
                                    text: btPageCol.inCfg.mouseHwName ? ("Dispositivo detectado: " + btPageCol.inCfg.mouseHwName) : "Configuración de mouse (Wayland / libinput)"
                                    color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                FluentBtn {
                                    label: "Restablecer predeterminados"
                                    onClicked: {
                                        if (root.saveInputPatch({ mouseSpeed: 0.0, mouseAccel: "adaptive", mouseLeftHanded: false, mouseNaturalScroll: false, mouseScrollFactor: 1.0, mouseMiddleEmulation: false })) {
                                            root.showToast("Valores predeterminados del mouse restaurados");
                                        }
                                    }
                                }
                            }

                            // Velocidad del puntero (-1.0 a +1.0)
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(70, mSpdCol.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: mSpdCol; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        WinSvg { width: 21; height: 21; iconFile: "input-mouse-symbolic.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Velocidad del puntero del mouse"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Sensibilidad nativa de libinput aplicada en caliente en Wayland"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: root.narrowBody; Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight; spacing: 10
                                        SettingsSlider {
                                            Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 200
                                            from: -1.0; to: 1.0
                                            value: root.localMouseSpeed
                                            onDraggingChanged: root.mouseSpeedDragging = dragging
                                            onMovedValue: (v) => { root.localMouseSpeed = Math.round(v * 20) / 20.0; }
                                            onReleasedValue: (v) => {
                                                var sv = Math.round(v * 20) / 20.0;
                                                root.localMouseSpeed = sv;
                                                if (root.saveInputPatch({ mouseSpeed: sv })) root.showToast("Velocidad de mouse: " + Math.round((sv + 1.0) * 50) + "%");
                                            }
                                        }
                                        Text { text: Math.round((root.localMouseSpeed + 1.0) * 50) + "%"; color: root.accentColor; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }

                            // Perfil de aceleración (Plana Gaming vs Adaptativa)
                            Rectangle {
                                width: parent.width; implicitHeight: mAccCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: mAccCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 10
                                    Text { text: "Perfil de aceleración del puntero"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                    Text { text: "El perfil Plano desactiva la aceleración artificial (ideal para FPS y precisión 1:1)."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "flat",     label: "Plana (Gaming / Sin aceleración)" },
                                                { id: "adaptive", label: "Adaptativa (Estándar)" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: (btPageCol.inCfg.mouseAccel || "adaptive") === modelData.id
                                                width: maT.implicitWidth + 24; height: 34; radius: 6
                                                color: isCur ? root.accentColor : (maH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"
                                                Text { id: maT; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: maH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (root.saveInputPatch({ mouseAccel: modelData.id })) root.showToast("Aceleración: " + modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Botón principal + Velocidad de rueda
                            Rectangle {
                                width: parent.width; implicitHeight: mBtnCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: mBtnCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        Text { text: "Botón principal del mouse"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Row {
                                            spacing: 8
                                            Repeater {
                                                model: [{ lh: false, label: "Izquierdo" }, { lh: true, label: "Derecho (zurdo)" }]
                                                delegate: Rectangle {
                                                    readonly property bool isCur: Boolean(btPageCol.inCfg.mouseLeftHanded) === modelData.lh
                                                    width: mlT.implicitWidth + 22; height: 34; radius: 6
                                                    color: isCur ? root.accentColor : (mlH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCur ? root.accentColor : "#20ffffff"
                                                    Text { id: mlT; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                    MouseArea {
                                                        id: mlH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: { if (root.saveInputPatch({ mouseLeftHanded: modelData.lh })) root.showToast("Botón principal: " + modelData.label); }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        Text { text: "Velocidad de rueda (scroll)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Row {
                                            spacing: 6
                                            Repeater {
                                                model: [0.5, 1.0, 1.5, 2.0]
                                                delegate: Rectangle {
                                                    readonly property bool isCur: Math.abs(Number(btPageCol.inCfg.mouseScrollFactor || 1.0) - modelData) < 0.1
                                                    width: 54; height: 32; radius: 6
                                                    color: isCur ? root.accentColor : (msH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCur ? root.accentColor : "#20ffffff"
                                                    Text { anchors.centerIn: parent; text: modelData + "x"; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                    MouseArea {
                                                        id: msH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: { if (root.saveInputPatch({ mouseScrollFactor: modelData })) root.showToast("Velocidad de rueda: " + modelData + "x"); }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ToggleCard {
                                iconFile: "input-mouse-symbolic.svg"
                                title: "Desplazamiento natural del mouse"
                                subtitle: "Invierte el sentido vertical de la rueda (estilo panel táctil)"
                                checked: Boolean(btPageCol.inCfg.mouseNaturalScroll)
                                onToggled: (v) => { if (root.saveInputPatch({ mouseNaturalScroll: v })) root.showToast(v ? "Desplazamiento natural activado" : "Desplazamiento clásico activado"); }
                            }

                            ToggleCard {
                                iconFile: "input-mouse-symbolic.svg"
                                title: "Emulación de clic central"
                                subtitle: "Pulsar los botones izquierdo y derecho a la vez actúa como clic de rueda central"
                                checked: Boolean(btPageCol.inCfg.mouseMiddleEmulation)
                                onToggled: (v) => { if (root.saveInputPatch({ mouseMiddleEmulation: v })) root.showToast(v ? "Emulación de clic central activada" : "Emulación de clic central desactivada"); }
                            }
                        }

                        // [2.2] SUBPAGE: BLUETOOTH Y DISPOSITIVOS › PANEL TÁCTIL (100% Real labwc touchpad!)
                        Column {
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Panel táctil"

                            RowLayout {
                                width: parent.width; spacing: 10
                                Text {
                                    text: btPageCol.inCfg.hasTouchpad
                                          ? ("Hardware detectado: " + btPageCol.inCfg.touchpadHwName)
                                          : "No se detectó un panel táctil integrado en este equipo"
                                    color: btPageCol.inCfg.hasTouchpad ? "#c8c8c8" : "#f59e0b"
                                    font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                                FluentBtn {
                                    label: "Restablecer predeterminados"
                                    onClicked: {
                                        if (root.saveInputPatch({ tpSendEvents: "yes", tpTap: true, tpTapAndDrag: true, tpThreeFingerDrag: false, tpNaturalScroll: true, tpDisableTyping: true, tpClickMethod: "clickfinger", tpSpeed: 0.0 })) {
                                            root.showToast("Valores predeterminados del panel táctil restaurados");
                                        }
                                    }
                                }
                            }

                            // Estado maestro del panel táctil (Activado / Auto al conectar mouse USB / Desactivado)
                            Rectangle {
                                width: parent.width; implicitHeight: tpModeCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: tpModeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 10
                                    Text { text: "Estado del panel táctil"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                    Text { text: "Puedes mantenerlo activo o desactivarlo automáticamente cuando conectes un mouse externo."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "yes",                     label: "Activado" },
                                                { id: "disabledOnExternalMouse", label: "Desactivar con mouse USB" },
                                                { id: "no",                      label: "Desactivado" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: (btPageCol.inCfg.tpSendEvents || "yes") === modelData.id
                                                width: tseT.implicitWidth + 24; height: 34; radius: 6
                                                color: isCur ? root.accentColor : (tseH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#20ffffff"
                                                Text { id: tseT; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: tseH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { if (root.saveInputPatch({ tpSendEvents: modelData.id })) root.showToast("Panel táctil: " + modelData.label); }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Velocidad del panel táctil (FIXED flush-right alignment!)
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(70, tpSpdCol.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: tpSpdCol; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        WinSvg { width: 21; height: 21; iconFile: "input-touchpad-symbolic.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Velocidad del panel táctil"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Ajusta la sensibilidad del cursor en el trackpad"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: root.narrowBody; Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight; spacing: 10
                                        SettingsSlider {
                                            Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 200
                                            from: -1.0; to: 1.0; value: root.localTpSpeed
                                            onDraggingChanged: root.tpSpeedDragging = dragging
                                            onMovedValue: (v) => { root.localTpSpeed = Math.round(v * 20) / 20.0; }
                                            onReleasedValue: (v) => {
                                                var sv = Math.round(v * 20) / 20.0;
                                                root.localTpSpeed = sv;
                                                if (root.saveInputPatch({ tpSpeed: sv })) root.showToast("Velocidad touchpad: " + Math.round((sv + 1.0) * 50) + "%");
                                            }
                                        }
                                        Text { text: Math.round((root.localTpSpeed + 1.0) * 50) + "%"; color: root.accentColor; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }

                            ToggleCard {
                                iconFile: "input-touchpad-symbolic.svg"
                                title: "Tocar para hacer clic"
                                subtitle: "Permite hacer clic izquierdo tocando suavemente la superficie del panel táctil"
                                checked: btPageCol.inCfg.tpTap !== false
                                onToggled: (v) => { if (root.saveInputPatch({ tpTap: v })) root.showToast(v ? "Toque activado" : "Toque desactivado"); }
                            }
                            ToggleCard {
                                iconFile: "input-touchpad-symbolic.svg"
                                title: "Tocar y arrastrar"
                                subtitle: "Un toque seguido de mantener el dedo pulsado permite arrastrar ventanas y archivos"
                                checked: btPageCol.inCfg.tpTapAndDrag !== false
                                onToggled: (v) => { if (root.saveInputPatch({ tpTapAndDrag: v })) root.showToast(v ? "Tocar y arrastrar activado" : "Tocar y arrastrar desactivado"); }
                            }
                            ToggleCard {
                                iconFile: "input-touchpad-symbolic.svg"
                                title: "Arrastrar con 3 dedos"
                                subtitle: "Desliza tres dedos para arrastrar ventanas y seleccionar texto sin pulsar botones físicos"
                                checked: Boolean(btPageCol.inCfg.tpThreeFingerDrag)
                                onToggled: (v) => { if (root.saveInputPatch({ tpThreeFingerDrag: v })) root.showToast(v ? "Arrastre con 3 dedos activado" : "Arrastre con 3 dedos desactivado"); }
                            }
                            ToggleCard {
                                iconFile: "input-touchpad-symbolic.svg"
                                title: "Desplazamiento natural con dos dedos"
                                subtitle: "Desliza hacia arriba o abajo en la misma dirección que el contenido"
                                checked: btPageCol.inCfg.tpNaturalScroll !== false
                                onToggled: (v) => { if (root.saveInputPatch({ tpNaturalScroll: v })) root.showToast(v ? "Desplazamiento natural activado" : "Desplazamiento clásico activado"); }
                            }
                            ToggleCard {
                                iconFile: "fluent-keyboard.svg"
                                title: "Desactivar panel táctil mientras escribes"
                                subtitle: "Evita toques accidentales con la palma al teclear en portátiles"
                                checked: btPageCol.inCfg.tpDisableTyping !== false
                                onToggled: (v) => { if (root.saveInputPatch({ tpDisableTyping: v })) root.showToast(v ? "Protección de palma activada" : "Protección de palma desactivada"); }
                            }

                            // Método de clic derecho (clickfinger vs buttonAreas)
                            Rectangle {
                                width: parent.width; implicitHeight: Math.max(70, tpCmRow.implicitHeight + 30)
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: tpCmRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 16
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        WinSvg { width: 21; height: 21; iconFile: "input-touchpad-symbolic.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Método de clic derecho"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Elige cómo activar el menú contextual al presionar el panel táctil"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Row {
                                        Layout.alignment: root.narrowBody ? Qt.AlignLeft : Qt.AlignRight
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "clickfinger", label: "Pulsar con 2 dedos" },
                                                { id: "buttonAreas", label: "Esquina inferior derecha" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: (btPageCol.inCfg.tpClickMethod || "clickfinger") === modelData.id
                                                width: tcmT.implicitWidth + 22; height: 34; radius: 6
                                                color: isCur ? root.accentColor : (tcmH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#20ffffff"
                                                Text { id: tcmT; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: tcmH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { if (root.saveInputPatch({ tpClickMethod: modelData.id })) root.showToast("Clic derecho: " + modelData.label); }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // [2.3] SUBPAGE: BLUETOOTH Y DISPOSITIVOS › DISPOSITIVOS USB (Enriched sysfs + Speed + Category + Safe Eject!)
                        Column {
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Dispositivos USB"

                            RowLayout {
                                width: parent.width; spacing: 10
                                Text { text: "Periféricos USB detectados en vivo (" + (root.extData.usbDevices ? root.extData.usbDevices.length : 0) + ")"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                FluentBtn { label: "Actualizar"; onClicked: { root.refreshLiveState(false); root.showToast("Lista USB actualizada"); } }
                            }
                            Rectangle {
                                visible: (root.extData.usbDevices || []).length === 0
                                width: parent.width; implicitHeight: 68; radius: 7; color: "#262626"; border.color: "#1cffffff"
                                Text {
                                    anchors.centerIn: parent
                                    text: "No se detectaron periféricos USB externos conectados en este momento."
                                    color: "#9a9a9a"; font.pixelSize: 12
                                }
                            }
                            Repeater {
                                model: root.extData.usbDevices || []
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: Math.max(68, usbRow.implicitHeight + 28)
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: usbRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                        WinSvg { width: 21; height: 21; iconFile: modelData.icon || "usb-hub-symbolic.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text {
                                                text: (modelData.mfg ? (modelData.mfg + "  •  ") : "") + "ID " + modelData.id + "  •  Bus " + modelData.bus + " Dispositivo " + modelData.dev
                                                color: "#9a9a9a"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                        Rectangle {
                                            width: uCatT.implicitWidth + 16; height: 24; radius: 5; color: "#1cffffff"; border.color: "#22ffffff"
                                            Text { id: uCatT; anchors.centerIn: parent; text: modelData.category || "USB"; color: "#e0e0e0"; font.pixelSize: 11; font.weight: Font.Medium }
                                        }
                                        Rectangle {
                                            visible: Boolean(modelData.speed)
                                            width: uSpdT.implicitWidth + 16; height: 24; radius: 5; color: Qt.alpha(root.accentColor, 0.1); border.color: Qt.alpha(root.accentColor, 0.22)
                                            Text { id: uSpdT; anchors.centerIn: parent; text: modelData.speed || ""; color: "#8ad9ff"; font.pixelSize: 11 }
                                        }
                                        FluentBtn {
                                            visible: Boolean(modelData.ejectDevice)
                                            label: "Expulsar"
                                            accent: true
                                            onClicked: {
                                                var r = bridge.ejectUsbDrive(modelData.ejectDevice);
                                                root.refreshLiveState(false);
                                                root.showToast(r === "ok" ? ("Expulsado con seguridad: " + modelData.name) : r.replace(/^error:/, ""));
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // [2.4] SUBPAGE: BLUETOOTH Y DISPOSITIVOS › IMPRESORAS Y ESCÁNERES (Live CUPS + Test Page + Default!)
                        Column {
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Impresoras y escáneres"

                            Rectangle {
                                width: parent.width; implicitHeight: prnHdrCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: prnHdrCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        WinSvg { width: 22; height: 22; iconFile: "printer-symbolic.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Agregar o administrar impresoras"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                            Text { text: "Detecta impresoras USB y de red Wi-Fi mediante el servicio de impresión CUPS"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Rectangle {
                                            width: cupsStT.implicitWidth + 18; height: 26; radius: 5
                                            color: root.extData.cupsActive ? "#2210b981" : "#22ef4444"
                                            border.color: root.extData.cupsActive ? "#5510b981" : "#55ef4444"
                                            Text {
                                                id: cupsStT; anchors.centerIn: parent
                                                text: root.extData.cupsActive ? "CUPS activo" : "CUPS inactivo"
                                                color: root.extData.cupsActive ? "#4ade80" : "#f87171"
                                                font.pixelSize: 11; font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 10
                                        FluentBtn {
                                            label: (root.extData.tools && root.extData.tools.hasPrinterGui) ? "+ Agregar / Configurar" : "Instalar (Tienda Shelly)"
                                            accent: true
                                            onClicked: {
                                                if (root.extData.tools && root.extData.tools.hasPrinterGui) {
                                                    bridge.launchRealApp("system-config-printer");
                                                } else {
                                                    bridge.launchRealApp("/usr/bin/shelly-ui");
                                                    root.showToast("Busca 'system-config-printer' en Tienda Shelly");
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            label: "Actualizar lista"
                                            onClicked: { root.refreshLiveState(true); root.showToast("Buscando impresoras en CUPS..."); }
                                        }
                                        FluentBtn {
                                            visible: Boolean(root.extData.cupsActive)
                                            label: "Panel web CUPS (localhost:631)"
                                            onClicked: bridge.openFileOrUrl("http://localhost:631")
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                visible: (root.extData.printers || []).length === 0
                                width: parent.width; implicitHeight: 74; radius: 7; color: "#242424"; border.color: "#18ffffff"
                                Text {
                                    anchors.centerIn: parent; width: parent.width - 40
                                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                                    text: "No hay impresoras configuradas todavía. Haz clic en «+ Agregar / Configurar» para detectar automáticamente impresoras USB o de red Wi-Fi."
                                    color: "#9a9a9a"; font.pixelSize: 12
                                }
                            }

                            Repeater {
                                model: root.extData.printers || []
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: Math.max(68, prnItRow.implicitHeight + 28)
                                    radius: 7; color: modelData.isDefault ? "#223242" : "#262626"; border.color: modelData.isDefault ? root.accentColor : "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: prnItRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                        WinSvg { width: 21; height: 21; iconFile: "printer-symbolic.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: (modelData.isDefault ? "Predeterminada  •  " : "") + (modelData.status || "Lista"); color: modelData.isDefault ? root.accentColor : "#9a9a9a"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                        Row {
                                            spacing: 8
                                            FluentBtn {
                                                visible: !modelData.isDefault
                                                label: "Predeterminada"
                                                onClicked: {
                                                    if (bridge.setDefaultPrinter(modelData.name)) {
                                                        root.refreshLiveState(true);
                                                        root.showToast("Impresora predeterminada: " + modelData.name);
                                                    }
                                                }
                                            }
                                            FluentBtn {
                                                label: "Página de prueba"
                                                onClicked: {
                                                    if (bridge.printTestPage(modelData.name)) root.showToast("Enviada página de prueba a " + modelData.name);
                                                    else root.showToast("No se pudo enviar la página de prueba");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // [2.5] SUBPAGE: BLUETOOTH Y DISPOSITIVOS › DISPOSITIVOS MÓVILES (Enlace Móvil: scrcpy Acoplado/Desacoplado + KDE Connect!)
                        Column {
                            id: mobSubCol
                            width: parent.width; spacing: 12
                            visible: root.settingsSubPage === "Dispositivos móviles"
                            readonly property var pl: root.extData.phoneLink || ({ "kdeInstalled": true, "kdeRunning": false, "scrcpyInstalled": true, "adbInstalled": true, "kdeDevices": [], "adbDevices": [], "mirrorActive": false, "mirrorMode": "", "mirrorSerial": "" })
                            readonly property var adbList: pl.adbDevices || []
                            readonly property var kdeList: pl.kdeDevices || []

                            // [2.5.A] PANTALLA DEL TELÉFONO ANDROID (scrcpy Acoplado / Desacoplado / Wi-Fi sin cable!)
                            RowLayout {
                                width: parent.width; spacing: 10
                                Text { text: "Pantalla del teléfono Android (scrcpy)"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                FluentBtn { label: "Actualizar dispositivos"; onClicked: { root.refreshLiveState(false); root.showToast("Buscando teléfonos conectados..."); } }
                            }

                            // Hero Mirror Card
                            Rectangle {
                                width: parent.width; implicitHeight: phMirCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: mobSubCol.pl.mirrorActive ? Qt.alpha(root.accentColor, 0.33) : "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: phMirCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        WinSvg { width: 24; height: 24; iconFile: "fluent-phone.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text {
                                                text: mobSubCol.pl.mirrorActive
                                                      ? "Pantalla del móvil activa en el escritorio"
                                                      : (mobSubCol.adbList.length > 0 ? ("Android detectado: " + mobSubCol.adbList[0].model) : "Controla tu Android directamente en el escritorio")
                                                color: "#ffffff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                            Text {
                                                text: mobSubCol.adbList.length > 0
                                                      ? (mobSubCol.adbList[0].authorized
                                                         ? ("Conectado por " + (mobSubCol.adbList[0].isWifi ? "Wi-Fi inalámbrico" : "cable USB")
                                                            + (Number(mobSubCol.adbList[0].battery) >= 0 ? ("  •  Batería " + mobSubCol.adbList[0].battery + "%" + (mobSubCol.adbList[0].charging ? " (cargando)" : "")) : "")
                                                            + "  •  Clic derecho = Atrás, clic central = Inicio")
                                                         : "Desbloquea tu móvil Android y acepta el permiso «Permitir depuración USB»")
                                                      : "Conecta tu Android por USB con «Depuración USB» activada o enlázalo por Wi-Fi para verlo y usarlo en 60/120 FPS."
                                                color: mobSubCol.adbList.length > 0 ? "#9ed8f5" : "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn {
                                            label: mobSubCol.pl.mirrorActive ? "Cerrar pantalla del móvil" : "Ver pantalla del móvil"
                                            accent: !mobSubCol.pl.mirrorActive
                                            onClicked: {
                                                if (mobSubCol.pl.mirrorActive) {
                                                    bridge.phoneMirrorStop();
                                                    root.refreshLiveState(false);
                                                    root.showToast("Pantalla del teléfono cerrada");
                                                } else {
                                                    var r = bridge.phoneMirrorStart("");
                                                    root.refreshLiveState(false);
                                                    root.showToast(r === "ok" ? "Pantalla del móvil abierta" : r.replace(/^error:/, ""));
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            visible: mobSubCol.adbList.length > 0 && Boolean(mobSubCol.adbList[0].authorized)
                                            label: "Enviar archivo (Descargas)"
                                            onClicked: {
                                                var rf = bridge.phoneSendFileAdb(mobSubCol.adbList[0].serial);
                                                if (rf !== "cancel") root.showToast(rf.replace(/^(ok|error):/, ""));
                                            }
                                        }
                                    }

                                    // Individual Detected Android ADB Devices List (when 1+ connected via USB/Wi-Fi!)
                                    Repeater {
                                        model: mobSubCol.adbList
                                        delegate: Rectangle {
                                            Layout.fillWidth: true; implicitHeight: Math.max(54, adbDevR.implicitHeight + 18)
                                            radius: 6; color: "#202020"; border.color: modelData.authorized ? Qt.alpha(root.accentColor, 0.2) : "#34f59e0b"
                                            RowLayout {
                                                id: adbDevR; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10
                                                WinSvg { width: 17; height: 17; iconFile: modelData.isWifi ? "fluent-wifi.svg" : "usb-hub-symbolic.svg" }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 1
                                                    Text { text: modelData.model; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                    Text {
                                                        text: (modelData.isWifi ? ("Wi-Fi • " + modelData.serial) : ("USB • " + modelData.serial))
                                                              + (Number(modelData.battery) >= 0 ? ("  •  Batería " + modelData.battery + "%" + (modelData.charging ? " (cargando)" : "")) : "")
                                                              + (!modelData.authorized ? "  •  Sin autorizar" : "")
                                                        color: modelData.authorized ? "#9e9e9e" : "#fbbf24"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                }
                                                FluentBtn {
                                                    visible: Boolean(modelData.authorized)
                                                    label: "Proyectar"
                                                    onClicked: {
                                                        var rs = bridge.phoneMirrorStart(modelData.serial);
                                                        root.refreshLiveState(false);
                                                        root.showToast(rs === "ok" ? ("Proyectando " + modelData.model) : rs.replace(/^error:/, ""));
                                                    }
                                                }
                                                FluentBtn {
                                                    visible: Boolean(modelData.isWifi)
                                                    label: "Desconectar"
                                                    onClicked: {
                                                        if (bridge.phoneDisconnectWifiAdb(modelData.serial)) {
                                                            root.refreshLiveState(false);
                                                            root.showToast("Desconectado de " + modelData.serial);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Wireless ADB 1-Click + Manual IP:port Bar
                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Modo inalámbrico sin cable (Wi-Fi ADB)"; color: "#ececec"; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: "Conecta tu móvil una vez por USB y pulsa activar, o escribe su IP de red local (p. ej. 192.168.3.42)"; color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        FluentBtn {
                                            label: "Activar Wi-Fi desde USB"
                                            onClicked: {
                                                var rw = bridge.phoneEnableWifiAdb("");
                                                root.refreshLiveState(false);
                                                if (rw.indexOf("ok:") === 0) root.showToast("Android enlazado por Wi-Fi (" + rw.slice(3) + ") — ya puedes desconectar el cable");
                                                else root.showToast(rw.replace(/^error:/, ""));
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Rectangle {
                                            Layout.fillWidth: true; height: 34; radius: 6; color: "#181818"
                                            border.color: wifiAdbIn.activeFocus ? root.accentColor : "#2cffffff"; clip: true
                                            TextInput {
                                                id: wifiAdbIn
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                                                verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true
                                                onAccepted: {
                                                    var rc = bridge.phoneConnectWifiAdb(text);
                                                    root.refreshLiveState(false);
                                                    root.showToast(rc.indexOf("ok:") === 0 ? ("Conectado por Wi-Fi a " + rc.slice(3)) : rc.replace(/^error:/, ""));
                                                }
                                            }
                                            Text {
                                                visible: wifiAdbIn.text === ""; anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12
                                                text: "IP del teléfono (ej. 192.168.3.50 o 192.168.3.50:5555)"; color: "#6e6e6e"; font.pixelSize: 12
                                            }
                                        }
                                        FluentBtn {
                                            label: "Conectar IP"
                                            onClicked: wifiAdbIn.accepted()
                                        }
                                    }
                                }
                            }

                            // Quality & Behavior Controls for scrcpy
                            Rectangle {
                                width: parent.width; implicitHeight: scrcpyCfgCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: scrcpyCfgCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        Text { text: "Fluidez máxima (FPS)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Row {
                                            spacing: 6
                                            Repeater {
                                                model: [30, 60, 120]
                                                delegate: Rectangle {
                                                    readonly property bool isCurF: Number(root.cfg.phoneMaxFps || 60) === modelData
                                                    width: 68; height: 32; radius: 6
                                                    color: isCurF ? root.accentColor : (pfH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCurF ? root.accentColor : "#20ffffff"
                                                    Text { anchors.centerIn: parent; text: modelData + " FPS"; color: parent.isCurF ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCurF ? Font.DemiBold : Font.Normal }
                                                    MouseArea {
                                                        id: pfH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.applyPhonePref("phoneMaxFps", modelData, "Fluidez Enlace Móvil: " + modelData + " FPS")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        Text { text: "Calidad de vídeo (Bitrate)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Row {
                                            spacing: 6
                                            Repeater {
                                                model: [
                                                    { id: "4M",  lbl: "4 Mbps" },
                                                    { id: "8M",  lbl: "8 Mbps" },
                                                    { id: "16M", lbl: "16 Mbps" }
                                                ]
                                                delegate: Rectangle {
                                                    readonly property bool isCurB: String(root.cfg.phoneBitrate || "8M") === modelData.id
                                                    width: 76; height: 32; radius: 6
                                                    color: isCurB ? root.accentColor : (pbH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCurB ? root.accentColor : "#20ffffff"
                                                    Text { anchors.centerIn: parent; text: modelData.lbl; color: parent.isCurB ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCurB ? Font.DemiBold : Font.Normal }
                                                    MouseArea {
                                                        id: pbH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.applyPhonePref("phoneBitrate", modelData.id, "Bitrate de vídeo: " + modelData.lbl)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-display.svg"
                                title: "Mantener ventana del móvil siempre encima"
                                subtitle: "Fija la pantalla del teléfono por delante del resto de ventanas mientras trabajas o juegas"
                                checked: Boolean(root.cfg.phoneAlwaysOnTop)
                                onToggled: (v) => root.applyPhonePref("phoneAlwaysOnTop", v, v ? "Ventana móvil siempre encima" : "Ventana móvil normal")
                            }
                            ToggleCard {
                                iconFile: "fluent-speaker-high.svg"
                                title: "Reenviar audio del móvil al PC"
                                subtitle: "Escucha el sonido de apps, vídeos y notificaciones del teléfono por tus altavoces o auriculares"
                                checked: root.cfg.phoneAudio !== false
                                onToggled: (v) => root.applyPhonePref("phoneAudio", v, v ? "Audio del móvil activado" : "Audio del móvil silenciado")
                            }
                            ToggleCard {
                                iconFile: "fluent-sleep.svg"
                                title: "Apagar pantalla física del teléfono al proyectar"
                                subtitle: "Ahorra batería y privacidad en el móvil mientras lo controlas desde X64 LIOS"
                                checked: Boolean(root.cfg.phoneTurnScreenOff)
                                onToggled: (v) => root.applyPhonePref("phoneTurnScreenOff", v, v ? "Pantalla física del móvil se apagará" : "Pantalla física del móvil encendida")
                            }
                            ToggleCard {
                                iconFile: "fluent-battery-charge.svg"
                                title: "Mantener el teléfono despierto"
                                subtitle: "Evita que el teléfono se bloquee mientras está proyectado en el escritorio"
                                checked: root.cfg.phoneStayAwake !== false
                                onToggled: (v) => root.applyPhonePref("phoneStayAwake", v, v ? "Mantener teléfono despierto activado" : "Mantener teléfono despierto desactivado")
                            }

                            // [2.5.B] SINCRONIZACIÓN INALÁMBRICA (KDE Connect — Android e iPhone!)
                            Text { text: "Sincronización inalámbrica (KDE Connect — Android e iPhone)"; color: "#c8c8c8"; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }

                            Rectangle {
                                width: parent.width; implicitHeight: kdeHdrCol.implicitHeight + 34
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: kdeHdrCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; anchors.topMargin: 17; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        WinSvg { width: 22; height: 22; iconFile: "fluent-link.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Servicio KDE Connect"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                            Text { text: "Sincroniza notificaciones, portapapeles, batería, SMS y envío de archivos en tu red Wi-Fi"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Rectangle {
                                            width: kdeStT.implicitWidth + 18; height: 26; radius: 5
                                            color: mobSubCol.pl.kdeRunning ? "#2210b981" : "#22f59e0b"
                                            border.color: mobSubCol.pl.kdeRunning ? "#5510b981" : "#55f59e0b"
                                            Text {
                                                id: kdeStT; anchors.centerIn: parent
                                                text: mobSubCol.pl.kdeRunning ? "Activo" : "En espera"
                                                color: mobSubCol.pl.kdeRunning ? "#4ade80" : "#fbbf24"
                                                font.pixelSize: 11; font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn {
                                            label: "Buscar teléfonos en red"
                                            accent: true
                                            onClicked: {
                                                var r = bridge.phoneKdeAction("refresh", "");
                                                root.refreshLiveState(false);
                                                root.showToast(r.replace(/^(ok|error):/, ""));
                                            }
                                        }
                                        FluentBtn {
                                            label: "Abrir app KDE Connect"
                                            onClicked: bridge.launchRealApp("kdeconnect-app || kdeconnect-settings")
                                        }
                                        FluentBtn {
                                            label: "Verificar puertos firewall (1714–1764)"
                                            onClicked: {
                                                var rf = bridge.openKdeConnectFirewall();
                                                root.showToast(rf.replace(/^(ok|error):/, ""));
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty hint if no KDE Connect devices visible yet
                            Rectangle {
                                visible: mobSubCol.kdeList.length === 0
                                width: parent.width; implicitHeight: 74; radius: 7; color: "#242424"; border.color: "#18ffffff"
                                Text {
                                    anchors.centerIn: parent; width: parent.width - 40
                                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                                    text: "Instala la app gratuita «KDE Connect» en tu Android o iPhone conectado al mismo Wi-Fi y pulsa «Buscar teléfonos en red» para vincularlo."
                                    color: "#9a9a9a"; font.pixelSize: 12
                                }
                            }

                            // Live KDE Connect Device Cards
                            Repeater {
                                model: mobSubCol.kdeList
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: kdeDevCol.implicitHeight + 30
                                    radius: 7
                                    color: (modelData.paired && modelData.reachable) ? "#223242" : "#262626"
                                    border.color: (modelData.paired && modelData.reachable) ? root.accentColor : "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: kdeDevCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 15; spacing: 10
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 12
                                            WinSvg { width: 20; height: 20; iconFile: "fluent-phone.svg" }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text {
                                                    text: (modelData.paired ? (modelData.reachable ? "Vinculado y conectado" : "Vinculado (fuera de alcance)") : "Disponible para vincular")
                                                          + (Number(modelData.battery) >= 0 ? ("  •  Batería " + modelData.battery + "%" + (modelData.charging ? " (cargando)" : "")) : "")
                                                    color: (modelData.paired && modelData.reachable) ? root.accentColor : "#9a9a9a"; font.pixelSize: 12
                                                }
                                            }
                                            FluentBtn {
                                                visible: !modelData.paired
                                                label: "Vincular"
                                                accent: true
                                                onClicked: {
                                                    var rp = bridge.phoneKdeAction("pair", modelData.id);
                                                    root.showToast(rp.replace(/^(ok|error):/, ""));
                                                }
                                            }
                                            FluentBtn {
                                                visible: Boolean(modelData.paired)
                                                label: "Desvincular"
                                                onClicked: {
                                                    var ru = bridge.phoneKdeAction("unpair", modelData.id);
                                                    root.refreshLiveState(false);
                                                    root.showToast(ru.replace(/^(ok|error):/, ""));
                                                }
                                            }
                                        }
                                        Flow {
                                            visible: Boolean(modelData.paired && modelData.reachable)
                                            Layout.fillWidth: true; spacing: 8
                                            FluentBtn { label: "Enviar archivo"; accent: true; onClicked: { var r = bridge.phoneKdeAction("share-file", modelData.id); if (r !== "cancel") root.showToast(r.replace(/^(ok|error):/, "")); } }
                                            FluentBtn { label: "Enviar portapapeles"; onClicked: { var r = bridge.phoneKdeAction("clipboard", modelData.id); root.showToast(r.replace(/^(ok|error):/, "")); } }
                                            FluentBtn { label: "Hacer sonar"; onClicked: { var r = bridge.phoneKdeAction("ring", modelData.id); root.showToast(r.replace(/^(ok|error):/, "")); } }
                                            FluentBtn { label: "Enviar ping"; onClicked: { var r = bridge.phoneKdeAction("ping", modelData.id); root.showToast(r.replace(/^(ok|error):/, "")); } }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 3: RED E INTERNET (Windows 11 26H2 Hub + 4 Real Subpages)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 12
                        visible: root.settingsPage === "Red e Internet" && root.settingsSubPage === ""

                        // 1. Universal Win11 26H2 Network Hero Banner (Wi-Fi / Ethernet / Offline + Session Data Usage)
                        Rectangle {
                            width: parent.width; implicitHeight: netHeroCol.implicitHeight + 32
                            radius: 8; color: "#252525"; border.color: root.netData.connected ? Qt.alpha(root.accentColor, 0.22) : "#1effffff"; border.width: 1
                            ColumnLayout {
                                id: netHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 16
                                    Rectangle {
                                        Layout.preferredWidth: 52; Layout.preferredHeight: 52; radius: 10
                                        color: root.netData.connected ? Qt.alpha(root.accentColor, 0.13) : "#1affffff"
                                        border.color: root.netData.connected ? Qt.alpha(root.accentColor, 0.33) : "#22ffffff"; border.width: 1
                                        WinSvg {
                                            anchors.centerIn: parent; width: 26; height: 26
                                            iconFile: root.netData.airplaneMode ? "airplane-mode-symbolic.svg"
                                                      : (root.netData.activeType === "ethernet" ? "fluent-ethernet.svg"
                                                         : (root.netData.connected ? "fluent-wifi.svg" : "fluent-wifi-off.svg"))
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            Text {
                                                text: root.netData.connected
                                                      ? (root.netData.activeName || "Conectado")
                                                      : (root.netData.airplaneMode ? "Modo avión activado" : "Sin conexión a Internet")
                                                color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold
                                                Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                            Rectangle {
                                                visible: root.netData.connected
                                                radius: 10; height: 22; implicitWidth: netStPill.implicitWidth + 16
                                                color: Qt.alpha(root.accentColor, 0.13); border.color: Qt.alpha(root.accentColor, 0.33); border.width: 1
                                                Text { id: netStPill; anchors.centerIn: parent; text: "Conectado"; color: root.accentColor; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            }
                                        }
                                        Text {
                                            text: {
                                                if (root.netData.airplaneMode) return "Radios inalámbricas apagadas (Wi-Fi y Bluetooth)";
                                                if (!root.netData.connected) return "Conecta un cable Ethernet o elige una red Wi-Fi disponible";
                                                if (root.netData.activeType === "ethernet") {
                                                    return "Ethernet (" + (root.netData.activeIface || "eth") + ")  •  Red privada cableada";
                                                }
                                                var parts = ["Wi-Fi (" + (root.netData.wifiIface || "wlan0") + ")"];
                                                if (root.netData.wifiBand) parts.push(root.netData.wifiBand);
                                                if (root.netData.wifiRate) parts.push(root.netData.wifiRate);
                                                if (root.netData.wifiSignalDbm) parts.push(root.netData.wifiSignalDbm);
                                                return parts.join("  •  ");
                                            }
                                            color: root.netData.connected ? "#b8dfff" : "#9e9e9e"
                                            font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    // Right-hand Session Data Usage Mini-Card (Authentic Win11 26H2 Hero!)
                                    Rectangle {
                                        visible: !root.narrowBody
                                        Layout.preferredWidth: 196; implicitHeight: 54; radius: 7
                                        color: "#1e1e1e"; border.color: "#1cffffff"; border.width: 1
                                        ColumnLayout {
                                            anchors.fill: parent; anchors.margins: 9; spacing: 2
                                            Text { text: "Uso de datos (sesión)"; color: "#9e9e9e"; font.pixelSize: 10 }
                                            Text {
                                                text: "↓ " + (root.netData.totalRxHuman || "0 B") + "   ↑ " + (root.netData.totalTxHuman || "0 B")
                                                color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.DemiBold
                                                Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.navigateTo("Red e Internet", "Configuración de red avanzada", true)
                                        }
                                    }
                                }

                                // Live Compact Telemetry Strip (IPv4 • Gateway • DNS + DoT • UFW)
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: netMetaFlow.implicitHeight + 16
                                    radius: 6; color: "#1d1d1d"; border.color: "#16ffffff"; border.width: 1
                                    Flow {
                                        id: netMetaFlow; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
                                        spacing: 16
                                        Text { text: "IPv4: " + (root.hwState.localIp || "N/A"); color: "#d8d8d8"; font.pixelSize: 11 }
                                        Text { text: "Puerta: " + (root.extData.netGateway || "—"); color: "#c2c2c2"; font.pixelSize: 11 }
                                        Text { text: "DNS: " + (root.extData.netDns || "—") + (root.netData.dnsDot ? " (DoT)" : ""); color: root.netData.dnsDot ? root.accentColor : "#c2c2c2"; font.pixelSize: 11 }
                                        Text { text: "Firewall UFW: " + (root.netData.ufwActive ? "Activo" : "Inactivo"); color: root.netData.ufwActive ? "#4ade80" : "#fbbf24"; font.pixelSize: 11 }
                                    }
                                }

                                // Live Ping Summary Banner (when tested)
                                Text {
                                    visible: root.netPingSummary !== ""
                                    text: "Latencia medida: " + root.netPingSummary
                                    color: root.accentColor; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                }

                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn {
                                        label: root.netPingRunning ? "Midiendo latencia..." : "Probar latencia"
                                        accent: true; enabled: !root.netPingRunning
                                        onClicked: {
                                            root.netPingRunning = true;
                                            root.netPingSummary = "";
                                            bridge.startNetPingTest();
                                        }
                                    }
                                    FluentBtn {
                                        label: "DNS y Firewall (X64 Hello)"
                                        onClicked: {
                                            bridge.launchRealApp("x64-hello --dns");
                                            root.showToast("Abriendo Red y Seguridad en X64 Hello");
                                        }
                                    }
                                    FluentBtn {
                                        visible: root.netData.connected && root.hwState.localIp && root.hwState.localIp !== "Sin conexión IP"
                                        label: "Copiar IPv4"
                                        onClicked: {
                                            bridge.copyTextToClipboard(root.hwState.localIp);
                                            root.showToast("IPv4 copiada: " + root.hwState.localIp);
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Win11 26H2 Network Directory Cards
                        Text { text: "Conexiones y preferencias"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                        // Wi-Fi Card with inline ON/OFF Switch + Subpage Chevron (Exact Win11 26H2!)
                        Rectangle {
                            width: parent.width; implicitHeight: Math.max(70, wifiHubRow.implicitHeight + 32)
                            radius: 7
                            color: wifiHubHov.containsMouse ? "#2e2e2e" : "#262626"
                            border.color: wifiHubHov.containsMouse ? "#2cffffff" : "#1cffffff"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea {
                                id: wifiHubHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.navigateTo("Red e Internet", "Wi-Fi", true)
                            }
                            RowLayout {
                                id: wifiHubRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                WinSvg { width: 21; height: 21; iconFile: root.hwState.wifiEnabled ? "fluent-wifi.svg" : "fluent-wifi-off.svg" }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    Text { text: "Wi-Fi"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                    Text {
                                        text: !root.netData.hasWifi
                                              ? "No se detectó tarjeta inalámbrica en este equipo"
                                              : (root.netData.wifiConnected
                                                 ? ("Conectado a " + (root.netData.wifiConName || root.hwState.wifiSsid) + (root.netData.wifiBand ? (" • " + root.netData.wifiBand) : ""))
                                                 : (root.hwState.wifiEnabled ? "Activado • Sin red conectada" : "Desactivado"))
                                        color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                }
                                Win11Switch {
                                    visible: root.netData.hasWifi
                                    checked: Boolean(root.hwState.wifiEnabled)
                                    onToggled: (v) => {
                                        var cp = Object.assign({}, root.hwState); cp.wifiEnabled = v; root.hwState = cp;
                                        bridge.setWifiEnabled(v);
                                        root.refreshLiveState(false);
                                        root.showToast(v ? "Wi-Fi activado" : "Wi-Fi desactivado");
                                    }
                                }
                                WinSvg { width: 13; height: 13; iconFile: "fluent-chevron-right.svg"; opacity: 0.75 }
                            }
                        }

                        // Ethernet HubNavCard
                        HubNavCard {
                            iconFile: "fluent-ethernet.svg"
                            title: "Ethernet"
                            subtitle: {
                                var eths = root.netData.ethernetDevices || [];
                                if (eths.length === 0) return "No se detectó puerto Ethernet (RJ45) en este equipo";
                                var e0 = eths[0];
                                return e0.connected
                                       ? (e0.iface + " • " + (e0.speed || "Conectado") + " • IPv4 " + e0.ip4)
                                       : (e0.iface + " (" + e0.driver + ") • " + (e0.stateLabel || "Cable desconectado"));
                            }
                            badge: {
                                var eths = root.netData.ethernetDevices || [];
                                if (eths.length === 0) return "No presente";
                                for (var i = 0; i < eths.length; i++) if (eths[i].connected) return "Conectado";
                                return "Desconectado";
                            }
                            onClicked: root.navigateTo("Red e Internet", "Ethernet", true)
                        }

                        // VPN HubNavCard
                        HubNavCard {
                            iconFile: "fluent-shield.svg"
                            title: "VPN"
                            subtitle: "Importa perfiles OpenVPN (.ovpn) o WireGuard (.conf) y conéctate en un clic"
                            badge: {
                                var vpns = root.netData.vpnProfiles || [];
                                if (vpns.length === 0) return "Sin perfiles";
                                for (var i = 0; i < vpns.length; i++) if (vpns[i].active) return vpns[i].name;
                                return vpns.length + (vpns.length === 1 ? " perfil" : " perfiles");
                            }
                            onClicked: root.navigateTo("Red e Internet", "VPN", true)
                        }

                        // Airplane Mode Inline ToggleCard (Authentic Win11 26H2!)
                        ToggleCard {
                            iconFile: "airplane-mode-symbolic.svg"
                            title: "Modo avión"
                            subtitle: "Detiene todas las comunicaciones inalámbricas (Wi-Fi y Bluetooth) y restaura tu estado al desactivarlo"
                            checked: Boolean(root.netData.airplaneMode)
                            onToggled: (v) => {
                                var cp = Object.assign({}, root.extData);
                                var np = Object.assign({}, root.netData);
                                np.airplaneMode = v;
                                cp.net = np;
                                root.extData = cp;
                                bridge.setAirplaneMode(v);
                                root.refreshLiveState(false);
                                root.showToast(v ? "Modo avión activado" : "Modo avión desactivado");
                            }
                        }

                        // Advanced Network Settings HubNavCard
                        HubNavCard {
                            iconFile: "fluent-settings.svg"
                            title: "Configuración de red avanzada"
                            subtitle: "Ver todos los adaptadores, tráfico de datos de la sesión, pila TCP BBR y herramientas de red"
                            badge: ((root.netData.adapters || []).length) + ((root.netData.adapters || []).length === 1 ? " adaptador" : " adaptadores")
                            onClicked: root.navigateTo("Red e Internet", "Configuración de red avanzada", true)
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 3.1: RED E INTERNET › WI-FI
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Red e Internet" && root.settingsSubPage === "Wi-Fi"

                        ToggleCard {
                            iconFile: root.hwState.wifiEnabled ? "fluent-wifi.svg" : "fluent-wifi-off.svg"
                            title: "Wi-Fi"
                            subtitle: root.netData.hasWifi
                                      ? ("Adaptador inalámbrico " + (root.netData.wifiIface || "wlan0") + (root.netData.wifiMac ? ("  •  MAC " + root.netData.wifiMac) : ""))
                                      : "No hay adaptador Wi-Fi disponible en este equipo"
                            checked: Boolean(root.hwState.wifiEnabled)
                            onToggled: (v) => {
                                if (!root.netData.hasWifi) { root.showToast("No hay adaptador Wi-Fi instalado"); return; }
                                var cp = Object.assign({}, root.hwState); cp.wifiEnabled = v; root.hwState = cp;
                                bridge.setWifiEnabled(v);
                                root.refreshLiveState(false);
                                root.showToast(v ? "Wi-Fi activado" : "Wi-Fi desactivado");
                            }
                        }

                        // Active Wi-Fi Connection Properties Card
                        Rectangle {
                            visible: Boolean(root.netData.wifiConnected)
                            width: parent.width; implicitHeight: wifiActCol.implicitHeight + 28
                            radius: 7; color: "#232d36"; border.color: Qt.alpha(root.accentColor, 0.33); border.width: 1
                            ColumnLayout {
                                id: wifiActCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 22; height: 22; iconFile: "fluent-wifi.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: root.netData.wifiConName || root.hwState.wifiSsid || "Red Wi-Fi"; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text {
                                            text: {
                                                var ps = ["Conectado, seguro"];
                                                if (root.netData.wifiBand) ps.push(root.netData.wifiBand);
                                                if (root.netData.wifiRate) ps.push(root.netData.wifiRate);
                                                if (root.netData.wifiSignalDbm) ps.push(root.netData.wifiSignalDbm);
                                                return ps.join("  •  ");
                                            }
                                            color: root.accentColor; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        label: "Desconectar"
                                        onClicked: {
                                            var s = root.netData.wifiConName || root.hwState.wifiSsid;
                                            if (bridge.disconnectWifi(s)) {
                                                root.refreshLiveState(false);
                                                root.showToast("Desconectado de " + s);
                                            }
                                        }
                                    }
                                    FluentBtn {
                                        visible: root.netData.wifiUuid !== ""
                                        label: "Olvidar"
                                        onClicked: {
                                            root.netConfirmAction = "forget_wifi";
                                            root.netConfirmTarget = root.netData.wifiUuid;
                                            root.netConfirmLabel = root.netData.wifiConName || root.hwState.wifiSsid;
                                        }
                                    }
                                }

                                // 2-column technical specs grid
                                Rectangle {
                                    Layout.fillWidth: true; implicitHeight: wifiSpecGrid.implicitHeight + 16
                                    radius: 6; color: "#1c2329"; border.color: "#18ffffff"; border.width: 1
                                    GridLayout {
                                        id: wifiSpecGrid; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                                        columns: root.narrowBody ? 1 : 2; columnSpacing: 20; rowSpacing: 6
                                        Text { text: "Dirección IPv4:  " + (root.netData.wifiIp4 || root.hwState.localIp || "—"); color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: "Puerta de enlace:  " + (root.netData.wifiGateway || root.extData.netGateway || "—"); color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: "Servidores DNS:  " + (root.netData.wifiDns || root.extData.netDns || "—") + (root.netData.dnsDot ? " (DoT)" : ""); color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: "Dirección física (MAC):  " + (root.netData.wifiMac || "—"); color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { visible: (root.netData.wifiIp6 || "") !== ""; text: "IPv6 de enlace:  " + (root.netData.wifiIp6 || ""); color: "#a8a8a8"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight; Layout.columnSpan: root.narrowBody ? 1 : 2 }
                                    }
                                }

                                // Real NetworkManager Connection Properties (Auto-Connect & Metered)
                                RowLayout {
                                    visible: root.netData.wifiUuid !== ""
                                    Layout.fillWidth: true; spacing: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text { text: "Conectar automáticamente al estar al alcance"; color: "#f0f0f0"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text { text: "Reconecta a esta red Wi-Fi al iniciar sesión"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    Win11Switch {
                                        checked: Boolean(root.netData.wifiAutoconnect)
                                        onToggled: (v) => {
                                            if (bridge.setConnectionProp(root.netData.wifiUuid, "connection.autoconnect", v ? "yes" : "no")) {
                                                root.refreshLiveState(false);
                                                root.showToast(v ? "Conexión automática activada" : "Conexión automática desactivada");
                                            }
                                        }
                                    }
                                }
                                Rectangle { visible: root.netData.wifiUuid !== ""; Layout.fillWidth: true; height: 1; color: "#14ffffff" }
                                RowLayout {
                                    visible: root.netData.wifiUuid !== ""
                                    Layout.fillWidth: true; spacing: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text { text: "Conexión de uso medido"; color: "#f0f0f0"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text { text: "Indica al sistema y apps que limiten descargas en segundo plano (ideal al compartir datos del móvil)"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    Win11Switch {
                                        checked: Boolean(root.netData.wifiMetered)
                                        onToggled: (v) => {
                                            if (bridge.setConnectionProp(root.netData.wifiUuid, "connection.metered", v ? "1" : "2")) {
                                                root.refreshLiveState(false);
                                                root.showToast(v ? "Marcada como uso medido" : "Uso medido desactivado");
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Nearby Wi-Fi Networks Section
                        RowLayout {
                            width: parent.width; spacing: 10
                            Text { text: "Redes disponibles"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold; Layout.fillWidth: true }
                            FluentBtn {
                                visible: root.netData.hasWifi && root.hwState.wifiEnabled
                                label: root.wifiScanning ? "Explorando..." : "Explorar redes"
                                accent: true; enabled: !root.wifiScanning
                                onClicked: {
                                    root.wifiScanning = true;
                                    bridge.startWifiScan();
                                    root.showToast("Buscando redes Wi-Fi cercanas...");
                                }
                            }
                        }

                        Rectangle {
                            visible: !root.hwState.wifiEnabled || (root.hwState.wifiNetworks || []).length === 0
                            width: parent.width; implicitHeight: 62; radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 16
                                text: !root.netData.hasWifi ? "Este equipo no dispone de adaptador Wi-Fi."
                                      : (!root.hwState.wifiEnabled ? "Activa el interruptor de Wi-Fi para ver las redes cercanas."
                                         : "No se detectaron redes cercanas. Pulsa «Explorar redes» para actualizar.")
                                color: "#9e9e9e"; font.pixelSize: 12; wrapMode: Text.WordWrap
                            }
                        }

                        Repeater {
                            model: root.hwState.wifiEnabled ? (root.hwState.wifiNetworks || []) : []
                            delegate: Rectangle {
                                width: parent.width; implicitHeight: wnRow2.implicitHeight + 22
                                radius: 6
                                color: modelData.active ? "#26333f" : "#262626"
                                border.color: modelData.active ? root.accentColor : "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: wnRow2; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 14; spacing: 12
                                    WinSvg { width: 18; height: 18; iconFile: "fluent-wifi.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            Text { text: modelData.ssid || "Red"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: modelData.active ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.maximumWidth: 320 }
                                            Rectangle {
                                                visible: Boolean(modelData.band)
                                                radius: 4; height: 18; implicitWidth: bndTxt.implicitWidth + 10
                                                color: "#1effffff"; border.color: "#22ffffff"; border.width: 1
                                                Text { id: bndTxt; anchors.centerIn: parent; text: modelData.band || ""; color: "#d4d4d4"; font.pixelSize: 10 }
                                            }
                                        }
                                        Text {
                                            text: (modelData.active ? "Conectado, seguro  •  " : "") + "Señal " + (modelData.signal || 0) + "%  •  " + (modelData.security || "WPA2")
                                            color: modelData.active ? root.accentColor : "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                    FluentBtn {
                                        visible: Boolean(modelData.active)
                                        label: "Desconectar"
                                        onClicked: {
                                            if (bridge.disconnectWifi(modelData.ssid)) {
                                                root.refreshLiveState(false);
                                                root.showToast("Desconectado de " + modelData.ssid);
                                            }
                                        }
                                    }
                                    FluentBtn {
                                        visible: !modelData.active
                                        label: "Conectar"; accent: true
                                        onClicked: root.tryConnectWifi(modelData.ssid)
                                    }
                                }
                            }
                        }

                        // Manage Known Wi-Fi Networks (Real Saved NetworkManager Profiles!)
                        Text { text: "Administrar redes conocidas (" + ((root.netData.knownWifi || []).length) + ")"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 6 }

                        Rectangle {
                            width: parent.width; implicitHeight: kwCol.implicitHeight + 24
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: kwCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8
                                Text {
                                    visible: (root.netData.knownWifi || []).length === 0
                                    text: "No hay redes Wi-Fi guardadas todavía."
                                    color: "#9e9e9e"; font.pixelSize: 12
                                }
                                Repeater {
                                    model: root.netData.knownWifi || []
                                    delegate: ColumnLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Rectangle { visible: index > 0; Layout.fillWidth: true; height: 1; color: "#14ffffff" }
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 10
                                            WinSvg { width: 17; height: 17; iconFile: "fluent-wifi.svg"; opacity: modelData.active ? 1.0 : 0.7 }
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 1
                                                Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 12; font.weight: modelData.active ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
                                                Text { text: (modelData.active ? "Conectada ahora  •  " : "") + (modelData.autoconnect ? "Auto-conexión activa" : "Conexión manual"); color: modelData.active ? root.accentColor : "#9a9a9a"; font.pixelSize: 11 }
                                            }
                                            FluentBtn {
                                                label: modelData.autoconnect ? "Auto: Sí" : "Auto: No"
                                                onClicked: {
                                                    var nv = !modelData.autoconnect;
                                                    if (bridge.setConnectionProp(modelData.uuid, "connection.autoconnect", nv ? "yes" : "no")) {
                                                        root.refreshLiveState(false);
                                                        root.showToast(modelData.name + (nv ? ": auto-conexión activada" : ": auto-conexión desactivada"));
                                                    }
                                                }
                                            }
                                            FluentBtn {
                                                label: "Olvidar"
                                                onClicked: {
                                                    root.netConfirmAction = "forget_wifi";
                                                    root.netConfirmTarget = modelData.uuid;
                                                    root.netConfirmLabel = modelData.name;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 3.2: RED E INTERNET › ETHERNET
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Red e Internet" && root.settingsSubPage === "Ethernet"

                        Rectangle {
                            visible: (root.netData.ethernetDevices || []).length === 0
                            width: parent.width; implicitHeight: 88; radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 18; spacing: 14
                                WinSvg { width: 24; height: 24; iconFile: "fluent-ethernet.svg"; opacity: 0.7 }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    Text { text: "No se detectó adaptador Ethernet"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                    Text { text: "Si conectas un adaptador USB-C / USB a RJ45 aparecerá automáticamente aquí."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                            }
                        }

                        Repeater {
                            model: root.netData.ethernetDevices || []
                            delegate: Rectangle {
                                width: parent.width; implicitHeight: ethCardCol.implicitHeight + 30
                                radius: 7; color: modelData.connected ? "#232d36" : "#262626"
                                border.color: modelData.connected ? Qt.alpha(root.accentColor, 0.33) : "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: ethCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 24; height: 24; iconFile: "fluent-ethernet.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: modelData.connName + "  (" + modelData.iface + ")"; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text {
                                                text: (modelData.stateLabel || "Desconectado") + "  •  Controlador " + modelData.driver + (modelData.connected && modelData.speed !== "—" ? ("  •  " + modelData.speed) : "")
                                                color: modelData.connected ? root.accentColor : "#9e9e9e"; font.pixelSize: 12
                                            }
                                        }
                                        FluentBtn {
                                            label: modelData.connected ? "Desconectar" : "Conectar"
                                            accent: !modelData.connected && modelData.carrier
                                            enabled: modelData.connected || modelData.carrier
                                            onClicked: {
                                                var r = bridge.setAdapterConnected(modelData.iface, !modelData.connected);
                                                root.refreshLiveState(false);
                                                root.showToast(r === "ok"
                                                    ? (modelData.connected ? ("Ethernet " + modelData.iface + " desconectado") : ("Ethernet " + modelData.iface + " conectado"))
                                                    : r.replace(/^error:/, ""));
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true; implicitHeight: ethSpecs.implicitHeight + 16
                                        radius: 6; color: "#1d1d1d"; border.color: "#16ffffff"; border.width: 1
                                        GridLayout {
                                            id: ethSpecs; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10
                                            columns: root.narrowBody ? 1 : 2; columnSpacing: 20; rowSpacing: 6
                                            Text { text: "Dirección IPv4:  " + modelData.ip4; color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: "Puerta de enlace:  " + modelData.gateway; color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: "Servidores DNS:  " + modelData.dns; color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: "Dirección MAC:  " + modelData.mac; color: "#dcdcdc"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: "Velocidad / MTU:  " + modelData.speed + "  •  MTU " + modelData.mtu; color: "#b4b4b4"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: "Tráfico sesión:  ↓ " + modelData.rxHuman + "  •  ↑ " + modelData.txHuman; color: "#b4b4b4"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }
                                    }

                                    RowLayout {
                                        visible: (modelData.connUuid || "") !== ""
                                        Layout.fillWidth: true; spacing: 12
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: "Conectar automáticamente al enchufar el cable"; color: "#f0f0f0"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                            Text { text: "Activa el enlace Ethernet automáticamente en cuanto detecta señal"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Win11Switch {
                                            checked: Boolean(modelData.autoconnect)
                                            onToggled: (v) => {
                                                if (bridge.setConnectionProp(modelData.connUuid, "connection.autoconnect", v ? "yes" : "no")) {
                                                    root.refreshLiveState(false);
                                                    root.showToast(v ? "Auto-conexión Ethernet activada" : "Auto-conexión Ethernet desactivada");
                                                }
                                            }
                                        }
                                    }
                                    Rectangle { visible: (modelData.connUuid || "") !== ""; Layout.fillWidth: true; height: 1; color: "#14ffffff" }
                                    RowLayout {
                                        visible: (modelData.connUuid || "") !== ""
                                        Layout.fillWidth: true; spacing: 12
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: "Conexión de uso medido"; color: "#f0f0f0"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                            Text { text: "Establece límites de datos si esta conexión tiene tarifa restringida"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Win11Switch {
                                            checked: Boolean(modelData.metered)
                                            onToggled: (v) => {
                                                if (bridge.setConnectionProp(modelData.connUuid, "connection.metered", v ? "1" : "2")) {
                                                    root.refreshLiveState(false);
                                                    root.showToast(v ? "Ethernet marcado como uso medido" : "Uso medido desactivado");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 3.3: RED E INTERNET › VPN
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Red e Internet" && root.settingsSubPage === "VPN"

                        Rectangle {
                            width: parent.width; implicitHeight: vpnHdrCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: vpnHdrCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 22; height: 22; iconFile: "fluent-shield.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Conexiones VPN"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                        Text { text: "Importa directamente archivos .ovpn (OpenVPN) o .conf (WireGuard) en NetworkManager sin consola"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn {
                                        label: "+ Importar perfil VPN (.ovpn / .conf)"
                                        accent: true
                                        onClicked: {
                                            var r = bridge.importVpnFile();
                                            if (r === "cancel") return;
                                            if (r.indexOf("ok:") === 0) {
                                                root.refreshLiveState(false);
                                                root.showToast("Perfil VPN importado: " + r.slice(3));
                                            } else {
                                                root.showToast(r.replace(/^error:/, "") || "No se pudo importar el perfil VPN");
                                            }
                                        }
                                    }
                                    FluentBtn {
                                        visible: Boolean(root.extData.tools && root.extData.tools.hasNmEditor)
                                        label: "Configurar VPN manual (Editor de red)"
                                        onClicked: bridge.launchRealApp("nm-connection-editor")
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: (root.netData.vpnProfiles || []).length === 0
                            width: parent.width; implicitHeight: 74; radius: 7; color: "#242424"; border.color: "#18ffffff"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 12
                                WinSvg { width: 20; height: 20; iconFile: "fluent-lock.svg"; opacity: 0.65 }
                                Text {
                                    text: "No tienes perfiles VPN guardados todavía. Pulsa «+ Importar perfil VPN» para cargar tu configuración de ProtonVPN, Mullvad, NordVPN, WireGuard o VPN corporativa."
                                    color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Repeater {
                            model: root.netData.vpnProfiles || []
                            delegate: Rectangle {
                                width: parent.width; implicitHeight: vpnItemRow.implicitHeight + 24
                                radius: 7; color: modelData.active ? "#232d36" : "#262626"
                                border.color: modelData.active ? root.accentColor : "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: vpnItemRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 14; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-shield.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        RowLayout {
                                            spacing: 8
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                            Rectangle {
                                                radius: 4; height: 18; implicitWidth: vtLbl.implicitWidth + 10
                                                color: "#1effffff"; border.color: "#22ffffff"; border.width: 1
                                                Text { id: vtLbl; anchors.centerIn: parent; text: modelData.vpnType; color: "#d4d4d4"; font.pixelSize: 10 }
                                            }
                                        }
                                        Text {
                                            text: modelData.active ? ("Conectada" + (modelData.device ? (" • " + modelData.device) : "")) : "Desconectada"
                                            color: modelData.active ? root.accentColor : "#9e9e9e"; font.pixelSize: 11
                                        }
                                    }
                                    FluentBtn {
                                        label: modelData.active ? "Desconectar" : "Conectar"
                                        accent: !modelData.active
                                        onClicked: {
                                            var r = bridge.toggleVpnProfile(modelData.uuid, !modelData.active);
                                            root.refreshLiveState(false);
                                            root.showToast(r === "ok"
                                                ? (modelData.active ? ("VPN desconectada: " + modelData.name) : ("VPN conectada: " + modelData.name))
                                                : r.replace(/^error:/, ""));
                                        }
                                    }
                                    FluentBtn {
                                        label: "Eliminar"
                                        onClicked: {
                                            root.netConfirmAction = "delete_vpn";
                                            root.netConfirmTarget = modelData.uuid;
                                            root.netConfirmLabel = modelData.name;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 3.4: RED E INTERNET › CONFIGURACIÓN DE RED AVANZADA
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Red e Internet" && root.settingsSubPage === "Configuración de red avanzada"

                        Text { text: "Adaptadores de red (" + ((root.netData.adapters || []).length) + ")"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold }

                        Repeater {
                            model: root.netData.adapters || []
                            delegate: Rectangle {
                                width: parent.width; implicitHeight: adpCol.implicitHeight + 24
                                radius: 7; color: "#262626"; border.color: modelData.connected ? Qt.alpha(root.accentColor, 0.25) : "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: adpCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 20; height: 20; iconFile: modelData.type === "ethernet" ? "fluent-ethernet.svg" : "fluent-wifi.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            RowLayout {
                                                spacing: 8
                                                Text { text: modelData.typeLabel + "  —  " + modelData.iface; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                                Rectangle {
                                                    radius: 4; height: 18; implicitWidth: adpSt.implicitWidth + 10
                                                    color: modelData.connected ? Qt.alpha(root.accentColor, 0.13) : "#18ffffff"
                                                    Text { id: adpSt; anchors.centerIn: parent; text: modelData.stateLabel; color: modelData.connected ? root.accentColor : "#b0b0b0"; font.pixelSize: 10 }
                                                }
                                            }
                                            Text {
                                                text: "Driver " + modelData.driver + "  •  MAC " + modelData.mac + "  •  MTU " + modelData.mtu + (modelData.ip4 !== "—" ? ("  •  IPv4 " + modelData.ip4) : "")
                                                color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                            Text {
                                                text: "Tráfico de la sesión:  ↓ " + modelData.rxHuman + " descargado   •   ↑ " + modelData.txHuman + " enviado" + (modelData.speed !== "—" ? ("   •   Enlace " + modelData.speed) : "")
                                                color: "#c4c4c4"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                        FluentBtn {
                                            label: modelData.connected ? "Deshabilitar" : "Conectar"
                                            enabled: modelData.connected || modelData.state === "disconnected"
                                            onClicked: {
                                                var r = bridge.setAdapterConnected(modelData.iface, !modelData.connected);
                                                root.refreshLiveState(false);
                                                root.showToast(r === "ok"
                                                    ? (modelData.connected ? (modelData.iface + " desconectado") : (modelData.iface + " conectado"))
                                                    : r.replace(/^error:/, ""));
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // X64 LIOS Security, DNS & Kernel Stack Card (Zero duplication with X64 Hello!)
                        Text { text: "Seguridad, DNS y pila de red X64 LIOS"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 6 }

                        Rectangle {
                            width: parent.width; implicitHeight: stackAdvCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: stackAdvCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                GridLayout {
                                    Layout.fillWidth: true; columns: root.narrowBody ? 1 : 2; columnSpacing: 16; rowSpacing: 8
                                    Text { text: "DNS activo:  " + (root.extData.netDns || "—") + (root.netData.dnsDot ? "  (DoT cifrado)" : ""); color: "#e0e0e0"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: "Cortafuegos UFW:  " + (root.netData.ufwActive ? "Activo (entrantes bloqueadas)" : "Inactivo"); color: root.netData.ufwActive ? "#4ade80" : "#fbbf24"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: "Control de congestión:  TCP " + String(root.netData.tcpCongestion || "—").toUpperCase() + "  •  Cola " + (root.netData.qdisc || "—"); color: "#c8c8c8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: "Wi-Fi baja latencia:  " + (root.netData.wifiPowerSaveOff ? "PowerSave desactivado (sin jitter)" : "Estándar"); color: "#c8c8c8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn {
                                        label: "Abrir Red y Seguridad (X64 Hello)"
                                        accent: true
                                        onClicked: {
                                            bridge.launchRealApp("x64-hello --dns");
                                            root.showToast("Abriendo Optimizador DNS y Firewall en X64 Hello");
                                        }
                                    }
                                    FluentBtn {
                                        label: (root.extData.tools && root.extData.tools.hasNmEditor) ? "Editor de conexiones (IP estática / Proxy)" : "Instalar editor de red"
                                        onClicked: {
                                            if (root.extData.tools && root.extData.tools.hasNmEditor) {
                                                bridge.launchRealApp("nm-connection-editor");
                                            } else {
                                                bridge.launchRealApp("/usr/bin/shelly-ui");
                                                root.showToast("Busca 'nm-connection-editor' en Tienda Shelly");
                                            }
                                        }
                                    }
                                    FluentBtn {
                                        label: "Reiniciar pila de red"
                                        onClicked: {
                                            root.netConfirmAction = "restart_nm";
                                            root.netConfirmTarget = "";
                                            root.netConfirmLabel = "NetworkManager";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 4: PERSONALIZACIÓN (Windows 11 26H2 Visual Hub + 6 Real Subpages)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 12
                        visible: root.settingsPage === "Personalización" && root.settingsSubPage === ""

                        // 1. Authentic Win11 26H2 Live Desktop Preview + 1-Click Theme Strip
                        Rectangle {
                            width: parent.width; implicitHeight: persHeroRow.implicitHeight + 32
                            radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1

                            GridLayout {
                                id: persHeroRow
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16
                                columns: root.narrowBody ? 1 : 2; columnSpacing: 20; rowSpacing: 14

                                // Live 16:9 Mini-Desktop Preview (reflects wallpaper/solid color, accent color, taskbar align & compact!)
                                Rectangle {
                                    Layout.preferredWidth: root.narrowBody ? Math.min(340, parent.width) : 336
                                    Layout.preferredHeight: 190
                                    radius: 8; clip: true
                                    color: root.cfg.wallpaperMode === 4 ? (root.cfg.solidBgColor || "#141923") : "#0e131c"
                                    border.color: "#36ffffff"; border.width: 1

                                    Image {
                                        anchors.fill: parent
                                        visible: root.cfg.wallpaperMode !== 4
                                        cache: false
                                        source: root.activeWallpaperSrc
                                        fillMode: root.cfg.wallpaperFit === "fit" ? Image.PreserveAspectFit
                                                  : (root.cfg.wallpaperFit === "stretch" ? Image.Stretch
                                                     : (root.cfg.wallpaperFit === "center" ? Image.Pad : Image.PreserveAspectCrop))
                                    }

                                    // Mini Win11 Dark Window Preview reflecting active Accent Color
                                    Rectangle {
                                        x: 118; y: 26; width: 174; height: 114; radius: 6
                                        color: "#eb202020"; border.color: "#34ffffff"; border.width: 1
                                        Row {
                                            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 7; spacing: 5
                                            Rectangle { width: 6; height: 6; radius: 3; color: "#55ffffff" }
                                            Rectangle { width: 6; height: 6; radius: 3; color: "#55ffffff" }
                                            Rectangle { width: 6; height: 6; radius: 3; color: "#c42b1c" }
                                        }
                                        Column {
                                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                            anchors.topMargin: 24; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 7
                                            Rectangle { width: 66; height: 7; radius: 3; color: "#e8e8e8" }
                                            Rectangle { width: 126; height: 5; radius: 2; color: "#55ffffff" }
                                            Rectangle { width: 98; height: 5; radius: 2; color: "#40ffffff" }
                                            Row {
                                                spacing: 8; topPadding: 6
                                                Rectangle { width: 54; height: 18; radius: 4; color: root.accentColor }
                                                Rectangle { width: 42; height: 18; radius: 4; color: "#363636"; border.color: "#22ffffff" }
                                            }
                                        }
                                    }

                                    // Mini Desktop Icons (when showDesktopIcons is ON)
                                    Column {
                                        visible: Boolean(root.cfg.showDesktopIcons)
                                        x: 12; y: 14; spacing: 8
                                        Repeater {
                                            model: 3
                                            delegate: Column {
                                                spacing: 2
                                                Rectangle { width: 14; height: 14; radius: 3; color: "#88ffffff"; anchors.horizontalCenter: parent.horizontalCenter }
                                                Rectangle { width: 20; height: 3; radius: 1.5; color: "#70ffffff" }
                                            }
                                        }
                                    }

                                    // Mini Taskbar reflecting Alignment (center/left), Compact & Transparency
                                    Rectangle {
                                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                        height: root.cfg.taskbarCompact ? 16 : 21
                                        color: (root.cfg.transparencyEnabled === false) ? "#ff1c1c1c" : "#dd1c1c1c"
                                        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: "#28ffffff" }
                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: root.cfg.taskbarLeftAlign ? 8 : Math.round((parent.width - width) / 2)
                                            spacing: 5
                                            Rectangle { width: 9; height: 9; radius: 2; color: root.accentColor }
                                            Rectangle { visible: (root.cfg.taskbarSearchMode || "box") === "box"; width: 32; height: 9; radius: 4.5; color: "#44ffffff" }
                                            Rectangle { visible: (root.cfg.taskbarSearchMode || "box") === "icon"; width: 9; height: 9; radius: 4.5; color: "#55ffffff" }
                                            Rectangle { width: 9; height: 9; radius: 2; color: "#66ffffff" }
                                            Rectangle { width: 9; height: 9; radius: 2; color: "#66ffffff" }
                                            Rectangle { width: 9; height: 9; radius: 2; color: "#66ffffff" }
                                        }
                                    }
                                }

                                // Right Column: Quick 1-Click Themes (Windows 11 26H2!)
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; spacing: 10
                                    Text { text: "Seleccionar un tema para aplicar"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                    Text { text: "Combina al instante fondo de escritorio y color de énfasis en toda la sesión"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }

                                    GridLayout {
                                        Layout.fillWidth: true; columns: 2; columnSpacing: 10; rowSpacing: 10
                                        Repeater {
                                            model: [
                                                { label: "Windows Oscuro",   wp: 0, acc: "#4cc2ff", src: wpDirUrl + "win11-bloom-dark.jpg" },
                                                { label: "Bloom Luminoso",   wp: 1, acc: "#60a5fa", src: wpDirUrl + "win11-bloom-light.jpg" },
                                                { label: "X64 Carmesí",      wp: 2, acc: "#ff6b6b", src: wpDirUrl + "x64-monolith.jpg" },
                                                { label: "Esmeralda Fluido", wp: 0, acc: "#34d399", src: wpDirUrl + "win11-bloom-dark.jpg" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isSel: Number(root.cfg.wallpaperMode) === modelData.wp && root.accentColor.toLowerCase() === modelData.acc.toLowerCase()
                                                Layout.fillWidth: true; height: 64; radius: 7; clip: true
                                                color: "#1e1e1e"
                                                border.color: isSel ? root.accentColor : (thHov.containsMouse ? "#44ffffff" : "#22ffffff")
                                                border.width: isSel ? 2 : 1
                                                Image { anchors.fill: parent; anchors.margins: isSel ? 2 : 1; source: modelData.src; fillMode: Image.PreserveAspectCrop; opacity: 0.72 }
                                                Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0.0; color: "#22000000" } GradientStop { position: 1.0; color: "#c8121212" } } }
                                                RowLayout {
                                                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; spacing: 7
                                                    Rectangle { width: 12; height: 12; radius: 6; color: modelData.acc; border.color: "#66ffffff"; border.width: 1 }
                                                    Text { text: modelData.label; color: "#ffffff"; font.pixelSize: 11; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                                }
                                                MouseArea {
                                                    id: thHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.updateCfg("wallpaperMode", modelData.wp);
                                                        root.updateCfg("accentColor", modelData.acc);
                                                        bridge.applyAppearanceSetting(JSON.stringify({ accentColor: modelData.acc }));
                                                        root.showToast("Tema aplicado: " + modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Authentic Win11 26H2 Personalization Subpage Directory (6 HubNavCards!)
                        Text { text: "Ajustes de personalización"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                        HubNavCard {
                            iconFile: "fluent-image.svg"
                            title: "Fondo"
                            subtitle: "Imagen 4K de escritorio, foto propia, color sólido y modo de ajuste"
                            badge: root.cfg.wallpaperMode === 4 ? "Color sólido"
                                   : (root.cfg.wallpaperMode === 3 ? "Foto propia"
                                      : (root.cfg.wallpaperMode === 2 ? "X64 Monolith"
                                         : (root.cfg.wallpaperMode === 1 ? "Bloom Claro" : "Bloom Oscuro")))
                            onClicked: root.navigateTo("Personalización", "Fondo", true)
                        }

                        HubNavCard {
                            iconFile: "fluent-paint-brush.svg"
                            title: "Colores"
                            subtitle: "Color de énfasis en vivo, efectos de transparencia Acrylic y modo Oscuro/Claro de apps"
                            badge: (root.appearanceData.gtkDark ? "Oscuro" : "Claro") + " • " + (root.cfg.transparencyEnabled === false ? "Opaco" : "Acrylic")
                            onClicked: root.navigateTo("Personalización", "Colores", true)
                        }

                        HubNavCard {
                            iconFile: "fluent-window-apps.svg"
                            title: "Barra de tareas"
                            subtitle: "Elementos visibles (Buscar, Vista de tareas, Clima), alineación y altura compacta"
                            badge: (root.cfg.taskbarLeftAlign ? "Izquierda" : "Centrada") + (root.cfg.taskbarCompact ? " • 38 px" : " • 48 px")
                            onClicked: root.navigateTo("Personalización", "Barra de tareas", true)
                        }

                        HubNavCard {
                            iconFile: "fluent-grid.svg"
                            title: "Inicio"
                            subtitle: "Diseño de Todas las aplicaciones (Categoría, Cuadrícula o Lista), Recomendado y Enlace Móvil"
                            badge: (root.cfg.startAllViewMode === "grid") ? "Cuadrícula" : ((root.cfg.startAllViewMode === "list") ? "Lista" : "Categoría")
                            onClicked: root.navigateTo("Personalización", "Inicio", true)
                        }

                        HubNavCard {
                            iconFile: "fluent-lock.svg"
                            title: "Pantalla de bloqueo"
                            subtitle: "Imagen de bloqueo independiente o sincronizada, estado rápido y vista previa Win + L"
                            badge: (Number(root.cfg.lockWallpaperMode) === -1 || root.cfg.lockWallpaperMode === undefined) ? "Igual al escritorio" : "Personalizada"
                            onClicked: root.navigateTo("Personalización", "Pantalla de bloqueo", true)
                        }

                        HubNavCard {
                            iconFile: "fluent-folder-grid.svg"
                            title: "Escritorio y puntero"
                            subtitle: "Visibilidad, tamaño y orden automático de iconos del escritorio + tema y tamaño del cursor"
                            badge: (root.appearanceData.cursorTheme || "breeze_cursors") + " • " + (root.appearanceData.cursorSize || 24) + " px"
                            onClicked: root.navigateTo("Personalización", "Escritorio y puntero", true)
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 4.1: PERSONALIZACIÓN › FONDO
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Personalización" && root.settingsSubPage === "Fondo"

                        // Live Wallpaper Preview Banner
                        Rectangle {
                            width: parent.width; implicitHeight: bgPrevRow.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            RowLayout {
                                id: bgPrevRow; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 18
                                Rectangle {
                                    Layout.preferredWidth: 230; Layout.preferredHeight: 130; radius: 7; clip: true
                                    color: root.cfg.wallpaperMode === 4 ? (root.cfg.solidBgColor || "#141923") : "#0e131c"
                                    border.color: "#34ffffff"; border.width: 1
                                    Image {
                                        anchors.fill: parent; visible: root.cfg.wallpaperMode !== 4; cache: false
                                        source: root.activeWallpaperSrc
                                        fillMode: root.cfg.wallpaperFit === "fit" ? Image.PreserveAspectFit
                                                  : (root.cfg.wallpaperFit === "stretch" ? Image.Stretch
                                                     : (root.cfg.wallpaperFit === "center" ? Image.Pad : Image.PreserveAspectCrop))
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    Text { text: "Personalizar el fondo"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Text { text: "Cambia entre fondos 4K integrados, cualquier imagen local o un color sólido minimalista con efecto inmediato."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn {
                                            label: "Examinar foto..."
                                            accent: true
                                            onClicked: {
                                                var u = bridge.pickAndSetWallpaper();
                                                if (u !== "") {
                                                    root.updateCfg("customWallpaperUrl", u);
                                                    root.updateCfg("wallpaperMode", 3);
                                                    root.showToast("Fondo personalizado aplicado");
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            label: root.cfg.wallpaperMode === 4 ? "Usar imagen" : "Usar color sólido"
                                            onClicked: {
                                                if (root.cfg.wallpaperMode === 4) {
                                                    root.updateCfg("wallpaperMode", 0);
                                                    root.showToast("Modo imagen activado");
                                                } else {
                                                    root.updateCfg("wallpaperMode", 4);
                                                    root.showToast("Fondo de color sólido activado");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Built-in 4K + Custom Wallpapers Gallery
                        Rectangle {
                            width: parent.width; implicitHeight: wpGalCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: wpGalCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                Text { text: "Imágenes recientes e integradas"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Flow {
                                    Layout.fillWidth: true; spacing: 12
                                    Repeater {
                                        model: [
                                            { mode: 0, label: "Bloom Oscuro", src: wpDirUrl + "win11-bloom-dark.jpg" },
                                            { mode: 1, label: "Bloom Claro",  src: wpDirUrl + "win11-bloom-light.jpg" },
                                            { mode: 2, label: "X64 Monolith", src: wpDirUrl + "x64-monolith.jpg" }
                                        ]
                                        delegate: Column {
                                            spacing: 5
                                            Rectangle {
                                                width: 160; height: 92; radius: 6; clip: true
                                                border.color: root.cfg.wallpaperMode === modelData.mode ? root.accentColor : "#33ffffff"
                                                border.width: root.cfg.wallpaperMode === modelData.mode ? 2 : 1
                                                Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: modelData.src; fillMode: Image.PreserveAspectCrop }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.updateCfg("wallpaperMode", modelData.mode); root.showToast("Fondo aplicado: " + modelData.label); } }
                                            }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: root.cfg.wallpaperMode === modelData.mode ? root.accentColor : "#b8b8b8"; font.pixelSize: 11 }
                                        }
                                    }
                                    Column {
                                        visible: (root.cfg.customWallpaperUrl || "") !== ""
                                        spacing: 5
                                        Rectangle {
                                            width: 160; height: 92; radius: 6; clip: true
                                            border.color: root.cfg.wallpaperMode === 3 ? root.accentColor : "#33ffffff"
                                            border.width: root.cfg.wallpaperMode === 3 ? 2 : 1
                                            Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: root.cfg.customWallpaperUrl || ""; fillMode: Image.PreserveAspectCrop }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.updateCfg("wallpaperMode", 3); root.showToast("Foto propia aplicada"); } }
                                        }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Foto propia"; color: root.cfg.wallpaperMode === 3 ? root.accentColor : "#b8b8b8"; font.pixelSize: 11 }
                                    }
                                }
                            }
                        }

                        // Image Fit Mode Selector (Rellenar / Ajustar / Estirar / Centrar)
                        Rectangle {
                            visible: root.cfg.wallpaperMode !== 4
                            width: parent.width; implicitHeight: wpFitRow.implicitHeight + 24
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            RowLayout {
                                id: wpFitRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16; spacing: 12
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Elegir un ajuste para la imagen de escritorio"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                    Text { text: "Controla cómo se escala el fondo respecto a la relación de aspecto de tu monitor"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: [{ id: "fill", l: "Rellenar" }, { id: "fit", l: "Ajustar" }, { id: "stretch", l: "Estirar" }, { id: "center", l: "Centrar" }]
                                        delegate: Rectangle {
                                            readonly property bool isCur: (root.cfg.wallpaperFit || "fill") === modelData.id
                                            width: 74; height: 32; radius: 5
                                            color: isCur ? root.accentColor : (wfH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"
                                            Text { anchors.centerIn: parent; text: modelData.l; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea { id: wfH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.updateCfg("wallpaperFit", modelData.id); root.showToast("Ajuste de fondo: " + modelData.l); } }
                                        }
                                    }
                                }
                            }
                        }

                        // Solid Background Color Palette (8 Fluent Dark Surfaces)
                        Rectangle {
                            width: parent.width; implicitHeight: solCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: solCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                Text { text: "Color sólido de fondo"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { text: "Haz clic en cualquier tono para usar un escritorio limpio sin imagen (0 % VRAM extra)"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Flow {
                                    Layout.fillWidth: true; spacing: 10
                                    Repeater {
                                        model: [
                                            { hex: "#0f141e", name: "Obsidiana Azul" },
                                            { hex: "#141923", name: "Pizarra Oscura" },
                                            { hex: "#111111", name: "Negro OLED" },
                                            { hex: "#1b1426", name: "Índigo Profundo" },
                                            { hex: "#211216", name: "Burdeos X64" },
                                            { hex: "#0f201d", name: "Bosque Nocturno" },
                                            { hex: "#1c2430", name: "Acero Nórdico" },
                                            { hex: "#241d15", name: "Bronce Oscuro" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: root.cfg.wallpaperMode === 4 && (root.cfg.solidBgColor || "").toLowerCase() === modelData.hex
                                            width: 44; height: 44; radius: 7; color: modelData.hex
                                            border.color: isCur ? root.accentColor : "#44ffffff"; border.width: isCur ? 2 : 1
                                            WinSvg { visible: parent.isCur; anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-checkmark.svg" }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.updateCfg("solidBgColor", modelData.hex);
                                                    root.updateCfg("wallpaperMode", 4);
                                                    root.showToast("Color sólido: " + modelData.name);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 4.2: PERSONALIZACIÓN › COLORES
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Personalización" && root.settingsSubPage === "Colores"

                        // Accent Color Picker (8 Fluent Luminous Accents — live across shell + Settings + GTK!)
                        Rectangle {
                            width: parent.width; implicitHeight: accCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: accCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-paint-brush.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Color de énfasis"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                        Text { text: "Se aplica al instante a los botones, interruptores, barra de tareas, Centro de control y aplicaciones GTK"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 10
                                    Repeater {
                                        model: [
                                            { hex: "#4cc2ff", name: "Azul Windows" },
                                            { hex: "#60a5fa", name: "Cobalto" },
                                            { hex: "#a78bfa", name: "Violeta" },
                                            { hex: "#ff6b6b", name: "Carmesí X64" },
                                            { hex: "#34d399", name: "Esmeralda" },
                                            { hex: "#fbbf24", name: "Ámbar" },
                                            { hex: "#2dd4bf", name: "Turquesa" },
                                            { hex: "#f472b6", name: "Rosa" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: root.accentColor.toLowerCase() === modelData.hex
                                            width: Math.max(122, acLbl.implicitWidth + 46); height: 42; radius: 6
                                            color: isCur ? "#343434" : (acH.containsMouse ? "#303030" : "#1f1f1f")
                                            border.color: isCur ? modelData.hex : "#22ffffff"; border.width: isCur ? 2 : 1
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                                Rectangle { width: 16; height: 16; radius: 8; color: modelData.hex; border.color: "#55ffffff"; border.width: 1 }
                                                Text { id: acLbl; text: modelData.name; color: "#f2f2f2"; font.pixelSize: 11; font.weight: parent.parent.isCur ? Font.DemiBold : Font.Normal }
                                            }
                                            MouseArea {
                                                id: acH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.updateCfg("accentColor", modelData.hex);
                                                    bridge.applyAppearanceSetting(JSON.stringify({ accentColor: modelData.hex }));
                                                    root.showToast("Color de énfasis: " + modelData.name);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Show Accent Color on Active Window Borders & Alt+Tab OSD (Real labwc themerc-override!)
                        ToggleCard {
                            iconFile: "fluent-window-apps.svg"
                            title: "Mostrar color de énfasis en bordes de ventana y Alt+Tab"
                            subtitle: "Aplica el color de énfasis al borde que envuelve la ventana activa y al selector Alt+Tab de labwc"
                            checked: root.cfg.accentOnBorders !== false
                            onToggled: (v) => {
                                root.updateCfg("accentOnBorders", v);
                                bridge.applyAppearanceSetting(JSON.stringify({ accentColor: root.accentColor, accentOnBorders: v }));
                                root.showToast(v ? "Color de énfasis activado en bordes de ventana" : "Bordes de ventana en tono neutro");
                            }
                        }

                        // Transparency Effects (Acrylic vs Opaque)
                        ToggleCard {
                            iconFile: "fluent-sparkle.svg"
                            title: "Efectos de transparencia (Acrylic)"
                            subtitle: "Aplica translucidez oscura en la barra de tareas y superficies del shell; desactívalo para aspecto sólido de máximo contraste"
                            checked: root.cfg.transparencyEnabled !== false
                            onToggled: (v) => {
                                root.updateCfg("transparencyEnabled", v);
                                root.showToast(v ? "Transparencia Acrylic activada" : "Modo sólido opaco activado");
                            }
                        }

                        // GTK3/GTK4 System & Apps Color Scheme (Dark vs Light)
                        Rectangle {
                            width: parent.width; implicitHeight: gtkModRow.implicitHeight + 24
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            RowLayout {
                                id: gtkModRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16; spacing: 12
                                WinSvg { width: 20; height: 20; iconFile: "fluent-display.svg" }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Modo de color para aplicaciones (GTK3 / GTK4)"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                    Text { text: "Sincroniza automáticamente gsettings, GTK y navegadores con tema Oscuro (adw-gtk3-dark) o Claro (adw-gtk3)"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: [{ dark: true, l: "Oscuro" }, { dark: false, l: "Claro" }]
                                        delegate: Rectangle {
                                            readonly property bool isCur: Boolean(root.appearanceData.gtkDark) === modelData.dark
                                            width: 82; height: 32; radius: 5
                                            color: isCur ? root.accentColor : (gmH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"
                                            Text { anchors.centerIn: parent; text: modelData.l; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea {
                                                id: gmH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var ec = Object.assign({}, root.extData);
                                                    var ap = Object.assign({}, root.appearanceData);
                                                    ap.gtkDark = modelData.dark;
                                                    ec.appearance = ap;
                                                    root.extData = ec;
                                                    bridge.applyAppearanceSetting(JSON.stringify({ gtkDark: modelData.dark }));
                                                    root.showToast("Modo de aplicaciones: " + modelData.l);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 4.3: PERSONALIZACIÓN › BARRA DE TAREAS
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Personalización" && root.settingsSubPage === "Barra de tareas"

                        Text { text: "Elementos de la barra de tareas"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold }

                        // Search Pill Mode (Cuadro / Solo icono / Ocultar — Exact Win11 26H2!)
                        Rectangle {
                            width: parent.width; implicitHeight: srchModRow.implicitHeight + 24
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            RowLayout {
                                id: srchModRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16; spacing: 12
                                WinSvg { width: 20; height: 20; iconFile: "fluent-search.svg" }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Buscar"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                    Text { text: "Elige cómo se muestra el buscador junto al botón de Inicio"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: [{ id: "box", l: "Cuadro" }, { id: "icon", l: "Solo icono" }, { id: "hidden", l: "Ocultar" }]
                                        delegate: Rectangle {
                                            readonly property bool isCur: (root.cfg.taskbarSearchMode || "box") === modelData.id
                                            width: 84; height: 32; radius: 5
                                            color: isCur ? root.accentColor : (smH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"
                                            Text { anchors.centerIn: parent; text: modelData.l; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea { id: smH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.updateCfg("taskbarSearchMode", modelData.id); root.showToast("Buscador en barra: " + modelData.l); } }
                                        }
                                    }
                                }
                            }
                        }

                        ToggleCard {
                            iconFile: "win11-taskview.svg"
                            title: "Vista de tareas (Win + Tab)"
                            subtitle: "Muestra el botón de escritorios virtuales y ventanas abiertas en la barra de tareas"
                            checked: root.cfg.showTaskViewBtn !== false
                            onToggled: (v) => { root.updateCfg("showTaskViewBtn", v); root.showToast(v ? "Vista de tareas visible" : "Vista de tareas oculta"); }
                        }

                        ToggleCard {
                            iconFile: "win11-weather-clear.svg"
                            title: "Widgets (El Tiempo)"
                            subtitle: root.cfg.taskbarLeftAlign
                                      ? "Oculto automáticamente mientras la barra de tareas esté alineada a la izquierda (cambia a «Centro» para mostrarlo)"
                                      : "Muestra el pronóstico del tiempo en la esquina izquierda cuando la barra está centrada"
                            checked: root.cfg.showWeatherWidget !== false
                            onToggled: (v) => { root.updateCfg("showWeatherWidget", v); root.showToast(v ? "Widget del Tiempo visible" : "Widget del Tiempo oculto"); }
                        }

                        ToggleCard {
                            iconFile: "fluent-battery-charge.svg"
                            title: "Mostrar porcentaje de batería en la bandeja"
                            subtitle: "Muestra el porcentaje numérico junto al icono de batería en equipos portátiles"
                            checked: Boolean(root.cfg.showBatteryPct)
                            onToggled: (v) => root.updateCfg("showBatteryPct", v)
                        }

                        Text { text: "Comportamientos de la barra de tareas"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 6 }

                        Rectangle {
                            width: parent.width; implicitHeight: alignRow.implicitHeight + 24
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            RowLayout {
                                id: alignRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16; spacing: 12
                                WinSvg { width: 20; height: 20; iconFile: "fluent-window-apps.svg" }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: "Alineación de la barra de tareas"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                    Text { text: "Alterna entre los iconos centrados de Windows 11 o el estilo clásico a la izquierda"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: [{ left: false, l: "Centro" }, { left: true, l: "Izquierda" }]
                                        delegate: Rectangle {
                                            readonly property bool isCur: Boolean(root.cfg.taskbarLeftAlign) === modelData.left
                                            width: 86; height: 32; radius: 5
                                            color: isCur ? root.accentColor : (alH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"
                                            Text { anchors.centerIn: parent; text: modelData.l; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea { id: alH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.updateCfg("taskbarLeftAlign", modelData.left); root.showToast("Barra alineada: " + modelData.l); } }
                                        }
                                    }
                                }
                            }
                        }

                        ToggleCard {
                            iconFile: "fluent-maximize.svg"
                            title: "Barra de tareas compacta"
                            subtitle: "Reduce la altura de la barra de tareas de 48 px a 38 px para ganar espacio vertical"
                            checked: Boolean(root.cfg.taskbarCompact)
                            onToggled: (v) => root.updateCfg("taskbarCompact", v)
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 4.4: PERSONALIZACIÓN › INICIO
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Personalización" && root.settingsSubPage === "Inicio"

                        Rectangle {
                            width: parent.width; implicitHeight: stLayoutCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: stLayoutCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-grid.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Diseño de «Todas las aplicaciones» (Windows 11 26H2)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                        Text { text: "Elige cómo se organizan tus programas instalados al abrir el Menú Inicio"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                GridLayout {
                                    Layout.fillWidth: true; columns: root.narrowBody ? 1 : 3; columnSpacing: 10; rowSpacing: 10
                                    Repeater {
                                        model: [
                                            { id: "categories", title: "Categoría",  desc: "Carpetas inteligentes 2×2 estilo 26H2", icon: "fluent-grid.svg" },
                                            { id: "grid",       title: "Cuadrícula", desc: "Todos los iconos en rejilla alfabética", icon: "fluent-folder-grid.svg" },
                                            { id: "list",       title: "Lista",      desc: "Lista vertical clásica A–Z detallada",  icon: "fluent-apps-list.svg" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: (root.cfg.startAllViewMode || "categories") === modelData.id
                                            Layout.fillWidth: true; implicitHeight: 82; radius: 7
                                            color: isCur ? "#25313b" : (svH.containsMouse ? "#2f2f2f" : "#1f1f1f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"; border.width: isCur ? 2 : 1
                                            ColumnLayout {
                                                anchors.fill: parent; anchors.margins: 12; spacing: 4
                                                RowLayout {
                                                    spacing: 8
                                                    WinSvg { width: 17; height: 17; iconFile: modelData.icon }
                                                    Text { text: modelData.title; color: isCur ? root.accentColor : "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                                }
                                                Text { text: modelData.desc; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                            }
                                            MouseArea {
                                                id: svH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { root.updateCfg("startAllViewMode", modelData.id); root.showToast("Vista de Inicio: " + modelData.title); }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ToggleCard {
                            iconFile: "fluent-sparkle.svg"
                            title: "Mostrar sección «Recomendado» en el Menú Inicio"
                            subtitle: "Incluye accesos a archivos y actividad reciente dentro de Inicio"
                            checked: Boolean(root.cfg.showRecommended)
                            onToggled: (v) => root.updateCfg("showRecommended", v)
                        }

                        ToggleCard {
                            iconFile: "fluent-phone.svg"
                            title: "Mostrar panel lateral «Enlace Móvil» junto al Menú Inicio"
                            subtitle: "Muestra batería, pantalla táctil, envío de archivos y timbre rápido para tu móvil Android"
                            checked: Boolean(root.cfg.showPhoneLink)
                            onToggled: (v) => root.updateCfg("showPhoneLink", v)
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 4.5: PERSONALIZACIÓN › PANTALLA DE BLOQUEO
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Personalización" && root.settingsSubPage === "Pantalla de bloqueo"

                        // Live Lock Screen Preview Banner
                        Rectangle {
                            width: parent.width; implicitHeight: lkPrevRow.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            RowLayout {
                                id: lkPrevRow; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 18
                                Rectangle {
                                    Layout.preferredWidth: 230; Layout.preferredHeight: 130; radius: 7; clip: true
                                    color: (Number(root.cfg.lockWallpaperMode) === -1 && root.cfg.wallpaperMode === 4) ? (root.cfg.solidBgColor || "#141923") : "#0e131c"
                                    border.color: "#34ffffff"; border.width: 1
                                    Image {
                                        anchors.fill: parent; visible: !(Number(root.cfg.lockWallpaperMode) === -1 && root.cfg.wallpaperMode === 4)
                                        cache: false; source: root.activeLockWallpaperSrc; fillMode: Image.PreserveAspectCrop
                                    }
                                    Rectangle { anchors.fill: parent; color: "#2a000000" }
                                    Column {
                                        anchors.horizontalCenter: parent.horizontalCenter; y: 24; spacing: 2
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.clockTimeStr.replace(/:\d\d(\s|$)/, "$1"); color: "#ffffff"; font.pixelSize: 22; font.weight: Font.DemiBold }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "X64 Windows 11"; color: "#e8eef5"; font.pixelSize: 8 }
                                        Rectangle {
                                            visible: root.cfg.lockShowStatus !== false
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 92; height: 14; radius: 7; color: "#77141820"; border.color: "#33ffffff"
                                            Text { anchors.centerIn: parent; text: "Clima • Red activa"; color: "#e6edf5"; font.pixelSize: 7 }
                                        }
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    Text { text: "Personalizar pantalla de bloqueo (Win + L)"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Text { text: "Sincroniza automáticamente el fondo del escritorio o asigna una imagen exclusiva para la pantalla de bloqueo."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn {
                                            label: "Probar pantalla de bloqueo (Win + L)"
                                            accent: true
                                            onClicked: bridge.runCtlAction("lock")
                                        }
                                        FluentBtn {
                                            label: "Examinar foto de bloqueo..."
                                            onClicked: {
                                                var u = bridge.pickAndSetLockWallpaper();
                                                if (u !== "") {
                                                    root.updateCfg("lockWallpaperUrl", u);
                                                    root.updateCfg("lockWallpaperMode", 3);
                                                    root.showToast("Imagen de bloqueo aplicada");
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Lock Wallpaper Source Selector
                        Rectangle {
                            width: parent.width; implicitHeight: lkSrcCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: lkSrcCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                Text { text: "Origen del fondo de bloqueo"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    Repeater {
                                        model: [
                                            { id: -1, l: "Igual que el escritorio" },
                                            { id: 0,  l: "Bloom Oscuro" },
                                            { id: 1,  l: "Bloom Claro" },
                                            { id: 2,  l: "X64 Monolith" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: (root.cfg.lockWallpaperMode !== undefined ? Number(root.cfg.lockWallpaperMode) : -1) === modelData.id
                                            width: lkBtnT.implicitWidth + 24; height: 34; radius: 5
                                            color: isCur ? root.accentColor : (lkH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"
                                            Text { id: lkBtnT; anchors.centerIn: parent; text: modelData.l; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea { id: lkH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.updateCfg("lockWallpaperMode", modelData.id); root.showToast("Fondo de bloqueo: " + modelData.l); } }
                                        }
                                    }
                                }
                            }
                        }

                        ToggleCard {
                            iconFile: "win11-weather-clear.svg"
                            title: "Mostrar tarjeta de clima y red en la pantalla de bloqueo"
                            subtitle: "Muestra una cápsula discreta bajo el reloj con el tiempo actual y tu red activa"
                            checked: root.cfg.lockShowStatus !== false
                            onToggled: (v) => root.updateCfg("lockShowStatus", v)
                        }
                    }

                    // ---------------------------------------------------------
                    // SUBPAGE 4.6: PERSONALIZACIÓN › ESCRITORIO Y PUNTERO
                    // ---------------------------------------------------------
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Personalización" && root.settingsSubPage === "Escritorio y puntero"

                        Text { text: "Iconos del escritorio"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold }

                        ToggleCard {
                            iconFile: "fluent-grid.svg"
                            title: "Mostrar iconos del escritorio"
                            subtitle: "Oculta o muestra todos los iconos y archivos sobre el fondo del escritorio"
                            checked: Boolean(root.cfg.showDesktopIcons)
                            onToggled: (v) => root.updateCfg("showDesktopIcons", v)
                        }

                        ToggleCard {
                            iconFile: "fluent-arrow-sort.svg"
                            title: "Organizar iconos automáticamente"
                            subtitle: "Mantiene los iconos alineados en columnas de forma automática"
                            checked: Boolean(root.cfg.desktopAutoArrange)
                            onToggled: (v) => {
                                root.updateCfg("desktopAutoArrange", v);
                                if (v) root.updateCfg("desktopIconPositions", ({}));
                            }
                        }

                        Rectangle {
                            width: parent.width; implicitHeight: icSzCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: icSzCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                Text { text: "Tamaño de los iconos del escritorio"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    Repeater {
                                        model: [{ id: "small", label: "Pequeños" }, { id: "medium", label: "Medianos" }, { id: "large", label: "Grandes" }]
                                        delegate: Rectangle {
                                            readonly property bool isCur: (root.cfg.desktopIconSizeMode || "medium") === modelData.id
                                            width: 96; height: 32; radius: 5
                                            color: isCur ? root.accentColor : (iszH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"
                                            Text { anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea { id: iszH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.updateCfg("desktopIconSizeMode", modelData.id) }
                                        }
                                    }
                                    FluentBtn {
                                        label: "Restaurar iconos predeterminados"
                                        onClicked: {
                                            root.updateCfg("showDesktopIcons", true);
                                            bridge.runCtlAction("restore-desktop-icons");
                                            root.showToast("Iconos predeterminados restaurados");
                                        }
                                    }
                                }
                            }
                        }

                        // Real Cursor Theme & Size Control (gsettings + GTK3/4 + labwc/environment!)
                        Text { text: "Puntero del ratón (Wayland / GTK)"; color: "#a8a8a8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 6 }

                        Rectangle {
                            width: parent.width; implicitHeight: curCol.implicitHeight + 28
                            radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: curCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Tema del cursor"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Text { text: "Se aplica al instante en aplicaciones GTK/Qt y al recargar el compositor labwc"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    Repeater {
                                        model: root.appearanceData.cursorThemes || ["breeze_cursors", "Breeze_Light", "Adwaita"]
                                        delegate: Rectangle {
                                            readonly property bool isCur: (root.appearanceData.cursorTheme || "breeze_cursors") === modelData
                                            width: ctLbl.implicitWidth + 24; height: 32; radius: 5
                                            color: isCur ? root.accentColor : (ctH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? root.accentColor : "#22ffffff"
                                            Text { id: ctLbl; anchors.centerIn: parent; text: modelData; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea {
                                                id: ctH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var ec = Object.assign({}, root.extData);
                                                    var ap = Object.assign({}, root.appearanceData);
                                                    ap.cursorTheme = modelData;
                                                    ec.appearance = ap;
                                                    root.extData = ec;
                                                    bridge.applyAppearanceSetting(JSON.stringify({ cursorTheme: modelData }));
                                                    root.showToast("Cursor aplicado: " + modelData);
                                                }
                                            }
                                        }
                                    }
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#14ffffff" }
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Tamaño del puntero"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Text { text: "Útil en monitores 4K o para mejorar la visibilidad del cursor"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    Row {
                                        spacing: 6
                                        Repeater {
                                            model: [24, 32, 48]
                                            delegate: Rectangle {
                                                readonly property bool isCur: Number(root.appearanceData.cursorSize || 24) === modelData
                                                width: 64; height: 32; radius: 5
                                                color: isCur ? root.accentColor : (csH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"
                                                Text { anchors.centerIn: parent; text: modelData + " px"; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: csH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var ec = Object.assign({}, root.extData);
                                                        var ap = Object.assign({}, root.appearanceData);
                                                        ap.cursorSize = modelData;
                                                        ec.appearance = ap;
                                                        root.extData = ec;
                                                        bridge.applyAppearanceSetting(JSON.stringify({ cursorSize: modelData }));
                                                        root.showToast("Tamaño del puntero: " + modelData + " px");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 5: APLICACIONES (Win11 26H2 Hub + 3 Subpáginas + Desinstalador Gráfico!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Aplicaciones"

                        // --- HUB PRINCIPAL DE APLICACIONES ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === ""

                            // Hero Banner de Resumen de Aplicaciones
                            Rectangle {
                                width: parent.width; implicitHeight: appsHeroRow.implicitHeight + 30
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                RowLayout {
                                    id: appsHeroRow
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                    Rectangle {
                                        width: 50; height: 50; radius: 10
                                        color: Qt.alpha(root.accentColor, 0.14); border.color: Qt.alpha(root.accentColor, 0.35); border.width: 1
                                        Layout.preferredWidth: 50; Layout.preferredHeight: 50
                                        WinSvg { anchors.centerIn: parent; width: 26; height: 26; iconFile: "fluent-apps-list.svg" }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text {
                                            text: "Aplicaciones y características"
                                            color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold
                                            Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                        Text {
                                            text: root.appsStats.total + " aplicaciones detectadas (" + root.appsStats.pacman + " Pacman"
                                                  + (root.appsStats.flatpak > 0 ? (", " + root.appsStats.flatpak + " Flatpak") : "")
                                                  + (root.appsStats.local > 0 ? (", " + root.appsStats.local + (root.appsStats.local === 1 ? " local" : " locales")) : "")
                                                  + ")  •  " + root.appsStats.totalSizeHuman + " en disco  •  " + root.startupEnabledCount + " al inicio"
                                            color: "#a8a8a8"; font.pixelSize: 12
                                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        label: "Tienda Shelly"
                                        accent: true
                                        onClicked: bridge.launchRealApp("/usr/bin/shelly-ui")
                                    }
                                }
                            }

                            // 3 Subpáginas Oficiales Windows 11 26H2
                            HubNavCard {
                                iconFile: "fluent-apps-list.svg"
                                title: "Aplicaciones instaladas"
                                subtitle: "Buscar, ordenar por tamaño, abrir o desinstalar programas gráficos con asistente"
                                badge: root.appsStats.total + " apps"
                                onClicked: root.navigateTo("Aplicaciones", "Aplicaciones instaladas", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-open-more.svg"
                                title: "Aplicaciones predeterminadas"
                                subtitle: "Navegador web, explorador, fotos, vídeo, música, texto, PDF, archivos y terminal"
                                badge: (root.extData.defaultApps || []).length + " categorías"
                                onClicked: root.navigateTo("Aplicaciones", "Aplicaciones predeterminadas", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-play-filled.svg"
                                title: "Inicio"
                                subtitle: "Controla qué aplicaciones se inician automáticamente al abrir sesión"
                                badge: root.startupEnabledCount + " activas"
                                onClicked: root.navigateTo("Aplicaciones", "Inicio", true)
                            }

                            // Tarjeta informativa de Desinstalador Rápido
                            Rectangle {
                                width: parent.width; implicitHeight: appsTipRow.implicitHeight + 24
                                radius: 7; color: "#222222"; border.color: "#18ffffff"; border.width: 1
                                RowLayout {
                                    id: appsTipRow
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    WinSvg { width: 18; height: 18; iconFile: "fluent-shield.svg"; opacity: 0.85 }
                                    Text {
                                        text: "Sugerencia: también puedes hacer clic derecho › Desinstalar sobre cualquier aplicación en el Menú Inicio para abrir directamente el Asistente de Desinstalación."
                                        color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 1: APLICACIONES INSTALADAS + DESINSTALADOR GRÁFICO ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Aplicaciones instaladas"

                            // Barra superior de búsqueda, filtro de origen, orden y Tienda Shelly
                            Rectangle {
                                width: parent.width; implicitHeight: instCtrlCol.implicitHeight + 26
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: instCtrlCol
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 14; spacing: 10

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Rectangle {
                                            Layout.fillWidth: true; height: 36; radius: 5; clip: true
                                            color: appFilterIn.activeFocus ? "#161616" : "#1f1f1f"
                                            border.color: appFilterIn.activeFocus ? root.accentColor : "#26ffffff"; border.width: 1
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 8
                                                WinSvg { width: 14; height: 14; iconFile: "fluent-search.svg"; opacity: 0.8 }
                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                                    Text {
                                                        visible: appFilterIn.text === ""
                                                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                                        text: "Buscar por nombre, paquete o descripción..."
                                                        color: "#9a9a9a"; font.pixelSize: 12; elide: Text.ElideRight
                                                    }
                                                    TextInput {
                                                        id: appFilterIn
                                                        anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                                        color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                                                        text: root.appSearchFilter
                                                        onTextChanged: root.appSearchFilter = text
                                                    }
                                                }
                                                WinSvg {
                                                    visible: appFilterIn.text !== ""
                                                    width: 12; height: 12; iconFile: "fluent-dismiss.svg"; opacity: 0.75
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { appFilterIn.text = ""; root.appSearchFilter = ""; } }
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            label: root.appSortBy === "size" ? "Orden: Mayor tamaño" : "Orden: A – Z"
                                            onClicked: root.appSortBy = (root.appSortBy === "name" ? "size" : "name")
                                        }
                                        FluentBtn {
                                            label: "Tienda Shelly"
                                            accent: true
                                            onClicked: bridge.launchRealApp("/usr/bin/shelly-ui")
                                        }
                                    }

                                    // Pastillas de origen + contador en vivo + actualizar
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Flow {
                                            Layout.fillWidth: true; spacing: 6
                                            Repeater {
                                                model: [
                                                    { id: "all",     label: "Todas (" + root.appsStats.total + ")" },
                                                    { id: "pacman",  label: "Pacman (" + root.appsStats.pacman + ")" },
                                                    { id: "flatpak", label: "Flatpak (" + root.appsStats.flatpak + ")" },
                                                    { id: "local",   label: "Locales (" + root.appsStats.local + ")" }
                                                ]
                                                delegate: Rectangle {
                                                    readonly property bool act: root.appSourceFilter === modelData.id
                                                    width: sfLbl.implicitWidth + 22; height: 28; radius: 5
                                                    color: act ? root.accentColor : (sfH.containsMouse ? "#383838" : "#2e2e2e")
                                                    border.color: act ? root.accentColor : "#22ffffff"; border.width: 1
                                                    Text {
                                                        id: sfLbl; anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: act ? "#000000" : "#e8e8e8"
                                                        font.pixelSize: 11; font.weight: act ? Font.DemiBold : Font.Normal
                                                    }
                                                    MouseArea {
                                                        id: sfH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.appSourceFilter = modelData.id
                                                    }
                                                }
                                            }
                                        }
                                        Text {
                                            text: root.filteredInstalledApps.length + " mostradas"
                                            color: "#9a9a9a"; font.pixelSize: 11
                                        }
                                        Rectangle {
                                            width: 28; height: 28; radius: 5
                                            color: refAppH.containsMouse ? "#3a3a3a" : "#2e2e2e"; border.color: "#22ffffff"; border.width: 1
                                            WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-refresh.svg" }
                                            MouseArea {
                                                id: refAppH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { root.reloadInstalledApps(); root.showToast("Lista de aplicaciones actualizada"); }
                                            }
                                        }
                                    }
                                }
                            }

                            // Estado vacío cuando el filtro no encuentra resultados
                            Rectangle {
                                visible: root.filteredInstalledApps.length === 0
                                width: parent.width; height: 84; radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: root.appSourceFilter === "flatpak" && root.appsStats.flatpak === 0
                                          ? "No hay aplicaciones Flatpak instaladas actualmente."
                                          : "No se encontraron aplicaciones que coincidan con el filtro."
                                    color: "#9a9a9a"; font.pixelSize: 13
                                }
                            }

                            // Catálogo de aplicaciones con tamaño real, versión, escudo de sistema y Desinstalador Gráfico
                            Repeater {
                                model: root.filteredInstalledApps
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: Math.max(66, appItemRow.implicitHeight + 22)
                                    radius: 7; color: appRowHov.containsMouse ? "#2b2b2b" : "#262626"
                                    border.color: "#1cffffff"; border.width: 1
                                    MouseArea { id: appRowHov; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

                                    RowLayout {
                                        id: appItemRow
                                        anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 14

                                        WinSvg { width: 32; height: 32; iconUrl: modelData.iconUrl || "" }

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 6
                                                Text {
                                                    text: modelData.name || ""
                                                    color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium
                                                    elide: Text.ElideRight; Layout.maximumWidth: 320
                                                }
                                                Rectangle {
                                                    visible: String(modelData.sourceLabel || "") !== ""
                                                    width: srcPillTxt.implicitWidth + 12; height: 19; radius: 4
                                                    color: modelData.source === "flatpak" ? "#263b82f6" : (modelData.source === "local" ? "#26a855f7" : "#22ffffff")
                                                    border.color: modelData.source === "flatpak" ? "#553b82f6" : (modelData.source === "local" ? "#55a855f7" : "#26ffffff")
                                                    Text {
                                                        id: srcPillTxt; anchors.centerIn: parent
                                                        text: modelData.sourceLabel || ""
                                                        color: "#dcdcdc"; font.pixelSize: 10; font.weight: Font.Medium
                                                    }
                                                }
                                                Rectangle {
                                                    visible: Boolean(modelData.isSystemProtected)
                                                    width: sysProtTxt.implicitWidth + 12; height: 19; radius: 4
                                                    color: "#22eab308"; border.color: "#44eab308"
                                                    Text {
                                                        id: sysProtTxt; anchors.centerIn: parent
                                                        text: "Sistema"
                                                        color: "#facc15"; font.pixelSize: 10; font.weight: Font.Medium
                                                    }
                                                }
                                                Item { Layout.fillWidth: true }
                                            }
                                            Text {
                                                text: (modelData.pkgName || modelData.cmd || "")
                                                      + (modelData.version ? ("  •  v" + modelData.version) : "")
                                                      + (modelData.publisher ? ("  •  " + modelData.publisher) : "")
                                                      + (modelData.installDate ? ("  •  " + modelData.installDate) : "")
                                                color: "#9a9a9a"; font.pixelSize: 11
                                                Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }

                                        Text {
                                            visible: !root.narrowBody
                                            text: modelData.sizeHuman || "—"
                                            color: "#c8c8c8"; font.pixelSize: 12; font.weight: Font.Medium
                                            Layout.preferredWidth: 74; horizontalAlignment: Text.AlignRight
                                        }

                                        FluentBtn {
                                            label: "Abrir"
                                            onClicked: bridge.launchRealApp(modelData.cmd)
                                        }

                                        // Botón Desinstalar (Asistente Gráfico WinUI 3 o protegido por escudo)
                                        Rectangle {
                                            readonly property bool blocked: !Boolean(modelData.canUninstall)
                                            implicitWidth: Math.max(114, unBtnRow.implicitWidth + 20); implicitHeight: 35
                                            Layout.preferredWidth: implicitWidth; Layout.preferredHeight: 35
                                            radius: 6
                                            color: blocked ? "#222222" : (unBtnH.containsMouse ? "#5a2323" : "#342424")
                                            border.color: blocked ? "#18ffffff" : (unBtnH.containsMouse ? "#ef4444" : "#44ef4444")
                                            border.width: 1
                                            opacity: blocked ? 0.55 : 1.0
                                            RowLayout {
                                                id: unBtnRow; anchors.centerIn: parent; spacing: 6
                                                WinSvg { width: 13; height: 13; iconFile: parent.parent.blocked ? "fluent-shield.svg" : "fluent-delete.svg" }
                                                Text {
                                                    text: parent.parent.blocked ? "Protegida" : "Desinstalar"
                                                    color: parent.parent.blocked ? "#9e9e9e" : "#fca5a5"
                                                    font.pixelSize: 12; font.weight: Font.Medium
                                                }
                                            }
                                            MouseArea {
                                                id: unBtnH; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.openUninstallWizard(modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 2: APLICACIONES PREDETERMINADAS (10 ROLES REALES + RESTABLECER) ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Aplicaciones predeterminadas"

                            Rectangle {
                                width: parent.width; implicitHeight: defHdrRow.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: defHdrRow
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
                                    WinSvg { width: 22; height: 22; iconFile: "fluent-open-more.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Restablecer todas las aplicaciones predeterminadas"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text { text: "Restaura las asociaciones recomendadas por X64 Windows 11 (Navegador, Explorador, Fotos, Vídeo, Música, Texto, PDF y Terminal)"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    FluentBtn {
                                        label: "Restablecer"
                                        onClicked: {
                                            if (bridge.resetDefaultAppsWin11()) {
                                                root.expandedMimeRole = "";
                                                root.refreshLiveState(false);
                                                root.showToast("Aplicaciones predeterminadas restablecidas");
                                            } else {
                                                root.showToast("No se pudieron restablecer las asociaciones");
                                            }
                                        }
                                    }
                                }
                            }

                            Text { text: "Establecer predeterminadas por tipo de contenido (haz clic para elegir)"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                            Repeater {
                                model: root.extData.defaultApps || []
                                delegate: Rectangle {
                                    id: roleCard
                                    readonly property string rId: modelData.id || ""
                                    readonly property bool hasChoices: (modelData.candidates || []).length > 0
                                    readonly property bool isExp: root.expandedMimeRole === rId && hasChoices
                                    width: parent.width; implicitHeight: roleCardCol.implicitHeight + 24
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1

                                    ColumnLayout {
                                        id: roleCardCol
                                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.margins: 12; spacing: 8

                                        Rectangle {
                                            Layout.fillWidth: true; implicitHeight: Math.max(46, defRowLay.implicitHeight + 10); radius: 5
                                            color: defRowH.containsMouse ? "#303030" : "transparent"
                                            RowLayout {
                                                id: defRowLay
                                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 12
                                                WinSvg { width: 22; height: 22; iconFile: modelData.icon || "fluent-apps-list.svg" }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 2
                                                    Text { text: modelData.role || ""; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                    Text { visible: String(modelData.subtitle || "") !== ""; text: modelData.subtitle || ""; color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                                }
                                                Text {
                                                    text: modelData.app || "Sin asignar"
                                                    color: (modelData.desktop && modelData.desktop !== "") ? root.accentColor : "#8e8e8e"
                                                    font.pixelSize: 12; font.weight: Font.Medium
                                                    elide: Text.ElideRight; Layout.maximumWidth: 210
                                                }
                                                WinSvg {
                                                    visible: roleCard.hasChoices
                                                    width: 12; height: 12
                                                    iconFile: roleCard.isExp ? "fluent-chevron-up.svg" : "fluent-chevron-down.svg"
                                                    opacity: 0.75
                                                }
                                            }
                                            MouseArea {
                                                id: defRowH; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: roleCard.hasChoices ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: {
                                                    if (roleCard.hasChoices) {
                                                        root.expandedMimeRole = (root.expandedMimeRole === roleCard.rId) ? "" : roleCard.rId;
                                                    } else {
                                                        root.showToast("No hay aplicaciones compatibles instaladas para esta categoría");
                                                    }
                                                }
                                            }
                                        }

                                        Flow {
                                            visible: roleCard.isExp
                                            Layout.fillWidth: true; Layout.leftMargin: 42; Layout.bottomMargin: 4; spacing: 6
                                            Repeater {
                                                model: modelData.candidates || []
                                                delegate: Rectangle {
                                                    width: cLbl.implicitWidth + 22; height: 30; radius: 5
                                                    color: modelData.active ? root.accentColor : (candH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                    border.color: modelData.active ? root.accentColor : "#24ffffff"; border.width: 1
                                                    Text {
                                                        id: cLbl; anchors.centerIn: parent
                                                        text: modelData.label
                                                        color: modelData.active ? "#000000" : "#f0f0f0"
                                                        font.pixelSize: 12; font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                    }
                                                    MouseArea {
                                                        id: candH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (bridge.setDefaultAppForRole(roleCard.rId, modelData.desktop)) {
                                                                root.expandedMimeRole = "";
                                                                root.refreshLiveState(false);
                                                                root.showToast("Predeterminada cambiada a " + modelData.label);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 3: APLICACIONES DE INICIO (AUTOSTART REAL CON SWITCHES EN LÍNEA) ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Inicio"

                            Rectangle {
                                width: parent.width; implicitHeight: stHdrRow.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: stHdrRow
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 12
                                    WinSvg { width: 22; height: 22; iconFile: "fluent-play-filled.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Aplicaciones de inicio automático (" + root.startupEnabledCount + " de " + root.startupApps.length + " activas)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text { text: "Se cargan desde ~/.config/autostart y /etc/xdg/autostart al iniciar sesión en X64 LIOS"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    FluentBtn {
                                        label: root.startupAddOpen ? "Cerrar formulario" : "Agregar al inicio"
                                        accent: !root.startupAddOpen
                                        onClicked: {
                                            root.startupAddErr = "";
                                            root.startupAddOpen = !root.startupAddOpen;
                                        }
                                    }
                                    FluentBtn {
                                        label: "Adm. de tareas"
                                        onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app taskmgr startup")
                                    }
                                }
                            }

                            // Formulario colapsable para añadir nueva app al inicio
                            Rectangle {
                                visible: root.startupAddOpen
                                width: parent.width; implicitHeight: stAddCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: Qt.alpha(root.accentColor, 0.4); border.width: 1
                                ColumnLayout {
                                    id: stAddCol
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                    anchors.margins: 16; spacing: 10
                                    Text { text: "Nueva aplicación de inicio automático"; color: "#ffffff"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        Rectangle {
                                            Layout.fillWidth: true; height: 34; radius: 5; color: "#191919"
                                            border.color: stNameIn.activeFocus ? root.accentColor : "#2cffffff"; border.width: 1
                                            Text { visible: stNameIn.text === ""; anchors.fill: parent; anchors.leftMargin: 10; verticalAlignment: Text.AlignVCenter; text: "Nombre (ej. Discord)"; color: "#888888"; font.pixelSize: 12 }
                                            TextInput { id: stNameIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 34; radius: 5; color: "#191919"
                                            border.color: stCmdIn.activeFocus ? root.accentColor : "#2cffffff"; border.width: 1
                                            Text { visible: stCmdIn.text === ""; anchors.fill: parent; anchors.leftMargin: 10; verticalAlignment: Text.AlignVCenter; text: "Comando (ej. /usr/bin/discord)"; color: "#888888"; font.pixelSize: 12 }
                                            TextInput { id: stCmdIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true }
                                        }
                                        FluentBtn {
                                            label: "Guardar"
                                            accent: true
                                            onClicked: {
                                                if (stNameIn.text.trim() === "" || stCmdIn.text.trim() === "") {
                                                    root.startupAddErr = "Introduce un nombre y un comando válido.";
                                                    return;
                                                }
                                                if (bridge.addStartupApp(stNameIn.text.trim(), stCmdIn.text.trim(), "")) {
                                                    stNameIn.text = ""; stCmdIn.text = ""; root.startupAddErr = "";
                                                    root.startupAddOpen = false;
                                                    root.reloadStartupApps();
                                                    root.showToast("Aplicación añadida al inicio automático");
                                                } else {
                                                    root.startupAddErr = "No se pudo crear la entrada de inicio.";
                                                }
                                            }
                                        }
                                    }
                                    Text { visible: root.startupAddErr !== ""; text: root.startupAddErr; color: "#f87171"; font.pixelSize: 11 }
                                }
                            }

                            Repeater {
                                model: root.startupApps
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: Math.max(66, stRow.implicitHeight + 22)
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: stRow
                                        anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 14

                                        WinSvg { width: 28; height: 28; iconUrl: modelData.iconUrl || "" }

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 6
                                                Text { text: modelData.name || ""; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight; Layout.maximumWidth: 320 }
                                                Rectangle {
                                                    width: pubTxt.implicitWidth + 10; height: 18; radius: 4; color: "#1effffff"
                                                    Text { id: pubTxt; anchors.centerIn: parent; text: modelData.publisher || "Sistema"; color: "#bcbcbc"; font.pixelSize: 10 }
                                                }
                                                Item { Layout.fillWidth: true }
                                            }
                                            Text { text: modelData.execCmd || ""; color: "#909090"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        }

                                        // Impacto en el arranque
                                        Rectangle {
                                            visible: !root.narrowBody
                                            readonly property string imp: String(modelData.impact || "Bajo")
                                            width: impTxt.implicitWidth + 16; height: 22; radius: 4
                                            color: imp === "Alto" ? "#26ef4444" : (imp === "Medio" ? Qt.alpha(root.accentColor, 0.16) : "#2622c55e")
                                            Text {
                                                id: impTxt; anchors.centerIn: parent
                                                text: "Impacto " + parent.imp.toLowerCase()
                                                color: parent.imp === "Alto" ? "#fca5a5" : (parent.imp === "Medio" ? root.accentColor : "#86efac")
                                                font.pixelSize: 11; font.weight: Font.Medium
                                            }
                                        }

                                        // Quitar entrada de usuario
                                        Rectangle {
                                            visible: Boolean(modelData.canRemove)
                                            width: 30; height: 30; radius: 5
                                            color: rmStH.containsMouse ? "#4d2323" : "#2c2c2c"; border.color: "#22ffffff"
                                            WinSvg { anchors.centerIn: parent; width: 13; height: 13; iconFile: "fluent-delete.svg" }
                                            MouseArea {
                                                id: rmStH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (bridge.removeStartupApp(modelData.id)) {
                                                        root.reloadStartupApps();
                                                        root.showToast("Eliminada del inicio: " + modelData.name);
                                                    }
                                                }
                                            }
                                        }

                                        Win11Switch {
                                            checked: Boolean(modelData.enabled)
                                            onToggled: (v) => {
                                                if (bridge.setStartupAppEnabled(modelData.id, v)) {
                                                    root.reloadStartupApps();
                                                    root.showToast(modelData.name + (v ? " habilitada al inicio" : " deshabilitada al inicio"));
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 6: CUENTAS (Win11 26H2 Hub + 3 Subpáginas + Modales Gráficos!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Cuentas"

                        // --- HUB PRINCIPAL DE CUENTAS ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === ""

                            // Profile Hero Card with Circular Avatar (0ms real data, zero placeholder flash!)
                            Rectangle {
                                width: parent.width; implicitHeight: accHeroCol.implicitHeight + 32
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                RowLayout {
                                    id: accHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 18
                                    UserAvatarBadge { sz: root.narrowBody ? 68 : 84 }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { text: root.activeDisplayName; color: "#ffffff"; font.pixelSize: 21; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: root.activeAccountHandle; color: "#b8b8b8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        RowLayout {
                                            spacing: 6; Layout.topMargin: 2
                                            Rectangle {
                                                width: roleTxt.implicitWidth + 16; height: 22; radius: 4
                                                color: Qt.alpha(root.accentColor, 0.14); border.color: Qt.alpha(root.accentColor, 0.32)
                                                Text {
                                                    id: roleTxt; anchors.centerIn: parent
                                                    text: root.accData.isAdmin ? "Administrador local" : "Usuario estándar"
                                                    color: root.accentColor; font.pixelSize: 11; font.weight: Font.DemiBold
                                                }
                                            }
                                            Rectangle {
                                                visible: Boolean(root.accData.hasPin) || Boolean(root.cfg.lockRequireAuth)
                                                width: secTagT.implicitWidth + 14; height: 22; radius: 4
                                                color: "#2222c55e"; border.color: "#4422c55e"
                                                Text {
                                                    id: secTagT; anchors.centerIn: parent
                                                    text: Boolean(root.accData.hasPin) ? "PIN activo" : "Win+L protegido"
                                                    color: "#86efac"; font.pixelSize: 11; font.weight: Font.Medium
                                                }
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        visible: !root.narrowBody
                                        spacing: 6
                                        FluentBtn { label: "Bloquear (Win+L)"; accent: true; onClicked: bridge.runCtlAction("lock") }
                                        FluentBtn { label: "Carpeta personal"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer 'Inicio'") }
                                    }
                                }
                            }

                            // 3 Official Windows 11 26H2 Account Subpages
                            HubNavCard {
                                iconFile: "fluent-person.svg"
                                title: "Tu información"
                                subtitle: "Foto de perfil, nombre visible, consola de tu usuario y detalles de la cuenta"
                                badge: root.accData.isAdmin ? "Administrador" : "Estándar"
                                onClicked: root.navigateTo("Cuentas", "Tu información", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-lock.svg"
                                title: "Opciones de inicio de sesión"
                                subtitle: "Contraseña gráfica, PIN rápido, protección de Win+L e inicio automático SDDM"
                                badge: Boolean(root.accData.hasPin) ? "PIN activo" : (Boolean(root.cfg.lockRequireAuth) ? "Protegido" : "Contraseña")
                                onClicked: root.navigateTo("Cuentas", "Opciones de inicio de sesión", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-add-circle.svg"
                                title: "Otros usuarios"
                                subtitle: "Agregar cuentas locales, gestionar permisos de administrador o quitar cuentas"
                                badge: {
                                    var n = (root.accData.otherUsers || []).length;
                                    return n > 0 ? (n + (n === 1 ? " cuenta" : " cuentas")) : "1 cuenta";
                                }
                                onClicked: root.navigateTo("Cuentas", "Otros usuarios", true)
                            }
                        }

                        // --- SUBPÁGINA 1: TU INFORMACIÓN ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Tu información"

                            // Compact identity bar
                            Rectangle {
                                width: parent.width; implicitHeight: tiHeroRow.implicitHeight + 28
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                RowLayout {
                                    id: tiHeroRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 16
                                    UserAvatarBadge { sz: 64 }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: root.activeDisplayName; color: "#ffffff"; font.pixelSize: 18; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: root.activeAccountHandle + "  •  " + (root.accData.isAdmin ? "Administrador local" : "Usuario estándar"); color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    FluentBtn { label: "Abrir carpeta"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer 'Inicio'") }
                                }
                            }

                            // Change Account Picture Card (File Picker + 7 Instant Presets + Reset including ~/.face!)
                            Rectangle {
                                width: parent.width; implicitHeight: avCardCol.implicitHeight + 28
                                radius: 8; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: avCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 20; height: 20; iconFile: "fluent-image.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Imagen de la cuenta"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                            Text { text: "Se sincroniza al instante en Configuración, Menú Inicio y Pantalla de Bloqueo (~/.face)"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }

                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn {
                                            label: "Elegir una foto..."
                                            accent: true
                                            onClicked: {
                                                var newU = bridge.pickAndSetUserAvatar();
                                                if (newU !== "") {
                                                    root.cfgWriteGuardUntil = Date.now() + 2500;
                                                    root.reloadAccountInfo();
                                                    root.refreshLiveState(false);
                                                    root.showToast("Imagen de perfil actualizada");
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            visible: root.activeAvatarUrl !== ""
                                            label: "Restablecer predeterminado"
                                            onClicked: {
                                                if (bridge.resetUserAvatar()) {
                                                    root.cfgWriteGuardUntil = Date.now() + 2500;
                                                    root.reloadAccountInfo();
                                                    root.refreshLiveState(false);
                                                    root.showToast("Imagen de cuenta restablecida");
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }
                                    Text { text: "O elige un avatar rápido con tus iniciales:"; color: "#b8b8b8"; font.pixelSize: 12 }

                                    Flow {
                                        Layout.fillWidth: true; spacing: 12
                                        Repeater {
                                            model: [
                                                { id: "fluent_blue",    c1: "#0078D4", c2: "#4CC2FF", label: "Azul" },
                                                { id: "fluent_purple",  c1: "#6B21A8", c2: "#C084FC", label: "Violeta" },
                                                { id: "fluent_emerald", c1: "#047857", c2: "#34D399", label: "Esmeralda" },
                                                { id: "fluent_crimson", c1: "#991B1B", c2: "#FF2B2B", label: "Carmesí" },
                                                { id: "fluent_amber",   c1: "#B45309", c2: "#FBBF24", label: "Ámbar" },
                                                { id: "fluent_slate",   c1: "#1E293B", c2: "#475569", label: "Grafito" },
                                                { id: "x64_logo",       c1: "#111318", c2: "#1d2230", label: "X64 LIOS", isLogo: true }
                                            ]
                                            delegate: Column {
                                                spacing: 4
                                                Rectangle {
                                                    width: 46; height: 46; radius: 23
                                                    border.color: avPrH.containsMouse ? root.accentColor : "#38ffffff"; border.width: avPrH.containsMouse ? 2 : 1
                                                    gradient: Gradient {
                                                        GradientStop { position: 0.0; color: modelData.c1 }
                                                        GradientStop { position: 1.0; color: modelData.c2 }
                                                    }
                                                    WinSvg { visible: Boolean(modelData.isLogo); anchors.centerIn: parent; width: 28; height: 28; iconFile: "x64lios.png" }
                                                    Text {
                                                        visible: !modelData.isLogo
                                                        anchors.centerIn: parent
                                                        text: String(root.activeDisplayName || "X").substring(0, 1).toUpperCase()
                                                        color: modelData.id === "fluent_amber" ? "#111111" : "#ffffff"
                                                        font.pixelSize: 17; font.weight: Font.DemiBold
                                                    }
                                                    MouseArea {
                                                        id: avPrH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            var u = bridge.setPresetUserAvatar(modelData.id);
                                                            if (u !== "") {
                                                                root.cfgWriteGuardUntil = Date.now() + 2500;
                                                                root.reloadAccountInfo();
                                                                root.refreshLiveState(false);
                                                                root.showToast("Avatar aplicado: " + modelData.label);
                                                            }
                                                        }
                                                    }
                                                }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#a8a8a8"; font.pixelSize: 10 }
                                            }
                                        }
                                    }
                                }
                            }

                            // Customize Display Name Card
                            Rectangle {
                                width: parent.width; implicitHeight: dnCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: dnCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    Text { text: "Nombre visible del perfil"; color: "#f2f2f2"; font.pixelSize: 14; font.weight: Font.Medium }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Rectangle {
                                            Layout.fillWidth: true; height: 35; radius: 5; clip: true
                                            color: "#171717"; border.color: dispNameIn.activeFocus ? root.accentColor : "#30ffffff"
                                            TextInput {
                                                id: dispNameIn
                                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                                verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; selectByMouse: true; clip: true
                                                Component.onCompleted: text = root.activeDisplayName
                                                onAccepted: {
                                                    if (bridge.setDisplayName(text)) {
                                                        root.cfgWriteGuardUntil = Date.now() + 2500;
                                                        root.forceActiveFocus();
                                                        root.reloadAccountInfo();
                                                        try { root.sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
                                                        root.refreshLiveState(false);
                                                        root.showToast("Nombre visible guardado");
                                                    }
                                                }
                                            }
                                        }
                                        FluentBtn { label: "Guardar"; accent: true; onClicked: dispNameIn.accepted() }
                                    }
                                }
                            }

                            // Friendly Terminal Command Interpreter Selector Card (Real pkexec usermod -s!)
                            Rectangle {
                                width: parent.width; implicitHeight: shCardCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: shCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 20; height: 20; iconFile: "fluent-window-console.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: "Intérprete de comandos de la terminal"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Define qué consola se carga al abrir la Terminal (Kitty). Fish incluye autocompletado y tema X64 LIOS (recomendado); Bash es la consola clásica de Linux."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: root.accData.availableShells || []
                                            delegate: Rectangle {
                                                readonly property string shPath: String(modelData)
                                                readonly property string shBase: shPath.split("/").pop()
                                                readonly property string shLabel: shBase === "fish" ? "Fish (Recomendado)"
                                                                                 : (shBase === "bash" ? "Bash (Clásico)"
                                                                                    : (shBase === "zsh" ? "Zsh" : shBase))
                                                readonly property bool isCur: shBase === String(root.accData.shell || "").split("/").pop()
                                                width: shPillT.implicitWidth + 24; height: 32; radius: 5
                                                color: isCur ? root.accentColor : (shPillH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#26ffffff"; border.width: 1
                                                Text {
                                                    id: shPillT; anchors.centerIn: parent
                                                    text: parent.shLabel
                                                    color: isCur ? "#000000" : "#efefef"
                                                    font.pixelSize: 12; font.weight: isCur ? Font.DemiBold : Font.Normal
                                                }
                                                MouseArea {
                                                    id: shPillH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (parent.isCur) return;
                                                        var r = bridge.setUserShell(parent.shPath);
                                                        if (r === "ok") {
                                                            root.reloadAccountInfo();
                                                            root.refreshLiveState(false);
                                                            root.showToast("Consola cambiada a " + parent.shLabel);
                                                        } else {
                                                            root.showToast(r.replace(/^error:/, ""));
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Technical Profile Summary Card
                            Rectangle {
                                width: parent.width; implicitHeight: accInfoCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: accInfoCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 8
                                    Text { text: "Detalles del perfil del sistema"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                    RowLayout { Layout.fillWidth: true; Text { text: "Nombre de usuario"; color: "#9e9e9e"; font.pixelSize: 12; Layout.preferredWidth: 160 } Text { text: root.accData.username || root.sysInfo.username || "—"; color: "#ececec"; font.pixelSize: 12; Layout.fillWidth: true } }
                                    RowLayout { Layout.fillWidth: true; Text { text: "Carpeta personal"; color: "#9e9e9e"; font.pixelSize: 12; Layout.preferredWidth: 160 } Text { text: root.accData.homeDir || "—"; color: "#ececec"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideMiddle } }
                                    RowLayout { Layout.fillWidth: true; Text { text: "Grupos del sistema"; color: "#9e9e9e"; font.pixelSize: 12; Layout.preferredWidth: 160 } Text { text: root.accData.groups || "—"; color: "#d0d0d0"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap } }
                                }
                            }
                        }

                        // --- SUBPÁGINA 2: OPCIONES DE INICIO DE SESIÓN ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Opciones de inicio de sesión"

                            Text { text: "Formas de iniciar sesión"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                            // 1. Account Password Card (Native WinUI 3 Graphical Modal!)
                            Rectangle {
                                width: parent.width; implicitHeight: pwCardRow.implicitHeight + 30
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: pwCardRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                    WinSvg { width: 21; height: 21; iconFile: "fluent-lock.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text { text: "Contraseña de la cuenta"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                        Text { text: "Inicia sesión en SDDM, sudo y pantalla de bloqueo con tu contraseña local de Linux"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    FluentBtn {
                                        label: "Cambiar contraseña"
                                        accent: true
                                        onClicked: {
                                            root.pwModalErr = "";
                                            root.pwShowFields = false;
                                            pwCurIn.text = ""; pwNewIn.text = ""; pwConfIn.text = "";
                                            root.pwModalOpen = true;
                                            pwCurIn.forceActiveFocus();
                                        }
                                    }
                                }
                            }

                            // 2. Quick PIN Card (Windows Hello Style PBKDF2-SHA256!)
                            Rectangle {
                                width: parent.width; implicitHeight: pinCardRow.implicitHeight + 30
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: pinCardRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    WinSvg { width: 21; height: 21; iconFile: "fluent-shield.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        RowLayout {
                                            spacing: 8
                                            Text { text: "PIN rápido (estilo Windows Hello)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Rectangle {
                                                visible: Boolean(root.accData.hasPin)
                                                width: pinOnT.implicitWidth + 12; height: 19; radius: 4
                                                color: "#2222c55e"; border.color: "#4422c55e"
                                                Text { id: pinOnT; anchors.centerIn: parent; text: "Activo"; color: "#86efac"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                            }
                                        }
                                        Text {
                                            text: Boolean(root.accData.hasPin)
                                                  ? "PIN cifrado (PBKDF2-SHA256) habilitado para desbloquear rápidamente la pantalla Win+L."
                                                  : "Crea un PIN numérico de 4 a 8 dígitos para desbloquear Win+L sin escribir tu contraseña larga."
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        visible: Boolean(root.accData.hasPin)
                                        label: "Quitar"
                                        onClicked: {
                                            if (bridge.removeQuickPin()) {
                                                root.reloadAccountInfo();
                                                root.refreshLiveState(false);
                                                root.showToast("PIN rápido eliminado");
                                            }
                                        }
                                    }
                                    FluentBtn {
                                        label: Boolean(root.accData.hasPin) ? "Cambiar PIN" : "Configurar PIN"
                                        onClicked: {
                                            root.pinModalErr = "";
                                            pinVerifyIn.text = ""; pinNewIn.text = ""; pinConfIn.text = "";
                                            root.pinModalOpen = true;
                                            pinVerifyIn.forceActiveFocus();
                                        }
                                    }
                                }
                            }

                            Text { text: "Configuración adicional de bloqueo e inicio"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 6 }

                            // 3. Real Win+L Lock Screen Authentication Toggle
                            ToggleCard {
                                iconFile: "fluent-lock.svg"
                                title: "Requerir contraseña o PIN al desbloquear (Win+L)"
                                subtitle: Boolean(root.cfg.lockRequireAuth)
                                          ? "Activo: la pantalla de bloqueo Win+L verificará tu PIN rápido o tu contraseña real de Linux."
                                          : "Desactivado: Win+L actúa como pantalla de reposo con desbloqueo instantáneo al pulsar Iniciar sesión."
                                checked: Boolean(root.cfg.lockRequireAuth)
                                onToggled: (v) => {
                                    root.updateCfg("lockRequireAuth", v);
                                    root.showToast(v ? "Bloqueo Win+L protegido con contraseña / PIN" : "Desbloqueo rápido en Win+L activado");
                                }
                            }

                            // 4. Real SDDM Autologin Toggle
                            ToggleCard {
                                iconFile: "fluent-play-filled.svg"
                                title: "Inicio de sesión automático al encender el equipo (SDDM)"
                                subtitle: Boolean(root.accData.sddmAutologin)
                                          ? ("Activo para «" + (root.accData.username || root.sysInfo.username || "") + "» en sesión X64 Windows 11 (/etc/sddm.conf.d/20-x64-autologin.conf)")
                                          : "Al encender el equipo, SDDM pedirá tu contraseña antes de cargar el escritorio."
                                checked: Boolean(root.accData.sddmAutologin)
                                onToggled: (v) => {
                                    var r = bridge.setSddmAutologin(v);
                                    if (r === "ok") {
                                        root.reloadAccountInfo();
                                        root.refreshLiveState(false);
                                        root.showToast(v ? "Auto-inicio de sesión SDDM activado" : "Auto-inicio de sesión SDDM desactivado");
                                    } else {
                                        root.showToast(r.replace(/^error:/, ""));
                                    }
                                }
                            }

                            // Quick actions bar
                            Rectangle {
                                width: parent.width; implicitHeight: siActRow.implicitHeight + 24
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                Flow {
                                    id: siActRow; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8
                                    FluentBtn { label: "Probar bloqueo ahora (Win+L)"; onClicked: bridge.runCtlAction("lock") }
                                    FluentBtn { label: "Personalizar pantalla de bloqueo"; onClicked: root.navigateTo("Personalización", "Pantalla de bloqueo", true) }
                                }
                            }
                        }

                        // --- SUBPÁGINA 3: OTROS USUARIOS ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Otros usuarios"

                            Rectangle {
                                width: parent.width; implicitHeight: ouHdrRow.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: ouHdrRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
                                    WinSvg { width: 22; height: 22; iconFile: "fluent-add-circle.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Agregar otro usuario a este equipo"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                        Text { text: "Crea cuentas locales independientes con su propia carpeta personal, configuración y contraseña"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    FluentBtn {
                                        label: "Agregar cuenta"
                                        accent: true
                                        onClicked: {
                                            root.addUserModalErr = "";
                                            root.addUserIsAdmin = false;
                                            auFullIn.text = ""; auUserIn.text = ""; auPwIn.text = "";
                                            root.addUserModalOpen = true;
                                            auFullIn.forceActiveFocus();
                                        }
                                    }
                                }
                            }

                            Text { text: "Cuentas locales registradas en el sistema (" + (root.accData.otherUsers || []).length + ")"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                            Repeater {
                                model: root.accData.otherUsers || []
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: Math.max(68, uRow.implicitHeight + 24)
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: uRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 14

                                        Rectangle {
                                            width: 40; height: 40; radius: 20
                                            Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                            color: "#323232"; border.color: "#2cffffff"
                                            Image {
                                                visible: String(modelData.avatarUrl || "") !== ""
                                                anchors.fill: parent; anchors.margins: 1
                                                source: modelData.avatarUrl || ""
                                                sourceSize.width: 80; sourceSize.height: 80
                                                fillMode: Image.PreserveAspectFit; mipmap: true; smooth: true; cache: false
                                            }
                                            Text {
                                                visible: String(modelData.avatarUrl || "") === ""
                                                anchors.centerIn: parent
                                                text: String(modelData.displayName || modelData.username || "U").substring(0, 1).toUpperCase()
                                                color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 6
                                                Text { text: modelData.displayName || modelData.username || ""; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight; Layout.maximumWidth: 260 }
                                                Rectangle {
                                                    width: uRoleT.implicitWidth + 12; height: 19; radius: 4
                                                    color: modelData.isAdmin ? Qt.alpha(root.accentColor, 0.16) : "#22ffffff"
                                                    border.color: modelData.isAdmin ? Qt.alpha(root.accentColor, 0.35) : "#28ffffff"
                                                    Text { id: uRoleT; anchors.centerIn: parent; text: modelData.isAdmin ? "Administrador" : "Estándar"; color: modelData.isAdmin ? root.accentColor : "#d4d4d4"; font.pixelSize: 10; font.weight: Font.Medium }
                                                }
                                                Rectangle {
                                                    visible: Boolean(modelData.isCurrent)
                                                    width: uCurT.implicitWidth + 12; height: 19; radius: 4
                                                    color: "#2222c55e"; border.color: "#4422c55e"
                                                    Text { id: uCurT; anchors.centerIn: parent; text: "Sesión activa"; color: "#86efac"; font.pixelSize: 10; font.weight: Font.Medium }
                                                }
                                                Item { Layout.fillWidth: true }
                                            }
                                            Text {
                                                text: "@" + (modelData.username || "") + "  •  " + (modelData.homeDir || "") + "  •  " + (modelData.shell || "")
                                                color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                        }

                                        // Secondary user controls (never shown on active account!)
                                        RowLayout {
                                            visible: !Boolean(modelData.isCurrent)
                                            spacing: 6
                                            FluentBtn {
                                                label: modelData.isAdmin ? "Hacer estándar" : "Hacer admin"
                                                onClicked: {
                                                    var r = bridge.setOtherUserAdmin(modelData.username, !Boolean(modelData.isAdmin));
                                                    if (r === "ok") {
                                                        root.reloadAccountInfo();
                                                        root.refreshLiveState(false);
                                                        root.showToast("Tipo de cuenta actualizado para " + modelData.username);
                                                    } else {
                                                        root.showToast(r.replace(/^error:/, ""));
                                                    }
                                                }
                                            }
                                            FluentBtn {
                                                label: "Contraseña"
                                                onClicked: {
                                                    root.resetOtherPwErr = "";
                                                    root.resetOtherPwUser = String(modelData.username || "");
                                                    othPwIn.text = "";
                                                    othPwIn.forceActiveFocus();
                                                }
                                            }
                                            Rectangle {
                                                implicitWidth: 74; implicitHeight: 35; radius: 6
                                                color: delUH.containsMouse ? "#5a2323" : "#342424"
                                                border.color: delUH.containsMouse ? "#ef4444" : "#44ef4444"; border.width: 1
                                                Text { anchors.centerIn: parent; text: "Quitar"; color: "#fca5a5"; font.pixelSize: 12; font.weight: Font.Medium }
                                                MouseArea {
                                                    id: delUH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.delUserErr = "";
                                                        root.delUserRemoveHome = false;
                                                        root.delUserTarget = String(modelData.username || "");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                visible: (root.accData.otherUsers || []).length <= 1
                                width: parent.width; implicitHeight: singleUsrRow.implicitHeight + 24
                                radius: 7; color: "#222222"; border.color: "#18ffffff"; border.width: 1
                                RowLayout {
                                    id: singleUsrRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    WinSvg { width: 18; height: 18; iconFile: "fluent-info.svg"; opacity: 0.85 }
                                    Text {
                                        text: "Solo existe tu cuenta actual en este equipo. Pulsa «Agregar cuenta» arriba para crear un perfil independiente para otra persona."
                                        color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 7: HORA E IDIOMA (Win11 26H2 Hub + 3 Subpáginas Reales!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Hora e idioma"

                        // --- HUB PRINCIPAL DE HORA E IDIOMA ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === ""

                            // Live Clock Hero Banner (100% pure Spanish date!)
                            Rectangle {
                                width: parent.width; implicitHeight: clkHeroRow.implicitHeight + 34
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                RowLayout {
                                    id: clkHeroRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { text: root.clockTimeStr; color: "#ffffff"; font.pixelSize: 32; font.weight: Font.DemiBold }
                                        Text { text: root.clockDateStr; color: root.accentColor; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        Text {
                                            text: (root.tlData.timezone || "Local") + "  •  " + (root.tlData.locale || "es_ES.UTF-8") + "  •  Teclado " + (root.tlData.kbLayout || "ES")
                                            color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        label: "Sincronizar ahora"
                                        accent: true
                                        onClicked: {
                                            var r = bridge.syncClockNow();
                                            if (r === "ok") {
                                                root.reloadTimeLangInfo();
                                                root.showToast("Reloj sincronizado por NTP");
                                            } else {
                                                root.showToast(r.replace(/^error:/, ""));
                                            }
                                        }
                                    }
                                }
                            }

                            // 3 Official Windows 11 26H2 Subpages
                            HubNavCard {
                                iconFile: "fluent-refresh.svg"
                                title: "Fecha y hora"
                                subtitle: "Sincronización NTP, formato 12h/24h, segundos en barra, dual-boot RTC y zona horaria mundial"
                                badge: root.tlData.timezoneId || "Local"
                                onClicked: root.navigateTo("Hora e idioma", "Fecha y hora", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-document.svg"
                                title: "Idioma y región"
                                subtitle: "Idioma del sistema (LANG), regiones instaladas y formato de fecha y hora"
                                badge: root.tlData.locale || "es_ES.UTF-8"
                                onClicked: root.navigateTo("Hora e idioma", "Idioma y región", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-keyboard.svg"
                                title: "Escritura y teclado"
                                subtitle: "Distribuciones principal y secundaria, atajo de cambio, velocidad de repetición y Bloq Num"
                                badge: "Teclado " + (root.tlData.kbLayout || "ES")
                                onClicked: root.navigateTo("Hora e idioma", "Escritura y teclado", true)
                            }
                        }

                        // --- SUBPÁGINA 1: FECHA Y HORA ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Fecha y hora"

                            // Live Clock & NTP Status Bar
                            Rectangle {
                                width: parent.width; implicitHeight: dhHeroRow.implicitHeight + 28
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                RowLayout {
                                    id: dhHeroRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: root.clockTimeStr + "  —  " + root.clockDateStr; color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text {
                                            text: (root.tlData.synced ? "Sincronizado por NTP" : "Sincronización manual") + "  •  " + (root.tlData.timezone || "Local")
                                            color: root.tlData.synced ? "#86efac" : "#fbbf24"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                    FluentBtn {
                                        label: "Sincronizar ahora"
                                        accent: true
                                        onClicked: {
                                            var r = bridge.syncClockNow();
                                            if (r === "ok") {
                                                root.reloadTimeLangInfo();
                                                root.showToast("Hora sincronizada con servidores NTP");
                                            } else {
                                                root.showToast(r.replace(/^error:/, ""));
                                            }
                                        }
                                    }
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-refresh.svg"
                                title: "Establecer hora automáticamente (NTP)"
                                subtitle: root.tlData.ntpActive
                                          ? (root.tlData.synced ? "Reloj sincronizado automáticamente con systemd-timesyncd" : "Servicio NTP activado, esperando sincronización...")
                                          : "Desactivado: puedes fijar la fecha y hora manualmente abajo"
                                checked: Boolean(root.tlData.ntpActive)
                                onToggled: (v) => {
                                    if (bridge.setNtpEnabled(v)) {
                                        root.reloadTimeLangInfo();
                                        if (!v) {
                                            var zNow = root.getZonedNow();
                                            manDateIn.text = Qt.formatDate(zNow, "yyyy-MM-dd");
                                            manTimeIn.text = Qt.formatTime(zNow, "hh:mm:ss");
                                        }
                                        root.showToast(v ? "Sincronización NTP activada" : "Sincronización NTP desactivada");
                                    } else {
                                        root.showToast("Cambio de NTP cancelado");
                                    }
                                }
                            }

                            // Manual Date & Time Setter (visible when NTP is OFF!)
                            Rectangle {
                                visible: !Boolean(root.tlData.ntpActive)
                                width: parent.width; implicitHeight: manDtCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: Qt.alpha(root.accentColor, 0.35); border.width: 1
                                ColumnLayout {
                                    id: manDtCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    Text { text: "Establecer fecha y hora manualmente"; color: "#ffffff"; font.pixelSize: 14; font.weight: Font.Medium }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        Rectangle {
                                            Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                                            border.color: manDateIn.activeFocus ? root.accentColor : "#30ffffff"
                                            TextInput {
                                                id: manDateIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                                verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                                                Component.onCompleted: text = Qt.formatDate(new Date(), "yyyy-MM-dd")
                                            }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                                            border.color: manTimeIn.activeFocus ? root.accentColor : "#30ffffff"
                                            TextInput {
                                                id: manTimeIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                                verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                                                Component.onCompleted: text = Qt.formatTime(new Date(), "hh:mm:ss")
                                            }
                                        }
                                        FluentBtn {
                                            label: "Aplicar"
                                            accent: true
                                            onClicked: {
                                                root.manualDtErr = "";
                                                var r = bridge.setManualDateTime(manDateIn.text.trim() + " " + manTimeIn.text.trim());
                                                if (r === "ok") {
                                                    root.reloadTimeLangInfo();
                                                    root.showToast("Fecha y hora actualizadas");
                                                } else {
                                                    root.manualDtErr = r.replace(/^error:/, "");
                                                }
                                            }
                                        }
                                    }
                                    Text { visible: root.manualDtErr !== ""; text: root.manualDtErr; color: "#f87171"; font.pixelSize: 11 }
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-refresh.svg"
                                title: "Formato de reloj de 12 horas (AM / PM)"
                                subtitle: "Cambia el reloj de la barra de tareas y pantalla de bloqueo entre 24h y 12h"
                                checked: Boolean(root.cfg.clock12h)
                                onToggled: (v) => {
                                    root.updateCfg("clock12h", v);
                                    root.refreshDisplayedClock();
                                    root.showToast(v ? "Reloj en formato 12 horas" : "Reloj en formato 24 horas");
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-display.svg"
                                title: "Mostrar segundos en el reloj de la barra de tareas"
                                subtitle: "Muestra HH:MM:SS en vivo en la bandeja del sistema (como en Windows 11)"
                                checked: Boolean(root.cfg.clockShowSeconds)
                                onToggled: (v) => {
                                    root.updateCfg("clockShowSeconds", v);
                                    root.showToast(v ? "Segundos visibles en el reloj de la barra" : "Segundos ocultos en la barra");
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-shield.svg"
                                title: "Compatibilidad Dual-Boot con Windows (reloj RTC en hora local)"
                                subtitle: Boolean(root.tlData.localRtc)
                                          ? "Activo: el reloj de la placa base usa hora local (ideal si alternas entre Windows y X64 LIOS)."
                                          : "Estándar Linux (UTC): recomendado si solo usas Linux en este equipo."
                                checked: Boolean(root.tlData.localRtc)
                                onToggled: (v) => {
                                    var r = bridge.setLocalRtc(v);
                                    if (r === "ok") {
                                        root.reloadTimeLangInfo();
                                        root.showToast(v ? "RTC en hora local activado (Dual-Boot Windows)" : "RTC restaurado a UTC estándar");
                                    } else {
                                        root.showToast(r.replace(/^error:/, ""));
                                    }
                                }
                            }

                            // Universal Searchable Timezone Picker (Quick 9 + Live Search across all ~400 IANA zones!)
                            Rectangle {
                                width: parent.width; implicitHeight: tzPickCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: tzPickCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Zona horaria"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Text { text: root.tlData.timezone || "Local"; color: root.accentColor; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 35; radius: 5; clip: true
                                        color: tzSearchIn.activeFocus ? "#161616" : "#1f1f1f"
                                        border.color: tzSearchIn.activeFocus ? root.accentColor : "#28ffffff"; border.width: 1
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                            WinSvg { width: 14; height: 14; iconFile: "fluent-search.svg"; opacity: 0.8 }
                                            Item {
                                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                                Text { visible: tzSearchIn.text === ""; anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Buscar entre todas las zonas del mundo (ej. Tokyo, Caracas, Madrid, Costa Rica)..."; color: "#8e8e8e"; font.pixelSize: 12; elide: Text.ElideRight }
                                                TextInput {
                                                    id: tzSearchIn; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                                                    color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                                                    onTextChanged: {
                                                        root.tzSearchFilter = text;
                                                        if (text.trim() !== "" && root.allTimezones.length === 0) {
                                                            try { root.allTimezones = JSON.parse(bridge.getAllTimezonesJson()); } catch (e) {}
                                                        }
                                                    }
                                                }
                                            }
                                            WinSvg {
                                                visible: tzSearchIn.text !== ""; width: 12; height: 12; iconFile: "fluent-dismiss.svg"; opacity: 0.75
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { tzSearchIn.text = ""; root.tzSearchFilter = ""; } }
                                            }
                                        }
                                    }

                                    Flow {
                                        Layout.fillWidth: true; spacing: 6
                                        Repeater {
                                            model: root.tzSearchFilter.trim() !== ""
                                                   ? root.filteredTimezones
                                                   : ["America/Panama", "America/Bogota", "America/Mexico_City", "America/Lima", "America/Santiago", "America/Argentina/Buenos_Aires", "America/New_York", "Europe/Madrid", "UTC"]
                                            delegate: Rectangle {
                                                readonly property bool isCur: String(root.tlData.timezoneId || "") === String(modelData)
                                                width: tzLbl.implicitWidth + 20; height: 30; radius: 5
                                                color: isCur ? root.accentColor : (tzHov.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"; border.width: 1
                                                Text { id: tzLbl; anchors.centerIn: parent; text: String(modelData).replace(/_/g, " "); color: parent.isCur ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: tzHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (bridge.setSystemTimezone(String(modelData))) {
                                                            root.reloadTimeLangInfo();
                                                            root.refreshLiveState(false);
                                                            root.showToast("Zona horaria cambiada a " + String(modelData).replace(/_/g, " "));
                                                        } else {
                                                            root.showToast("Cambio de zona horaria cancelado");
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Text {
                                        visible: root.tzSearchFilter.trim() !== "" && root.filteredTimezones.length === 0
                                        text: "No se encontraron zonas horarias con «" + root.tzSearchFilter + "»."
                                        color: "#9a9a9a"; font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 2: IDIOMA Y REGIÓN ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Idioma y región"

                            // Regional Format Preview Card
                            Rectangle {
                                width: parent.width; implicitHeight: regPrevCol.implicitHeight + 28
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                ColumnLayout {
                                    id: regPrevCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 6
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 22; height: 22; iconFile: "fluent-document.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Idioma y región activos del sistema"; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                            Text { text: "Locale actual (/etc/locale.conf): " + (root.tlData.locale || "es_ES.UTF-8"); color: root.accentColor; font.pixelSize: 12; font.weight: Font.Medium }
                                        }
                                    }
                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1cffffff"; Layout.topMargin: 4; Layout.bottomMargin: 4 }
                                    RowLayout { Layout.fillWidth: true; Text { text: "Fecha larga"; color: "#9e9e9e"; font.pixelSize: 12; Layout.preferredWidth: 140 } Text { text: root.clockDateStr; color: "#ececec"; font.pixelSize: 12; Layout.fillWidth: true } }
                                    RowLayout { Layout.fillWidth: true; Text { text: "Fecha corta"; color: "#9e9e9e"; font.pixelSize: 12; Layout.preferredWidth: 140 } Text { text: Qt.formatDate(root.getZonedNow(), "dd/MM/yyyy"); color: "#ececec"; font.pixelSize: 12; Layout.fillWidth: true } }
                                    RowLayout { Layout.fillWidth: true; Text { text: "Hora actual"; color: "#9e9e9e"; font.pixelSize: 12; Layout.preferredWidth: 140 } Text { text: root.clockTimeStr; color: "#ececec"; font.pixelSize: 12; Layout.fillWidth: true } }
                                }
                            }

                            // Interactive System Locale Picker (localectl + auto locale-gen!)
                            Rectangle {
                                width: parent.width; implicitHeight: locPickCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: locPickCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Cambiar idioma y formato regional (LANG)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                        Text { text: "Si una región aún no está generada, se habilitará automáticamente con locale-gen. El cambio completo se aplica al volver a iniciar sesión."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    Repeater {
                                        model: [
                                            { code: "es_PA.UTF-8", label: "Español (Panamá)" },
                                            { code: "es_ES.UTF-8", label: "Español (España)" },
                                            { code: "es_MX.UTF-8", label: "Español (México)" },
                                            { code: "es_CO.UTF-8", label: "Español (Colombia)" },
                                            { code: "es_AR.UTF-8", label: "Español (Argentina)" },
                                            { code: "es_CL.UTF-8", label: "Español (Chile)" },
                                            { code: "es_PE.UTF-8", label: "Español (Perú)" },
                                            { code: "en_US.UTF-8", label: "English (United States)" },
                                            { code: "pt_BR.UTF-8", label: "Português (Brasil)" },
                                            { code: "fr_FR.UTF-8", label: "Français (France)" },
                                            { code: "de_DE.UTF-8", label: "Deutsch (Deutschland)" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: String(root.tlData.locale || "").toLowerCase() === modelData.code.toLowerCase()
                                            readonly property bool isInst: (root.tlData.installedLocales || []).indexOf(modelData.code) !== -1
                                            Layout.fillWidth: true; height: 46; radius: 6
                                            color: isCur ? Qt.alpha(root.accentColor, 0.14) : (locH.containsMouse ? "#303030" : "#202020")
                                            border.color: isCur ? root.accentColor : "#1effffff"; border.width: 1
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10
                                                Text { text: modelData.label; color: "#f2f2f2"; font.pixelSize: 13; font.weight: parent.parent.isCur ? Font.DemiBold : Font.Normal; Layout.fillWidth: true }
                                                Text { text: modelData.code; color: "#9a9a9a"; font.pixelSize: 11 }
                                                Rectangle {
                                                    visible: parent.parent.isCur || parent.parent.isInst
                                                    width: lStT.implicitWidth + 14; height: 20; radius: 4
                                                    color: parent.parent.isCur ? root.accentColor : "#2222c55e"
                                                    Text {
                                                        id: lStT; anchors.centerIn: parent
                                                        text: parent.parent.parent.isCur ? "Activo" : "Instalado"
                                                        color: parent.parent.parent.isCur ? "#000000" : "#86efac"
                                                        font.pixelSize: 10; font.weight: Font.DemiBold
                                                    }
                                                }
                                            }
                                            MouseArea {
                                                id: locH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (parent.isCur) return;
                                                    var r = bridge.setSystemLocale(modelData.code);
                                                    if (r === "ok") {
                                                        root.reloadTimeLangInfo();
                                                        root.showToast("Idioma cambiado a " + modelData.label + " (reinicia sesión)");
                                                    } else {
                                                        root.showToast(r.replace(/^error:/, ""));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 3: ESCRITURA Y TECLADO ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Escritura y teclado"

                            // Primary & Secondary Layout + Toggle Shortcut
                            Rectangle {
                                width: parent.width; implicitHeight: kbCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: kbCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 20; height: 20; iconFile: "fluent-keyboard.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Distribución de teclado principal"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Aplica al instante en Wayland (labwc) y sincroniza el indicador de la barra de tareas (haz clic en él para alternar)."; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { code: "es",    label: "Español (España)" },
                                                { code: "latam", label: "Español (Latinoamérica)" },
                                                { code: "us",    label: "Inglés (EE. UU.)" },
                                                { code: "br",    label: "Portugués (Brasil)" },
                                                { code: "fr",    label: "Francés" },
                                                { code: "de",    label: "Alemán" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: String(root.tlData.kbPrimary || "es") === modelData.code
                                                width: kbTxt.implicitWidth + 24; height: 32; radius: 5
                                                color: isCur ? root.accentColor : (kbHov.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"; border.width: 1
                                                Text { id: kbTxt; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: kbHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        var sec = String(root.tlData.kbSecondary || "us");
                                                        if (sec === modelData.code) sec = (modelData.code === "us" ? "es" : "us");
                                                        if (bridge.setKeyboardConfig(modelData.code, sec, String(root.tlData.kbToggleOpt || "grp:alt_shift_toggle"))) {
                                                            root.cfgWriteGuardUntil = Date.now() + 2000;
                                                            root.reloadTimeLangInfo();
                                                            root.showToast("Teclado principal: " + modelData.label);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1cffffff" }

                                    Text { text: "Distribución secundaria para alternar rápidamente"; color: "#dcdcdc"; font.pixelSize: 13; font.weight: Font.Medium }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { code: "none",  label: "Ninguna" },
                                                { code: "us",    label: "Inglés (EE. UU.)" },
                                                { code: "es",    label: "Español (España)" },
                                                { code: "latam", label: "Español (LATAM)" },
                                                { code: "br",    label: "Portugués (BR)" },
                                                { code: "fr",    label: "Francés" },
                                                { code: "de",    label: "Alemán" }
                                            ]
                                            delegate: Rectangle {
                                                visible: modelData.code === "none" || modelData.code !== String(root.tlData.kbPrimary || "es")
                                                readonly property bool isCur: String(root.tlData.kbSecondary || "us") === modelData.code
                                                width: kbsTxt.implicitWidth + 20; height: 30; radius: 5
                                                color: isCur ? root.accentColor : (kbsH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"; border.width: 1
                                                Text { id: kbsTxt; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: kbsH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (bridge.setKeyboardConfig(String(root.tlData.kbPrimary || "es"), modelData.code, String(root.tlData.kbToggleOpt || "grp:alt_shift_toggle"))) {
                                                            root.reloadTimeLangInfo();
                                                            root.showToast("Teclado secundario: " + modelData.label);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1cffffff" }

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        Text { text: "Atajo para alternar teclado:"; color: "#dcdcdc"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Repeater {
                                            model: [
                                                { id: "grp:alt_shift_toggle",  label: "Alt + Shift" },
                                                { id: "grp:ctrl_shift_toggle", label: "Ctrl + Shift" },
                                                { id: "none",                  label: "Desactivado" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: String(root.tlData.kbToggleOpt || "grp:alt_shift_toggle") === modelData.id
                                                width: kboT.implicitWidth + 20; height: 30; radius: 5
                                                color: isCur ? root.accentColor : (kboH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"; border.width: 1
                                                Text { id: kboT; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: kboH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (bridge.setKeyboardConfig(String(root.tlData.kbPrimary || "es"), String(root.tlData.kbSecondary || "us"), modelData.id)) {
                                                            root.reloadTimeLangInfo();
                                                            root.showToast("Atajo de teclado: " + modelData.label);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Keyboard Repeat Rate, Repeat Delay & Live Typing Test Box (labwc <keyboard>!)
                            Rectangle {
                                width: parent.width; implicitHeight: kbRepCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: kbRepCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                    Text { text: "Repetición de caracteres (labwc)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Velocidad de repetición"; color: "#e8e8e8"; font.pixelSize: 13; Layout.fillWidth: true }
                                            Text { text: root.localKbRate + " teclas por segundo (predeterminado: 25)"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true }
                                        }
                                        SettingsSlider {
                                            Layout.preferredWidth: 220; Layout.minimumWidth: 220; Layout.maximumWidth: 220
                                            from: 15; to: 60; value: root.localKbRate
                                            onMovedValue: (v) => { root.kbRateDragging = true; root.localKbRate = Math.round(v); }
                                            onReleasedValue: (v) => {
                                                root.kbRateDragging = false;
                                                root.localKbRate = Math.round(v);
                                                if (bridge.setKeyboardTyping(root.localKbRate, root.localKbDelay, Boolean(root.tlData.numlock))) {
                                                    root.reloadTimeLangInfo();
                                                    root.showToast("Velocidad de repetición: " + root.localKbRate + " teclas/s");
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Retraso antes de repetir"; color: "#e8e8e8"; font.pixelSize: 13; Layout.fillWidth: true }
                                            Text { text: root.localKbDelay + " ms (predeterminado: 600 ms)"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true }
                                        }
                                        SettingsSlider {
                                            Layout.preferredWidth: 220; Layout.minimumWidth: 220; Layout.maximumWidth: 220
                                            from: 200; to: 1000; value: root.localKbDelay
                                            onMovedValue: (v) => { root.kbDelayDragging = true; root.localKbDelay = Math.round(v / 25) * 25; }
                                            onReleasedValue: (v) => {
                                                root.kbDelayDragging = false;
                                                root.localKbDelay = Math.round(v / 25) * 25;
                                                if (bridge.setKeyboardTyping(root.localKbRate, root.localKbDelay, Boolean(root.tlData.numlock))) {
                                                    root.reloadTimeLangInfo();
                                                    root.showToast("Retraso de repetición: " + root.localKbDelay + " ms");
                                                }
                                            }
                                        }
                                    }

                                    // Interactive Typing Test Field
                                    Rectangle {
                                        Layout.fillWidth: true; height: 36; radius: 5; color: "#171717"
                                        border.color: kbTestIn.activeFocus ? root.accentColor : "#2cffffff"; border.width: 1
                                        Text { visible: kbTestIn.text === ""; anchors.fill: parent; anchors.leftMargin: 10; verticalAlignment: Text.AlignVCenter; text: "Haz clic aquí y mantén pulsada una tecla para probar la distribución (ñ, @, #) y velocidad..."; color: "#888888"; font.pixelSize: 12; elide: Text.ElideRight }
                                        TextInput { id: kbTestIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; selectByMouse: true; clip: true }
                                    }
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-keyboard.svg"
                                title: "Activar Bloq Num automáticamente al iniciar (Num Lock)"
                                subtitle: "Enciende automáticamente el bloque numérico al iniciar sesión en teclados con pad numérico"
                                checked: Boolean(root.tlData.numlock)
                                onToggled: (v) => {
                                    if (bridge.setKeyboardTyping(root.localKbRate, root.localKbDelay, v)) {
                                        root.reloadTimeLangInfo();
                                        root.showToast(v ? "Bloq Num activado al iniciar" : "Bloq Num desactivado al iniciar");
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 8: JUEGOS (Win11 26H2 Hub + 3 Subpáginas + Stack X64 & labwc!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Juegos"

                        // --- HUB PRINCIPAL DE JUEGOS ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === ""

                            // Hero Banner del Motor Gaming X64 (sin duplicar X64 Hello)
                            Rectangle {
                                width: parent.width; implicitHeight: gmHeroCol.implicitHeight + 34
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                ColumnLayout {
                                    id: gmHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 14
                                        Rectangle {
                                            width: 48; height: 48; radius: 10
                                            Layout.preferredWidth: 48; Layout.preferredHeight: 48
                                            color: root.hwState.powerProfile === "performance" ? Qt.alpha(root.accentColor, 0.18) : "#2e2e2e"
                                            border.color: root.hwState.powerProfile === "performance" ? Qt.alpha(root.accentColor, 0.45) : "#24ffffff"
                                            WinSvg { anchors.centerIn: parent; width: 24; height: 24; iconFile: "fluent-games.svg" }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text {
                                                text: root.hwState.powerProfile === "performance" ? "Modo Juego X64 — Activo" : "Motor Gaming X64 LIOS"
                                                color: "#ffffff"; font.pixelSize: 17; font.weight: Font.DemiBold
                                                Layout.fillWidth: true; elide: Text.ElideRight
                                            }
                                            Text {
                                                text: "Optimización de baja latencia 1% Low  •  VRR: " + (root.gmData.adaptiveSync === "no" ? "Desactivado" : (root.gmData.adaptiveSync === "fullscreen" ? "Pantalla completa" : "Activo"))
                                                      + "  •  Tearing: " + (root.gmData.allowTearing === "no" ? "Desactivado" : "Activo")
                                                color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                        FluentBtn {
                                            visible: Boolean(root.gmData.hasX64Hello)
                                            label: "X64 Hello Gaming"
                                            accent: true
                                            onClicked: bridge.launchRealApp("x64-hello --gaming")
                                        }
                                    }

                                    // 5 Live Stack Status Pills
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { label: "Planificador: " + (root.gmData.sched || root.sysInfo.sched || "BORE"), ok: true },
                                                { label: "FalconD", ok: Boolean(root.gmData.falcond) },
                                                { label: "dmemcg VRAM", ok: Boolean(root.gmData.dmemcg) },
                                                { label: "Ananicy-cpp", ok: Boolean(root.gmData.ananicy) },
                                                { label: "NTSYNC", ok: Boolean(root.gmData.ntsync) }
                                            ]
                                            delegate: Rectangle {
                                                width: gmPillTxt.implicitWidth + 20; height: 27; radius: 5
                                                color: modelData.ok ? "#224ade80" : "#22ffffff"
                                                border.color: modelData.ok ? "#554ade80" : "#22ffffff"
                                                Text { id: gmPillTxt; anchors.centerIn: parent; text: modelData.label; color: modelData.ok ? "#4ade80" : "#9e9e9e"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            }
                                        }
                                    }
                                }
                            }

                            // 3 Official Windows 11 26H2 Gaming Subpages
                            HubNavCard {
                                iconFile: "fluent-games.svg"
                                title: "Modo de juego"
                                subtitle: "Perfil de rendimiento máximo CPU, No molestar automático, VRR y tearing de baja latencia"
                                badge: root.hwState.powerProfile === "performance" ? "Activado" : "Equilibrado"
                                onClicked: root.navigateTo("Juegos", "Modo de juego", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-image.svg"
                                title: "Capturas"
                                subtitle: "Carpeta de recortes (Win+Shift+S), captura completa, portapapeles, notificaciones y OBS Studio"
                                badge: (root.gmData.screenshotCount || 0) + ((root.gmData.screenshotCount || 0) === 1 ? " captura" : " capturas")
                                onClicked: root.navigateTo("Juegos", "Capturas", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-apps-list.svg"
                                title: "Bibliotecas y mandos"
                                subtitle: "Gamepads conectados, Steam, Heroic, Lutris, Goverlay, MangoHud y Gamescope"
                                badge: {
                                    var gps = (root.gmData.gamepads || []).length;
                                    return gps > 0 ? (gps + (gps === 1 ? " mando" : " mandos")) : "Ver lanzadores";
                                }
                                onClicked: root.navigateTo("Juegos", "Bibliotecas y mandos", true)
                            }
                        }

                        // --- SUBPÁGINA 1: MODO DE JUEGO ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Modo de juego"

                            ToggleCard {
                                iconFile: "fluent-games.svg"
                                title: "Modo Juego X64 (Alto rendimiento)"
                                subtitle: "Activa el perfil de rendimiento máximo en CPU y prioriza fotogramas 1% Low sin latencia"
                                checked: root.hwState.powerProfile === "performance"
                                onToggled: (v) => {
                                    var prof = v ? "performance" : "balanced";
                                    root.lockedPowerProfile = prof;
                                    root.powerProfileLockUntil = Date.now() + 1600;
                                    var copy = Object.assign({}, root.hwState);
                                    copy.powerProfile = prof;
                                    copy.cpuGovernor = v ? "Rendimiento" : "Equilibrado";
                                    root.hwState = copy;
                                    root.cfgWriteGuardUntil = Date.now() + 2000;
                                    try {
                                        var gmRes = JSON.parse(bridge.setGameModeActive(v));
                                        if (gmRes && gmRes.doNotDisturb !== undefined) {
                                            var c2 = Object.assign({}, root.cfg);
                                            c2.doNotDisturb = Boolean(gmRes.doNotDisturb);
                                            root.cfg = c2;
                                        }
                                    } catch (e) {}
                                    powerModeSyncTimer.restart();
                                    root.showToast(v ? "Modo Juego X64 activado" : "Perfil equilibrado restaurado");
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-bell-snooze.svg"
                                title: "Silenciar notificaciones automáticamente en Modo Juego"
                                subtitle: "Activa No molestar al encender Modo Juego X64 y restaura tu estado anterior al apagarlo"
                                checked: Boolean(root.cfg.gameModeAutoDnd)
                                onToggled: (v) => {
                                    root.updateCfg("gameModeAutoDnd", v);
                                    root.showToast(v ? "No molestar automático activado en Modo Juego" : "Notificaciones sin cambios en Modo Juego");
                                }
                            }

                            // Real labwc <core> Video Latency Controls (VRR + Tearing!)
                            Rectangle {
                                width: parent.width; implicitHeight: gmCoreCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: gmCoreCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 20; height: 20; iconFile: "fluent-display.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Optimización de vídeo Wayland (compositor labwc)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text { text: "Ajustes directos de frecuencia variable (VRR) y latencia mínima de entrada en juegos a pantalla completa"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Sincronización adaptativa (VRR / FreeSync / G-Sync)"; color: "#e8e8e8"; font.pixelSize: 13; Layout.fillWidth: true }
                                            Text { text: "Adapta los Hz del monitor a los FPS del juego sin tirones"; color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true }
                                        }
                                        Repeater {
                                            model: [
                                                { id: "yes",        label: "Siempre" },
                                                { id: "fullscreen", label: "Pantalla completa" },
                                                { id: "no",         label: "Desactivado" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: String(root.gmData.adaptiveSync || "yes") === modelData.id
                                                width: vrrT.implicitWidth + 20; height: 30; radius: 5
                                                color: isCur ? root.accentColor : (vrrH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"; border.width: 1
                                                Text { id: vrrT; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: vrrH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (bridge.setLabwcGamingCore(modelData.id, String(root.gmData.allowTearing || "no"))) {
                                                            root.reloadGamingInfo();
                                                            root.showToast("VRR: " + modelData.label);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; height: 1; color: "#1cffffff" }

                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Permitir tearing de baja latencia"; color: "#e8e8e8"; font.pixelSize: 13; Layout.fillWidth: true }
                                            Text { text: "Reduce el retardo de entrada en juegos competitivos omitiendo VSync"; color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true }
                                        }
                                        Repeater {
                                            model: [
                                                { id: "no",               label: "Desactivado" },
                                                { id: "fullscreen",       label: "Pantalla completa" },
                                                { id: "fullscreenForced", label: "Forzado" }
                                            ]
                                            delegate: Rectangle {
                                                readonly property bool isCur: String(root.gmData.allowTearing || "no") === modelData.id
                                                width: tearT.implicitWidth + 20; height: 30; radius: 5
                                                color: isCur ? root.accentColor : (tearH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? root.accentColor : "#22ffffff"; border.width: 1
                                                Text { id: tearT; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                                MouseArea {
                                                    id: tearH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (bridge.setLabwcGamingCore(String(root.gmData.adaptiveSync || "yes"), modelData.id)) {
                                                            root.reloadGamingInfo();
                                                            root.showToast("Tearing de baja latencia: " + modelData.label);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Related Tools (Direct links to X64 Hello --gaming / --scheduler + Task Manager!)
                            Rectangle {
                                width: parent.width; implicitHeight: gmRelCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: gmRelCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    Text { text: "Herramientas avanzadas de rendimiento"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn { visible: Boolean(root.gmData.hasX64Hello); label: "X64 Hello — Gaming Toolkit Pro"; accent: true; onClicked: bridge.launchRealApp("x64-hello --gaming") }
                                        FluentBtn { visible: Boolean(root.gmData.hasX64Hello); label: "Planificadores SCX (X64 Hello)"; onClicked: bridge.launchRealApp("x64-hello --scheduler") }
                                        FluentBtn { label: "Administrador de tareas (Multi-GPU)"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app taskmgr performance") }
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 2: CAPTURAS ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Capturas"

                            // Captures Folder Card
                            Rectangle {
                                width: parent.width; implicitHeight: capDirCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: capDirCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 22; height: 22; iconFile: "fluent-image.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            RowLayout {
                                                spacing: 8
                                                Text { text: "Ubicación de capturas"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                                Rectangle {
                                                    width: capCntT.implicitWidth + 14; height: 20; radius: 4
                                                    color: Qt.alpha(root.accentColor, 0.16)
                                                    Text { id: capCntT; anchors.centerIn: parent; text: (root.gmData.screenshotCount || 0) + ((root.gmData.screenshotCount || 0) === 1 ? " archivo" : " archivos"); color: root.accentColor; font.pixelSize: 10; font.weight: Font.DemiBold }
                                                }
                                            }
                                            Text { text: root.gmData.screenshotDir || "~/Imágenes/Capturas"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideMiddle }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn {
                                            label: "Abrir carpeta"
                                            accent: true
                                            onClicked: bridge.openScreenshotDir()
                                        }
                                        FluentBtn {
                                            label: "Cambiar carpeta..."
                                            onClicked: {
                                                var chosen = bridge.pickScreenshotDir();
                                                if (chosen !== "") {
                                                    root.cfgWriteGuardUntil = Date.now() + 2500;
                                                    root.reloadGamingInfo();
                                                    root.showToast("Carpeta de capturas actualizada");
                                                }
                                            }
                                        }
                                        FluentBtn {
                                            visible: String(root.cfg.screenshotDir || "") !== ""
                                            label: "Restablecer predeterminada"
                                            onClicked: {
                                                root.cfgWriteGuardUntil = Date.now() + 2500;
                                                bridge.resetScreenshotDir();
                                                var c = Object.assign({}, root.cfg); c.screenshotDir = ""; root.cfg = c;
                                                root.reloadGamingInfo();
                                                root.showToast("Carpeta de capturas restablecida");
                                            }
                                        }
                                    }
                                }
                            }

                            // Quick Capture Triggers Card
                            Rectangle {
                                width: parent.width; implicitHeight: capActCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: capActCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Hacer una captura ahora"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                        Text { text: "Atajos globales activos en todo el escritorio: Win + Shift + S o tecla Impr Pant"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn { label: "Capturar área (Win + Shift + S)"; accent: true; onClicked: bridge.runCtlAction("screenshot") }
                                        FluentBtn {
                                            label: "Capturar pantalla completa"
                                            onClicked: {
                                                bridge.runCtlAction("screenshot-full");
                                                root.showToast("Captura de pantalla completa guardada");
                                                capReloadT.restart();
                                            }
                                        }
                                    }
                                }
                            }

                            Timer { id: capReloadT; interval: 900; repeat: false; onTriggered: root.reloadGamingInfo() }

                            ToggleCard {
                                iconFile: "fluent-copy.svg"
                                title: "Copiar captura automáticamente al portapapeles"
                                subtitle: "Permite pegar tus capturas al instante con Ctrl + V en chats o editores"
                                checked: root.cfg.screenshotCopyClipboard !== false
                                onToggled: (v) => {
                                    root.updateCfg("screenshotCopyClipboard", v);
                                    root.showToast(v ? "Copiado automático al portapapeles activado" : "Copiado al portapapeles desactivado");
                                }
                            }

                            ToggleCard {
                                iconFile: "fluent-bell.svg"
                                title: "Mostrar notificación al guardar una captura"
                                subtitle: "Avisa con la ruta exacta cada vez que se guarda un recorte o captura"
                                checked: root.cfg.screenshotNotify !== false
                                onToggled: (v) => {
                                    root.updateCfg("screenshotNotify", v);
                                    root.showToast(v ? "Notificaciones de captura activadas" : "Notificaciones de captura desactivadas");
                                }
                            }

                            // OBS Studio Card
                            Rectangle {
                                width: parent.width; implicitHeight: obsRow.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: obsRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
                                    WinSvg { width: 26; height: 26; iconUrl: (root.gmData.appIcons && root.gmData.appIcons.obs) ? root.gmData.appIcons.obs : ""; iconFile: "fluent-play-filled.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Grabación y streaming de partidas (OBS Studio)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                        Text {
                                            text: Boolean(root.gmData.hasObs)
                                                  ? "OBS Studio detectado con soporte nativo PipeWire / Wayland para grabar partidas en alta calidad"
                                                  : "Instala OBS Studio desde Tienda Shelly para grabar vídeo y transmitir en vivo"
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        label: Boolean(root.gmData.hasObs) ? "Abrir OBS Studio" : "Tienda Shelly"
                                        onClicked: bridge.launchRealApp(Boolean(root.gmData.hasObs) ? "obs" : "/usr/bin/shelly-ui")
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 3: BIBLIOTECAS Y MANDOS ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Bibliotecas y mandos"

                            // Connected Gamepads Card (Real /sys/class/input/js* detection!)
                            Rectangle {
                                width: parent.width; implicitHeight: gpCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: gpCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 22; height: 22; iconFile: "fluent-games.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Mandos y controles conectados"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Text {
                                                text: (root.gmData.gamepads || []).length > 0
                                                      ? ((root.gmData.gamepads || []).length + " control(es) detectado(s) en tiempo real")
                                                      : "Ningún mando conectado actualmente — conecta un control Xbox, PlayStation o Switch por USB o Bluetooth"
                                                color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                        FluentBtn { label: "Actualizar"; onClicked: { root.reloadGamingInfo(); root.showToast("Mandos escaneados"); } }
                                        FluentBtn { label: "Bluetooth"; onClicked: root.navigateTo("Bluetooth y dispositivos", "", true) }
                                    }
                                    Repeater {
                                        model: root.gmData.gamepads || []
                                        delegate: Rectangle {
                                            Layout.fillWidth: true; height: 42; radius: 6; color: "#202020"; border.color: "#224ade80"
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                                WinSvg { width: 18; height: 18; iconFile: "fluent-games.svg" }
                                                Text { text: modelData.name || "Mando"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: "/dev/input/" + (modelData.id || "js0"); color: "#86efac"; font.pixelSize: 11 }
                                            }
                                        }
                                    }
                                }
                            }

                            // Overlays & Micro-compositors Status Strip
                            Rectangle {
                                width: parent.width; implicitHeight: ovCol.implicitHeight + 24
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: ovCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8
                                    Text { text: "Capas de rendimiento y compatibilidad detectadas"; color: "#d8d8d8"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { label: "MangoHud (Overlay FPS)", ok: Boolean(root.gmData.hasMangohud) },
                                                { label: "Goverlay",               ok: Boolean(root.gmData.hasGoverlay) },
                                                { label: "Gamescope",              ok: Boolean(root.gmData.hasGamescope) },
                                                { label: "NTSYNC Kernel",          ok: Boolean(root.gmData.ntsync) }
                                            ]
                                            delegate: Rectangle {
                                                width: ovT.implicitWidth + 20; height: 27; radius: 5
                                                color: modelData.ok ? "#224ade80" : "#22ffffff"
                                                border.color: modelData.ok ? "#554ade80" : "#22ffffff"
                                                Text { id: ovT; anchors.centerIn: parent; text: modelData.label; color: modelData.ok ? "#4ade80" : "#9e9e9e"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            }
                                        }
                                    }
                                }
                            }

                            Text { text: "Lanzadores y utilidades instaladas"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                            Repeater {
                                model: [
                                    { key: "steam",    icon: "steam.svg",             title: "Steam",                   desc: "Biblioteca de juegos con Proton y aceleración NTSYNC activa", cmd: "steam",    show: Boolean(root.gmData.hasSteam) },
                                    { key: "heroic",   icon: "fluent-games.svg",      title: "Heroic Games Launcher",   desc: "Epic Games, GOG y Amazon Games en Linux",                     cmd: "heroic",   show: Boolean(root.gmData.hasHeroic) },
                                    { key: "lutris",   icon: "fluent-games.svg",      title: "Lutris",                  desc: "Gestor universal de bibliotecas gaming y emuladores",         cmd: "lutris",   show: Boolean(root.gmData.hasLutris) },
                                    { key: "goverlay", icon: "fluent-display.svg",    title: "Goverlay (MangoHud)",     desc: "Configura tu contador de FPS, temperaturas y frametime",      cmd: "goverlay", show: Boolean(root.gmData.hasGoverlay) },
                                    { key: "obs",      icon: "fluent-play-filled.svg",title: "OBS Studio",              desc: "Grabación y transmisión profesional de partidas",             cmd: "obs",      show: Boolean(root.gmData.hasObs) }
                                ]
                                delegate: Rectangle {
                                    visible: Boolean(modelData.show)
                                    width: parent.width; implicitHeight: gmRow.implicitHeight + 24
                                    radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: gmRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 14
                                        WinSvg {
                                            width: 28; height: 28
                                            iconUrl: (root.gmData.appIcons && root.gmData.appIcons[modelData.key]) ? root.gmData.appIcons[modelData.key] : ""
                                            iconFile: modelData.icon
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: modelData.title; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: modelData.desc; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        FluentBtn { label: "Abrir"; onClicked: bridge.launchRealApp(modelData.cmd) }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width; implicitHeight: gmMoreRow.implicitHeight + 24
                                radius: 7; color: "#222222"; border.color: "#18ffffff"; border.width: 1
                                RowLayout {
                                    id: gmMoreRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "x64lios.png" }
                                    Text { text: "¿Buscas instalar Proton-GE, emuladores, Wine o drivers gaming adicionales?"; color: "#bcbcbc"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    FluentBtn { label: "X64 Hello Gaming"; accent: true; onClicked: bridge.launchRealApp("x64-hello --gaming") }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 9: ACTUALIZACIÓN DEL SISTEMA (Win11 26H2 Hub + 3 Subpáginas!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Actualización del sistema"

                        // --- HUB PRINCIPAL DE ACTUALIZACIÓN ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === ""

                            // Reboot Recommended Banner (Real Arch /usr/lib/modules/$(uname -r) check!)
                            Rectangle {
                                visible: Boolean(root.updData.rebootRequired)
                                width: parent.width; implicitHeight: rebRow.implicitHeight + 24
                                radius: 7; color: "#28eab308"; border.color: "#55eab308"; border.width: 1
                                RowLayout {
                                    id: rebRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-power.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Reinicio recomendado para activar el nuevo kernel"; color: "#fde047"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { text: "El kernel en ejecución (" + (root.updData.runningKernel || root.sysInfo.kernel) + ") fue actualizado. Reinicia cuando puedas para cargar los módulos nuevos."; color: "#f2e7b5"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    FluentBtn { label: "Reiniciar ahora"; accent: true; onClicked: root.powerConfirmAction = "reboot" }
                                }
                            }

                            // Authentic Windows Update 26H2 Honest 4-State Hero Banner
                            Rectangle {
                                width: parent.width; implicitHeight: updHeroCol.implicitHeight + 34
                                radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                                ColumnLayout {
                                    id: updHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 16
                                        WinSvg { width: 42; height: 42; iconFile: "update.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text {
                                                text: root.checkingUpdates
                                                      ? "Buscando actualizaciones..."
                                                      : (root.updateResult.error && String(root.updateResult.error) !== ""
                                                         ? "No se pudo comprobar las actualizaciones"
                                                         : (root.updateResult.count > 0
                                                            ? (root.updateResult.count + (root.updateResult.count === 1 ? " actualización disponible" : " actualizaciones disponibles"))
                                                            : (root.updateResult.count === 0
                                                               ? "Todo está actualizado"
                                                               : "Listo para buscar actualizaciones")))
                                                color: (root.updateResult.error && String(root.updateResult.error) !== "") ? "#fca5a5"
                                                       : (root.updateResult.count > 0 ? "#fbbf24"
                                                          : (root.updateResult.count === 0 ? "#86efac" : "#ffffff"))
                                                font.pixelSize: 18; font.weight: Font.DemiBold
                                                Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                            Text {
                                                text: (root.updateResult.error && String(root.updateResult.error) !== "")
                                                      ? String(root.updateResult.error)
                                                      : ("Kernel " + (root.updData.runningKernel || root.sysInfo.kernel)
                                                         + "  •  " + (root.updData.pkgCount || root.extData.pkgCount || 0) + " paquetes"
                                                         + "  •  " + (root.updData.repos ? root.updData.repos.length : 0) + " repositorios"
                                                         + (root.updateResult.checkedAt
                                                            ? ("  •  Última comprobación: " + root.updateResult.checkedAt)
                                                            : (root.updData.lastUpgradeDate ? ("  •  Última actualización: " + root.updData.lastUpgradeDate) : "")))
                                                color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                            }
                                        }
                                        FluentBtn {
                                            label: root.checkingUpdates ? "Comprobando..." : "Buscar actualizaciones"
                                            accent: true
                                            onClicked: root.runUpdateCheck()
                                        }
                                    }

                                    // Animated checking bar
                                    Rectangle {
                                        visible: root.checkingUpdates
                                        Layout.fillWidth: true; height: 4; radius: 2; color: "#343434"; clip: true
                                        Rectangle {
                                            id: updSweepBar; width: parent.width * 0.32; height: parent.height; radius: 2; color: root.accentColor
                                            SequentialAnimation on x {
                                                running: root.checkingUpdates; loops: Animation.Infinite
                                                NumberAnimation { from: -updSweepBar.width; to: updSweepBar.parent ? updSweepBar.parent.width : 600; duration: 1100; easing.type: Easing.InOutQuad }
                                            }
                                        }
                                    }

                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn { visible: Boolean(root.updData.hasX64Update); label: "Abrir X64 Update (Instalador oficial)"; onClicked: bridge.launchRealApp("x64-update") }
                                        FluentBtn { label: "Abrir Tienda Shelly"; onClicked: bridge.launchRealApp("/usr/bin/shelly-ui") }
                                    }
                                }
                            }

                            // Pending Packages Preview Card (Pacman + Flatpak!)
                            Rectangle {
                                visible: root.updateResult.count > 0
                                width: parent.width; implicitHeight: pendCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#55fbbf24"; border.width: 1
                                ColumnLayout {
                                    id: pendCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 8
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        Text {
                                            text: {
                                                var parts = [];
                                                if ((root.updateResult.pacmanCount || 0) > 0) parts.push(root.updateResult.pacmanCount + " Pacman");
                                                if ((root.updateResult.aurCount || 0) > 0) parts.push(root.updateResult.aurCount + " AUR");
                                                if ((root.updateResult.flatpakCount || 0) > 0) parts.push(root.updateResult.flatpakCount + " Flatpak");
                                                return "Paquetes pendientes" + (parts.length > 0 ? (" (" + parts.join(", ") + ")") : "");
                                            }
                                            color: "#fbbf24"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true
                                        }
                                        FluentBtn {
                                            visible: Boolean(root.updData.hasX64Update)
                                            label: "Instalar con X64 Update"
                                            accent: true
                                            onClicked: bridge.launchRealApp("x64-update")
                                        }
                                    }
                                    Repeater {
                                        model: (root.updateResult.packages || []).slice(0, 10)
                                        delegate: Text { text: "•  " + modelData; color: "#e4e4e4"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    Text {
                                        readonly property int totalPend: Math.max(root.updateResult.count || 0, (root.updateResult.packages || []).length)
                                        visible: totalPend > 10
                                        text: "... y " + (totalPend - 10) + " paquete(s) más. Abre X64 Update para ver e instalar todo con snapshot Btrfs automático."
                                        color: "#a8a8a8"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            // 3 Official Windows 11 26H2 Update Subpages
                            HubNavCard {
                                iconFile: "fluent-document.svg"
                                title: "Historial de actualizaciones"
                                subtitle: "Registro real de paquetes actualizados, instalados y eliminados desde /var/log/pacman.log"
                                badge: (root.updData.history || []).length + " eventos"
                                onClicked: root.navigateTo("Actualización del sistema", "Historial de actualizaciones", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-settings.svg"
                                title: "Opciones avanzadas"
                                subtitle: "Limpieza automática de caché Pacman, SSD TRIM semanal, repositorios activos y monitor en bandeja"
                                badge: (root.updData.repos ? root.updData.repos.length : 0) + " repos"
                                onClicked: root.navigateTo("Actualización del sistema", "Opciones avanzadas", true)
                            }
                            HubNavCard {
                                iconFile: "fluent-shield.svg"
                                title: "Recuperación y copias"
                                subtitle: "Instantáneas Btrfs (Snapper / Btrfs Assistant), kernels instalados e inicio en UEFI / BIOS"
                                badge: (root.updData.snapperConfigs || []).length > 0 ? "Btrfs activo" : "Kernels"
                                onClicked: root.navigateTo("Actualización del sistema", "Recuperación y copias", true)
                            }
                        }

                        // --- SUBPÁGINA 1: HISTORIAL DE ACTUALIZACIONES ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Historial de actualizaciones"

                            Rectangle {
                                width: parent.width; implicitHeight: uhCtrlCol.implicitHeight + 26
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: uhCtrlCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Rectangle {
                                            Layout.fillWidth: true; height: 35; radius: 5; clip: true
                                            color: uhSearchIn.activeFocus ? "#161616" : "#1f1f1f"
                                            border.color: uhSearchIn.activeFocus ? root.accentColor : "#26ffffff"; border.width: 1
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                                WinSvg { width: 14; height: 14; iconFile: "fluent-search.svg"; opacity: 0.8 }
                                                Item {
                                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                                    Text { visible: uhSearchIn.text === ""; anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Buscar paquete o fecha en el historial..."; color: "#8e8e8e"; font.pixelSize: 12; elide: Text.ElideRight }
                                                    TextInput { id: uhSearchIn; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true; onTextChanged: root.updHistSearch = text }
                                                }
                                                WinSvg {
                                                    visible: uhSearchIn.text !== ""; width: 12; height: 12; iconFile: "fluent-dismiss.svg"; opacity: 0.75
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { uhSearchIn.text = ""; root.updHistSearch = ""; } }
                                                }
                                            }
                                        }
                                        FluentBtn { label: "Actualizar"; onClicked: { root.reloadUpdateInfo(); root.showToast("Historial recargado"); } }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Flow {
                                            Layout.fillWidth: true; spacing: 6
                                            Repeater {
                                                model: [
                                                    { id: "all",        label: "Todos" },
                                                    { id: "upgraded",   label: "Actualizados" },
                                                    { id: "installed",  label: "Instalados" },
                                                    { id: "downgraded", label: "Degradados" },
                                                    { id: "removed",    label: "Eliminados" }
                                                ]
                                                delegate: Rectangle {
                                                    readonly property bool act: root.updHistFilter === modelData.id
                                                    width: uhFT.implicitWidth + 22; height: 28; radius: 5
                                                    color: act ? root.accentColor : (uhFH.containsMouse ? "#383838" : "#2e2e2e")
                                                    border.color: act ? root.accentColor : "#22ffffff"; border.width: 1
                                                    Text { id: uhFT; anchors.centerIn: parent; text: modelData.label; color: act ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: act ? Font.DemiBold : Font.Normal }
                                                    MouseArea { id: uhFH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.updHistFilter = modelData.id }
                                                }
                                            }
                                        }
                                        Text {
                                            text: "Mostrando " + root.filteredUpdHistory.length + " de " + (root.updData.history || []).length
                                            color: "#9a9a9a"; font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width; implicitHeight: histListCol.implicitHeight + 24
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: histListCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 6
                                    Text {
                                        visible: root.filteredUpdHistory.length === 0
                                        text: "No hay eventos que coincidan con el filtro seleccionado."
                                        color: "#9a9a9a"; font.pixelSize: 12
                                    }
                                    Repeater {
                                        model: root.filteredUpdHistory
                                        delegate: Rectangle {
                                            Layout.fillWidth: true; height: 36; radius: 5; color: "#202020"
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                                Text { text: modelData.date || ""; color: "#8e8e8e"; font.pixelSize: 11; Layout.preferredWidth: 112 }
                                                Rectangle {
                                                    readonly property string a: String(modelData.action || "upgraded")
                                                    width: 82; height: 20; radius: 4
                                                    color: a === "installed" ? "#2422c55e"
                                                           : (a === "removed" ? "#26ef4444"
                                                              : (a === "downgraded" ? "#26f59e0b" : Qt.alpha(root.accentColor, 0.16)))
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: parent.a === "installed" ? "Instalado"
                                                              : (parent.a === "removed" ? "Eliminado"
                                                                 : (parent.a === "downgraded" ? "Degradado" : "Actualizado"))
                                                        color: parent.a === "installed" ? "#86efac"
                                                               : (parent.a === "removed" ? "#fca5a5"
                                                                  : (parent.a === "downgraded" ? "#fcd34d" : root.accentColor))
                                                        font.pixelSize: 10; font.weight: Font.DemiBold
                                                    }
                                                }
                                                Text { text: modelData.entry || ""; color: "#e4e4e4"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 2: OPCIONES AVANZADAS ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Opciones avanzadas"

                            Text { text: "Mantenimiento automático del sistema (systemd)"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                            ToggleCard {
                                visible: Boolean(root.updData.hasPaccacheTimer)
                                iconFile: "fluent-folder-zip.svg"
                                title: "Limpieza semanal automática de caché Pacman (paccache.timer)"
                                subtitle: (root.updData.pacmanCacheHuman ? ("Caché actual: " + root.updData.pacmanCacheHuman + " — ") : "")
                                          + "Mantiene solo las últimas versiones de paquetes descargados para evitar que /var/cache crezca sin control"
                                checked: Boolean(root.updData.paccacheTimerEnabled)
                                onToggled: (v) => {
                                    var r = bridge.setSystemdTimerEnabled("paccache.timer", v);
                                    if (r === "ok") {
                                        root.reloadUpdateInfo();
                                        root.showToast(v ? "Limpieza semanal paccache activada" : "Limpieza semanal paccache desactivada");
                                    } else {
                                        root.showToast(r.replace(/^error:/, ""));
                                    }
                                }
                            }

                            ToggleCard {
                                visible: Boolean(root.updData.hasFstrimTimer)
                                iconFile: "fluent-display.svg"
                                title: "Optimización semanal de SSD / NVMe (fstrim.timer)"
                                subtitle: "Ejecuta TRIM periódicamente para conservar la velocidad y vida útil de tus discos de estado sólido"
                                checked: Boolean(root.updData.fstrimTimerEnabled)
                                onToggled: (v) => {
                                    var r = bridge.setSystemdTimerEnabled("fstrim.timer", v);
                                    if (r === "ok") {
                                        root.reloadUpdateInfo();
                                        root.showToast(v ? "Optimización SSD TRIM activada" : "Optimización SSD TRIM desactivada");
                                    } else {
                                        root.showToast(r.replace(/^error:/, ""));
                                    }
                                }
                            }

                            // Active Pacman Repositories Card
                            Rectangle {
                                width: parent.width; implicitHeight: repoCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: repoCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    Text { text: "Repositorios activos (/etc/pacman.conf)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 6
                                        Repeater {
                                            model: root.updData.repos || []
                                            delegate: Rectangle {
                                                readonly property bool isX64: String(modelData).indexOf("x64") !== -1
                                                width: rpT.implicitWidth + 20; height: 27; radius: 5
                                                color: isX64 ? Qt.alpha(root.accentColor, 0.18) : "#22ffffff"
                                                border.color: isX64 ? root.accentColor : "#26ffffff"
                                                Text { id: rpT; anchors.centerIn: parent; text: "[" + modelData + "]"; color: isX64 ? root.accentColor : "#e0e0e0"; font.pixelSize: 11; font.weight: isX64 ? Font.DemiBold : Font.Normal }
                                            }
                                        }
                                    }
                                    Text {
                                        visible: (root.updData.ignorePkgs || []).length > 0
                                        text: "Paquetes congelados (IgnorePkg): " + (root.updData.ignorePkgs || []).join(", ")
                                        color: "#fbbf24"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            // Tray Monitor & X64 Tools Card (Interactive live + autostart control!)
                            Rectangle {
                                width: parent.width; implicitHeight: trayCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: trayCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 22; height: 22; iconFile: "update.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            RowLayout {
                                                spacing: 8
                                                Text { text: "Monitor en bandeja X64 Update"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                                Rectangle {
                                                    width: trStT.implicitWidth + 12; height: 19; radius: 4
                                                    color: root.updData.trayRunning ? "#2222c55e" : "#22ffffff"
                                                    Text { id: trStT; anchors.centerIn: parent; text: root.updData.trayRunning ? "Activo" : "Detenido"; color: root.updData.trayRunning ? "#86efac" : "#a8a8a8"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                                }
                                            }
                                            Text { text: "Avisa en la bandeja del sistema cuando llegan actualizaciones oficiales de X64 LIOS e inicia automáticamente con la sesión"; color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                        Win11Switch {
                                            visible: Boolean(root.updData.hasUpdateTray)
                                            checked: Boolean(root.updData.trayRunning)
                                            onToggled: (v) => {
                                                var r = bridge.setUpdateTrayEnabled(v);
                                                if (r === "ok") {
                                                    root.reloadUpdateInfo();
                                                    root.showToast(v ? "Monitor X64 Update activado" : "Monitor X64 Update desactivado");
                                                } else {
                                                    root.showToast(r.replace(/^error:/, ""));
                                                }
                                            }
                                        }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        FluentBtn { visible: Boolean(root.updData.hasX64Update); label: "Abrir X64 Update"; accent: true; onClicked: bridge.launchRealApp("x64-update") }
                                        FluentBtn { visible: Boolean(root.updData.hasX64Hello); label: "Abrir X64 Hello"; onClicked: bridge.launchRealApp("x64-hello") }
                                    }
                                }
                            }
                        }

                        // --- SUBPÁGINA 3: RECUPERACIÓN Y COPIAS (BTRFS) ---
                        Column {
                            width: parent.width; spacing: 10
                            visible: root.settingsSubPage === "Recuperación y copias"

                            // Btrfs Snapper Card
                            Rectangle {
                                width: parent.width; implicitHeight: snpRow.implicitHeight + 30
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: snpRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
                                    WinSvg { width: 24; height: 24; iconFile: "fluent-shield.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Flow {
                                            Layout.fillWidth: true; spacing: 6
                                            Text { text: "Instantáneas del sistema (Snapper Btrfs)"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                            Rectangle {
                                                visible: (root.updData.snapperConfigs || []).length > 0
                                                width: snOnT.implicitWidth + 12; height: 19; radius: 4; color: "#2222c55e"
                                                Text { id: snOnT; anchors.centerIn: parent; text: "Configurado (" + (root.updData.snapperConfigs || []).join(", ") + ")"; color: "#86efac"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                            }
                                            Rectangle {
                                                visible: Boolean(root.updData.hasSnapPac)
                                                width: spOnT.implicitWidth + 12; height: 19; radius: 4; color: Qt.alpha(root.accentColor, 0.16)
                                                Text { id: spOnT; anchors.centerIn: parent; text: "snap-pac automático"; color: root.accentColor; font.pixelSize: 10; font.weight: Font.DemiBold }
                                            }
                                            Rectangle {
                                                visible: Boolean(root.updData.hasLimineSnapper)
                                                width: lmOnT.implicitWidth + 12; height: 19; radius: 4; color: "#22ffffff"
                                                Text { id: lmOnT; anchors.centerIn: parent; text: "Limine Boot"; color: "#dcdcdc"; font.pixelSize: 10; font.weight: Font.DemiBold }
                                            }
                                        }
                                        Text {
                                            text: (root.updData.snapperConfigs || []).length > 0
                                                  ? "X64 LIOS crea puntos de restauración Btrfs antes de actualizar para revertir cambios desde el arranque o Btrfs Assistant."
                                                  : "No se detectó un perfil Snapper Btrfs activo en /etc/snapper/configs."
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        visible: Boolean(root.updData.hasBtrfsAssistant)
                                        label: "Abrir Btrfs Assistant"
                                        accent: true
                                        onClicked: bridge.launchRealApp("btrfs-assistant")
                                    }
                                }
                            }

                            // Installed Kernels Card
                            Rectangle {
                                width: parent.width; implicitHeight: krnCol.implicitHeight + 28
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: krnCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Kernels instalados en este equipo"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true }
                                        Text { text: "En ejecución: " + (root.updData.runningKernel || root.sysInfo.kernel); color: root.accentColor; font.pixelSize: 12; font.weight: Font.Medium }
                                    }
                                    Flow {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: root.updData.installedKernels || []
                                            delegate: Rectangle {
                                                readonly property bool isAct: Boolean(modelData.active)
                                                readonly property bool isLts: String(modelData.name || "").indexOf("lts") !== -1
                                                width: krnChipT.implicitWidth + 22; height: 30; radius: 5
                                                color: isAct ? Qt.alpha(root.accentColor, 0.18) : "#22ffffff"
                                                border.color: isAct ? root.accentColor : "#2cffffff"
                                                Text {
                                                    id: krnChipT; anchors.centerIn: parent
                                                    text: modelData.name + "  v" + modelData.version
                                                          + (parent.isAct ? "  (En uso)" : (parent.isLts ? "  (Respaldo LTS)" : ""))
                                                    color: parent.isAct ? "#ffffff" : "#dcdcdc"; font.pixelSize: 12; font.weight: Font.Medium
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Advanced Startup (UEFI Firmware Setup) & Storage Cleanup Card
                            Rectangle {
                                width: parent.width; implicitHeight: uefiRow.implicitHeight + 30
                                radius: 7; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: uefiRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
                                    WinSvg { width: 22; height: 22; iconFile: "fluent-power.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Inicio avanzado y recuperación"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium }
                                        Text {
                                            text: root.updData.canRebootFirmware
                                                  ? "Reinicia directamente en la configuración UEFI / BIOS o libera espacio de caché y archivos temporales"
                                                  : (!root.updData.isUefi
                                                     ? "Equipo iniciado en modo BIOS / Legacy — accede a Almacenamiento para limpiar caché y archivos temporales"
                                                     : "Tu firmware UEFI no admite salto automático — accede a Almacenamiento para limpiar caché y temporales")
                                            color: "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                    FluentBtn {
                                        visible: Boolean(root.updData.canRebootFirmware)
                                        label: "Reiniciar en UEFI / BIOS"
                                        onClicked: root.powerConfirmAction = "firmware"
                                    }
                                    FluentBtn {
                                        label: "Almacenamiento"
                                        onClicked: root.navigateTo("Sistema", "Almacenamiento", true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Wi-Fi Password Modal (for connecting to new secured networks including SSIDs with spaces!)
    Rectangle {
        visible: root.wifiPassModalOpen
        anchors.fill: parent; color: "#77000000"; z: 90
        MouseArea { anchors.fill: parent; onClicked: root.wifiPassModalOpen = false }

        Rectangle {
            anchors.centerIn: parent; width: Math.min(390, root.width - 36); implicitHeight: wpModCol.implicitHeight + 36
            radius: 10; color: "#f8242424"; border.color: "#36ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: wpModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 10
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 22; height: 22; iconFile: "fluent-wifi.svg" }
                    Text { text: "Conectar a " + root.wifiPassSsid; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                Text { text: "Escribe la clave de seguridad de red:"; color: "#b8b8b8"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: 5; clip: true
                    color: "#151515"; border.color: wifiPassField.activeFocus ? root.accentColor : "#34ffffff"
                    TextInput {
                        id: wifiPassField
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12
                        echoMode: TextInput.Password; selectByMouse: true; clip: true
                        Keys.onEscapePressed: root.wifiPassModalOpen = false
                        onAccepted: {
                            var r = bridge.connectWifi(root.wifiPassSsid, text);
                            if (r === "ok") {
                                root.wifiPassModalOpen = false;
                                root.refreshLiveState();
                                root.showToast("Conectado a " + root.wifiPassSsid);
                            } else {
                                root.wifiPassErr = r.replace(/^error:/, "") || "Contraseña incorrecta";
                            }
                        }
                    }
                }
                Text { visible: root.wifiPassErr !== ""; text: root.wifiPassErr; color: "#f87171"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.wifiPassModalOpen = false }
                    FluentBtn { label: "Conectar"; accent: true; onClicked: wifiPassField.accepted() }
                }
            }
        }
    }

    // Authentic WinUI 3 Rename PC Modal (hostnamectl via Polkit)
    Rectangle {
        visible: root.renamePcModalOpen
        anchors.fill: parent; color: "#77000000"; z: 91
        MouseArea { anchors.fill: parent; onClicked: root.renamePcModalOpen = false }

        Rectangle {
            anchors.centerIn: parent; width: Math.min(410, root.width - 36); implicitHeight: renModCol.implicitHeight + 36
            radius: 10; color: "#f8242424"; border.color: "#36ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: renModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 10
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 22; height: 22; iconFile: "fluent-display.svg" }
                    Text { text: "Cambiar el nombre de este equipo"; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true }
                }
                Text { text: "Usa una combinación de letras, números y guiones (sin espacios)."; color: "#b8b8b8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: 5; clip: true
                    color: "#151515"; border.color: renamePcField.activeFocus ? root.accentColor : "#34ffffff"
                    TextInput {
                        id: renamePcField
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                        Keys.onEscapePressed: root.renamePcModalOpen = false
                        onAccepted: {
                            var r = bridge.setSystemHostname(text);
                            if (r === "ok") {
                                root.renamePcModalOpen = false;
                                try { root.sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
                                root.refreshLiveState();
                                root.showToast("Nombre del equipo actualizado");
                            } else {
                                root.renamePcErr = r.replace(/^error:/, "") || "No se pudo cambiar el nombre";
                            }
                        }
                    }
                }
                Text { visible: root.renamePcErr !== ""; text: root.renamePcErr; color: "#f87171"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.renamePcModalOpen = false }
                    FluentBtn { label: "Guardar"; accent: true; onClicked: renamePcField.accepted() }
                }
            }
        }
    }

    // Authentic Windows 11 15-Second Display Auto-Revert Confirmation Modal
    Rectangle {
        visible: root.dispRevertModalOpen
        anchors.fill: parent; color: "#88000000"; z: 92
        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.centerIn: parent; width: Math.min(440, root.width - 36); implicitHeight: revModCol.implicitHeight + 40
            radius: 10; color: "#f8242424"; border.color: Qt.alpha(root.accentColor, 0.27); border.width: 1
            ColumnLayout {
                id: revModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    WinSvg { width: 24; height: 24; iconFile: "fluent-display.svg" }
                    Text { text: "¿Conservar esta configuración de pantalla?"; color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
                Text {
                    text: (root.dispRevertSnap && root.dispRevertSnap.desc ? (root.dispRevertSnap.desc + " aplicada. ") : "")
                          + "Se restaurará automáticamente la configuración anterior en " + root.dispRevertSec + " segundo" + (root.dispRevertSec === 1 ? "" : "s") + "."
                    color: "#c4c4c4"; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Revertir"; onClicked: root.revertDisplayChange() }
                    FluentBtn { label: "Conservar cambios"; accent: true; onClicked: root.keepDisplayChange() }
                }
            }
        }
    }

    // Authentic WinUI 3 Power Action Confirmation Modal (Reboot / Poweroff safety!)
    Rectangle {
        visible: root.powerConfirmAction !== ""
        anchors.fill: parent; color: "#88000000"; z: 93
        MouseArea { anchors.fill: parent; onClicked: root.powerConfirmAction = "" }

        Rectangle {
            anchors.centerIn: parent; width: Math.min(410, root.width - 36); implicitHeight: pwrModCol.implicitHeight + 40
            radius: 10; color: "#f8242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: pwrModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    WinSvg { width: 24; height: 24; iconFile: "fluent-power.svg" }
                    Text {
                        text: root.powerConfirmAction === "reboot" ? "¿Reiniciar este equipo?"
                              : (root.powerConfirmAction === "firmware" ? "¿Reiniciar en UEFI / BIOS?" : "¿Apagar este equipo?")
                        color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true
                    }
                }
                Text {
                    text: root.powerConfirmAction === "reboot"
                          ? "Se cerrarán las aplicaciones abiertas y el equipo volverá a iniciar en X64 LIOS."
                          : (root.powerConfirmAction === "firmware"
                             ? "Se cerrarán las aplicaciones abiertas y el equipo reiniciará directamente en la configuración de firmware UEFI / BIOS."
                             : "Se cerrarán las aplicaciones abiertas y el equipo se apagará de forma segura.")
                    color: "#c0c0c0"; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.powerConfirmAction = "" }
                    FluentBtn {
                        label: root.powerConfirmAction === "reboot" ? "Reiniciar ahora"
                               : (root.powerConfirmAction === "firmware" ? "Reiniciar en UEFI" : "Apagar ahora")
                        accent: true
                        onClicked: {
                            var act = root.powerConfirmAction;
                            root.powerConfirmAction = "";
                            var ok = bridge.triggerPowerAction(act);
                            if (!ok) root.showToast("No se pudo ejecutar la acción de energía");
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Storage Cleanup Confirmation Modal (Trash / Pacman Cache / User Cache)
    Rectangle {
        visible: root.storageConfirmAction !== ""
        anchors.fill: parent; color: "#88000000"; z: 94
        MouseArea { anchors.fill: parent; onClicked: root.storageConfirmAction = "" }

        Rectangle {
            anchors.centerIn: parent; width: Math.min(440, root.width - 36); implicitHeight: stoModCol.implicitHeight + 40
            radius: 10; color: "#f8242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: stoModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    WinSvg {
                        width: 24; height: 24
                        iconFile: root.storageConfirmAction === "trash" ? "trash.svg"
                                  : (root.storageConfirmAction === "pacman" ? "fluent-folder-zip.svg" : "fluent-delete.svg")
                    }
                    Text {
                        text: root.storageConfirmAction === "trash" ? "¿Vaciar la papelera de reciclaje?"
                              : (root.storageConfirmAction === "pacman" ? "¿Limpiar caché de paquetes Pacman?"
                                 : "¿Limpiar caché temporal (~/.cache)?")
                        color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Text {
                    text: root.storageConfirmAction === "trash"
                          ? "Se eliminarán permanentemente los archivos de la papelera y no podrán restaurarse."
                          : (root.storageConfirmAction === "pacman"
                             ? "Se conservará 1 versión instalada de cada paquete para reversión segura y se eliminarán versiones antiguas y paquetes desinstalados (requiere clave de administrador)."
                             : "Se borrarán archivos temporales regenerables de aplicaciones y miniaturas en ~/.cache. Tus documentos, sesiones activas, fuentes y configuraciones se mantienen intactos.")
                    color: "#c0c0c0"; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.storageConfirmAction = "" }
                    FluentBtn {
                        label: root.storageConfirmAction === "trash" ? "Vaciar ahora" : "Limpiar ahora"
                        accent: true
                        onClicked: {
                            var act = root.storageConfirmAction;
                            root.storageConfirmAction = "";
                            if (act === "trash") {
                                bridge.emptyTrash();
                                root.refreshLiveState(true);
                                root.showToast("Papelera de reciclaje vaciada");
                            } else if (act === "pacman") {
                                var rp = bridge.cleanPacmanCache();
                                if (rp.indexOf("ok:") === 0) {
                                    root.refreshLiveState(true);
                                    root.showToast("Caché de Pacman limpiada (" + rp.slice(3) + " liberados)");
                                } else {
                                    root.showToast(rp.replace(/^error:/, ""));
                                }
                            } else if (act === "usercache") {
                                var ru = bridge.cleanUserCache();
                                if (ru.indexOf("ok:") === 0) {
                                    root.refreshLiveState(true);
                                    root.showToast("Caché temporal limpiada (" + ru.slice(3) + " liberados)");
                                } else {
                                    root.showToast(ru.replace(/^error:/, ""));
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Network Action Confirmation Modal (Forget Wi-Fi / Delete VPN / Restart NetworkManager)
    Rectangle {
        visible: root.netConfirmAction !== ""
        anchors.fill: parent; color: "#88000000"; z: 95
        MouseArea { anchors.fill: parent; onClicked: root.netConfirmAction = "" }

        Rectangle {
            anchors.centerIn: parent; width: Math.min(430, root.width - 36); implicitHeight: netModCol.implicitHeight + 40
            radius: 10; color: "#f8242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: netModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    WinSvg {
                        width: 24; height: 24
                        iconFile: root.netConfirmAction === "delete_vpn" ? "fluent-shield.svg"
                                  : (root.netConfirmAction === "restart_nm" ? "fluent-refresh.svg" : "fluent-wifi.svg")
                    }
                    Text {
                        text: root.netConfirmAction === "forget_wifi" ? ("¿Olvidar red «" + root.netConfirmLabel + "»?")
                              : (root.netConfirmAction === "delete_vpn" ? ("¿Eliminar perfil VPN «" + root.netConfirmLabel + "»?")
                                 : "¿Reiniciar la pila de red?")
                        color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap
                    }
                }
                Text {
                    text: root.netConfirmAction === "forget_wifi"
                          ? "Se eliminará la contraseña guardada y el equipo no volverá a conectarse automáticamente a esta red."
                          : (root.netConfirmAction === "delete_vpn"
                             ? "Se borrará este perfil VPN de NetworkManager. Podrás volver a importarlo más adelante."
                             : "Se reiniciará NetworkManager y la conexión a Internet se interrumpirá unos segundos (requiere clave de administrador).")
                    color: "#c0c0c0"; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.netConfirmAction = "" }
                    FluentBtn {
                        label: root.netConfirmAction === "restart_nm" ? "Reiniciar ahora" : (root.netConfirmAction === "delete_vpn" ? "Eliminar" : "Olvidar")
                        accent: true
                        onClicked: {
                            var act = root.netConfirmAction;
                            var tgt = root.netConfirmTarget;
                            var lbl = root.netConfirmLabel;
                            root.netConfirmAction = "";
                            if (act === "forget_wifi" || act === "delete_vpn") {
                                if (bridge.forgetNetwork(tgt)) {
                                    root.refreshLiveState(false);
                                    root.showToast(act === "delete_vpn" ? ("Perfil VPN eliminado: " + lbl) : ("Red olvidada: " + lbl));
                                } else {
                                    root.showToast("No se pudo eliminar " + lbl);
                                }
                            } else if (act === "restart_nm") {
                                var rn = bridge.restartNetworkStack();
                                root.refreshLiveState(false);
                                root.showToast(rn === "ok" ? "Pila de red reiniciada" : rn.replace(/^error:/, ""));
                            }
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Graphical App Uninstaller Wizard Modal (Pacman + Flatpak + Local + System Shield!)
    Rectangle {
        visible: root.uninstModalOpen && root.uninstTargetApp !== null && root.uninstPlan !== null
        anchors.fill: parent; color: "#92000000"; z: 96
        MouseArea {
            anchors.fill: parent
            onClicked: { if (!root.uninstRunning) root.uninstModalOpen = false; }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(500, root.width - 36)
            implicitHeight: Math.min(root.height - 48, uninstModCol.implicitHeight + 44)
            radius: 10; color: "#f9242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                id: uninstModCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 22; spacing: 14

                // Header with real App Icon + Title + Package Subtitle
                RowLayout {
                    Layout.fillWidth: true; spacing: 14
                    WinSvg {
                        width: 40; height: 40
                        iconUrl: root.uninstTargetApp ? (root.uninstTargetApp.iconUrl || "") : ""
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text {
                            text: root.uninstFinishedState === "ok"
                                  ? "Aplicación desinstalada"
                                  : (root.uninstRunning
                                     ? ("Desinstalando " + (root.uninstTargetApp ? root.uninstTargetApp.name : "") + "...")
                                     : ("Desinstalar " + (root.uninstTargetApp ? root.uninstTargetApp.name : "")))
                            color: "#ffffff"; font.pixelSize: 17; font.weight: Font.DemiBold
                            Layout.fillWidth: true; elide: Text.ElideRight
                        }
                        Text {
                            text: (root.uninstPlan ? (root.uninstPlan.pkgName || "") : "")
                                  + (root.uninstPlan && root.uninstPlan.version ? ("  •  v" + root.uninstPlan.version) : "")
                                  + (root.uninstPlan && root.uninstPlan.sourceLabel ? ("  •  " + root.uninstPlan.sourceLabel) : "")
                            color: "#a8a8a8"; font.pixelSize: 12
                            Layout.fillWidth: true; elide: Text.ElideRight
                        }
                    }
                }

                // PHASE A: Blocked / Protected Warning
                Rectangle {
                    visible: !root.uninstRunning && root.uninstFinishedState === "" && root.uninstPlan && !root.uninstPlan.canUninstall
                    Layout.fillWidth: true; implicitHeight: blkCol.implicitHeight + 24
                    radius: 7; color: "#26eab308"; border.color: "#55eab308"; border.width: 1
                    ColumnLayout {
                        id: blkCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 12; spacing: 6
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            WinSvg { width: 18; height: 18; iconFile: "fluent-shield.svg" }
                            Text { text: "Desinstalación bloqueada por seguridad"; color: "#fde047"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        }
                        Text {
                            text: root.uninstPlan ? String(root.uninstPlan.blockedReason || "") : ""
                            color: "#f2e7b5"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                        }
                    }
                }

                // PHASE B: Ready-to-Uninstall Real Impact Preview
                ColumnLayout {
                    visible: !root.uninstRunning && root.uninstFinishedState === "" && root.uninstPlan && root.uninstPlan.canUninstall
                    Layout.fillWidth: true; spacing: 10

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: impBoxCol.implicitHeight + 22
                        radius: 7; color: "#1c1c1c"; border.color: "#22ffffff"; border.width: 1
                        ColumnLayout {
                            id: impBoxCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 12; spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Espacio estimado que se liberará"; color: "#b8b8b8"; font.pixelSize: 12; Layout.fillWidth: true }
                                Text {
                                    text: root.uninstPlan ? (root.uninstPlan.totalFreeHuman || "—") : "—"
                                    color: root.accentColor; font.pixelSize: 13; font.weight: Font.DemiBold
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Paquetes a eliminar"; color: "#b8b8b8"; font.pixelSize: 12; Layout.fillWidth: true }
                                Text {
                                    text: {
                                        var n = (root.uninstPlan && root.uninstPlan.removePkgs) ? root.uninstPlan.removePkgs.length : 1;
                                        var orp = root.uninstPlan ? Number(root.uninstPlan.orphanCount || 0) : 0;
                                        return n + (orp > 0 ? (" (incluye " + orp + " huérfana" + (orp === 1 ? "" : "s") + ")") : " paquete");
                                    }
                                    color: "#e8e8e8"; font.pixelSize: 12; font.weight: Font.Medium
                                }
                            }

                            // Compact package chips preview
                            Flow {
                                visible: root.uninstPlan && (root.uninstPlan.removePkgs || []).length > 0
                                Layout.fillWidth: true; spacing: 5
                                Repeater {
                                    model: root.uninstPlan ? (root.uninstPlan.removePkgs || []).slice(0, 8) : []
                                    delegate: Rectangle {
                                        width: pkChipT.implicitWidth + 14; height: 22; radius: 4
                                        color: "#2a2a2a"; border.color: "#1effffff"
                                        Text {
                                            id: pkChipT; anchors.centerIn: parent
                                            text: modelData.name + (modelData.sizeHuman && modelData.sizeHuman !== "—" ? (" (" + modelData.sizeHuman + ")") : "")
                                            color: "#cccccc"; font.pixelSize: 10
                                        }
                                    }
                                }
                            }

                            Text {
                                text: (root.uninstPlan && root.uninstPlan.needsRoot)
                                      ? "Se solicitará tu contraseña gráfica de administrador (Polkit)."
                                      : "No requiere contraseña de administrador."
                                color: "#8e8e8e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // Optional User-Data Cleanup Checkbox (unchecked by default!)
                    Rectangle {
                        visible: root.uninstPlan && (root.uninstPlan.userDataPaths || []).length > 0
                        Layout.fillWidth: true; implicitHeight: udRow.implicitHeight + 20
                        radius: 7; color: udHov.containsMouse ? "#2b2b2b" : "#1f1f1f"
                        border.color: root.uninstCleanUserData ? Qt.alpha(root.accentColor, 0.55) : "#20ffffff"; border.width: 1
                        RowLayout {
                            id: udRow
                            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            Rectangle {
                                width: 18; height: 18; radius: 4
                                Layout.preferredWidth: 18; Layout.preferredHeight: 18
                                color: root.uninstCleanUserData ? root.accentColor : "transparent"
                                border.color: root.uninstCleanUserData ? root.accentColor : "#8e8e8e"; border.width: 1.5
                                WinSvg {
                                    visible: root.uninstCleanUserData
                                    anchors.centerIn: parent; width: 12; height: 12; iconFile: "fluent-checkmark.svg"
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text {
                                    text: "Eliminar también datos y configuración local del usuario"
                                          + (root.uninstPlan && root.uninstPlan.userDataSizeHuman && root.uninstPlan.userDataSizeHuman !== "—"
                                             ? (" (" + root.uninstPlan.userDataSizeHuman + ")") : "")
                                    color: "#ececec"; font.pixelSize: 12; font.weight: Font.Medium
                                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                                }
                                Text {
                                    text: root.uninstPlan && root.uninstPlan.userDataPaths ? root.uninstPlan.userDataPaths.join("  •  ") : ""
                                    color: "#8e8e8e"; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                            }
                        }
                        MouseArea {
                            id: udHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.uninstCleanUserData = !root.uninstCleanUserData
                        }
                    }
                }

                // PHASE C: Live Progress Bar during Async Uninstall
                ColumnLayout {
                    visible: root.uninstRunning
                    Layout.fillWidth: true; spacing: 8
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.uninstStepText || "Procesando desinstalación..."; color: "#e8e8e8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: root.uninstPct + "%"; color: root.accentColor; font.pixelSize: 12; font.weight: Font.DemiBold }
                    }
                    Rectangle {
                        Layout.fillWidth: true; height: 6; radius: 3; color: "#343434"
                        Rectangle {
                            width: parent.width * Math.max(0.06, Math.min(1.0, root.uninstPct / 100.0))
                            height: parent.height; radius: 3; color: root.accentColor
                            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // PHASE D: Final Result Banner (Success / Error)
                Rectangle {
                    visible: !root.uninstRunning && root.uninstFinishedState !== ""
                    Layout.fillWidth: true; implicitHeight: resRow.implicitHeight + 22
                    radius: 7
                    color: root.uninstFinishedState === "ok" ? "#2422c55e" : "#26ef4444"
                    border.color: root.uninstFinishedState === "ok" ? "#5522c55e" : "#55ef4444"; border.width: 1
                    RowLayout {
                        id: resRow
                        anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                        WinSvg {
                            width: 18; height: 18
                            iconFile: root.uninstFinishedState === "ok" ? "fluent-checkmark.svg" : "fluent-dismiss.svg"
                        }
                        Text {
                            text: root.uninstResultMsg
                            color: root.uninstFinishedState === "ok" ? "#bbf7d0" : "#fecaca"
                            font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                        }
                    }
                }

                // Expandable Technical Output Log (visible during/after uninstall)
                ColumnLayout {
                    visible: root.uninstLog !== ""
                    Layout.fillWidth: true; spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: root.uninstShowLog ? "Ocultar registro técnico" : "Ver registro técnico"
                            color: root.accentColor; font.pixelSize: 11; font.weight: Font.Medium
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.uninstShowLog = !root.uninstShowLog }
                        }
                        Item { Layout.fillWidth: true }
                    }
                    Rectangle {
                        visible: root.uninstShowLog
                        Layout.fillWidth: true; height: 110; radius: 6; color: "#141414"; border.color: "#22ffffff"; border.width: 1; clip: true
                        Flickable {
                            anchors.fill: parent; anchors.margins: 8
                            contentWidth: width; contentHeight: logTxt.implicitHeight
                            clip: true
                            Text {
                                id: logTxt; width: parent.width
                                text: root.uninstLog; color: "#b8b8b8"; font.family: "monospace"; font.pixelSize: 10; wrapMode: Text.WrapAnywhere
                            }
                        }
                    }
                }

                // Footer Action Buttons
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Item { Layout.fillWidth: true }

                    // Cancel / Close
                    FluentBtn {
                        visible: !root.uninstRunning
                        label: (root.uninstFinishedState !== "" || (root.uninstPlan && !root.uninstPlan.canUninstall)) ? "Cerrar" : "Cancelar"
                        accent: root.uninstFinishedState !== "" || (root.uninstPlan && !root.uninstPlan.canUninstall)
                        onClicked: root.uninstModalOpen = false
                    }

                    // Red Win11 Destructive Confirm Button
                    Rectangle {
                        visible: !root.uninstRunning && root.uninstFinishedState === "" && root.uninstPlan && root.uninstPlan.canUninstall
                        implicitWidth: Math.max(136, delConfirmTxt.implicitWidth + 28); implicitHeight: 35
                        Layout.preferredWidth: implicitWidth; Layout.preferredHeight: 35
                        radius: 6
                        color: delConfH.containsMouse ? "#d93829" : "#c42b1c"
                        border.color: "#ef4444"; border.width: 1
                        Text { id: delConfirmTxt; anchors.centerIn: parent; text: "Desinstalar ahora"; color: "#ffffff"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        MouseArea {
                            id: delConfH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.uninstRunning = true;
                                root.uninstPct = 10;
                                root.uninstStepText = "Preparando desinstalación...";
                                root.uninstLog = "";
                                root.uninstFinishedState = "";
                                var started = bridge.startAppUninstall(
                                    String(root.uninstPlan.pkgName || ""),
                                    String(root.uninstPlan.source || ""),
                                    String(root.uninstTargetApp ? (root.uninstTargetApp.desktopPath || "") : ""),
                                    String(root.uninstTargetApp ? (root.uninstTargetApp.name || "") : ""),
                                    Boolean(root.uninstCleanUserData),
                                    String(root.uninstPlan.flatpakScope || "system")
                                );
                                if (!started) {
                                    root.uninstRunning = false;
                                    root.uninstFinishedState = "error";
                                    root.uninstResultMsg = "Ya hay otra desinstalación en curso.";
                                }
                            }
                        }
                    }

                    // Running label
                    Text {
                        visible: root.uninstRunning
                        text: "No cierres esta ventana..."
                        color: "#9a9a9a"; font.pixelSize: 11
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Graphical Password Change Modal (Zero black terminal!)
    Rectangle {
        visible: root.pwModalOpen
        anchors.fill: parent; color: "#88000000"; z: 97
        MouseArea { anchors.fill: parent; onClicked: root.pwModalOpen = false }
        Rectangle {
            anchors.centerIn: parent; width: Math.min(430, root.width - 36); implicitHeight: pwModCol.implicitHeight + 42
            radius: 10; color: "#f9242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: pwModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 22; spacing: 11
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 22; height: 22; iconFile: "fluent-lock.svg" }
                    Text { text: "Cambiar contraseña de la cuenta"; color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    Rectangle {
                        width: 30; height: 30; radius: 5; color: pwEyeH.containsMouse ? "#383838" : "#2c2c2c"
                        WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "fluent-eye.svg"; opacity: root.pwShowFields ? 1.0 : 0.6 }
                        MouseArea { id: pwEyeH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pwShowFields = !root.pwShowFields }
                    }
                }
                Text { text: "Contraseña actual"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: pwCurIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput {
                        id: pwCurIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                        echoMode: root.pwShowFields ? TextInput.Normal : TextInput.Password
                        onAccepted: pwNewIn.forceActiveFocus()
                    }
                }
                Text { text: "Nueva contraseña"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: pwNewIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput {
                        id: pwNewIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                        echoMode: root.pwShowFields ? TextInput.Normal : TextInput.Password
                        onAccepted: pwConfIn.forceActiveFocus()
                    }
                }
                Text { text: "Confirmar nueva contraseña"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: pwConfIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput {
                        id: pwConfIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                        echoMode: root.pwShowFields ? TextInput.Normal : TextInput.Password
                        onAccepted: pwSaveBtn.clicked()
                    }
                }
                Text { visible: root.pwModalErr !== ""; text: root.pwModalErr; color: "#f87171"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8; Layout.topMargin: 4
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.pwModalOpen = false }
                    FluentBtn {
                        id: pwSaveBtn; label: "Actualizar"; accent: true
                        onClicked: {
                            if (pwNewIn.text !== pwConfIn.text) { root.pwModalErr = "Las nuevas contraseñas no coinciden."; return; }
                            var r = bridge.changeAccountPassword(pwCurIn.text, pwNewIn.text);
                            if (r === "ok") {
                                pwCurIn.text = ""; pwNewIn.text = ""; pwConfIn.text = "";
                                root.pwModalOpen = false;
                                root.showToast("Contraseña actualizada correctamente");
                            } else {
                                root.pwModalErr = r.replace(/^error:/, "");
                            }
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Quick PIN Setup Modal (Windows Hello Style 4-8 digits!)
    Rectangle {
        visible: root.pinModalOpen
        anchors.fill: parent; color: "#88000000"; z: 97
        MouseArea { anchors.fill: parent; onClicked: root.pinModalOpen = false }
        Rectangle {
            anchors.centerIn: parent; width: Math.min(430, root.width - 36); implicitHeight: pinModCol.implicitHeight + 42
            radius: 10; color: "#f9242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: pinModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 22; spacing: 11
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 22; height: 22; iconFile: "fluent-shield.svg" }
                    Text { text: Boolean(root.accData.hasPin) ? "Cambiar PIN rápido" : "Configurar PIN rápido"; color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true }
                }
                Text { text: "Confirma tu contraseña actual de Linux"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: pinVerifyIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput {
                        id: pinVerifyIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                        echoMode: TextInput.Password; onAccepted: pinNewIn.forceActiveFocus()
                    }
                }
                Text { text: "Nuevo PIN (4 a 8 dígitos)"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: pinNewIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput {
                        id: pinNewIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                        maximumLength: 8; echoMode: TextInput.Password; onAccepted: pinConfIn.forceActiveFocus()
                    }
                }
                Text { text: "Confirmar PIN"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: pinConfIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput {
                        id: pinConfIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true
                        maximumLength: 8; echoMode: TextInput.Password; onAccepted: pinSaveBtn.clicked()
                    }
                }
                Text { visible: root.pinModalErr !== ""; text: root.pinModalErr; color: "#f87171"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8; Layout.topMargin: 4
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.pinModalOpen = false }
                    FluentBtn {
                        id: pinSaveBtn; label: "Guardar PIN"; accent: true
                        onClicked: {
                            if (pinNewIn.text !== pinConfIn.text) { root.pinModalErr = "Los códigos PIN no coinciden."; return; }
                            var r = bridge.setQuickPin(pinVerifyIn.text, pinNewIn.text);
                            if (r === "ok") {
                                pinVerifyIn.text = ""; pinNewIn.text = ""; pinConfIn.text = "";
                                root.pinModalOpen = false;
                                root.updateCfg("lockRequireAuth", true);
                                root.reloadAccountInfo();
                                root.refreshLiveState(false);
                                root.showToast("PIN rápido guardado y bloqueo Win+L activado");
                            } else {
                                root.pinModalErr = r.replace(/^error:/, "");
                            }
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Add Local User Modal
    Rectangle {
        visible: root.addUserModalOpen
        anchors.fill: parent; color: "#88000000"; z: 97
        MouseArea { anchors.fill: parent; onClicked: root.addUserModalOpen = false }
        Rectangle {
            anchors.centerIn: parent; width: Math.min(440, root.width - 36); implicitHeight: auModCol.implicitHeight + 42
            radius: 10; color: "#f9242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: auModCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 22; spacing: 11
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 22; height: 22; iconFile: "fluent-add-circle.svg" }
                    Text { text: "Agregar nueva cuenta local"; color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true }
                }
                Text { text: "Nombre completo"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: auFullIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput { id: auFullIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true; onAccepted: auUserIn.forceActiveFocus() }
                }
                Text { text: "Nombre de usuario (minúsculas, sin espacios)"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: auUserIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput { id: auUserIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true; onAccepted: auPwIn.forceActiveFocus() }
                }
                Text { text: "Contraseña inicial (mínimo 4 caracteres)"; color: "#c0c0c0"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: auPwIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput { id: auPwIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true; echoMode: TextInput.Password; onAccepted: auCreateBtn.clicked() }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8; Layout.topMargin: 2
                    Text { text: "Tipo de cuenta:"; color: "#c0c0c0"; font.pixelSize: 12; Layout.fillWidth: true }
                    Repeater {
                        model: [{ adm: false, lbl: "Usuario estándar" }, { adm: true, lbl: "Administrador" }]
                        delegate: Rectangle {
                            readonly property bool act: root.addUserIsAdmin === modelData.adm
                            width: rPickT.implicitWidth + 20; height: 30; radius: 5
                            color: act ? root.accentColor : "#2f2f2f"; border.color: act ? root.accentColor : "#28ffffff"
                            Text { id: rPickT; anchors.centerIn: parent; text: modelData.lbl; color: act ? "#000000" : "#efefef"; font.pixelSize: 12; font.weight: act ? Font.DemiBold : Font.Normal }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.addUserIsAdmin = modelData.adm }
                        }
                    }
                }
                Text { visible: root.addUserModalErr !== ""; text: root.addUserModalErr; color: "#f87171"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8; Layout.topMargin: 4
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.addUserModalOpen = false }
                    FluentBtn {
                        id: auCreateBtn; label: "Crear cuenta"; accent: true
                        onClicked: {
                            var r = bridge.createLocalUser(auUserIn.text, auFullIn.text, auPwIn.text, root.addUserIsAdmin);
                            if (r === "ok") {
                                auFullIn.text = ""; auUserIn.text = ""; auPwIn.text = "";
                                root.addUserModalOpen = false;
                                root.reloadAccountInfo();
                                root.refreshLiveState(false);
                                root.showToast("Cuenta local creada correctamente");
                            } else {
                                root.addUserModalErr = r.replace(/^error:/, "");
                            }
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Secondary User Password Reset Modal
    Rectangle {
        visible: root.resetOtherPwUser !== ""
        anchors.fill: parent; color: "#88000000"; z: 97
        MouseArea { anchors.fill: parent; onClicked: root.resetOtherPwUser = "" }
        Rectangle {
            anchors.centerIn: parent; width: Math.min(410, root.width - 36); implicitHeight: othPwCol.implicitHeight + 40
            radius: 10; color: "#f9242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: othPwCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 20; spacing: 11
                Text { text: "Restablecer contraseña de «" + root.resetOtherPwUser + "»"; color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Rectangle {
                    Layout.fillWidth: true; height: 35; radius: 5; color: "#171717"
                    border.color: othPwIn.activeFocus ? root.accentColor : "#30ffffff"
                    TextInput { id: othPwIn; anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; clip: true; echoMode: TextInput.Password; onAccepted: othPwSave.clicked() }
                }
                Text { visible: root.resetOtherPwErr !== ""; text: root.resetOtherPwErr; color: "#f87171"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.resetOtherPwUser = "" }
                    FluentBtn {
                        id: othPwSave; label: "Guardar"; accent: true
                        onClicked: {
                            var r = bridge.resetOtherUserPassword(root.resetOtherPwUser, othPwIn.text);
                            if (r === "ok") {
                                othPwIn.text = "";
                                root.resetOtherPwUser = "";
                                root.showToast("Contraseña actualizada");
                            } else {
                                root.resetOtherPwErr = r.replace(/^error:/, "");
                            }
                        }
                    }
                }
            }
        }
    }

    // Authentic WinUI 3 Delete Secondary User Confirmation Modal
    Rectangle {
        visible: root.delUserTarget !== ""
        anchors.fill: parent; color: "#88000000"; z: 97
        MouseArea { anchors.fill: parent; onClicked: root.delUserTarget = "" }
        Rectangle {
            anchors.centerIn: parent; width: Math.min(430, root.width - 36); implicitHeight: delUCol.implicitHeight + 42
            radius: 10; color: "#f9242424"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }
            ColumnLayout {
                id: delUCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 22; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 22; height: 22; iconFile: "fluent-delete.svg" }
                    Text { text: "¿Eliminar la cuenta «" + root.delUserTarget + "»?"; color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
                Text { text: "Esta acción eliminará la cuenta local del sistema (requiere autorización de administrador)."; color: "#c0c0c0"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: rmHomeRow.implicitHeight + 18; radius: 6; color: "#1c1c1c"
                    border.color: root.delUserRemoveHome ? "#66ef4444" : "#22ffffff"
                    RowLayout {
                        id: rmHomeRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                        Rectangle {
                            width: 18; height: 18; radius: 4; color: root.delUserRemoveHome ? "#ef4444" : "transparent"; border.color: root.delUserRemoveHome ? "#ef4444" : "#8e8e8e"; border.width: 1.5
                            WinSvg { visible: root.delUserRemoveHome; anchors.centerIn: parent; width: 12; height: 12; iconFile: "fluent-checkmark.svg" }
                        }
                        Text { text: "Eliminar también su carpeta personal (/home/" + root.delUserTarget + ")"; color: "#e8e8e8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.delUserRemoveHome = !root.delUserRemoveHome }
                }
                Text { visible: root.delUserErr !== ""; text: root.delUserErr; color: "#f87171"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.delUserTarget = "" }
                    Rectangle {
                        implicitWidth: 126; implicitHeight: 35; radius: 6
                        color: delUConfH.containsMouse ? "#d93829" : "#c42b1c"; border.color: "#ef4444"
                        Text { anchors.centerIn: parent; text: "Eliminar cuenta"; color: "#ffffff"; font.pixelSize: 13; font.weight: Font.DemiBold }
                        MouseArea {
                            id: delUConfH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var r = bridge.deleteLocalUser(root.delUserTarget, root.delUserRemoveHome);
                                if (r === "ok") {
                                    var oldU = root.delUserTarget;
                                    root.delUserTarget = "";
                                    root.reloadAccountInfo();
                                    root.refreshLiveState(false);
                                    root.showToast("Cuenta eliminada: " + oldU);
                                } else {
                                    root.delUserErr = r.replace(/^error:/, "");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
