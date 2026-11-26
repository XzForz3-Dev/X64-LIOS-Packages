//@ pragma UseQApplication
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications

ShellRoot {
    id: shellRoot

    readonly property string assetDir: "file:///usr/share/x64-win11/assets/icons/"
    readonly property string wpDir: "file:///usr/share/x64-win11/assets/wallpapers/"

    // Global Windows 11 26H2 Shell State
    property var activeScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    property string currentTimeStr: Qt.formatTime(new Date(), "hh:mm")
    property string currentDateStr: Qt.formatDate(new Date(), "dd/MM/yyyy")
    property string currentLongDateStr: formatSpanishDate(new Date(), true)
    property string currentLockDateStr: formatSpanishDate(new Date(), false)

    property bool startOpen: false
    property bool searchOpen: false
    property bool quickSettingsOpen: false
    property bool calendarOpen: false
    property bool weatherOpen: false
    property bool weatherRefreshing: false
    property bool taskViewOpen: false
    property bool appJumpOpen: false
    property var appJumpData: null
    property real appJumpX: 400
    property bool trayFlyoutOpen: false
    property bool powerPopupOpen: false
    property bool ctxMenuOpen: false
    property string ctxSubMenu: ""
    property bool desktopItemCtxOpen: false
    property var desktopItemData: null
    property real desktopItemCtxX: 200
    property real desktopItemCtxY: 200
    property bool winXMenuOpen: false
    property string winXSubOpen: ""
    property real winXMenuX: 12
    property bool startAppCtxOpen: false
    property var startAppCtxData: null
    property real startAppCtxX: 300
    property real startAppCtxY: 300
    property bool propertiesModalOpen: false
    property var propertiesData: null
    property bool desktopRenameOpen: false
    property var desktopRenameData: null
    property bool newShortcutModalOpen: false
    property string desktopClipboardPath: ""
    property var desktopClipboardPaths: []
    property bool desktopClipboardCut: false
    property var desktopSelectedItems: []
    property bool taskbarCtxOpen: false
    property bool runDialogOpen: false
    property bool lockScreenOpen: false
    property bool lockPromptOpen: false
    property bool lockShowPass: false
    property bool lockRequireAuth: false
    property string lockAuthError: ""
    property bool lockAuthChecking: false
    property real ctxX: 200
    property real ctxY: 200
    property real ctxSubY: 0
    property real taskbarCtxX: 400
    property string desktopIconSizeMode: "medium"
    property bool showDesktopIcons: true
    property bool desktopAutoArrange: false
    property var desktopIconPositions: ({})
    property string desktopSortMode: "default"
    property bool desktopSortAsc: true
    property bool desktopRefreshing: false
    property double cfgWriteGuardUntil: 0
    property string _lastCfgRaw: ""
    property string _lastSysRaw: ""
    property string _lastClipRaw: ""
    property string _lastWsRaw: ""
    property bool trashHasFiles: false
    property int trashCount: 0
    property string trashSize: "0 B"
    property bool hasHiddenDesktopIcons: false
    property string customWallpaperUrl: ""
    property int activeVirtualDesktop: 1
    property string activeVirtualDesktopName: "Escritorio 1"
    property int virtualDesktopCount: 2
    property var virtualDesktops: [
        { index: 1, name: "Escritorio 1", active: true, urgent: false },
        { index: 2, name: "Escritorio 2", active: false, urgent: false }
    ]

    // 26H2 Preferences (Synchronized live from ~/.local/state/x64-win11/config.json)
    property string startAllViewMode: "categories"
    property bool startViewDropdownOpen: false
    property bool startPinnedExpanded: false
    property var expandedCategoryObj: null
    property bool showRecommended: false
    property bool showPhoneLink: true
    property bool taskbarCompact: false
    property bool taskbarLeftAlign: false
    property string taskbarSearchMode: "box"     // "box" | "icon" | "hidden"
    property bool showTaskViewBtn: true
    property bool showWeatherWidget: true
    property bool showBatteryPct: true
    property int wallpaperMode: 0                // 0=BloomDark, 1=BloomLight, 2=Monolith, 3=Custom, 4=SolidColor
    property string wallpaperFit: "fill"         // "fill" | "fit" | "stretch" | "center"
    property string solidBgColor: "#141923"
    property string accentColor: "#4cc2ff"
    property bool transparencyEnabled: true
    readonly property color taskbarBg: transparencyEnabled ? "#cc1c1c1c" : "#ff1c1c1c"
    readonly property color panelBg: transparencyEnabled ? "#d6202020" : "#ff202020"
    readonly property color menuBg: transparencyEnabled ? "#e2262626" : "#ff262626"
    property var startRecentFiles: []
    property int lockWallpaperMode: -1           // -1=same as desktop, 0..2=builtin, 3=custom lock img
    property string lockWallpaperUrl: ""
    property bool lockShowStatus: true
    property bool clock12h: false
    property bool clockShowSeconds: false
    property int tzOffsetMins: -99999
    property string kbLayout: "ES"

    function getZonedNow() {
        var now = new Date();
        if (shellRoot.tzOffsetMins > -90000) {
            var deltaMs = (shellRoot.tzOffsetMins + now.getTimezoneOffset()) * 60000;
            return new Date(now.getTime() + deltaMs);
        }
        return now;
    }

    function formatSpanishDate(dt, withYear) {
        var days = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"];
        var months = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
        var base = days[dt.getDay()] + ", " + dt.getDate() + " de " + months[dt.getMonth()];
        return withYear ? (base + " de " + dt.getFullYear()) : base;
    }

    function formatTaskbarClock(dt) {
        if (shellRoot.clock12h) {
            return Qt.formatTime(dt, shellRoot.clockShowSeconds ? "h:mm:ss AP" : "h:mm AP");
        }
        return Qt.formatTime(dt, shellRoot.clockShowSeconds ? "hh:mm:ss" : "hh:mm");
    }

    function kbLangTop(code) {
        var c = String(code || "ES").toUpperCase();
        if (c === "ES" || c === "LATAM") return "ESP";
        if (c === "US") return "ENG";
        if (c === "BR") return "POR";
        if (c === "FR") return "FRA";
        if (c === "DE") return "DEU";
        return c.slice(0, 3);
    }

    function kbLangSub(code) {
        var c = String(code || "ES").toUpperCase();
        return c === "LATAM" ? "LAT" : c;
    }

    function kbLangTooltip(code) {
        var c = String(code || "ES").toUpperCase();
        var names = {
            "ES": "Español (España)",
            "LATAM": "Español (Latinoamérica)",
            "US": "Inglés (Estados Unidos)",
            "BR": "Portugués (Brasil)",
            "FR": "Francés",
            "DE": "Alemán"
        };
        return (names[c] || c) + "\n(Haz clic para cambiar o usa tu atajo de teclado)";
    }
    property string searchQuery: ""

    // Universal Dynamic System & User State (Synchronized from ~/.local/state/x64-win11/sysinfo.json)
    property string userName: "Usuario"
    property string userAvatarUrl: ""
    property string hostName: "x64-lios"
    property bool hasBattery: false
    property int batteryPct: 100
    property string batteryText: "Conectado a CA"
    property bool kdeConnectInstalled: true
    property var phoneLinkData: ({ "kdeInstalled": true, "kdeRunning": false, "scrcpyInstalled": true, "adbInstalled": true, "kdeDevices": [], "adbDevices": [], "mirrorActive": false, "mirrorMode": "", "mirrorSerial": "" })
    property bool phoneMirrorActive: false
    property string phoneMirrorMode: ""
    property string phoneMirrorSerial: ""
    property string _lastPhoneRaw: ""
    onStartOpenChanged: {
        if (startOpen && showPhoneLink) {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "phone", "refresh"]);
        }
    }
    property var desktopIcons: [
        { title: "Este equipo",            iconUrl: shellRoot.assetDir + "thispc.svg",      cmd: "/usr/bin/x64-win11-app explorer 'Este equipo'" },
        { title: "Papelera de\nreciclaje", iconUrl: shellRoot.assetDir + "trash.svg",       cmd: "/usr/bin/x64-win11-app explorer 'Papelera'" },
        { title: "Carpeta\npersonal",      iconUrl: shellRoot.assetDir + "folder-home.svg", cmd: "/usr/bin/x64-win11-app explorer 'Inicio'" },
        { title: "Chromium",               iconUrl: shellRoot.assetDir + "chromium.png",    cmd: "chromium" },
        { title: "Tienda\nShelly",         iconUrl: "file:///usr/share/icons/hicolor/256x256/apps/shelly.png", cmd: "/usr/bin/shelly-ui" },
        { title: "X64 Hello",              iconUrl: shellRoot.assetDir + "x64lios.png",     cmd: "x64-hello" },
        { title: "Configuración\n26H2",    iconUrl: shellRoot.assetDir + "settings.svg",    cmd: "/usr/bin/x64-win11-app settings" }
    ]
    property var taskbarPinned: [
        { id: "explorer", title: "Explorador de archivos", match: "explorer",  iconUrl: shellRoot.assetDir + "explorer.svg", cmd: "/usr/bin/x64-win11-app explorer 'Este equipo'" },
        { id: "browser",  title: "Chromium",               match: "chromium",  iconUrl: shellRoot.assetDir + "chromium.png", cmd: "chromium" },
        { id: "shelly",   title: "Tienda Shelly",          match: "shelly",    iconUrl: "file:///usr/share/icons/hicolor/256x256/apps/shelly.png", cmd: "/usr/bin/shelly-ui" },
        { id: "kitty",    title: "Terminal",               match: "kitty",     iconUrl: shellRoot.assetDir + "terminal.svg", cmd: "kitty" },
        { id: "x64hello", title: "X64 Hello",              match: "x64-hello", iconUrl: shellRoot.assetDir + "x64lios.png",  cmd: "x64-hello" },
        { id: "settings", title: "Configuración",          match: "settings",  iconUrl: shellRoot.assetDir + "settings.svg", cmd: "/usr/bin/x64-win11-app settings" }
    ]

    // Windows 11 Taskbar Hover Tooltip State
    property string tbTooltipText: ""
    property real tbTooltipCenterX: 0
    property real trayChevronX: 1600
    property bool tbTooltipVisible: false

    Timer {
        id: tbTooltipTimer
        interval: 280
        repeat: false
        onTriggered: {
            if (shellRoot.tbTooltipText !== "") shellRoot.tbTooltipVisible = true;
        }
    }

    function showTbTooltip(scr, cx, txt) {
        if (!txt || shellRoot.startOpen || shellRoot.searchOpen || shellRoot.quickSettingsOpen ||
            shellRoot.calendarOpen || shellRoot.weatherOpen || shellRoot.appJumpOpen || shellRoot.trayFlyoutOpen) {
            hideTbTooltip();
            return;
        }
        shellRoot.activeScreen = scr;
        shellRoot.tbTooltipCenterX = cx;
        shellRoot.tbTooltipText = txt;
        if (!shellRoot.tbTooltipVisible) {
            tbTooltipTimer.restart();
        }
    }

    function hideTbTooltip() {
        tbTooltipTimer.stop();
        shellRoot.tbTooltipVisible = false;
        shellRoot.tbTooltipText = "";
    }
    property var startPinned: []
    property var allApps: []
    property var startCategories: []
    property string calendarHeader: Qt.formatDate(new Date(), "MMMM 'de' yyyy")
    property var calendarCells: []

    // =========================================================================
    // AUTHENTIC WINDOWS 11 26H2 NOTIFICATION CENTER, CALENDAR & FOCUS ENGINE
    // =========================================================================
    property var notifItems: [
        {
            uid: 1001,
            app: "Seguridad y rendimiento",
            title: "X64 Windows 11 26H2 activo",
            body: "Perfiles de energía dinámicos y servicios del sistema sincronizados correctamente.",
            time: Qt.formatTime(new Date(), "hh:mm"),
            iconUrl: shellRoot.assetDir + "windows.svg"
        }
    ]
    property bool toastVisible: false
    property var activeToast: null
    property bool notifEnabled: true
    property bool notifShowBanners: true
    property bool notifPlaySound: true
    property int notifBannerSecs: 5
    property var notifMutedApps: ({})
    property var _seenNotifApps: ({})

    Timer {
        id: toastAutoHideTimer
        interval: Math.max(2, shellRoot.notifBannerSecs) * 1000
        repeat: false
        onTriggered: shellRoot.toastVisible = false
    }

    function resolveNotifIcon(appName, rawIcon) {
        if (rawIcon && rawIcon.indexOf("file://") === 0) return rawIcon;
        if (rawIcon && rawIcon.indexOf("/") === 0) return "file://" + rawIcon;
        var q = ((appName || "") + " " + (rawIcon || "")).toLowerCase();
        for (var i = 0; i < shellRoot.allApps.length; i++) {
            var a = shellRoot.allApps[i];
            if (a && a.name && q.indexOf(a.name.toLowerCase()) !== -1 && a.iconUrl) {
                return a.iconUrl;
            }
        }
        if (q.indexOf("shelly") !== -1) return "file:///usr/share/icons/hicolor/256x256/apps/shelly.png";
        if (q.indexOf("recortes") !== -1 || q.indexOf("captura") !== -1) return shellRoot.assetDir + "fluent-image.svg";
        return shellRoot.assetDir + "windows.svg";
    }

    function isNotifAppMuted(appTitle) {
        var k = (appTitle || "Sistema").trim().toLowerCase();
        var map = shellRoot.notifMutedApps || ({});
        if (map[k] === true) return true;
        for (var mk in map) {
            if (map[mk] === true && mk.length >= 3 && k.indexOf(mk) !== -1) return true;
        }
        return false;
    }

    function addInternalNotification(appTitle, summaryText, bodyText, customIconUrl) {
        var cleanApp = (appTitle || "Sistema").trim();
        var appKey = cleanApp.toLowerCase();
        if (cleanApp !== "" && !shellRoot._seenNotifApps[appKey]) {
            var sc = Object.assign({}, shellRoot._seenNotifApps);
            sc[appKey] = true;
            shellRoot._seenNotifApps = sc;
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "record-notif-app", cleanApp]);
        }
        if (!shellRoot.notifEnabled || shellRoot.isNotifAppMuted(cleanApp)) return;
        var entry = {
            uid: Date.now() + Math.floor(Math.random() * 10000),
            app: cleanApp || "Sistema",
            title: summaryText || "Notificación",
            body: bodyText || "",
            time: Qt.formatTime(new Date(), "hh:mm"),
            iconUrl: customIconUrl || (shellRoot.assetDir + "windows.svg")
        };
        var nextList = [entry];
        for (var i = 0; i < Math.min(24, shellRoot.notifItems.length); i++) {
            nextList.push(shellRoot.notifItems[i]);
        }
        shellRoot.notifItems = nextList;
        if (!shellRoot.qsDnd && !shellRoot.calendarOpen && !shellRoot.lockScreenOpen) {
            if (shellRoot.notifShowBanners) {
                shellRoot.activeToast = entry;
                shellRoot.toastVisible = true;
                toastAutoHideTimer.interval = Math.max(2, shellRoot.notifBannerSecs) * 1000;
                toastAutoHideTimer.restart();
            }
            if (shellRoot.notifPlaySound) {
                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "notif-sound"]);
            }
        }
    }

    function dismissNotification(uidVal) {
        var filtered = [];
        for (var i = 0; i < shellRoot.notifItems.length; i++) {
            if (shellRoot.notifItems[i].uid !== uidVal) {
                filtered.push(shellRoot.notifItems[i]);
            }
        }
        shellRoot.notifItems = filtered;
    }

    function clearAllNotifications() {
        shellRoot.notifItems = [];
    }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: (n) => {
            var ic = shellRoot.resolveNotifIcon(n.appName, n.appIcon);
            shellRoot.addInternalNotification(n.appName || "Notificación del sistema", n.summary || n.appName || "Aviso", n.body || "", ic);
            try { n.dismiss(); } catch (e) {}
        }
    }

    // Pure-JS 0ms-Latency 42-Cell Interactive Calendar State
    property int calViewYear: (new Date()).getFullYear()
    property int calViewMonth: (new Date()).getMonth()
    property int calSelectedYear: (new Date()).getFullYear()
    property int calSelectedMonth: (new Date()).getMonth()
    property int calSelectedDay: (new Date()).getDate()
    property bool calendarCollapsed: false
    property string calMonthTitle: ""
    property string calShortTopDate: formatSpanishDate(new Date(), false)
    property var calDayCells: []

    function rebuildInteractiveCalendar() {
        var months = ["enero", "febrero", "marzo", "abril", "mayo", "junio",
                      "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"];
        var y = shellRoot.calViewYear;
        var m = shellRoot.calViewMonth;
        shellRoot.calMonthTitle = months[m] + " de " + y;

        var now = new Date();
        var todayY = now.getFullYear();
        var todayM = now.getMonth();
        var todayD = now.getDate();

        var firstDowJs = (new Date(y, m, 1)).getDay(); // 0=Sun..6=Sat
        var startOffset = (firstDowJs + 6) % 7;        // 0=Mon..6=Sun
        var daysInCur = (new Date(y, m + 1, 0)).getDate();
        var prevY = (m === 0) ? (y - 1) : y;
        var prevM = (m === 0) ? 11 : (m - 1);
        var daysInPrev = (new Date(y, m, 0)).getDate();
        var nextY = (m === 11) ? (y + 1) : y;
        var nextM = (m === 11) ? 0 : (m + 1);

        var arr = [];
        for (var i = 0; i < 42; i++) {
            var cDay = 1;
            var cYear = y;
            var cMonth = m;
            var inCur = true;
            if (i < startOffset) {
                cDay = daysInPrev - startOffset + 1 + i;
                cYear = prevY;
                cMonth = prevM;
                inCur = false;
            } else if (i < startOffset + daysInCur) {
                cDay = i - startOffset + 1;
                cYear = y;
                cMonth = m;
                inCur = true;
            } else {
                cDay = i - (startOffset + daysInCur) + 1;
                cYear = nextY;
                cMonth = nextM;
                inCur = false;
            }
            arr.push({
                day: cDay,
                year: cYear,
                month: cMonth,
                inMonth: inCur,
                isToday: (cYear === todayY && cMonth === todayM && cDay === todayD)
            });
        }
        shellRoot.calDayCells = arr;
    }

    function stepCalendarMonth(delta) {
        var nm = shellRoot.calViewMonth + delta;
        var ny = shellRoot.calViewYear;
        while (nm < 0) { nm += 12; ny -= 1; }
        while (nm > 11) { nm -= 12; ny += 1; }
        shellRoot.calViewYear = ny;
        shellRoot.calViewMonth = nm;
        shellRoot.rebuildInteractiveCalendar();
    }

    function jumpCalendarToToday() {
        var now = new Date();
        shellRoot.calViewYear = now.getFullYear();
        shellRoot.calViewMonth = now.getMonth();
        shellRoot.calSelectedYear = now.getFullYear();
        shellRoot.calSelectedMonth = now.getMonth();
        shellRoot.calSelectedDay = now.getDate();
        shellRoot.calendarCollapsed = false;
        shellRoot.rebuildInteractiveCalendar();
    }

    // Windows 11 26H2 Focus Session ("Concentración") State
    property int focusDurationMins: 30
    property bool focusRunning: false
    property int focusRemainingSecs: 0
    property bool dndBeforeFocus: false

    function stepFocusDuration(deltaSign) {
        var steps = [15, 30, 45, 60, 90, 120, 180, 240];
        var idx = steps.indexOf(shellRoot.focusDurationMins);
        if (idx === -1) idx = 1;
        var nextIdx = Math.max(0, Math.min(steps.length - 1, idx + deltaSign));
        shellRoot.focusDurationMins = steps[nextIdx];
        shellRoot.saveConfigKey("focusDurationMins", String(shellRoot.focusDurationMins));
    }

    function startFocusSession() {
        shellRoot.dndBeforeFocus = shellRoot.qsDnd;
        shellRoot.focusRemainingSecs = shellRoot.focusDurationMins * 60;
        shellRoot.focusRunning = true;
        shellRoot.qsDnd = true;
    }

    function stopFocusSession(completedNaturally) {
        shellRoot.focusRunning = false;
        shellRoot.focusRemainingSecs = 0;
        shellRoot.qsDnd = shellRoot.dndBeforeFocus;
        if (completedNaturally) {
            shellRoot.addInternalNotification(
                "Reloj • Concentración",
                "Sesión de concentración completada",
                "Has completado tus " + shellRoot.focusDurationMins + " minutos de concentración.",
                shellRoot.assetDir + "fluent-bell-filled-accent.svg"
            );
        }
    }

    function formatFocusTime(totalSecs) {
        var s = Math.max(0, Math.floor(totalSecs));
        var hrs = Math.floor(s / 3600);
        var mins = Math.floor((s % 3600) / 60);
        var rem = s % 60;
        var mm = (mins < 10 ? "0" : "") + mins;
        var ss = (rem < 10 ? "0" : "") + rem;
        if (hrs > 0) return hrs + ":" + mm + ":" + ss;
        return mm + ":" + ss;
    }
    property var weatherData: ({
        "city": "Cargando...",
        "location": "Detectando ubicación...",
        "temp": "--°C",
        "desc": "Clima en vivo",
        "icon": "win11-weather.svg",
        "feelsLike": "--°C",
        "humidity": "--%",
        "wind": "-- km/h",
        "pressure": "---- hPa",
        "todayMax": "--°",
        "todayMin": "--°",
        "rainProb": "--%",
        "updatedAt": "--:--",
        "hourly": [],
        "daily": []
    })

    // Quick Settings state (100% Synchronized with Real Linux Hardware)
    property string qsSubView: "main"
    property bool qsWifi: true
    property string qsWifiSsid: "Wi-Fi"
    property var qsWifiNetworks: []
    property bool qsBt: true
    property bool qsGaming: true
    property bool qsNightLight: false
    property real qsNightLightStrength: 45
    property bool identifyActive: false
    property var identifyMap: ({})
    property double lastIdentifyTs: 0
    // Authentic Windows 11 26H2 Center-Bottom Hardware OSD Pill (Fn Volume / Brightness / Mic Mute)
    property bool osdVisible: false
    property string osdKind: "volume"
    property int osdValue: 50
    property bool osdMuted: false
    property double lastOsdTs: 0
    property string _lastOsdRaw: ""
    property bool qsBatterySaver: false
    property bool qsDnd: false
    property real qsBrightness: 100
    property bool brightnessAdjusting: false
    property bool powerProfileAdjusting: false
    property string desiredPowerProfile: ""
    property string qsCpuGov: "Equilibrado"

    Timer {
        id: brightnessCooldownTimer
        interval: 1200
        repeat: false
        onTriggered: shellRoot.brightnessAdjusting = false
    }

    Timer {
        id: identifyHideTimer
        interval: 3200
        repeat: false
        onTriggered: shellRoot.identifyActive = false
    }

    Timer {
        id: osdHideTimer
        interval: 1850
        repeat: false
        onTriggered: shellRoot.osdVisible = false
    }

    Timer {
        id: hwBacklightWriteTimer
        interval: 75
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "brightness", "set", String(Math.round(shellRoot.qsBrightness))]);
        }
    }

    Timer {
        id: powerProfileCooldownTimer
        interval: 800
        repeat: false
        onTriggered: {
            if (!powerProfileProc.running) {
                shellRoot.powerProfileAdjusting = false;
            }
        }
    }

    function applyPowerProfile(nextProfile) {
        shellRoot.powerProfileAdjusting = true;
        shellRoot.desiredPowerProfile = nextProfile;
        shellRoot.qsGaming = (nextProfile === "performance");
        shellRoot.qsBatterySaver = (nextProfile === "power-saver");
        shellRoot.qsCpuGov = (nextProfile === "performance")
                             ? "Gaming X64"
                             : ((nextProfile === "power-saver") ? "Ahorro energía" : "Equilibrado");
        if (!powerProfileProc.running) {
            powerProfileProc.targetArg = nextProfile;
            powerProfileProc.running = true;
        }
    }

    Process {
        id: powerProfileProc
        property string targetArg: "balanced"
        command: ["/usr/bin/x64-win11-ctl", "power-profile", targetArg]
        onExited: {
            if (shellRoot.desiredPowerProfile !== "" && shellRoot.desiredPowerProfile !== targetArg) {
                targetArg = shellRoot.desiredPowerProfile;
                running = true;
            } else {
                powerProfileCooldownTimer.restart();
                if (!statePoller.running) statePoller.running = true;
            }
        }
    }

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property int sinkVolPct: (defaultSink && defaultSink.audio) ? Math.round(defaultSink.audio.volume * 100) : 80
    readonly property bool sinkMuted: (defaultSink && defaultSink.audio) ? Boolean(defaultSink.audio.muted) : false
    PwObjectTracker { objects: [shellRoot.defaultSink] }

    property string lastCmdToken: ""
    property bool firstPollDone: false

    // Live Clock & Focus Session Timer (updates every second so taskbar, lockscreen & Focus countdown never freeze)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var now = shellRoot.getZonedNow();
            shellRoot.currentTimeStr = shellRoot.formatTaskbarClock(now);
            shellRoot.currentDateStr = Qt.formatDate(now, "dd/MM/yyyy");
            shellRoot.currentLongDateStr = shellRoot.formatSpanishDate(now, true);
            shellRoot.currentLockDateStr = shellRoot.formatSpanishDate(now, false);
            shellRoot.calShortTopDate = shellRoot.formatSpanishDate(now, false);
            if (shellRoot.focusRunning) {
                if (shellRoot.focusRemainingSecs > 1) {
                    shellRoot.focusRemainingSecs -= 1;
                } else {
                    shellRoot.stopFocusSession(true);
                }
            }
        }
    }

    function toggleShowDesktop() {
        var list = ToplevelManager.toplevels ? ToplevelManager.toplevels.values : [];
        if (list.length === 0) return;
        var anyVisible = false;
        for (var i = 0; i < list.length; i++) {
            if (!list[i].minimized) {
                anyVisible = true;
                break;
            }
        }
        for (var j = 0; j < list.length; j++) {
            list[j].minimized = anyVisible;
        }
    }

    function toggleWindowFocusOrMinimize(topWin) {
        if (!topWin) return;
        if (topWin.activated && !topWin.minimized) {
            topWin.minimized = true;
        } else {
            topWin.minimized = false;
            topWin.activate();
        }
    }

    function saveConfigKey(k, valJson) {
        shellRoot.cfgWriteGuardUntil = Date.now() + 1400;
        Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "set-config", k, valJson]);
    }

    function closeAllPopups() {
        startOpen = false;
        searchOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        weatherOpen = false;
        taskViewOpen = false;
        appJumpOpen = false;
        trayFlyoutOpen = false;
        powerPopupOpen = false;
        ctxMenuOpen = false;
        ctxSubMenu = "";
        desktopItemCtxOpen = false;
        winXMenuOpen = false;
        winXSubOpen = "";
        startAppCtxOpen = false;
        taskbarCtxOpen = false;
        qsSubView = "main";
    }

    function isCmdPinnedStart(cmdStr) {
        if (!cmdStr) return false;
        var list = shellRoot.startPinned || [];
        for (var i = 0; i < list.length; i++) {
            if (list[i].cmd === cmdStr) return true;
        }
        return false;
    }

    function isCmdPinnedTaskbar(cmdStr) {
        if (!cmdStr) return false;
        var list = shellRoot.taskbarPinned || [];
        for (var i = 0; i < list.length; i++) {
            if (list[i].cmd === cmdStr) return true;
        }
        return false;
    }

    function openPropertiesDialog(itemObj) {
        shellRoot.closeAllPopups();
        shellRoot.propertiesData = itemObj;
        shellRoot.propertiesModalOpen = true;
    }

    function openDesktopRenameDialog(itemObj) {
        if (!itemObj || !itemObj.realPath) return;
        shellRoot.closeAllPopups();
        shellRoot.desktopRenameData = itemObj;
        shellRoot.desktopRenameOpen = true;
    }

    function execDesktopBgAction(id) {
        closeAllPopups();
        if (id === "refresh") {
            triggerDesktopRefresh();
        } else if (id === "paste") {
            var srcArr = (desktopClipboardPaths && desktopClipboardPaths.length > 0)
                         ? desktopClipboardPaths
                         : (desktopClipboardPath !== "" ? [desktopClipboardPath] : []);
            if (srcArr.length > 0) {
                var m = desktopClipboardCut ? "cut" : "copy";
                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "paste-desktop", m].concat(srcArr));
                if (desktopClipboardCut) {
                    desktopClipboardPaths = [];
                    desktopClipboardPath = "";
                    desktopClipboardCut = false;
                    Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "set-clipboard", "copy"]);
                }
            }
        } else if (id === "display") {
            spawnCmd("/usr/bin/x64-win11-app settings 'Sistema'");
        } else if (id === "person") {
            spawnCmd("/usr/bin/x64-win11-app settings 'Personalización'");
        } else if (id === "term") {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "open-terminal", "desktop"]);
        }
    }

    function execDesktopSubAction(a) {
        if (a === "sz_large" || a === "sz_medium" || a === "sz_small") {
            var sz = a.substring(3);
            desktopIconSizeMode = sz;
            saveConfigKey("desktopIconSizeMode", "\"" + sz + "\"");
            closeAllPopups();
        } else if (a === "toggle_auto_arrange") {
            var nextAuto = !desktopAutoArrange;
            desktopAutoArrange = nextAuto;
            saveConfigKey("desktopAutoArrange", nextAuto ? "true" : "false");
            if (nextAuto) {
                desktopIconPositions = ({});
                saveConfigKey("desktopIconPositions", "{}");
            }
            closeAllPopups();
        } else if (a === "toggle_ic") {
            var nextShow = !showDesktopIcons;
            showDesktopIcons = nextShow;
            saveConfigKey("showDesktopIcons", nextShow ? "true" : "false");
            closeAllPopups();
        } else if (a === "restore_ic") {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "restore-desktop-icons"]);
            closeAllPopups();
        } else if (a.indexOf("sort_") === 0) {
            var sm = a.substring(5);
            if (desktopSortMode === sm) {
                desktopSortAsc = !desktopSortAsc;
                saveConfigKey("desktopSortAsc", desktopSortAsc ? "true" : "false");
            } else {
                desktopSortMode = sm;
                desktopSortAsc = true;
                saveConfigKey("desktopSortMode", "\"" + sm + "\"");
                saveConfigKey("desktopSortAsc", "true");
            }
            // Windows 11 behavior: sorting resets manual desktop slot overrides cleanly
            desktopIconPositions = ({});
            saveConfigKey("desktopIconPositions", "{}");
            closeAllPopups();
        } else if (a === "new_folder") {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "new-desktop-folder"]);
            closeAllPopups();
        } else if (a === "new_shortcut") {
            closeAllPopups();
            newShortcutModalOpen = true;
        } else if (a === "new_doc") {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "new-desktop-doc"]);
            closeAllPopups();
        } else if (a === "new_md") {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "new-desktop-md"]);
            closeAllPopups();
        } else if (a === "next_wp") {
            var nextWp = (wallpaperMode + 1) % 3;
            wallpaperMode = nextWp;
            saveConfigKey("wallpaperMode", String(nextWp));
            closeAllPopups();
        } else if (a === "explorer") {
            spawnCmd("/usr/bin/x64-win11-app explorer 'Este equipo'");
            closeAllPopups();
        } else if (a === "taskmgr") {
            spawnCmd("/usr/bin/x64-win11-app taskmgr");
            closeAllPopups();
        } else if (a === "run_dlg") {
            closeAllPopups();
            runDialogOpen = true;
        } else if (a === "x64hello") {
            spawnCmd("x64-hello");
            closeAllPopups();
        }
    }

    function execDesktopQuickAction(qa) {
        var d = desktopItemData;
        var multi = (desktopSelectedItems && desktopSelectedItems.length > 1) ? desktopSelectedItems : (d ? [d] : []);
        if (multi.length === 0) return;

        var fsPaths = [];
        var appIds = [];
        for (var i = 0; i < multi.length; i++) {
            var it = multi[i];
            if (it.kind === "app" && it.id) appIds.push(it.id);
            else if ((it.kind === "folder" || it.kind === "file" || it.kind === "shortcut_file") && it.realPath) fsPaths.push(it.realPath);
        }

        if (qa === "q_cut" && fsPaths.length > 0) {
            desktopClipboardPaths = fsPaths;
            desktopClipboardPath = fsPaths[0];
            desktopClipboardCut = true;
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "set-clipboard", "cut"].concat(fsPaths));
            closeAllPopups();
        } else if (qa === "q_copy" && fsPaths.length > 0) {
            desktopClipboardPaths = fsPaths;
            desktopClipboardPath = fsPaths[0];
            desktopClipboardCut = false;
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "set-clipboard", "copy"].concat(fsPaths));
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "copy-text", fsPaths.join("\n")]);
            closeAllPopups();
        } else if (qa === "q_copy_path" && d) {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "copy-text", d.realPath || d.cmd || ""]);
            closeAllPopups();
        } else if (qa === "q_rename" && d) {
            openDesktopRenameDialog(d);
        } else if (qa === "q_delete") {
            if (fsPaths.length > 0) {
                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "trash-path"].concat(fsPaths));
            }
            if (appIds.length > 0) {
                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "hide-desktop-id"].concat(appIds));
            }
            desktopSelectedItems = [];
            closeAllPopups();
        }
    }

    function execDesktopItemAction(act) {
        var d = desktopItemData;
        var multi = (desktopSelectedItems && desktopSelectedItems.length > 1) ? desktopSelectedItems : (d ? [d] : []);
        if (!d) return;
        if (act === "props") {
            openPropertiesDialog(d);
            return;
        }
        if (act === "open") {
            for (var oi = 0; oi < Math.min(5, multi.length); oi++) {
                if (multi[oi] && multi[oi].cmd) spawnCmd(multi[oi].cmd);
            }
        } else if (act === "empty_trash") {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "empty-trash"]);
        } else if (act === "disks") {
            spawnCmd("gnome-disks");
        } else if (act === "taskmgr") {
            spawnCmd("/usr/bin/x64-win11-app taskmgr");
        } else if (act === "term_home") {
            var tTarget = (d.kind === "thispc") ? "/" : (d.realPath || "home");
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "open-terminal", tTarget]);
        } else if (act === "term_dir" && d.realPath) {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "open-terminal", String(d.realPath)]);
        } else if (act === "sys_props") {
            spawnCmd("/usr/bin/x64-win11-app settings 'Sistema'");
        } else if (act === "run_admin") {
            spawnCmd("pkexec " + d.cmd + " || kitty -e sudo " + d.cmd);
        } else if (act === "open_loc") {
            spawnCmd("/usr/bin/x64-win11-app explorer '/usr/share/applications'");
        } else if (act === "pin_start") {
            var cleanTitle = String(d.title || "App").replace(/\n/g, " ");
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "toggle-pin-start", cleanTitle, d.cmd, d.iconUrl || ""]);
        } else if (act === "pin_tb") {
            var cleanT = String(d.title || "App").replace(/\n/g, " ");
            var mKey = String(d.cmd || "").split(" ")[0].split("/").pop();
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "toggle-pin-taskbar", cleanT, d.cmd, d.iconUrl || "", mKey]);
        } else if (act === "copy_path") {
            var cPaths = [];
            for (var ci = 0; ci < multi.length; ci++) {
                if (multi[ci] && (multi[ci].realPath || multi[ci].cmd)) cPaths.push(multi[ci].realPath || multi[ci].cmd);
            }
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "copy-text", cPaths.join("\n")]);
        } else if (act === "zip_item") {
            var zPaths = [];
            for (var zi = 0; zi < multi.length; zi++) {
                if (multi[zi] && multi[zi].realPath && (multi[zi].kind === "folder" || multi[zi].kind === "file" || multi[zi].kind === "shortcut_file")) {
                    zPaths.push(multi[zi].realPath);
                }
            }
            if (zPaths.length > 0) {
                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "zip-path"].concat(zPaths));
            }
        } else if (act === "set_wp" && d.realPath) {
            var wpU = "file://" + d.realPath;
            customWallpaperUrl = wpU;
            wallpaperMode = 3;
            saveConfigKey("customWallpaperUrl", JSON.stringify(wpU));
            saveConfigKey("wallpaperMode", "3");
        }
        closeAllPopups();
    }

    function execStartAppAction(a) {
        var d = startAppCtxData;
        if (!d) return;
        if (a === "open") {
            spawnCmd(d.cmd);
            startAppCtxOpen = false;
            startOpen = false;
        } else if (a === "admin") {
            spawnCmd("pkexec " + d.cmd + " || kitty -e sudo " + d.cmd);
            startAppCtxOpen = false;
            startOpen = false;
        } else if (a === "pin_start") {
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "toggle-pin-start", d.name || "App", d.cmd, d.iconUrl || ""]);
            startAppCtxOpen = false;
        } else if (a === "pin_tb") {
            var mKey = String(d.cmd || "").split(" ")[0].split("/").pop();
            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "toggle-pin-taskbar", d.name || "App", d.cmd, d.iconUrl || "", mKey]);
            startAppCtxOpen = false;
        } else if (a === "uninstall") {
            var rawName = String(d.id || d.name || d.title || "").replace(/\n/g, " ").trim();
            var rawCmd = String(d.cmd || "").trim();
            var uSpec = rawName !== "" ? (rawCmd !== "" ? (rawName + "||" + rawCmd) : rawName) : rawCmd;
            if (uSpec !== "") {
                Quickshell.execDetached(["/usr/bin/x64-win11-app", "settings", "Aplicaciones:Desinstalar:" + uSpec]);
            } else {
                Quickshell.execDetached(["/usr/bin/x64-win11-app", "settings", "Aplicaciones:Aplicaciones instaladas"]);
            }
            startAppCtxOpen = false;
            startOpen = false;
        }
    }

    readonly property var sortedDesktopIcons: {
        var src = shellRoot.desktopIcons ? shellRoot.desktopIcons.slice() : [];
        var dirMul = shellRoot.desktopSortAsc ? 1 : -1;
        if (shellRoot.desktopSortMode === "name" || shellRoot.desktopSortMode === "name_asc") {
            src.sort(function(a, b) {
                return dirMul * String(a.title || "").localeCompare(String(b.title || ""));
            });
        } else if (shellRoot.desktopSortMode === "name_desc") {
            src.sort(function(a, b) {
                return String(b.title || "").localeCompare(String(a.title || ""));
            });
        } else if (shellRoot.desktopSortMode === "size") {
            src.sort(function(a, b) {
                return dirMul * (Number(b.sizeBytes || 0) - Number(a.sizeBytes || 0));
            });
        } else if (shellRoot.desktopSortMode === "date") {
            src.sort(function(a, b) {
                return dirMul * (Number(b.mtimeTs || 0) - Number(a.mtimeTs || 0));
            });
        } else if (shellRoot.desktopSortMode === "type") {
            src.sort(function(a, b) {
                return dirMul * String(a.typeLabel || a.kind || "").localeCompare(String(b.typeLabel || b.kind || ""));
            });
        }
        return src;
    }

    Timer {
        id: desktopRefreshTimer
        interval: 150
        repeat: false
        onTriggered: shellRoot.desktopRefreshing = false
    }

    function triggerDesktopRefresh() {
        shellRoot.desktopRefreshing = true;
        desktopRefreshTimer.restart();
        Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "sysinfo"]);
    }

    function resolveWindowIconUrl(topWin) {
        if (!topWin) return shellRoot.assetDir + "windows.svg";
        var aid = String(topWin.appId || "").toLowerCase();
        var ttl = String(topWin.title || "").toLowerCase();
        if (aid.indexOf("explorer") !== -1 || ttl.indexOf("explorador") !== -1) return shellRoot.assetDir + "explorer.svg";
        if (aid.indexOf("settings") !== -1 || ttl.indexOf("configuración") !== -1) return shellRoot.assetDir + "settings.svg";
        if (aid.indexOf("taskmgr") !== -1 || ttl.indexOf("administrador de tareas") !== -1) return shellRoot.assetDir + "taskmgr.svg";
        if (aid.indexOf("shelly") !== -1) return "file:///usr/share/icons/hicolor/256x256/apps/shelly.png";
        if (aid.indexOf("antigravity") !== -1 || ttl.indexOf("antigravity") !== -1) return shellRoot.assetDir + "antigravity.png";
        if (aid.indexOf("kitty") !== -1) return shellRoot.assetDir + "terminal.svg";
        if (aid.indexOf("chromium") !== -1) return shellRoot.assetDir + "chromium.png";
        var pinned = shellRoot.taskbarPinned || [];
        for (var i = 0; i < pinned.length; i++) {
            var m = String(pinned[i].match || "").toLowerCase();
            if (m !== "" && (aid.indexOf(m) !== -1 || ttl.indexOf(m) !== -1) && pinned[i].iconUrl) {
                return pinned[i].iconUrl;
            }
        }
        var apps = shellRoot.allApps || [];
        for (var j = 0; j < apps.length; j++) {
            var an = String(apps[j].name || "").toLowerCase();
            var ac = String(apps[j].id || "").toLowerCase();
            if ((ac !== "" && aid !== "" && (ac.indexOf(aid) !== -1 || aid.indexOf(ac) !== -1)) ||
                (an !== "" && aid !== "" && an.indexOf(aid) !== -1)) {
                if (apps[j].iconUrl) return apps[j].iconUrl;
            }
        }
        return shellRoot.assetDir + "fluent-window-apps.svg";
    }

    function executeRunCommand(rawText) {
        var t = String(rawText || "").trim();
        if (t === "") return;
        var low = t.toLowerCase();
        if (low === "explorer" || low === "explorer.exe" || low === ".") {
            shellRoot.spawnCmd("/usr/bin/x64-win11-app explorer 'Este equipo'");
        } else if (low === "taskmgr" || low === "taskmgr.exe") {
            shellRoot.spawnCmd("/usr/bin/x64-win11-app taskmgr");
        } else if (low === "control" || low === "ms-settings:" || low === "desk.cpl") {
            shellRoot.spawnCmd("/usr/bin/x64-win11-app settings");
        } else if (low === "cmd" || low === "cmd.exe" || low === "powershell" || low === "wt") {
            shellRoot.spawnCmd("kitty");
        } else if (low === "calc" || low === "calc.exe") {
            shellRoot.spawnCmd("gnome-calculator");
        } else if (low === "notepad" || low === "notepad.exe") {
            shellRoot.spawnCmd("gnome-text-editor");
        } else if (low.indexOf("http://") === 0 || low.indexOf("https://") === 0) {
            shellRoot.spawnCmd("xdg-open '" + t.replace(/'/g, "'\\''") + "'");
        } else if (low.indexOf("www.") === 0) {
            shellRoot.spawnCmd("xdg-open 'https://" + t.replace(/'/g, "'\\''") + "'");
        } else if (t.indexOf("/") === 0 || t.indexOf("~/") === 0) {
            var expanded = (t.indexOf("~/") === 0) ? ("$HOME/" + t.substring(2)) : t;
            shellRoot.spawnCmd("xdg-open \"" + expanded + "\"");
        } else {
            shellRoot.spawnCmd(t);
        }
    }

    function spawnCmd(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function triggerLiveWeatherRefresh() {
        shellRoot.weatherRefreshing = true;
        weatherSpinMinTimer.restart();
        if (!weatherRefreshProc.running) {
            weatherRefreshProc.running = true;
        }
    }

    Timer {
        id: weatherSpinMinTimer
        interval: 850
        repeat: false
        onTriggered: {
            if (!weatherRefreshProc.running) shellRoot.weatherRefreshing = false;
        }
    }

    property bool wifiRescanning: false
    function triggerWifiRescan() {
        shellRoot.wifiRescanning = true;
        wifiSpinMinTimer.restart();
        if (!wifiRescanProc.running) {
            wifiRescanProc.running = true;
        }
    }

    Timer {
        id: wifiSpinMinTimer
        interval: 850
        repeat: false
        onTriggered: {
            if (!wifiRescanProc.running) shellRoot.wifiRescanning = false;
        }
    }

    Process {
        id: wifiRescanProc
        command: ["/usr/bin/x64-win11-ctl", "wifi", "rescan"]
        onExited: {
            if (!wifiSpinMinTimer.running) shellRoot.wifiRescanning = false;
            if (!statePoller.running) statePoller.running = true;
        }
    }

    Process {
        id: weatherRefreshProc
        command: ["/usr/bin/x64-win11-app", "--refresh-weather"]
        onExited: {
            if (!weatherSpinMinTimer.running) shellRoot.weatherRefreshing = false;
            if (!statePoller.running) statePoller.running = true;
        }
    }

    Process {
        id: wsSyncProc
        command: ["/usr/bin/x64-win11-workspaces", "sync"]
        onExited: {
            if (!statePoller.running) statePoller.running = true;
        }
    }

    Process {
        id: unlockAuthProc
        command: ["/usr/bin/x64-win11-ctl", "verify-unlock"]
        environment: ({ X64_UNLOCK_SECRET: "" })
        onExited: (exitCode, exitStatus) => {
            shellRoot.lockAuthChecking = false;
            unlockAuthProc.environment = ({ X64_UNLOCK_SECRET: "" });
            if (exitCode === 0) {
                shellRoot.lockAuthError = "";
                shellRoot.lockPromptOpen = false;
                shellRoot.lockScreenOpen = false;
            } else {
                shellRoot.lockAuthError = "PIN o contraseña incorrectos. Inténtalo de nuevo.";
            }
        }
    }

    function submitLockUnlock(secretStr) {
        if (!shellRoot.lockRequireAuth) {
            shellRoot.lockAuthError = "";
            shellRoot.lockPromptOpen = false;
            shellRoot.lockScreenOpen = false;
            return;
        }
        var s = String(secretStr || "");
        if (s === "") {
            shellRoot.lockAuthError = "Introduce tu PIN o contraseña para desbloquear.";
            return;
        }
        if (shellRoot.lockAuthChecking) return;
        shellRoot.lockAuthError = "";
        shellRoot.lockAuthChecking = true;
        unlockAuthProc.environment = ({ X64_UNLOCK_SECRET: s });
        unlockAuthProc.running = true;
    }

    // Poll IPC Command File, Config JSON, Shared Clipboard, Workspaces & Dynamic SysInfo JSON (Diff-guarded for zero flicker!)
    Process {
        id: statePoller
        command: ["sh", "-c", "cat ~/.local/state/x64-win11/cmd 2>/dev/null || echo ''; echo '---CFG---'; cat ~/.local/state/x64-win11/config.json 2>/dev/null || echo '{}'; echo '---SYS---'; cat ~/.local/state/x64-win11/sysinfo.json 2>/dev/null || echo '{}'; echo '---CLIP---'; cat ~/.local/state/x64-win11/clipboard.json 2>/dev/null || echo '{}'; echo '---WS---'; cat ~/.local/state/x64-win11/workspaces.json 2>/dev/null || echo '{}'; echo '---OSD---'; cat ~/.local/state/x64-win11/osd.json 2>/dev/null || echo '{}'; echo '---PHONE---'; cat ~/.local/state/x64-win11/phone-mirror.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text || "";
                var parts = raw.split("---CFG---");
                var cmdLine = (parts[0] || "").trim();
                var isFirst = !shellRoot.firstPollDone;
                if (isFirst) {
                    shellRoot.lastCmdToken = cmdLine;
                    shellRoot.firstPollDone = true;
                } else if (cmdLine !== "" && cmdLine !== shellRoot.lastCmdToken) {
                    var act = cmdLine.split(":")[0];
                    if (act === "toggle-start") {
                        var ns = !shellRoot.startOpen;
                        shellRoot.closeAllPopups();
                        shellRoot.startOpen = ns;
                    } else if (act === "toggle-qs") {
                        var nq = !shellRoot.quickSettingsOpen;
                        shellRoot.closeAllPopups();
                        shellRoot.quickSettingsOpen = nq;
                    } else if (act === "toggle-calendar") {
                        var nc = !shellRoot.calendarOpen;
                        shellRoot.closeAllPopups();
                        shellRoot.calendarOpen = nc;
                    } else if (act === "toggle-taskview") {
                        var ntv = !shellRoot.taskViewOpen;
                        shellRoot.closeAllPopups();
                        shellRoot.taskViewOpen = ntv;
                    } else if (act === "toggle-winx") {
                        var nwx = !shellRoot.winXMenuOpen;
                        shellRoot.closeAllPopups();
                        shellRoot.winXMenuX = 12;
                        shellRoot.winXMenuOpen = nwx;
                    } else if (act === "toggle-run") {
                        shellRoot.closeAllPopups();
                        shellRoot.runDialogOpen = !shellRoot.runDialogOpen;
                    } else if (act === "lock") {
                        shellRoot.closeAllPopups();
                        shellRoot.lockPromptOpen = false;
                        shellRoot.lockScreenOpen = true;
                    } else if (act === "clear-notifs") {
                        shellRoot.clearAllNotifications();
                        shellRoot.toastVisible = false;
                    }
                    shellRoot.lastCmdToken = cmdLine;
                }
                if (parts.length > 1) {
                    var subParts = parts[1].split("---SYS---");
                    var cfgRaw = (subParts[0] || "{}").trim();
                    var cfgObj = {};
                    if (isFirst || (cfgRaw !== shellRoot._lastCfgRaw && Date.now() >= shellRoot.cfgWriteGuardUntil)) {
                        shellRoot._lastCfgRaw = cfgRaw;
                        try {
                            var cfg = JSON.parse(cfgRaw);
                            cfgObj = cfg;
                            if (cfg.taskbarCompact !== undefined) shellRoot.taskbarCompact = Boolean(cfg.taskbarCompact);
                            if (cfg.taskbarLeftAlign !== undefined) shellRoot.taskbarLeftAlign = Boolean(cfg.taskbarLeftAlign);
                            if (cfg.taskbarSearchMode !== undefined) shellRoot.taskbarSearchMode = String(cfg.taskbarSearchMode);
                            if (cfg.showTaskViewBtn !== undefined) shellRoot.showTaskViewBtn = Boolean(cfg.showTaskViewBtn);
                            if (cfg.showWeatherWidget !== undefined) shellRoot.showWeatherWidget = Boolean(cfg.showWeatherWidget);
                            if (cfg.startAllViewMode !== undefined) shellRoot.startAllViewMode = String(cfg.startAllViewMode);
                            if (cfg.showRecommended !== undefined) shellRoot.showRecommended = Boolean(cfg.showRecommended);
                            if (cfg.showPhoneLink !== undefined) shellRoot.showPhoneLink = Boolean(cfg.showPhoneLink);
                            if (cfg.showBatteryPct !== undefined) shellRoot.showBatteryPct = Boolean(cfg.showBatteryPct);
                            if (cfg.wallpaperMode !== undefined) shellRoot.wallpaperMode = Number(cfg.wallpaperMode);
                            if (cfg.wallpaperFit !== undefined) shellRoot.wallpaperFit = String(cfg.wallpaperFit);
                            if (cfg.solidBgColor !== undefined) shellRoot.solidBgColor = String(cfg.solidBgColor);
                            if (cfg.accentColor !== undefined && String(cfg.accentColor).indexOf("#") === 0) shellRoot.accentColor = String(cfg.accentColor);
                            if (cfg.transparencyEnabled !== undefined) shellRoot.transparencyEnabled = Boolean(cfg.transparencyEnabled);
                            if (cfg.lockWallpaperMode !== undefined) shellRoot.lockWallpaperMode = Number(cfg.lockWallpaperMode);
                            if (cfg.lockWallpaperUrl !== undefined) shellRoot.lockWallpaperUrl = String(cfg.lockWallpaperUrl);
                            if (cfg.lockShowStatus !== undefined) shellRoot.lockShowStatus = Boolean(cfg.lockShowStatus);
                            if (cfg.lockRequireAuth !== undefined) shellRoot.lockRequireAuth = Boolean(cfg.lockRequireAuth);
                            if (cfg.customWallpaperUrl !== undefined) shellRoot.customWallpaperUrl = String(cfg.customWallpaperUrl);
                            if (cfg.userAvatarUrl !== undefined) shellRoot.userAvatarUrl = String(cfg.userAvatarUrl);
                            if (cfg.clock12h !== undefined) {
                                shellRoot.clock12h = Boolean(cfg.clock12h);
                                shellRoot.currentTimeStr = shellRoot.formatTaskbarClock(shellRoot.getZonedNow());
                            }
                            if (cfg.clockShowSeconds !== undefined) {
                                shellRoot.clockShowSeconds = Boolean(cfg.clockShowSeconds);
                                shellRoot.currentTimeStr = shellRoot.formatTaskbarClock(shellRoot.getZonedNow());
                            }
                            if (cfg.kbLayout !== undefined) shellRoot.kbLayout = String(cfg.kbLayout).toUpperCase();
                            if (cfg.desktopIconSizeMode !== undefined) shellRoot.desktopIconSizeMode = String(cfg.desktopIconSizeMode);
                            if (cfg.showDesktopIcons !== undefined) shellRoot.showDesktopIcons = Boolean(cfg.showDesktopIcons);
                            if (cfg.desktopAutoArrange !== undefined) shellRoot.desktopAutoArrange = Boolean(cfg.desktopAutoArrange);
                            if (cfg.desktopIconPositions !== undefined && typeof cfg.desktopIconPositions === "object") shellRoot.desktopIconPositions = cfg.desktopIconPositions;
                            if (cfg.desktopSortMode !== undefined) shellRoot.desktopSortMode = String(cfg.desktopSortMode);
                            if (cfg.desktopSortAsc !== undefined) shellRoot.desktopSortAsc = Boolean(cfg.desktopSortAsc);
                            if (cfg.nightLight !== undefined) shellRoot.qsNightLight = Boolean(cfg.nightLight);
                            if (cfg.nightLightStrength !== undefined) shellRoot.qsNightLightStrength = Math.max(15, Math.min(100, Number(cfg.nightLightStrength)));
                            if (cfg.identifyDisplays && typeof cfg.identifyDisplays === "object") {
                                var idTs = Number(cfg.identifyDisplays.ts || 0);
                                if (idTs > shellRoot.lastIdentifyTs) {
                                    var wasInit = (shellRoot.lastIdentifyTs === 0 && (Date.now() - idTs) > 4000);
                                    shellRoot.lastIdentifyTs = idTs;
                                    if (!wasInit) {
                                        shellRoot.identifyMap = cfg.identifyDisplays.map || ({});
                                        shellRoot.identifyActive = true;
                                        identifyHideTimer.restart();
                                    }
                                }
                            }
                            if (cfg.doNotDisturb !== undefined && !shellRoot.focusRunning) shellRoot.qsDnd = Boolean(cfg.doNotDisturb);
                            if (cfg.notifEnabled !== undefined) shellRoot.notifEnabled = Boolean(cfg.notifEnabled);
                            if (cfg.notifShowBanners !== undefined) shellRoot.notifShowBanners = Boolean(cfg.notifShowBanners);
                            if (cfg.notifPlaySound !== undefined) shellRoot.notifPlaySound = Boolean(cfg.notifPlaySound);
                            if (cfg.notifBannerSecs !== undefined) shellRoot.notifBannerSecs = Math.max(2, Math.min(20, Number(cfg.notifBannerSecs)));
                            if (cfg.notifMutedApps !== undefined && typeof cfg.notifMutedApps === "object") shellRoot.notifMutedApps = cfg.notifMutedApps;
                            if (cfg.focusDurationMins !== undefined && !shellRoot.focusRunning) shellRoot.focusDurationMins = Math.max(15, Math.min(240, Number(cfg.focusDurationMins)));
                            if (cfg.brightnessPct !== undefined && !shellRoot.brightnessAdjusting) shellRoot.qsBrightness = Number(cfg.brightnessPct);
                        } catch (e) {}
                    }

                    if (subParts.length > 1) {
                        var sysClipParts = subParts[1].split("---CLIP---");
                        var sysRaw = (sysClipParts[0] || "{}").trim();
                        if (isFirst || sysRaw !== shellRoot._lastSysRaw) {
                            shellRoot._lastSysRaw = sysRaw;
                            try {
                                var sys = JSON.parse(sysRaw);
                                if (sys.user) shellRoot.userName = sys.user;
                                if (sys.userAvatarUrl !== undefined) shellRoot.userAvatarUrl = String(sys.userAvatarUrl);
                                if (sys.tzOffsetMins !== undefined && !isNaN(Number(sys.tzOffsetMins))) {
                                    shellRoot.tzOffsetMins = Number(sys.tzOffsetMins);
                                    var zNow = shellRoot.getZonedNow();
                                    shellRoot.currentTimeStr = shellRoot.formatTaskbarClock(zNow);
                                    shellRoot.currentDateStr = Qt.formatDate(zNow, "dd/MM/yyyy");
                                    shellRoot.currentLongDateStr = shellRoot.formatSpanishDate(zNow, true);
                                    shellRoot.currentLockDateStr = shellRoot.formatSpanishDate(zNow, false);
                                    shellRoot.calShortTopDate = shellRoot.formatSpanishDate(zNow, false);
                                }
                                if (sys.hostname) shellRoot.hostName = sys.hostname;
                                if (sys.hasBattery !== undefined) shellRoot.hasBattery = Boolean(sys.hasBattery);
                                if (sys.batteryPct !== undefined) shellRoot.batteryPct = Number(sys.batteryPct);
                                if (sys.batteryText) shellRoot.batteryText = sys.batteryText;
                                if (sys.trashHasFiles !== undefined) shellRoot.trashHasFiles = Boolean(sys.trashHasFiles);
                                if (sys.trashCount !== undefined) shellRoot.trashCount = Number(sys.trashCount);
                                if (sys.trashSize !== undefined) shellRoot.trashSize = String(sys.trashSize);
                                if (sys.hasHiddenDesktopIcons !== undefined) shellRoot.hasHiddenDesktopIcons = Boolean(sys.hasHiddenDesktopIcons);
                                if (sys.kdeConnectInstalled !== undefined) shellRoot.kdeConnectInstalled = Boolean(sys.kdeConnectInstalled);
                                if (sys.phoneLink && typeof sys.phoneLink === "object") shellRoot.phoneLinkData = sys.phoneLink;
                                if (sys.desktopIcons && sys.desktopIcons.length > 0) shellRoot.desktopIcons = sys.desktopIcons;
                                if (sys.taskbarPinned && sys.taskbarPinned.length > 0) shellRoot.taskbarPinned = sys.taskbarPinned;
                                if (sys.startPinned && sys.startPinned.length > 0) shellRoot.startPinned = sys.startPinned;
                                if (sys.recentFiles !== undefined && Array.isArray(sys.recentFiles)) shellRoot.startRecentFiles = sys.recentFiles;
                                if (sys.allApps && sys.allApps.length > 0) shellRoot.allApps = sys.allApps;
                                if (sys.categories && sys.categories.length > 0) shellRoot.startCategories = sys.categories;
                                if (sys.calendar) {
                                    if (sys.calendar.header) shellRoot.calendarHeader = sys.calendar.header;
                                    if (sys.calendar.cells) shellRoot.calendarCells = sys.calendar.cells;
                                }
                                if (sys.weather) {
                                    shellRoot.weatherData = sys.weather;
                                }
                                if (sys.hwControls) {
                                    if (sys.hwControls.wifiEnabled !== undefined) shellRoot.qsWifi = Boolean(sys.hwControls.wifiEnabled);
                                    if (sys.hwControls.wifiSsid) shellRoot.qsWifiSsid = String(sys.hwControls.wifiSsid);
                                    if (sys.hwControls.wifiNetworks) shellRoot.qsWifiNetworks = sys.hwControls.wifiNetworks;
                                    if (sys.hwControls.btEnabled !== undefined) shellRoot.qsBt = Boolean(sys.hwControls.btEnabled);
                                    if (sys.hwControls.brightnessPct !== undefined && !shellRoot.brightnessAdjusting && cfgObj.brightnessPct === undefined) {
                                        shellRoot.qsBrightness = Number(sys.hwControls.brightnessPct);
                                    }
                                    if (!shellRoot.powerProfileAdjusting) {
                                        if (sys.hwControls.cpuGovernor) shellRoot.qsCpuGov = String(sys.hwControls.cpuGovernor);
                                        if (sys.hwControls.gamingActive !== undefined) shellRoot.qsGaming = Boolean(sys.hwControls.gamingActive);
                                        if (sys.hwControls.powerSaverActive !== undefined) shellRoot.qsBatterySaver = Boolean(sys.hwControls.powerSaverActive);
                                    }
                                }
                            } catch (e2) {}
                        }
                        if (sysClipParts.length > 1) {
                            var clipWsParts = (sysClipParts[1] || "{}").split("---WS---");
                            var clipRaw = (clipWsParts[0] || "{}").trim();
                            if (clipRaw !== shellRoot._lastClipRaw) {
                                shellRoot._lastClipRaw = clipRaw;
                                try {
                                    var cl = JSON.parse(clipRaw);
                                    if (cl && Array.isArray(cl.paths)) {
                                        shellRoot.desktopClipboardPaths = cl.paths;
                                        shellRoot.desktopClipboardPath = cl.paths.length > 0 ? cl.paths[0] : "";
                                        shellRoot.desktopClipboardCut = (cl.mode === "cut");
                                    }
                                } catch (e3) {}
                            }
                            if (clipWsParts.length > 1) {
                                var wsOsdParts = (clipWsParts[1] || "{}").split("---OSD---");
                                var wsRaw = (wsOsdParts[0] || "{}").trim();
                                if (wsRaw !== shellRoot._lastWsRaw && wsRaw !== "{}") {
                                    shellRoot._lastWsRaw = wsRaw;
                                    try {
                                        var ws = JSON.parse(wsRaw);
                                        if (ws && Array.isArray(ws.desktops) && ws.desktops.length > 0) {
                                            shellRoot.virtualDesktops = ws.desktops;
                                            shellRoot.virtualDesktopCount = ws.desktops.length;
                                            if (ws.active !== undefined) shellRoot.activeVirtualDesktop = Number(ws.active);
                                            if (ws.activeName) shellRoot.activeVirtualDesktopName = String(ws.activeName);
                                        }
                                    } catch (e4) {}
                                }
                                if (wsOsdParts.length > 1) {
                                    var osdPhoneParts = (wsOsdParts[1] || "{}").split("---PHONE---");
                                    var osdRaw = (osdPhoneParts[0] || "{}").trim();
                                    if (osdRaw !== shellRoot._lastOsdRaw && osdRaw !== "{}") {
                                        shellRoot._lastOsdRaw = osdRaw;
                                        try {
                                            var ev = JSON.parse(osdRaw);
                                            var evTs = Number(ev.ts || 0);
                                            if (evTs > shellRoot.lastOsdTs) {
                                                var staleInit = (shellRoot.lastOsdTs === 0 && (Date.now() - evTs) > 2500);
                                                shellRoot.lastOsdTs = evTs;
                                                if (!staleInit) {
                                                    if (ev.kind === "brightness" && ev.value !== undefined && !shellRoot.brightnessAdjusting) {
                                                        shellRoot.qsBrightness = Math.max(10, Math.min(100, Number(ev.value)));
                                                    }
                                                    if (ev.showOsd !== false) {
                                                        shellRoot.osdKind = String(ev.kind || "volume");
                                                        shellRoot.osdValue = Math.max(0, Math.min(150, Math.round(Number(ev.value !== undefined ? ev.value : 50))));
                                                        shellRoot.osdMuted = Boolean(ev.muted);
                                                        shellRoot.osdVisible = true;
                                                        osdHideTimer.restart();
                                                    }
                                                }
                                            }
                                        } catch (e5) {}
                                    }
                                    if (osdPhoneParts.length > 1) {
                                        var phRaw = (osdPhoneParts[1] || "{}").trim();
                                        if (phRaw !== shellRoot._lastPhoneRaw) {
                                            shellRoot._lastPhoneRaw = phRaw;
                                            try {
                                                var pm = JSON.parse(phRaw);
                                                shellRoot.phoneMirrorActive = Boolean(pm && pm.active);
                                                shellRoot.phoneMirrorMode = (pm && pm.mode) ? String(pm.mode) : "";
                                                shellRoot.phoneMirrorSerial = (pm && pm.serial) ? String(pm.serial) : "";
                                            } catch (e6) {}
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

    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: {
            if (!statePoller.running) statePoller.running = true;
        }
    }

    // Refresh dynamic hardware/battery/apps profile every 15s
    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "sysinfo"])
    }

    Component.onCompleted: {
        try { Qt.application.font = Qt.font({ family: "Inter", pointSize: 9 }); } catch (e) {}
        shellRoot.rebuildInteractiveCalendar();
        Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "sysinfo"]);
        if (!wsSyncProc.running) wsSyncProc.running = true;
    }

    // Reusable SVG/PNG Loader (2x Exact Supersampling + Trilinear Mipmapping for Razor-Sharp Curves)
    component WinSvg : Image {
        property string iconFile: "explorer.svg"
        property string iconUrl: ""
        property int fixedSourceSize: 0
        Layout.preferredWidth: width
        Layout.preferredHeight: height
        Layout.maximumWidth: width
        Layout.maximumHeight: height
        source: iconUrl !== "" ? iconUrl : (iconFile.indexOf("file://") === 0 ? iconFile : (shellRoot.assetDir + iconFile))
        sourceSize.width: fixedSourceSize > 0 ? fixedSourceSize : Math.max(24, Math.round(width * 2))
        sourceSize.height: fixedSourceSize > 0 ? fixedSourceSize : Math.max(24, Math.round(height * 2))
        fillMode: Image.PreserveAspectFit
        mipmap: true
        smooth: true
        antialiasing: true
    }

    // Authentic 144Hz Sub-Pixel Smooth Windows 11 26H2 WinUI 3 Slider
    component Win11Slider : Item {
        id: wSlider
        property real from: 0.0
        property real to: 100.0
        property real externalValue: 50.0
        property string tooltipOverride: ""
        signal userMoved(real newValue)
        signal userReleased(real finalValue)

        implicitWidth: 200
        implicitHeight: 32

        readonly property bool dragging: sliderMouse.pressed
        property real internalRatio: Math.max(0.0, Math.min(1.0, (externalValue - from) / Math.max(0.001, to - from)))
        readonly property real currentValue: from + internalRatio * (to - from)

        onExternalValueChanged: {
            if (!dragging && !releaseHoldTimer.running) {
                internalRatio = Math.max(0.0, Math.min(1.0, (externalValue - from) / Math.max(0.001, to - from)));
            }
        }

        Timer {
            id: releaseHoldTimer
            interval: 350
            repeat: false
        }

        // Recessed Track (11px..width-11px so track NEVER protrudes past thumb)
        Item {
            id: trackItem
            x: 11
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, wSlider.width - 22)
            height: 4

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: "#8a8a8a"
            }

            Rectangle {
                width: wSlider.internalRatio * parent.width
                height: 4
                radius: 2
                color: shellRoot.accentColor
            }
        }

        // Concentric GPU-Scaled Vector Thumb (Zero integer anchor snapping, zero wobble)
        Item {
            id: thumbBox
            x: wSlider.internalRatio * Math.max(0, wSlider.width - 22)
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22

            Image {
                anchors.fill: parent
                source: shellRoot.assetDir + "fluent-slider-outer.svg"
                sourceSize.width: 96
                sourceSize.height: 96
                mipmap: true
                smooth: true
            }

            Image {
                id: innerDot
                anchors.fill: parent
                transformOrigin: Item.Center
                readonly property bool isThumbHovered: sliderMouse.containsMouse &&
                                                       Math.abs(sliderMouse.mouseX - (thumbBox.x + 11)) <= 13
                scale: wSlider.dragging ? 0.44 : (isThumbHovered ? 0.70 : 0.56)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                source: shellRoot.assetDir + "fluent-slider-inner.svg"
                sourceSize.width: 96
                sourceSize.height: 96
                mipmap: true
                smooth: true
            }

            // WinUI 3 Floating Value Tooltip Pill
            Rectangle {
                visible: opacity > 0.01
                opacity: (wSlider.dragging || innerDot.isThumbHovered) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 100 } }
                anchors.horizontalCenter: parent.horizontalCenter
                y: -32
                width: Math.max(32, tipTxt.implicitWidth + 14)
                height: 26
                radius: 5
                color: "#2c2c2c"
                border.color: "#38ffffff"
                border.width: 1
                z: 50

                Text {
                    id: tipTxt
                    anchors.centerIn: parent
                    text: wSlider.tooltipOverride !== "" ? wSlider.tooltipOverride : String(Math.round(wSlider.currentValue))
                    color: "#ffffff"
                    font.pixelSize: 12
                }
            }
        }

        // Direct 1:1 Sub-Pixel Mouse Input (Zero binding lag, zero process-fork stutter)
        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function updateFromMouse(mx) {
                var span = Math.max(1.0, wSlider.width - 22.0);
                var r = Math.max(0.0, Math.min(1.0, (mx - 11.0) / span));
                wSlider.internalRatio = r;
                wSlider.userMoved(wSlider.from + r * (wSlider.to - wSlider.from));
            }

            onPressed: (mouse) => updateFromMouse(mouse.x)
            onPositionChanged: (mouse) => {
                if (pressed) updateFromMouse(mouse.x);
            }
            onReleased: {
                releaseHoldTimer.restart();
                wSlider.userReleased(wSlider.currentValue);
            }
        }
    }

    // Authentic Windows 11 26H2 WinUI 3 ToggleSwitch (40x20 capsule with animated sliding circle)
    component Win11Switch : Switch {
        id: wSwitch
        implicitWidth: 40
        implicitHeight: 20
        padding: 0
        hoverEnabled: true
        contentItem: Item {}

        indicator: Rectangle {
            implicitWidth: 40
            implicitHeight: 20
            radius: 10
            color: wSwitch.checked ? shellRoot.accentColor : (wSwitch.hovered ? "#24ffffff" : "#14000000")
            border.color: wSwitch.checked ? shellRoot.accentColor : "#99ffffff"
            border.width: 1
            antialiasing: true
            Behavior on color { ColorAnimation { duration: 130 } }

            Rectangle {
                x: wSwitch.checked ? (wSwitch.pressed ? 21 : 23) : 4
                anchors.verticalCenter: parent.verticalCenter
                width: wSwitch.pressed ? 14 : 12
                height: 12
                radius: 6
                color: wSwitch.checked ? "#000000" : "#d8d8d8"
                antialiasing: true
                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 90 } }
            }
        }
    }

    // =========================================================================
    // LAYER 1: DESKTOP BACKGROUND & ICONS ON ALL MONITORS (WlrLayer.Bottom)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: desktopWin
            required property var modelData
            screen: modelData
            readonly property bool isPrimary: Quickshell.screens.length > 0 && modelData === Quickshell.screens[0]

            WlrLayershell.namespace: "x64-win11-desktop"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "#040812"

            property var selectedDesktopIndices: []
            property int hoveredDesktopIdx: -1
            property int anchorDesktopIdx: -1
            property int dropTargetIdx: -1

            readonly property int deskCellW: shellRoot.desktopIconSizeMode === "large" ? 96 : (shellRoot.desktopIconSizeMode === "small" ? 76 : 84)
            readonly property int deskCellH: shellRoot.desktopIconSizeMode === "large" ? 98 : (shellRoot.desktopIconSizeMode === "small" ? 72 : 86)
            readonly property int deskIconSz: shellRoot.desktopIconSizeMode === "large" ? 52 : (shellRoot.desktopIconSizeMode === "small" ? 30 : 40)
            readonly property int deskStepX: deskCellW + 6
            readonly property int deskStepY: deskCellH + 6
            readonly property int deskMaxRows: Math.max(1, Math.floor((desktopWin.height - (shellRoot.taskbarCompact ? 38 : 48) - 24) / deskStepY))
            readonly property int deskMaxCols: Math.max(1, Math.floor((desktopWin.width - 24) / deskStepX))

            // Deterministic Non-Overlapping Windows 11 Grid Layout (custom saved slots + top-to-bottom column fill)
            readonly property var desktopSlotLayout: {
                var icons = shellRoot.sortedDesktopIcons || [];
                var saved = (!shellRoot.desktopAutoArrange && shellRoot.desktopIconPositions) ? shellRoot.desktopIconPositions : ({});
                var maxR = Math.max(1, desktopWin.deskMaxRows);
                var maxC = Math.max(1, desktopWin.deskMaxCols);
                var occupied = ({});
                var slots = [];
                var i, k, p, key;

                // Pass 1: Place icons that have valid saved positions
                for (i = 0; i < icons.length; i++) {
                    k = icons[i].id || ("idx_" + i);
                    p = saved[k];
                    if (p && typeof p.col === "number" && typeof p.row === "number") {
                        var sc = Math.max(0, Math.min(maxC - 1, Math.round(p.col)));
                        var sr = Math.max(0, Math.min(maxR - 1, Math.round(p.row)));
                        key = sc + "," + sr;
                        if (!occupied[key]) {
                            occupied[key] = true;
                            slots.push({ col: sc, row: sr });
                            continue;
                        }
                    }
                    slots.push(null);
                }

                // Pass 2: Assign remaining icons column-major (Windows 11 top-to-bottom)
                var curC = 0, curR = 0;
                for (i = 0; i < icons.length; i++) {
                    if (slots[i] !== null) continue;
                    while (occupied[curC + "," + curR]) {
                        curR++;
                        if (curR >= maxR) { curR = 0; curC++; }
                    }
                    occupied[curC + "," + curR] = true;
                    slots[i] = { col: curC, row: curR };
                }
                return slots;
            }

            function isDeskIdxSelected(idx) {
                return selectedDesktopIndices.indexOf(idx) !== -1;
            }

            function syncDesktopSelectedItems() {
                var icons = shellRoot.sortedDesktopIcons || [];
                var out = [];
                for (var i = 0; i < selectedDesktopIndices.length; i++) {
                    var idx = selectedDesktopIndices[i];
                    if (idx >= 0 && idx < icons.length) out.push(icons[idx]);
                }
                shellRoot.desktopSelectedItems = out;
            }

            // Desktop Keyboard Shortcuts (Delete, Ctrl+A, Ctrl+C, Ctrl+X, Ctrl+V, F2, F5, Enter)
            Item {
                id: desktopKeyCatcher
                anchors.fill: parent
                focus: true
                Keys.onPressed: (event) => {
                    if (!desktopWin.isPrimary) return;
                    var icons = shellRoot.sortedDesktopIcons || [];
                    if (event.key === Qt.Key_F5) {
                        shellRoot.triggerDesktopRefresh();
                        event.accepted = true;
                    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_A) {
                        var allIdx = [];
                        for (var i = 0; i < icons.length; i++) allIdx.push(i);
                        desktopWin.selectedDesktopIndices = allIdx;
                        desktopWin.syncDesktopSelectedItems();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete && desktopWin.selectedDesktopIndices.length > 0) {
                        desktopWin.syncDesktopSelectedItems();
                        if (shellRoot.desktopSelectedItems.length > 0) {
                            shellRoot.desktopItemData = shellRoot.desktopSelectedItems[0];
                            shellRoot.execDesktopQuickAction("q_delete");
                            desktopWin.selectedDesktopIndices = [];
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_F2 && desktopWin.selectedDesktopIndices.length === 1) {
                        var it = icons[desktopWin.selectedDesktopIndices[0]];
                        if (it && it.realPath && (it.kind === "folder" || it.kind === "file" || it.kind === "shortcut_file")) {
                            shellRoot.openDesktopRenameDialog(it);
                        }
                        event.accepted = true;
                    } else if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_C || event.key === Qt.Key_X) && desktopWin.selectedDesktopIndices.length > 0) {
                        desktopWin.syncDesktopSelectedItems();
                        if (shellRoot.desktopSelectedItems.length > 0) {
                            shellRoot.desktopItemData = shellRoot.desktopSelectedItems[0];
                            shellRoot.execDesktopQuickAction(event.key === Qt.Key_X ? "q_cut" : "q_copy");
                        }
                        event.accepted = true;
                    } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V && shellRoot.desktopClipboardPaths.length > 0) {
                        var pm = shellRoot.desktopClipboardCut ? "cut" : "copy";
                        Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "paste-desktop", pm].concat(shellRoot.desktopClipboardPaths));
                        if (shellRoot.desktopClipboardCut) {
                            shellRoot.desktopClipboardPaths = [];
                            shellRoot.desktopClipboardPath = "";
                            shellRoot.desktopClipboardCut = false;
                        }
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && desktopWin.selectedDesktopIndices.length > 0) {
                        for (var oi = 0; oi < Math.min(5, desktopWin.selectedDesktopIndices.length); oi++) {
                            var oit = icons[desktopWin.selectedDesktopIndices[oi]];
                            if (oit && oit.cmd) shellRoot.spawnCmd(oit.cmd);
                        }
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: shellRoot.wallpaperMode === 4 ? (shellRoot.solidBgColor || "#141923") : "#0b0e14"
            }

            Image {
                anchors.fill: parent
                visible: shellRoot.wallpaperMode !== 4
                cache: false
                source: (shellRoot.wallpaperMode === 3 && shellRoot.customWallpaperUrl !== "")
                        ? shellRoot.customWallpaperUrl
                        : (shellRoot.wallpaperMode === 0
                           ? (shellRoot.wpDir + "win11-bloom-dark.jpg")
                           : (shellRoot.wallpaperMode === 1
                              ? (shellRoot.wpDir + "win11-bloom-light.jpg")
                              : (shellRoot.wpDir + "x64-monolith.jpg")))
                fillMode: shellRoot.wallpaperFit === "fit" ? Image.PreserveAspectFit
                          : (shellRoot.wallpaperFit === "stretch" ? Image.Stretch
                             : (shellRoot.wallpaperFit === "center" ? Image.Pad : Image.PreserveAspectCrop))
                smooth: true
            }

            // Authentic Windows 11 Grid Desktop Canvas (Smooth Resizing + Full Drag-and-Drop Grid Positioning!)
            Item {
                id: desktopIconsCanvas
                visible: desktopWin.isPrimary && shellRoot.showDesktopIcons
                opacity: shellRoot.desktopRefreshing ? 0.25 : 1.0
                Behavior on opacity { NumberAnimation { duration: 130 } }
                x: 12
                y: 12
                width: desktopWin.width - 24
                height: desktopWin.height - (shellRoot.taskbarCompact ? 38 : 48) - 24

                // Target Grid Cell Hint Outline when dragging icon(s) over empty desktop space
                Rectangle {
                    id: desktopDropSlotHint
                    visible: desktopArea.draggingIcons && desktopWin.dropTargetIdx === -1 && !shellRoot.desktopAutoArrange
                    x: desktopArea.hoverGridCol * desktopWin.deskStepX
                    y: desktopArea.hoverGridRow * desktopWin.deskStepY
                    width: desktopWin.deskCellW
                    height: desktopWin.deskCellH
                    radius: 5
                    color: Qt.alpha(shellRoot.accentColor, 0.13)
                    border.color: Qt.alpha(shellRoot.accentColor, 0.6)
                    border.width: 1
                    Behavior on x { NumberAnimation { duration: 85; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 85; easing.type: Easing.OutCubic } }
                }

                Repeater {
                    model: shellRoot.sortedDesktopIcons

                    delegate: Rectangle {
                        id: deskIconCell
                        readonly property int deskIdx: index
                        readonly property var slotObj: (index < desktopWin.desktopSlotLayout.length && desktopWin.desktopSlotLayout[index]) ? desktopWin.desktopSlotLayout[index] : ({ col: 0, row: index })
                        readonly property bool isSel: desktopWin.selectedDesktopIndices.indexOf(index) !== -1
                        readonly property bool isHov: desktopWin.hoveredDesktopIdx === index
                        readonly property bool isDropTarget: desktopWin.dropTargetIdx === index
                        readonly property bool isDraggingSelf: desktopArea.draggingIcons && isSel
                        readonly property bool isCutPending: shellRoot.desktopClipboardCut && shellRoot.desktopClipboardPaths.indexOf(modelData.realPath || "") !== -1

                        x: slotObj.col * desktopWin.deskStepX
                        y: slotObj.row * desktopWin.deskStepY
                        width: desktopWin.deskCellW
                        height: desktopWin.deskCellH
                        radius: 4
                        opacity: isDraggingSelf ? 0.35 : (isCutPending ? 0.52 : 1.0)
                        color: isDropTarget ? (modelData.kind === "trash" ? "#55c42b1c" : "#550078d4")
                                            : (isSel ? "#440078d4" : (isHov ? "#1cffffff" : "transparent"))
                        border.color: isDropTarget ? (modelData.kind === "trash" ? "#ff7b72" : shellRoot.accentColor)
                                                   : (isSel ? Qt.alpha(shellRoot.accentColor, 0.53) : (isHov ? "#22ffffff" : "transparent"))
                        border.width: isDropTarget ? 1.5 : 1

                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            WinSvg {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: desktopWin.deskIconSz
                                height: desktopWin.deskIconSz
                                fixedSourceSize: 128
                                iconUrl: modelData.iconUrl || ""
                                Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: desktopWin.deskCellW - 6
                                text: modelData.title
                                color: "#ffffff"
                                font.pixelSize: 11
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                style: Text.Outline
                                styleColor: "#bb000000"
                            }
                        }
                    }
                }
            }

            // Unified Desktop Marquee Drag-Select, Icon Drag-and-Drop (Move to Folder / Trash / Grid Slot), Click & Right-Click Layer
            MouseArea {
                id: desktopArea
                anchors.fill: parent
                anchors.bottomMargin: shellRoot.taskbarCompact ? 38 : 48
                z: 10
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                property real pressX: 0
                property real pressY: 0
                property real dragCurX: 0
                property real dragCurY: 0
                property int pressHitIdx: -1
                property bool leftPressed: false
                property bool draggingBox: false
                property bool draggingIcons: false
                property bool pressWasAlreadySel: false
                property var baseDragSel: []
                property int hoverGridCol: 0
                property int hoverGridRow: 0
                property string dropHintLabel: ""

                function hitTestDesktopIcon(mx, my) {
                    if (!desktopWin.isPrimary || !shellRoot.showDesktopIcons) return -1;
                    var kids = desktopIconsCanvas.children;
                    for (var i = 0; i < kids.length; i++) {
                        var c = kids[i];
                        if (typeof c.deskIdx === "number") {
                            var ix = desktopIconsCanvas.x + c.x;
                            var iy = desktopIconsCanvas.y + c.y;
                            if (mx >= ix && mx <= ix + c.width && my >= iy && my <= iy + c.height) {
                                return c.deskIdx;
                            }
                        }
                    }
                    return -1;
                }

                function updateMarqueeSelection(rx, ry, rw, rh) {
                    if (!desktopWin.isPrimary || !shellRoot.showDesktopIcons) return;
                    var nextSel = baseDragSel.slice();
                    var kids = desktopIconsCanvas.children;
                    for (var i = 0; i < kids.length; i++) {
                        var c = kids[i];
                        if (typeof c.deskIdx === "number") {
                            var ix = desktopIconsCanvas.x + c.x;
                            var iy = desktopIconsCanvas.y + c.y;
                            if (ix < rx + rw && ix + c.width > rx && iy < ry + rh && iy + c.height > ry) {
                                if (nextSel.indexOf(c.deskIdx) === -1) nextSel.push(c.deskIdx);
                            }
                        }
                    }
                    desktopWin.selectedDesktopIndices = nextSel;
                    desktopWin.syncDesktopSelectedItems();
                }

                function updateIconDragFeedback(mx, my) {
                    dragCurX = mx;
                    dragCurY = my;
                    hoverGridCol = Math.max(0, Math.min(desktopWin.deskMaxCols - 1, Math.floor((mx - desktopIconsCanvas.x) / desktopWin.deskStepX)));
                    hoverGridRow = Math.max(0, Math.min(desktopWin.deskMaxRows - 1, Math.floor((my - desktopIconsCanvas.y) / desktopWin.deskStepY)));

                    var hit = hitTestDesktopIcon(mx, my);
                    var icons = shellRoot.sortedDesktopIcons || [];
                    if (hit >= 0 && hit < icons.length && desktopWin.selectedDesktopIndices.indexOf(hit) === -1) {
                        var target = icons[hit];
                        // Check if dragged selection contains movable items for folder/trash drop
                        var hasFs = false;
                        var hasApp = false;
                        for (var si = 0; si < desktopWin.selectedDesktopIndices.length; si++) {
                            var sIt = icons[desktopWin.selectedDesktopIndices[si]];
                            if (!sIt) continue;
                            if (sIt.kind === "folder" || sIt.kind === "file" || sIt.kind === "shortcut_file") hasFs = true;
                            if (sIt.kind === "app") hasApp = true;
                        }
                        if (target.kind === "trash" && (hasFs || hasApp)) {
                            desktopWin.dropTargetIdx = hit;
                            dropHintLabel = "Mover a Papelera de reciclaje";
                            return;
                        }
                        if ((target.kind === "folder" || target.kind === "userhome") && hasFs && target.realPath) {
                            desktopWin.dropTargetIdx = hit;
                            dropHintLabel = "Mover a " + String(target.title || "Carpeta").replace(/\n/g, " ");
                            return;
                        }
                    }
                    desktopWin.dropTargetIdx = -1;
                    dropHintLabel = "";
                }

                function commitIconDrop(mx, my) {
                    var icons = shellRoot.sortedDesktopIcons || [];
                    var selIdxs = desktopWin.selectedDesktopIndices.slice();
                    if (selIdxs.length === 0) return;

                    // Case 1: Dropped on Trash or Folder
                    if (desktopWin.dropTargetIdx >= 0 && desktopWin.dropTargetIdx < icons.length) {
                        var target = icons[desktopWin.dropTargetIdx];
                        var fsPaths = [];
                        var appIds = [];
                        for (var i = 0; i < selIdxs.length; i++) {
                            var it = icons[selIdxs[i]];
                            if (!it) continue;
                            if (it.kind === "folder" || it.kind === "file" || it.kind === "shortcut_file") {
                                if (it.realPath) fsPaths.push(it.realPath);
                            } else if (it.kind === "app" && it.id) {
                                appIds.push(it.id);
                            }
                        }
                        if (target.kind === "trash") {
                            if (fsPaths.length > 0) Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "trash-path"].concat(fsPaths));
                            if (appIds.length > 0) Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "hide-desktop-id"].concat(appIds));
                            desktopWin.selectedDesktopIndices = [];
                            desktopWin.syncDesktopSelectedItems();
                            return;
                        }
                        if ((target.kind === "folder" || target.kind === "userhome") && target.realPath && fsPaths.length > 0) {
                            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "move-to", String(target.realPath)].concat(fsPaths));
                            desktopWin.selectedDesktopIndices = [];
                            desktopWin.syncDesktopSelectedItems();
                            return;
                        }
                    }

                    // Case 2: Reposition dragged icon(s) onto desktop grid slots
                    if (shellRoot.desktopAutoArrange) return;
                    var maxR = Math.max(1, desktopWin.deskMaxRows);
                    var maxC = Math.max(1, desktopWin.deskMaxCols);
                    var layout = desktopWin.desktopSlotLayout;

                    // Copy all current slots so non-dragged icons stay anchored where they are
                    var nextPos = ({});
                    var occupied = ({});
                    for (var j = 0; j < icons.length; j++) {
                        if (selIdxs.indexOf(j) !== -1) continue;
                        var idKey = icons[j].id || ("idx_" + j);
                        var sl = layout[j] || { col: 0, row: j };
                        nextPos[idKey] = { col: sl.col, row: sl.row };
                        occupied[sl.col + "," + sl.row] = true;
                    }

                    var baseCol = Math.max(0, Math.min(maxC - 1, Math.floor((mx - desktopIconsCanvas.x) / desktopWin.deskStepX)));
                    var baseRow = Math.max(0, Math.min(maxR - 1, Math.floor((my - desktopIconsCanvas.y) / desktopWin.deskStepY)));
                    var anchorSlot = (pressHitIdx >= 0 && pressHitIdx < layout.length && layout[pressHitIdx]) ? layout[pressHitIdx] : { col: 0, row: 0 };

                    for (var s = 0; s < selIdxs.length; s++) {
                        var idx = selIdxs[s];
                        if (idx < 0 || idx >= icons.length) continue;
                        var origSl = (idx < layout.length && layout[idx]) ? layout[idx] : anchorSlot;
                        var tc = Math.max(0, Math.min(maxC - 1, baseCol + (origSl.col - anchorSlot.col)));
                        var tr = Math.max(0, Math.min(maxR - 1, baseRow + (origSl.row - anchorSlot.row)));
                        // If target cell is occupied, find nearest free cell going down then next column
                        var tries = 0;
                        while (occupied[tc + "," + tr] && tries < maxR * maxC) {
                            tr++;
                            if (tr >= maxR) { tr = 0; tc = (tc + 1) % maxC; }
                            tries++;
                        }
                        occupied[tc + "," + tr] = true;
                        var dk = icons[idx].id || ("idx_" + idx);
                        nextPos[dk] = { col: tc, row: tr };
                    }
                    shellRoot.desktopIconPositions = nextPos;
                    shellRoot.saveConfigKey("desktopIconPositions", JSON.stringify(nextPos));
                }

                onExited: desktopWin.hoveredDesktopIdx = -1

                onPressed: (mouse) => {
                    desktopKeyCatcher.forceActiveFocus();
                    shellRoot.activeScreen = desktopWin.modelData;
                    var hit = hitTestDesktopIcon(mouse.x, mouse.y);

                    if (mouse.button === Qt.LeftButton) {
                        shellRoot.closeAllPopups();
                        pressX = mouse.x;
                        pressY = mouse.y;
                        dragCurX = mouse.x;
                        dragCurY = mouse.y;
                        pressHitIdx = hit;
                        leftPressed = true;
                        draggingBox = false;
                        draggingIcons = false;
                        desktopWin.dropTargetIdx = -1;
                        dropHintLabel = "";
                        pressWasAlreadySel = (hit >= 0 && desktopWin.isDeskIdxSelected(hit));
                        baseDragSel = (mouse.modifiers & Qt.ControlModifier) ? desktopWin.selectedDesktopIndices.slice() : [];
                        if (hit === -1 && !(mouse.modifiers & Qt.ControlModifier)) {
                            desktopWin.selectedDesktopIndices = [];
                            desktopWin.syncDesktopSelectedItems();
                        } else if (hit >= 0 && !pressWasAlreadySel && !(mouse.modifiers & Qt.ControlModifier) && !(mouse.modifiers & Qt.ShiftModifier)) {
                            desktopWin.selectedDesktopIndices = [hit];
                            desktopWin.anchorDesktopIdx = hit;
                            desktopWin.syncDesktopSelectedItems();
                        }
                    } else if (mouse.button === Qt.RightButton) {
                        shellRoot.closeAllPopups();
                        if (hit >= 0) {
                            var icons = shellRoot.sortedDesktopIcons || [];
                            if (!desktopWin.isDeskIdxSelected(hit)) {
                                desktopWin.selectedDesktopIndices = [hit];
                            }
                            desktopWin.syncDesktopSelectedItems();
                            shellRoot.desktopItemCtxX = Math.max(8, Math.min(desktopWin.width - 284, mouse.x));
                            shellRoot.desktopItemCtxY = Math.max(8, Math.min(desktopWin.height - (shellRoot.taskbarCompact ? 38 : 48) - 340, mouse.y));
                            shellRoot.desktopItemData = icons[hit] || null;
                            shellRoot.desktopItemCtxOpen = (shellRoot.desktopItemData !== null);
                        } else {
                            desktopWin.selectedDesktopIndices = [];
                            desktopWin.syncDesktopSelectedItems();
                            shellRoot.ctxX = Math.max(8, Math.min(mouse.x, desktopWin.width - 276));
                            shellRoot.ctxY = Math.max(8, Math.min(mouse.y, desktopWin.height - (shellRoot.taskbarCompact ? 38 : 48) - 318));
                            shellRoot.ctxSubMenu = "";
                            shellRoot.ctxMenuOpen = true;
                        }
                    }
                }

                onPositionChanged: (mouse) => {
                    if (leftPressed && (mouse.buttons & Qt.LeftButton)) {
                        var dx = Math.abs(mouse.x - pressX);
                        var dy = Math.abs(mouse.y - pressY);
                        if (pressHitIdx >= 0) {
                            // Dragging selected desktop icon(s)!
                            if (draggingIcons || dx > 6 || dy > 6) {
                                draggingIcons = true;
                                updateIconDragFeedback(mouse.x, mouse.y);
                            }
                        } else {
                            // Dragging marquee box on empty space!
                            if (draggingBox || dx > 5 || dy > 5) {
                                draggingBox = true;
                                var rx = Math.min(pressX, mouse.x);
                                var ry = Math.min(pressY, mouse.y);
                                var rw = Math.abs(mouse.x - pressX);
                                var rh = Math.abs(mouse.y - pressY);
                                rubberBand.x = rx;
                                rubberBand.y = ry;
                                rubberBand.width = rw;
                                rubberBand.height = rh;
                                updateMarqueeSelection(rx, ry, rw, rh);
                            }
                        }
                    } else {
                        desktopWin.hoveredDesktopIdx = hitTestDesktopIcon(mouse.x, mouse.y);
                    }
                }

                onReleased: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        if (draggingIcons) {
                            commitIconDrop(mouse.x, mouse.y);
                        } else if (!draggingBox && pressHitIdx >= 0) {
                            var cur = desktopWin.selectedDesktopIndices.slice();
                            if (mouse.modifiers & Qt.ControlModifier) {
                                var pos = cur.indexOf(pressHitIdx);
                                if (pos !== -1) cur.splice(pos, 1);
                                else cur.push(pressHitIdx);
                                desktopWin.selectedDesktopIndices = cur;
                            } else if ((mouse.modifiers & Qt.ShiftModifier) && desktopWin.anchorDesktopIdx >= 0) {
                                var a = Math.min(desktopWin.anchorDesktopIdx, pressHitIdx);
                                var b = Math.max(desktopWin.anchorDesktopIdx, pressHitIdx);
                                var rng = [];
                                for (var k = a; k <= b; k++) rng.push(k);
                                desktopWin.selectedDesktopIndices = rng;
                            } else if (pressWasAlreadySel && cur.length > 1) {
                                desktopWin.selectedDesktopIndices = [pressHitIdx];
                                desktopWin.anchorDesktopIdx = pressHitIdx;
                            }
                            desktopWin.syncDesktopSelectedItems();
                        }
                        leftPressed = false;
                        draggingBox = false;
                        draggingIcons = false;
                        desktopWin.dropTargetIdx = -1;
                        dropHintLabel = "";
                        rubberBand.width = 0;
                        rubberBand.height = 0;
                    }
                }

                onDoubleClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        var hit = hitTestDesktopIcon(mouse.x, mouse.y);
                        var icons = shellRoot.sortedDesktopIcons || [];
                        if (hit >= 0 && hit < icons.length && icons[hit].cmd) {
                            shellRoot.closeAllPopups();
                            shellRoot.spawnCmd(icons[hit].cmd);
                        }
                    }
                }
            }

            // Floating Translucent Drag Ghost Preview (follows cursor with count badge & drop action hint)
            Item {
                id: desktopDragGhost
                z: 25
                visible: desktopArea.draggingIcons && desktopWin.selectedDesktopIndices.length > 0
                x: Math.max(4, Math.min(desktopWin.width - 120, desktopArea.dragCurX - 38))
                y: Math.max(4, Math.min(desktopWin.height - 96, desktopArea.dragCurY - 38))
                readonly property var leadIcon: {
                    var icons = shellRoot.sortedDesktopIcons || [];
                    var idx = desktopArea.pressHitIdx >= 0 ? desktopArea.pressHitIdx : (desktopWin.selectedDesktopIndices.length > 0 ? desktopWin.selectedDesktopIndices[0] : -1);
                    return (idx >= 0 && idx < icons.length) ? icons[idx] : null;
                }

                Rectangle {
                    width: desktopWin.deskCellW
                    height: desktopWin.deskCellH
                    radius: 6
                    color: "#66182230"
                    border.color: Qt.alpha(shellRoot.accentColor, 0.6)
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        WinSvg {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: desktopWin.deskIconSz
                            height: desktopWin.deskIconSz
                            fixedSourceSize: 128
                            iconUrl: desktopDragGhost.leadIcon ? (desktopDragGhost.leadIcon.iconUrl || "") : ""
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: desktopWin.deskCellW - 8
                            text: desktopDragGhost.leadIcon ? desktopDragGhost.leadIcon.title : ""
                            color: "#ffffff"
                            font.pixelSize: 11
                            maximumLineCount: 1
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // Multi-item Count Badge (Windows 11 accent pill)
                    Rectangle {
                        visible: desktopWin.selectedDesktopIndices.length > 1
                        anchors.top: parent.top; anchors.right: parent.right
                        anchors.topMargin: -6; anchors.rightMargin: -6
                        width: 24; height: 22; radius: 11
                        color: "#0078d4"; border.color: shellRoot.accentColor; border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: String(desktopWin.selectedDesktopIndices.length)
                            color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Bold
                        }
                    }
                }

                // Contextual Drop Hint Pill ("Mover a Carpeta" / "Mover a Papelera de reciclaje")
                Rectangle {
                    visible: desktopArea.dropHintLabel !== ""
                    x: 0; y: desktopWin.deskCellH + 6
                    width: hintTxt.implicitWidth + 18; height: 24; radius: 5
                    color: shellRoot.panelBg; border.color: shellRoot.accentColor; border.width: 1
                    Text {
                        id: hintTxt; anchors.centerIn: parent
                        text: desktopArea.dropHintLabel
                        color: "#f2f2f2"; font.pixelSize: 11
                    }
                }
            }

            // Authentic Windows 11 Translucent Blue Marquee Selection Rectangle (Drawn ON TOP of Icons!)
            Rectangle {
                id: rubberBand
                z: 20
                visible: desktopArea.draggingBox && (width > 4 || height > 4)
                color: "#380078d4"
                border.color: shellRoot.accentColor
                border.width: 1
            }

        }
    }

    // =========================================================================
    // LAYER 1B: CLICK-THROUGH GLOBAL SCREEN FILTER (NIGHT LIGHT + BRIGHTNESS)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: screenFilterWin
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "x64-win11-screenfilter"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "transparent"

            // Empty input mask: 100% of mouse clicks & hovers pass through to apps below
            mask: Region {}

            // 1. Smooth Natural Night Light (Adjustable Warm Amber Filter across all monitors!)
            Rectangle {
                anchors.fill: parent
                color: "#ff9230"
                opacity: shellRoot.qsNightLight ? (0.04 + (Math.max(15, Math.min(100, shellRoot.qsNightLightStrength)) / 100.0) * 0.22) : 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 420; easing.type: Easing.InOutCubic }
                }
            }

            // 2. Real-Time Universal Screen Brightness Dimmer (10%..100% across all monitors)
            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: Math.max(0.0, Math.min(0.80, (100.0 - shellRoot.qsBrightness) / 112.0))
            }

            // 2B. Authentic Windows 11 26H2 "Identificar pantallas" Floating Badge per Monitor!
            Rectangle {
                readonly property string scrName: screenFilterWin.modelData ? (screenFilterWin.modelData.name || "") : ""
                readonly property int monIdx: (shellRoot.identifyMap && shellRoot.identifyMap[scrName] !== undefined)
                    ? Number(shellRoot.identifyMap[scrName])
                    : (Quickshell.screens.indexOf(screenFilterWin.modelData) + 1)
                visible: opacity > 0.01
                opacity: shellRoot.identifyActive ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                x: 44
                y: screenFilterWin.height - height - (shellRoot.taskbarCompact ? 62 : 72)
                width: 156; height: 118; radius: 12
                color: "#eb1c1c1c"
                border.color: shellRoot.accentColor; border.width: 2
                Column {
                    anchors.centerIn: parent; spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String(parent.parent.monIdx)
                        color: "#ffffff"; font.pixelSize: 54; font.weight: Font.Bold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.parent.scrName || "Pantalla"
                        color: shellRoot.accentColor; font.pixelSize: 13; font.weight: Font.DemiBold
                    }
                }
            }

            // 2C. Authentic Windows 11 26H2 Floating Center-Bottom OSD Pill (Fn Volume / Brightness / Mic Mute!)
            Rectangle {
                id: win11OsdPill
                visible: opacity > 0.01
                opacity: shellRoot.osdVisible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                width: 244; height: 52; radius: 10
                x: Math.round((screenFilterWin.width - width) / 2)
                y: screenFilterWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - (shellRoot.osdVisible ? 20 : 10)
                Behavior on y { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
                color: shellRoot.panelBg
                border.color: "#32ffffff"; border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12

                    WinSvg {
                        width: 20; height: 20
                        iconFile: shellRoot.osdKind === "brightness"
                                  ? "fluent-brightness.svg"
                                  : (shellRoot.osdKind === "mic"
                                     ? (shellRoot.osdMuted ? "audio-input-microphone-muted-symbolic.svg" : "audio-input-microphone-symbolic.svg")
                                     : ((shellRoot.osdMuted || shellRoot.osdValue <= 0) ? "fluent-speaker-mute.svg" : "fluent-speaker-high.svg"))
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 4; radius: 2; color: "#4a4a4a"
                        Rectangle {
                            height: 4; radius: 2
                            width: shellRoot.osdMuted ? 0 : Math.max(0, Math.min(parent.width, parent.width * (Math.min(100, shellRoot.osdValue) / 100.0)))
                            color: shellRoot.osdValue > 100 ? "#fbbf24" : shellRoot.accentColor
                            Behavior on width { NumberAnimation { duration: 85; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        text: shellRoot.osdMuted ? "Mute" : String(shellRoot.osdValue)
                        color: shellRoot.osdMuted ? "#f87171" : (shellRoot.osdValue > 100 ? "#fbbf24" : "#f5f5f5")
                        font.pixelSize: 13; font.weight: Font.DemiBold
                        Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // 3. Click-Through Authentic Windows 11 Taskbar Hover Tooltip Pill
            Rectangle {
                id: tbFloatingTip
                visible: opacity > 0.01
                opacity: (screenFilterWin.modelData === shellRoot.activeScreen && shellRoot.tbTooltipVisible && shellRoot.tbTooltipText !== "") ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                width: Math.min(320, tbTipLabel.implicitWidth + 20)
                height: tbTipLabel.implicitHeight + 12
                x: Math.max(8, Math.min(screenFilterWin.width - width - 8, shellRoot.tbTooltipCenterX - width / 2))
                y: screenFilterWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 8
                radius: 5
                color: "#f52a2a2a"
                border.color: "#32ffffff"
                border.width: 1

                Text {
                    id: tbTipLabel
                    anchors.centerIn: parent
                    width: Math.min(300, implicitWidth)
                    text: shellRoot.tbTooltipText
                    color: "#f2f2f2"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // =========================================================================
    // LAYER 2: WINDOWS 11 26H2 TASKBAR ON ALL MONITORS (WlrLayer.Top)
    // =========================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: taskbarWin
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "x64-win11-taskbar"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.left: true
            anchors.right: true
            anchors.bottom: true
            implicitHeight: shellRoot.taskbarCompact ? 38 : 48
            exclusiveZone: implicitHeight
            color: shellRoot.taskbarBg

            readonly property var toplevels: ToplevelManager.toplevels ? ToplevelManager.toplevels.values : []

            // Authentic 1px Top Specular Acrylic Hairline
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: "#22ffffff"
            }

            // [1] Left Weather Widget (Exact Windows 11 26H2 Two-Line Layout: Temp on top, Condition below)
            Rectangle {
                id: wthWidget
                visible: shellRoot.showWeatherWidget && !shellRoot.taskbarLeftAlign && taskbarWin.width >= 900
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 158
                height: shellRoot.taskbarCompact ? 32 : 40
                radius: 4
                color: shellRoot.weatherOpen ? "#20ffffff" : (wthHov.containsMouse ? "#18ffffff" : "transparent")
                Behavior on color { ColorAnimation { duration: 110 } }
                border.color: (shellRoot.weatherOpen || wthHov.containsMouse) ? "#16ffffff" : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                    WinSvg { width: 25; height: 25; iconFile: shellRoot.weatherData.icon || "win11-weather.svg" }
                    Column {
                        Layout.fillWidth: true
                        spacing: -1
                        Text {
                            text: shellRoot.weatherData.temp || "--°C"
                            color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight; width: 108
                        }
                        Text {
                            visible: !shellRoot.taskbarCompact
                            text: shellRoot.weatherData.desc || "El Tiempo"
                            color: "#c8c8c8"; font.pixelSize: 11; elide: Text.ElideRight; width: 108
                        }
                    }
                }
                MouseArea {
                    id: wthHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                    onEntered: shellRoot.showTbTooltip(taskbarWin.modelData, wthWidget.x + wthWidget.width / 2,
                                                       (shellRoot.weatherData.location || "El Tiempo") + " • " + (shellRoot.weatherData.temp || "") + " (" + (shellRoot.weatherData.desc || "") + ")")
                    onExited: shellRoot.hideTbTooltip()
                    onClicked: {
                        shellRoot.hideTbTooltip();
                        shellRoot.activeScreen = taskbarWin.modelData;
                        var next = !shellRoot.weatherOpen;
                        shellRoot.closeAllPopups();
                        shellRoot.weatherOpen = next;
                        if (next) {
                            shellRoot.triggerLiveWeatherRefresh();
                        }
                    }
                }
            }

            // [2] Centered (or Left-Aligned) Taskbar Icons + Running Wayland Windows
            Row {
                id: mainIconsRow
                readonly property bool autoCompactSearch: shellRoot.taskbarSearchMode === "icon" || shellRoot.taskbarCompact || taskbarWin.width < 1180
                x: shellRoot.taskbarLeftAlign
                   ? 8
                   : Math.max(wthWidget.visible ? 174 : 8,
                              Math.min(Math.round((taskbarWin.width - width) / 2),
                                       taskbarWin.width - rightTrayRow.width - width - 14))
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // WINDOWS 11 26H2 START BUTTON
                Rectangle {
                    id: startBtnRect
                    width: shellRoot.taskbarCompact ? 34 : 40
                    height: shellRoot.taskbarCompact ? 34 : 40
                    radius: 4
                    color: shellRoot.startOpen ? "#22ffffff" : (startBtnHov.containsMouse ? "#18ffffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 110 } }
                    border.color: shellRoot.startOpen ? "#1cffffff" : "transparent"
                    border.width: 1

                    WinSvg {
                        anchors.centerIn: parent
                        width: shellRoot.taskbarCompact ? 20 : 24
                        height: shellRoot.taskbarCompact ? 20 : 24
                        iconFile: "win11-start.svg"
                        scale: startBtnHov.pressed ? 0.84 : 1.0
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    }

                    MouseArea {
                        id: startBtnHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onEntered: shellRoot.showTbTooltip(taskbarWin.modelData, mainIconsRow.x + startBtnRect.x + startBtnRect.width / 2, "Inicio")
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: (mouse) => {
                            shellRoot.hideTbTooltip();
                            shellRoot.activeScreen = taskbarWin.modelData;
                            if (mouse.button === Qt.RightButton) {
                                var nextWx = !shellRoot.winXMenuOpen;
                                shellRoot.closeAllPopups();
                                shellRoot.winXMenuX = Math.max(12, Math.min(taskbarWin.width - 256, mainIconsRow.x + startBtnRect.x));
                                shellRoot.winXMenuOpen = nextWx;
                                return;
                            }
                            var next = !shellRoot.startOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.startOpen = next;
                        }
                    }
                }

                // WINDOWS 11 26H2 SEARCH CAPSULE ("Buscar" + Search Highlights Sparkle)
                Rectangle {
                    id: searchPillRect
                    visible: shellRoot.taskbarSearchMode !== "hidden"
                    width: mainIconsRow.autoCompactSearch ? (shellRoot.taskbarCompact ? 34 : 40) : 210
                    height: shellRoot.taskbarCompact ? 30 : 32
                    radius: mainIconsRow.autoCompactSearch ? 4 : 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: mainIconsRow.autoCompactSearch
                           ? (shellRoot.searchOpen ? "#22ffffff" : (searchPillHov.containsMouse ? "#18ffffff" : "transparent"))
                           : ((shellRoot.searchOpen || searchPillHov.containsMouse) ? "#343434" : "#2c2c2c")
                    Behavior on color { ColorAnimation { duration: 110 } }
                    border.color: mainIconsRow.autoCompactSearch
                                  ? "transparent"
                                  : (shellRoot.searchOpen ? shellRoot.accentColor : "#32ffffff")
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: mainIconsRow.autoCompactSearch ? ((parent.width - 18) / 2) : 12
                        anchors.rightMargin: mainIconsRow.autoCompactSearch ? 0 : 11
                        spacing: 8
                        WinSvg {
                            width: mainIconsRow.autoCompactSearch ? 18 : 15
                            height: mainIconsRow.autoCompactSearch ? 18 : 15
                            iconFile: "fluent-search.svg"
                            opacity: 0.92
                        }
                        Text {
                            visible: !mainIconsRow.autoCompactSearch
                            text: (shellRoot.searchOpen && shellRoot.searchQuery !== "")
                                  ? shellRoot.searchQuery
                                  : "Buscar"
                            color: (shellRoot.searchOpen && shellRoot.searchQuery !== "") ? "#ffffff" : "#d0d0d0"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        WinSvg {
                            visible: !mainIconsRow.autoCompactSearch
                            width: 16; height: 16
                            iconFile: "fluent-sparkle.svg"
                            opacity: searchPillHov.containsMouse ? 0.95 : 0.70
                        }
                    }

                    MouseArea {
                        id: searchPillHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        onEntered: shellRoot.showTbTooltip(taskbarWin.modelData, mainIconsRow.x + searchPillRect.x + searchPillRect.width / 2, "Buscar")
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: {
                            shellRoot.hideTbTooltip();
                            shellRoot.activeScreen = taskbarWin.modelData;
                            var next = !shellRoot.searchOpen;
                            shellRoot.closeAllPopups();
                            if (next) {
                                shellRoot.searchQuery = "";
                                shellRoot.searchOpen = true;
                            }
                        }
                    }
                }

                // WINDOWS 11 26H2 TASK VIEW BUTTON ("Vista de tareas")
                Rectangle {
                    id: tvBtnRect
                    visible: shellRoot.showTaskViewBtn
                    width: shellRoot.taskbarCompact ? 34 : 40
                    height: shellRoot.taskbarCompact ? 34 : 40
                    radius: 4
                    color: shellRoot.taskViewOpen ? "#22ffffff" : (tvBtnHov.containsMouse ? "#18ffffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 110 } }
                    border.color: shellRoot.taskViewOpen ? "#1cffffff" : "transparent"
                    border.width: 1

                    WinSvg {
                        anchors.centerIn: parent
                        width: shellRoot.taskbarCompact ? 19 : 22
                        height: shellRoot.taskbarCompact ? 19 : 22
                        iconFile: "win11-taskview.svg"
                        scale: tvBtnHov.pressed ? 0.84 : 1.0
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    }

                    MouseArea {
                        id: tvBtnHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        onEntered: shellRoot.showTbTooltip(taskbarWin.modelData, mainIconsRow.x + tvBtnRect.x + tvBtnRect.width / 2, "Vista de tareas — " + shellRoot.activeVirtualDesktopName)
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: {
                            shellRoot.hideTbTooltip();
                            shellRoot.activeScreen = taskbarWin.modelData;
                            var next = !shellRoot.taskViewOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.taskViewOpen = next;
                        }
                    }
                }

                // Dynamic Pinned Applications (only apps installed on this machine)
                Repeater {
                    model: shellRoot.taskbarPinned

                    delegate: Rectangle {
                        id: tbAppBtn
                        width: shellRoot.taskbarCompact ? 34 : 40
                        height: shellRoot.taskbarCompact ? 34 : 40
                        radius: 4

                        readonly property var matchedTop: {
                            var list = taskbarWin.toplevels;
                            for (var i = 0; i < list.length; i++) {
                                var app = (list[i].appId || "").toLowerCase();
                                var ttl = (list[i].title || "").toLowerCase();
                                if (app.indexOf(modelData.match) !== -1 || ttl.indexOf(modelData.match) !== -1) {
                                    return list[i];
                                }
                            }
                            return null;
                        }
                        readonly property bool isOpen: matchedTop !== null
                        readonly property bool isFocused: matchedTop !== null && Boolean(matchedTop.activated) && !Boolean(matchedTop.minimized)

                        color: isFocused ? "#20ffffff" : (tbHov.containsMouse ? "#18ffffff" : "transparent")
                        Behavior on color { ColorAnimation { duration: 115 } }
                        border.color: isFocused ? "#1affffff" : "transparent"
                        border.width: 1

                        WinSvg {
                            anchors.centerIn: parent
                            width: shellRoot.taskbarCompact ? 20 : 24
                            height: shellRoot.taskbarCompact ? 20 : 24
                            iconUrl: modelData.iconUrl || ""
                            scale: tbHov.pressed ? 0.84 : 1.0
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        }

                        // Authentic Windows 11 Bottom Pill (16px #4cc2ff when focused, 6px #9a9a9a when open in background)
                        Rectangle {
                            visible: tbAppBtn.isOpen
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tbAppBtn.isFocused ? 16 : 6
                            height: 3
                            radius: 1.5
                            color: tbAppBtn.isFocused ? shellRoot.accentColor : "#9a9a9a"
                            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: tbHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onEntered: {
                                var tip = (tbAppBtn.matchedTop && tbAppBtn.matchedTop.title)
                                          ? tbAppBtn.matchedTop.title
                                          : (modelData.title || modelData.id);
                                shellRoot.showTbTooltip(taskbarWin.modelData, mainIconsRow.x + tbAppBtn.x + tbAppBtn.width / 2, tip);
                            }
                            onExited: shellRoot.hideTbTooltip()
                            onClicked: (mouse) => {
                                shellRoot.hideTbTooltip();
                                shellRoot.activeScreen = taskbarWin.modelData;
                                if (mouse.button === Qt.RightButton) {
                                    shellRoot.closeAllPopups();
                                    shellRoot.appJumpData = {
                                        title: (tbAppBtn.matchedTop && tbAppBtn.matchedTop.title) ? tbAppBtn.matchedTop.title : (modelData.title || modelData.id),
                                        baseTitle: modelData.title || modelData.id,
                                        match: modelData.match || modelData.id,
                                        iconUrl: modelData.iconUrl || "",
                                        cmd: modelData.cmd,
                                        isPinned: true,
                                        topWin: tbAppBtn.matchedTop
                                    };
                                    var globalX = mainIconsRow.x + tbAppBtn.x;
                                    shellRoot.appJumpX = Math.max(12, Math.min(taskbarWin.width - 256, globalX - 80));
                                    shellRoot.appJumpOpen = true;
                                    return;
                                }
                                shellRoot.closeAllPopups();
                                if (mouse.button === Qt.MiddleButton && tbAppBtn.matchedTop) {
                                    tbAppBtn.matchedTop.close();
                                } else if (tbAppBtn.matchedTop) {
                                    shellRoot.toggleWindowFocusOrMinimize(tbAppBtn.matchedTop);
                                } else {
                                    shellRoot.spawnCmd(modelData.cmd);
                                }
                            }
                        }
                    }
                }

                // Dynamic Unpinned Running Wayland Windows
                Repeater {
                    model: {
                        var list = taskbarWin.toplevels;
                        var pinnedList = shellRoot.taskbarPinned;
                        var extra = [];
                        for (var i = 0; i < list.length; i++) {
                            var app = (list[i].appId || "").toLowerCase();
                            var ttl = (list[i].title || "").toLowerCase();
                            var isPinned = false;
                            for (var j = 0; j < pinnedList.length; j++) {
                                var mk = (pinnedList[j].match || "").toLowerCase();
                                if (mk !== "" && (app.indexOf(mk) !== -1 || ttl.indexOf(mk) !== -1)) {
                                    isPinned = true;
                                    break;
                                }
                            }
                            if (!isPinned) {
                                extra.push(list[i]);
                            }
                        }
                        return extra;
                    }

                    delegate: Rectangle {
                        id: dynBtn
                        required property var modelData
                        width: shellRoot.taskbarCompact ? 34 : 40
                        height: shellRoot.taskbarCompact ? 34 : 40
                        radius: 4
                        readonly property bool isFocused: Boolean(modelData && modelData.activated) && !Boolean(modelData && modelData.minimized)
                        readonly property string dynIcon: {
                            var a = ((modelData ? modelData.appId : "") || "").toLowerCase();
                            var t = ((modelData ? modelData.title : "") || "").toLowerCase();
                            if (a.indexOf("taskmgr") !== -1 || t.indexOf("tareas") !== -1) return "thispc.svg";
                            if (a.indexOf("antigravity") !== -1) return "antigravity.png";
                            if (a.indexOf("discord") !== -1) return "discord.svg";
                            if (a.indexOf("steam") !== -1) return "steam.svg";
                            if (a.indexOf("calc") !== -1) return "calculator.svg";
                            if (a.indexOf("disk") !== -1) return "drive-c.svg";
                            if (a.indexOf("update") !== -1) return "update.svg";
                            if (a.indexOf("loupe") !== -1 || a.indexOf("image") !== -1) return "folder-images.svg";
                            return "windows.svg";
                        }
                        color: isFocused ? "#20ffffff" : (dynHov.containsMouse ? "#18ffffff" : "transparent")
                        Behavior on color { ColorAnimation { duration: 115 } }
                        border.color: isFocused ? "#1affffff" : "transparent"
                        border.width: 1

                        WinSvg {
                            anchors.centerIn: parent
                            width: shellRoot.taskbarCompact ? 20 : 24
                            height: shellRoot.taskbarCompact ? 20 : 24
                            iconFile: dynBtn.dynIcon
                            scale: dynHov.pressed ? 0.84 : 1.0
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: dynBtn.isFocused ? 16 : 6
                            height: 3
                            radius: 1.5
                            color: dynBtn.isFocused ? shellRoot.accentColor : "#9a9a9a"
                            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        MouseArea {
                            id: dynHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                            onEntered: {
                                var tip = (dynBtn.modelData && dynBtn.modelData.title) ? dynBtn.modelData.title : ((dynBtn.modelData && dynBtn.modelData.appId) ? dynBtn.modelData.appId : "Ventana");
                                shellRoot.showTbTooltip(taskbarWin.modelData, mainIconsRow.x + dynBtn.x + dynBtn.width / 2, tip);
                            }
                            onExited: shellRoot.hideTbTooltip()
                            onClicked: (mouse) => {
                                shellRoot.hideTbTooltip();
                                shellRoot.activeScreen = taskbarWin.modelData;
                                if (!dynBtn.modelData) return;
                                if (mouse.button === Qt.RightButton) {
                                    shellRoot.closeAllPopups();
                                    var dynAid = String(dynBtn.modelData.appId || "");
                                    shellRoot.appJumpData = {
                                        title: dynBtn.modelData.title || dynAid || "Ventana",
                                        baseTitle: dynBtn.modelData.title || dynAid || "Aplicación",
                                        match: dynAid.toLowerCase(),
                                        iconUrl: shellRoot.resolveWindowIconUrl(dynBtn.modelData),
                                        cmd: dynAid,
                                        isPinned: false,
                                        topWin: dynBtn.modelData
                                    };
                                    var globalX = mainIconsRow.x + dynBtn.x;
                                    shellRoot.appJumpX = Math.max(12, Math.min(taskbarWin.width - 256, globalX - 80));
                                    shellRoot.appJumpOpen = true;
                                    return;
                                }
                                shellRoot.closeAllPopups();
                                if (mouse.button === Qt.MiddleButton) dynBtn.modelData.close();
                                else shellRoot.toggleWindowFocusOrMinimize(dynBtn.modelData);
                            }
                        }
                    }
                }
            }

            // [3] Right System Tray (Exact Windows 11 26H2 Layout)
            Row {
                id: rightTrayRow
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                // 3A. Show Hidden Icons Overflow Chevron ("^" — Houses all SystemTray background apps)
                Rectangle {
                    id: trayChevronBtn
                    visible: SystemTray.items.values.length > 0
                    width: 28
                    height: shellRoot.taskbarCompact ? 32 : 40
                    radius: 4
                    color: shellRoot.trayFlyoutOpen ? "#22ffffff" : (trayChevHov.containsMouse ? "#18ffffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 110 } }

                    WinSvg {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        iconFile: "fluent-chevron-up.svg"
                        transformOrigin: Item.Center
                        rotation: shellRoot.trayFlyoutOpen ? 180 : 0
                        Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: trayChevHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        onEntered: shellRoot.showTbTooltip(taskbarWin.modelData, rightTrayRow.x + trayChevronBtn.x + 14, "Mostrar iconos ocultos")
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: {
                            shellRoot.hideTbTooltip();
                            shellRoot.activeScreen = taskbarWin.modelData;
                            shellRoot.trayChevronX = rightTrayRow.x + trayChevronBtn.x + 14;
                            var next = !shellRoot.trayFlyoutOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.trayFlyoutOpen = next;
                        }
                    }
                }

                // 3C. Keyboard Layout Indicator (ESP / ES)
                Rectangle {
                    id: kbTrayBtn
                    width: 36
                    height: shellRoot.taskbarCompact ? 32 : 40
                    radius: 4
                    color: kbHov.containsMouse ? "#18ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: -1
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: shellRoot.kbLangTop(shellRoot.kbLayout)
                            color: "#f2f2f2"; font.pixelSize: 11
                        }
                        Text {
                            visible: !shellRoot.taskbarCompact
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: shellRoot.kbLangSub(shellRoot.kbLayout)
                            color: "#cfcfcf"; font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        id: kbHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        onEntered: shellRoot.showTbTooltip(taskbarWin.modelData, rightTrayRow.x + kbTrayBtn.x + 18,
                                                           shellRoot.kbLangTooltip(shellRoot.kbLayout))
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: {
                            shellRoot.hideTbTooltip();
                            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "kb-cycle"]);
                        }
                    }
                }

                // 3D. Unified Network + Volume (+ Battery) Pill
                Rectangle {
                    id: qsTrayBtn
                    width: qsTrayRow.implicitWidth + 18
                    height: shellRoot.taskbarCompact ? 32 : 40
                    radius: 4
                    color: shellRoot.quickSettingsOpen ? "#22ffffff" : (qsBtnHov.containsMouse ? "#18ffffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 110 } }
                    border.color: shellRoot.quickSettingsOpen ? "#1cffffff" : "transparent"
                    border.width: 1

                    Row {
                        id: qsTrayRow
                        anchors.centerIn: parent
                        spacing: 7
                        WinSvg {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            iconFile: shellRoot.qsWifi ? "fluent-wifi.svg" : "fluent-wifi-off.svg"
                        }
                        WinSvg {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            iconFile: (shellRoot.sinkMuted || shellRoot.sinkVolPct === 0)
                                      ? "fluent-speaker-mute.svg"
                                      : (shellRoot.sinkVolPct < 50 ? "fluent-speaker-med.svg" : "fluent-speaker-high.svg")
                        }
                        WinSvg {
                            visible: shellRoot.hasBattery
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18; height: 18
                            iconFile: shellRoot.qsBatterySaver ? "fluent-battery-saver.svg" : "fluent-battery-charge.svg"
                        }
                        Text {
                            visible: shellRoot.hasBattery && shellRoot.showBatteryPct
                            anchors.verticalCenter: parent.verticalCenter
                            text: shellRoot.batteryPct + "%"
                            color: "#f2f2f2"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: qsBtnHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onEntered: {
                            var netStr = shellRoot.qsWifi ? (shellRoot.qsWifiSsid + " (Acceso a Internet)") : "Wi-Fi desconectado";
                            var volStr = shellRoot.sinkMuted ? "Altavoces: Silenciado" : ("Altavoces: " + shellRoot.sinkVolPct + "%");
                            shellRoot.showTbTooltip(taskbarWin.modelData, rightTrayRow.x + qsTrayBtn.x + qsTrayBtn.width / 2, netStr + " • " + volStr);
                        }
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: (mouse) => {
                            shellRoot.hideTbTooltip();
                            shellRoot.activeScreen = taskbarWin.modelData;
                            if (mouse.button === Qt.MiddleButton) {
                                shellRoot.spawnCmd("/usr/bin/x64-win11-ctl volume mute");
                                return;
                            }
                            var next = !shellRoot.quickSettingsOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.quickSettingsOpen = next;
                        }
                        onWheel: (wheel) => {
                            if (wheel.angleDelta.y > 0) {
                                shellRoot.spawnCmd("/usr/bin/x64-win11-ctl volume up");
                            } else if (wheel.angleDelta.y < 0) {
                                shellRoot.spawnCmd("/usr/bin/x64-win11-ctl volume down");
                            }
                        }
                    }
                }

                // 3E. Authentic Windows 11 26H2 Clock + Date + Notification Bell Pill
                Rectangle {
                    id: clkTrayBtn
                    width: clkRow.implicitWidth + 16
                    height: shellRoot.taskbarCompact ? 32 : 40
                    radius: 4
                    color: shellRoot.calendarOpen ? "#22ffffff" : (clkHov.containsMouse ? "#18ffffff" : "transparent")
                    Behavior on color { ColorAnimation { duration: 110 } }
                    border.color: shellRoot.calendarOpen ? "#1cffffff" : "transparent"
                    border.width: 1

                    Row {
                        id: clkRow
                        anchors.centerIn: parent
                        spacing: 9

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: -1
                            Text {
                                anchors.right: parent.right
                                text: shellRoot.currentTimeStr
                                color: "#f5f5f5"
                                font.pixelSize: 12
                            }
                            Text {
                                visible: !shellRoot.taskbarCompact
                                anchors.right: parent.right
                                text: shellRoot.currentDateStr
                                color: "#d4d4d4"
                                font.pixelSize: 11
                            }
                        }

                        WinSvg {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16
                            iconFile: shellRoot.qsDnd
                                      ? "fluent-bell-snooze.svg"
                                      : (shellRoot.notifItems.length > 0 ? "fluent-bell-filled-accent.svg" : "fluent-bell.svg")
                            opacity: 0.95
                        }
                    }

                    MouseArea {
                        id: clkHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        onEntered: {
                            var extra = shellRoot.qsDnd
                                        ? " • No molestar activado"
                                        : (shellRoot.notifItems.length > 0
                                           ? (" • " + shellRoot.notifItems.length + (shellRoot.notifItems.length === 1 ? " notificación nueva" : " notificaciones nuevas"))
                                           : "");
                            shellRoot.showTbTooltip(taskbarWin.modelData, rightTrayRow.x + clkTrayBtn.x + clkTrayBtn.width / 2, shellRoot.currentLongDateStr + extra);
                        }
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: {
                            shellRoot.hideTbTooltip();
                            shellRoot.toastVisible = false;
                            shellRoot.activeScreen = taskbarWin.modelData;
                            var next = !shellRoot.calendarOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.calendarOpen = next;
                        }
                    }
                }

                // 3F. Authentic Windows 11 26H2 Invisible-at-Rest Corner Show Desktop Sliver
                Rectangle {
                    id: sdCornerBtn
                    width: 8
                    height: taskbarWin.height
                    color: sdHov.containsMouse ? "#18ffffff" : "transparent"
                    Rectangle {
                        visible: sdHov.containsMouse
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1; height: 18; color: "#55ffffff"
                    }
                    MouseArea {
                        id: sdHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        onEntered: shellRoot.showTbTooltip(taskbarWin.modelData, taskbarWin.width - 54, "Mostrar el escritorio")
                        onExited: shellRoot.hideTbTooltip()
                        onClicked: {
                            shellRoot.hideTbTooltip();
                            shellRoot.closeAllPopups();
                            shellRoot.toggleShowDesktop();
                        }
                    }
                }
            }

            // Right-Click on Empty Taskbar -> Windows 11 Taskbar Menu
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    shellRoot.hideTbTooltip();
                    shellRoot.activeScreen = taskbarWin.modelData;
                    shellRoot.closeAllPopups();
                    shellRoot.taskbarCtxX = Math.max(12, Math.min(taskbarWin.width - 250, mouse.x - 110));
                    shellRoot.taskbarCtxOpen = true;
                }
            }
        }
    }

    // =========================================================================
    // LAYER 3B: SECONDARY MONITORS LOCK SCREEN CURTAIN (True Multi-Monitor Win+L!)
    // =========================================================================
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: shellRoot.lockScreenOpen && modelData !== shellRoot.activeScreen
            WlrLayershell.namespace: "x64-win11-lock-secondary"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
            color: (shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperMode === 4) ? (shellRoot.solidBgColor || "#141923") : "#0b0e14"

            Image {
                anchors.fill: parent
                visible: !(shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperMode === 4)
                cache: false
                source: {
                    var lm = shellRoot.lockWallpaperMode;
                    if (lm === 3 && shellRoot.lockWallpaperUrl !== "") return shellRoot.lockWallpaperUrl;
                    if (lm === 0) return shellRoot.wpDir + "win11-bloom-dark.jpg";
                    if (lm === 1) return shellRoot.wpDir + "win11-bloom-light.jpg";
                    if (lm === 2) return shellRoot.wpDir + "x64-monolith.jpg";
                    if (shellRoot.wallpaperMode === 3 && shellRoot.customWallpaperUrl !== "") return shellRoot.customWallpaperUrl;
                    if (shellRoot.wallpaperMode === 1) return shellRoot.wpDir + "win11-bloom-light.jpg";
                    if (shellRoot.wallpaperMode === 2) return shellRoot.wpDir + "x64-monolith.jpg";
                    return shellRoot.wpDir + "win11-bloom-dark.jpg";
                }
                fillMode: (shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperFit === "fit") ? Image.PreserveAspectFit
                          : ((shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperFit === "stretch") ? Image.Stretch
                             : ((shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperFit === "center") ? Image.Pad : Image.PreserveAspectCrop))
            }
            Rectangle {
                anchors.fill: parent
                color: shellRoot.lockPromptOpen ? "#bf0c1018" : "#30000000"
                Behavior on color { ColorAnimation { duration: 220 } }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { if (!shellRoot.lockPromptOpen) shellRoot.lockPromptOpen = true; }
            }
        }
    }

    // =========================================================================
    // LAYER 3: OVERLAY POPUPS (Start 26H2, Search, Quick Settings, Calendar, Run, Lock)
    // =========================================================================
    PanelWindow {
        id: overlayWin
        screen: shellRoot.activeScreen
        visible: shellRoot.startOpen || shellRoot.searchOpen || shellRoot.quickSettingsOpen || shellRoot.calendarOpen ||
                 shellRoot.weatherOpen || shellRoot.taskViewOpen || shellRoot.appJumpOpen || shellRoot.trayFlyoutOpen ||
                 shellRoot.ctxMenuOpen || shellRoot.desktopItemCtxOpen || shellRoot.winXMenuOpen ||
                 shellRoot.propertiesModalOpen || shellRoot.desktopRenameOpen || shellRoot.newShortcutModalOpen ||
                 shellRoot.taskbarCtxOpen || shellRoot.runDialogOpen || shellRoot.lockScreenOpen

        WlrLayershell.namespace: "x64-win11-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: (shellRoot.startOpen || shellRoot.searchOpen || shellRoot.taskViewOpen ||
                                      shellRoot.desktopRenameOpen || shellRoot.newShortcutModalOpen ||
                                      shellRoot.runDialogOpen || shellRoot.lockScreenOpen)
                                     ? WlrKeyboardFocus.Exclusive
                                     : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        color: "transparent"

        // Click-outside backdrop to dismiss popups
        MouseArea {
            anchors.fill: parent
            enabled: !shellRoot.lockScreenOpen
            onClicked: shellRoot.closeAllPopups()
        }

        // 0. WINDOWS 11 26H2 SYSTEM TRAY OVERFLOW FLYOUT ("^")
        Rectangle {
            id: trayOverflowCard
            visible: shellRoot.trayFlyoutOpen && SystemTray.items.values.length > 0
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: shellRoot.trayFlyoutOpen ? 0 : 8
                Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
            width: trayOverflowGrid.implicitWidth + 12
            height: trayOverflowGrid.implicitHeight + 12
            x: Math.max(12, Math.min(overlayWin.width - width - 12, shellRoot.trayChevronX - width / 2))
            y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 10
            radius: 8
            color: "#f5262626"
            border.color: "#32ffffff"
            border.width: 1
            MouseArea { anchors.fill: parent }

            Grid {
                id: trayOverflowGrid
                anchors.centerIn: parent
                columns: Math.min(4, Math.max(1, SystemTray.items.values.length))
                spacing: 4

                Repeater {
                    model: SystemTray.items
                    delegate: Rectangle {
                        id: ovSniItem
                        required property var modelData
                        width: 36; height: 36; radius: 5
                        color: ovSniHov.containsMouse ? "#24ffffff" : "transparent"
                        Image {
                            anchors.centerIn: parent
                            width: 18; height: 18
                            sourceSize.width: 36; sourceSize.height: 36
                            source: modelData.icon || ""
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            smooth: true
                        }
                        MouseArea {
                            id: ovSniHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                                    modelData.display(overlayWin, trayOverflowCard.x + 6 + ovSniItem.x, trayOverflowCard.y);
                                } else {
                                    shellRoot.closeAllPopups();
                                    if (mouse.button === Qt.RightButton) modelData.secondaryActivate();
                                    else modelData.activate();
                                }
                            }
                        }
                    }
                }
            }
        }

        // 1. AUTHENTIC WINDOWS 11 26H2 EMPTY DESKTOP RIGHT-CLICK ACRYLIC CONTEXT MENU + SUBMENUS
        Item {
            visible: shellRoot.ctxMenuOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }

            Rectangle {
                id: desktopCtxCard
                x: shellRoot.ctxX
                y: Math.min(shellRoot.ctxY, overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 10)
                width: 274
                height: desktopCtxCol.implicitHeight + 12
                radius: 8
                color: "#f5282828"
                border.color: "#2effffff"
                border.width: 1
                MouseArea { anchors.fill: parent }

                readonly property var mainRows: {
                    var rows = [
                        { kind: "sub", id: "view",    icon: "fluent-grid.svg",           label: "Ver" },
                        { kind: "sub", id: "sort",    icon: "fluent-arrow-sort.svg",     label: "Ordenar por" },
                        { kind: "act", id: "refresh", icon: "fluent-refresh.svg",        label: "Actualizar" }
                    ];
                    if (shellRoot.desktopClipboardPath !== "") {
                        rows.push({ kind: "sep" });
                        rows.push({ kind: "act", id: "paste", icon: "fluent-paste.svg", label: "Pegar", hint: "Ctrl+V" });
                    }
                    rows.push({ kind: "sep" });
                    rows.push({ kind: "sub", id: "new",     icon: "fluent-add-circle.svg",     label: "Nuevo" });
                    rows.push({ kind: "sep" });
                    rows.push({ kind: "act", id: "display", icon: "fluent-display.svg",        label: "Configuración de pantalla" });
                    rows.push({ kind: "act", id: "person",  icon: "fluent-paint-brush.svg",    label: "Personalizar" });
                    rows.push({ kind: "sep" });
                    rows.push({ kind: "act", id: "term",    icon: "fluent-window-console.svg", label: "Abrir en Terminal" });
                    rows.push({ kind: "sep" });
                    rows.push({ kind: "sub", id: "more",    icon: "fluent-open-more.svg",      label: "Mostrar más opciones", hint: "Mayús+F10" });
                    return rows;
                }

                Column {
                    id: desktopCtxCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5
                    spacing: 2

                    Repeater {
                        model: desktopCtxCard.mainRows

                        delegate: Item {
                            width: 264
                            height: modelData.kind === "sep" ? 9 : 32

                            Rectangle {
                                visible: modelData.kind === "sep"
                                anchors.verticalCenter: parent.verticalCenter
                                x: 6; width: 252; height: 1; color: "#1effffff"
                            }

                            Rectangle {
                                visible: modelData.kind !== "sep"
                                anchors.fill: parent
                                radius: 5
                                color: (ctxItemHov.containsMouse || (modelData.kind === "sub" && shellRoot.ctxSubMenu === modelData.id))
                                       ? "#24ffffff"
                                       : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 12

                                    WinSvg { width: 17; height: 17; iconFile: modelData.icon || "fluent-grid.svg" }

                                    Text {
                                        text: modelData.label || ""
                                        color: "#f2f2f2"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        visible: Boolean(modelData.hint)
                                        text: modelData.hint || ""
                                        color: "#8e8e8e"
                                        font.pixelSize: 11
                                    }

                                    WinSvg {
                                        visible: modelData.kind === "sub" && !modelData.hint
                                        width: 12; height: 12
                                        iconFile: "fluent-chevron-right.svg"
                                        opacity: 0.8
                                    }
                                }

                                MouseArea {
                                    id: ctxItemHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: {
                                        if (modelData.kind === "sub" && modelData.id !== "more") {
                                            shellRoot.ctxSubY = desktopCtxCard.y + 5 + parent.parent.y;
                                            shellRoot.ctxSubMenu = modelData.id;
                                        } else if (modelData.id !== "more") {
                                            shellRoot.ctxSubMenu = "";
                                        }
                                    }
                                    onClicked: {
                                        if (modelData.kind === "sub") {
                                            shellRoot.ctxSubY = desktopCtxCard.y + 5 + parent.parent.y;
                                            shellRoot.ctxSubMenu = (shellRoot.ctxSubMenu === modelData.id) ? "" : modelData.id;
                                            return;
                                        }
                                        shellRoot.execDesktopBgAction(modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Cascading WinUI 3 Submenu ("Ver", "Ordenar por", "Nuevo", "Mostrar más opciones")
            Rectangle {
                id: desktopSubCard
                visible: shellRoot.ctxSubMenu !== ""
                width: 244
                height: desktopSubCol.implicitHeight + 12
                x: (desktopCtxCard.x + desktopCtxCard.width + width + 10 < overlayWin.width)
                   ? (desktopCtxCard.x + desktopCtxCard.width + 4)
                   : (desktopCtxCard.x - width - 4)
                y: Math.min(shellRoot.ctxSubY, overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 10)
                radius: 8
                color: shellRoot.menuBg
                border.color: "#32ffffff"
                border.width: 1
                MouseArea { anchors.fill: parent }

                readonly property var subItems: {
                    if (shellRoot.ctxSubMenu === "view") {
                        var vArr = [
                            { act: "sz_large",            label: "Iconos grandes",                   checked: shellRoot.desktopIconSizeMode === "large" },
                            { act: "sz_medium",           label: "Iconos medianos",                  checked: shellRoot.desktopIconSizeMode === "medium" },
                            { act: "sz_small",            label: "Iconos pequeños",                  checked: shellRoot.desktopIconSizeMode === "small" },
                            { sep: true },
                            { act: "toggle_auto_arrange", label: "Organizar iconos automáticamente", checked: shellRoot.desktopAutoArrange, isCheck: true },
                            { act: "toggle_ic",           label: "Mostrar iconos del escritorio",    checked: shellRoot.showDesktopIcons, isCheck: true }
                        ];
                        if (shellRoot.hasHiddenDesktopIcons) {
                            vArr.push({ sep: true });
                            vArr.push({ act: "restore_ic", label: "Restaurar iconos predeterminados", icon: "fluent-arrow-undo.svg" });
                        }
                        return vArr;
                    }
                    if (shellRoot.ctxSubMenu === "sort") {
                        return [
                            { act: "sort_name", label: "Nombre",                checked: shellRoot.desktopSortMode === "name" || shellRoot.desktopSortMode === "name_asc" || shellRoot.desktopSortMode === "name_desc" },
                            { act: "sort_size", label: "Tamaño",                checked: shellRoot.desktopSortMode === "size" },
                            { act: "sort_type", label: "Tipo de elemento",      checked: shellRoot.desktopSortMode === "type" || shellRoot.desktopSortMode === "default" },
                            { act: "sort_date", label: "Fecha de modificación", checked: shellRoot.desktopSortMode === "date" }
                        ];
                    }
                    if (shellRoot.ctxSubMenu === "new") {
                        return [
                            { act: "new_folder",   label: "Carpeta",              icon: "folder.svg" },
                            { act: "new_shortcut", label: "Acceso directo",       icon: "fluent-link.svg" },
                            { sep: true },
                            { act: "new_doc",      label: "Documento de texto",   icon: "fluent-document.svg" },
                            { act: "new_md",       label: "Notas Markdown (.md)", icon: "fluent-document.svg" }
                        ];
                    }
                    if (shellRoot.ctxSubMenu === "more") {
                        return [
                            { act: "next_wp",  label: "Siguiente fondo Windows Bloom", icon: "fluent-image.svg" },
                            { act: "explorer", label: "Explorador de archivos",        icon: "explorer.svg" },
                            { act: "taskmgr",  label: "Administrador de tareas",       icon: "taskmgr.svg" },
                            { act: "run_dlg",  label: "Ejecutar (Win + R)",            icon: "fluent-window-apps.svg" },
                            { act: "x64hello", label: "X64 Hello",                     icon: "x64lios.png" }
                        ];
                    }
                    return [];
                }

                Column {
                    id: desktopSubCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 5
                    spacing: 2

                    Repeater {
                        model: desktopSubCard.subItems

                        delegate: Item {
                            width: 234
                            height: modelData.sep ? 9 : 31

                            Rectangle {
                                visible: Boolean(modelData.sep)
                                anchors.verticalCenter: parent.verticalCenter
                                x: 6; width: 222; height: 1; color: "#1effffff"
                            }

                            Rectangle {
                                visible: !modelData.sep
                                anchors.fill: parent
                                radius: 5
                                color: subRowHov.containsMouse ? "#24ffffff" : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Item {
                                        width: 16; height: 16
                                        WinSvg {
                                            visible: Boolean(modelData.icon)
                                            anchors.centerIn: parent
                                            width: 16; height: 16
                                            iconFile: modelData.icon || "folder.svg"
                                        }
                                        WinSvg {
                                            visible: !modelData.icon && Boolean(modelData.checked) && Boolean(modelData.isCheck)
                                            anchors.centerIn: parent
                                            width: 14; height: 14
                                            iconFile: "fluent-checkmark.svg"
                                        }
                                        Rectangle {
                                            visible: !modelData.icon && Boolean(modelData.checked) && !modelData.isCheck
                                            anchors.centerIn: parent
                                            width: 6; height: 6; radius: 3
                                            color: shellRoot.accentColor
                                        }
                                    }

                                    Text {
                                        text: modelData.label || ""
                                        color: "#f2f2f2"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: subRowHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: shellRoot.execDesktopSubAction(modelData.act)
                                }
                            }
                        }
                    }
                }
            }
        }

        // 1B. AUTHENTIC WINDOWS 11 26H2 DESKTOP ICON RIGHT-CLICK CONTEXT MENU (Recycle Bin, This PC, Home, Apps, Folders & Files!)
        Rectangle {
            id: desktopItemCtxCard
            visible: shellRoot.desktopItemCtxOpen && shellRoot.desktopItemData !== null
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }
            width: 282
            height: deskItemCtxCol.implicitHeight + 12
            x: Math.max(8, Math.min(overlayWin.width - width - 10, shellRoot.desktopItemCtxX))
            y: Math.max(8, Math.min(overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 10, shellRoot.desktopItemCtxY))
            radius: 8
            color: "#f5282828"
            border.color: "#2effffff"
            border.width: 1
            MouseArea { anchors.fill: parent }

            readonly property string itemKind: shellRoot.desktopItemData ? String(shellRoot.desktopItemData.kind || "file") : "file"
            readonly property bool showTopActionBar: itemKind === "folder" || itemKind === "file" || itemKind === "shortcut_file" || itemKind === "app"

            readonly property var itemRows: {
                var d = shellRoot.desktopItemData;
                if (!d) return [];
                var k = d.kind || "file";
                var pinnedStart = shellRoot.isCmdPinnedStart(d.cmd);
                var pinnedTb = shellRoot.isCmdPinnedTaskbar(d.cmd);

                if (k === "trash") {
                    return [
                        { act: "open",        label: "Abrir",                        icon: "trash.svg",        bold: true },
                        { act: "empty_trash", label: "Vaciar Papelera de reciclaje", icon: "fluent-delete.svg", disabled: !shellRoot.trashHasFiles },
                        { sep: true },
                        { act: "pin_start",   label: pinnedStart ? "Desanclar de Inicio" : "Anclar a Inicio", icon: pinnedStart ? "fluent-pin-off.svg" : "fluent-pin.svg" },
                        { sep: true },
                        { act: "props",       label: "Propiedades",                  icon: "fluent-info.svg" }
                    ];
                }
                if (k === "thispc") {
                    return [
                        { act: "open",      label: "Abrir",                      icon: "thispc.svg",              bold: true },
                        { act: "disks",     label: "Administrar almacenamiento", icon: "drive-c.svg" },
                        { act: "taskmgr",   label: "Administrador de tareas",    icon: "taskmgr.svg" },
                        { act: "term_home", label: "Abrir en Terminal",          icon: "fluent-window-console.svg" },
                        { sep: true },
                        { act: "pin_start", label: pinnedStart ? "Desanclar de Inicio" : "Anclar a Inicio", icon: pinnedStart ? "fluent-pin-off.svg" : "fluent-pin.svg" },
                        { sep: true },
                        { act: "sys_props", label: "Propiedades",                icon: "fluent-info.svg" }
                    ];
                }
                if (k === "userhome") {
                    return [
                        { act: "open",      label: "Abrir",                      icon: "folder-home.svg",         bold: true },
                        { act: "term_home", label: "Abrir en Terminal",          icon: "fluent-window-console.svg" },
                        { sep: true },
                        { act: "pin_start", label: pinnedStart ? "Desanclar de Inicio" : "Anclar a Inicio", icon: pinnedStart ? "fluent-pin-off.svg" : "fluent-pin.svg" },
                        { act: "copy_path", label: "Copiar como ruta de acceso", icon: "fluent-link.svg" },
                        { sep: true },
                        { act: "props",     label: "Propiedades",                icon: "fluent-info.svg" }
                    ];
                }
                if (k === "app") {
                    return [
                        { act: "open",      label: "Abrir",                        iconUrl: d.iconUrl,        bold: true },
                        { act: "run_admin", label: "Ejecutar como administrador",  icon: "fluent-shield.svg" },
                        { act: "open_loc",  label: "Abrir ubicación del archivo",  icon: "folder.svg" },
                        { sep: true },
                        { act: "pin_start", label: pinnedStart ? "Desanclar de Inicio" : "Anclar a Inicio", icon: pinnedStart ? "fluent-pin-off.svg" : "fluent-pin.svg" },
                        { act: "pin_tb",    label: pinnedTb ? "Desanclar de la barra de tareas" : "Anclar a la barra de tareas", icon: pinnedTb ? "fluent-pin-off.svg" : "fluent-pin.svg" },
                        { act: "copy_path", label: "Copiar como ruta de acceso",   icon: "fluent-link.svg" },
                        { sep: true },
                        { act: "props",     label: "Propiedades",                  icon: "fluent-info.svg" }
                    ];
                }

                // Real File, Folder, or .desktop Shortcut on ~/Escritorio
                var fRows = [
                    { act: "open", label: "Abrir", iconUrl: d.iconUrl, bold: true }
                ];
                if (k === "folder") {
                    fRows.push({ act: "term_dir",  label: "Abrir en Terminal",          icon: "fluent-window-console.svg" });
                    fRows.push({ act: "pin_start", label: pinnedStart ? "Desanclar de Inicio" : "Anclar a Inicio", icon: pinnedStart ? "fluent-pin-off.svg" : "fluent-pin.svg" });
                }
                if (Boolean(d.isImage)) {
                    fRows.push({ act: "set_wp", label: "Establecer como fondo de escritorio", icon: "fluent-image.svg" });
                }
                fRows.push({ sep: true });
                fRows.push({ act: "zip_item",  label: "Comprimir en archivo ZIP",   icon: "fluent-folder-zip.svg" });
                fRows.push({ act: "copy_path", label: "Copiar como ruta de acceso", icon: "fluent-link.svg" });
                fRows.push({ sep: true });
                fRows.push({ act: "props",     label: "Propiedades",                icon: "fluent-info.svg" });
                return fRows;
            }

            Column {
                id: deskItemCtxCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                spacing: 2

                // Authentic Windows 11 26H2 Top Labeled Quick-Action Strip (Cortar, Copiar, Renombrar, Eliminar)
                Column {
                    visible: desktopItemCtxCard.showTopActionBar
                    width: 272
                    spacing: 4

                    Row {
                        x: 2
                        spacing: 2

                        Repeater {
                            model: desktopItemCtxCard.itemKind === "app"
                                   ? [
                                       { id: "q_copy_path", icon: "fluent-copy.svg",   label: "Copiar" },
                                       { id: "q_delete",    icon: "fluent-delete.svg", label: "Quitar" }
                                     ]
                                   : [
                                       { id: "q_cut",    icon: "fluent-cut.svg",    label: "Cortar" },
                                       { id: "q_copy",   icon: "fluent-copy.svg",   label: "Copiar" },
                                       { id: "q_rename", icon: "fluent-rename.svg", label: "Nombre" },
                                       { id: "q_delete", icon: "fluent-delete.svg", label: "Eliminar" }
                                     ]

                            delegate: Rectangle {
                                width: 66
                                height: 48
                                radius: 5
                                color: qActHov.containsMouse ? "#24ffffff" : "transparent"

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 17; height: 17; iconFile: modelData.icon }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#e6e6e6"; font.pixelSize: 10 }
                                }

                                MouseArea {
                                    id: qActHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: shellRoot.execDesktopQuickAction(modelData.id)
                                }
                            }
                        }
                    }

                    Rectangle { x: 6; width: 260; height: 1; color: "#1effffff" }
                }

                // Menu Rows
                Repeater {
                    model: desktopItemCtxCard.itemRows

                    delegate: Item {
                        width: 272
                        height: modelData.sep ? 9 : 32

                        Rectangle {
                            visible: Boolean(modelData.sep)
                            anchors.verticalCenter: parent.verticalCenter
                            x: 6; width: 260; height: 1; color: "#1effffff"
                        }

                        Rectangle {
                            visible: !modelData.sep
                            anchors.fill: parent
                            radius: 5
                            opacity: modelData.disabled ? 0.42 : 1.0
                            color: (dRowHov.containsMouse && !modelData.disabled) ? "#24ffffff" : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 12

                                WinSvg {
                                    width: 17; height: 17
                                    iconUrl: modelData.iconUrl || ""
                                    iconFile: modelData.icon || "fluent-info.svg"
                                }

                                Text {
                                    text: modelData.label || ""
                                    color: "#f2f2f2"
                                    font.pixelSize: 12
                                    font.weight: modelData.bold ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: dRowHov
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !modelData.disabled
                                onClicked: shellRoot.execDesktopItemAction(modelData.act)
                            }
                        }
                    }
                }
            }
        }

        // 1C. AUTHENTIC WINDOWS 11 "WIN + X" / START RIGHT-CLICK POWER USER MENU
        Item {
            visible: shellRoot.winXMenuOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }

            Rectangle {
                id: winXCard
                width: 252
                height: winXCol.implicitHeight + 12
                x: shellRoot.winXMenuX
                y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 10
                radius: 8
                color: "#f5282828"
                border.color: "#2effffff"
                border.width: 1
                MouseArea { anchors.fill: parent }

                Column {
                    id: winXCol
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 5; spacing: 2

                    Repeater {
                        model: [
                            { act: "apps",     label: "Aplicaciones instaladas" },
                            { act: "powercfg", label: "Opciones de energía" },
                            { act: "net",      label: "Conexiones de red" },
                            { act: "disks",    label: "Administración de discos" },
                            { act: "sys",      label: "Sistema" },
                            { sep: true },
                            { act: "term",     label: "Terminal" },
                            { sep: true },
                            { act: "taskmgr",  label: "Administrador de tareas" },
                            { act: "settings", label: "Configuración" },
                            { act: "explorer", label: "Explorador de archivos" },
                            { act: "search",   label: "Buscar" },
                            { act: "run",      label: "Ejecutar" },
                            { sep: true },
                            { sub: "power",    label: "Apagar o cerrar sesión" },
                            { act: "desktop",  label: "Escritorio" }
                        ]

                        delegate: Item {
                            width: 242
                            height: modelData.sep ? 9 : 30

                            Rectangle {
                                visible: Boolean(modelData.sep)
                                anchors.verticalCenter: parent.verticalCenter
                                x: 6; width: 230; height: 1; color: "#1effffff"
                            }

                            Rectangle {
                                visible: !modelData.sep
                                anchors.fill: parent
                                radius: 5
                                color: (wxHov.containsMouse || (modelData.sub && shellRoot.winXSubOpen === modelData.sub)) ? "#24ffffff" : "transparent"

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10
                                    Text { text: modelData.label || ""; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true }
                                    WinSvg { visible: Boolean(modelData.sub); width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.8 }
                                }

                                MouseArea {
                                    id: wxHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: shellRoot.winXSubOpen = modelData.sub ? modelData.sub : ""
                                    onClicked: {
                                        if (modelData.sub) {
                                            shellRoot.winXSubOpen = (shellRoot.winXSubOpen === modelData.sub) ? "" : modelData.sub;
                                            return;
                                        }
                                        var a = modelData.act;
                                        if (a === "apps") shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Aplicaciones'");
                                        else if (a === "powercfg") shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Sistema'");
                                        else if (a === "net") shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Red e Internet'");
                                        else if (a === "disks") shellRoot.spawnCmd("gnome-disks");
                                        else if (a === "sys") shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Sistema'");
                                        else if (a === "term") shellRoot.spawnCmd("kitty");
                                        else if (a === "taskmgr") shellRoot.spawnCmd("/usr/bin/x64-win11-app taskmgr");
                                        else if (a === "settings") shellRoot.spawnCmd("/usr/bin/x64-win11-app settings");
                                        else if (a === "explorer") shellRoot.spawnCmd("/usr/bin/x64-win11-app explorer 'Este equipo'");
                                        else if (a === "search") { shellRoot.closeAllPopups(); shellRoot.searchQuery = ""; shellRoot.searchOpen = true; return; }
                                        else if (a === "run") { shellRoot.closeAllPopups(); shellRoot.runDialogOpen = true; return; }
                                        else if (a === "desktop") shellRoot.toggleShowDesktop();
                                        shellRoot.closeAllPopups();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Win+X "Apagar o cerrar sesión" Submenu
            Rectangle {
                visible: shellRoot.winXSubOpen === "power"
                width: 190
                height: 162
                x: winXCard.x + winXCard.width + 4
                y: winXCard.y + winXCard.height - height - 30
                radius: 8
                color: shellRoot.menuBg
                border.color: "#32ffffff"; border.width: 1
                MouseArea { anchors.fill: parent }

                Column {
                    anchors.fill: parent; anchors.margins: 5; spacing: 2
                    Repeater {
                        model: [
                            { act: "lock",     label: "Bloquear",      icon: "fluent-lock.svg" },
                            { act: "suspend",  label: "Suspender",     icon: "fluent-sleep.svg" },
                            { act: "logout",   label: "Cerrar sesión", icon: "fluent-signout.svg" },
                            { act: "reboot",   label: "Reiniciar",     icon: "fluent-refresh.svg" },
                            { act: "poweroff", label: "Apagar",        icon: "fluent-power.svg" }
                        ]
                        delegate: Rectangle {
                            width: 180; height: 29; radius: 5
                            color: wxPwrHov.containsMouse ? "#24ffffff" : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                                WinSvg { width: 15; height: 15; iconFile: modelData.icon }
                                Text { text: modelData.label; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true }
                            }
                            MouseArea {
                                id: wxPwrHov; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    var act = modelData.act;
                                    shellRoot.closeAllPopups();
                                    if (act === "lock") { shellRoot.lockPromptOpen = false; shellRoot.lockScreenOpen = true; }
                                    else if (act === "suspend") shellRoot.spawnCmd("systemctl suspend");
                                    else if (act === "logout") shellRoot.spawnCmd("labwc -e");
                                    else if (act === "reboot") shellRoot.spawnCmd("systemctl reboot");
                                    else if (act === "poweroff") shellRoot.spawnCmd("systemctl poweroff");
                                }
                            }
                        }
                    }
                }
            }
        }

        // 1D. AUTHENTIC WINDOWS 11 PROPERTIES MODAL ("Propiedades")
        Rectangle {
            visible: shellRoot.propertiesModalOpen && shellRoot.propertiesData !== null
            anchors.centerIn: parent
            width: 390
            height: propsInnerCol.implicitHeight + 84
            radius: 10
            color: shellRoot.menuBg
            border.color: "#34ffffff"
            border.width: 1
            z: 90
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Titlebar
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 36
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 14; spacing: 10
                        WinSvg { width: 16; height: 16; iconUrl: (shellRoot.propertiesData && shellRoot.propertiesData.iconUrl) ? shellRoot.propertiesData.iconUrl : "" }
                        Text {
                            text: "Propiedades: " + (shellRoot.propertiesData ? String(shellRoot.propertiesData.title || "").replace(/\n/g, " ") : "")
                            color: "#f2f2f2"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 42; height: 36; color: propCloseHov.containsMouse ? "#c42b1c" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 11; height: 11; iconFile: "fluent-dismiss.svg" }
                            MouseArea { id: propCloseHov; anchors.fill: parent; hoverEnabled: true; onClicked: shellRoot.propertiesModalOpen = false }
                        }
                    }
                }

                Column {
                    id: propsInnerCol
                    Layout.fillWidth: true
                    Layout.margins: 18
                    spacing: 12

                    RowLayout {
                        width: 354; spacing: 14
                        WinSvg { width: 44; height: 44; iconUrl: (shellRoot.propertiesData && shellRoot.propertiesData.iconUrl) ? shellRoot.propertiesData.iconUrl : "" }
                        Column {
                            Layout.fillWidth: true; spacing: 3
                            Text {
                                text: shellRoot.propertiesData ? String(shellRoot.propertiesData.title || "").replace(/\n/g, " ") : ""
                                color: "#ffffff"; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight; width: 290
                            }
                            Text {
                                text: shellRoot.propertiesData ? (shellRoot.propertiesData.typeLabel || "Elemento") : ""
                                color: "#9e9e9e"; font.pixelSize: 12
                            }
                        }
                    }

                    Rectangle { width: 354; height: 1; color: "#1effffff" }

                    Grid {
                        width: 354
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 16

                        Text { text: "Tipo:"; color: "#9e9e9e"; font.pixelSize: 12; width: 92 }
                        Text { text: shellRoot.propertiesData ? (shellRoot.propertiesData.typeLabel || "Objeto") : ""; color: "#f0f0f0"; font.pixelSize: 12; width: 244; elide: Text.ElideRight }

                        Text { text: "Ubicación:"; color: "#9e9e9e"; font.pixelSize: 12; width: 92 }
                        Text { text: shellRoot.propertiesData ? (shellRoot.propertiesData.realPath || "~") : ""; color: "#f0f0f0"; font.pixelSize: 12; width: 244; elide: Text.ElideMiddle }

                        Text { text: "Tamaño:"; color: "#9e9e9e"; font.pixelSize: 12; width: 92 }
                        Text { text: shellRoot.propertiesData ? (shellRoot.propertiesData.sizeLabel || "0 B") : ""; color: "#f0f0f0"; font.pixelSize: 12; width: 244 }

                        Text { text: "Modificado:"; color: "#9e9e9e"; font.pixelSize: 12; width: 92 }
                        Text { text: shellRoot.propertiesData ? (shellRoot.propertiesData.mtimeStr || "Hoy") : ""; color: "#f0f0f0"; font.pixelSize: 12; width: 244 }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 50
                    color: "#1b1b1b"
                    Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#1cffffff" }
                    RowLayout {
                        anchors.fill: parent; anchors.rightMargin: 16; anchors.leftMargin: 16
                        Rectangle {
                            visible: Boolean(shellRoot.propertiesData && shellRoot.propertiesData.kind === "trash" && shellRoot.trashHasFiles)
                            width: 132; height: 30; radius: 5; color: "#2e2e2e"; border.color: "#22ffffff"
                            Text { anchors.centerIn: parent; text: "Vaciar papelera"; color: "#f2f2f2"; font.pixelSize: 12 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "empty-trash"]);
                                    shellRoot.propertiesModalOpen = false;
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 92; height: 30; radius: 5; color: shellRoot.accentColor
                            Text { anchors.centerIn: parent; text: "Aceptar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.propertiesModalOpen = false }
                        }
                    }
                }
            }
        }

        // 1E. DESKTOP RENAME DIALOG ("Cambiar nombre")
        Rectangle {
            visible: shellRoot.desktopRenameOpen && shellRoot.desktopRenameData !== null
            onVisibleChanged: {
                if (visible) {
                    renameDialogInput.text = shellRoot.desktopRenameData ? String(shellRoot.desktopRenameData.title || "").replace(/\n/g, " ") : "";
                    renameDialogInput.forceActiveFocus();
                    renameDialogInput.selectAll();
                }
            }
            anchors.centerIn: parent
            width: 380; height: 168; radius: 10
            color: shellRoot.menuBg; border.color: "#34ffffff"; border.width: 1; z: 90
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 12
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 18; height: 18; iconFile: "fluent-rename.svg" }
                    Text { text: "Cambiar nombre"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: 5; color: "#171717"; border.color: shellRoot.accentColor; border.width: 1
                    TextInput {
                        id: renameDialogInput
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 13; selectByMouse: true
                        Keys.onEscapePressed: shellRoot.desktopRenameOpen = false
                        onAccepted: {
                            if (shellRoot.desktopRenameData && shellRoot.desktopRenameData.realPath && text.trim() !== "") {
                                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "rename-path", shellRoot.desktopRenameData.realPath, text.trim()]);
                            }
                            shellRoot.desktopRenameOpen = false;
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 90; height: 30; radius: 5; color: shellRoot.accentColor
                        Text { anchors.centerIn: parent; text: "Guardar"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: renameDialogInput.accepted() }
                    }
                    Rectangle {
                        width: 90; height: 30; radius: 5; color: "#2d2d2d"; border.color: "#22ffffff"
                        Text { anchors.centerIn: parent; text: "Cancelar"; color: "#f2f2f2"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.desktopRenameOpen = false }
                    }
                }
            }
        }

        // 1F. CREATE SHORTCUT MODAL ("Nuevo › Acceso directo")
        Rectangle {
            visible: shellRoot.newShortcutModalOpen
            onVisibleChanged: {
                if (visible) {
                    newShortcutNameIn.text = "";
                    newShortcutCmdIn.text = "";
                    newShortcutNameIn.forceActiveFocus();
                }
            }
            anchors.centerIn: parent
            width: 400; height: 224; radius: 10
            color: shellRoot.menuBg; border.color: "#34ffffff"; border.width: 1; z: 90
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 10
                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    WinSvg { width: 18; height: 18; iconFile: "fluent-link.svg" }
                    Text { text: "Crear acceso directo en el Escritorio"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                }
                Text { text: "Nombre del acceso directo:"; color: "#c8c8c8"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 32; radius: 5; color: "#171717"; border.color: shellRoot.accentColor
                    TextInput {
                        id: newShortcutNameIn
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12
                        KeyNavigation.tab: newShortcutCmdIn
                        Keys.onEscapePressed: shellRoot.newShortcutModalOpen = false
                    }
                }
                Text { text: "Comando o ubicación del elemento:"; color: "#c8c8c8"; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; height: 32; radius: 5; color: "#171717"; border.color: "#32ffffff"
                    TextInput {
                        id: newShortcutCmdIn
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12
                        Keys.onEscapePressed: shellRoot.newShortcutModalOpen = false
                        onAccepted: {
                            if (newShortcutCmdIn.text.trim() !== "") {
                                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "new-desktop-shortcut", newShortcutNameIn.text.trim() || "Acceso directo", newShortcutCmdIn.text.trim()]);
                                shellRoot.newShortcutModalOpen = false;
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 90; height: 30; radius: 5; color: shellRoot.accentColor
                        Text { anchors.centerIn: parent; text: "Crear"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: newShortcutCmdIn.accepted() }
                    }
                    Rectangle {
                        width: 90; height: 30; radius: 5; color: "#2d2d2d"
                        Text { anchors.centerIn: parent; text: "Cancelar"; color: "#f2f2f2"; font.pixelSize: 12 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.newShortcutModalOpen = false }
                    }
                }
            }
        }

        // 2. AUTHENTIC WINDOWS 11 26H2 TASKBAR RIGHT-CLICK MENU
        Rectangle {
            visible: shellRoot.taskbarCtxOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }
            x: Math.max(12, Math.min(overlayWin.width - width - 12, shellRoot.taskbarCtxX))
            y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 10
            width: 268
            height: 83
            radius: 8
            color: "#f5282828"
            border.color: "#2effffff"
            border.width: 1
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent; anchors.margins: 5; spacing: 2
                Rectangle {
                    width: 258; height: 32; radius: 5
                    color: tbCtx1.containsMouse ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 12
                        WinSvg { width: 17; height: 17; iconFile: "fluent-task-manager.svg" }
                        Text { text: "Administrador de tareas"; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: tbCtx1; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            shellRoot.taskbarCtxOpen = false;
                            shellRoot.spawnCmd("/usr/bin/x64-win11-app taskmgr");
                        }
                    }
                }

                Item {
                    width: 258; height: 5
                    Rectangle { anchors.centerIn: parent; width: 244; height: 1; color: "#1effffff" }
                }

                Rectangle {
                    width: 258; height: 32; radius: 5
                    color: tbCtx2.containsMouse ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 12
                        WinSvg { width: 17; height: 17; iconFile: "fluent-settings.svg" }
                        Text { text: "Configuración de la barra de tareas"; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: tbCtx2; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            shellRoot.taskbarCtxOpen = false;
                            shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Personalización (26H2)'");
                        }
                    }
                }
            }
        }

        // 2B. AUTHENTIC WINDOWS 11 26H2 TASKBAR APP JUMP LIST MENU
        Rectangle {
            visible: shellRoot.appJumpOpen && shellRoot.appJumpData !== null
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }
            x: Math.max(12, Math.min(overlayWin.width - width - 12, shellRoot.appJumpX))
            y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 10
            width: 256
            height: jmpCol.implicitHeight + 10
            radius: 8
            color: "#f5282828"
            border.color: "#2effffff"
            border.width: 1
            MouseArea { anchors.fill: parent }

            Column {
                id: jmpCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 5
                spacing: 2

                // Option 1: App Title (Opens app or new instance)
                Rectangle {
                    width: 246; height: 32; radius: 5
                    color: jmp1.containsMouse ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 11
                        WinSvg { width: 16; height: 16; iconUrl: (shellRoot.appJumpData && shellRoot.appJumpData.iconUrl) ? shellRoot.appJumpData.iconUrl : "" }
                        Text {
                            text: (shellRoot.appJumpData && shellRoot.appJumpData.title) ? shellRoot.appJumpData.title : "Abrir aplicación"
                            color: "#f2f2f2"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                    MouseArea {
                        id: jmp1; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            var d = shellRoot.appJumpData;
                            shellRoot.appJumpOpen = false;
                            if (d && d.cmd !== "") shellRoot.spawnCmd(d.cmd);
                            else if (d && d.topWin) shellRoot.toggleWindowFocusOrMinimize(d.topWin);
                        }
                    }
                }

                // Option 1B: Pin / Unpin from Taskbar
                Rectangle {
                    visible: Boolean(shellRoot.appJumpData && shellRoot.appJumpData.cmd !== "")
                    width: 246; height: 32; radius: 5
                    color: jmpPinHov.containsMouse ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 11
                        WinSvg {
                            width: 16; height: 16
                            iconFile: (shellRoot.appJumpData && shellRoot.appJumpData.isPinned) ? "fluent-pin-off.svg" : "fluent-pin.svg"
                        }
                        Text {
                            text: (shellRoot.appJumpData && shellRoot.appJumpData.isPinned)
                                  ? "Desanclar de la barra de tareas"
                                  : "Anclar a la barra de tareas"
                            color: "#f2f2f2"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                    MouseArea {
                        id: jmpPinHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            var d = shellRoot.appJumpData;
                            shellRoot.appJumpOpen = false;
                            if (d && d.cmd) {
                                Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "toggle-pin-taskbar", d.baseTitle || d.title || "App", d.cmd, d.iconUrl || "", d.match || ""]);
                            }
                        }
                    }
                }

                // Option 2: Minimize / Restore (when open)
                Rectangle {
                    visible: Boolean(shellRoot.appJumpData && shellRoot.appJumpData.topWin)
                    width: 246; height: 32; radius: 5
                    color: jmp2.containsMouse ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 11
                        WinSvg {
                            width: 16; height: 16
                            iconFile: (shellRoot.appJumpData && shellRoot.appJumpData.topWin && shellRoot.appJumpData.topWin.minimized)
                                      ? "fluent-maximize.svg"
                                      : "fluent-subtract.svg"
                        }
                        Text {
                            text: (shellRoot.appJumpData && shellRoot.appJumpData.topWin && shellRoot.appJumpData.topWin.minimized) ? "Restaurar ventana" : "Minimizar ventana"
                            color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true
                        }
                    }
                    MouseArea {
                        id: jmp2; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            var d = shellRoot.appJumpData;
                            shellRoot.appJumpOpen = false;
                            if (d && d.topWin) shellRoot.toggleWindowFocusOrMinimize(d.topWin);
                        }
                    }
                }

                Item {
                    visible: Boolean(shellRoot.appJumpData && shellRoot.appJumpData.topWin)
                    width: 246; height: 5
                    Rectangle { anchors.centerIn: parent; width: 232; height: 1; color: "#1effffff" }
                }

                // Option 3: Close Window (when open — Clean WinUI 3 subtle hover)
                Rectangle {
                    visible: Boolean(shellRoot.appJumpData && shellRoot.appJumpData.topWin)
                    width: 246; height: 32; radius: 5
                    color: jmp3.containsMouse ? "#24ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 11
                        WinSvg { width: 16; height: 16; iconFile: "fluent-dismiss.svg" }
                        Text { text: "Cerrar ventana"; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: jmp3; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            var d = shellRoot.appJumpData;
                            shellRoot.appJumpOpen = false;
                            if (d && d.topWin) d.topWin.close();
                        }
                    }
                }
            }
        }

        // 2C. WINDOWS 11 REAL METEOROLOGY & FORECAST PANEL (Left Taskbar Button)
        Rectangle {
            id: weatherPopupCard
            visible: shellRoot.weatherOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: shellRoot.weatherOpen ? 0 : 12
                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            x: 12
            y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 12
            width: 410
            height: weatherMainCol.implicitHeight + 40
            radius: 12
            color: "#f51f1f1f"
            border.color: "#30ffffff"
            border.width: 1
            MouseArea { anchors.fill: parent }

            Column {
                id: weatherMainCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 20
                spacing: 14

                // Header: Location & Live Refresh Button with Spinner
                RowLayout {
                    width: 370
                    WinSvg { width: 24; height: 24; iconFile: shellRoot.weatherData.icon || "win11-weather.svg" }
                    Column {
                        Layout.fillWidth: true
                        Text { text: shellRoot.weatherData.location || "El Tiempo"; color: "#ffffff"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight; width: 265 }
                        Text {
                            text: shellRoot.weatherRefreshing
                                  ? "Actualizando en tiempo real..."
                                  : ("Actualizado en vivo a las " + (shellRoot.weatherData.updatedAt || shellRoot.currentTimeStr))
                            color: shellRoot.weatherRefreshing ? "#60cdff" : "#999999"
                            font.pixelSize: 10
                        }
                    }
                    Rectangle {
                        width: 30; height: 30; radius: 6
                        color: (shellRoot.weatherRefreshing || wRefHov.containsMouse) ? "#28ffffff" : "transparent"
                        WinSvg {
                            id: wRefIcon
                            anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-refresh.svg"
                            transformOrigin: Item.Center
                            NumberAnimation on rotation {
                                from: 0; to: 360; duration: 650
                                loops: Animation.Infinite
                                running: shellRoot.weatherRefreshing
                                onStopped: wRefIcon.rotation = 0
                            }
                        }
                        MouseArea {
                            id: wRefHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.triggerLiveWeatherRefresh()
                        }
                    }
                }

                // [1] Current Weather Hero Card
                Rectangle {
                    width: 370; height: 138; radius: 8; color: "#282828"; border.color: "#22ffffff"
                    Column {
                        anchors.fill: parent; anchors.margins: 14; spacing: 10
                        RowLayout {
                            width: 342; spacing: 14
                            WinSvg { width: 56; height: 56; iconFile: shellRoot.weatherData.icon || "win11-weather.svg" }
                            Column {
                                Layout.fillWidth: true; spacing: 2
                                Row {
                                    spacing: 10
                                    Text { text: shellRoot.weatherData.temp || "--°C"; color: "#ffffff"; font.pixelSize: 30; font.bold: true }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text { text: shellRoot.weatherData.desc || ""; color: "#60cdff"; font.pixelSize: 13; font.bold: true }
                                        Text { text: "Máx: " + (shellRoot.weatherData.todayMax || "--°") + "  •  Mín: " + (shellRoot.weatherData.todayMin || "--°"); color: "#bbbbbb"; font.pixelSize: 11 }
                                    }
                                }
                            }
                        }

                        Rectangle { width: 342; height: 1; color: "#1fffffff" }

                        // 4 Real Meteorological Metrics (Sensación, Humedad, Viento, Lluvia)
                        Row {
                            width: 342; spacing: 10
                            Repeater {
                                model: [
                                    { label: "Sensación", val: shellRoot.weatherData.feelsLike || "--°C" },
                                    { label: "Humedad",   val: shellRoot.weatherData.humidity || "--%" },
                                    { label: "Viento",    val: shellRoot.weatherData.wind || "-- km/h" },
                                    { label: "Lluvia",    val: shellRoot.weatherData.rainProb || "--%" }
                                ]
                                delegate: Column {
                                    width: 78; spacing: 2
                                    Text { text: modelData.label; color: "#999999"; font.pixelSize: 10 }
                                    Text { text: modelData.val; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                }
                            }
                        }
                    }
                }

                // [2] Hourly Forecast Strip (Pronóstico por horas)
                Column {
                    width: 370; spacing: 6
                    Text { text: "Pronóstico por horas"; color: "#cccccc"; font.pixelSize: 11; font.bold: true }
                    Rectangle {
                        width: 370; height: 86; radius: 8; color: "#282828"; border.color: "#22ffffff"
                        Row {
                            anchors.centerIn: parent; spacing: 12
                            Repeater {
                                model: shellRoot.weatherData.hourly || []
                                delegate: Column {
                                    width: 60; spacing: 4
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.time; color: "#aaaaaa"; font.pixelSize: 10 }
                                    WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 24; height: 24; iconFile: modelData.icon || "win11-weather.svg" }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.temp; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                }
                            }
                        }
                    }
                }

                // [3] 5-Day Forecast List (Pronóstico de 5 días)
                Column {
                    width: 370; spacing: 6
                    Text { text: "Pronóstico de 5 días"; color: "#cccccc"; font.pixelSize: 11; font.bold: true }
                    Rectangle {
                        width: 370
                        height: dailyListCol.implicitHeight + 24
                        radius: 8
                        color: "#282828"
                        border.color: "#22ffffff"
                        Column {
                            id: dailyListCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 5
                            Repeater {
                                model: shellRoot.weatherData.daily || []
                                delegate: Rectangle {
                                    width: 346; height: 32; radius: 5
                                    color: index === 0 ? "#18ffffff" : "transparent"
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                        Text { text: modelData.day; color: "#ffffff"; font.pixelSize: 12; font.bold: index === 0; Layout.preferredWidth: 68 }
                                        WinSvg { width: 20; height: 20; iconFile: modelData.icon || "win11-weather.svg" }
                                        Text { text: modelData.desc; color: "#cccccc"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                        Text { text: "Lluvia " + modelData.rain; color: "#60cdff"; font.pixelSize: 11; Layout.preferredWidth: 74 }
                                        Text { text: modelData.max + " / " + modelData.min; color: "#ffffff"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 58 }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2D. AUTHENTIC WINDOWS 11 26H2 FULL-SCREEN TASK VIEW ("Win + Tab" + Desktops Strip)
        Rectangle {
            id: taskViewSurface
            visible: shellRoot.taskViewOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            x: 0
            y: 0
            width: overlayWin.width
            height: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48)
            color: "#d414161d"
            focus: shellRoot.taskViewOpen
            Keys.onEscapePressed: shellRoot.closeAllPopups()
            onVisibleChanged: {
                if (visible) {
                    taskViewSurface.forceActiveFocus();
                    if (!wsSyncProc.running) wsSyncProc.running = true;
                }
            }

            // Click empty background in Task View to dismiss
            MouseArea {
                anchors.fill: parent
                onClicked: shellRoot.closeAllPopups()
            }

            readonly property var openWindowsList: ToplevelManager.toplevels ? ToplevelManager.toplevels.values : []

            // Empty State when 0 windows open
            Column {
                visible: taskViewSurface.openWindowsList.length === 0
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -54
                spacing: 10
                WinSvg {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 44; height: 44
                    iconFile: "win11-taskview.svg"
                    opacity: 0.7
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No hay ventanas abiertas en " + shellRoot.activeVirtualDesktopName
                    color: "#cfcfcf"
                    font.pixelSize: 15
                }
            }

            // Centered Responsive Window Cards Grid
            Flickable {
                visible: taskViewSurface.openWindowsList.length > 0
                width: Math.min(1260, parent.width - 96)
                height: Math.min(parent.height - 190, tvWindowsFlow.implicitHeight + 12)
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(44, (parent.height - 144 - height) / 2)
                contentWidth: width
                contentHeight: tvWindowsFlow.implicitHeight
                clip: true

                Flow {
                    id: tvWindowsFlow
                    width: parent.width
                    spacing: 20

                    Repeater {
                        model: taskViewSurface.openWindowsList

                        delegate: Rectangle {
                            required property var modelData
                            width: 288
                            height: 178
                            radius: 10
                            color: tvCardHov.containsMouse ? "#f52d2d2d" : "#f0242424"
                            border.color: (modelData && modelData.activated) ? shellRoot.accentColor : (tvCardHov.containsMouse ? "#48ffffff" : "#26ffffff")
                            border.width: (modelData && modelData.activated) ? 2 : 1
                            Behavior on color { ColorAnimation { duration: 110 } }

                            Column {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                // Window Title Header Row
                                RowLayout {
                                    width: 268
                                    height: 24
                                    spacing: 8

                                    WinSvg {
                                        width: 18; height: 18
                                        iconUrl: shellRoot.resolveWindowIconUrl(modelData)
                                    }

                                    Text {
                                        text: (modelData && modelData.title) ? modelData.title : ((modelData && modelData.appId) ? modelData.appId : "Ventana")
                                        color: "#f2f2f2"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        width: 24; height: 24; radius: 5
                                        color: tvCloseHov.containsMouse ? "#c42b1c" : "transparent"
                                        opacity: (tvCardHov.containsMouse || tvCloseHov.containsMouse) ? 1.0 : 0.0
                                        Behavior on opacity { NumberAnimation { duration: 100 } }
                                        WinSvg { anchors.centerIn: parent; width: 11; height: 11; iconFile: "fluent-dismiss.svg" }
                                        MouseArea {
                                            id: tvCloseHov
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { if (modelData) modelData.close(); }
                                        }
                                    }
                                }

                                // Window Preview Surface
                                Rectangle {
                                    width: 268
                                    height: 126
                                    radius: 6
                                    color: "#1a1a1a"
                                    border.color: "#1affffff"
                                    border.width: 1
                                    clip: true

                                    // Subtle Window Chrome Header Accent inside Thumbnail
                                    Rectangle {
                                        width: 268; height: 20
                                        color: "#232323"
                                        Row {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6
                                            Rectangle { width: 6; height: 1; color: "#777777"; anchors.verticalCenter: parent.verticalCenter }
                                            Rectangle { width: 6; height: 6; color: "transparent"; border.color: "#777777"; border.width: 1 }
                                        }
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: 8
                                        spacing: 8
                                        WinSvg {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 44; height: 44
                                            iconUrl: shellRoot.resolveWindowIconUrl(modelData)
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: (modelData && modelData.minimized)
                                                  ? "Minimizada"
                                                  : ((modelData && modelData.activated) ? "En primer plano" : "Abierta")
                                            color: (modelData && modelData.activated && !modelData.minimized) ? shellRoot.accentColor : "#969696"
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: tvCardHov
                                anchors.fill: parent
                                anchors.rightMargin: 36
                                z: -1
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shellRoot.closeAllPopups();
                                    if (modelData) {
                                        modelData.minimized = false;
                                        modelData.activate();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Authentic Windows 11 26H2 Bottom Virtual Desktops Strip ("Escritorio 1 | + Nuevo escritorio")
            Rectangle {
                id: desktopsDockBar
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                width: Math.min(parent.width - 48, desktopsRow.implicitWidth + 24)
                height: 112
                radius: 10
                color: shellRoot.panelBg
                border.color: "#2effffff"
                border.width: 1
                clip: true
                MouseArea { anchors.fill: parent }

                Flickable {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    contentWidth: desktopsRow.implicitWidth
                    contentHeight: height
                    flickableDirection: Flickable.HorizontalFlick
                    interactive: contentWidth > width
                    clip: true

                Row {
                    id: desktopsRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Repeater {
                        model: shellRoot.virtualDesktops

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property int deskNum: Number(modelData.index || (index + 1))
                            readonly property string deskName: String(modelData.name || ("Escritorio " + deskNum))
                            readonly property bool isCur: shellRoot.activeVirtualDesktop === deskNum
                            width: 148
                            height: 92
                            radius: 7
                            color: (deskCardHov.containsMouse || deskCloseHov.containsMouse) ? "#2cffffff" : (isCur ? "#1effffff" : "transparent")
                            Behavior on color { ColorAnimation { duration: 110 } }

                            MouseArea {
                                id: deskCardHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shellRoot.activeVirtualDesktop = deskNum;
                                    shellRoot.activeVirtualDesktopName = deskName;
                                    Quickshell.execDetached(["/usr/bin/x64-win11-workspaces", "switch", String(deskNum)]);
                                    shellRoot.closeAllPopups();
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 118
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: deskName
                                    color: isCur ? "#ffffff" : "#cfcfcf"
                                    font.pixelSize: 11
                                    font.weight: isCur ? Font.DemiBold : Font.Normal
                                }

                                Rectangle {
                                    width: 128
                                    height: 60
                                    radius: 5
                                    clip: true
                                    border.color: isCur ? shellRoot.accentColor : "#30ffffff"
                                    border.width: isCur ? 2 : 1
                                    color: shellRoot.wallpaperMode === 4 ? (shellRoot.solidBgColor || "#141923") : "#0b0e14"

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: isCur ? 2 : 1
                                        visible: shellRoot.wallpaperMode !== 4
                                        source: (shellRoot.wallpaperMode === 3 && shellRoot.customWallpaperUrl !== "")
                                                ? shellRoot.customWallpaperUrl
                                                : (shellRoot.wallpaperMode === 0
                                                   ? (shellRoot.wpDir + "win11-bloom-dark.jpg")
                                                   : (shellRoot.wallpaperMode === 1
                                                      ? (shellRoot.wpDir + "win11-bloom-light.jpg")
                                                      : (shellRoot.wpDir + "x64-monolith.jpg")))
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }
                            }

                            // Authentic Windows 11 Close Desktop button ("✕") when > 1 desktop exists
                            Rectangle {
                                visible: shellRoot.virtualDesktopCount > 1
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 3
                                anchors.rightMargin: 3
                                width: 20
                                height: 20
                                radius: 4
                                z: 5
                                color: deskCloseHov.containsMouse ? "#c42b1c" : "#b8242424"
                                border.color: "#2cffffff"
                                border.width: 1
                                opacity: (deskCardHov.containsMouse || deskCloseHov.containsMouse) ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 100 } }

                                WinSvg {
                                    anchors.centerIn: parent
                                    width: 9; height: 9
                                    iconFile: "fluent-dismiss.svg"
                                }

                                MouseArea {
                                    id: deskCloseHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        Quickshell.execDetached(["/usr/bin/x64-win11-workspaces", "remove", String(deskNum)]);
                                    }
                                }
                            }
                        }
                    }

                    // "+ Nuevo escritorio" Card (up to 8 real labwc virtual desktops!)
                    Rectangle {
                        visible: shellRoot.virtualDesktopCount < 8
                        width: 138
                        height: 92
                        radius: 7
                        color: addDeskHov.containsMouse ? "#26ffffff" : "transparent"

                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Nuevo escritorio"
                                color: "#cfcfcf"
                                font.pixelSize: 11
                            }
                            Rectangle {
                                width: 118
                                height: 60
                                radius: 5
                                color: "#282828"
                                border.color: "#28ffffff"
                                border.width: 1
                                WinSvg {
                                    anchors.centerIn: parent
                                    width: 22; height: 22
                                    iconFile: "fluent-add.svg"
                                }
                            }
                        }

                        MouseArea {
                            id: addDeskHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (shellRoot.virtualDesktopCount < 8) {
                                    Quickshell.execDetached(["/usr/bin/x64-win11-workspaces", "add"]);
                                }
                            }
                        }
                    }
                }
                }
            }
        }

        // 3. WINDOWS 11 26H2 UNIFIED START MENU + PHONE LINK COMPANION (1:1 AUTHENTIC DESIGN)
        Item {
            width: shellRoot.showPhoneLink ? 918 : 656
            height: 700
            x: shellRoot.taskbarLeftAlign ? 12 : Math.round((overlayWin.width - width) / 2)
            y: overlayWin.height - height - (shellRoot.taskbarCompact ? 38 : 48) - 12
            visible: shellRoot.startOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: shellRoot.startOpen ? 0 : 14
                Behavior on y { NumberAnimation { duration: 155; easing.type: Easing.OutCubic } }
            }
            onVisibleChanged: {
                if (visible) {
                    shellRoot.searchQuery = "";
                    shellRoot.startViewDropdownOpen = false;
                    shellRoot.expandedCategoryObj = null;
                    startSearchInput.forceActiveFocus();
                }
            }

            Row {
                anchors.fill: parent
                spacing: 12

                // [A] Main Windows 11 26H2 Start Menu Surface (656x700)
                Rectangle {
                    id: startMainSurface
                    width: 656
                    height: 700
                    radius: 12
                    color: shellRoot.panelBg
                    border.color: "#2cffffff"
                    border.width: 1

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            shellRoot.startViewDropdownOpen = false;
                            shellRoot.powerPopupOpen = false;
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // 1. Authentic Matte Top Search Pill + Phone Link Companion Toggle
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74

                            RowLayout {
                                anchors.centerIn: parent
                                width: 592
                                spacing: 10

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 19
                                    color: startSearchInput.activeFocus ? "#1e1e1e" : "#252525"
                                    border.color: "#2affffff"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        WinSvg { width: 16; height: 16; iconFile: "fluent-search.svg"; opacity: 0.88 }

                                        TextInput {
                                            id: startSearchInput
                                            Layout.fillWidth: true
                                            color: "#ffffff"
                                            font.pixelSize: 13
                                            focus: true
                                            selectByMouse: true
                                            text: shellRoot.searchQuery
                                            onTextChanged: shellRoot.searchQuery = text
                                            Keys.onEscapePressed: shellRoot.closeAllPopups()
                                            onAccepted: {
                                                var q = text.trim().toLowerCase();
                                                if (q !== "") {
                                                    var apps = shellRoot.allApps;
                                                    for (var i = 0; i < apps.length; i++) {
                                                        if (apps[i].name.toLowerCase().indexOf(q) !== -1) {
                                                            shellRoot.startOpen = false;
                                                            shellRoot.spawnCmd(apps[i].cmd);
                                                            return;
                                                        }
                                                    }
                                                }
                                            }
                                            Text {
                                                visible: startSearchInput.text === ""
                                                text: "Buscar aplicaciones, configuración y documentos"
                                                color: "#9e9e9e"
                                                font.pixelSize: 13
                                            }
                                        }

                                        Rectangle {
                                            visible: startSearchInput.text !== ""
                                            width: 22; height: 22; radius: 11
                                            color: stClrHov.containsMouse ? "#28ffffff" : "transparent"
                                            WinSvg { anchors.centerIn: parent; width: 11; height: 11; iconFile: "fluent-dismiss.svg" }
                                            MouseArea {
                                                id: stClrHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                                onClicked: { shellRoot.searchQuery = ""; startSearchInput.text = ""; startSearchInput.forceActiveFocus(); }
                                            }
                                        }
                                    }
                                }

                                // Official 26H2 Phone Link Companion Toggle Icon right next to Search Bar
                                Rectangle {
                                    width: 38; height: 38; radius: 8
                                    color: shellRoot.showPhoneLink ? "#28ffffff" : (phToggleHov.containsMouse ? "#1effffff" : "#252525")
                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    border.color: shellRoot.showPhoneLink ? "#38ffffff" : "#24ffffff"
                                    border.width: 1

                                    WinSvg {
                                        anchors.centerIn: parent
                                        width: 18; height: 18
                                        iconFile: shellRoot.showPhoneLink ? "fluent-phone-filled.svg" : "fluent-phone.svg"
                                    }

                                    MouseArea {
                                        id: phToggleHov
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            var nextPh = !shellRoot.showPhoneLink;
                                            shellRoot.showPhoneLink = nextPh;
                                            shellRoot.saveConfigKey("showPhoneLink", nextPh ? "true" : "false");
                                        }
                                    }
                                }
                            }
                        }

                        // 2. Unified Single-Page Scrollable Start Body
                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: startScrollCol.implicitHeight + 28
                            clip: true
                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                            Column {
                                id: startScrollCol
                                x: 32
                                width: 592
                                spacing: 20

                                // [SECTION 1] ANCLADOS (Hidden while typing a search query so results appear immediately)
                                Column {
                                    width: 592
                                    spacing: 12
                                    visible: shellRoot.searchQuery.trim() === ""

                                    RowLayout {
                                        width: 592
                                        Text {
                                            text: "Anclados"
                                            color: "#ffffff"
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                        }
                                        Item { Layout.fillWidth: true }

                                        // Authentic Windows 11 "Mostrar todo >" / "Mostrar menos ^" Subtle Pill
                                        Rectangle {
                                            visible: shellRoot.startPinned.length > 12
                                            width: pinExpRow.implicitWidth + 18
                                            height: 26
                                            radius: 5
                                            color: pinExpHov.containsMouse ? "#343434" : "#2a2a2a"
                                            Behavior on color { ColorAnimation { duration: 110 } }
                                            border.color: "#1fffffff"
                                            border.width: 1

                                            Row {
                                                id: pinExpRow
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: shellRoot.startPinnedExpanded ? "Mostrar menos" : "Mostrar todo"
                                                    color: "#e6e6e6"
                                                    font.pixelSize: 11
                                                }
                                                WinSvg {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 11; height: 11
                                                    iconFile: shellRoot.startPinnedExpanded ? "fluent-chevron-up.svg" : "fluent-chevron-right.svg"
                                                    opacity: 0.85
                                                }
                                            }

                                            MouseArea {
                                                id: pinExpHov
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                                onClicked: shellRoot.startPinnedExpanded = !shellRoot.startPinnedExpanded
                                            }
                                        }
                                    }

                                    // Pinned Apps Grid (2 clean rows by default, 3 rows when expanded)
                                    Grid {
                                        width: 592
                                        columns: 6
                                        rowSpacing: 8
                                        columnSpacing: 8

                                        Repeater {
                                            model: shellRoot.startPinnedExpanded ? shellRoot.startPinned : shellRoot.startPinned.slice(0, 12)

                                            delegate: Rectangle {
                                                width: 92
                                                height: 80
                                                radius: 6
                                                color: appHov.containsMouse ? "#1affffff" : "transparent"
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                Column {
                                                    anchors.centerIn: parent
                                                    spacing: 7
                                                    WinSvg {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: 32; height: 32
                                                        iconUrl: modelData.iconUrl || ""
                                                        scale: appHov.pressed ? 0.88 : 1.0
                                                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                                                    }
                                                    Text {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: 84
                                                        horizontalAlignment: Text.AlignHCenter
                                                        text: modelData.name
                                                        color: "#f2f2f2"
                                                        font.pixelSize: 11
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                MouseArea {
                                                    id: appHov
                                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                    onClicked: (mouse) => {
                                                        if (mouse.button === Qt.RightButton) {
                                                            var gp = appHov.mapToItem(startMainSurface, mouse.x, mouse.y);
                                                            shellRoot.startAppCtxData = modelData;
                                                            shellRoot.startAppCtxX = Math.max(16, Math.min(startMainSurface.width - 258, gp.x));
                                                            shellRoot.startAppCtxY = Math.max(16, Math.min(startMainSurface.height - 230, gp.y));
                                                            shellRoot.startAppCtxOpen = true;
                                                            return;
                                                        }
                                                        shellRoot.startAppCtxOpen = false;
                                                        shellRoot.startOpen = false;
                                                        shellRoot.spawnCmd(modelData.cmd);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // [SECTION 1.5] RECOMENDADO — Authentic Windows 11 26H2 Recent Files Grid (controlled by showRecommended!)
                                Column {
                                    visible: shellRoot.showRecommended && shellRoot.searchQuery.trim() === ""
                                    width: 592
                                    spacing: 10

                                    RowLayout {
                                        width: 592
                                        Text {
                                            text: "Recomendado"
                                            color: "#ffffff"
                                            font.pixelSize: 14
                                            font.weight: Font.DemiBold
                                        }
                                        Item { Layout.fillWidth: true }
                                        Rectangle {
                                            width: recMoreRow.implicitWidth + 18; height: 26; radius: 5
                                            color: recMoreHov.containsMouse ? "#323232" : "#282828"
                                            border.color: "#1effffff"; border.width: 1
                                            Row {
                                                id: recMoreRow; anchors.centerIn: parent; spacing: 5
                                                Text { text: "Más"; color: "#e8e8e8"; font.pixelSize: 11 }
                                                WinSvg { width: 10; height: 10; iconFile: "fluent-chevron-right.svg"; anchors.verticalCenter: parent.verticalCenter; opacity: 0.85 }
                                            }
                                            MouseArea {
                                                id: recMoreHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                                onClicked: {
                                                    shellRoot.startOpen = false;
                                                    shellRoot.spawnCmd("/usr/bin/x64-win11-app explorer 'Descargas'");
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        visible: (shellRoot.startRecentFiles || []).length === 0
                                        text: "Tus archivos recientes aparecerán aquí automáticamente."
                                        color: "#9a9a9a"; font.pixelSize: 12
                                    }

                                    Grid {
                                        visible: (shellRoot.startRecentFiles || []).length > 0
                                        width: 592
                                        columns: 2
                                        columnSpacing: 12
                                        rowSpacing: 8

                                        Repeater {
                                            model: (shellRoot.startRecentFiles || []).slice(0, 6)
                                            delegate: Rectangle {
                                                width: 290; height: 50; radius: 6
                                                color: recItemHov.containsMouse ? "#1affffff" : "#10ffffff"
                                                border.color: recItemHov.containsMouse ? "#24ffffff" : "transparent"; border.width: 1
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                RowLayout {
                                                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                                    WinSvg { width: 22; height: 22; iconFile: modelData.icon || "fluent-document.svg" }
                                                    ColumnLayout {
                                                        Layout.fillWidth: true; spacing: 1
                                                        Text { text: modelData.name || ""; color: "#f2f2f2"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                                        Text { text: (modelData.age || "") + (modelData.folder ? ("  •  " + modelData.folder) : ""); color: "#9e9e9e"; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                                    }
                                                }

                                                MouseArea {
                                                    id: recItemHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        shellRoot.startOpen = false;
                                                        var p = String(modelData.path || "").replace(/'/g, "'\\''");
                                                        if (p !== "") shellRoot.spawnCmd("xdg-open '" + p + "'");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // [SECTION 2] TODAS — Authentic 26H2 Header + WinUI 3 View Dropdown ("Vista: Categoría ∨")
                                RowLayout {
                                    width: 592
                                    Text {
                                        text: shellRoot.searchQuery.trim() !== "" ? "Resultados de búsqueda" : "Todas"
                                        color: "#ffffff"
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                    }
                                    Item { Layout.fillWidth: true }

                                    // Single Authentic WinUI 3 Dropdown Button ("Vista: Categoría ∨")
                                    Rectangle {
                                        id: viewDropBtn
                                        visible: shellRoot.searchQuery.trim() === ""
                                        width: viewDropRow.implicitWidth + 20
                                        height: 28
                                        radius: 5
                                        color: (shellRoot.startViewDropdownOpen || viewDropHov.containsMouse) ? "#343434" : "#2a2a2a"
                                        Behavior on color { ColorAnimation { duration: 110 } }
                                        border.color: "#22ffffff"
                                        border.width: 1

                                        Row {
                                            id: viewDropRow
                                            anchors.centerIn: parent
                                            spacing: 7
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Vista: " + (shellRoot.startAllViewMode === "categories"
                                                                   ? "Categoría"
                                                                   : (shellRoot.startAllViewMode === "grid" ? "Cuadrícula" : "Lista"))
                                                color: "#ececec"
                                                font.pixelSize: 11
                                            }
                                            WinSvg {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 11; height: 11
                                                iconFile: "fluent-chevron-down.svg"
                                                opacity: 0.85
                                            }
                                        }

                                        MouseArea {
                                            id: viewDropHov
                                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                            onClicked: shellRoot.startViewDropdownOpen = !shellRoot.startViewDropdownOpen
                                        }
                                    }
                                }

                                // VIEW 1: CATEGORÍA — Authentic Windows 11 26H2 2x2 Visual App Folders (4 per row!)
                                Grid {
                                    width: 592
                                    columns: 4
                                    rowSpacing: 16
                                    columnSpacing: 16
                                    visible: shellRoot.startAllViewMode === "categories" && shellRoot.searchQuery.trim() === ""

                                    Repeater {
                                        model: shellRoot.startCategories

                                        delegate: Column {
                                            width: 136
                                            spacing: 7

                                            // Rounded Frosted Category Folder Box containing 2x2 App Icons
                                            Rectangle {
                                                width: 136
                                                height: 136
                                                radius: 12
                                                color: catBoxHov.containsMouse ? "#303030" : "#272727"
                                                Behavior on color { ColorAnimation { duration: 110 } }
                                                border.color: "#22ffffff"
                                                border.width: 1

                                                // Click background of folder to open full category popover
                                                MouseArea {
                                                    id: catBoxHov
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.ArrowCursor
                                                    onClicked: shellRoot.expandedCategoryObj = modelData
                                                }

                                                Grid {
                                                    anchors.centerIn: parent
                                                    columns: 2
                                                    rowSpacing: 14
                                                    columnSpacing: 14

                                                    Repeater {
                                                        model: modelData.preview || (modelData.items ? modelData.items.slice(0, 4) : [])

                                                        delegate: Rectangle {
                                                            width: 46; height: 46; radius: 8
                                                            color: subAppHov.containsMouse ? "#22ffffff" : "transparent"

                                                            WinSvg {
                                                                anchors.centerIn: parent
                                                                width: 34; height: 34
                                                                iconUrl: modelData.iconUrl || ""
                                                                scale: subAppHov.pressed ? 0.86 : 1.0
                                                                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                                                            }

                                                            MouseArea {
                                                                id: subAppHov
                                                                anchors.fill: parent
                                                                hoverEnabled: true
                                                                cursorShape: Qt.ArrowCursor
                                                                onClicked: {
                                                                    // If 4th slot and folder has >4 apps, open folder; otherwise launch app directly!
                                                                    shellRoot.startOpen = false;
                                                                    shellRoot.spawnCmd(modelData.cmd);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            // Category Title Below Folder (Authentic 26H2 Style — Never clips app names!)
                                            Text {
                                                width: 136
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.cat
                                                color: "#e6e6e6"
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.ArrowCursor
                                                    onClicked: shellRoot.expandedCategoryObj = modelData
                                                }
                                            }
                                        }
                                    }
                                }

                                // VIEW 2: CUADRÍCULA (Alphabetical Wide Icon Grid)
                                Grid {
                                    width: 592
                                    columns: 6
                                    rowSpacing: 10
                                    columnSpacing: 8
                                    visible: shellRoot.startAllViewMode === "grid" || shellRoot.searchQuery.trim() !== ""

                                    Repeater {
                                        model: shellRoot.allApps
                                        delegate: Rectangle {
                                            visible: shellRoot.searchQuery.trim() === "" || modelData.name.toLowerCase().indexOf(shellRoot.searchQuery.trim().toLowerCase()) !== -1
                                            width: 92
                                            height: 78
                                            radius: 6
                                            color: allGridHov.containsMouse ? "#1affffff" : "transparent"

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 32; height: 32; iconUrl: modelData.iconUrl || "" }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 84; horizontalAlignment: Text.AlignHCenter
                                                    text: modelData.name; color: "#f2f2f2"; font.pixelSize: 11; elide: Text.ElideRight
                                                }
                                            }
                                            MouseArea {
                                                id: allGridHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: (mouse) => {
                                                    if (mouse.button === Qt.RightButton) {
                                                        var gp = allGridHov.mapToItem(startMainSurface, mouse.x, mouse.y);
                                                        shellRoot.startAppCtxData = modelData;
                                                        shellRoot.startAppCtxX = Math.max(16, Math.min(startMainSurface.width - 258, gp.x));
                                                        shellRoot.startAppCtxY = Math.max(16, Math.min(startMainSurface.height - 230, gp.y));
                                                        shellRoot.startAppCtxOpen = true;
                                                        return;
                                                    }
                                                    shellRoot.startAppCtxOpen = false;
                                                    shellRoot.startOpen = false;
                                                    shellRoot.spawnCmd(modelData.cmd);
                                                }
                                            }
                                        }
                                    }
                                }

                                // VIEW 3: LISTA (Authentic Windows 11 A-Z Grouped List with Letter Headers)
                                Column {
                                    width: 592
                                    spacing: 2
                                    visible: shellRoot.startAllViewMode === "list" && shellRoot.searchQuery.trim() === ""

                                    Repeater {
                                        model: shellRoot.allApps
                                        delegate: Column {
                                            width: 592
                                            spacing: 2
                                            readonly property string curLetter: (modelData.name && modelData.name.length > 0) ? modelData.name.charAt(0).toUpperCase() : "#"
                                            readonly property string prevLetter: (index > 0 && shellRoot.allApps[index - 1].name && shellRoot.allApps[index - 1].name.length > 0)
                                                                                 ? shellRoot.allApps[index - 1].name.charAt(0).toUpperCase()
                                                                                 : ""

                                            Item {
                                                visible: curLetter !== prevLetter
                                                width: 592; height: 28
                                                Text {
                                                    x: 12; anchors.verticalCenter: parent.verticalCenter
                                                    text: curLetter
                                                    color: "#cfcfcf"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                }
                                            }

                                            Rectangle {
                                                width: 592; height: 38; radius: 6
                                                color: allListHov.containsMouse ? "#1affffff" : "transparent"
                                                RowLayout {
                                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 14
                                                    WinSvg { width: 24; height: 24; iconUrl: modelData.iconUrl || "" }
                                                    Text { text: modelData.name; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                                }
                                                MouseArea {
                                                    id: allListHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                    onClicked: (mouse) => {
                                                        if (mouse.button === Qt.RightButton) {
                                                            var gp = allListHov.mapToItem(startMainSurface, mouse.x, mouse.y);
                                                            shellRoot.startAppCtxData = modelData;
                                                            shellRoot.startAppCtxX = Math.max(16, Math.min(startMainSurface.width - 258, gp.x));
                                                            shellRoot.startAppCtxY = Math.max(16, Math.min(startMainSurface.height - 230, gp.y));
                                                            shellRoot.startAppCtxOpen = true;
                                                            return;
                                                        }
                                                        shellRoot.startAppCtxOpen = false;
                                                        shellRoot.startOpen = false;
                                                        shellRoot.spawnCmd(modelData.cmd);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3. Authentic Windows 11 26H2 Bottom Account & Power Strip (Clean Circular Avatar + Username ONLY)
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62

                            // Subtle bottom chamber background respecting 12px outer bottom corners
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 11
                                color: "#181818"
                                Rectangle {
                                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                    height: 11; color: "#181818"
                                }
                                Rectangle {
                                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                    height: 1; color: "#1cffffff"
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 32
                                anchors.rightMargin: 28

                                // User Profile Pill (Circular Avatar + Username ONLY — Exact Win11 26H2)
                                Rectangle {
                                    width: usrRow.implicitWidth + 18
                                    height: 40
                                    radius: 6
                                    color: usrBtnHov.containsMouse ? "#1affffff" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 110 } }

                                    Row {
                                        id: usrRow
                                        anchors.centerIn: parent
                                        spacing: 12

                                        Rectangle {
                                            width: 32; height: 32; radius: 16
                                            color: "#2e2e2e"
                                            border.color: "#28ffffff"
                                            border.width: 1
                                            Image {
                                                visible: shellRoot.userAvatarUrl !== ""
                                                anchors.fill: parent
                                                source: shellRoot.userAvatarUrl
                                                sourceSize.width: 64; sourceSize.height: 64
                                                fillMode: Image.PreserveAspectFit
                                                mipmap: true; smooth: true; cache: false
                                            }
                                            WinSvg {
                                                visible: shellRoot.userAvatarUrl === ""
                                                anchors.centerIn: parent
                                                width: 18; height: 18
                                                iconFile: "fluent-person.svg"
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: shellRoot.userName
                                            color: "#f2f2f2"
                                            font.pixelSize: 12
                                        }
                                    }

                                    MouseArea {
                                        id: usrBtnHov
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            shellRoot.closeAllPopups();
                                            shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Cuentas'");
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Power Button
                                Rectangle {
                                    width: 40; height: 40; radius: 6
                                    color: (shellRoot.powerPopupOpen || pwrHov.containsMouse) ? "#20ffffff" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    WinSvg { anchors.centerIn: parent; width: 18; height: 18; iconFile: "fluent-power.svg" }
                                    MouseArea {
                                        id: pwrHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            shellRoot.startViewDropdownOpen = false;
                                            shellRoot.powerPopupOpen = !shellRoot.powerPopupOpen;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Floating WinUI 3 "Vista: Categoría / Cuadrícula / Lista" Dropdown Menu
                    Rectangle {
                        visible: shellRoot.startViewDropdownOpen
                        anchors.right: parent.right
                        anchors.rightMargin: 32
                        y: shellRoot.startViewDropdownOpen
                           ? Math.max(80, Math.min(startMainSurface.height - height - 68, viewDropBtn.mapToItem(startMainSurface, 0, viewDropBtn.height + 4).y))
                           : 300
                        width: 156
                        height: 112
                        radius: 8
                        color: shellRoot.menuBg
                        border.color: "#34ffffff"
                        border.width: 1
                        z: 30

                        Column {
                            anchors.fill: parent; anchors.margins: 5; spacing: 2
                            Repeater {
                                model: [
                                    { id: "categories", label: "Categoría",  icon: "fluent-grid.svg" },
                                    { id: "grid",       label: "Cuadrícula", icon: "fluent-folder-grid.svg" },
                                    { id: "list",       label: "Lista",      icon: "fluent-apps-list.svg" }
                                ]
                                delegate: Rectangle {
                                    width: 146; height: 32; radius: 5
                                    readonly property bool isSel: shellRoot.startAllViewMode === modelData.id
                                    color: isSel ? "#22ffffff" : (vdItemHov.containsMouse ? "#1affffff" : "transparent")

                                    // WinUI 3 Left Selection Pill
                                    Rectangle {
                                        visible: parent.isSel
                                        x: 2; anchors.verticalCenter: parent.verticalCenter
                                        width: 3; height: 16; radius: 1.5
                                        color: shellRoot.accentColor
                                    }

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 10
                                        WinSvg { width: 15; height: 15; iconFile: modelData.icon; opacity: 0.9 }
                                        Text { text: modelData.label; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true }
                                    }

                                    MouseArea {
                                        id: vdItemHov
                                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            shellRoot.startAllViewMode = modelData.id;
                                            shellRoot.saveConfigKey("startAllViewMode", JSON.stringify(modelData.id));
                                            shellRoot.startViewDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Start Menu App Right-Click Context Menu ("Desanclar de Inicio | Anclar a barra | Ejecutar como admin | Desinstalar")
                    MouseArea {
                        visible: shellRoot.startAppCtxOpen
                        anchors.fill: parent
                        z: 34
                        onClicked: shellRoot.startAppCtxOpen = false
                    }

                    Rectangle {
                        id: startAppCtxCard
                        visible: shellRoot.startAppCtxOpen && shellRoot.startAppCtxData !== null
                        x: shellRoot.startAppCtxX
                        y: shellRoot.startAppCtxY
                        width: 246
                        height: stAppCtxCol.implicitHeight + 10
                        radius: 8
                        color: shellRoot.menuBg
                        border.color: "#36ffffff"
                        border.width: 1
                        z: 35
                        MouseArea { anchors.fill: parent }

                        readonly property bool isPinnedSt: shellRoot.startAppCtxData ? shellRoot.isCmdPinnedStart(shellRoot.startAppCtxData.cmd) : false
                        readonly property bool isPinnedTb: shellRoot.startAppCtxData ? shellRoot.isCmdPinnedTaskbar(shellRoot.startAppCtxData.cmd) : false

                        Column {
                            id: stAppCtxCol
                            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                            anchors.margins: 5; spacing: 2

                            Repeater {
                                model: [
                                    { act: "open",      label: "Abrir", iconUrl: shellRoot.startAppCtxData ? shellRoot.startAppCtxData.iconUrl : "", bold: true },
                                    { act: "admin",     label: "Ejecutar como administrador", icon: "fluent-shield.svg" },
                                    { sep: true },
                                    { act: "pin_start", label: startAppCtxCard.isPinnedSt ? "Desanclar de Inicio" : "Anclar a Inicio", icon: startAppCtxCard.isPinnedSt ? "fluent-pin-off.svg" : "fluent-pin.svg" },
                                    { act: "pin_tb",    label: startAppCtxCard.isPinnedTb ? "Desanclar de la barra de tareas" : "Anclar a la barra de tareas", icon: startAppCtxCard.isPinnedTb ? "fluent-pin-off.svg" : "fluent-pin.svg" },
                                    { sep: true },
                                    { act: "uninstall", label: "Desinstalar", icon: "fluent-delete.svg" }
                                ]
                                delegate: Item {
                                    width: 236; height: modelData.sep ? 9 : 31
                                    Rectangle { visible: Boolean(modelData.sep); anchors.verticalCenter: parent.verticalCenter; x: 6; width: 224; height: 1; color: "#1effffff" }
                                    Rectangle {
                                        visible: !modelData.sep
                                        anchors.fill: parent; radius: 5
                                        color: stCtxRowHov.containsMouse ? "#24ffffff" : "transparent"
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                            WinSvg { width: 16; height: 16; iconUrl: modelData.iconUrl || ""; iconFile: modelData.icon || "windows.svg" }
                                            Text {
                                                text: modelData.label || ""
                                                color: "#f2f2f2"; font.pixelSize: 12
                                                font.weight: modelData.bold ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight; Layout.fillWidth: true
                                            }
                                        }
                                        MouseArea {
                                            id: stCtxRowHov; anchors.fill: parent; hoverEnabled: true
                                            onClicked: shellRoot.execStartAppAction(modelData.act)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Expanded Category Folder Overlay Modal (When clicking a 26H2 Category Folder)
                    Rectangle {
                        visible: shellRoot.expandedCategoryObj !== null
                        anchors.fill: parent
                        radius: 12
                        color: "#e61a1a1a"
                        z: 40

                        MouseArea {
                            anchors.fill: parent
                            onClicked: shellRoot.expandedCategoryObj = null
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 480
                            height: 360
                            radius: 12
                            color: "#272727"
                            border.color: "#32ffffff"
                            border.width: 1
                            MouseArea { anchors.fill: parent }

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 22; spacing: 16
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: shellRoot.expandedCategoryObj ? shellRoot.expandedCategoryObj.cat : ""
                                        color: "#ffffff"; font.pixelSize: 16; font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                    }
                                    Rectangle {
                                        width: 28; height: 28; radius: 6
                                        color: expCloseHov.containsMouse ? "#28ffffff" : "transparent"
                                        WinSvg { anchors.centerIn: parent; width: 12; height: 12; iconFile: "fluent-dismiss.svg" }
                                        MouseArea {
                                            id: expCloseHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                            onClicked: shellRoot.expandedCategoryObj = null
                                        }
                                    }
                                }

                                Flickable {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    contentWidth: width; contentHeight: expGrid.implicitHeight; clip: true
                                    Grid {
                                        id: expGrid
                                        width: parent.width; columns: 4; rowSpacing: 12; columnSpacing: 12
                                        Repeater {
                                            model: (shellRoot.expandedCategoryObj && shellRoot.expandedCategoryObj.items) ? shellRoot.expandedCategoryObj.items : []
                                            delegate: Rectangle {
                                                width: 100; height: 82; radius: 8
                                                color: expAppHov.containsMouse ? "#20ffffff" : "transparent"
                                                Column {
                                                    anchors.centerIn: parent; spacing: 6
                                                    WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 34; height: 34; iconUrl: modelData.iconUrl || "" }
                                                    Text {
                                                        width: 90; horizontalAlignment: Text.AlignHCenter
                                                        text: modelData.name; color: "#f2f2f2"; font.pixelSize: 11; elide: Text.ElideRight
                                                    }
                                                }
                                                MouseArea {
                                                    id: expAppHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                                    onClicked: {
                                                        var cmd = modelData.cmd;
                                                        shellRoot.expandedCategoryObj = null;
                                                        shellRoot.startOpen = false;
                                                        shellRoot.spawnCmd(cmd);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Power Menu Popup
                    Rectangle {
                        visible: shellRoot.powerPopupOpen
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.rightMargin: 24; anchors.bottomMargin: 58
                        width: 210; height: 170; radius: 8; color: shellRoot.menuBg; border.color: "#34ffffff"
                        z: 45

                        Column {
                            anchors.fill: parent; anchors.margins: 6; spacing: 2
                            Repeater {
                                model: [
                                    { label: "Bloquear (Win + L)",     icon: "fluent-lock.svg",     act: "lock" },
                                    { label: "Cambiar Escritorio X64", icon: "fluent-settings.svg", act: "dashboard" },
                                    { label: "Cerrar sesión",          icon: "fluent-signout.svg",  act: "logout" },
                                    { label: "Reiniciar",              icon: "fluent-refresh.svg",  act: "reboot" },
                                    { label: "Apagar",                 icon: "fluent-power.svg",    act: "poweroff" }
                                ]
                                delegate: Rectangle {
                                    width: 198; height: 30; radius: 5
                                    color: pSubHov.containsMouse ? "#28ffffff" : "transparent"
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                        WinSvg { width: 15; height: 15; iconFile: modelData.icon }
                                        Text { text: modelData.label; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                                    }
                                    MouseArea {
                                        id: pSubHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                                        onClicked: {
                                            shellRoot.closeAllPopups();
                                            if (modelData.act === "lock") { shellRoot.lockPromptOpen = false; shellRoot.lockScreenOpen = true; }
                                            else if (modelData.act === "dashboard") shellRoot.spawnCmd("kitty -e x64-dashboard");
                                            else if (modelData.act === "logout") shellRoot.spawnCmd("labwc -e");
                                            else if (modelData.act === "reboot") shellRoot.spawnCmd("systemctl reboot");
                                            else if (modelData.act === "poweroff") shellRoot.spawnCmd("systemctl poweroff");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // [B] Authentic Windows 11 26H2 Phone Link ("Enlace Móvil") Live Companion Panel (250x700)
                Rectangle {
                    id: phoneCompanionCard
                    visible: shellRoot.showPhoneLink
                    width: 250
                    height: 700
                    radius: 12
                    color: shellRoot.panelBg
                    border.color: "#2cffffff"
                    border.width: 1
                    MouseArea { anchors.fill: parent }

                    readonly property var phData: shellRoot.phoneLinkData || ({})
                    readonly property var kdeList: phData.kdeDevices || []
                    readonly property var adbList: phData.adbDevices || []
                    readonly property var activeKde: {
                        for (var i = 0; i < kdeList.length; i++) if (kdeList[i].paired && kdeList[i].reachable) return kdeList[i];
                        for (var j = 0; j < kdeList.length; j++) if (kdeList[j].paired) return kdeList[j];
                        return null;
                    }
                    readonly property var activeAdb: {
                        for (var i = 0; i < adbList.length; i++) if (adbList[i].authorized) return adbList[i];
                        return adbList.length > 0 ? adbList[0] : null;
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 12

                        // Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            WinSvg { width: 18; height: 18; iconFile: "fluent-phone.svg" }
                            Text {
                                text: "Enlace Móvil"
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                width: 26; height: 26; radius: 5
                                color: phSetHov.containsMouse ? "#24ffffff" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 13; height: 13; iconFile: "fluent-settings.svg"; opacity: 0.85 }
                                MouseArea {
                                    id: phSetHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        shellRoot.closeAllPopups();
                                        shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Bluetooth y dispositivos:Dispositivos móviles'");
                                    }
                                }
                            }
                            Rectangle {
                                width: 26; height: 26; radius: 5
                                color: phCloseHov.containsMouse ? "#24ffffff" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 11; height: 11; iconFile: "fluent-dismiss.svg"; opacity: 0.8 }
                                MouseArea {
                                    id: phCloseHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        shellRoot.showPhoneLink = false;
                                        shellRoot.saveConfigKey("showPhoneLink", "false");
                                    }
                                }
                            }
                        }

                        // Phone Live Status + 4 Real Quick Actions (Acoplar, Flotante, Sonar, Ajustes)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: phStatInner.implicitHeight + 24
                            radius: 8
                            color: "#282828"
                            border.color: (phoneCompanionCard.activeAdb || (phoneCompanionCard.activeKde && phoneCompanionCard.activeKde.reachable)) ? Qt.alpha(shellRoot.accentColor, 0.27) : "#1fffffff"
                            border.width: 1

                            Column {
                                id: phStatInner
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                anchors.margins: 12
                                spacing: 12

                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    Rectangle {
                                        width: 36; height: 36; radius: 8
                                        color: (phoneCompanionCard.activeAdb || (phoneCompanionCard.activeKde && phoneCompanionCard.activeKde.reachable)) ? Qt.alpha(shellRoot.accentColor, 0.15) : "#333333"
                                        WinSvg { anchors.centerIn: parent; width: 20; height: 20; iconFile: "fluent-phone.svg" }
                                    }
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            width: parent.width; elide: Text.ElideRight
                                            text: phoneCompanionCard.activeAdb ? phoneCompanionCard.activeAdb.model
                                                  : (phoneCompanionCard.activeKde ? phoneCompanionCard.activeKde.name : "Sin teléfono activo")
                                            color: "#ffffff"; font.pixelSize: 12; font.weight: Font.DemiBold
                                        }
                                        Text {
                                            width: parent.width; elide: Text.ElideRight
                                            text: {
                                                if (shellRoot.phoneMirrorActive) {
                                                    var ab = phoneCompanionCard.activeAdb && Number(phoneCompanionCard.activeAdb.battery) >= 0
                                                        ? (" • " + phoneCompanionCard.activeAdb.battery + "%") : "";
                                                    return "Pantalla activa" + ab;
                                                }
                                                if (phoneCompanionCard.activeAdb) {
                                                    var adbBat = Number(phoneCompanionCard.activeAdb.battery);
                                                    var batS = adbBat >= 0 ? (" • " + adbBat + "%" + (phoneCompanionCard.activeAdb.charging ? " (cargando)" : "")) : "";
                                                    return phoneCompanionCard.activeAdb.authorized
                                                        ? ((phoneCompanionCard.activeAdb.isWifi ? "Wi-Fi" : "USB") + batS)
                                                        : "Acepta depuración en el móvil";
                                                }
                                                if (phoneCompanionCard.activeKde) {
                                                    var b = Number(phoneCompanionCard.activeKde.battery);
                                                    return (phoneCompanionCard.activeKde.reachable ? "Conectado" : "Fuera de alcance")
                                                        + (b >= 0 ? (" • " + b + "%") : "");
                                                }
                                                return "KDE Connect + scrcpy listos";
                                            }
                                            color: (shellRoot.phoneMirrorActive || phoneCompanionCard.activeAdb || (phoneCompanionCard.activeKde && phoneCompanionCard.activeKde.reachable)) ? shellRoot.accentColor : "#a8a8a8"
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                // 4 Distinct Real Quick Actions Row (Pantalla, Enviar, Sonar, Ajustes)
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: [
                                            { icon: "fluent-display.svg",  lbl: "Pantalla", act: "screen" },
                                            { icon: "fluent-send.svg",     lbl: "Enviar",   act: "send" },
                                            { icon: "fluent-bell.svg",     lbl: "Sonar",    act: "ring" },
                                            { icon: "fluent-settings.svg", lbl: "Ajustes",  act: "settings" }
                                        ]
                                        delegate: Rectangle {
                                            width: 44; height: 46; radius: 6
                                            color: phActHov.containsMouse ? "#3e3e3e" : "#323232"
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            border.color: "#1affffff"
                                            Column {
                                                anchors.centerIn: parent; spacing: 3
                                                WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 16; height: 16; iconFile: modelData.icon }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.lbl; color: "#d4d4d4"; font.pixelSize: 9 }
                                            }
                                            MouseArea {
                                                id: phActHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    shellRoot.closeAllPopups();
                                                    if (modelData.act === "screen") {
                                                        shellRoot.spawnCmd(shellRoot.phoneMirrorActive ? "/usr/bin/x64-win11-ctl phone stop" : "/usr/bin/x64-win11-ctl phone mirror");
                                                    } else if (modelData.act === "ring") {
                                                        shellRoot.spawnCmd("/usr/bin/x64-win11-ctl phone ring");
                                                    } else if (modelData.act === "send") {
                                                        if (phoneCompanionCard.activeKde && phoneCompanionCard.activeKde.id) {
                                                            shellRoot.spawnCmd("kdeconnect-app");
                                                        } else if (phoneCompanionCard.activeAdb && phoneCompanionCard.activeAdb.authorized) {
                                                            shellRoot.spawnCmd("/usr/bin/x64-win11-ctl phone send-file '" + phoneCompanionCard.activeAdb.serial + "'");
                                                        } else {
                                                            shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Bluetooth y dispositivos:Dispositivos móviles'");
                                                        }
                                                    } else {
                                                        shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Bluetooth y dispositivos:Dispositivos móviles'");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Live Screen Mirroring & Continuity Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: "#262626"
                            border.color: "#1cffffff"
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10

                                Text {
                                    text: "Tu teléfono en el escritorio"
                                    color: "#ffffff"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: phoneCompanionCard.activeAdb
                                          ? "Tu Android está detectado. Abre su pantalla flotante para controlarlo libremente en cualquiera de tus monitores."
                                          : "Conecta tu Android por USB (Depuración USB) o Wi-Fi para ver y controlar su pantalla con ratón y teclado."
                                    color: "#b8b8b8"
                                    font.pixelSize: 11
                                    lineHeight: 1.25
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Column {
                                    spacing: 7
                                    Layout.fillWidth: true
                                    Repeater {
                                        model: [
                                            "Control táctil 60/120 FPS + audio",
                                            "Ventana flotante libre y fijable",
                                            "Notificaciones y archivos (KDE Connect)"
                                        ]
                                        delegate: Row {
                                            spacing: 8
                                            WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; iconFile: "fluent-checkmark.svg"; opacity: 0.85 }
                                            Text { text: modelData; color: "#d8d8d8"; font.pixelSize: 10; width: 164; wrapMode: Text.WordWrap }
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }

                                // Single Clean Primary Action: Ver / Cerrar pantalla del móvil
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36; radius: 5
                                    color: phMirBtnH.containsMouse ? Qt.lighter(shellRoot.accentColor, 1.12) : shellRoot.accentColor
                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: shellRoot.phoneMirrorActive ? "Cerrar pantalla del móvil" : "Ver pantalla del móvil"
                                        color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold
                                    }
                                    MouseArea {
                                        id: phMirBtnH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.closeAllPopups();
                                            shellRoot.spawnCmd(shellRoot.phoneMirrorActive ? "/usr/bin/x64-win11-ctl phone stop" : "/usr/bin/x64-win11-ctl phone mirror");
                                        }
                                    }
                                }

                                // Secondary Action: Configurar Wi-Fi y KDE Connect
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 32; radius: 5
                                    color: phCfgBtnH.containsMouse ? "#3a3a3a" : "#303030"
                                    border.color: "#22ffffff"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Configurar Wi-Fi y vinculación"
                                        color: "#f0f0f0"; font.pixelSize: 11; font.weight: Font.Medium
                                    }
                                    MouseArea {
                                        id: phCfgBtnH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.closeAllPopups();
                                            shellRoot.spawnCmd("/usr/bin/x64-win11-app settings 'Bluetooth y dispositivos:Dispositivos móviles'");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3B. WINDOWS 11 DEDICATED SEARCH FLYOUT (Taskbar "Escribe para buscar")
        Rectangle {
            id: searchFlyoutCard
            visible: shellRoot.searchOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: shellRoot.searchOpen ? 0 : 12
                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            width: 620
            height: 560
            x: shellRoot.taskbarLeftAlign ? 12 : ((overlayWin.width - width) / 2)
            y: overlayWin.height - height - (shellRoot.taskbarCompact ? 38 : 48) - 12
            radius: 12
            color: "#f5202020"
            border.color: "#30ffffff"
            border.width: 1
            MouseArea { anchors.fill: parent }

            onVisibleChanged: {
                if (visible) {
                    searchFlyoutInput.text = "";
                    shellRoot.searchQuery = "";
                    searchFlyoutInput.forceActiveFocus();
                }
            }

            readonly property var filteredSearchApps: {
                var q = shellRoot.searchQuery.trim().toLowerCase();
                var list = shellRoot.allApps || [];
                if (q === "") return list.slice(0, 12);
                var out = [];
                for (var i = 0; i < list.length; i++) {
                    if (list[i].name.toLowerCase().indexOf(q) !== -1 || (list[i].id && list[i].id.toLowerCase().indexOf(q) !== -1)) {
                        out.push(list[i]);
                    }
                }
                return out;
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 16

                // Top Live Search Input Box (Auto-focused on open!)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: 21
                    color: "#151515"
                    border.color: "#60cdff"
                    border.width: 2

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 10

                        WinSvg { width: 18; height: 18; iconFile: "fluent-search.svg" }

                        TextInput {
                            id: searchFlyoutInput
                            Layout.fillWidth: true
                            color: "#ffffff"
                            font.pixelSize: 14
                            focus: true
                            selectByMouse: true
                            onTextChanged: shellRoot.searchQuery = text
                            Keys.onEscapePressed: shellRoot.closeAllPopups()
                            onAccepted: {
                                var matches = searchFlyoutCard.filteredSearchApps;
                                if (matches.length > 0) {
                                    shellRoot.closeAllPopups();
                                    shellRoot.spawnCmd(matches[0].cmd);
                                } else if (text.trim() !== "") {
                                    var qUrl = "https://www.google.com/search?q=" + encodeURIComponent(text.trim());
                                    shellRoot.closeAllPopups();
                                    shellRoot.spawnCmd("xdg-open '" + qUrl + "'");
                                }
                            }

                            Text {
                                visible: searchFlyoutInput.text === ""
                                text: "Escribe aquí para buscar aplicaciones, configuración o en la Web..."
                                color: "#9e9e9e"
                                font.pixelSize: 13
                            }
                        }

                        Rectangle {
                            visible: searchFlyoutInput.text !== ""
                            width: 22; height: 22; radius: 11
                            color: clrSearchHov.containsMouse ? "#33ffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 12; height: 12; iconFile: "fluent-dismiss.svg" }
                            MouseArea {
                                id: clrSearchHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchFlyoutInput.text = "";
                                    searchFlyoutInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Search Results Area
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: searchResCol.implicitHeight + 16
                    clip: true

                    Column {
                        id: searchResCol
                        width: parent.width
                        spacing: 14

                        // [A] Best Match Card (when typing)
                        Column {
                            visible: shellRoot.searchQuery.trim() !== "" && searchFlyoutCard.filteredSearchApps.length > 0
                            width: parent.width
                            spacing: 6

                            Text { text: "Mejor coincidencia (pulsa Enter para abrir)"; color: "#60cdff"; font.pixelSize: 12; font.bold: true }

                            Rectangle {
                                width: parent.width
                                height: 58
                                radius: 8
                                color: bestMatchHov.containsMouse ? "#0078d4" : "#2c2c2c"
                                border.color: "#60cdff"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 14

                                    WinSvg {
                                        width: 34; height: 34
                                        iconUrl: searchFlyoutCard.filteredSearchApps.length > 0 ? (searchFlyoutCard.filteredSearchApps[0].iconUrl || "") : ""
                                    }
                                    Column {
                                        Layout.fillWidth: true
                                        Text {
                                            text: searchFlyoutCard.filteredSearchApps.length > 0 ? searchFlyoutCard.filteredSearchApps[0].name : ""
                                            color: "#ffffff"; font.pixelSize: 14; font.bold: true
                                        }
                                        Text { text: "Aplicación del sistema • Pulsa Enter para abrir"; color: "#d0d0d0"; font.pixelSize: 11 }
                                    }
                                    Rectangle {
                                        width: 72; height: 28; radius: 5; color: "#0078d4"
                                        Text { anchors.centerIn: parent; text: "Abrir ↵"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                                    }
                                }

                                MouseArea {
                                    id: bestMatchHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (searchFlyoutCard.filteredSearchApps.length > 0) {
                                            var cmd = searchFlyoutCard.filteredSearchApps[0].cmd;
                                            shellRoot.closeAllPopups();
                                            shellRoot.spawnCmd(cmd);
                                        }
                                    }
                                }
                            }
                        }

                        // [B] Matching Installed Applications List / Top Apps
                        Column {
                            width: parent.width
                            spacing: 6

                            Text {
                                text: shellRoot.searchQuery.trim() === ""
                                      ? "Principales aplicaciones instaladas"
                                      : ("Aplicaciones encontradas (" + searchFlyoutCard.filteredSearchApps.length + ")")
                                color: "#cccccc"; font.pixelSize: 12; font.bold: true
                            }

                            Column {
                                width: parent.width
                                spacing: 4

                                Repeater {
                                    model: searchFlyoutCard.filteredSearchApps
                                    delegate: Rectangle {
                                        width: searchResCol.width
                                        height: 40
                                        radius: 6
                                        color: sItemHov.containsMouse ? "#2e2e2e" : "#252525"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 12

                                            WinSvg { width: 24; height: 24; iconUrl: modelData.iconUrl || "" }
                                            Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: "Aplicación"; color: "#888888"; font.pixelSize: 11 }
                                        }

                                        MouseArea {
                                            id: sItemHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                shellRoot.closeAllPopups();
                                                shellRoot.spawnCmd(modelData.cmd);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // [C] Search the Web option when typing
                        Rectangle {
                            visible: shellRoot.searchQuery.trim() !== ""
                            width: parent.width
                            height: 46
                            radius: 8
                            color: webSearchHov.containsMouse ? "#2e2e2e" : "#252525"
                            border.color: "#22ffffff"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 12
                                WinSvg { width: 24; height: 24; iconFile: "chromium.png" }
                                Text {
                                    text: "Buscar «" + shellRoot.searchQuery.trim() + "» en Google con Chromium"
                                    color: "#60cdff"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: webSearchHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var qUrl = "https://www.google.com/search?q=" + encodeURIComponent(shellRoot.searchQuery.trim());
                                    shellRoot.closeAllPopups();
                                    shellRoot.spawnCmd("xdg-open '" + qUrl + "'");
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. WINDOWS 11 QUICK SETTINGS (Win + A) — 100% REAL HARDWARE CONTROLS
        Rectangle {
            visible: shellRoot.quickSettingsOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 135; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: shellRoot.quickSettingsOpen ? 0 : 12
                Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            width: 368
            height: shellRoot.qsSubView === "wifi" ? 426 : (qsMainCol.implicitHeight + 36)
            x: overlayWin.width - width - 12
            y: overlayWin.height - height - (shellRoot.taskbarCompact ? 38 : 48) - 12
            radius: 12
            color: "#f5202020"
            border.color: "#30ffffff"
            border.width: 1
            MouseArea { anchors.fill: parent }

            // MAIN VIEW: 6 Hardware Tiles + Volume & Brightness Sliders
            Column {
                id: qsMainCol
                visible: shellRoot.qsSubView === "main"
                x: 20
                y: 20
                width: 328
                spacing: 16

                Grid {
                    columns: 3
                    rowSpacing: 14
                    columnSpacing: 12

                    // Tile 1: Wi-Fi (Split button: Toggle + Sub-view arrow)
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: shellRoot.qsWifi ? shellRoot.accentColor : "#2d2d2d"
                            Behavior on color { ColorAnimation { duration: 115 } }
                            border.color: shellRoot.qsWifi ? shellRoot.accentColor : "#22ffffff"

                            Row {
                                anchors.fill: parent
                                Item {
                                    width: 68; height: 48
                                    WinSvg {
                                        anchors.centerIn: parent
                                        width: 20; height: 20
                                        iconFile: shellRoot.qsWifi ? "fluent-wifi-dark.svg" : "fluent-wifi-off.svg"
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.qsWifi = !shellRoot.qsWifi;
                                            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "wifi", "toggle"]);
                                        }
                                    }
                                }
                                Rectangle { width: 1; height: 28; anchors.verticalCenter: parent.verticalCenter; color: shellRoot.qsWifi ? "#28000000" : "#33ffffff" }
                                Item {
                                    width: 31; height: 48
                                    WinSvg {
                                        anchors.centerIn: parent
                                        width: 14; height: 14
                                        iconFile: shellRoot.qsWifi ? "fluent-chevron-right-dark.svg" : "fluent-chevron-right.svg"
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.qsSubView = "wifi"
                                    }
                                }
                            }
                        }
                        Text {
                            width: 100
                            horizontalAlignment: Text.AlignHCenter
                            text: shellRoot.qsWifi ? shellRoot.qsWifiSsid : "Wi-Fi (Apagado)"
                            color: "#e0e0e0"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    // Tile 2: Bluetooth (Split button: Toggle + Blueman Manager)
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: shellRoot.qsBt ? shellRoot.accentColor : "#2d2d2d"
                            Behavior on color { ColorAnimation { duration: 115 } }
                            border.color: shellRoot.qsBt ? shellRoot.accentColor : "#22ffffff"

                            Row {
                                anchors.fill: parent
                                Item {
                                    width: 68; height: 48
                                    WinSvg {
                                        anchors.centerIn: parent
                                        width: 20; height: 20
                                        iconFile: shellRoot.qsBt ? "fluent-bluetooth-filled-dark.svg" : "fluent-bluetooth.svg"
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.qsBt = !shellRoot.qsBt;
                                            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "bluetooth", "toggle"]);
                                        }
                                    }
                                }
                                Rectangle { width: 1; height: 28; anchors.verticalCenter: parent.verticalCenter; color: shellRoot.qsBt ? "#28000000" : "#33ffffff" }
                                Item {
                                    width: 31; height: 48
                                    WinSvg {
                                        anchors.centerIn: parent
                                        width: 14; height: 14
                                        iconFile: shellRoot.qsBt ? "fluent-chevron-right-dark.svg" : "fluent-chevron-right.svg"
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            shellRoot.closeAllPopups();
                                            shellRoot.spawnCmd("blueman-manager || /usr/bin/x64-win11-app settings");
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            width: 100
                            horizontalAlignment: Text.AlignHCenter
                            text: shellRoot.qsBt ? "Bluetooth" : "BT (Apagado)"
                            color: "#e0e0e0"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    // Tile 3: Gaming X64 (3-State Real Power Profile: performance <-> balanced)
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: shellRoot.qsGaming ? shellRoot.accentColor : (qsGameHov.containsMouse ? "#383838" : "#2d2d2d")
                            Behavior on color { ColorAnimation { duration: 115 } }
                            border.color: shellRoot.qsGaming ? shellRoot.accentColor : "#22ffffff"
                            WinSvg {
                                anchors.centerIn: parent
                                width: 21; height: 21
                                iconFile: shellRoot.qsGaming ? "fluent-games-filled-dark.svg" : "fluent-games.svg"
                            }
                            MouseArea {
                                id: qsGameHov
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var nextProfile = shellRoot.qsGaming ? "balanced" : "performance";
                                    shellRoot.applyPowerProfile(nextProfile);
                                }
                            }
                        }
                        Text {
                            width: 100
                            horizontalAlignment: Text.AlignHCenter
                            text: "Gaming X64"
                            color: "#e0e0e0"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    // Tile 4: Luz nocturna (Real ~4800K warm screen filter persisted in config.json)
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: shellRoot.qsNightLight ? shellRoot.accentColor : (qsNlHov.containsMouse ? "#383838" : "#2d2d2d")
                            Behavior on color { ColorAnimation { duration: 115 } }
                            border.color: shellRoot.qsNightLight ? shellRoot.accentColor : "#22ffffff"
                            WinSvg {
                                anchors.centerIn: parent
                                width: 20; height: 20
                                iconFile: shellRoot.qsNightLight ? "fluent-night-light-filled-dark.svg" : "fluent-night-light.svg"
                            }
                            MouseArea {
                                id: qsNlHov
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shellRoot.qsNightLight = !shellRoot.qsNightLight;
                                    shellRoot.saveConfigKey("nightLight", shellRoot.qsNightLight ? "true" : "false");
                                }
                            }
                        }
                        Text {
                            width: 100
                            horizontalAlignment: Text.AlignHCenter
                            text: "Luz nocturna"
                            color: "#e0e0e0"
                            font.pixelSize: 11
                        }
                    }

                    // Tile 5: Ahorro energía (3-State Real Power Profile: power-saver <-> balanced)
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: shellRoot.qsBatterySaver ? shellRoot.accentColor : (qsSaverHov.containsMouse ? "#383838" : "#2d2d2d")
                            Behavior on color { ColorAnimation { duration: 115 } }
                            border.color: shellRoot.qsBatterySaver ? shellRoot.accentColor : "#22ffffff"
                            WinSvg {
                                anchors.centerIn: parent
                                width: 20; height: 20
                                iconFile: shellRoot.qsBatterySaver ? "fluent-battery-saver-filled-dark.svg" : "fluent-battery-saver.svg"
                            }
                            MouseArea {
                                id: qsSaverHov
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var nextProfile = shellRoot.qsBatterySaver ? "balanced" : "power-saver";
                                    shellRoot.applyPowerProfile(nextProfile);
                                }
                            }
                        }
                        Text {
                            width: 100
                            horizontalAlignment: Text.AlignHCenter
                            text: "Ahorro energía"
                            color: "#e0e0e0"
                            font.pixelSize: 11
                        }
                    }

                    // Tile 6: Configuración 26H2
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: qsCfgHov.containsMouse ? "#383838" : "#2d2d2d"
                            Behavior on color { ColorAnimation { duration: 115 } }
                            border.color: "#22ffffff"
                            WinSvg { anchors.centerIn: parent; width: 20; height: 20; iconFile: "fluent-settings.svg" }
                            MouseArea {
                                id: qsCfgHov
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shellRoot.closeAllPopups();
                                    shellRoot.spawnCmd("/usr/bin/x64-win11-app settings");
                                }
                            }
                        }
                        Text {
                            width: 100
                            horizontalAlignment: Text.AlignHCenter
                            text: "Configuración"
                            color: "#e0e0e0"
                            font.pixelSize: 11
                        }
                    }
                }

                // 1st Row (Authentic Win11 Order): Brightness Slider ON TOP
                RowLayout {
                    width: 328
                    spacing: 12
                    Rectangle {
                        width: 32; height: 32; radius: 6
                        color: "transparent"
                        WinSvg {
                            anchors.centerIn: parent
                            width: 20; height: 20
                            iconFile: "fluent-brightness.svg"
                        }
                    }
                    Win11Slider {
                        id: brightnessSlider
                        Layout.fillWidth: true
                        from: 10.0; to: 100.0
                        externalValue: shellRoot.qsBrightness
                        onUserMoved: (newVal) => {
                            shellRoot.brightnessAdjusting = true;
                            brightnessCooldownTimer.restart();
                            shellRoot.qsBrightness = newVal;
                            if (!hwBacklightWriteTimer.running) hwBacklightWriteTimer.start();
                        }
                        onUserReleased: (finalVal) => {
                            brightnessCooldownTimer.restart();
                            shellRoot.qsBrightness = finalVal;
                            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "brightness", "set", String(Math.round(finalVal))]);
                        }
                    }
                    Item { width: 32; height: 32 }
                }

                // 2nd Row (Authentic Win11 Order): Volume Slider + Mute Button + Audio Output ">" Button
                RowLayout {
                    width: 328
                    spacing: 12
                    Rectangle {
                        width: 32; height: 32; radius: 6
                        color: muteBtnHov.containsMouse ? "#28ffffff" : "transparent"
                        WinSvg {
                            anchors.centerIn: parent
                            width: 20; height: 20
                            iconFile: (shellRoot.sinkMuted || shellRoot.sinkVolPct === 0)
                                      ? "fluent-speaker-mute.svg"
                                      : (shellRoot.sinkVolPct < 50 ? "fluent-speaker-med.svg" : "fluent-speaker-high.svg")
                        }
                        MouseArea {
                            id: muteBtnHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "volume", "mute"])
                        }
                    }
                    Win11Slider {
                        Layout.fillWidth: true
                        from: 0.0; to: 100.0
                        externalValue: shellRoot.sinkVolPct
                        tooltipOverride: shellRoot.sinkMuted ? "Silenciado" : ""
                        onUserMoved: (newVal) => {
                            if (shellRoot.defaultSink && shellRoot.defaultSink.audio) {
                                if (shellRoot.defaultSink.audio.muted && newVal > 0.5) {
                                    shellRoot.defaultSink.audio.muted = false;
                                }
                                shellRoot.defaultSink.audio.volume = Math.max(0.0, Math.min(1.0, newVal / 100.0));
                            } else {
                                shellRoot.spawnCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(newVal) + "%");
                            }
                        }
                    }
                    Rectangle {
                        width: 32; height: 32; radius: 6
                        color: audOutHov.containsMouse ? "#28ffffff" : "transparent"
                        WinSvg {
                            anchors.centerIn: parent
                            width: 15; height: 15
                            iconFile: "fluent-chevron-right.svg"
                        }
                        MouseArea {
                            id: audOutHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                shellRoot.closeAllPopups();
                                shellRoot.spawnCmd("pavucontrol || /usr/bin/x64-win11-app settings 'Sistema'");
                            }
                        }
                    }
                }

                Rectangle { width: 328; height: 1; color: "#22ffffff" }

                // Bottom Status Footer
                RowLayout {
                    width: 328
                    spacing: 8
                    WinSvg {
                        width: 18; height: 18
                        iconFile: shellRoot.hasBattery
                                  ? (shellRoot.qsBatterySaver ? "fluent-battery-saver.svg" : "fluent-battery-charge.svg")
                                  : "fluent-plug.svg"
                    }
                    Text {
                        text: (shellRoot.hasBattery ? shellRoot.batteryText : "Conectado a CA") + " • Perfil: " + shellRoot.qsCpuGov
                        color: "#cccccc"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // WI-FI SUB-VIEW: Real Network Selector via NetworkManager (nmcli)
            Column {
                visible: shellRoot.qsSubView === "wifi"
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    width: 332
                    spacing: 8
                    Rectangle {
                        width: 30; height: 30; radius: 6
                        color: wifiBackHov.containsMouse ? "#33ffffff" : "transparent"
                        WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: "fluent-arrow-left.svg" }
                        MouseArea {
                            id: wifiBackHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.qsSubView = "main"
                        }
                    }
                    WinSvg { width: 18; height: 18; iconFile: "fluent-wifi.svg" }
                    Text {
                        text: "Redes Wi-Fi"
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 30; height: 30; radius: 6
                        color: (shellRoot.wifiRescanning || wifiScanHov.containsMouse) ? "#33ffffff" : "transparent"
                        WinSvg {
                            id: wifiRefreshIcon
                            anchors.centerIn: parent
                            width: 16; height: 16
                            iconFile: "fluent-refresh.svg"
                            transformOrigin: Item.Center
                            NumberAnimation on rotation {
                                from: 0; to: 360; duration: 650
                                loops: Animation.Infinite
                                running: shellRoot.wifiRescanning
                                onStopped: wifiRefreshIcon.rotation = 0
                            }
                        }
                        MouseArea {
                            id: wifiScanHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.triggerWifiRescan()
                        }
                    }
                    Win11Switch {
                        checked: shellRoot.qsWifi
                        onToggled: {
                            shellRoot.qsWifi = checked;
                            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "wifi", checked ? "on" : "off"]);
                        }
                    }
                }

                Rectangle { width: 332; height: 1; color: "#22ffffff" }

                Flickable {
                    width: 332
                    height: 305
                    contentWidth: 332
                    contentHeight: wifiNetCol.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    Column {
                        id: wifiNetCol
                        width: 332
                        spacing: 6

                        Repeater {
                            model: shellRoot.qsWifiNetworks

                            delegate: Rectangle {
                                width: 332
                                height: 54
                                radius: 8
                                color: modelData.active ? "#2b3b4b" : (wifiItemHov.containsMouse ? "#2e2e2e" : "#252525")
                                border.color: modelData.active ? "#60cdff" : "#1affffff"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    WinSvg { width: 20; height: 20; iconFile: "fluent-wifi.svg" }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: modelData.ssid || "Red Wi-Fi"
                                            color: "#ffffff"
                                            font.pixelSize: 13
                                            font.bold: modelData.active
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: (modelData.active ? "Conectado, seguro • " : "") + "Señal " + (modelData.signal || 0) + "% • " + (modelData.security || "Abierta")
                                            color: modelData.active ? "#60cdff" : "#aaaaaa"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        visible: !modelData.active
                                        width: 74; height: 28; radius: 5
                                        color: "#0078d4"
                                        Text { anchors.centerIn: parent; text: "Conectar"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                                    }
                                }

                                MouseArea {
                                    id: wifiItemHov
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!modelData.active && modelData.ssid) {
                                            Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "wifi", "connect", modelData.ssid]);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { width: 332; height: 1; color: "#22ffffff" }

                Text {
                    text: "Más opciones de adaptador de red"
                    color: "#60cdff"
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            shellRoot.closeAllPopups();
                            shellRoot.spawnCmd("nm-connection-editor || /usr/bin/x64-win11-app settings");
                        }
                    }
                }
            }
        }

        // 5. AUTHENTIC WINDOWS 11 26H2 TWO-CARD NOTIFICATION CENTER + INTERACTIVE CALENDAR + FOCUS SESSION
        Column {
            id: notifCalendarFlyout
            visible: shellRoot.calendarOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            transform: Translate {
                x: shellRoot.calendarOpen ? 0 : 18
                Behavior on x { NumberAnimation { duration: 165; easing.type: Easing.OutCubic } }
            }
            width: 360
            x: overlayWin.width - width - 12
            y: overlayWin.height - implicitHeight - (shellRoot.taskbarCompact ? 38 : 48) - 12
            spacing: 10

            // CARD 1: NOTIFICATION CENTER ("Notificaciones" + No molestar + Borrar todo)
            Rectangle {
                id: notifCenterCard
                width: 360
                height: notifCardInnerCol.implicitHeight + 28
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                radius: 12
                color: shellRoot.panelBg
                border.color: "#2effffff"
                border.width: 1
                clip: true
                MouseArea { anchors.fill: parent }

                Column {
                    id: notifCardInnerCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 10

                    // Top Header Row: Title + Do Not Disturb ("No molestar") + "Borrar todo"
                    RowLayout {
                        width: 332
                        spacing: 8

                        Text {
                            text: "Notificaciones"
                            color: "#f5f5f5"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        // Do Not Disturb ("No molestar") Toggle Button
                        Rectangle {
                            width: 30
                            height: 26
                            radius: 5
                            color: shellRoot.qsDnd ? shellRoot.accentColor : (dndBtnHov.containsMouse ? "#2effffff" : "#1effffff")
                            border.color: shellRoot.qsDnd ? shellRoot.accentColor : "#20ffffff"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 115 } }

                            WinSvg {
                                anchors.centerIn: parent
                                width: 15; height: 15
                                iconFile: shellRoot.qsDnd ? "fluent-bell-snooze-filled-dark.svg" : "fluent-bell-snooze.svg"
                            }

                            MouseArea {
                                id: dndBtnHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var nextDnd = !shellRoot.qsDnd;
                                    shellRoot.qsDnd = nextDnd;
                                    if (shellRoot.focusRunning) shellRoot.dndBeforeFocus = nextDnd;
                                    shellRoot.saveConfigKey("doNotDisturb", nextDnd ? "true" : "false");
                                }
                            }
                        }

                        // "Borrar todo" Pill Button (visible only when there are notifications)
                        Rectangle {
                            visible: shellRoot.notifItems.length > 0
                            width: clearAllLbl.implicitWidth + 18
                            height: 26
                            radius: 5
                            color: clearAllHov.containsMouse ? "#383838" : "#2b2b2b"
                            border.color: "#22ffffff"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 115 } }

                            Text {
                                id: clearAllLbl
                                anchors.centerIn: parent
                                text: "Borrar todo"
                                color: "#f0f0f0"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: clearAllHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.clearAllNotifications()
                            }
                        }
                    }

                    // Subtle "No molestar" Active Banner (Exact Win11 26H2 Notice)
                    Rectangle {
                        visible: shellRoot.qsDnd
                        width: 332
                        height: 32
                        radius: 6
                        color: "#262626"
                        border.color: "#1effffff"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8
                            WinSvg { width: 15; height: 15; iconFile: "fluent-bell-snooze-filled.svg" }
                            Text {
                                text: shellRoot.focusRunning
                                      ? "No molestar activado por Concentración"
                                      : "No molestar está activado"
                                color: "#d4d4d4"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Empty State ("No hay notificaciones nuevas")
                    Item {
                        visible: shellRoot.notifItems.length === 0
                        width: 332
                        height: 52
                        Text {
                            anchors.centerIn: parent
                            text: "No hay notificaciones nuevas"
                            color: "#9a9a9a"
                            font.pixelSize: 12
                        }
                    }

                    // Scrollable Notification Cards List
                    Flickable {
                        visible: shellRoot.notifItems.length > 0
                        width: 332
                        height: Math.min(260, notifCardsCol.implicitHeight)
                        contentWidth: 332
                        contentHeight: notifCardsCol.implicitHeight
                        clip: true
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        Column {
                            id: notifCardsCol
                            width: 332
                            spacing: 8

                            Repeater {
                                model: shellRoot.notifItems

                                delegate: Rectangle {
                                    width: 332
                                    height: nCardContent.implicitHeight + 20
                                    radius: 8
                                    color: nCardHover.containsMouse ? "#303030" : "#292929"
                                    border.color: "#1effffff"
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 110 } }

                                    MouseArea {
                                        id: nCardHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }

                                    Column {
                                        id: nCardContent
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 10
                                        spacing: 5

                                        RowLayout {
                                            width: 312
                                            spacing: 7
                                            WinSvg {
                                                width: 15; height: 15
                                                iconUrl: modelData.iconUrl || (shellRoot.assetDir + "windows.svg")
                                            }
                                            Text {
                                                text: modelData.app || "Sistema"
                                                color: "#c8c8c8"
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: modelData.time || ""
                                                color: "#8e8e8e"
                                                font.pixelSize: 11
                                            }
                                            Rectangle {
                                                width: 22; height: 22; radius: 4
                                                color: nDismissHov.containsMouse ? "#2affffff" : "transparent"
                                                opacity: (nCardHover.containsMouse || nDismissHov.containsMouse) ? 1.0 : 0.65
                                                WinSvg {
                                                    anchors.centerIn: parent
                                                    width: 10; height: 10
                                                    iconFile: "fluent-dismiss.svg"
                                                }
                                                MouseArea {
                                                    id: nDismissHov
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: shellRoot.dismissNotification(modelData.uid)
                                                }
                                            }
                                        }

                                        Text {
                                            width: 312
                                            text: modelData.title || ""
                                            color: "#f5f5f5"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            wrapMode: Text.WordWrap
                                        }

                                        Text {
                                            visible: (modelData.body || "") !== ""
                                            width: 312
                                            text: modelData.body || ""
                                            color: "#c6c6c6"
                                            font.pixelSize: 12
                                            wrapMode: Text.WordWrap
                                            maximumLineCount: 3
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // CARD 2: AUTHENTIC WINDOWS 11 26H2 INTERACTIVE CALENDAR + FOCUS SESSION
            Rectangle {
                id: calendarMainCard
                width: 360
                height: calOuterCol.implicitHeight
                radius: 12
                color: shellRoot.panelBg
                border.color: "#2effffff"
                border.width: 1
                clip: true
                MouseArea {
                    anchors.fill: parent
                    onWheel: (wheel) => {
                        if (!shellRoot.calendarCollapsed) {
                            if (wheel.angleDelta.y > 0) shellRoot.stepCalendarMonth(-1);
                            else if (wheel.angleDelta.y < 0) shellRoot.stepCalendarMonth(1);
                        }
                    }
                }

                Column {
                    id: calOuterCol
                    width: 360
                    spacing: 0

                    // 2A. Top Long Date Header Bar + Collapse/Expand Chevron ("v")
                    Item {
                        width: 360
                        height: 46

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 11
                            color: "#1b1b1b"
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                height: 11; color: "#1b1b1b"
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                                height: 1; color: "#1cffffff"
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            spacing: 8

                            Text {
                                text: shellRoot.calShortTopDate
                                color: topDateHov.containsMouse ? shellRoot.accentColor : "#f0f0f0"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Behavior on color { ColorAnimation { duration: 110 } }
                                MouseArea {
                                    id: topDateHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.jumpCalendarToToday()
                                }
                            }

                            Rectangle {
                                width: 28; height: 28; radius: 5
                                color: calCollapseHov.containsMouse ? "#363636" : "#272727"
                                border.color: "#22ffffff"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 110 } }

                                WinSvg {
                                    anchors.centerIn: parent
                                    width: 13; height: 13
                                    iconFile: "fluent-chevron-down.svg"
                                    transformOrigin: Item.Center
                                    rotation: shellRoot.calendarCollapsed ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 165; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    id: calCollapseHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.calendarCollapsed = !shellRoot.calendarCollapsed
                                }
                            }
                        }
                    }

                    // 2B. Collapsible Month Navigation & 42-Cell Day Grid
                    Item {
                        width: 360
                        height: shellRoot.calendarCollapsed ? 0 : (calGridInnerCol.implicitHeight + 24)
                        clip: true
                        Behavior on height { NumberAnimation { duration: 195; easing.type: Easing.OutCubic } }

                        Column {
                            id: calGridInnerCol
                            x: 16
                            y: 12
                            width: 328
                            spacing: 8

                            // Month Title + Solid Up/Down Caret Buttons ("▲" / "▼")
                            RowLayout {
                                width: 328
                                height: 30
                                spacing: 4

                                Text {
                                    text: shellRoot.calMonthTitle
                                    color: monthLblHov.containsMouse ? shellRoot.accentColor : "#f5f5f5"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 110 } }
                                    MouseArea {
                                        id: monthLblHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.jumpCalendarToToday()
                                    }
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 5
                                    color: prevMoHov.containsMouse ? "#2cffffff" : "transparent"
                                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-caret-up.svg" }
                                    MouseArea {
                                        id: prevMoHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.stepCalendarMonth(-1)
                                    }
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 5
                                    color: nextMoHov.containsMouse ? "#2cffffff" : "transparent"
                                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "fluent-caret-down.svg" }
                                    MouseArea {
                                        id: nextMoHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.stepCalendarMonth(1)
                                    }
                                }
                            }

                            // Weekday Headers Row ("lu ma mi ju vi sá do")
                            Row {
                                width: 328
                                spacing: 8
                                Repeater {
                                    model: ["lu", "ma", "mi", "ju", "vi", "sá", "do"]
                                    delegate: Item {
                                        width: 40; height: 26
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: "#cfcfcf"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }

                            // 6x7 (42-Cell) Full Month Grid with Trailing/Leading Dimmed Days & Smooth Vector Circles
                            Grid {
                                width: 328
                                columns: 7
                                columnSpacing: 8
                                rowSpacing: 4

                                Repeater {
                                    model: shellRoot.calDayCells

                                    delegate: Item {
                                        width: 40
                                        height: 36
                                        readonly property bool isSel: (modelData.year === shellRoot.calSelectedYear &&
                                                                       modelData.month === shellRoot.calSelectedMonth &&
                                                                       modelData.day === shellRoot.calSelectedDay)

                                        WinSvg {
                                            visible: modelData.isToday || parent.isSel || calDayHov.containsMouse
                                            anchors.centerIn: parent
                                            width: 36; height: 36
                                            iconFile: modelData.isToday
                                                      ? (parent.isSel ? "fluent-cal-today-ring.svg" : "fluent-cal-today.svg")
                                                      : (parent.isSel ? "fluent-cal-selected.svg" : "fluent-cal-hover.svg")
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: String(modelData.day)
                                            color: modelData.isToday
                                                   ? "#000000"
                                                   : (parent.isSel ? shellRoot.accentColor : (modelData.inMonth ? "#f5f5f5" : "#767676"))
                                            font.pixelSize: 12
                                            font.weight: (modelData.isToday || parent.isSel) ? Font.DemiBold : Font.Normal
                                        }

                                        MouseArea {
                                            id: calDayHov
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                shellRoot.calSelectedYear = modelData.year;
                                                shellRoot.calSelectedMonth = modelData.month;
                                                shellRoot.calSelectedDay = modelData.day;
                                                if (!modelData.inMonth) {
                                                    shellRoot.calViewYear = modelData.year;
                                                    shellRoot.calViewMonth = modelData.month;
                                                    shellRoot.rebuildInteractiveCalendar();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 2C. Authentic Windows 11 26H2 Focus Session Footer ("-  30 min  +   [▶ Concentrarse]")
                    Item {
                        width: 360
                        height: 54

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 11
                            color: "#1b1b1b"
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                height: 11; color: "#1b1b1b"
                            }
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                height: 1; color: "#1cffffff"
                            }
                        }

                        // Idle State: Duration Stepper + "▶ Concentrarse"
                        RowLayout {
                            visible: !shellRoot.focusRunning
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            spacing: 6

                            Rectangle {
                                width: 28; height: 28; radius: 5
                                color: focusMinusHov.containsMouse ? "#383838" : "#2a2a2a"
                                border.color: "#22ffffff"
                                border.width: 1
                                opacity: shellRoot.focusDurationMins <= 15 ? 0.42 : 1.0
                                WinSvg { anchors.centerIn: parent; width: 13; height: 13; iconFile: "fluent-subtract.svg" }
                                MouseArea {
                                    id: focusMinusHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: shellRoot.focusDurationMins > 15
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.stepFocusDuration(-1)
                                }
                            }

                            Item {
                                width: 68; height: 30
                                Column {
                                    anchors.centerIn: parent
                                    spacing: -2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(shellRoot.focusDurationMins)
                                        color: "#f5f5f5"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "minutos"
                                        color: "#a8a8a8"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Rectangle {
                                width: 28; height: 28; radius: 5
                                color: focusPlusHov.containsMouse ? "#383838" : "#2a2a2a"
                                border.color: "#22ffffff"
                                border.width: 1
                                opacity: shellRoot.focusDurationMins >= 240 ? 0.42 : 1.0
                                WinSvg { anchors.centerIn: parent; width: 13; height: 13; iconFile: "fluent-add.svg" }
                                MouseArea {
                                    id: focusPlusHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: shellRoot.focusDurationMins < 240
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.stepFocusDuration(1)
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: focusStartRow.implicitWidth + 22
                                height: 30
                                radius: 5
                                color: focusStartHov.containsMouse ? "#383838" : "#2a2a2a"
                                border.color: "#24ffffff"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 110 } }

                                Row {
                                    id: focusStartRow
                                    anchors.centerIn: parent
                                    spacing: 7
                                    WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; iconFile: "fluent-play-filled.svg" }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Concentrarse"
                                        color: "#f5f5f5"
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    id: focusStartHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.startFocusSession()
                                }
                            }
                        }

                        // Running State: Live Countdown + "■ Finalizar"
                        RowLayout {
                            visible: shellRoot.focusRunning
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 14
                            spacing: 10

                            WinSvg { width: 16; height: 16; iconFile: "fluent-bell-snooze-filled.svg" }

                            Column {
                                Layout.fillWidth: true
                                spacing: -1
                                Text {
                                    text: shellRoot.formatFocusTime(shellRoot.focusRemainingSecs)
                                    color: shellRoot.accentColor
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "Sesión de concentración activa"
                                    color: "#b8b8b8"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                width: focusStopRow.implicitWidth + 20
                                height: 30
                                radius: 5
                                color: focusStopHov.containsMouse ? "#3a3a3a" : "#2a2a2a"
                                border.color: "#24ffffff"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 110 } }

                                Row {
                                    id: focusStopRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 11; height: 11; iconFile: "fluent-stop-filled.svg" }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Finalizar"
                                        color: "#f5f5f5"
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    id: focusStopHov
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: shellRoot.stopFocusSession(false)
                                }
                            }
                        }
                    }
                }
            }
        }

        // 6. AUTHENTIC WINDOWS 11 26H2 DARK WINUI 3 RUN DIALOG ("Win + R")
        Rectangle {
            id: runDialogCard
            visible: shellRoot.runDialogOpen
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 125; easing.type: Easing.OutCubic } }
            transform: Translate {
                y: shellRoot.runDialogOpen ? 0 : 10
                Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
            onVisibleChanged: {
                if (visible) {
                    runInput.selectAll();
                    runInput.forceActiveFocus();
                }
            }
            x: 16
            y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 14
            width: 444
            height: 222
            radius: 10
            color: shellRoot.menuBg
            border.color: "#30ffffff"
            border.width: 1
            clip: true
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // WinUI 3 Titlebar
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        spacing: 10

                        WinSvg { width: 16; height: 16; iconFile: "fluent-window-apps.svg" }
                        Text {
                            text: "Ejecutar"
                            color: "#f2f2f2"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 44; height: 36
                            color: runCloseHov.containsMouse ? "#c42b1c" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 11; height: 11; iconFile: "fluent-dismiss.svg" }
                            MouseArea {
                                id: runCloseHov
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: shellRoot.runDialogOpen = false
                            }
                        }
                    }
                }

                // Dialog Content Area
                Column {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    Layout.topMargin: 8
                    spacing: 16

                    RowLayout {
                        width: 408
                        spacing: 14
                        WinSvg { width: 34; height: 34; iconFile: "fluent-window-apps.svg" }
                        Text {
                            Layout.fillWidth: true
                            text: "Escriba el nombre de un programa, carpeta, documento o recurso de Internet y se abrirá automáticamente."
                            color: "#d4d4d4"
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }

                    RowLayout {
                        width: 408
                        spacing: 12
                        Text { text: "Abrir:"; color: "#f0f0f0"; font.pixelSize: 12 }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 5
                            color: "#1b1b1b"
                            border.color: "#28ffffff"
                            border.width: 1
                            clip: true

                            // Authentic WinUI 3 Bottom Focus Accent Bar
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: runInput.activeFocus ? 2 : 1
                                color: runInput.activeFocus ? shellRoot.accentColor : "#55ffffff"
                            }

                            TextInput {
                                id: runInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#ffffff"
                                selectionColor: "#0067c0"
                                selectedTextColor: "#ffffff"
                                selectByMouse: true
                                font.pixelSize: 12
                                text: "explorer"
                                Keys.onEscapePressed: shellRoot.runDialogOpen = false
                                onAccepted: {
                                    var c = runInput.text;
                                    shellRoot.runDialogOpen = false;
                                    shellRoot.executeRunCommand(c);
                                }
                            }
                        }
                    }
                }

                // WinUI 3 Bottom Action Chamber ("Aceptar | Cancelar | Examinar...")
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58

                    Rectangle {
                        anchors.fill: parent
                        color: "#1b1b1b"
                        Rectangle {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            height: 1; color: "#1cffffff"
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 8

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            readonly property bool canRun: runInput.text.trim() !== ""
                            width: 96; height: 32; radius: 5
                            color: !canRun ? "#2a2a2a" : (runOkHov.containsMouse ? Qt.lighter(shellRoot.accentColor, 1.12) : shellRoot.accentColor)
                            opacity: canRun ? 1.0 : 0.5
                            Text {
                                anchors.centerIn: parent
                                text: "Aceptar"
                                color: parent.canRun ? "#000000" : "#aaaaaa"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                id: runOkHov
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: parent.canRun
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var c = runInput.text;
                                    shellRoot.runDialogOpen = false;
                                    shellRoot.executeRunCommand(c);
                                }
                            }
                        }

                        Rectangle {
                            width: 96; height: 32; radius: 5
                            color: runCancelHov.containsMouse ? "#383838" : "#2b2b2b"
                            border.color: "#22ffffff"
                            border.width: 1
                            Text { anchors.centerIn: parent; text: "Cancelar"; color: "#f2f2f2"; font.pixelSize: 12 }
                            MouseArea {
                                id: runCancelHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.runDialogOpen = false
                            }
                        }

                        Rectangle {
                            width: 102; height: 32; radius: 5
                            color: runBrowseHov.containsMouse ? "#383838" : "#2b2b2b"
                            border.color: "#22ffffff"
                            border.width: 1
                            Text { anchors.centerIn: parent; text: "Examinar..."; color: "#f2f2f2"; font.pixelSize: 12 }
                            MouseArea {
                                id: runBrowseHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shellRoot.runDialogOpen = false;
                                    shellRoot.spawnCmd("/usr/bin/x64-win11-app explorer 'Inicio'");
                                }
                            }
                        }
                    }
                }
            }
        }

        // 7. AUTHENTIC WINDOWS 11 26H2 LOCK SCREEN & SIGN-IN SCREEN ("Win + L")
        Rectangle {
            id: lockScreenRoot
            visible: shellRoot.lockScreenOpen
            anchors.fill: parent
            color: "#000000"
            focus: shellRoot.lockScreenOpen && (!shellRoot.lockPromptOpen || !shellRoot.lockRequireAuth)

            onVisibleChanged: {
                if (visible) {
                    shellRoot.lockShowPass = false;
                    shellRoot.lockAuthError = "";
                    shellRoot.lockAuthChecking = false;
                    lockPassInput.text = "";
                    lockScreenRoot.forceActiveFocus();
                } else {
                    shellRoot.lockAuthError = "";
                    shellRoot.lockAuthChecking = false;
                }
            }

            Connections {
                target: shellRoot
                function onLockPromptOpenChanged() {
                    if (shellRoot.lockPromptOpen && shellRoot.lockRequireAuth) {
                        Qt.callLater(function() { lockPassInput.forceActiveFocus(); });
                    } else if (shellRoot.lockScreenOpen) {
                        Qt.callLater(function() { lockScreenRoot.forceActiveFocus(); });
                    }
                }
                function onLockAuthErrorChanged() {
                    if (shellRoot.lockAuthError !== "" && shellRoot.lockPromptOpen && shellRoot.lockRequireAuth) {
                        Qt.callLater(function() { lockPassInput.forceActiveFocus(); });
                    }
                }
            }

            Keys.onPressed: (event) => {
                if (!shellRoot.lockPromptOpen && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                    shellRoot.lockPromptOpen = true;
                    event.accepted = true;
                } else if (shellRoot.lockPromptOpen && !shellRoot.lockRequireAuth && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                    shellRoot.submitLockUnlock("");
                    event.accepted = true;
                } else if (shellRoot.lockPromptOpen && event.key === Qt.Key_Escape) {
                    shellRoot.lockAuthError = "";
                    shellRoot.lockPromptOpen = false;
                    lockScreenRoot.forceActiveFocus();
                    event.accepted = true;
                }
            }

            Rectangle {
                anchors.fill: parent
                color: (shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperMode === 4) ? (shellRoot.solidBgColor || "#141923") : "#0b0e14"
            }

            Image {
                anchors.fill: parent
                visible: !(shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperMode === 4)
                cache: false
                source: {
                    var lm = shellRoot.lockWallpaperMode;
                    if (lm === 3 && shellRoot.lockWallpaperUrl !== "") return shellRoot.lockWallpaperUrl;
                    if (lm === 0) return shellRoot.wpDir + "win11-bloom-dark.jpg";
                    if (lm === 1) return shellRoot.wpDir + "win11-bloom-light.jpg";
                    if (lm === 2) return shellRoot.wpDir + "x64-monolith.jpg";
                    if (shellRoot.wallpaperMode === 3 && shellRoot.customWallpaperUrl !== "") return shellRoot.customWallpaperUrl;
                    if (shellRoot.wallpaperMode === 1) return shellRoot.wpDir + "win11-bloom-light.jpg";
                    if (shellRoot.wallpaperMode === 2) return shellRoot.wpDir + "x64-monolith.jpg";
                    return shellRoot.wpDir + "win11-bloom-dark.jpg";
                }
                fillMode: (shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperFit === "fit") ? Image.PreserveAspectFit
                          : ((shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperFit === "stretch") ? Image.Stretch
                             : ((shellRoot.lockWallpaperMode === -1 && shellRoot.wallpaperFit === "center") ? Image.Pad : Image.PreserveAspectCrop))
                scale: shellRoot.lockPromptOpen ? 1.04 : 1.0
                Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                anchors.fill: parent
                color: shellRoot.lockPromptOpen ? "#bf0c1018" : "#26000000"
                Behavior on color { ColorAnimation { duration: 240 } }
            }

            // [A] Clock & Date Spotlight View (+ Optional Lock Screen Quick Status Card!)
            Column {
                visible: opacity > 0.01
                opacity: shellRoot.lockPromptOpen ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                anchors.horizontalCenter: parent.horizontalCenter
                y: shellRoot.lockPromptOpen ? 60 : 118
                Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: shellRoot.currentTimeStr
                    color: "#ffffff"
                    font.pixelSize: 96
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: shellRoot.currentLockDateStr
                    color: "#f2f4f8"
                    font.pixelSize: 21
                }
                Rectangle {
                    visible: shellRoot.lockShowStatus
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: lockStatRow.implicitWidth + 28; height: 38; radius: 19
                    color: "#66141820"; border.color: "#2cffffff"; border.width: 1
                    RowLayout {
                        id: lockStatRow; anchors.centerIn: parent; spacing: 10
                        WinSvg { width: 18; height: 18; iconFile: shellRoot.weatherData.icon || "win11-weather.svg" }
                        Text {
                            text: (shellRoot.weatherData.temp || "--°C") + "  •  " + (shellRoot.weatherData.desc || "El Tiempo")
                                  + (shellRoot.qsWifiSsid ? ("  •  " + shellRoot.qsWifiSsid) : "")
                            color: "#f0f4f8"; font.pixelSize: 12; font.weight: Font.Medium
                        }
                    }
                }
            }

            // Click anywhere on Clock View to slide into Sign-In View
            MouseArea {
                anchors.fill: parent
                enabled: !shellRoot.lockPromptOpen
                onClicked: {
                    shellRoot.lockPromptOpen = true;
                    lockPassInput.forceActiveFocus();
                }
            }

            // [B] Authentic Windows 11 26H2 Centered Sign-In View (Avatar + Name + WinUI 3 Password/PIN Box)
            Column {
                visible: opacity > 0.01
                opacity: shellRoot.lockPromptOpen ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -18
                spacing: 18

                onVisibleChanged: {
                    if (visible && shellRoot.lockPromptOpen) lockPassInput.forceActiveFocus();
                }

                // Frosted Circular User Avatar (synced live with Configuración -> Cuentas!)
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 128; height: 128; radius: 64
                    color: "#28ffffff"
                    border.color: "#38ffffff"
                    border.width: 2
                    Image {
                        visible: shellRoot.userAvatarUrl !== ""
                        anchors.fill: parent; anchors.margins: 2
                        source: shellRoot.userAvatarUrl
                        sourceSize.width: 256; sourceSize.height: 256
                        fillMode: Image.PreserveAspectFit
                        mipmap: true; smooth: true; cache: false
                    }
                    WinSvg {
                        visible: shellRoot.userAvatarUrl === ""
                        anchors.centerIn: parent
                        width: 62; height: 62
                        iconFile: "fluent-person.svg"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: shellRoot.userName
                    color: "#ffffff"
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                }

                // Authentic WinUI 3 Password / PIN Input Field with Eye Reveal & Real PAM/PIN Verification
                Rectangle {
                    visible: shellRoot.lockRequireAuth
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 288
                    height: 38
                    radius: 5
                    color: "#cc1e1e1e"
                    border.color: shellRoot.lockAuthError !== "" ? "#ef4444" : "#36ffffff"
                    border.width: 1
                    clip: true

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 2
                        color: shellRoot.lockAuthError !== "" ? "#ef4444" : shellRoot.accentColor
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 4
                        spacing: 4

                        TextInput {
                            id: lockPassInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#ffffff"
                            font.pixelSize: 13
                            echoMode: shellRoot.lockShowPass ? TextInput.Normal : TextInput.Password
                            focus: shellRoot.lockPromptOpen && shellRoot.lockRequireAuth
                            onTextChanged: { if (shellRoot.lockAuthError !== "") shellRoot.lockAuthError = ""; }
                            Keys.onEscapePressed: {
                                shellRoot.lockAuthError = "";
                                shellRoot.lockPromptOpen = false;
                                lockScreenRoot.forceActiveFocus();
                            }
                            onAccepted: {
                                var v = lockPassInput.text;
                                lockPassInput.text = "";
                                shellRoot.submitLockUnlock(v);
                            }

                            Text {
                                visible: lockPassInput.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "PIN o contraseña"
                                color: "#a8a8a8"
                                font.pixelSize: 13
                            }
                        }

                        Rectangle {
                            visible: lockPassInput.text !== ""
                            width: 28; height: 28; radius: 4
                            color: lockEyeHov.containsMouse ? "#28ffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "fluent-eye.svg" }
                            MouseArea {
                                id: lockEyeHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: shellRoot.lockShowPass = !shellRoot.lockShowPass
                            }
                        }

                        Rectangle {
                            width: 30; height: 30; radius: 4
                            color: lockSubmitHov.containsMouse ? "#2cffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "fluent-arrow-right.svg" }
                            MouseArea {
                                id: lockSubmitHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var v = lockPassInput.text;
                                    lockPassInput.text = "";
                                    shellRoot.submitLockUnlock(v);
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: shellRoot.lockRequireAuth && shellRoot.lockAuthError !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: shellRoot.lockAuthError
                    color: "#fca5a5"
                    font.pixelSize: 12
                }

                // Instant Windows 11 Sign-In Button when lockRequireAuth is OFF (or helper label when ON)
                Rectangle {
                    visible: !shellRoot.lockRequireAuth
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 146; height: 36; radius: 6
                    color: signInBtnHov.containsMouse ? "#42ffffff" : "#2cffffff"
                    border.color: "#44ffffff"; border.width: 1
                    Text { anchors.centerIn: parent; text: "Iniciar sesión"; color: "#ffffff"; font.pixelSize: 13; font.weight: Font.Medium }
                    MouseArea {
                        id: signInBtnHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            lockPassInput.text = "";
                            shellRoot.submitLockUnlock("");
                        }
                    }
                }

                Text {
                    visible: shellRoot.lockRequireAuth
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: shellRoot.lockAuthChecking ? "Verificando credenciales..." : "Introduce tu PIN o contraseña de Linux"
                    color: "#cfcfcf"
                    font.pixelSize: 12
                }
            }

            // Authentic Windows 11 Bottom-Right Lock Screen Status Icons (Wi-Fi + Battery/AC + Power)
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 28
                anchors.bottomMargin: 24
                spacing: 16

                WinSvg {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 18
                    iconFile: shellRoot.qsWifi ? "fluent-wifi.svg" : "fluent-wifi-off.svg"
                    opacity: 0.92
                }

                WinSvg {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18; height: 18
                    iconFile: shellRoot.hasBattery ? "fluent-battery-charge.svg" : "fluent-plug.svg"
                    opacity: 0.92
                }

                Rectangle {
                    width: 32; height: 32; radius: 6
                    color: lockPwrHov.containsMouse ? "#28ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 18; height: 18; iconFile: "fluent-power.svg" }
                    MouseArea {
                        id: lockPwrHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: shellRoot.spawnCmd("systemctl suspend")
                    }
                }
            }
        }
    }

    // =========================================================================
    // LAYER 4: WINDOWS 11 26H2 BOTTOM-RIGHT LIVE TOAST NOTIFICATION BANNER
    // =========================================================================
    PanelWindow {
        id: toastPopupWin
        screen: shellRoot.activeScreen
        visible: shellRoot.toastVisible && shellRoot.activeToast !== null && !shellRoot.calendarOpen && !shellRoot.lockScreenOpen && !shellRoot.qsDnd

        WlrLayershell.namespace: "x64-win11-toast"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors.bottom: true
        anchors.right: true
        margins.bottom: (shellRoot.taskbarCompact ? 38 : 48) + 12
        margins.right: 12
        implicitWidth: 360
        implicitHeight: toastInnerCol.implicitHeight + 28
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: "#f5242424"
            border.color: "#32ffffff"
            border.width: 1

            Column {
                id: toastInnerCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    width: 332
                    spacing: 8
                    WinSvg {
                        width: 16; height: 16
                        iconUrl: (shellRoot.activeToast && shellRoot.activeToast.iconUrl) ? shellRoot.activeToast.iconUrl : (shellRoot.assetDir + "windows.svg")
                    }
                    Text {
                        text: shellRoot.activeToast ? (shellRoot.activeToast.app || "Sistema") : ""
                        color: "#cfcfcf"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 24; height: 24; radius: 4
                        color: toastCloseHov.containsMouse ? "#2affffff" : "transparent"
                        WinSvg { anchors.centerIn: parent; width: 11; height: 11; iconFile: "fluent-dismiss.svg" }
                        MouseArea {
                            id: toastCloseHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: shellRoot.toastVisible = false
                        }
                    }
                }

                Text {
                    width: 332
                    text: shellRoot.activeToast ? (shellRoot.activeToast.title || "") : ""
                    color: "#f5f5f5"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: shellRoot.activeToast !== null && (shellRoot.activeToast.body || "") !== ""
                    width: 332
                    text: shellRoot.activeToast ? (shellRoot.activeToast.body || "") : ""
                    color: "#c8c8c8"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    shellRoot.toastVisible = false;
                    shellRoot.closeAllPopups();
                    shellRoot.calendarOpen = true;
                }
            }
        }
    }
}
