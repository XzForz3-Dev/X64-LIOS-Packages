import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 1600
    height: 920

    readonly property string assetDir: "file:///home/qqqq/Proyectos/X64-LIOS-Packages/x64-win11-settings/assets/icons/"
    readonly property string wpDir: "file:///home/qqqq/Proyectos/X64-LIOS-Packages/x64-win11-settings/assets/wallpapers/"

    // =========================================================================
    // WINDOWS 11 26H2 GLOBAL STATE
    // =========================================================================
    property bool startOpen: false
    property bool quickSettingsOpen: false
    property bool calendarOpen: false
    property bool trayFlyoutOpen: false
    property bool powerPopupOpen: false
    property bool ctxMenuOpen: false
    property bool runDialogOpen: false
    property real ctxX: 200
    property real ctxY: 200

    // 26H2 Specific Features
    property string startAllViewMode: "categories" // "categories" | "grid" | "list"
    property bool showRecommended: false           // 26H2 allows hiding Recommended completely!
    property bool showPhoneLink: true              // 26H2 Phone Link / KDE Connect companion panel
    property bool taskbarCompact: false            // 26H2 Small Taskbar Mode (38px vs 48px)
    property bool taskbarLeftAlign: false          // Centered vs Left alignment
    property bool showBatteryPct: true             // 26H2 Battery % + Color-coded battery icon
    property int wallpaperMode: 0                  // 0 = Official Win11 Dark Bloom, 1 = Official Win11 Light Bloom, 2 = X64 Monolith
    property string kbLayout: "ES"
    property string searchQuery: ""

    // Hover Peek on Taskbar
    property string hoveredTaskId: ""
    property real hoveredTaskX: 0

    // Windows state
    property bool explorerOpen: true
    property bool explorerMinimized: false
    property bool explorerMaximized: false
    property bool explorerFocused: true
    property string explorerSection: "Este equipo"
    property string explorerRealPath: "Este equipo"
    property string explorerMode: "thispc"
    property var explorerItems: []
    property var explorerDrives: []
    property int explorerItemCount: 8
    property string explorerSortBy: "name"
    property var explorerHistory: ["Este equipo"]
    property int explorerHistoryIdx: 0
    property var explorerTabs: ["Este equipo"]
    property int activeTabIndex: 0
    property bool newMenuOpen: false
    property bool lockScreenOpen: false
    property bool lockPromptOpen: false
    property var sysInfo: ({ "user": "Cristian", "hostname": "x64-pc", "cpu": "AMD Ryzen / Intel", "ram": "64 GB", "kernel": "7.3.5-cachyos", "sched": "scx_lavd" })

    function refreshExplorer() {
        try {
            explorerDrives = JSON.parse(bridge.getDrivesJson());
            var res = JSON.parse(bridge.listDirectoryJson(explorerSection, explorerSortBy));
            explorerMode = res.mode;
            explorerRealPath = res.path;
            explorerItems = res.items;
            explorerItemCount = res.count;
        } catch (e) {}
    }

    function navigateExplorer(target, pushHistory) {
        explorerSection = target;
        var tabsCopy = explorerTabs.slice();
        tabsCopy[activeTabIndex] = target;
        explorerTabs = tabsCopy;
        if (pushHistory !== false) {
            var h = explorerHistory.slice(0, explorerHistoryIdx + 1);
            h.push(target);
            explorerHistory = h;
            explorerHistoryIdx = h.length - 1;
        }
        refreshExplorer();
    }

    Component.onCompleted: {
        try {
            sysInfo = JSON.parse(bridge.getSystemTelemetryJson());
        } catch (e) {}
        refreshExplorer();
    }

    property bool settingsOpen: false
    property bool settingsMinimized: false
    property bool settingsMaximized: false
    property bool settingsFocused: false
    property string settingsPage: "Personalización (26H2)"

    property bool taskMgrOpen: false
    property bool taskMgrFocused: false
    property bool taskbarCtxOpen: false
    property real taskbarCtxX: 400

    Timer {
        interval: 2000
        running: root.taskMgrOpen || root.settingsOpen
        repeat: true
        onTriggered: {
            try {
                root.sysInfo = JSON.parse(bridge.getSystemTelemetryJson());
            } catch (e) {}
        }
    }

    // Quick Settings (Win + A) state & sub-view ("main" | "wifi" | "bt")
    property string qsSubView: "main"
    property bool qsWifi: true
    property bool qsBt: true
    property bool qsGaming: true
    property bool qsNightLight: false
    property bool qsBatterySaver: false
    property bool qsDnd: false
    property real qsVolume: 82
    property real qsBrightness: 92

    property int selectedDesktopIcon: -1

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

    // Authentic Win11 SVG Icon Loader (Fixed sourceSize + Layout dimensions to prevent binding loop)
    component WinSvg : Image {
        property string iconFile: "explorer.svg"
        Layout.preferredWidth: width
        Layout.preferredHeight: height
        Layout.maximumWidth: width
        Layout.maximumHeight: height
        source: root.assetDir + iconFile
        sourceSize.width: 96
        sourceSize.height: 96
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    // Drop Shadow Backdrop for Windows 11 Floating Surfaces
    component WinShadow : Rectangle {
        anchors.fill: parent
        anchors.margins: -8
        anchors.topMargin: -4
        anchors.bottomMargin: -12
        radius: parent.radius + 6
        color: "#55000000"
        z: -1
    }

    // =========================================================================
    // 1. REAL 4K WINDOWS 11 BLOOM WALLPAPER LAYER
    // =========================================================================
    Rectangle {
        anchors.fill: parent
        color: "#040812"

        Image {
            anchors.fill: parent
            cache: false
            source: root.wallpaperMode === 0
                    ? (root.wpDir + "win11-bloom-dark.jpg")
                    : (root.wallpaperMode === 1
                       ? (root.wpDir + "win11-bloom-light.jpg")
                       : "file:///usr/share/backgrounds/x64-lios/01-monolith.jpg")
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }

        // Desktop Surface (Rubberband Selection + Right-Click Win11 Context Menu)
        MouseArea {
            id: desktopArea
            anchors.fill: parent
            anchors.bottomMargin: root.taskbarCompact ? 38 : 48
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property real pressX: 0
            property real pressY: 0
            property bool dragging: false

            onPressed: (mouse) => {
                root.closeAllPopups();
                root.selectedDesktopIcon = -1;
                if (mouse.button === Qt.LeftButton) {
                    pressX = mouse.x;
                    pressY = mouse.y;
                    dragging = true;
                } else if (mouse.button === Qt.RightButton) {
                    root.ctxX = Math.min(mouse.x, root.width - 285);
                    root.ctxY = Math.min(mouse.y, root.height - 420);
                    root.ctxMenuOpen = true;
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

        // =====================================================================
        // 2. DESKTOP ICONS (100% Authentic Win11-icon-theme SVGs)
        // =====================================================================
        Column {
            x: 12
            y: 12
            spacing: 6

            Repeater {
                model: [
                    { title: "Este equipo", icon: "thispc.svg", action: "explorer" },
                    { title: "Papelera de\nreciclaje", icon: "trash-full.svg", action: "trash" },
                    { title: "Cristian", icon: "folder-home.svg", action: "home" },
                    { title: "Red", icon: "network.svg", action: "network" },
                    { title: "Microsoft Edge\n/ Chromium", icon: "edge.svg", action: "chromium" },
                    { title: "Tienda\nShelly", icon: "store.svg", action: "shelly" },
                    { title: "X64 Hello", icon: "x64lios.png", action: "x64hello" },
                    { title: "Configuración", icon: "settings.svg", action: "settings" }
                ]

                delegate: Rectangle {
                    width: 82
                    height: 82
                    radius: 3
                    color: root.selectedDesktopIcon === index ? "#38ffffff" : (dIconHov.containsMouse ? "#1fffffff" : "transparent")
                    border.color: root.selectedDesktopIcon === index ? "#55ffffff" : "transparent"
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
                            root.closeAllPopups();
                            root.selectedDesktopIcon = index;
                        }
                        onDoubleClicked: {
                            root.closeAllPopups();
                            if (modelData.action === "explorer" || modelData.action === "home" || modelData.action === "trash" || modelData.action === "network") {
                                root.explorerSection = modelData.action === "home" ? "Cristian" : (modelData.action === "trash" ? "Papelera de reciclaje" : (modelData.action === "network" ? "Red" : "Este equipo"));
                                root.explorerOpen = true;
                                root.explorerMinimized = false;
                                root.explorerFocused = true;
                                root.settingsFocused = false;
                            } else if (modelData.action === "settings") {
                                root.settingsOpen = true;
                                root.settingsMinimized = false;
                                root.settingsFocused = true;
                                root.explorerFocused = false;
                            } else if (modelData.action === "x64hello") {
                                bridge.launchRealApp("x64-hello");
                            } else if (modelData.action === "shelly") {
                                bridge.launchRealApp("shelly");
                            } else if (modelData.action === "chromium") {
                                bridge.launchRealApp("chromium");
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // LIVE HOT-RELOAD STUDIO HUD (Top-Right Compact Floating Pill)
        // =====================================================================
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            width: hudRow.implicitWidth + 20
            height: 32
            radius: 6
            color: "#d9191919"
            border.color: "#3860cdff"
            border.width: 1
            z: 999

            RowLayout {
                id: hudRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle { width: 7; height: 7; radius: 3.5; color: "#6ccb5f" }

                Text {
                    text: "Windows 11 26H2 (Activos Oficiales SVG + 4K Bloom)"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                }

                Rectangle {
                    width: 98; height: 22; radius: 4
                    color: root.taskbarCompact ? "#0078d4" : "#2a2a2a"
                    border.color: "#33ffffff"
                    Text { anchors.centerIn: parent; text: root.taskbarCompact ? "Barra: 38px" : "Barra: 48px"; color: "#ffffff"; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.taskbarCompact = !root.taskbarCompact }
                }

                Rectangle {
                    width: 96; height: 22; radius: 4
                    color: root.taskbarLeftAlign ? "#0078d4" : "#2a2a2a"
                    border.color: "#33ffffff"
                    Text { anchors.centerIn: parent; text: root.taskbarLeftAlign ? "Alinear: Izq" : "Alinear: Centro"; color: "#ffffff"; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.taskbarLeftAlign = !root.taskbarLeftAlign }
                }

                Rectangle {
                    width: 66; height: 22; radius: 4; color: "#2a2a2a"; border.color: "#33ffffff"
                    Text { anchors.centerIn: parent; text: "Win + R"; color: "#60cdff"; font.pixelSize: 10; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.runDialogOpen = !root.runDialogOpen }
                }

                Rectangle {
                    width: 90; height: 22; radius: 4; color: "#2a2a2a"; border.color: "#33ffffff"
                    Text { anchors.centerIn: parent; text: root.wallpaperMode === 0 ? "Bloom Oscuro" : (root.wallpaperMode === 1 ? "Bloom Claro" : "X64 Monolith"); color: "#60cdff"; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.wallpaperMode = (root.wallpaperMode + 1) % 3 }
                }

                Rectangle {
                    width: 58; height: 22; radius: 4
                    color: exitHov.containsMouse ? "#c42b1c" : "#7f1d1d"
                    Text { anchors.centerIn: parent; text: "✕ Salir"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                    MouseArea { id: exitHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bridge.quitPreview() }
                }
            }
        }

        // =====================================================================
        // 3. WINDOWS 11 26H2 FILE EXPLORER WINDOW ("Explorador de archivos")
        // =====================================================================
        Rectangle {
            id: explorerWin
            visible: root.explorerOpen && !root.explorerMinimized
            x: root.explorerMaximized ? 0 : Math.max(96, Math.min(185, root.width - width - 16))
            y: root.explorerMaximized ? 0 : 48
            width: root.explorerMaximized ? root.width : Math.min(1120, Math.max(720, root.width - 116))
            height: root.explorerMaximized ? (root.height - taskbar.height) : Math.min(670, Math.max(480, root.height - 120))
            radius: root.explorerMaximized ? 0 : 8
            color: "#191919"
            border.color: root.explorerFocused ? "#48ffffff" : "#25ffffff"
            border.width: 1
            z: root.explorerFocused ? 20 : 10

            WinShadow { visible: !root.explorerMaximized }

            Behavior on width { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => {
                    root.closeAllPopups();
                    root.explorerFocused = true;
                    root.settingsFocused = false;
                    mouse.accepted = false;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // [A] Authentic Windows 11 Deep Mica Tab Strip (#0c0c0c)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: root.explorerMaximized ? 0 : 8
                    color: "#0e0e0e"

                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 145
                        property real dragStartX: 0
                        property real dragStartY: 0
                        onPressed: (mouse) => {
                            root.closeAllPopups();
                            root.explorerFocused = true;
                            root.settingsFocused = false;
                            dragStartX = mouse.x;
                            dragStartY = mouse.y;
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed && !root.explorerMaximized) {
                                explorerWin.x = Math.max(0, Math.min(root.width - 200, explorerWin.x + (mouse.x - dragStartX)));
                                explorerWin.y = Math.max(0, Math.min(root.height - 120, explorerWin.y + (mouse.y - dragStartY)));
                            }
                        }
                        onDoubleClicked: root.explorerMaximized = !root.explorerMaximized
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        spacing: 4

                        // Multi-Tab Bar (Authentic Windows 11 File Explorer Tabs)
                        Repeater {
                            model: root.explorerTabs
                            delegate: Rectangle {
                                Layout.preferredWidth: Math.min(215, Math.max(130, (explorerWin.width - 220) / root.explorerTabs.length))
                                Layout.preferredHeight: 33
                                Layout.alignment: Qt.AlignBottom
                                radius: 7
                                color: index === root.activeTabIndex ? "#202020" : (tabHov.containsMouse ? "#171717" : "#121212")

                                Rectangle {
                                    visible: index === root.activeTabIndex
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 7
                                    color: "#202020"
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 7

                                    WinSvg { width: 15; height: 15; iconFile: modelData === "Este equipo" ? "thispc.svg" : "folder.svg" }
                                    Text {
                                        text: modelData
                                        color: index === root.activeTabIndex ? "#ffffff" : "#b0b0b0"
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Rectangle {
                                        width: 18; height: 18; radius: 4
                                        color: tabCloseHov.containsMouse ? "#28ffffff" : "transparent"
                                        WinSvg { anchors.centerIn: parent; width: 10; height: 10; iconFile: "window-close-symbolic.svg"; opacity: 0.75 }
                                        MouseArea {
                                            id: tabCloseHov
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (root.explorerTabs.length > 1) {
                                                    var t = root.explorerTabs.slice();
                                                    t.splice(index, 1);
                                                    root.explorerTabs = t;
                                                    root.activeTabIndex = Math.min(root.activeTabIndex, t.length - 1);
                                                    root.navigateExplorer(root.explorerTabs[root.activeTabIndex], false);
                                                } else {
                                                    root.explorerOpen = false;
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tabHov
                                    anchors.fill: parent
                                    anchors.rightMargin: 24
                                    hoverEnabled: true
                                    onClicked: {
                                        root.activeTabIndex = index;
                                        root.navigateExplorer(root.explorerTabs[index], false);
                                    }
                                }
                            }
                        }

                        // "+" New Tab Button
                        Rectangle {
                            width: 28; height: 28; radius: 5
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 2
                            color: newTabHov.containsMouse ? "#22ffffff" : "transparent"
                            Text { anchors.centerIn: parent; text: "+"; color: "#d0d0d0"; font.pixelSize: 16 }
                            MouseArea {
                                id: newTabHov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.explorerTabs.length < 5) {
                                        var t = root.explorerTabs.slice();
                                        t.push("Este equipo");
                                        root.explorerTabs = t;
                                        root.activeTabIndex = t.length - 1;
                                        root.navigateExplorer("Este equipo", true);
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Authentic Windows 11 Caption Buttons (46x32px with official symbolic SVGs)
                        Row {
                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            Rectangle {
                                width: 46; height: 32
                                color: minHover.containsMouse ? "#26ffffff" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "window-minimize-symbolic.svg" }
                                MouseArea { id: minHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.explorerMinimized = true }
                            }
                            Rectangle {
                                width: 46; height: 32
                                color: maxHover.containsMouse ? "#26ffffff" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: root.explorerMaximized ? "window-restore-symbolic.svg" : "window-maximize-symbolic.svg" }
                                MouseArea { id: maxHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.explorerMaximized = !root.explorerMaximized }
                            }
                            Rectangle {
                                width: 46; height: 32
                                radius: root.explorerMaximized ? 0 : 6
                                color: closeHover.containsMouse ? "#c42b1c" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "window-close-symbolic.svg" }
                                MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.explorerOpen = false }
                            }
                        }
                    }
                }

                // [B] Windows 11 23H2/26H2 Address & Search Row (#202020)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    color: "#202020"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 6

                        Rectangle {
                            width: 30; height: 30; radius: 5
                            color: backHov.containsMouse ? "#24ffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "pan-start-symbolic.svg"; opacity: root.explorerHistoryIdx > 0 ? 1.0 : 0.35 }
                            MouseArea {
                                id: backHov; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (root.explorerHistoryIdx > 0) {
                                        root.explorerHistoryIdx--;
                                        root.navigateExplorer(root.explorerHistory[root.explorerHistoryIdx], false);
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: 30; height: 30; radius: 5
                            color: fwdHov.containsMouse ? "#24ffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "pan-end-symbolic.svg"; opacity: root.explorerHistoryIdx < root.explorerHistory.length - 1 ? 1.0 : 0.35 }
                            MouseArea {
                                id: fwdHov; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (root.explorerHistoryIdx < root.explorerHistory.length - 1) {
                                        root.explorerHistoryIdx++;
                                        root.navigateExplorer(root.explorerHistory[root.explorerHistoryIdx], false);
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: 30; height: 30; radius: 5
                            color: upHov.containsMouse ? "#24ffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "pan-up-symbolic.svg"; opacity: root.explorerSection !== "Este equipo" ? 1.0 : 0.35 }
                            MouseArea {
                                id: upHov; anchors.fill: parent; hoverEnabled: true
                                onClicked: root.navigateExplorer(bridge.getParentDir(root.explorerRealPath), true)
                            }
                        }
                        Rectangle {
                            width: 30; height: 30; radius: 5
                            color: refHov.containsMouse ? "#24ffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "view-refresh-symbolic.svg" }
                            MouseArea { id: refHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.refreshExplorer() }
                        }

                        // Breadcrumb Address Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 5
                            color: "#2b2b2b"
                            border.color: "#1fffffff"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                spacing: 6
                                WinSvg { width: 15; height: 15; iconFile: root.explorerMode === "thispc" ? "thispc.svg" : "folder.svg" }
                                WinSvg { width: 12; height: 12; iconFile: "pan-end-symbolic.svg"; opacity: 0.6 }
                                Text { text: root.explorerRealPath; color: "#ffffff"; font.pixelSize: 12; elide: Text.ElideMiddle; Layout.fillWidth: true }
                            }
                        }

                        // Search Box
                        Rectangle {
                            Layout.preferredWidth: 250
                            Layout.preferredHeight: 32
                            radius: 5
                            color: "#2b2b2b"
                            border.color: "#1fffffff"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8
                                Text { text: "Buscar en " + root.explorerSection; color: "#9e9e9e"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                                WinSvg { width: 14; height: 14; iconFile: "searching-symbolic.svg"; opacity: 0.7 }
                            }
                        }
                    }
                }

                // [C] Windows 11 Command Toolbar with Authentic Action SVGs (#191919)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    color: "#191919"
                    border.color: "#18ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        spacing: 10

                        // "+ Nuevo ▾" Pill (Creates real Folder or Text File on disk!)
                        Rectangle {
                            width: 92; height: 32; radius: 5
                            color: newBtnHov.containsMouse ? "#28ffffff" : "transparent"
                            RowLayout {
                                anchors.centerIn: parent; spacing: 6
                                Rectangle {
                                    width: 16; height: 16; radius: 8; color: "#0078d4"
                                    Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                }
                                Text { text: "Nuevo"; color: "#ffffff"; font.pixelSize: 12 }
                                WinSvg { width: 10; height: 10; iconFile: "pan-down-symbolic.svg" }
                            }
                            MouseArea {
                                id: newBtnHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    bridge.createNewItem(root.explorerRealPath, "folder");
                                    if (root.explorerMode === "thispc") root.navigateExplorer("Escritorio", true);
                                    else root.refreshExplorer();
                                }
                            }
                        }

                        Rectangle { width: 1; height: 22; color: "#22ffffff" }

                        // Cut, Copy, Paste, Rename, Delete Icon Buttons
                        Repeater {
                            model: [
                                { icon: "edit-cut-symbolic.svg", tip: "Cortar" },
                                { icon: "edit-copy-symbolic.svg", tip: "Copiar" },
                                { icon: "edit-paste-symbolic.svg", tip: "Pegar" },
                                { icon: "document-edit-symbolic.svg", tip: "Cambiar nombre" },
                                { icon: "edit-delete-symbolic.svg", tip: "Eliminar" }
                            ]
                            delegate: Rectangle {
                                width: 34; height: 32; radius: 5
                                color: cmdHov.containsMouse ? "#24ffffff" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: modelData.icon }
                                MouseArea { id: cmdHov; anchors.fill: parent; hoverEnabled: true }
                            }
                        }

                        Rectangle { width: 1; height: 22; color: "#22ffffff" }

                        Rectangle {
                            width: 88; height: 32; radius: 5; color: "transparent"
                            RowLayout {
                                anchors.centerIn: parent; spacing: 5
                                Text { text: "⇅  Ordenar"; color: "#e5e5e5"; font.pixelSize: 12 }
                                WinSvg { width: 10; height: 10; iconFile: "pan-down-symbolic.svg" }
                            }
                        }

                        Rectangle {
                            width: 68; height: 32; radius: 5; color: "transparent"
                            RowLayout {
                                anchors.centerIn: parent; spacing: 5
                                Text { text: "☰  Ver"; color: "#e5e5e5"; font.pixelSize: 12 }
                                WinSvg { width: 10; height: 10; iconFile: "pan-down-symbolic.svg" }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                // [D] Main Split Body (Left Navigation Pane + Right Content)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Left Sidebar with Authentic Win11 Folder & Device Icons
                    Rectangle {
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        color: "#191919"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 2

                            Repeater {
                                model: [
                                    { icon: "folder-home.svg",      name: "Inicio" },
                                    { icon: "folder-images.svg",    name: "Galería" },
                                    { icon: "folder-desktop.svg",   name: "Escritorio" },
                                    { icon: "folder-download.svg",  name: "Descargas" },
                                    { icon: "folder-documents.svg", name: "Documentos" },
                                    { icon: "folder-images.svg",    name: "Imágenes" },
                                    { icon: "folder-music.svg",     name: "Música" },
                                    { icon: "folder-videos.svg",    name: "Vídeos" },
                                    { icon: "thispc.svg",           name: "Este equipo" },
                                    { icon: "drive-c.svg",          name: "X64 LIOS (C:)" },
                                    { icon: "drive.svg",            name: "Juegos Steam (D:)" },
                                    { icon: "network.svg",          name: "Red" }
                                ]

                                delegate: Rectangle {
                                    width: 204
                                    height: 32
                                    radius: 5
                                    color: root.explorerSection === modelData.name ? "#2d2d2d" : (navHover.containsMouse ? "#222222" : "transparent")

                                    Rectangle {
                                        visible: root.explorerSection === modelData.name
                                        x: 2; anchors.verticalCenter: parent.verticalCenter
                                        width: 3; height: 16; radius: 1.5
                                        color: "#60cdff"
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        spacing: 10
                                        WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                                        Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }

                                    MouseArea {
                                        id: navHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.navigateExplorer(modelData.name, true)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1fffffff" }

                    // Right Main Content Area (Switches between "Este equipo" view and Real Directory Browser!)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#191919"

                        // VIEW A: "ESTE EQUIPO" (6 Official Folders + Real Mounted Disks!)
                        Column {
                            anchors.fill: parent
                            anchors.margins: 22
                            spacing: 16
                            visible: root.explorerMode === "thispc"

                            RowLayout {
                                width: parent.width
                                WinSvg { width: 12; height: 12; iconFile: "pan-down-symbolic.svg" }
                                Text { text: "Carpetas (6)"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#1fffffff" }
                            }

                            Grid {
                                columns: explorerWin.width < 920 ? 2 : 3
                                rowSpacing: 10
                                columnSpacing: 14

                                Repeater {
                                    model: [
                                        { name: "Escritorio", icon: "folder-desktop.svg",   sub: "Carpeta real del sistema" },
                                        { name: "Descargas",  icon: "folder-download.svg",  sub: "Carpeta real del sistema" },
                                        { name: "Documentos", icon: "folder-documents.svg", sub: "Carpeta real del sistema" },
                                        { name: "Imágenes",   icon: "folder-images.svg",    sub: "Carpeta real del sistema" },
                                        { name: "Música",     icon: "folder-music.svg",     sub: "Carpeta real del sistema" },
                                        { name: "Vídeos",     icon: "folder-videos.svg",    sub: "Carpeta real del sistema" }
                                    ]

                                    delegate: Rectangle {
                                        width: explorerWin.width < 920 ? 255 : 265
                                        height: 64
                                        radius: 5
                                        color: folderHover.containsMouse ? "#282828" : "transparent"
                                        border.color: folderHover.containsMouse ? "#28ffffff" : "transparent"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 12

                                            WinSvg { width: 46; height: 46; iconFile: modelData.icon }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 13 }
                                                Text { text: modelData.sub; color: "#999999"; font.pixelSize: 11 }
                                            }
                                        }

                                        MouseArea {
                                            id: folderHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.navigateExplorer(modelData.name, true)
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                width: parent.width
                                WinSvg { width: 12; height: 12; iconFile: "pan-down-symbolic.svg" }
                                Text { text: "Dispositivos y unidades (" + root.explorerDrives.length + ")"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#1fffffff" }
                            }

                            // Real System Drives from bridge.getDrivesJson()
                            Row {
                                spacing: 14

                                Repeater {
                                    model: root.explorerDrives

                                    delegate: Rectangle {
                                        width: explorerWin.width < 920 ? 255 : 325
                                        height: 76
                                        radius: 5
                                        color: driveHover.containsMouse ? "#282828" : "transparent"
                                        border.color: driveHover.containsMouse ? "#28ffffff" : "transparent"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 12

                                            WinSvg { width: 44; height: 44; iconFile: modelData.icon }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 5
                                                Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 13 }
                                                Rectangle {
                                                    width: explorerWin.width < 920 ? 175 : 235; height: 12; radius: 2
                                                    color: "#333333"
                                                    border.color: "#555555"
                                                    border.width: 1
                                                    Rectangle {
                                                        x: 1; y: 1
                                                        width: (parent.width - 2) * modelData.usedRatio
                                                        height: parent.height - 2
                                                        radius: 1
                                                        color: modelData.isCritical ? "#d13438" : "#26a0da"
                                                    }
                                                }
                                                Text { text: modelData.info; color: "#9e9e9e"; font.pixelSize: 11 }
                                            }
                                        }
                                        MouseArea {
                                            id: driveHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.navigateExplorer(modelData.path, true)
                                        }
                                    }
                                }
                            }
                        }

                        // VIEW B: REAL DIRECTORY BROWSER (Lists real files and folders on disk!)
                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 18
                            visible: root.explorerMode === "dir"
                            contentWidth: width
                            contentHeight: realDirGrid.implicitHeight + 20
                            clip: true

                            Grid {
                                id: realDirGrid
                                width: parent.width
                                columns: explorerWin.width < 920 ? 2 : 3
                                rowSpacing: 8
                                columnSpacing: 12

                                Repeater {
                                    model: root.explorerItems

                                    delegate: Rectangle {
                                        width: explorerWin.width < 920 ? ((realDirGrid.width - 12) / 2) : ((realDirGrid.width - 24) / 3)
                                        height: 56
                                        radius: 5
                                        color: itemHov.containsMouse ? "#282828" : "#1f1f1f"
                                        border.color: itemHov.containsMouse ? "#33ffffff" : "#14ffffff"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            WinSvg { width: 34; height: 34; iconFile: modelData.icon }

                                            Column {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text {
                                                    width: parent.width
                                                    text: modelData.name
                                                    color: "#ffffff"
                                                    font.pixelSize: 12
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    text: modelData.sub + " • " + modelData.mtime
                                                    color: "#8e8e8e"
                                                    font.pixelSize: 10
                                                    elide: Text.ElideRight
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: itemHov
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.isDir) {
                                                    root.navigateExplorer(modelData.path, true);
                                                } else {
                                                    bridge.openFileOrUrl(modelData.path);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // [E] Explorer Status Footer
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    color: "#191919"
                    border.color: "#16ffffff"
                    border.width: 1
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        Text { text: root.explorerItemCount + " elementos   |   " + root.explorerRealPath + "   |   Kernel " + root.sysInfo.kernel + " (" + root.sysInfo.sched + ")"; color: "#9e9e9e"; font.pixelSize: 11 }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }

        // =====================================================================
        // 4. WINDOWS 11 26H2 SETTINGS WINDOW ("Configuración" — All 6 Pages!)
        // =====================================================================
        Rectangle {
            id: settingsWin
            visible: root.settingsOpen && !root.settingsMinimized
            x: Math.max(88, Math.min(240, root.width - width - 16))
            y: 52
            width: Math.min(960, Math.max(720, root.width - 108))
            height: Math.min(640, Math.max(480, root.height - 110))
            radius: 8
            color: "#202020"
            border.color: root.settingsFocused ? "#48ffffff" : "#25ffffff"
            border.width: 1
            z: root.settingsFocused ? 22 : 11

            WinShadow {}

            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => {
                    root.closeAllPopups();
                    root.settingsFocused = true;
                    root.explorerFocused = false;
                    root.taskMgrFocused = false;
                    mouse.accepted = false;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Draggable Titlebar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 8
                    color: "#202020"

                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 100
                        property real dx: 0
                        property real dy: 0
                        onPressed: (m) => { root.settingsFocused = true; root.explorerFocused = false; dx = m.x; dy = m.y; }
                        onPositionChanged: (m) => {
                            if (pressed) {
                                settingsWin.x = Math.max(0, Math.min(root.width - 200, settingsWin.x + (m.x - dx)));
                                settingsWin.y = Math.max(0, Math.min(root.height - 120, settingsWin.y + (m.y - dy)));
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        WinSvg { width: 16; height: 16; iconFile: "settings.svg" }
                        Text { text: "Configuración"; color: "#ffffff"; font.pixelSize: 12 }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 46; height: 32
                            color: sMinHov.containsMouse ? "#26ffffff" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "window-minimize-symbolic.svg" }
                            MouseArea { id: sMinHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.settingsMinimized = true }
                        }
                        Rectangle {
                            width: 46; height: 32; radius: 6
                            color: sClsHov.containsMouse ? "#c42b1c" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "window-close-symbolic.svg" }
                            MouseArea { id: sClsHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.settingsOpen = false }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Rectangle {
                        Layout.preferredWidth: 235
                        Layout.fillHeight: true
                        color: "#202020"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 6

                            Row {
                                spacing: 12
                                WinSvg { width: 40; height: 40; iconFile: "x64lios.png" }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { text: "Cristian"; color: "#ffffff"; font.bold: true; font.pixelSize: 13 }
                                    Text { text: "x64studios@x64lios.com"; color: "#999999"; font.pixelSize: 11 }
                                }
                            }

                            Item { width: 1; height: 10 }

                            Repeater {
                                model: [
                                    { icon: "thispc.svg",     name: "Sistema" },
                                    { icon: "bluetooth.svg",  name: "Bluetooth y dispositivos" },
                                    { icon: "wifi.svg",       name: "Red e Internet" },
                                    { icon: "windows.svg",    name: "Personalización (26H2)" },
                                    { icon: "gaming.svg",     name: "Juegos (FalconD & scx_lavd)" },
                                    { icon: "update.svg",     name: "Windows / X64 Update" }
                                ]
                                delegate: Rectangle {
                                    width: 207; height: 36; radius: 5
                                    color: root.settingsPage === modelData.name ? "#2d2d2d" : "transparent"
                                    Rectangle {
                                        visible: root.settingsPage === modelData.name
                                        x: 2; anchors.verticalCenter: parent.verticalCenter
                                        width: 3; height: 16; radius: 1.5; color: "#60cdff"
                                    }
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                                        WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                                        Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsPage = modelData.name }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#1c1c1c"
                        radius: 8

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 24
                            contentWidth: width
                            contentHeight: settingsBodyCol.implicitHeight + 20
                            clip: true

                            Column {
                                id: settingsBodyCol
                                width: parent.width
                                spacing: 14

                                Text { text: root.settingsPage; color: "#ffffff"; font.pixelSize: 22; font.bold: true }

                                // Authentic Windows 11 Hero Banner (Monitor Preview + Hostname + Update Status)
                                Rectangle {
                                    width: parent.width; height: 84; radius: 6; color: "#252525"; border.color: "#1fffffff"
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 16
                                        // Miniature Monitor showing current live wallpaper
                                        Rectangle {
                                            width: 96; height: 56; radius: 4; color: "#000000"; border.color: "#555555"; border.width: 2
                                            Image {
                                                anchors.fill: parent; anchors.margins: 2; cache: false
                                                source: root.wallpaperMode === 0 ? (root.wpDir + "win11-bloom-dark.jpg") : (root.wallpaperMode === 1 ? (root.wpDir + "win11-bloom-light.jpg") : "file:///usr/share/backgrounds/x64-lios/01-monolith.jpg")
                                                fillMode: Image.PreserveAspectCrop
                                            }
                                        }
                                        Column {
                                            Layout.fillWidth: true; spacing: 3
                                            Text { text: root.sysInfo.hostname; color: "#ffffff"; font.pixelSize: 15; font.bold: true }
                                            Text { text: "X64 LIOS Windows 11 26H2 • " + root.sysInfo.cpu; color: "#aaaaaa"; font.pixelSize: 11; elide: Text.ElideRight; width: 320 }
                                            Text { text: "Cambiar nombre"; color: "#60cdff"; font.pixelSize: 11 }
                                        }
                                        Row {
                                            spacing: 8
                                            WinSvg { width: 22; height: 22; iconFile: "update.svg" }
                                            Column {
                                                Text { text: "Windows Update"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                                Text { text: "Todo actualizado"; color: "#6ccb5f"; font.pixelSize: 11 }
                                            }
                                        }
                                    }
                                }

                                // PAGE 1: PERSONALIZACIÓN (26H2)
                                Column {
                                    width: parent.width; spacing: 10
                                    visible: root.settingsPage === "Personalización (26H2)"

                                    // Theme Thumbnail Selector Row
                                    Rectangle {
                                        width: parent.width; height: 92; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14; spacing: 12
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: "Seleccionar un tema de Windows 11 26H2"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                                Text { text: "Haz clic en un tema para cambiar el fondo 4K en tiempo real"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Repeater {
                                                model: [
                                                    { mode: 0, label: "Bloom Dark", src: root.wpDir + "win11-bloom-dark.jpg" },
                                                    { mode: 1, label: "Bloom Light", src: root.wpDir + "win11-bloom-light.jpg" },
                                                    { mode: 2, label: "X64 Monolith", src: "file:///usr/share/backgrounds/x64-lios/01-monolith.jpg" }
                                                ]
                                                delegate: Rectangle {
                                                    width: 96; height: 60; radius: 5
                                                    border.color: root.wallpaperMode === modelData.mode ? "#60cdff" : "#33ffffff"
                                                    border.width: root.wallpaperMode === modelData.mode ? 2 : 1
                                                    Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: modelData.src; fillMode: Image.PreserveAspectCrop }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.wallpaperMode = modelData.mode }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width; height: 56; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: "Iconos pequeños en la barra de tareas (Windows 11 26H2)"; color: "#ffffff"; font.pixelSize: 13 }
                                                Text { text: "Reduce la barra de tareas de 48 px a 38 px"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Switch { checked: root.taskbarCompact; onToggled: root.taskbarCompact = checked }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width; height: 56; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: "Alineación de la barra de tareas a la izquierda"; color: "#ffffff"; font.pixelSize: 13 }
                                                Text { text: "Alterna entre el diseño centrado y el diseño alineado a la izquierda"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Switch { checked: root.taskbarLeftAlign; onToggled: root.taskbarLeftAlign = checked }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width; height: 56; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: "Mostrar sección «Recomendado» en el Menú Inicio (26H2)"; color: "#ffffff"; font.pixelSize: 13 }
                                                Text { text: "Desactívalo para dejar un Menú Inicio unificado 100 % limpio"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Switch { checked: root.showRecommended; onToggled: root.showRecommended = checked }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width; height: 56; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: "Panel lateral Phone Link / KDE Connect en el Menú Inicio (26H2)"; color: "#ffffff"; font.pixelSize: 13 }
                                                Text { text: "Muestra el estado de tu teléfono Android/iPhone junto al Menú Inicio"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Switch { checked: root.showPhoneLink; onToggled: root.showPhoneLink = checked }
                                        }
                                    }
                                }

                                // PAGE 2: SISTEMA (Real Hardware Specs & Controls)
                                Column {
                                    width: parent.width; spacing: 10
                                    visible: root.settingsPage === "Sistema"

                                    Repeater {
                                        model: [
                                            { icon: "thispc.svg", title: "Especificaciones del dispositivo (" + root.sysInfo.hostname + ")", desc: "CPU: " + root.sysInfo.cpu + "  |  RAM: " + root.sysInfo.ram },
                                            { icon: "windows.svg", title: "Especificaciones de Windows 11 Edition (X64 LIOS)", desc: "Versión 26H2  |  Kernel " + root.sysInfo.kernel + "  |  Planificador activo: " + root.sysInfo.sched },
                                            { icon: "audio.svg", title: "Sonido PipeWire Low-Latency (5.3 ms)", desc: "Volumen actual: " + Math.round(root.qsVolume) + "% • Sin crackling en gaming" },
                                            { icon: "drive-c.svg", title: "Almacenamiento NVMe Btrfs ZSTD", desc: root.explorerDrives.length > 0 ? root.explorerDrives[0].info : "NVMe Gen4" }
                                        ]
                                        delegate: Rectangle {
                                            width: parent.width; height: 60; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                            RowLayout {
                                                anchors.fill: parent; anchors.margins: 14; spacing: 14
                                                WinSvg { width: 24; height: 24; iconFile: modelData.icon }
                                                Column {
                                                    Layout.fillWidth: true
                                                    Text { text: modelData.title; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                                    Text { text: modelData.desc; color: "#999999"; font.pixelSize: 11; elide: Text.ElideRight }
                                                }
                                            }
                                        }
                                    }
                                }

                                // PAGE 3 & 4: BLUETOOTH / RED E INTERNET
                                Column {
                                    width: parent.width; spacing: 10
                                    visible: root.settingsPage === "Bluetooth y dispositivos" || root.settingsPage === "Red e Internet"

                                    Rectangle {
                                        width: parent.width; height: 64; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14; spacing: 14
                                            WinSvg { width: 28; height: 28; iconFile: root.settingsPage === "Red e Internet" ? "wifi.svg" : "bluetooth.svg" }
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: root.settingsPage === "Red e Internet" ? "Red Conectada • TCP BBR + fq Low-Latency Activo" : "Bluetooth y KDE Connect Activos"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                                Text { text: root.settingsPage === "Red e Internet" ? "Firewall UFW activo • Puertos KDE Connect 1714:1764 UDP/TCP autorizados" : "Listo para vincular mandos Xbox/PlayStation, auriculares y móviles"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Rectangle {
                                                width: 135; height: 32; radius: 5; color: "#0078d4"
                                                Text { anchors.centerIn: parent; text: "Abrir en X64 Hello"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("x64-hello") }
                                            }
                                        }
                                    }
                                }

                                // PAGE 5: JUEGOS (FALCOND & SCX_LAVD)
                                Column {
                                    width: parent.width; spacing: 10
                                    visible: root.settingsPage === "Juegos (FalconD & scx_lavd)"

                                    Rectangle {
                                        width: parent.width; height: 62; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14
                                            WinSvg { width: 26; height: 26; iconFile: "gaming.svg" }
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: "Modo de juego X64 (scx_lavd + FalconD + dmemcg-booster)"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                                Text { text: "Optimiza el PC para jugar priorizando 1% Low FPS, VRAM y latencia NVMe ADIOS"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Switch { checked: root.qsGaming; onToggled: root.qsGaming = checked }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width; height: 62; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 14
                                            WinSvg { width: 26; height: 26; iconFile: "x64lios.png" }
                                            Column {
                                                Layout.fillWidth: true
                                                Text { text: "Planificador eBPF Activo: " + root.sysInfo.sched; color: "#60cdff"; font.pixelSize: 13; font.bold: true }
                                                Text { text: "Cambiar entre scx_lavd, scx_bpfland, scx_flash y BORE desde X64 Hello"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Rectangle {
                                                width: 140; height: 32; radius: 5; color: "#0078d4"
                                                Text { anchors.centerIn: parent; text: "Configurar Scheduler"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("x64-hello") }
                                            }
                                        }
                                    }
                                }

                                // PAGE 6: WINDOWS / X64 UPDATE
                                Column {
                                    width: parent.width; spacing: 12
                                    visible: root.settingsPage === "Windows / X64 Update"

                                    Rectangle {
                                        width: parent.width; height: 86; radius: 6; color: "#272727"; border.color: "#1fffffff"
                                        RowLayout {
                                            anchors.fill: parent; anchors.margins: 16; spacing: 16
                                            WinSvg { width: 42; height: 42; iconFile: "update.svg" }
                                            Column {
                                                Layout.fillWidth: true; spacing: 4
                                                Text { text: "Todo está actualizado"; color: "#ffffff"; font.pixelSize: 16; font.bold: true }
                                                Text { text: "Última comprobación: Hoy • Repositorios oficiales x64-lios, cachyos-v3, AUR y Flatpak"; color: "#999999"; font.pixelSize: 11 }
                                            }
                                            Rectangle {
                                                width: 165; height: 34; radius: 5; color: "#0078d4"
                                                Text { anchors.centerIn: parent; text: "Buscar actualizaciones"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("x64-update") }
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

        // =====================================================================
        // 4B. WINDOWS 11 26H2 TASK MANAGER ("Administrador de tareas")
        // =====================================================================
        Rectangle {
            id: taskMgrWin
            visible: root.taskMgrOpen
            x: Math.max(120, (root.width - width) / 2)
            y: 70
            width: 760
            height: 530
            radius: 8
            color: "#1c1c1c"
            border.color: root.taskMgrFocused ? "#60cdff" : "#33ffffff"
            border.width: 1
            z: root.taskMgrFocused ? 25 : 15

            WinShadow {}

            MouseArea {
                anchors.fill: parent
                onPressed: (m) => {
                    root.closeAllPopups();
                    root.taskMgrFocused = true;
                    root.explorerFocused = false;
                    root.settingsFocused = false;
                    m.accepted = false;
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Titlebar
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 36; radius: 8; color: "#202020"
                    MouseArea {
                        anchors.fill: parent; anchors.rightMargin: 60
                        property real dx: 0; property real dy: 0
                        onPressed: (m) => { root.taskMgrFocused = true; dx = m.x; dy = m.y; }
                        onPositionChanged: (m) => {
                            if (pressed) {
                                taskMgrWin.x = Math.max(0, Math.min(root.width - 200, taskMgrWin.x + (m.x - dx)));
                                taskMgrWin.y = Math.max(0, Math.min(root.height - 120, taskMgrWin.y + (m.y - dy)));
                            }
                        }
                    }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 14
                        WinSvg { width: 16; height: 16; iconFile: "thispc.svg" }
                        Text { text: "Administrador de tareas — Windows 11 26H2"; color: "#ffffff"; font.pixelSize: 12 }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 46; height: 32; radius: 6
                            color: tmClsHov.containsMouse ? "#c42b1c" : "transparent"
                            WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "window-close-symbolic.svg" }
                            MouseArea { id: tmClsHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.taskMgrOpen = false }
                        }
                    }
                }

                // Live Telemetry Summary Strip (CPU %, RAM GB/%, Scheduler, Kernel)
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 74; color: "#252525"; border.color: "#1fffffff"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 16
                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 6; color: "#1d1d1d"; border.color: "#26a0da"
                            Column {
                                anchors.centerIn: parent
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "CPU (" + root.sysInfo.cpuPct + "%)"; color: "#60cdff"; font.pixelSize: 13; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.sysInfo.sched; color: "#aaaaaa"; font.pixelSize: 10 }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 6; color: "#1d1d1d"; border.color: "#8b5cf6"
                            Column {
                                anchors.centerIn: parent
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Memoria RAM"; color: "#c4b5fd"; font.pixelSize: 13; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.sysInfo.ram; color: "#aaaaaa"; font.pixelSize: 10 }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 48; radius: 6; color: "#1d1d1d"; border.color: "#10b981"
                            Column {
                                anchors.centerIn: parent
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Disco NVMe (ADIOS)"; color: "#6ee7b7"; font.pixelSize: 13; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "0% • Btrfs ZSTD"; color: "#aaaaaa"; font.pixelSize: 10 }
                            }
                        }
                    }
                }

                // Process Table Header
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 32; color: "#202020"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                        Text { text: "Nombre del proceso"; color: "#aaaaaa"; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }
                        Text { text: "PID"; color: "#aaaaaa"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 80 }
                        Text { text: "CPU"; color: "#60cdff"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 80 }
                        Text { text: "Memoria"; color: "#aaaaaa"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 100 }
                    }
                }

                // Live Processes Rows
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: width; contentHeight: procCol.implicitHeight; clip: true
                    Column {
                        id: procCol; width: parent.width; spacing: 1
                        Repeater {
                            model: root.sysInfo.procs || []
                            delegate: Rectangle {
                                width: procCol.width; height: 32; color: index % 2 === 0 ? "#191919" : "#1e1e1e"
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                                    WinSvg { width: 15; height: 15; iconFile: "terminal.svg" }
                                    Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                                    Text { text: modelData.pid; color: "#888888"; font.pixelSize: 11; Layout.preferredWidth: 80 }
                                    Text { text: modelData.cpu; color: "#60cdff"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 80 }
                                    Text { text: modelData.mem; color: "#cccccc"; font.pixelSize: 11; Layout.preferredWidth: 100 }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 5. WINDOWS 11 26H2 MODERN "WIN + R" RUN DIALOG (WinUI 3 Mica Dark)
        // =====================================================================
        Rectangle {
            visible: root.runDialogOpen
            x: 24
            y: root.height - taskbar.height - height - 16
            width: 425
            height: 205
            radius: 8
            color: "#f5202020"
            border.color: "#44ffffff"
            border.width: 1
            z: 550

            WinShadow {}

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 34; radius: 8; color: "#1a1a1a"
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10
                        WinSvg { width: 16; height: 16; iconFile: "terminal.svg" }
                        Text { text: "Ejecutar"; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                        WinSvg {
                            width: 13; height: 13; iconFile: "window-close-symbolic.svg"
                            MouseArea { anchors.fill: parent; onClicked: root.runDialogOpen = false }
                        }
                    }
                }

                Column {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 16; spacing: 12
                    RowLayout {
                        width: 393; spacing: 12
                        WinSvg { width: 36; height: 36; iconFile: "windows.svg" }
                        Text {
                            Layout.fillWidth: true
                            text: "Escriba el nombre de un programa, carpeta, documento o recurso de Internet y Windows lo abrirá."
                            color: "#d0d0d0"; font.pixelSize: 11; wrapMode: Text.WordWrap
                        }
                    }

                    RowLayout {
                        width: 393; spacing: 10
                        Text { text: "Abrir:"; color: "#ffffff"; font.pixelSize: 12 }
                        Rectangle {
                            Layout.fillWidth: true; height: 32; radius: 5; color: "#141414"; border.color: "#60cdff"
                            TextInput {
                                id: runInput
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#ffffff"; font.pixelSize: 12
                                text: "x64-hello"
                                onAccepted: {
                                    bridge.launchRealApp(runInput.text);
                                    root.runDialogOpen = false;
                                }
                            }
                        }
                    }

                    RowLayout {
                        width: 393; spacing: 8
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 90; height: 30; radius: 5; color: "#0078d4"
                            Text { anchors.centerIn: parent; text: "Aceptar"; color: "#ffffff"; font.pixelSize: 12 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    bridge.launchRealApp(runInput.text);
                                    root.runDialogOpen = false;
                                }
                            }
                        }
                        Rectangle {
                            width: 90; height: 30; radius: 5; color: "#2d2d2d"; border.color: "#22ffffff"
                            Text { anchors.centerIn: parent; text: "Cancelar"; color: "#ffffff"; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.runDialogOpen = false }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 6. WINDOWS 11 DESKTOP RIGHT-CLICK CONTEXT MENU
        // =====================================================================
        Rectangle {
            visible: root.ctxMenuOpen
            x: root.ctxX
            y: root.ctxY
            width: 280
            height: 344
            radius: 8
            color: "#f4252525"
            border.color: "#38ffffff"
            border.width: 1
            z: 500

            WinShadow {}

            Column {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 2

                Repeater {
                    model: [
                        { icon: "folder.svg",              label: "Ver", right: true, act: "" },
                        { icon: "view-refresh-symbolic.svg", label: "Ordenar por", right: true, act: "" },
                        { icon: "view-refresh-symbolic.svg", label: "Actualizar", right: false, act: "close" },
                        { icon: "folder-desktop.svg",      label: "Nuevo", right: true, act: "" },
                        { icon: "thispc.svg",              label: "Configuración de pantalla", right: false, act: "settings" },
                        { icon: "windows.svg",             label: "Personalizar", right: false, act: "settings" },
                        { icon: "folder-images.svg",       label: "Cambiar fondo (Dark / Light Bloom)", right: false, act: "wp" },
                        { icon: "terminal.svg",            label: "Abrir en Terminal", right: false, act: "term" },
                        { icon: "terminal.svg",            label: "Ejecutar (Win + R)", right: false, act: "run" },
                        { icon: "x64lios.png",             label: "Abrir X64 Hello", right: false, act: "x64hello" }
                    ]

                    delegate: Rectangle {
                        width: 268; height: 32; radius: 5
                        color: ctxHov.containsMouse ? "#35ffffff" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10
                            WinSvg { width: 16; height: 16; iconFile: modelData.icon }
                            Text { text: modelData.label; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                            WinSvg { visible: modelData.right; width: 12; height: 12; iconFile: "pan-end-symbolic.svg" }
                        }

                        MouseArea {
                            id: ctxHov
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.ctxMenuOpen = false;
                                if (modelData.act === "wp") {
                                    root.wallpaperMode = (root.wallpaperMode + 1) % 3;
                                } else if (modelData.act === "settings") {
                                    root.settingsOpen = true;
                                    root.settingsMinimized = false;
                                    root.settingsFocused = true;
                                } else if (modelData.act === "run") {
                                    root.runDialogOpen = true;
                                } else if (modelData.act === "term") {
                                    bridge.launchRealApp("kitty");
                                } else if (modelData.act === "x64hello") {
                                    bridge.launchRealApp("x64-hello");
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 7. WINDOWS 11 26H2 UNIFIED START MENU + PHONE LINK SIDEBAR
        // =====================================================================
        Item {
            id: startContainer
            width: root.showPhoneLink ? 875 : 640
            height: 690
            x: root.taskbarLeftAlign ? 12 : ((root.width - width) / 2)
            y: root.startOpen ? (root.height - height - taskbar.height - 12) : (root.height + 20)
            opacity: root.startOpen ? 1.0 : 0.0
            visible: opacity > 0.01
            z: 450

            Behavior on y { NumberAnimation { duration: 190; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Row {
                anchors.fill: parent
                spacing: 10

                // [A] MAIN WINDOWS 11 26H2 SINGLE-SCROLLABLE START MENU (640x690)
                Rectangle {
                    width: 640
                    height: 690
                    radius: 8
                    color: "#f4202020"
                    border.color: "#38ffffff"
                    border.width: 1

                    WinShadow {}

                    MouseArea { anchors.fill: parent }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Top Search Bar (Fixed)
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74

                            Rectangle {
                                anchors.centerIn: parent
                                width: 584
                                height: 38
                                radius: 19
                                color: "#171717"
                                border.color: "#60cdff"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 10
                                    WinSvg { width: 16; height: 16; iconFile: "search-app.svg" }
                                    TextInput {
                                        id: startSearchInput
                                        Layout.fillWidth: true
                                        color: "#ffffff"
                                        font.pixelSize: 13
                                        text: root.searchQuery
                                        onTextChanged: root.searchQuery = text
                                        Text {
                                            visible: startSearchInput.text === ""
                                            text: "Buscar aplicaciones, configuración y documentos"
                                            color: "#9e9e9e"
                                            font.pixelSize: 13
                                        }
                                    }
                                }
                            }
                        }

                        // 26H2 Single-Page Scrollable Content
                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: startScrollCol.implicitHeight + 24
                            clip: true

                            Column {
                                id: startScrollCol
                                x: 28
                                width: 584
                                spacing: 18

                                // 1. ANCLADOS SECTION
                                RowLayout {
                                    width: 584
                                    Text { text: "Anclados"; color: "#ffffff"; font.pixelSize: 14; font.bold: true }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 155; height: 24; radius: 4
                                        color: "#2b2b2b"; border.color: "#22ffffff"
                                        Text {
                                            anchors.centerIn: parent
                                            text: root.showRecommended ? "Ocultar Recomendado" : "Mostrar Recomendado"
                                            color: "#60cdff"; font.pixelSize: 10
                                        }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.showRecommended = !root.showRecommended
                                        }
                                    }
                                }

                                Grid {
                                    width: 584
                                    columns: 6
                                    rowSpacing: 10
                                    columnSpacing: 8

                                    Repeater {
                                        model: [
                                            { name: "Explorador",    icon: "explorer.svg",        act: "explorer" },
                                            { name: "Microsoft Edge",icon: "edge.svg",            act: "chromium" },
                                            { name: "Tienda Shelly", icon: "store.svg",           act: "shelly" },
                                            { name: "Configuración", icon: "settings.svg",        act: "settings" },
                                            { name: "X64 Hello",     icon: "x64lios.png",         act: "x64hello" },
                                            { name: "X64 Update",    icon: "update.svg",          act: "x64update" },
                                            { name: "Terminal",      icon: "terminal.svg",        act: "kitty" },
                                            { name: "Steam",         icon: "steam.svg",           act: "explorer" },
                                            { name: "Discord",       icon: "discord.svg",         act: "explorer" },
                                            { name: "Calculadora",   icon: "calculator.svg",      act: "explorer" },
                                            { name: "Este equipo",   icon: "thispc.svg",          act: "explorer" },
                                            { name: "Discos NVMe",   icon: "drive-c.svg",         act: "explorer" },
                                            { name: "Descargas",     icon: "folder-download.svg", act: "explorer" },
                                            { name: "Documentos",    icon: "folder-documents.svg",act: "explorer" },
                                            { name: "Imágenes",      icon: "folder-images.svg",   act: "explorer" },
                                            { name: "Música",        icon: "folder-music.svg",    act: "explorer" },
                                            { name: "Vídeos",        icon: "folder-videos.svg",   act: "explorer" },
                                            { name: "Papelera",      icon: "trash-full.svg",      act: "explorer" }
                                        ]

                                        delegate: Rectangle {
                                            width: 90
                                            height: 76
                                            radius: 6
                                            color: appHov.containsMouse ? "#28ffffff" : "transparent"

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                WinSvg {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 34; height: 34
                                                    iconFile: modelData.icon
                                                }
                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    width: 84
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: modelData.name
                                                    color: "#f3f4f6"
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: appHov
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    root.startOpen = false;
                                                    if (modelData.act === "explorer") {
                                                        root.explorerOpen = true;
                                                        root.explorerMinimized = false;
                                                        root.explorerFocused = true;
                                                        root.settingsFocused = false;
                                                    } else if (modelData.act === "settings") {
                                                        root.settingsOpen = true;
                                                        root.settingsMinimized = false;
                                                        root.settingsFocused = true;
                                                        root.explorerFocused = false;
                                                    } else if (modelData.act === "x64hello") {
                                                        bridge.launchRealApp("x64-hello");
                                                    } else if (modelData.act === "x64update") {
                                                        bridge.launchRealApp("x64-update");
                                                    } else if (modelData.act === "shelly") {
                                                        bridge.launchRealApp("shelly");
                                                    } else if (modelData.act === "kitty") {
                                                        bridge.launchRealApp("kitty");
                                                    } else if (modelData.act === "chromium") {
                                                        bridge.launchRealApp("chromium");
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 2. OPTIONAL RECOMMENDED SECTION (Hidden by default in 26H2!)
                                Column {
                                    width: 584
                                    spacing: 10
                                    visible: root.showRecommended

                                    Text { text: "Recomendado"; color: "#ffffff"; font.pixelSize: 14; font.bold: true }

                                    Grid {
                                        width: 584
                                        columns: 2
                                        rowSpacing: 8
                                        columnSpacing: 16

                                        Repeater {
                                            model: [
                                                { icon: "gaming.svg", title: "Perfil Gaming scx_lavd + FalconD", sub: "Activo en tiempo real" },
                                                { icon: "drive-c.svg", title: "X64 LIOS 2026.11 Release ISO", sub: "Abierto recientemente" }
                                            ]
                                            delegate: Rectangle {
                                                width: 284; height: 48; radius: 6; color: "#22ffffff"
                                                RowLayout {
                                                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 10
                                                    WinSvg { width: 28; height: 28; iconFile: modelData.icon }
                                                    Column {
                                                        Layout.fillWidth: true
                                                        Text { text: modelData.title; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                                        Text { text: modelData.sub; color: "#999999"; font.pixelSize: 10 }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 3. UNIFIED "TODAS" SECTION (Windows 11 26H2 Single-Scrollable All Apps with 3 View Modes!)
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
                                                color: root.startAllViewMode === modelData.id ? "#0078d4" : "#2b2b2b"
                                                border.color: "#22ffffff"
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    color: "#ffffff"
                                                    font.pixelSize: 10
                                                    font.bold: root.startAllViewMode === modelData.id
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.startAllViewMode = modelData.id
                                                }
                                            }
                                        }
                                    }
                                }

                                // VIEW MODE A: 26H2 CATEGORIES VIEW (2x2 Category Drawers)
                                Grid {
                                    width: 584
                                    columns: 2
                                    rowSpacing: 12
                                    columnSpacing: 14
                                    visible: root.startAllViewMode === "categories"

                                    Repeater {
                                        model: [
                                            { cat: "Sistema y Motor X64", items: [
                                                { name: "X64 Hello",     icon: "x64lios.png" },
                                                { name: "Configuración", icon: "settings.svg" },
                                                { name: "Terminal",      icon: "terminal.svg" },
                                                { name: "Tienda Shelly", icon: "store.svg" }
                                            ]},
                                            { cat: "Juegos y Entretenimiento", items: [
                                                { name: "Steam Gaming",  icon: "steam.svg" },
                                                { name: "Discord",       icon: "discord.svg" },
                                                { name: "Modo Gaming",   icon: "gaming.svg" },
                                                { name: "Juegos",        icon: "folder-games.svg" }
                                            ]},
                                            { cat: "Archivos y Discos", items: [
                                                { name: "Explorador",    icon: "explorer.svg" },
                                                { name: "Este equipo",   icon: "thispc.svg" },
                                                { name: "Disco (C:)",    icon: "drive-c.svg" },
                                                { name: "Papelera",      icon: "trash-full.svg" }
                                            ]},
                                            { cat: "Internet y Utilidades", items: [
                                                { name: "Edge / Web",    icon: "edge.svg" },
                                                { name: "Chrome",        icon: "chrome.svg" },
                                                { name: "Calculadora",   icon: "calculator.svg" },
                                                { name: "X64 Update",    icon: "update.svg" }
                                            ]}
                                        ]

                                        delegate: Rectangle {
                                            width: 285
                                            height: 112
                                            radius: 8
                                            color: "#272727"
                                            border.color: "#22ffffff"
                                            border.width: 1

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 8

                                                Text { text: modelData.cat; color: "#60cdff"; font.pixelSize: 11; font.bold: true }

                                                Grid {
                                                    columns: 2
                                                    rowSpacing: 8
                                                    columnSpacing: 10
                                                    Repeater {
                                                        model: modelData.items
                                                        delegate: Row {
                                                            width: 126
                                                            spacing: 6
                                                            WinSvg { width: 22; height: 22; iconFile: modelData.icon }
                                                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; color: "#e5e7eb"; font.pixelSize: 11; elide: Text.ElideRight; width: 96 }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // VIEW MODE B: 26H2 GRID A-Z VIEW
                                Grid {
                                    width: 584
                                    columns: 4
                                    rowSpacing: 8
                                    columnSpacing: 10
                                    visible: root.startAllViewMode === "grid"

                                    Repeater {
                                        model: [
                                            { name: "Calculadora",   icon: "calculator.svg" },
                                            { name: "Chrome",        icon: "chrome.svg" },
                                            { name: "Configuración", icon: "settings.svg" },
                                            { name: "Descargas",     icon: "folder-download.svg" },
                                            { name: "Discord",       icon: "discord.svg" },
                                            { name: "Disco (C:)",    icon: "drive-c.svg" },
                                            { name: "Edge / Web",    icon: "edge.svg" },
                                            { name: "Este equipo",   icon: "thispc.svg" },
                                            { name: "Explorador",    icon: "explorer.svg" },
                                            { name: "Steam",         icon: "steam.svg" },
                                            { name: "Terminal",      icon: "terminal.svg" },
                                            { name: "Tienda Shelly", icon: "store.svg" }
                                        ]
                                        delegate: Rectangle {
                                            width: 138; height: 40; radius: 6; color: "#262626"
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                                                WinSvg { width: 22; height: 22; iconFile: modelData.icon }
                                                Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                            }
                                        }
                                    }
                                }

                                // VIEW MODE C: CLASSIC LIST A-Z VIEW
                                Column {
                                    width: 584
                                    spacing: 4
                                    visible: root.startAllViewMode === "list"

                                    Repeater {
                                        model: [
                                            { name: "Calculadora",                                     icon: "calculator.svg" },
                                            { name: "Configuración (Windows 11 26H2)",                 icon: "settings.svg" },
                                            { name: "Discord",                                         icon: "discord.svg" },
                                            { name: "Este equipo",                                     icon: "thispc.svg" },
                                            { name: "Explorador de archivos",                          icon: "explorer.svg" },
                                            { name: "Microsoft Edge / Chromium",                       icon: "edge.svg" },
                                            { name: "Steam Gaming",                                    icon: "steam.svg" },
                                            { name: "Terminal (Kitty GPU)",                            icon: "terminal.svg" },
                                            { name: "Tienda Unificada Shelly (Pacman + AUR + Flatpak)",icon: "store.svg" },
                                            { name: "X64 Hello Control Center",                        icon: "x64lios.png" }
                                        ]
                                        delegate: Rectangle {
                                            width: 584; height: 34; radius: 5; color: "#222222"
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 10; spacing: 12
                                                WinSvg { width: 20; height: 20; iconFile: modelData.icon }
                                                Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Bottom Darker Profile & Power Bar (#171717, height 58)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 58
                            radius: 8
                            color: "#171717"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 28
                                anchors.rightMargin: 28

                                Rectangle {
                                    width: 215; height: 40; radius: 6
                                    color: usrHov.containsMouse ? "#24ffffff" : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        spacing: 10
                                        WinSvg { width: 28; height: 28; iconFile: "x64lios.png" }
                                        Column {
                                            Text { text: "Cristian"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                            Text { text: "X64 LIOS • Windows 11 26H2"; color: "#888888"; font.pixelSize: 10 }
                                        }
                                    }
                                    MouseArea { id: usrHov; anchors.fill: parent; hoverEnabled: true }
                                }

                                Item { Layout.fillWidth: true }

                                // Power Button
                                Rectangle {
                                    width: 38; height: 38; radius: 6
                                    color: pwrHov.containsMouse ? "#28ffffff" : "transparent"
                                    WinSvg { anchors.centerIn: parent; width: 17; height: 17; iconFile: "system-shutdown-symbolic.svg" }
                                    MouseArea {
                                        id: pwrHov
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.powerPopupOpen = !root.powerPopupOpen
                                    }
                                }
                            }
                        }
                    }

                    // Floating Power Submenu
                    Rectangle {
                        visible: root.powerPopupOpen
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 22
                        anchors.bottomMargin: 54
                        width: 185
                        height: 140
                        radius: 8
                        color: "#2b2b2b"
                        border.color: "#38ffffff"
                        border.width: 1

                        Column {
                            anchors.fill: parent; anchors.margins: 6; spacing: 2
                            Repeater {
                                model: [
                                    { label: "Bloquear (Win + L)", act: "lock" },
                                    { label: "Administrador de tareas", act: "taskmgr" },
                                    { label: "Reiniciar", act: "close" },
                                    { label: "Cerrar Vista Previa", act: "quit" }
                                ]
                                delegate: Rectangle {
                                    width: 173; height: 30; radius: 5
                                    color: pSubHov.containsMouse ? "#38ffffff" : "transparent"
                                    Text { anchors.verticalCenter: parent.verticalCenter; x: 12; text: modelData.label; color: "#ffffff"; font.pixelSize: 12 }
                                    MouseArea {
                                        id: pSubHov; anchors.fill: parent; hoverEnabled: true
                                        onClicked: {
                                            if (modelData.act === "quit") bridge.quitPreview();
                                            else if (modelData.act === "lock") { root.closeAllPopups(); root.lockPromptOpen = false; root.lockScreenOpen = true; }
                                            else if (modelData.act === "taskmgr") { root.closeAllPopups(); root.taskMgrOpen = true; root.taskMgrFocused = true; }
                                            else root.closeAllPopups();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // [B] 26H2 PHONE LINK / KDE CONNECT COMPANION PANEL (225x690)
                Rectangle {
                    visible: root.showPhoneLink
                    width: 225
                    height: 690
                    radius: 8
                    color: "#f21d1d1d"
                    border.color: "#38ffffff"
                    border.width: 1

                    WinShadow {}

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

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
                                    Text { text: "94% • Wi-Fi 5GHz"; color: "#d0d0d0"; font.pixelSize: 11 }
                                }
                            }
                        }

                        Text { text: "Acciones rápidas"; color: "#999999"; font.pixelSize: 11 }

                        Repeater {
                            model: ["Enviar archivo al móvil", "Portapapeles compartido", "Hacer sonar teléfono", "Control multimedia"]
                            delegate: Rectangle {
                                width: 193; height: 34; radius: 6; color: "#262626"
                                Text { anchors.centerIn: parent; text: modelData; color: "#ffffff"; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 8. WINDOWS 11 QUICK SETTINGS (Win + A) WITH SPLIT BUTTONS & SUBVIEWS
        // =====================================================================
        Rectangle {
            id: quickSettings
            width: 360
            height: 405
            x: root.width - width - 12
            y: root.quickSettingsOpen ? (root.height - height - taskbar.height - 12) : (root.height + 20)
            opacity: root.quickSettingsOpen ? 1.0 : 0.0
            visible: opacity > 0.01
            radius: 8
            color: "#f4222222"
            border.color: "#38ffffff"
            border.width: 1
            z: 450

            WinShadow {}

            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140 } }

            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 18
                visible: root.qsSubView === "main"

                Grid {
                    columns: 3
                    rowSpacing: 14
                    columnSpacing: 12

                    // Split Tile 1: Wi-Fi
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: root.qsWifi ? "#0078d4" : "#2d2d2d"
                            border.color: "#22ffffff"

                            Row {
                                anchors.fill: parent
                                Item {
                                    width: 68; height: 48
                                    WinSvg { anchors.centerIn: parent; width: 18; height: 18; iconFile: "am-wireless-symbolic.svg" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.qsWifi = !root.qsWifi }
                                }
                                Rectangle { width: 1; height: 32; anchors.verticalCenter: parent.verticalCenter; color: "#28ffffff" }
                                Item {
                                    width: 31; height: 48
                                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "pan-end-symbolic.svg" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.qsSubView = "wifi" }
                                }
                            }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "X64-5GHz"; color: "#e0e0e0"; font.pixelSize: 11 }
                    }

                    // Split Tile 2: Bluetooth
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: root.qsBt ? "#0078d4" : "#2d2d2d"
                            border.color: "#22ffffff"

                            Row {
                                anchors.fill: parent
                                Item {
                                    width: 68; height: 48
                                    WinSvg { anchors.centerIn: parent; width: 18; height: 18; iconFile: "bluetooth-active-symbolic.svg" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.qsBt = !root.qsBt }
                                }
                                Rectangle { width: 1; height: 32; anchors.verticalCenter: parent.verticalCenter; color: "#28ffffff" }
                                Item {
                                    width: 31; height: 48
                                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "pan-end-symbolic.svg" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.qsSubView = "bt" }
                                }
                            }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Bluetooth"; color: "#e0e0e0"; font.pixelSize: 11 }
                    }

                    // Tile 3: Gaming X64
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: root.qsGaming ? "#0078d4" : "#2d2d2d"
                            border.color: "#22ffffff"
                            WinSvg { anchors.centerIn: parent; width: 22; height: 22; iconFile: "gaming.svg" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.qsGaming = !root.qsGaming }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Gaming X64"; color: "#e0e0e0"; font.pixelSize: 11 }
                    }

                    // Tile 4: Night Light
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: root.qsNightLight ? "#0078d4" : "#2d2d2d"
                            border.color: "#22ffffff"
                            WinSvg { anchors.centerIn: parent; width: 18; height: 18; iconFile: "night-light-symbolic.svg" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.qsNightLight = !root.qsNightLight }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Luz nocturna"; color: "#e0e0e0"; font.pixelSize: 11 }
                    }

                    // Tile 5: Battery Saver
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: root.qsBatterySaver ? "#0078d4" : "#2d2d2d"
                            border.color: "#22ffffff"
                            WinSvg { anchors.centerIn: parent; width: 20; height: 16; iconFile: root.qsBatterySaver ? "win11-battery-yellow.svg" : "win11-battery-green.svg" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.qsBatterySaver = !root.qsBatterySaver }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Ahorro energía"; color: "#e0e0e0"; font.pixelSize: 11 }
                    }

                    // Tile 6: Settings
                    Column {
                        spacing: 5
                        Rectangle {
                            width: 100; height: 48; radius: 6
                            color: "#2d2d2d"
                            border.color: "#22ffffff"
                            WinSvg { anchors.centerIn: parent; width: 20; height: 20; iconFile: "settings.svg" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.quickSettingsOpen = false;
                                    root.settingsOpen = true;
                                    root.settingsMinimized = false;
                                    root.settingsFocused = true;
                                }
                            }
                        }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Configuración"; color: "#e0e0e0"; font.pixelSize: 11 }
                    }
                }

                // Brightness Slider
                RowLayout {
                    width: 320; spacing: 12
                    WinSvg { width: 18; height: 18; iconFile: "display-brightness-symbolic.svg" }
                    Slider { Layout.fillWidth: true; from: 10; to: 100; value: root.qsBrightness; onMoved: root.qsBrightness = value }
                }

                // Volume Slider (Connected to real PipeWire default sink!)
                RowLayout {
                    width: 320; spacing: 12
                    WinSvg { width: 18; height: 18; iconFile: "audio-volume-high-symbolic.svg" }
                    Slider {
                        Layout.fillWidth: true; from: 0; to: 100; value: root.qsVolume
                        onMoved: {
                            root.qsVolume = value;
                            bridge.setSystemVolume(Math.round(value));
                        }
                    }
                }

                Rectangle { width: 320; height: 1; color: "#22ffffff" }

                RowLayout {
                    width: 320
                    WinSvg {
                        width: 20; height: 16
                        iconFile: root.qsBatterySaver ? "win11-battery-yellow.svg" : "win11-battery-green.svg"
                    }
                    Text { text: "100% • CA (scx_lavd)"; color: "#cccccc"; font.pixelSize: 11 }
                    Item { Layout.fillWidth: true }
                    WinSvg {
                        width: 18; height: 18; iconFile: "settings.svg"
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.quickSettingsOpen = false;
                                root.settingsOpen = true;
                                root.settingsMinimized = false;
                                root.settingsFocused = true;
                            }
                        }
                    }
                }
            }

            // SUBVIEW: WI-FI / BLUETOOTH IN-PLACE LIST
            Column {
                anchors.fill: parent; anchors.margins: 20; spacing: 12
                visible: root.qsSubView !== "main"

                RowLayout {
                    width: 320
                    Rectangle {
                        width: 28; height: 28; radius: 5; color: "#2d2d2d"
                        WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "pan-start-symbolic.svg" }
                        MouseArea { anchors.fill: parent; onClicked: root.qsSubView = "main" }
                    }
                    Text {
                        text: root.qsSubView === "wifi" ? "Redes Wi-Fi disponibles" : "Dispositivos Bluetooth"
                        color: "#ffffff"; font.pixelSize: 14; font.bold: true
                    }
                }

                Repeater {
                    model: root.qsSubView === "wifi" ? ["X64-Studios-5GHz (Conectado)", "X64-Gaming-WiFi6E", "Invitados-LAN"] : ["Mando Xbox Series X (Conectado)", "Auriculares Sony WH-1000XM5", "Teléfono Android (KDE Connect)"]
                    delegate: Rectangle {
                        width: 320; height: 48; radius: 6; color: index === 0 ? "#2d3b4e" : "#2a2a2a"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 10
                            WinSvg { width: 16; height: 16; iconFile: root.qsSubView === "wifi" ? "am-wireless-symbolic.svg" : "bluetooth-active-symbolic.svg" }
                            Text { text: modelData; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 9. WINDOWS 11 TWO-CARD NOTIFICATION CENTER + CALENDAR (Bottom-Right)
        // =====================================================================
        Column {
            width: 340
            x: root.width - width - 12
            y: root.calendarOpen ? (root.height - implicitHeight - taskbar.height - 12) : (root.height + 20)
            opacity: root.calendarOpen ? 1.0 : 0.0
            visible: opacity > 0.01
            spacing: 10
            z: 450

            Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140 } }

            // Card 1: Top Notification Center Card
            Rectangle {
                width: 340
                height: 170
                radius: 8
                color: "#f4202020"
                border.color: "#38ffffff"
                border.width: 1

                WinShadow {}

                Column {
                    anchors.fill: parent; anchors.margins: 16; spacing: 10
                    RowLayout {
                        width: 308
                        Text { text: "Notificaciones"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: "Borrar todo"; color: "#60cdff"; font.pixelSize: 11 }
                    }
                    Rectangle {
                        width: 308; height: 95; radius: 6; color: "#2b2b2b"
                        Column {
                            anchors.fill: parent; anchors.margins: 10; spacing: 4
                            RowLayout {
                                width: 288
                                WinSvg { width: 16; height: 16; iconFile: "x64lios.png" }
                                Text { text: "X64 Gaming Engine • 26H2"; color: "#60cdff"; font.pixelSize: 11; font.bold: true }
                            }
                            Text {
                                width: 288
                                text: "Planificador scx_lavd + FalconD + dmemcg-booster activos. 0 timers en pantalla completa."
                                color: "#dddddd"; font.pixelSize: 11; wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            // Card 2: Separate Bottom Calendar Card
            Rectangle {
                width: 340
                height: 295
                radius: 8
                color: "#f4202020"
                border.color: "#38ffffff"
                border.width: 1

                WinShadow {}

                Column {
                    anchors.fill: parent; anchors.margins: 16; spacing: 12
                    Text { text: "domingo, 22 de noviembre de 2026"; color: "#60cdff"; font.pixelSize: 13; font.bold: true }
                    RowLayout {
                        width: 308
                        Text { text: "noviembre de 2026"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                        Item { Layout.fillWidth: true }
                        WinSvg { width: 13; height: 13; iconFile: "pan-up-symbolic.svg" }
                        WinSvg { width: 13; height: 13; iconFile: "pan-down-symbolic.svg" }
                    }
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
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: modelData === "22" ? "#000000" : "#ffffff"
                                    font.pixelSize: 11
                                    font.bold: modelData === "22"
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 10. TASKBAR HOVER THUMBNAIL PEEK POPUP (Above hovered running app)
        // =====================================================================
        Rectangle {
            visible: root.hoveredTaskId !== ""
            width: 210
            height: 132
            x: Math.max(12, Math.min(root.width - width - 12, root.hoveredTaskX - width / 2))
            y: root.height - taskbar.height - height - 10
            radius: 8
            color: "#f4252525"
            border.color: "#38ffffff"
            border.width: 1
            z: 590

            WinShadow {}

            Column {
                anchors.fill: parent; anchors.margins: 10; spacing: 8
                RowLayout {
                    width: 190
                    WinSvg { width: 16; height: 16; iconFile: root.hoveredTaskId === "explorer" ? "explorer.svg" : "settings.svg" }
                    Text {
                        text: root.hoveredTaskId === "explorer" ? root.explorerSection : "Configuración"
                        color: "#ffffff"; font.pixelSize: 11; font.bold: true
                        Layout.fillWidth: true; elide: Text.ElideRight
                    }
                    WinSvg { width: 12; height: 12; iconFile: "window-close-symbolic.svg" }
                }
                Rectangle {
                    width: 190; height: 84; radius: 5; color: "#181818"; border.color: "#22ffffff"
                    WinSvg {
                        anchors.centerIn: parent; width: 42; height: 42
                        iconFile: root.hoveredTaskId === "explorer" ? "explorer.svg" : "settings.svg"
                    }
                }
            }
        }

        // =====================================================================
        // 11. WINDOWS 11 26H2 TASKBAR (48px Normal / 38px 26H2 Compact Mode)
        // =====================================================================
        Rectangle {
            id: taskbar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.taskbarCompact ? 38 : 48
            color: "#ec181818"
            z: 600

            Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: "#28ffffff"
            }

            // [1] Left Weather Widget (Authentic Sun+Cloud SVG)
            Rectangle {
                id: wthWidget
                visible: !root.taskbarLeftAlign && root.width >= 900
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 145
                height: root.taskbarCompact ? 32 : 38
                radius: 5
                color: wthHov.containsMouse ? "#1fffffff" : "transparent"

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 8; spacing: 8
                    WinSvg { width: 24; height: 24; iconFile: "win11-weather.svg" }
                    Column {
                        Layout.fillWidth: true
                        Text { text: "22°C"; color: "#ffffff"; font.pixelSize: 11; font.bold: true }
                        Text { visible: !root.taskbarCompact; text: "Mayormente despejado"; color: "#cccccc"; font.pixelSize: 10; elide: Text.ElideRight; width: 95 }
                    }
                }
                MouseArea { id: wthHov; anchors.fill: parent; hoverEnabled: true }
            }

            // [2] Main Taskbar Icons Row (Centered or Left-Aligned, auto-clamped so it never collides with Right Tray!)
            Row {
                id: mainIconsRow
                readonly property bool autoCompactSearch: root.taskbarCompact || root.width < 1180
                x: root.taskbarLeftAlign
                   ? 12
                   : Math.max(wthWidget.visible ? (wthWidget.x + wthWidget.width + 8) : 12,
                              Math.min((parent.width - width) / 2, rightTrayRow.x - width - 10))
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // OFFICIAL WINDOWS 11 START BUTTON SVG
                Rectangle {
                    width: root.taskbarCompact ? 34 : 40
                    height: root.taskbarCompact ? 34 : 40
                    radius: 4
                    color: (root.startOpen || startBtnHov.containsMouse) ? "#24ffffff" : "transparent"

                    WinSvg {
                        anchors.centerIn: parent
                        width: root.taskbarCompact ? 22 : 26
                        height: root.taskbarCompact ? 22 : 26
                        iconFile: "win11-start.svg"
                        scale: startBtnHov.pressed ? 0.85 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }
                    }

                    MouseArea {
                        id: startBtnHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !root.startOpen;
                            root.closeAllPopups();
                            root.startOpen = next;
                        }
                    }
                }

                // Windows 11 Search Pill (Auto-collapses to icon on narrow screens just like real Win11)
                Rectangle {
                    width: mainIconsRow.autoCompactSearch ? (root.taskbarCompact ? 34 : 40) : 136
                    height: root.taskbarCompact ? 30 : 32
                    radius: height / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: searchPillHov.containsMouse ? "#343434" : "#292929"
                    border.color: "#28ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: mainIconsRow.autoCompactSearch ? ((parent.width - 15) / 2) : 12
                        spacing: 8
                        WinSvg { width: 15; height: 15; iconFile: "search-app.svg" }
                        Text { visible: !mainIconsRow.autoCompactSearch; text: "Buscar"; color: "#d0d0d0"; font.pixelSize: 12; Layout.fillWidth: true }
                    }

                    MouseArea {
                        id: searchPillHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !root.startOpen;
                            root.closeAllPopups();
                            root.startOpen = next;
                        }
                    }
                }

                // Task View Button
                Rectangle {
                    width: root.taskbarCompact ? 34 : 40
                    height: root.taskbarCompact ? 34 : 40
                    radius: 4
                    color: tvHov.containsMouse ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 22; height: 22; iconFile: "win11-taskview.svg" }
                    MouseArea { id: tvHov; anchors.fill: parent; hoverEnabled: true }
                }

                // Pinned & Running Applications (100% Authentic Win11-icon-theme SVGs!)
                Repeater {
                    model: [
                        { id: "explorer", icon: "explorer.svg", isOpen: root.explorerOpen, isFocused: root.explorerFocused && !root.explorerMinimized },
                        { id: "chromium", icon: "edge.svg",     isOpen: false, isFocused: false },
                        { id: "shelly",   icon: "store.svg",    isOpen: false, isFocused: false },
                        { id: "kitty",    icon: "terminal.svg", isOpen: false, isFocused: false },
                        { id: "steam",    icon: "steam.svg",    isOpen: false, isFocused: false },
                        { id: "x64hello", icon: "x64lios.png",  isOpen: false, isFocused: false },
                        { id: "settings", icon: "settings.svg", isOpen: root.settingsOpen, isFocused: root.settingsFocused && !root.settingsMinimized }
                    ]

                    delegate: Rectangle {
                        id: tbAppBtn
                        width: root.taskbarCompact ? 34 : 40
                        height: root.taskbarCompact ? 34 : 40
                        radius: 4
                        color: (modelData.isFocused || tbHov.containsMouse) ? "#24ffffff" : "transparent"

                        WinSvg {
                            anchors.centerIn: parent
                            width: root.taskbarCompact ? 21 : 25
                            height: root.taskbarCompact ? 21 : 25
                            iconFile: modelData.icon
                            scale: tbHov.pressed ? 0.85 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                        }

                        // Windows 11 Bottom Active Pill (16px active cyan #60CDFF, 6px background #8A8A8A)
                        Rectangle {
                            visible: modelData.isOpen
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: modelData.isFocused ? 16 : 6
                            height: 3
                            radius: 1.5
                            color: modelData.isFocused ? "#60cdff" : "#8a8a8a"
                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: tbHov
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                if (modelData.isOpen) {
                                    var g = tbAppBtn.mapToItem(root, tbAppBtn.width / 2, 0);
                                    root.hoveredTaskX = g.x;
                                    root.hoveredTaskId = modelData.id;
                                }
                            }
                            onExited: {
                                if (root.hoveredTaskId === modelData.id) root.hoveredTaskId = "";
                            }
                            onClicked: {
                                root.hoveredTaskId = "";
                                root.closeAllPopups();
                                if (modelData.id === "explorer") {
                                    if (!root.explorerOpen) {
                                        root.explorerOpen = true;
                                        root.explorerMinimized = false;
                                        root.explorerFocused = true;
                                        root.settingsFocused = false;
                                    } else if (root.explorerMinimized) {
                                        root.explorerMinimized = false;
                                        root.explorerFocused = true;
                                        root.settingsFocused = false;
                                    } else if (!root.explorerFocused) {
                                        root.explorerFocused = true;
                                        root.settingsFocused = false;
                                    } else {
                                        root.explorerMinimized = true;
                                    }
                                } else if (modelData.id === "settings") {
                                    if (!root.settingsOpen) {
                                        root.settingsOpen = true;
                                        root.settingsMinimized = false;
                                        root.settingsFocused = true;
                                        root.explorerFocused = false;
                                    } else if (root.settingsMinimized) {
                                        root.settingsMinimized = false;
                                        root.settingsFocused = true;
                                        root.explorerFocused = false;
                                    } else if (!root.settingsFocused) {
                                        root.settingsFocused = true;
                                        root.explorerFocused = false;
                                    } else {
                                        root.settingsMinimized = true;
                                    }
                                } else if (modelData.id === "x64hello") {
                                    bridge.launchRealApp("x64-hello");
                                } else if (modelData.id === "shelly") {
                                    bridge.launchRealApp("shelly");
                                } else if (modelData.id === "kitty") {
                                    bridge.launchRealApp("kitty");
                                } else if (modelData.id === "chromium") {
                                    bridge.launchRealApp("chromium");
                                }
                            }
                        }
                    }
                }
            }

            // [3] Right System Tray (Authentic Win11 Symbolic SVGs + 26H2 Green Battery & %)
            Row {
                id: rightTrayRow
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                // ^ Hidden Icons Chevron
                Rectangle {
                    width: 26; height: root.taskbarCompact ? 32 : 38; radius: 4
                    color: chvHov.containsMouse ? "#1fffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "pan-up-symbolic.svg" }
                    MouseArea { id: chvHov; anchors.fill: parent; hoverEnabled: true }
                }

                // Keyboard Layout (ESP / ES)
                Rectangle {
                    width: 36; height: root.taskbarCompact ? 32 : 38; radius: 4
                    color: kbHov.containsMouse ? "#1fffffff" : "transparent"
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.kbLayout === "ES" ? "ESP" : "ENG"; color: "#ffffff"; font.pixelSize: 10; font.bold: true }
                        Text { visible: !root.taskbarCompact; anchors.horizontalCenter: parent.horizontalCenter; text: root.kbLayout; color: "#bbbbbb"; font.pixelSize: 9 }
                    }
                    MouseArea {
                        id: kbHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root.kbLayout = (root.kbLayout === "ES" ? "US" : "ES")
                    }
                }

                // Unified Wi-Fi + Volume + 26H2 Color Battery & % Button
                Rectangle {
                    width: qsTrayRow.implicitWidth + 16
                    height: root.taskbarCompact ? 32 : 38
                    radius: 4
                    color: (root.quickSettingsOpen || qsBtnHov.containsMouse) ? "#24ffffff" : "transparent"

                    Row {
                        id: qsTrayRow
                        anchors.centerIn: parent
                        spacing: 7
                        WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; iconFile: "am-wireless-symbolic.svg" }
                        WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 15; height: 15; iconFile: "audio-volume-high-symbolic.svg" }
                        WinSvg {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 19; height: 15
                            iconFile: root.qsBatterySaver ? "win11-battery-yellow.svg" : "win11-battery-green.svg"
                        }
                        Text {
                            visible: root.showBatteryPct
                            anchors.verticalCenter: parent.verticalCenter
                            text: "100%"
                            color: "#ffffff"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: qsBtnHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !root.quickSettingsOpen;
                            root.closeAllPopups();
                            root.quickSettingsOpen = next;
                        }
                    }
                }

                // Windows 11 Clock & Date
                Rectangle {
                    width: 82
                    height: root.taskbarCompact ? 32 : 38
                    radius: 4
                    color: (root.calendarOpen || clkHov.containsMouse) ? "#24ffffff" : "transparent"

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
                            visible: !root.taskbarCompact
                            anchors.right: parent.right
                            text: "22/11/2026"
                            color: "#cccccc"
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: clkHov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !root.calendarOpen;
                            root.closeAllPopups();
                            root.calendarOpen = next;
                        }
                    }
                }

                // Far-Right Show Desktop Sliver
                Rectangle {
                    width: 8; height: root.taskbarCompact ? 32 : 38
                    color: sdHov.containsMouse ? "#28ffffff" : "transparent"
                    Rectangle {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        width: 1; height: 20; color: "#33ffffff"
                    }
                    MouseArea {
                        id: sdHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            root.closeAllPopups();
                            var anyVisible = (root.explorerOpen && !root.explorerMinimized) || (root.settingsOpen && !root.settingsMinimized);
                            root.explorerMinimized = anyVisible;
                            root.settingsMinimized = anyVisible;
                        }
                    }
                }
            }

            // Right-Click on Empty Taskbar -> Windows 11 Taskbar Context Menu ("Administrador de tareas" / "Configuración de la barra de tareas")
            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.RightButton
                onClicked: (mouse) => {
                    root.closeAllPopups();
                    root.taskbarCtxX = Math.max(12, Math.min(root.width - 250, mouse.x - 110));
                    root.taskbarCtxOpen = true;
                }
            }
        }

        // Authentic Windows 11 Taskbar Right-Click Popup
        Rectangle {
            visible: root.taskbarCtxOpen
            x: root.taskbarCtxX
            y: root.height - taskbar.height - height - 8
            width: 240
            height: 76
            radius: 8
            color: "#f4252525"
            border.color: "#38ffffff"
            border.width: 1
            z: 620

            WinShadow {}

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
                            root.taskbarCtxOpen = false;
                            root.taskMgrOpen = true;
                            root.taskMgrFocused = true;
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
                            root.taskbarCtxOpen = false;
                            root.settingsPage = "Personalización (26H2)";
                            root.settingsOpen = true;
                            root.settingsMinimized = false;
                            root.settingsFocused = true;
                        }
                    }
                }
            }
        }

        // =====================================================================
        // 12. WINDOWS 11 26H2 LOCK SCREEN ("Win + L")
        // =====================================================================
        Rectangle {
            visible: root.lockScreenOpen
            anchors.fill: parent
            color: "#000000"
            z: 950

            Image {
                anchors.fill: parent
                cache: false
                source: root.wpDir + "win11-bloom-dark.jpg"
                fillMode: Image.PreserveAspectCrop
            }

            // Darkened acrylic veil when password prompt is open
            Rectangle {
                anchors.fill: parent
                color: root.lockPromptOpen ? "#aa080d1a" : "#33000000"
                Behavior on color { ColorAnimation { duration: 220 } }
            }

            // State 1: Big Windows 11 Lock Clock & Date
            Column {
                visible: !root.lockPromptOpen
                anchors.horizontalCenter: parent.horizontalCenter
                y: 110
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(new Date(), "hh:mm")
                    color: "#ffffff"
                    font.pixelSize: 88
                    font.bold: true
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "domingo, 22 de noviembre"
                    color: "#f3f4f6"
                    font.pixelSize: 22
                }
                Item { width: 1; height: 260 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Haz clic en cualquier lugar para iniciar sesión"
                    color: "#cccccc"
                    font.pixelSize: 13
                }
            }

            // State 2: Windows 11 Sign-In Avatar & Password Box
            Column {
                visible: root.lockPromptOpen
                anchors.centerIn: parent
                spacing: 16

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 116; height: 116; radius: 58
                    color: "#22ffffff"
                    border.color: "#60cdff"
                    border.width: 2
                    WinSvg { anchors.centerIn: parent; width: 72; height: 72; iconFile: "x64lios.png" }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Cristian"
                    color: "#ffffff"
                    font.pixelSize: 24
                    font.bold: true
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 270; height: 36; radius: 5
                    color: "#cc1a1a1a"
                    border.color: "#60cdff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 6
                        TextInput {
                            Layout.fillWidth: true
                            color: "#ffffff"
                            font.pixelSize: 13
                            echoMode: TextInput.Password
                            text: "1111"
                            onAccepted: { root.lockScreenOpen = false; root.lockPromptOpen = false; }
                        }
                        Rectangle {
                            width: 26; height: 26; radius: 4; color: "#0078d4"
                            WinSvg { anchors.centerIn: parent; width: 13; height: 13; iconFile: "pan-end-symbolic.svg" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.lockScreenOpen = false; root.lockPromptOpen = false; }
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: !root.lockPromptOpen
                onClicked: root.lockPromptOpen = true
            }
        }
    }
}
