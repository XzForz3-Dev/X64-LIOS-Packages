import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

ShellRoot {
    id: shellRoot

    readonly property string assetDir: "file:///usr/share/x64-win11/assets/icons/"
    readonly property string wpDir: "file:///usr/share/x64-win11/assets/wallpapers/"

    // Global Windows 11 26H2 Shell State
    property bool startOpen: false
    property bool quickSettingsOpen: false
    property bool calendarOpen: false
    property bool trayFlyoutOpen: false
    property bool powerPopupOpen: false
    property bool ctxMenuOpen: false
    property bool taskbarCtxOpen: false
    property bool runDialogOpen: false
    property bool lockScreenOpen: false
    property bool lockPromptOpen: false
    property real ctxX: 200
    property real ctxY: 200
    property real taskbarCtxX: 400

    // 26H2 Preferences (Synchronized live from ~/.local/state/x64-win11/config.json)
    property string startAllViewMode: "categories"
    property bool showRecommended: false
    property bool showPhoneLink: true
    property bool taskbarCompact: false
    property bool taskbarLeftAlign: false
    property bool showBatteryPct: true
    property int wallpaperMode: 0
    property string kbLayout: "ES"
    property string searchQuery: ""

    // Quick Settings state
    property string qsSubView: "main"
    property bool qsWifi: true
    property bool qsBt: true
    property bool qsGaming: true
    property bool qsNightLight: false
    property bool qsBatterySaver: false
    property bool qsDnd: false
    property real qsBrightness: 90

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property int sinkVolPct: (defaultSink && defaultSink.audio) ? Math.round(defaultSink.audio.volume * 100) : 80
    PwObjectTracker { objects: [shellRoot.defaultSink] }

    property string lastCmdToken: ""
    property bool firstPollDone: false

    function saveConfigKey(k, valJson) {
        Quickshell.execDetached(["/usr/bin/x64-win11-ctl", "set-config", k, valJson]);
    }

    function closeAllPopups() {
        startOpen = false;
        quickSettingsOpen = false;
        calendarOpen = false;
        trayFlyoutOpen = false;
        powerPopupOpen = false;
        ctxMenuOpen = false;
        taskbarCtxOpen = false;
        qsSubView = "main";
    }

    function spawnCmd(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // Poll IPC Command File & Config JSON (Lightweight 180ms FileView / Process)
    Process {
        id: statePoller
        command: ["sh", "-c", "cat ~/.local/state/x64-win11/cmd 2>/dev/null || echo ''; echo '---CFG---'; cat ~/.local/state/x64-win11/config.json 2>/dev/null || echo '{}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text || "";
                var parts = raw.split("---CFG---");
                var cmdLine = (parts[0] || "").trim();
                if (!shellRoot.firstPollDone) {
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
                    } else if (act === "toggle-run") {
                        shellRoot.closeAllPopups();
                        shellRoot.runDialogOpen = !shellRoot.runDialogOpen;
                    } else if (act === "lock") {
                        shellRoot.closeAllPopups();
                        shellRoot.lockPromptOpen = false;
                        shellRoot.lockScreenOpen = true;
                    }
                    shellRoot.lastCmdToken = cmdLine;
                }
                if (parts.length > 1) {
                    try {
                        var cfg = JSON.parse(parts[1].trim());
                        if (cfg.taskbarCompact !== undefined) shellRoot.taskbarCompact = Boolean(cfg.taskbarCompact);
                        if (cfg.taskbarLeftAlign !== undefined) shellRoot.taskbarLeftAlign = Boolean(cfg.taskbarLeftAlign);
                        if (cfg.showRecommended !== undefined) shellRoot.showRecommended = Boolean(cfg.showRecommended);
                        if (cfg.showPhoneLink !== undefined) shellRoot.showPhoneLink = Boolean(cfg.showPhoneLink);
                        if (cfg.showBatteryPct !== undefined) shellRoot.showBatteryPct = Boolean(cfg.showBatteryPct);
                        if (cfg.wallpaperMode !== undefined) shellRoot.wallpaperMode = Number(cfg.wallpaperMode);
                    } catch (e) {}
                }
            }
        }
    }

    Timer {
        interval: 220
        running: true
        repeat: true
        onTriggered: {
            if (!statePoller.running) statePoller.running = true;
        }
    }

    // Reusable SVG Loader
    component WinSvg : Image {
        property string iconFile: "explorer.svg"
        Layout.preferredWidth: width
        Layout.preferredHeight: height
        Layout.maximumWidth: width
        Layout.maximumHeight: height
        source: shellRoot.assetDir + iconFile
        sourceSize.width: 96
        sourceSize.height: 96
        fillMode: Image.PreserveAspectFit
        smooth: true
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
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            color: "#040812"

            property int selectedDesktopIcon: -1

            Image {
                anchors.fill: parent
                cache: false
                source: shellRoot.wallpaperMode === 0
                        ? (shellRoot.wpDir + "win11-bloom-dark.jpg")
                        : (shellRoot.wallpaperMode === 1
                           ? (shellRoot.wpDir + "win11-bloom-light.jpg")
                           : (shellRoot.wpDir + "x64-monolith.jpg"))
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            // Rubberband Selection + Right-Click Context Menu Trigger
            MouseArea {
                id: desktopArea
                anchors.fill: parent
                anchors.bottomMargin: shellRoot.taskbarCompact ? 38 : 48
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                property real pressX: 0
                property real pressY: 0
                property bool dragging: false

                onPressed: (mouse) => {
                    shellRoot.closeAllPopups();
                    desktopWin.selectedDesktopIcon = -1;
                    if (mouse.button === Qt.LeftButton) {
                        pressX = mouse.x;
                        pressY = mouse.y;
                        dragging = true;
                    } else if (mouse.button === Qt.RightButton) {
                        shellRoot.ctxX = Math.min(mouse.x, desktopWin.width - 290);
                        shellRoot.ctxY = Math.min(mouse.y, desktopWin.height - 380);
                        shellRoot.ctxMenuOpen = true;
                    }
                }
                onPositionChanged: (mouse) => {
                    if (dragging) {
                        rubberBand.x = Math.min(pressX, mouse.x);
                        rubberBand.y = Math.min(pressY, mouse.y);
                        rubberBand.width = Math.abs(mouse.x - pressX);
                        rubberBand.height = Math.abs(mouse.y - pressY);
                    }
                }
                onReleased: {
                    dragging = false;
                    rubberBand.width = 0;
                    rubberBand.height = 0;
                }

                Rectangle {
                    id: rubberBand
                    visible: desktopArea.dragging && (width > 4 || height > 4)
                    color: "#380078d4"
                    border.color: "#0078d4"
                    border.width: 1
                }
            }

            // Desktop Icons Grid (Primary Monitor)
            Column {
                visible: desktopWin.isPrimary
                x: 12
                y: 12
                spacing: 6

                Repeater {
                    model: [
                        { title: "Este equipo",            icon: "thispc.svg",      cmd: "/usr/bin/x64-win11-app explorer 'Este equipo'" },
                        { title: "Papelera de\nreciclaje", icon: "trash-full.svg",  cmd: "/usr/bin/x64-win11-app explorer 'Escritorio'" },
                        { title: "Cristian",               icon: "folder-home.svg", cmd: "/usr/bin/x64-win11-app explorer 'Inicio'" },
                        { title: "Antigravity\nIDE",       icon: "antigravity.png", cmd: "/usr/bin/antigravity-ide" },
                        { title: "Microsoft Edge\n/ Web",  icon: "edge.svg",        cmd: "chromium" },
                        { title: "Tienda\nShelly",         icon: "store.svg",       cmd: "shelly" },
                        { title: "X64 Hello",              icon: "x64lios.png",     cmd: "x64-hello" },
                        { title: "Configuración\n26H2",    icon: "settings.svg",    cmd: "/usr/bin/x64-win11-app settings" }
                    ]

                    delegate: Rectangle {
                        width: 82
                        height: 82
                        radius: 3
                        color: desktopWin.selectedDesktopIcon === index ? "#38ffffff" : (dIconHov.containsMouse ? "#1fffffff" : "transparent")
                        border.color: desktopWin.selectedDesktopIcon === index ? "#55ffffff" : "transparent"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            WinSvg {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 42
                                height: 42
                                iconFile: modelData.icon
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 78
                                text: modelData.title
                                color: "#ffffff"
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                style: Text.Outline
                                styleColor: "#bb000000"
                            }
                        }

                        MouseArea {
                            id: dIconHov
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                shellRoot.closeAllPopups();
                                desktopWin.selectedDesktopIcon = index;
                            }
                            onDoubleClicked: {
                                shellRoot.closeAllPopups();
                                shellRoot.spawnCmd(modelData.cmd);
                            }
                        }
                    }
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
            color: "#ec181818"

            readonly property var toplevels: ToplevelManager.toplevels ? ToplevelManager.toplevels.values : []

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: "#28ffffff"
            }

            // [1] Left Weather Widget
            Rectangle {
                id: wthWidget
                visible: !shellRoot.taskbarLeftAlign && taskbarWin.width >= 900
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 145
                height: shellRoot.taskbarCompact ? 32 : 38
                radius: 5
                color: wthHov.containsMouse ? "#1fffffff" : "transparent"

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                    WinSvg { width: 24; height: 24; iconFile: "win11-weather.svg" }
                    Column {
                        Layout.fillWidth: true
                        Text { text: "22°C"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                        Text { visible: !shellRoot.taskbarCompact; text: "Mayormente despejado"; color: "#cccccc"; font.pixelSize: 10; elide: Text.ElideRight; width: 95 }
                    }
                }
                MouseArea { id: wthHov; anchors.fill: parent; hoverEnabled: true }
            }

            // [2] Centered (or Left-Aligned) Taskbar Icons + Running Wayland Windows
            Row {
                id: mainIconsRow
                readonly property bool autoCompactSearch: shellRoot.taskbarCompact || taskbarWin.width < 1180
                x: shellRoot.taskbarLeftAlign
                   ? 12
                   : Math.max(wthWidget.visible ? (wthWidget.x + wthWidget.width + 8) : 12,
                              Math.min((parent.width - width) / 2, rightTrayRow.x - width - 10))
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // WINDOWS 11 START BUTTON
                Rectangle {
                    width: shellRoot.taskbarCompact ? 34 : 40
                    height: shellRoot.taskbarCompact ? 34 : 40
                    radius: 4
                    color: (shellRoot.startOpen || startBtnHov.containsMouse) ? "#24ffffff" : "transparent"

                    WinSvg {
                        anchors.centerIn: parent
                        width: shellRoot.taskbarCompact ? 22 : 26
                        height: shellRoot.taskbarCompact ? 22 : 26
                        iconFile: "win11-start.svg"
                        scale: startBtnHov.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: startBtnHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !shellRoot.startOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.startOpen = next;
                        }
                    }
                }

                // Windows 11 Search Pill
                Rectangle {
                    width: mainIconsRow.autoCompactSearch ? (shellRoot.taskbarCompact ? 34 : 40) : 136
                    height: shellRoot.taskbarCompact ? 30 : 32
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: searchPillHov.containsMouse ? "#343434" : "#292929"
                    border.color: "#28ffffff"; border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: mainIconsRow.autoCompactSearch ? ((parent.width - 15) / 2) : 12
                        spacing: 8
                        WinSvg { width: 15; height: 15; iconFile: "search-app.svg" }
                        Text { visible: !mainIconsRow.autoCompactSearch; text: "Buscar"; color: "#d0d0d0"; font.pixelSize: 12; Layout.fillWidth: true }
                    }

                    MouseArea {
                        id: searchPillHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !shellRoot.startOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.startOpen = next;
                        }
                    }
                }

                // Pinned Applications
                Repeater {
                    model: [
                        { id: "explorer",    match: "explorer",    icon: "explorer.svg",    cmd: "/usr/bin/x64-win11-app explorer 'Este equipo'" },
                        { id: "chromium",    match: "chromium",    icon: "edge.svg",        cmd: "chromium" },
                        { id: "antigravity", match: "antigravity", icon: "antigravity.png", cmd: "/usr/bin/antigravity-ide" },
                        { id: "shelly",      match: "shelly",      icon: "store.svg",       cmd: "shelly" },
                        { id: "kitty",       match: "kitty",       icon: "terminal.svg",    cmd: "kitty" },
                        { id: "x64hello",    match: "x64-hello",   icon: "x64lios.png",     cmd: "x64-hello" },
                        { id: "settings",    match: "settings",    icon: "settings.svg",    cmd: "/usr/bin/x64-win11-app settings" }
                    ]

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
                        readonly property bool isFocused: matchedTop !== null && Boolean(matchedTop.activated)

                        color: (isFocused || tbHov.containsMouse) ? "#24ffffff" : "transparent"

                        WinSvg {
                            anchors.centerIn: parent
                            width: shellRoot.taskbarCompact ? 21 : 25
                            height: shellRoot.taskbarCompact ? 21 : 25
                            iconFile: modelData.icon
                            scale: tbHov.pressed ? 0.85 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        // Windows 11 Bottom Active Pill (16px active cyan #60CDFF, 6px background #8A8A8A)
                        Rectangle {
                            visible: tbAppBtn.isOpen
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tbAppBtn.isFocused ? 16 : 6
                            height: 3
                            radius: 1.5
                            color: tbAppBtn.isFocused ? "#60cdff" : "#8a8a8a"
                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: tbHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: (mouse) => {
                                shellRoot.closeAllPopups();
                                if (mouse.button === Qt.MiddleButton && tbAppBtn.matchedTop) {
                                    tbAppBtn.matchedTop.close();
                                } else if (tbAppBtn.matchedTop) {
                                    tbAppBtn.matchedTop.activate();
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
                        var pinnedKeys = ["explorer", "chromium", "antigravity", "shelly", "kitty", "x64-hello", "settings"];
                        var extra = [];
                        for (var i = 0; i < list.length; i++) {
                            var app = (list[i].appId || "").toLowerCase();
                            var ttl = (list[i].title || "").toLowerCase();
                            var isPinned = false;
                            for (var j = 0; j < pinnedKeys.length; j++) {
                                if (app.indexOf(pinnedKeys[j]) !== -1 || ttl.indexOf(pinnedKeys[j]) !== -1) {
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
                        readonly property bool isFocused: Boolean(modelData && modelData.activated)
                        readonly property string dynIcon: {
                            var a = ((modelData ? modelData.appId : "") || "").toLowerCase();
                            var t = ((modelData ? modelData.title : "") || "").toLowerCase();
                            if (a.indexOf("taskmgr") !== -1 || t.indexOf("tareas") !== -1) return "thispc.svg";
                            if (a.indexOf("discord") !== -1) return "discord.svg";
                            if (a.indexOf("steam") !== -1) return "steam.svg";
                            if (a.indexOf("calc") !== -1) return "calculator.svg";
                            if (a.indexOf("disk") !== -1) return "drive-c.svg";
                            if (a.indexOf("update") !== -1) return "update.svg";
                            if (a.indexOf("loupe") !== -1 || a.indexOf("image") !== -1) return "folder-images.svg";
                            return "windows.svg";
                        }
                        color: (isFocused || dynHov.containsMouse) ? "#24ffffff" : "transparent"

                        WinSvg {
                            anchors.centerIn: parent
                            width: shellRoot.taskbarCompact ? 21 : 25
                            height: shellRoot.taskbarCompact ? 21 : 25
                            iconFile: dynBtn.dynIcon
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: dynBtn.isFocused ? 16 : 6
                            height: 3
                            radius: 1.5
                            color: dynBtn.isFocused ? "#60cdff" : "#8a8a8a"
                        }

                        MouseArea {
                            id: dynHov
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            onClicked: (mouse) => {
                                shellRoot.closeAllPopups();
                                if (!dynBtn.modelData) return;
                                if (mouse.button === Qt.MiddleButton) dynBtn.modelData.close();
                                else dynBtn.modelData.activate();
                            }
                        }
                    }
                }
            }

            // [3] Right System Tray
            Row {
                id: rightTrayRow
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                // Live SystemTray Items (x64-update-tray, Discord, etc.)
                Repeater {
                    model: SystemTray.items
                    delegate: Rectangle {
                        required property var modelData
                        width: 26; height: shellRoot.taskbarCompact ? 32 : 38; radius: 4
                        color: sniHov.containsMouse ? "#1fffffff" : "transparent"
                        Image {
                            anchors.centerIn: parent; width: 15; height: 15
                            sourceSize.width: 30; sourceSize.height: 30
                            source: modelData.icon || ""
                            fillMode: Image.PreserveAspectFit
                        }
                        MouseArea {
                            id: sniHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) modelData.secondaryActivate();
                                else modelData.activate();
                            }
                        }
                    }
                }

                // Keyboard Layout (ESP / ES)
                Rectangle {
                    width: 36; height: shellRoot.taskbarCompact ? 32 : 38; radius: 4
                    color: kbHov.containsMouse ? "#1fffffff" : "transparent"
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: shellRoot.kbLayout === "ES" ? "ESP" : "ENG"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                        Text { visible: !shellRoot.taskbarCompact; anchors.horizontalCenter: parent.horizontalCenter; text: shellRoot.kbLayout; color: "#bbbbbb"; font.pixelSize: 9 }
                    }
                    MouseArea {
                        id: kbHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: shellRoot.kbLayout = (shellRoot.kbLayout === "ES" ? "US" : "ES")
                    }
                }

                // Unified Wi-Fi + Volume + 26H2 Color Battery & % Button
                Rectangle {
                    width: qsTrayRow.implicitWidth + 16
                    height: shellRoot.taskbarCompact ? 32 : 38
                    radius: 4
                    color: (shellRoot.quickSettingsOpen || qsBtnHov.containsMouse) ? "#24ffffff" : "transparent"

                    Row {
                        id: qsTrayRow
                        anchors.centerIn: parent
                        spacing: 7
                        WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; iconFile: "am-wireless-symbolic.svg" }
                        WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; iconFile: "audio-volume-high-symbolic.svg" }
                        WinSvg {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 19; height: 15
                            iconFile: shellRoot.qsBatterySaver ? "win11-battery-yellow.svg" : "win11-battery-green.svg"
                        }
                        Text {
                            visible: shellRoot.showBatteryPct
                            anchors.verticalCenter: parent.verticalCenter
                            text: "100%"
                            color: "#ffffff"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: qsBtnHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !shellRoot.quickSettingsOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.quickSettingsOpen = next;
                        }
                    }
                }

                // Windows 11 Clock & Date
                Rectangle {
                    width: 82
                    height: shellRoot.taskbarCompact ? 32 : 38
                    radius: 4
                    color: (shellRoot.calendarOpen || clkHov.containsMouse) ? "#24ffffff" : "transparent"

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        Text {
                            anchors.right: parent.right
                            text: Qt.formatTime(new Date(), "hh:mm")
                            color: "#ffffff"
                            font.pixelSize: 11
                        }
                        Text {
                            visible: !shellRoot.taskbarCompact
                            anchors.right: parent.right
                            text: Qt.formatDate(new Date(), "dd/MM/yyyy")
                            color: "#cccccc"
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: clkHov
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !shellRoot.calendarOpen;
                            shellRoot.closeAllPopups();
                            shellRoot.calendarOpen = next;
                        }
                    }
                }

                // Far-Right Show Desktop Sliver
                Rectangle {
                    width: 8; height: shellRoot.taskbarCompact ? 32 : 38
                    color: sdHov.containsMouse ? "#28ffffff" : "transparent"
                    Rectangle {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        width: 1; height: 20; color: "#33ffffff"
                    }
                    MouseArea {
                        id: sdHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: shellRoot.closeAllPopups()
                    }
                }
            }

            // Right-Click on Empty Taskbar -> Windows 11 Taskbar Menu
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    shellRoot.closeAllPopups();
                    shellRoot.taskbarCtxX = Math.max(12, Math.min(taskbarWin.width - 250, mouse.x - 110));
                    shellRoot.taskbarCtxOpen = true;
                }
            }
        }
    }

    // =========================================================================
    // LAYER 3: OVERLAY POPUPS (Start 26H2, Quick Settings, Calendar, Run, Lock)
    // =========================================================================
    PanelWindow {
        id: overlayWin
        visible: shellRoot.startOpen || shellRoot.quickSettingsOpen || shellRoot.calendarOpen ||
                 shellRoot.ctxMenuOpen || shellRoot.taskbarCtxOpen || shellRoot.runDialogOpen ||
                 shellRoot.lockScreenOpen

        WlrLayershell.namespace: "x64-win11-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: (shellRoot.startOpen || shellRoot.runDialogOpen || shellRoot.lockScreenOpen)
                                     ? WlrKeyboardFocus.OnDemand
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

        // 1. DESKTOP RIGHT-CLICK CONTEXT MENU
        Rectangle {
            visible: shellRoot.ctxMenuOpen
            x: shellRoot.ctxX
            y: shellRoot.ctxY
            width: 280
            height: 344
            radius: 8
            color: "#f4252525"
            border.color: "#38ffffff"
            border.width: 1

            Column {
                anchors.fill: parent; anchors.margins: 6; spacing: 2

                Repeater {
                    model: [
                        { icon: "explorer.svg",            label: "Abrir Explorador (Win + E)", cmd: "/usr/bin/x64-win11-app explorer 'Este equipo'" },
                        { icon: "view-refresh-symbolic.svg", label: "Actualizar escritorio",    cmd: "" },
                        { icon: "thispc.svg",              label: "Administrador de tareas",    cmd: "/usr/bin/x64-win11-app taskmgr" },
                        { icon: "settings.svg",            label: "Configuración (Win + I)",    cmd: "/usr/bin/x64-win11-app settings" },
                        { icon: "windows.svg",             label: "Personalizar (26H2)",        cmd: "/usr/bin/x64-win11-app settings 'Personalización (26H2)'" },
                        { icon: "folder-images.svg",       label: "Cambiar fondo 4K Bloom",     cmd: "__wp__" },
                        { icon: "terminal.svg",            label: "Abrir en Terminal (Kitty)",  cmd: "kitty" },
                        { icon: "antigravity.png",         label: "Abrir Antigravity IDE",      cmd: "/usr/bin/antigravity-ide" },
                        { icon: "terminal.svg",            label: "Ejecutar (Win + R 26H2)",    cmd: "__run__" },
                        { icon: "x64lios.png",             label: "Abrir X64 Hello",            cmd: "x64-hello" }
                    ]

                    delegate: Rectangle {
                        width: 268; height: 32; radius: 5
                        color: ctxHov.containsMouse ? "#35ffffff" : "transparent"

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                            WinSvg { width: 16; height: 16; iconFile: modelData.icon }
                            Text { text: modelData.label; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                        }

                        MouseArea {
                            id: ctxHov; anchors.fill: parent; hoverEnabled: true
                            onClicked: {
                                shellRoot.ctxMenuOpen = false;
                                if (modelData.cmd === "__wp__") {
                                    var nextWp = (shellRoot.wallpaperMode + 1) % 3;
                                    shellRoot.wallpaperMode = nextWp;
                                    shellRoot.saveConfigKey("wallpaperMode", String(nextWp));
                                } else if (modelData.cmd === "__run__") {
                                    shellRoot.runDialogOpen = true;
                                } else if (modelData.cmd !== "") {
                                    shellRoot.spawnCmd(modelData.cmd);
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. TASKBAR RIGHT-CLICK MENU
        Rectangle {
            visible: shellRoot.taskbarCtxOpen
            x: shellRoot.taskbarCtxX
            y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 8
            width: 240
            height: 76
            radius: 8
            color: "#f4252525"
            border.color: "#38ffffff"
            border.width: 1

            Column {
                anchors.fill: parent; anchors.margins: 6; spacing: 2
                Rectangle {
                    width: 228; height: 31; radius: 5
                    color: tbCtx1.containsMouse ? "#35ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                        WinSvg { width: 16; height: 16; iconFile: "thispc.svg" }
                        Text { text: "Administrador de tareas"; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: tbCtx1; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            shellRoot.taskbarCtxOpen = false;
                            shellRoot.spawnCmd("/usr/bin/x64-win11-app taskmgr");
                        }
                    }
                }
                Rectangle {
                    width: 228; height: 31; radius: 5
                    color: tbCtx2.containsMouse ? "#35ffffff" : "transparent"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                        WinSvg { width: 16; height: 16; iconFile: "settings.svg" }
                        Text { text: "Configuración de la barra"; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
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

        // 3. WINDOWS 11 26H2 UNIFIED START MENU + PHONE LINK SIDEBAR
        Item {
            width: shellRoot.showPhoneLink ? 875 : 640
            height: 690
            x: shellRoot.taskbarLeftAlign ? 12 : ((overlayWin.width - width) / 2)
            y: overlayWin.height - height - (shellRoot.taskbarCompact ? 38 : 48) - 12
            visible: shellRoot.startOpen

            Row {
                anchors.fill: parent
                spacing: 10

                // [A] Main Start Menu Card (640x690)
                Rectangle {
                    width: 640
                    height: 690
                    radius: 8
                    color: "#f4202020"
                    border.color: "#38ffffff"
                    border.width: 1

                    MouseArea { anchors.fill: parent }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Top Search Bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74

                            Rectangle {
                                anchors.centerIn: parent
                                width: 584; height: 38; radius: 19
                                color: "#171717"; border.color: "#60cdff"; border.width: 1

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                                    WinSvg { width: 16; height: 16; iconFile: "search-app.svg" }
                                    TextInput {
                                        id: startSearchInput
                                        Layout.fillWidth: true; color: "#ffffff"; font.pixelSize: 13
                                        text: shellRoot.searchQuery
                                        onTextChanged: shellRoot.searchQuery = text
                                        Text {
                                            visible: startSearchInput.text === ""
                                            text: "Buscar aplicaciones, configuración y documentos"
                                            color: "#9e9e9e"; font.pixelSize: 13
                                        }
                                    }
                                }
                            }
                        }

                        // 26H2 Single-Scrollable Content
                        Flickable {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentWidth: width; contentHeight: startScrollCol.implicitHeight + 24; clip: true

                            Column {
                                id: startScrollCol
                                x: 28; width: 584; spacing: 18

                                RowLayout {
                                    width: 584
                                    Text { text: "Anclados"; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 155; height: 24; radius: 4; color: "#2b2b2b"; border.color: "#22ffffff"
                                        Text {
                                            anchors.centerIn: parent
                                            text: shellRoot.showRecommended ? "Ocultar Recomendado" : "Mostrar Recomendado"
                                            color: "#60cdff"; font.pixelSize: 10
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var nextRec = !shellRoot.showRecommended;
                                                shellRoot.showRecommended = nextRec;
                                                shellRoot.saveConfigKey("showRecommended", nextRec ? "true" : "false");
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    width: 584; columns: 6; rowSpacing: 10; columnSpacing: 8
                                    Repeater {
                                        model: [
                                            { name: "Explorador",    icon: "explorer.svg",        cmd: "/usr/bin/x64-win11-app explorer 'Este equipo'" },
                                            { name: "Antigravity",   icon: "antigravity.png",     cmd: "/usr/bin/antigravity-ide" },
                                            { name: "Edge / Web",    icon: "edge.svg",            cmd: "chromium" },
                                            { name: "Tienda Shelly", icon: "store.svg",           cmd: "shelly" },
                                            { name: "Configuración", icon: "settings.svg",        cmd: "/usr/bin/x64-win11-app settings" },
                                            { name: "X64 Hello",     icon: "x64lios.png",         cmd: "x64-hello" },
                                            { name: "X64 Update",    icon: "update.svg",          cmd: "x64-update" },
                                            { name: "Terminal",      icon: "terminal.svg",        cmd: "kitty" },
                                            { name: "Admin. tareas", icon: "thispc.svg",          cmd: "/usr/bin/x64-win11-app taskmgr" },
                                            { name: "Steam",         icon: "steam.svg",           cmd: "steam" },
                                            { name: "Discord",       icon: "discord.svg",         cmd: "discord" },
                                            { name: "Calculadora",   icon: "calculator.svg",      cmd: "gnome-calculator" },
                                            { name: "Este equipo",   icon: "thispc.svg",          cmd: "/usr/bin/x64-win11-app explorer 'Este equipo'" },
                                            { name: "Discos NVMe",   icon: "drive-c.svg",         cmd: "gnome-disks" },
                                            { name: "Descargas",     icon: "folder-download.svg", cmd: "/usr/bin/x64-win11-app explorer 'Descargas'" },
                                            { name: "Documentos",    icon: "folder-documents.svg",cmd: "/usr/bin/x64-win11-app explorer 'Documentos'" },
                                            { name: "Imágenes",      icon: "folder-images.svg",   cmd: "/usr/bin/x64-win11-app explorer 'Imágenes'" },
                                            { name: "Consola X64",   icon: "x64lios.png",         cmd: "kitty -e x64-dashboard" }
                                        ]

                                        delegate: Rectangle {
                                            visible: shellRoot.searchQuery.trim() === "" || modelData.name.toLowerCase().indexOf(shellRoot.searchQuery.trim().toLowerCase()) !== -1
                                            width: 90; height: 76; radius: 6
                                            color: appHov.containsMouse ? "#28ffffff" : "transparent"
                                            Column {
                                                anchors.centerIn: parent; spacing: 6
                                                WinSvg { anchors.horizontalCenter: parent.horizontalCenter; width: 34; height: 34; iconFile: modelData.icon }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 84; horizontalAlignment: Text.AlignHCenter
                                                    text: modelData.name; color: "#f3f4f6"; font.pixelSize: 11; elide: Text.ElideRight
                                                }
                                            }
                                            MouseArea {
                                                id: appHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    shellRoot.startOpen = false;
                                                    shellRoot.spawnCmd(modelData.cmd);
                                                }
                                            }
                                        }
                                    }
                                }

                                // Unified "Todas" Section with 26H2 3-View Switcher
                                RowLayout {
                                    width: 584
                                    Text { text: "Todas"; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Row {
                                        spacing: 4
                                        Repeater {
                                            model: [
                                                { id: "categories", label: "Categorías" },
                                                { id: "grid",       label: "Cuadrícula" },
                                                { id: "list",       label: "Lista" }
                                            ]
                                            delegate: Rectangle {
                                                width: 78; height: 24; radius: 4
                                                color: shellRoot.startAllViewMode === modelData.id ? "#0078d4" : "#2b2b2b"
                                                border.color: "#22ffffff"
                                                Text { anchors.centerIn: parent; text: modelData.label; color: "#ffffff"; font.pixelSize: 10; font.bold: shellRoot.startAllViewMode === modelData.id }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.startAllViewMode = modelData.id }
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    width: 584; columns: 2; rowSpacing: 12; columnSpacing: 14
                                    visible: shellRoot.startAllViewMode === "categories"
                                    Repeater {
                                        model: [
                                            { cat: "Sistema y Motor X64", items: [
                                                { name: "X64 Hello",     icon: "x64lios.png",  cmd: "x64-hello" },
                                                { name: "Configuración", icon: "settings.svg", cmd: "/usr/bin/x64-win11-app settings" },
                                                { name: "Terminal",      icon: "terminal.svg", cmd: "kitty" },
                                                { name: "Tienda Shelly", icon: "store.svg",    cmd: "shelly" }
                                            ]},
                                            { cat: "Desarrollo y Juegos", items: [
                                                { name: "Antigravity",   icon: "antigravity.png", cmd: "/usr/bin/antigravity-ide" },
                                                { name: "Steam Gaming",  icon: "steam.svg",       cmd: "steam" },
                                                { name: "Discord",       icon: "discord.svg",     cmd: "discord" },
                                                { name: "X64 Dashboard", icon: "x64lios.png",     cmd: "kitty -e x64-dashboard" }
                                            ]}
                                        ]
                                        delegate: Rectangle {
                                            width: 285; height: 112; radius: 8; color: "#272727"; border.color: "#22ffffff"
                                            Column {
                                                anchors.fill: parent; anchors.margins: 10; spacing: 8
                                                Text { text: modelData.cat; color: "#60cdff"; font.pixelSize: 11; font.bold: true }
                                                Grid {
                                                    columns: 2; rowSpacing: 8; columnSpacing: 10
                                                    Repeater {
                                                        model: modelData.items
                                                        delegate: Item {
                                                            width: 126; height: 26
                                                            Row {
                                                                spacing: 6
                                                                WinSvg { width: 22; height: 22; iconFile: modelData.icon }
                                                                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: "#e5e7eb"; font.pixelSize: 11; elide: Text.ElideRight; width: 96 }
                                                            }
                                                            MouseArea {
                                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                                onClicked: { shellRoot.startOpen = false; shellRoot.spawnCmd(modelData.cmd); }
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

                        // Bottom Profile & Power Footer
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 58; radius: 8; color: "#171717"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 28; anchors.rightMargin: 28
                                Row {
                                    spacing: 10
                                    WinSvg { width: 28; height: 28; iconFile: "x64lios.png" }
                                    Column {
                                        Text { text: "Cristian"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                        Text { text: "X64 LIOS • Windows 11 26H2"; color: "#888888"; font.pixelSize: 10 }
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Rectangle {
                                    width: 38; height: 38; radius: 6
                                    color: pwrHov.containsMouse ? "#28ffffff" : "transparent"
                                    WinSvg { anchors.centerIn: parent; width: 17; height: 17; iconFile: "system-shutdown-symbolic.svg" }
                                    MouseArea {
                                        id: pwrHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: shellRoot.powerPopupOpen = !shellRoot.powerPopupOpen
                                    }
                                }
                            }
                        }
                    }

                    // Power Menu Popup
                    Rectangle {
                        visible: shellRoot.powerPopupOpen
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.rightMargin: 22; anchors.bottomMargin: 54
                        width: 195; height: 170; radius: 8; color: "#2b2b2b"; border.color: "#38ffffff"

                        Column {
                            anchors.fill: parent; anchors.margins: 6; spacing: 2
                            Repeater {
                                model: [
                                    { label: "Bloquear (Win + L)",    act: "lock" },
                                    { label: "Cambiar Escritorio X64",act: "dashboard" },
                                    { label: "Cerrar sesión",         act: "logout" },
                                    { label: "Reiniciar",             act: "reboot" },
                                    { label: "Apagar",                act: "poweroff" }
                                ]
                                delegate: Rectangle {
                                    width: 183; height: 30; radius: 5
                                    color: pSubHov.containsMouse ? "#38ffffff" : "transparent"
                                    Text { anchors.verticalCenter: parent.verticalCenter; x: 12; text: modelData.label; color: "#ffffff"; font.pixelSize: 12 }
                                    MouseArea {
                                        id: pSubHov; anchors.fill: parent; hoverEnabled: true
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

                // [B] 26H2 Phone Link Companion Panel
                Rectangle {
                    visible: shellRoot.showPhoneLink
                    width: 225; height: 690; radius: 8; color: "#f21d1d1d"; border.color: "#38ffffff"; border.width: 1
                    MouseArea { anchors.fill: parent }
                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 14
                        RowLayout {
                            width: 193
                            WinSvg { width: 20; height: 20; iconFile: "phone.svg" }
                            Text { text: "Enlace Móvil (26H2)"; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                            Rectangle { width: 8; height: 8; radius: 4; color: "#6ccb5f" }
                        }
                        Rectangle {
                            width: 193; height: 78; radius: 8; color: "#282828"; border.color: "#22ffffff"
                            Column {
                                anchors.fill: parent; anchors.margins: 10; spacing: 6
                                Text { text: "KDE Connect Activo"; color: "#60cdff"; font.pixelSize: 12; font.bold: true }
                                Text { text: "UFW 1714:1764 UDP/TCP Abierto"; color: "#aaaaaa"; font.pixelSize: 10 }
                                RowLayout {
                                    width: 173
                                    WinSvg { width: 18; height: 14; iconFile: "win11-battery-green.svg" }
                                    Text { text: "Conectado • Red Local"; color: "#d0d0d0"; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. WINDOWS 11 QUICK SETTINGS (Win + A)
        Rectangle {
            visible: shellRoot.quickSettingsOpen
            width: 360; height: 390
            x: overlayWin.width - width - 12
            y: overlayWin.height - height - (shellRoot.taskbarCompact ? 38 : 48) - 12
            radius: 8; color: "#f4222222"; border.color: "#38ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent; anchors.margins: 20; spacing: 18
                Grid {
                    columns: 3; rowSpacing: 14; columnSpacing: 12
                    Repeater {
                        model: [
                            { label: "Wi-Fi",         icon: "am-wireless-symbolic.svg",      active: shellRoot.qsWifi },
                            { label: "Bluetooth",     icon: "bluetooth-active-symbolic.svg", active: shellRoot.qsBt },
                            { label: "Gaming X64",    icon: "gaming.svg",                    active: shellRoot.qsGaming },
                            { label: "Luz nocturna",  icon: "night-light-symbolic.svg",      active: shellRoot.qsNightLight },
                            { label: "Ahorro energía",icon: "win11-battery-green.svg",       active: shellRoot.qsBatterySaver },
                            { label: "Configuración", icon: "settings.svg",                  active: false }
                        ]
                        delegate: Column {
                            spacing: 5
                            Rectangle {
                                width: 100; height: 48; radius: 6
                                color: modelData.active ? "#0078d4" : "#2d2d2d"
                                border.color: "#22ffffff"
                                WinSvg { anchors.centerIn: parent; width: 18; height: 18; iconFile: modelData.icon }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (index === 5) {
                                            shellRoot.closeAllPopups();
                                            shellRoot.spawnCmd("/usr/bin/x64-win11-app settings");
                                        }
                                    }
                                }
                            }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#e0e0e0"; font.pixelSize: 11 }
                        }
                    }
                }

                // Volume Slider (Real PipeWire control)
                RowLayout {
                    width: 320; spacing: 12
                    WinSvg { width: 18; height: 18; iconFile: "audio-volume-high-symbolic.svg" }
                    Slider {
                        Layout.fillWidth: true; from: 0; to: 100; value: shellRoot.sinkVolPct
                        onMoved: shellRoot.spawnCmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(value) + "%")
                    }
                }

                Rectangle { width: 320; height: 1; color: "#22ffffff" }

                RowLayout {
                    width: 320
                    WinSvg { width: 20; height: 16; iconFile: "win11-battery-green.svg" }
                    Text { text: "100% • CA (scx_lavd + FalconD)"; color: "#cccccc"; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                    WinSvg {
                        width: 18; height: 18; iconFile: "settings.svg"
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { shellRoot.closeAllPopups(); shellRoot.spawnCmd("/usr/bin/x64-win11-app settings"); }
                        }
                    }
                }
            }
        }

        // 5. WINDOWS 11 TWO-CARD NOTIFICATION CENTER + CALENDAR
        Column {
            visible: shellRoot.calendarOpen
            width: 340
            x: overlayWin.width - width - 12
            y: overlayWin.height - implicitHeight - (shellRoot.taskbarCompact ? 38 : 48) - 12
            spacing: 10

            Rectangle {
                width: 340; height: 155; radius: 8; color: "#f4202020"; border.color: "#38ffffff"; border.width: 1
                MouseArea { anchors.fill: parent }
                Column {
                    anchors.fill: parent; anchors.margins: 16; spacing: 10
                    RowLayout {
                        width: 308
                        Text { text: "Notificaciones"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: "Borrar todo"; color: "#60cdff"; font.pixelSize: 11 }
                    }
                    Rectangle {
                        width: 308; height: 82; radius: 6; color: "#2b2b2b"
                        Column {
                            anchors.fill: parent; anchors.margins: 10; spacing: 4
                            Text { text: "X64 Gaming Engine • Windows 11 26H2"; color: "#60cdff"; font.pixelSize: 11; font.bold: true }
                            Text { width: 288; text: "Planificador scx_lavd + FalconD + dmemcg-booster activos en segundo plano."; color: "#dddddd"; font.pixelSize: 11; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }

            Rectangle {
                width: 340; height: 280; radius: 8; color: "#f4202020"; border.color: "#38ffffff"; border.width: 1
                MouseArea { anchors.fill: parent }
                Column {
                    anchors.fill: parent; anchors.margins: 16; spacing: 12
                    Text { text: Qt.formatDate(new Date(), "dddd, d 'de' MMMM 'de' yyyy"); color: "#60cdff"; font.pixelSize: 13; font.bold: true }
                    Grid {
                        columns: 7; spacing: 8
                        Repeater {
                            model: ["L", "M", "X", "J", "V", "S", "D",
                                    "2", "3", "4", "5", "6", "7", "8",
                                    "9", "10","11","12","13","14","15",
                                    "16","17","18","19","20","21","22",
                                    "23","24","25","26","27","28","29"]
                            delegate: Rectangle {
                                width: 35; height: 30; radius: 15
                                color: modelData === "22" ? "#60cdff" : "transparent"
                                Text { anchors.centerIn: parent; text: modelData; color: modelData === "22" ? "#000000" : "#ffffff"; font.pixelSize: 11; font.bold: modelData === "22" }
                            }
                        }
                    }
                }
            }
        }

        // 6. WINDOWS 11 26H2 MODERN RUN DIALOG ("Win + R")
        Rectangle {
            visible: shellRoot.runDialogOpen
            x: 24
            y: overlayWin.height - (shellRoot.taskbarCompact ? 38 : 48) - height - 16
            width: 425; height: 205; radius: 8; color: "#f5202020"; border.color: "#44ffffff"; border.width: 1
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent; spacing: 0
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 34; radius: 8; color: "#1a1a1a"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10
                        WinSvg { width: 16; height: 16; iconFile: "terminal.svg" }
                        Text { text: "Ejecutar (Windows 11 26H2)"; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                        WinSvg {
                            width: 13; height: 13; iconFile: "window-close-symbolic.svg"
                            MouseArea { anchors.fill: parent; onClicked: shellRoot.runDialogOpen = false }
                        }
                    }
                }
                Column {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 16; spacing: 12
                    RowLayout {
                        width: 393; spacing: 12
                        WinSvg { width: 36; height: 36; iconFile: "windows.svg" }
                        Text { Layout.fillWidth: true; text: "Escriba el nombre de un programa, carpeta o documento y Windows 11 Edition lo abrirá."; color: "#d0d0d0"; font.pixelSize: 11; wrapMode: Text.WordWrap }
                    }
                    RowLayout {
                        width: 393; spacing: 10
                        Text { text: "Abrir:"; color: "#ffffff"; font.pixelSize: 12 }
                        Rectangle {
                            Layout.fillWidth: true; height: 32; radius: 5; color: "#141414"; border.color: "#60cdff"
                            TextInput {
                                id: runInput
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter; color: "#ffffff"; font.pixelSize: 12
                                text: "antigravity-ide"
                                onAccepted: { shellRoot.spawnCmd(runInput.text); shellRoot.runDialogOpen = false; }
                            }
                        }
                    }
                    RowLayout {
                        width: 393; spacing: 8
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 90; height: 30; radius: 5; color: "#0078d4"
                            Text { anchors.centerIn: parent; text: "Aceptar"; color: "#ffffff"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shellRoot.spawnCmd(runInput.text); shellRoot.runDialogOpen = false; } }
                        }
                        Rectangle {
                            width: 90; height: 30; radius: 5; color: "#2d2d2d"; border.color: "#22ffffff"
                            Text { anchors.centerIn: parent; text: "Cancelar"; color: "#ffffff"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: shellRoot.runDialogOpen = false }
                        }
                    }
                }
            }
        }

        // 7. WINDOWS 11 26H2 LOCK SCREEN ("Win + L")
        Rectangle {
            visible: shellRoot.lockScreenOpen
            anchors.fill: parent
            color: "#000000"

            Image {
                anchors.fill: parent; cache: false
                source: shellRoot.wpDir + "win11-bloom-dark.jpg"
                fillMode: Image.PreserveAspectCrop
            }

            Rectangle {
                anchors.fill: parent
                color: shellRoot.lockPromptOpen ? "#aa080d1a" : "#33000000"
            }

            Column {
                visible: !shellRoot.lockPromptOpen
                anchors.horizontalCenter: parent.horizontalCenter
                y: 110; spacing: 6
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatTime(new Date(), "hh:mm"); color: "#ffffff"; font.pixelSize: 88; font.bold: true }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDate(new Date(), "dddd, d 'de' MMMM"); color: "#f3f4f6"; font.pixelSize: 22 }
                Item { width: 1; height: 260 }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Haz clic en cualquier lugar para iniciar sesión"; color: "#cccccc"; font.pixelSize: 13 }
            }

            Column {
                visible: shellRoot.lockPromptOpen
                anchors.centerIn: parent; spacing: 16
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 116; height: 116; radius: 58; color: "#22ffffff"; border.color: "#60cdff"; border.width: 2
                    WinSvg { anchors.centerIn: parent; width: 72; height: 72; iconFile: "x64lios.png" }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Cristian"; color: "#ffffff"; font.pixelSize: 24; font.bold: true }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 180; height: 36; radius: 5; color: "#0078d4"
                    Text { anchors.centerIn: parent; text: "Iniciar sesión"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { shellRoot.lockScreenOpen = false; shellRoot.lockPromptOpen = false; } }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !shellRoot.lockPromptOpen
                onClicked: shellRoot.lockPromptOpen = true
            }
        }
    }
}
