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
        return idx !== -1 ? s.slice(idx + 1).trim() : "";
    }

    property string settingsPage: normalizePageName(typeof initialArg !== "undefined" ? initialArg : "")
    property string settingsSubPage: extractSubPage(typeof initialArg !== "undefined" ? initialArg : "")
    property var navHistory: [{ page: normalizePageName(typeof initialArg !== "undefined" ? initialArg : ""), sub: extractSubPage(typeof initialArg !== "undefined" ? initialArg : "") }]
    property int navHistIdx: 0
    readonly property bool canGoBack: navHistIdx > 0 || settingsSubPage !== ""
    readonly property bool canGoForward: navHistIdx < (navHistory.length - 1)

    property string navFilter: ""
    property string appSearchFilter: ""
    property bool navExpandedManual: false
    property bool copiedNotice: false
    property bool copiedOsNotice: false
    property string toastMsg: ""
    property string clockTimeStr: Qt.formatTime(new Date(), "hh:mm:ss")
    property string clockDateStr: Qt.formatDate(new Date(), "dddd, d 'de' MMMM 'de' yyyy")

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
    property var updateResult: ({ "count": -1, "packages": [], "checkedAt": "" })

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
        bridge.requestAsyncRefresh(s === "Impresoras y escáneres" || s === "Almacenamiento");
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
                root.showToast(res.count > 0 ? (res.count + " actualizaciones disponibles") : "Sistema al día");
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
    }

    // Responsive Breakpoints (ZERO deformation on small windows + full spacious layout when maximized!)
    readonly property bool compactNav: root.width < 820 && !root.navExpandedManual
    readonly property bool narrowBody: contentPane.width < 560
    readonly property bool wideBody: root.width >= 1260

    property var cfg: ({
        "taskbarCompact": false,
        "taskbarLeftAlign": false,
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
        "customWallpaperUrl": "",
        "userAvatarUrl": "",
        "phoneMaxFps": 60,
        "phoneBitrate": "8M",
        "phoneAudio": true,
        "phoneTurnScreenOff": false,
        "phoneStayAwake": true,
        "phoneAlwaysOnTop": false
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
        "battery": { "present": false, "pct": 100, "status": "AC", "acOnline": true, "label": "Conectado a corriente alterna (Escritorio)", "model": "Fuente CA", "tech": "", "healthPct": -1, "whDesign": "", "voltageStr": "", "powerW": "", "cycles": 0 },
        "powerInfo": { "cpuDriver": "intel_pstate", "cpuEpp": "balanced", "cpuFreqGhz": "—", "cpuMaxGhz": "—", "hasLid": false, "lidExtAction": "suspend", "caffeineActive": false },
        "storageExtras": { "trashCount": 0, "trashSize": "0 B", "pacmanCacheSize": "0 B", "pacmanCacheCount": 0, "userCacheSize": "0 B", "userCacheBytes": 0, "journalSize": "0 B", "journalBytes": 0, "userFolders": [] },
        "about": { "vendorModel": "", "boardBios": "", "archLabel": "Sistema operativo de 64 bits, procesador x86_64", "osPretty": "X64 LIOS Linux", "shellVersion": "x64-win11-settings", "compositorInfo": "Wayland • labwc", "uptimeHuman": "—", "hasX64Hello": false },
        "account": { "displayName": "Usuario", "username": "x64", "hostname": "x64-pc", "homeDir": "/home", "shell": "/usr/bin/fish", "groups": "wheel", "isAdmin": true, "avatarUrl": "" },
        "timeLang": { "timezone": "Local", "ntpActive": true, "synced": true, "locale": "es_ES.UTF-8", "kbLayout": "ES" },
        "defaultApps": [],
        "gamingStack": { "falcond": false, "dmemcg": false, "ananicy": false, "ntsync": false, "hasSteam": false, "hasHeroic": false, "hasLutris": false },
        "tools": { "hasKdeConnect": false, "hasBlueman": true, "hasPrinterGui": true, "hasNmEditor": true, "hasGnomeDisks": true },
        "recentUpgrades": [],
        "pkgCount": 0
    })

    property var drives: []
    property var installedApps: []

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
            return "network-wired-symbolic.svg";
        }
        return root.hwState.wifiEnabled ? "fluent-wifi.svg" : "fluent-wifi-off.svg";
    }

    readonly property string activeWallpaperSrc: {
        if (root.cfg.wallpaperMode === 3 && root.cfg.customWallpaperUrl && root.cfg.customWallpaperUrl !== "") {
            return root.cfg.customWallpaperUrl;
        }
        if (root.cfg.wallpaperMode === 1) return wpDirUrl + "win11-bloom-light.jpg";
        if (root.cfg.wallpaperMode === 2) return wpDirUrl + "x64-monolith.jpg";
        return wpDirUrl + "win11-bloom-dark.jpg";
    }

    readonly property string activeAvatarUrl: {
        var a = (root.cfg && root.cfg.userAvatarUrl) ? String(root.cfg.userAvatarUrl) : "";
        if (a !== "") return a;
        return (root.extData && root.extData.account && root.extData.account.avatarUrl) ? String(root.extData.account.avatarUrl) : "";
    }

    readonly property string activeDisplayName: {
        if (root.extData && root.extData.account && root.extData.account.displayName) return String(root.extData.account.displayName);
        return root.sysInfo.user || "Usuario";
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
        onTriggered: {
            var now = new Date();
            root.clockTimeStr = Boolean(root.cfg.clock12h) ? Qt.formatTime(now, "h:mm:ss AP") : Qt.formatTime(now, "hh:mm:ss");
            root.clockDateStr = Qt.formatDate(now, "dddd, d 'de' MMMM 'de' yyyy");
        }
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
            color: wSwitch.checked ? "#4cc2ff" : (swMouse.containsMouse ? "#24ffffff" : "#14000000")
            border.color: wSwitch.checked ? "#4cc2ff" : "#99ffffff"; border.width: 1
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
            Rectangle { width: sSlider.ratio * parent.width; height: 4; radius: 2; color: "#4cc2ff" }
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
        color: accent ? (fBtnH.containsMouse ? "#5ecbff" : "#4cc2ff")
                      : (fBtnH.containsMouse ? "#3b3b3b" : "#303030")
        border.color: accent ? "#4cc2ff" : "#26ffffff"
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
                text: hCard.badge; color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.DemiBold
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
            if (data.extData) extData = data.extData;
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
        bridge.requestAsyncRefresh(false);
        deferAppsTimer.start();
    }

    Timer {
        id: deferAppsTimer
        interval: 220; running: false; repeat: false
        onTriggered: { try { root.installedApps = JSON.parse(bridge.getInstalledAppsJson()); } catch (e) {} }
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
        { icon: "fluent-wifi.svg",        name: "Red e Internet",            kw: "red internet wifi ethernet ip dns puerta enlace conectar desconectar" },
        { icon: "fluent-paint-brush.svg", name: "Personalización",           kw: "personalizacion fondo wallpaper tema foto barra tareas compacta izquierda menu inicio iconos escritorio tamano bloqueo" },
        { icon: "fluent-apps-list.svg",   name: "Aplicaciones",              kw: "aplicaciones programas instaladas predeterminadas navegador editor fotos pdf video tienda shelly inicio" },
        { icon: "fluent-person.svg",      name: "Cuentas",                   kw: "cuentas usuario perfil avatar foto imagen nombre contrasena bloquear administrador sddm" },
        { icon: "fluent-keyboard.svg",    name: "Hora e idioma",             kw: "hora fecha reloj 12h 24h idioma teclado distribucion es us latam zona horaria ntp" },
        { icon: "fluent-games.svg",       name: "Juegos",                    kw: "juegos gaming modo juego scx lavd falcond dmemcg ananicy ntsync steam heroic lutris fps gpu" },
        { icon: "update.svg",             name: "Actualización del sistema", kw: "actualizacion sistema update paquetes pacman kernel historial comprobar" }
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
                        color: navSearchIn.activeFocus ? "#4cc2ff" : "#44ffffff"
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
                                        { kw: ["impresora", "escaner", "cups"], p: "Bluetooth y dispositivos", s: "Impresoras y escáneres" }
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
                                    width: 3; height: 18; radius: 1.5; color: "#4cc2ff"
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
                            width: 34; height: 34; radius: 6
                            color: hdrBackHov.containsMouse ? "#2cffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-arrow-left.svg" }
                            MouseArea { id: hdrBackHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goBackNav() }
                        }
                        Row {
                            Layout.fillWidth: true; spacing: 10
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.settingsPage
                                color: root.settingsSubPage !== "" ? (bcRootHov.containsMouse ? "#ffffff" : "#a8a8a8") : "#f5f5f5"
                                font.pixelSize: root.narrowBody ? 22 : (root.wideBody ? 28 : 25)
                                font.weight: Font.DemiBold
                                MouseArea {
                                    id: bcRootHov; anchors.fill: parent; hoverEnabled: true
                                    enabled: root.settingsSubPage !== ""
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.navigateTo(root.settingsPage, "", true)
                                }
                            }
                            WinSvg {
                                visible: root.settingsSubPage !== ""
                                anchors.verticalCenter: parent.verticalCenter
                                width: 15; height: 15; iconFile: "fluent-chevron-right.svg"; opacity: 0.7
                            }
                            Text {
                                visible: root.settingsSubPage !== ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.settingsSubPage
                                color: "#f5f5f5"
                                font.pixelSize: root.narrowBody ? 22 : (root.wideBody ? 28 : 25)
                                font.weight: Font.DemiBold
                            }
                        }
                        Rectangle {
                            visible: root.toastMsg !== ""
                            width: Math.min(300, toastTxt.implicitWidth + 22); height: 30; radius: 6
                            color: "#264cc2ff"; border.color: "#4cc2ff"; border.width: 1
                            Text {
                                id: toastTxt; anchors.centerIn: parent
                                width: Math.min(280, implicitWidth)
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
                                                Text { text: root.sysInfo.hostname || "Equipo X64"; color: heroIdH.containsMouse ? "#4cc2ff" : "#f5f5f5"; font.pixelSize: root.wideBody ? 21 : 17; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: root.sysInfo.cpu || ""; color: "#b0b0b0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: "X64 LIOS • " + (root.sysInfo.ram || "") + " • " + (root.hwState.monitors || ""); color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
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
                                                    color: root.updateResult.count > 0 ? "#4cc2ff" : "#f2f2f2"; font.pixelSize: 13
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
                                                color: root.updateResult.count > 0 ? "#4cc2ff" : "#f0f0f0"; font.pixelSize: 12
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
                                            text: "Personalización ›"; color: pMoreH.containsMouse ? "#7cd4ff" : "#4cc2ff"; font.pixelSize: 12; font.weight: Font.Medium
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
                                                border.color: root.cfg.wallpaperMode === modelData.mode ? "#4cc2ff" : "#33ffffff"
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
                                            border.color: (root.cfg.wallpaperMode === 3 && hasCustom) ? "#4cc2ff" : "#33ffffff"
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
                                                Text { text: modelData.mounted ? (Math.round(Number(modelData.usedRatio || 0) * 100) + "%") : "Sin montar"; color: modelData.mounted ? "#4cc2ff" : "#9a9a9a"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true; height: 8; radius: 4; color: "#383838"
                                                Rectangle { visible: Boolean(modelData.mounted); width: Math.max(8, parent.width * Number(modelData.usedRatio || 0.04)); height: 8; radius: 4; color: modelData.isCritical ? "#d13438" : "#4cc2ff" }
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
                                            text: "Bluetooth y energía"; color: btHdrH.containsMouse ? "#4cc2ff" : "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true
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
                                            text: "Energía ›"; color: pwrMoreH.containsMouse ? "#7cd4ff" : "#4cc2ff"; font.pixelSize: 12; font.weight: Font.Medium
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
                                                color: isCur ? "#4cc2ff" : (hpH.containsMouse ? "#383838" : "#202020")
                                                border.color: isCur ? "#4cc2ff" : "#24ffffff"
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
                                    Text { text: root.netChipLabel; color: "#4cc2ff"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
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
                                                    border.color: isSel ? "#4cc2ff" : (isOn ? "#3cffffff" : "#26ffffff")
                                                    border.width: isSel ? 2 : 1
                                                    opacity: isOn ? 1.0 : 0.55
                                                    Behavior on color { ColorAnimation { duration: 110 } }

                                                    // Subtle top accent bar on selected display
                                                    Rectangle {
                                                        visible: isSel; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                                                        anchors.topMargin: 5; width: 32; height: 3; radius: 2; color: "#4cc2ff"
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
                                                    color: modelData.active ? "#4cc2ff" : (pmH.containsMouse ? "#383838" : "#2d2d2d")
                                                    border.color: modelData.active ? "#4cc2ff" : "#24ffffff"
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
                                        Text { text: root.localBrightPct + "%"; color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
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
                                    color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 6
                                }
                            }

                            // Selected Monitor Identity & Power Card
                            Rectangle {
                                visible: root.selectedMonitor !== null
                                width: parent.width; implicitHeight: Math.max(70, selMonHdr.implicitHeight + 28)
                                radius: 7; color: "#222a33"; border.color: "#384cc2ff"; border.width: 1
                                RowLayout {
                                    id: selMonHdr; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                    Rectangle {
                                        width: 38; height: 38; radius: 8; color: "#264cc2ff"; border.color: "#554cc2ff"
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
                                                color: isCurSc ? "#4cc2ff" : (scHov.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurSc ? "#4cc2ff" : "#20ffffff"
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
                                            border.color: root.resDropdownOpen ? "#4cc2ff" : (resGrid.multiRes ? "#28ffffff" : "#18ffffff")
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
                                                color: isCurR ? "#254cc2ff" : (rOptH.containsMouse ? "#323232" : "#202020")
                                                border.color: isCurR ? "#554cc2ff" : "#14ffffff"
                                                RowLayout {
                                                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                                                    Text { text: modelData.label; color: isCurR ? "#4cc2ff" : "#f0f0f0"; font.pixelSize: 13; font.weight: isCurR ? Font.DemiBold : Font.Normal; Layout.fillWidth: true }
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
                                                color: isCurHz ? "#4cc2ff" : (hzH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurHz ? "#4cc2ff" : "#20ffffff"
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
                                                color: isCurT ? "#4cc2ff" : (trHov.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurT ? "#4cc2ff" : "#20ffffff"
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
                                                color: root.localVolPct > 100 ? "#fbbf24" : "#4cc2ff"
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
                                    border.color: sObj.active ? "#4cc2ff" : "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: sinkCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 13; spacing: 10
                                        Item {
                                            Layout.fillWidth: true; implicitHeight: sinkHdrRow.implicitHeight
                                            RowLayout {
                                                id: sinkHdrRow; anchors.fill: parent; spacing: 12
                                                Rectangle { width: 12; height: 12; radius: 6; color: sinkCard.sObj.active ? "#4cc2ff" : "transparent"; border.color: sinkCard.sObj.active ? "#4cc2ff" : "#777777"; border.width: 2 }
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
                                                Text { visible: Boolean(sinkCard.sObj.active); text: "Predeterminado"; color: "#4cc2ff"; font.pixelSize: 11; font.weight: Font.DemiBold }
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
                                                    color: modelData.active ? "#4cc2ff" : (spH.containsMouse ? "#383838" : "#202020")
                                                    border.color: modelData.active ? "#4cc2ff" : "#22ffffff"
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
                                        Text { text: root.localMicPct + "%"; color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
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
                                    border.color: srcObj.active ? "#4cc2ff" : "#1cffffff"; border.width: 1
                                    ColumnLayout {
                                        id: srcCardCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                        anchors.leftMargin: 18; anchors.rightMargin: 18; anchors.topMargin: 13; spacing: 10
                                        Item {
                                            Layout.fillWidth: true; implicitHeight: srcHdrRow.implicitHeight
                                            RowLayout {
                                                id: srcHdrRow; anchors.fill: parent; spacing: 12
                                                Rectangle { width: 12; height: 12; radius: 6; color: srcCard.srcObj.active ? "#4cc2ff" : "transparent"; border.color: srcCard.srcObj.active ? "#4cc2ff" : "#777777"; border.width: 2 }
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
                                                Text { visible: Boolean(srcCard.srcObj.active); text: "Predeterminado"; color: "#4cc2ff"; font.pixelSize: 11; font.weight: Font.DemiBold }
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
                                                    color: modelData.active ? "#4cc2ff" : (mpH.containsMouse ? "#383838" : "#202020")
                                                    border.color: modelData.active ? "#4cc2ff" : "#22ffffff"
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
                                    color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.Medium
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
                                                Text { text: appStrCard.localAppVol + "%"; color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.DemiBold; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
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
                                                    color: isCurS ? "#4cc2ff" : (rsH.containsMouse ? "#383838" : "#202020")
                                                    border.color: isCurS ? "#4cc2ff" : "#22ffffff"
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
                                    radius: 7; color: "#262626"; border.color: isExp ? "#444cc2ff" : "#1cffffff"; border.width: 1
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
                                                    color: modelData.active ? "#254cc2ff" : (cpH.containsMouse ? "#333333" : "#202020")
                                                    border.color: modelData.active ? "#554cc2ff" : "#14ffffff"
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.right: parent.right
                                                        anchors.leftMargin: 12; anchors.rightMargin: 12
                                                        text: modelData.label; color: modelData.active ? "#4cc2ff" : "#ececec"
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
                                                color: isCurD ? "#4cc2ff" : (ndH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurD ? "#4cc2ff" : "#20ffffff"
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
                                                color: isCurF ? "#4cc2ff" : (fdH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurF ? "#4cc2ff" : "#20ffffff"
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
                                            color: "#224cc2ff"; border.color: "#444cc2ff"
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
                                                color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight
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
                                                color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight
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
                                        border.color: isCur ? "#4cc2ff" : "#1effffff"; border.width: isCur ? 2 : 1
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
                                                    width: 10; height: 10; radius: 5; color: "#4cc2ff"
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
                                                color: isCurL ? "#4cc2ff" : (lidH.containsMouse ? "#3a3a3a" : "#2f2f2f")
                                                border.color: isCurL ? "#4cc2ff" : "#20ffffff"
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
                                                color: !modelData.mounted ? "#9e9e9e" : (modelData.isCritical ? "#f87171" : "#4cc2ff")
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
                                                color: modelData.isCritical ? "#d13438" : "#4cc2ff"
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
                                            color: Number(stoSubCol.sEx.trashCount || 0) > 0 ? "#4cc2ff" : "#9e9e9e"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
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
                                                Text { text: modelData.size || "0 B"; color: Number(modelData.bytes || 0) > 0 ? "#4cc2ff" : "#8e8e8e"; font.pixelSize: 12; font.weight: Font.DemiBold }
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
                                            color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight
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
                                        radius: 7; color: modelData.connected ? "#223242" : "#262626"; border.color: modelData.connected ? "#4cc2ff" : "#1cffffff"; border.width: 1
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
                                                    color: modelData.connected ? "#4cc2ff" : "#9a9a9a"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true
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
                                        Text { text: Math.round((root.localMouseSpeed + 1.0) * 50) + "%"; color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
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
                                                color: isCur ? "#4cc2ff" : (maH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? "#4cc2ff" : "#22ffffff"
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
                                                    color: isCur ? "#4cc2ff" : (mlH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCur ? "#4cc2ff" : "#20ffffff"
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
                                                    color: isCur ? "#4cc2ff" : (msH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCur ? "#4cc2ff" : "#20ffffff"
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
                                                color: isCur ? "#4cc2ff" : (tseH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? "#4cc2ff" : "#20ffffff"
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
                                        Text { text: Math.round((root.localTpSpeed + 1.0) * 50) + "%"; color: "#4cc2ff"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.preferredWidth: 44; horizontalAlignment: Text.AlignRight }
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
                                                color: isCur ? "#4cc2ff" : (tcmH.containsMouse ? "#383838" : "#2f2f2f")
                                                border.color: isCur ? "#4cc2ff" : "#20ffffff"
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
                                            width: uSpdT.implicitWidth + 16; height: 24; radius: 5; color: "#1a4cc2ff"; border.color: "#384cc2ff"
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
                                    radius: 7; color: modelData.isDefault ? "#223242" : "#262626"; border.color: modelData.isDefault ? "#4cc2ff" : "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: prnItRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 14
                                        WinSvg { width: 21; height: 21; iconFile: "printer-symbolic.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: (modelData.isDefault ? "Predeterminada  •  " : "") + (modelData.status || "Lista"); color: modelData.isDefault ? "#4cc2ff" : "#9a9a9a"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
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
                                radius: 7; color: "#262626"; border.color: mobSubCol.pl.mirrorActive ? "#554cc2ff" : "#1cffffff"; border.width: 1
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
                                            radius: 6; color: "#202020"; border.color: modelData.authorized ? "#344cc2ff" : "#34f59e0b"
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
                                            border.color: wifiAdbIn.activeFocus ? "#4cc2ff" : "#2cffffff"; clip: true
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
                                                    color: isCurF ? "#4cc2ff" : (pfH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCurF ? "#4cc2ff" : "#20ffffff"
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
                                                    color: isCurB ? "#4cc2ff" : (pbH.containsMouse ? "#383838" : "#2f2f2f")
                                                    border.color: isCurB ? "#4cc2ff" : "#20ffffff"
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
                                    border.color: (modelData.paired && modelData.reachable) ? "#4cc2ff" : "#1cffffff"; border.width: 1
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
                                                    color: (modelData.paired && modelData.reachable) ? "#4cc2ff" : "#9a9a9a"; font.pixelSize: 12
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
                    // PAGE 3: RED E INTERNET
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Red e Internet"

                        Rectangle {
                            width: parent.width; implicitHeight: netHeroCol.implicitHeight + 28
                            radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                            ColumnLayout {
                                id: netHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 14
                                    WinSvg { width: 32; height: 32; iconFile: root.hwState.wifiEnabled ? "fluent-wifi.svg" : "fluent-wifi-off.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: root.hwState.wifiEnabled ? ((root.hwState.wifiSsid || "Red") + " — Conectado") : "Wi-Fi desconectado"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: "IPv4: " + (root.hwState.localIp || "N/A") + "  •  Puerta: " + (root.extData.netGateway || "—") + "  •  DNS: " + (root.extData.netDns || "—"); color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn { label: "Explorar redes"; accent: true; onClicked: { bridge.runCtlAction("wifi rescan"); wifiRescanT.restart(); root.showToast("Buscando redes Wi-Fi..."); } }
                                    FluentBtn {
                                        label: (root.extData.tools && root.extData.tools.hasNmEditor) ? "Conexiones avanzadas" : "Instalar editor de red"
                                        onClicked: {
                                            if (root.extData.tools && root.extData.tools.hasNmEditor) {
                                                bridge.launchRealApp("nm-connection-editor");
                                            } else {
                                                bridge.launchRealApp("/usr/bin/shelly-ui");
                                                root.showToast("Busca 'nm-connection-editor' en Tienda Shelly");
                                            }
                                        }
                                    }
                                    FluentBtn { label: "Optimizador DNS"; onClicked: bridge.launchRealApp("x64-hello") }
                                }
                            }
                        }

                        ToggleCard {
                            iconFile: "fluent-wifi.svg"
                            title: "Wi-Fi"
                            subtitle: "Activa o desactiva la tarjeta inalámbrica del equipo (" + (root.extData.netIface || "wlan") + ")"
                            checked: Boolean(root.hwState.wifiEnabled)
                            onToggled: (v) => {
                                var cp = Object.assign({}, root.hwState); cp.wifiEnabled = v; root.hwState = cp;
                                bridge.setWifiEnabled(v);
                                root.refreshLiveState();
                                root.showToast(v ? "Wi-Fi activado" : "Wi-Fi desactivado");
                            }
                        }

                        Repeater {
                            model: root.hwState.wifiNetworks || []
                            delegate: Rectangle {
                                width: parent.width; implicitHeight: wnRow.implicitHeight + 22
                                radius: 6
                                color: modelData.active ? "#26333f" : "#262626"
                                border.color: modelData.active ? "#4cc2ff" : "#1cffffff"; border.width: 1
                                RowLayout {
                                    id: wnRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 14; spacing: 12
                                    WinSvg { width: 18; height: 18; iconFile: "fluent-wifi.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text { text: modelData.ssid || "Red"; color: "#f5f5f5"; font.pixelSize: 12; font.weight: modelData.active ? Font.DemiBold : Font.Normal; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: (modelData.active ? "Conectado, seguro • " : "") + "Señal " + (modelData.signal || 0) + "% • " + (modelData.security || "WPA2"); color: modelData.active ? "#4cc2ff" : "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    FluentBtn {
                                        visible: Boolean(modelData.active)
                                        label: "Desconectar"
                                        onClicked: {
                                            if (bridge.disconnectWifi(modelData.ssid)) {
                                                root.refreshLiveState();
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
                    }

                    // =========================================================
                    // PAGE 4: PERSONALIZACIÓN (Fondos + Foto Personalizada, Barra, Inicio, Escritorio)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Personalización"

                        // Fondo de escritorio + Examinar foto propia!
                        Rectangle {
                            width: parent.width; implicitHeight: wpCol.implicitHeight + 28
                            radius: 8; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: wpCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-image.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Fondo de escritorio"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                        Text { text: "Elige un fondo 4K integrado o selecciona cualquier imagen propia de tu equipo"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 10
                                    Repeater {
                                        model: [
                                            { mode: 0, label: "Bloom Oscuro", src: wpDirUrl + "win11-bloom-dark.jpg" },
                                            { mode: 1, label: "Bloom Claro",  src: wpDirUrl + "win11-bloom-light.jpg" },
                                            { mode: 2, label: "X64 Monolith", src: wpDirUrl + "x64-monolith.jpg" }
                                        ]
                                        delegate: Column {
                                            spacing: 4
                                            Rectangle {
                                                width: 124; height: 74; radius: 6; clip: true
                                                border.color: root.cfg.wallpaperMode === modelData.mode ? "#4cc2ff" : "#33ffffff"
                                                border.width: root.cfg.wallpaperMode === modelData.mode ? 2 : 1
                                                Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: modelData.src; fillMode: Image.PreserveAspectCrop }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.updateCfg("wallpaperMode", modelData.mode); root.showToast("Fondo aplicado: " + modelData.label); } }
                                            }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: root.cfg.wallpaperMode === modelData.mode ? "#4cc2ff" : "#b8b8b8"; font.pixelSize: 11 }
                                        }
                                    }
                                    // Custom Wallpaper Thumbnail when active
                                    Column {
                                        visible: root.cfg.customWallpaperUrl !== ""
                                        spacing: 4
                                        Rectangle {
                                            width: 124; height: 74; radius: 6; clip: true
                                            border.color: root.cfg.wallpaperMode === 3 ? "#4cc2ff" : "#33ffffff"
                                            border.width: root.cfg.wallpaperMode === 3 ? 2 : 1
                                            Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: root.cfg.customWallpaperUrl || ""; fillMode: Image.PreserveAspectCrop }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.updateCfg("wallpaperMode", 3) }
                                        }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Foto propia"; color: root.cfg.wallpaperMode === 3 ? "#4cc2ff" : "#b8b8b8"; font.pixelSize: 11 }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn {
                                        label: "Examinar foto personalizada..."
                                        accent: true
                                        onClicked: {
                                            var u = bridge.pickAndSetWallpaper();
                                            if (u !== "") {
                                                root.refreshLiveState();
                                                root.showToast("Fondo personalizado aplicado");
                                            }
                                        }
                                    }
                                    FluentBtn { label: "Probar pantalla de bloqueo (Win+L)"; onClicked: bridge.runCtlAction("lock") }
                                }
                            }
                        }

                        Text { text: "Barra de tareas y Menú Inicio"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 4 }

                        ToggleCard {
                            iconFile: "fluent-window-apps.svg"
                            title: "Alineación de la barra de tareas a la izquierda"
                            subtitle: "Alterna entre los iconos centrados y el diseño clásico alineado a la izquierda"
                            checked: Boolean(root.cfg.taskbarLeftAlign)
                            onToggled: (v) => root.updateCfg("taskbarLeftAlign", v)
                        }
                        ToggleCard {
                            iconFile: "fluent-maximize.svg"
                            title: "Barra de tareas compacta"
                            subtitle: "Reduce la altura de la barra de tareas de 48 px a 38 px para ganar espacio vertical"
                            checked: Boolean(root.cfg.taskbarCompact)
                            onToggled: (v) => root.updateCfg("taskbarCompact", v)
                        }
                        ToggleCard {
                            iconFile: "fluent-phone.svg"
                            title: "Mostrar panel Enlace Móvil en el Menú Inicio"
                            subtitle: "Muestra el panel lateral de sincronización móvil cuando abres Inicio"
                            checked: Boolean(root.cfg.showPhoneLink)
                            onToggled: (v) => root.updateCfg("showPhoneLink", v)
                        }
                        ToggleCard {
                            iconFile: "fluent-sparkle.svg"
                            title: "Mostrar sección Recomendado en el Menú Inicio"
                            subtitle: "Incluye accesos a archivos y actividad reciente dentro de Inicio"
                            checked: Boolean(root.cfg.showRecommended)
                            onToggled: (v) => root.updateCfg("showRecommended", v)
                        }
                        ToggleCard {
                            iconFile: "fluent-battery-charge.svg"
                            title: "Mostrar porcentaje de batería en la bandeja"
                            subtitle: "Muestra el porcentaje numérico junto al icono de batería en equipos portátiles"
                            checked: Boolean(root.cfg.showBatteryPct)
                            onToggled: (v) => root.updateCfg("showBatteryPct", v)
                        }

                        Text { text: "Iconos del escritorio"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 4 }

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
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
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
                                            color: isCur ? "#4cc2ff" : (iszH.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? "#4cc2ff" : "#22ffffff"
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
                    }

                    // =========================================================
                    // PAGE 5: APLICACIONES (Predeterminadas + Inicio + Catálogo Buscable)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Aplicaciones"

                        // Quick Management Row
                        Rectangle {
                            width: parent.width; implicitHeight: appActFlow.implicitHeight + 24
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            Flow {
                                id: appActFlow; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8
                                FluentBtn { label: "Instalar o quitar apps (Tienda Shelly)"; accent: true; onClicked: bridge.launchRealApp("/usr/bin/shelly-ui") }
                                FluentBtn { label: "Aplicaciones de inicio"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app taskmgr startup") }
                            }
                        }

                        // Aplicaciones predeterminadas (REAL xdg-mime + Selector interactivo!)
                        Text { text: "Aplicaciones predeterminadas (haz clic para cambiar)"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 2 }

                        Rectangle {
                            width: parent.width; implicitHeight: defCol.implicitHeight + 20
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: defCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; spacing: 4
                                Repeater {
                                    model: root.extData.defaultApps || []
                                    delegate: ColumnLayout {
                                        id: roleBlock
                                        readonly property string rId: modelData.id || ""
                                        readonly property bool isExp: root.expandedMimeRole === rId && (modelData.candidates || []).length > 1
                                        Layout.fillWidth: true; spacing: 4

                                        Rectangle {
                                            Layout.fillWidth: true; height: 40; radius: 5
                                            color: defRowH.containsMouse ? "#2c2c2c" : "#202020"
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                                WinSvg { width: 18; height: 18; iconFile: modelData.icon || "fluent-apps-list.svg" }
                                                Text { text: modelData.role; color: "#e8e8e8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { text: modelData.app; color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.Medium; elide: Text.ElideRight }
                                                WinSvg {
                                                    visible: (modelData.candidates || []).length > 1
                                                    width: 12; height: 12
                                                    iconFile: roleBlock.isExp ? "fluent-chevron-up.svg" : "fluent-chevron-down.svg"
                                                    opacity: 0.75
                                                }
                                            }
                                            MouseArea {
                                                id: defRowH; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: (modelData.candidates || []).length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: {
                                                    if ((modelData.candidates || []).length > 1) {
                                                        root.expandedMimeRole = (root.expandedMimeRole === roleBlock.rId) ? "" : roleBlock.rId;
                                                    }
                                                }
                                            }
                                        }

                                        Flow {
                                            visible: roleBlock.isExp
                                            Layout.fillWidth: true; Layout.leftMargin: 12; Layout.bottomMargin: 4; spacing: 6
                                            Repeater {
                                                model: modelData.candidates || []
                                                delegate: Rectangle {
                                                    width: cLbl.implicitWidth + 20; height: 28; radius: 4
                                                    color: modelData.active ? "#4cc2ff" : (candH.containsMouse ? "#383838" : "#2c2c2c")
                                                    border.color: modelData.active ? "#4cc2ff" : "#22ffffff"
                                                    Text { id: cLbl; anchors.centerIn: parent; text: modelData.label; color: modelData.active ? "#000000" : "#f0f0f0"; font.pixelSize: 11; font.weight: modelData.active ? Font.DemiBold : Font.Normal }
                                                    MouseArea {
                                                        id: candH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            if (bridge.setDefaultAppForRole(roleBlock.rId, modelData.desktop)) {
                                                                root.expandedMimeRole = "";
                                                                root.refreshLiveState();
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

                        // Installed Applications Search & List
                        Text { text: "Aplicaciones instaladas (" + root.installedApps.length + ")"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 4 }

                        Rectangle {
                            width: parent.width; height: 36; radius: 5; clip: true
                            color: appFilterIn.activeFocus ? "#161616" : "#2a2a2a"
                            border.color: appFilterIn.activeFocus ? "#4cc2ff" : "#24ffffff"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 8
                                WinSvg { width: 14; height: 14; iconFile: "fluent-search.svg"; opacity: 0.8 }
                                Item {
                                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                                    Text { visible: appFilterIn.text === ""; anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: "Filtrar aplicaciones instaladas..."; color: "#9a9a9a"; font.pixelSize: 12; elide: Text.ElideRight }
                                    TextInput { id: appFilterIn; anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true; onTextChanged: root.appSearchFilter = text }
                                }
                            }
                        }

                        Repeater {
                            model: root.installedApps
                            delegate: Rectangle {
                                visible: root.appSearchFilter.trim() === "" || String(modelData.name || "").toLowerCase().indexOf(root.appSearchFilter.trim().toLowerCase()) !== -1
                                width: parent.width; height: 52; radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 12
                                    WinSvg { width: 26; height: 26; iconUrl: modelData.iconUrl || "" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text { text: modelData.name || ""; color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: modelData.cmd || ""; color: "#8e8e8e"; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    FluentBtn { label: "Abrir"; onClicked: bridge.launchRealApp(modelData.cmd) }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 6: CUENTAS (REAL ACCOUNT PICTURE CHANGER + PROFILE SETTINGS!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 12
                        visible: root.settingsPage === "Cuentas"

                        // Profile Hero Card with Circular Avatar
                        Rectangle {
                            width: parent.width; implicitHeight: accHeroCol.implicitHeight + 32
                            radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                            RowLayout {
                                id: accHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 18
                                UserAvatarBadge { sz: root.narrowBody ? 68 : 88 }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    Text { text: root.activeDisplayName; color: "#ffffff"; font.pixelSize: 20; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: (root.extData.account ? root.extData.account.username : "usuario") + "@" + (root.extData.account ? root.extData.account.hostname : "equipo"); color: "#b8b8b8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Rectangle {
                                        width: roleTxt.implicitWidth + 16; height: 22; radius: 4
                                        color: "#224cc2ff"; border.color: "#444cc2ff"
                                        Text {
                                            id: roleTxt; anchors.centerIn: parent
                                            text: (root.extData.account && root.extData.account.isAdmin) ? "Administrador local" : "Usuario estándar"
                                            color: "#4cc2ff"; font.pixelSize: 11; font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }
                        }

                        // Change Account Picture Card (File Picker + 7 Instant Presets + Reset!)
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
                                        Text { text: "Se sincroniza al instante en Configuración, Menú Inicio, Pantalla de Bloqueo e inicio de sesión (SDDM)"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
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
                                                root.refreshLiveState();
                                                root.showToast("Imagen de perfil actualizada");
                                            }
                                        }
                                    }
                                    FluentBtn {
                                        visible: root.activeAvatarUrl !== ""
                                        label: "Restablecer predeterminado"
                                        onClicked: {
                                            if (bridge.resetUserAvatar()) {
                                                root.refreshLiveState();
                                                root.showToast("Imagen de cuenta restablecida");
                                            }
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }
                                Text { text: "O elige un avatar rápido con tus iniciales:"; color: "#b8b8b8"; font.pixelSize: 11 }

                                Flow {
                                    Layout.fillWidth: true; spacing: 10
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
                                                border.color: avPrH.containsMouse ? "#4cc2ff" : "#38ffffff"; border.width: avPrH.containsMouse ? 2 : 1
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
                                                            root.refreshLiveState();
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
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: dnCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                Text { text: "Nombre visible del perfil"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    Rectangle {
                                        Layout.fillWidth: true; height: 32; radius: 5; clip: true
                                        color: "#171717"; border.color: dispNameIn.activeFocus ? "#4cc2ff" : "#30ffffff"
                                        TextInput {
                                            id: dispNameIn
                                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                            verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true; clip: true
                                            Component.onCompleted: text = root.activeDisplayName
                                            onAccepted: {
                                                if (bridge.setDisplayName(text)) {
                                                    root.forceActiveFocus();
                                                    root.refreshLiveState();
                                                    root.showToast("Nombre visible guardado");
                                                }
                                            }
                                        }
                                    }
                                    FluentBtn {
                                        label: "Guardar"; accent: true
                                        onClicked: dispNameIn.accepted()
                                    }
                                }
                            }
                        }

                        // Account Security & Details Card
                        Rectangle {
                            width: parent.width; implicitHeight: accInfoCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: accInfoCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 8
                                Text { text: "Información y opciones de inicio de sesión"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { text: "Carpeta personal:   " + (root.extData.account ? root.extData.account.homeDir : ""); color: "#c8c8c8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideMiddle }
                                Text { text: "Shell interactivo:   " + (root.extData.account ? root.extData.account.shell : ""); color: "#c8c8c8"; font.pixelSize: 12 }
                                Text { text: "Grupos del sistema:   " + (root.extData.account ? root.extData.account.groups : ""); color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8; Layout.topMargin: 4
                                    FluentBtn { label: "Bloquear equipo (Win+L)"; onClicked: bridge.runCtlAction("lock") }
                                    FluentBtn { label: "Cambiar contraseña"; onClicked: bridge.launchRealApp("kitty -e sh -c 'passwd; echo \"\"; read -p \"Presiona Enter para cerrar...\" _'") }
                                    FluentBtn { label: "Abrir carpeta personal"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer 'Inicio'") }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 7: HORA E IDIOMA (100% Interactive: 12h/24h Clock, NTP, Timezone & Keyboard Layout!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Hora e idioma"

                        Rectangle {
                            width: parent.width; implicitHeight: clkCol.implicitHeight + 32
                            radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                            ColumnLayout {
                                id: clkCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 18; spacing: 4
                                Text { text: root.clockTimeStr; color: "#ffffff"; font.pixelSize: 32; font.weight: Font.DemiBold }
                                Text { text: root.clockDateStr; color: "#4cc2ff"; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Text { text: "Zona horaria:  " + (root.extData.timeLang ? root.extData.timeLang.timezone : "Local") + "  •  Idioma: " + (root.extData.timeLang ? root.extData.timeLang.locale : ""); color: "#a8a8a8"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }
                        }

                        ToggleCard {
                            iconFile: "fluent-refresh.svg"
                            title: "Formato de reloj de 12 horas (AM / PM)"
                            subtitle: "Cambia el reloj de la barra de tareas y pantalla de bloqueo entre 24h y 12h"
                            checked: Boolean(root.cfg.clock12h)
                            onToggled: (v) => {
                                root.updateCfg("clock12h", v);
                                var now = new Date();
                                root.clockTimeStr = v ? Qt.formatTime(now, "h:mm:ss AP") : Qt.formatTime(now, "hh:mm:ss");
                                root.showToast(v ? "Reloj en formato 12 horas" : "Reloj en formato 24 horas");
                            }
                        }

                        ToggleCard {
                            iconFile: "fluent-refresh.svg"
                            title: "Establecer hora automáticamente (NTP)"
                            subtitle: (root.extData.timeLang && root.extData.timeLang.synced) ? "Reloj sincronizado con servidores de tiempo del sistema" : "Sincronización automática desactivada"
                            checked: Boolean(root.extData.timeLang && root.extData.timeLang.ntpActive)
                            onToggled: (v) => {
                                if (bridge.setNtpEnabled(v)) {
                                    root.refreshLiveState();
                                    root.showToast(v ? "Sincronización NTP activada" : "Sincronización NTP desactivada");
                                } else {
                                    root.showToast("Cambio de NTP cancelado");
                                }
                            }
                        }

                        // Real Keyboard Layout Selector (ES / US / LATAM -> labwc reconfigure live!)
                        Rectangle {
                            width: parent.width; implicitHeight: kbCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: kbCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-keyboard.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Distribución de teclado principal"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { text: "Aplica inmediatamente en Wayland (labwc) y sincroniza la barra de tareas. También puedes alternar con Alt + Shift"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    Repeater {
                                        model: [
                                            { code: "es",    tag: "ES",    label: "Español (España)" },
                                            { code: "latam", tag: "LATAM", label: "Español (Latinoamérica)" },
                                            { code: "us",    tag: "US",    label: "Inglés (Estados Unidos)" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: (root.extData.timeLang ? String(root.extData.timeLang.kbLayout || "ES") : "ES") === modelData.tag
                                            width: kbTxt.implicitWidth + 24; height: 32; radius: 5
                                            color: isCur ? "#4cc2ff" : (kbHov.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? "#4cc2ff" : "#22ffffff"
                                            Text { id: kbTxt; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea {
                                                id: kbHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (bridge.setKeyboardLayout(modelData.code)) {
                                                        root.refreshLiveState();
                                                        root.showToast("Teclado cambiado a " + modelData.label);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Real Timezone Picker (via timedatectl)
                        Rectangle {
                            width: parent.width; implicitHeight: tzPickCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: tzPickCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                Text { text: "Cambiar zona horaria"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                Flow {
                                    Layout.fillWidth: true; spacing: 6
                                    Repeater {
                                        model: ["America/Panama", "America/Bogota", "America/Mexico_City", "America/Lima", "America/Santiago", "America/Argentina/Buenos_Aires", "America/New_York", "Europe/Madrid", "UTC"]
                                        delegate: Rectangle {
                                            readonly property bool isCur: root.extData.timeLang && String(root.extData.timeLang.timezone || "").indexOf(modelData) !== -1
                                            width: tzLbl.implicitWidth + 18; height: 28; radius: 4
                                            color: isCur ? "#4cc2ff" : (tzHov.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? "#4cc2ff" : "#22ffffff"
                                            Text { id: tzLbl; anchors.centerIn: parent; text: modelData.replace("_", " "); color: parent.isCur ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea {
                                                id: tzHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (bridge.setSystemTimezone(modelData)) {
                                                        root.refreshLiveState();
                                                        root.showToast("Zona horaria: " + modelData);
                                                    } else {
                                                        root.showToast("Cambio de zona horaria cancelado");
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
                    // PAGE 8: JUEGOS (Stack Gaming X64 Real!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Juegos"

                        ToggleCard {
                            iconFile: "fluent-games.svg"
                            title: "Modo Juego X64 (Alto rendimiento)"
                            subtitle: "Activa el perfil de rendimiento máximo en CPU y prioriza fotogramas 1% Low sin latencia"
                            checked: root.hwState.powerProfile === "performance"
                            onToggled: (v) => {
                                var prof = v ? "performance" : "balanced";
                                var copy = Object.assign({}, root.hwState);
                                copy.powerProfile = prof;
                                root.hwState = copy;
                                bridge.runCtlAction("power-profile " + prof);
                                root.showToast(v ? "Modo Juego X64 activado" : "Perfil equilibrado restaurado");
                            }
                        }

                        // Live X64 Gaming Engine Status Pills
                        Rectangle {
                            width: parent.width; implicitHeight: gmStCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: gmStCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                Text { text: "Motor de baja latencia X64 LIOS"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    Repeater {
                                        model: [
                                            { label: "Planificador: " + (root.sysInfo.sched || "BORE"), ok: true },
                                            { label: "FalconD", ok: Boolean(root.extData.gamingStack && root.extData.gamingStack.falcond) },
                                            { label: "dmemcg VRAM", ok: Boolean(root.extData.gamingStack && root.extData.gamingStack.dmemcg) },
                                            { label: "Ananicy-cpp", ok: Boolean(root.extData.gamingStack && root.extData.gamingStack.ananicy) },
                                            { label: "NTSYNC", ok: Boolean(root.extData.gamingStack && root.extData.gamingStack.ntsync) }
                                        ]
                                        delegate: Rectangle {
                                            width: gmPillTxt.implicitWidth + 20; height: 28; radius: 5
                                            color: modelData.ok ? "#224ade80" : "#22ffffff"
                                            border.color: modelData.ok ? "#554ade80" : "#22ffffff"
                                            Text { id: gmPillTxt; anchors.centerIn: parent; text: modelData.label; color: modelData.ok ? "#4ade80" : "#9e9e9e"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        }
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: [
                                { icon: "x64lios.png",  title: "X64 Hello — Centro de Optimización", desc: "Gestiona planificadores SCX, DNS, drivers GPU y perfiles gaming", cmd: "x64-hello", show: true },
                                { icon: "taskmgr.svg",  title: "Administrador de tareas (Multi-GPU)", desc: "Monitorea CPU por núcleo, VRAM y temperatura de todas tus GPUs", cmd: "/usr/bin/x64-win11-app taskmgr performance", show: true },
                                { icon: "steam.svg",    title: "Steam", desc: "Biblioteca de juegos con Proton y aceleración NTSYNC activa", cmd: "steam", show: Boolean(root.extData.gamingStack && root.extData.gamingStack.hasSteam) },
                                { icon: "fluent-games.svg", title: "Heroic Games Launcher", desc: "Epic Games, GOG y Amazon Games en Linux", cmd: "heroic", show: Boolean(root.extData.gamingStack && root.extData.gamingStack.hasHeroic) },
                                { icon: "fluent-games.svg", title: "Lutris", desc: "Gestor universal de bibliotecas gaming y emuladores", cmd: "lutris", show: Boolean(root.extData.gamingStack && root.extData.gamingStack.hasLutris) }
                            ]
                            delegate: Rectangle {
                                visible: Boolean(modelData.show)
                                width: parent.width; implicitHeight: gmRow.implicitHeight + 24
                                radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                GridLayout {
                                    id: gmRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16
                                    columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 12
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 24; height: 24; iconFile: modelData.icon }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: modelData.title; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: modelData.desc; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    FluentBtn { label: "Abrir"; onClicked: bridge.launchRealApp(modelData.cmd) }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 9: ACTUALIZACIÓN DEL SISTEMA (Honest, Real X64 LIOS System Update!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 12
                        visible: root.settingsPage === "Actualización del sistema"

                        Rectangle {
                            width: parent.width; implicitHeight: updHeroCol.implicitHeight + 32
                            radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1
                            ColumnLayout {
                                id: updHeroCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 14
                                    WinSvg { width: 40; height: 40; iconFile: "update.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 3
                                        Text {
                                            text: root.checkingUpdates ? "Comprobando actualizaciones..."
                                                  : (root.updateResult.count > 0 ? (root.updateResult.count + " actualizaciones disponibles")
                                                     : "Sistema X64 LIOS al día")
                                            color: root.updateResult.count > 0 ? "#fbbf24" : "#f5f5f5"
                                            font.pixelSize: 17; font.weight: Font.DemiBold
                                            Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                        Text {
                                            text: "Kernel " + root.sysInfo.kernel + "  •  " + (root.extData.pkgCount || 0) + " paquetes instalados" + (root.updateResult.checkedAt ? ("  •  Comprobado " + root.updateResult.checkedAt) : "")
                                            color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn {
                                        label: root.checkingUpdates ? "Comprobando..." : "Comprobar actualizaciones"
                                        accent: true
                                        onClicked: root.runUpdateCheck()
                                    }
                                    FluentBtn { label: "Abrir X64 Update"; onClicked: bridge.launchRealApp("x64-update") }
                                    FluentBtn { label: "Abrir Tienda Shelly"; onClicked: bridge.launchRealApp("/usr/bin/shelly-ui") }
                                }
                            }
                        }

                        // Pending Packages Preview (when found)
                        Rectangle {
                            visible: root.updateResult.count > 0
                            width: parent.width; implicitHeight: pendCol.implicitHeight + 24
                            radius: 6; color: "#262626"; border.color: "#44fbbf24"; border.width: 1
                            ColumnLayout {
                                id: pendCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 6
                                Text { text: "Paquetes pendientes de actualización:"; color: "#fbbf24"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                Repeater {
                                    model: root.updateResult.packages || []
                                    delegate: Text { text: "•  " + modelData; color: "#e0e0e0"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                }
                            }
                        }

                        // Recent Pacman Upgrade History (Real /var/log/pacman.log!)
                        Rectangle {
                            width: parent.width; implicitHeight: histCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: histCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 8
                                Text { text: "Historial reciente de actualizaciones"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { visible: (root.extData.recentUpgrades || []).length === 0; text: "No hay registros recientes disponibles"; color: "#8e8e8e"; font.pixelSize: 11 }
                                Repeater {
                                    model: root.extData.recentUpgrades || []
                                    delegate: RowLayout {
                                        Layout.fillWidth: true; spacing: 10
                                        Text { text: modelData.date; color: "#8e8e8e"; font.pixelSize: 11; Layout.preferredWidth: 112 }
                                        Text { text: modelData.entry; color: "#d8d8d8"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
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
                    color: "#151515"; border.color: wifiPassField.activeFocus ? "#4cc2ff" : "#34ffffff"
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
                    color: "#151515"; border.color: renamePcField.activeFocus ? "#4cc2ff" : "#34ffffff"
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
            radius: 10; color: "#f8242424"; border.color: "#444cc2ff"; border.width: 1
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
                        text: root.powerConfirmAction === "reboot" ? "¿Reiniciar este equipo?" : "¿Apagar este equipo?"
                        color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true
                    }
                }
                Text {
                    text: root.powerConfirmAction === "reboot"
                          ? "Se cerrarán las aplicaciones abiertas y el equipo volverá a iniciar en X64 LIOS."
                          : "Se cerrarán las aplicaciones abiertas y el equipo se apagará de forma segura."
                    color: "#c0c0c0"; font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Item { Layout.fillWidth: true }
                    FluentBtn { label: "Cancelar"; onClicked: root.powerConfirmAction = "" }
                    FluentBtn {
                        label: root.powerConfirmAction === "reboot" ? "Reiniciar ahora" : "Apagar ahora"
                        accent: true
                        onClicked: {
                            var act = root.powerConfirmAction;
                            root.powerConfirmAction = "";
                            bridge.triggerPowerAction(act);
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
}
