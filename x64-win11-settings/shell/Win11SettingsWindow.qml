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
        var s = String(raw || "").trim();
        if (s === "" || s === "Inicio") return "Inicio";
        if (s.indexOf("Personalizaci") === 0) return "Personalización";
        if (s.indexOf("Juegos") === 0) return "Juegos";
        if (s.indexOf("Cuenta") === 0) return "Cuentas";
        if (s.indexOf("Hora") === 0 || s.indexOf("Idioma") !== -1) return "Hora e idioma";
        if (s.indexOf("Actualizaci") === 0 || s.indexOf("Update") !== -1 || s.indexOf("Windows") === 0) return "Actualización del sistema";
        if (s === "Sistema" || s === "Bluetooth y dispositivos" || s === "Red e Internet" || s === "Aplicaciones") return s;
        return "Inicio";
    }

    property string settingsPage: normalizePageName(typeof initialArg !== "undefined" ? initialArg : "")
    property string navFilter: ""
    property string appSearchFilter: ""
    property bool navExpandedManual: false
    property bool copiedNotice: false
    property string toastMsg: ""
    property string clockTimeStr: Qt.formatTime(new Date(), "hh:mm:ss")
    property string clockDateStr: Qt.formatDate(new Date(), "dddd, d 'de' MMMM 'de' yyyy")

    // Live Optimistic Slider & Toggle States (prevents 4s poller jitter & instant 144Hz feedback!)
    property int localBrightPct: 100
    property int localVolPct: 80
    property int localMicPct: 50
    property bool brightDragging: false
    property bool volDragging: false
    property bool micDragging: false
    property string expandedMimeRole: ""

    // Wi-Fi Password Modal State (handles SSIDs with spaces & new secured networks!)
    property bool wifiPassModalOpen: false
    property string wifiPassSsid: ""
    property string wifiPassErr: ""

    // System Update Check State (100% Async QThread via bridge.updatesChecked signal!)
    property bool checkingUpdates: false
    property var updateResult: ({ "count": -1, "packages": [], "checkedAt": "" })

    Connections {
        target: bridge
        function onUpdatesChecked(jsonStr) {
            root.checkingUpdates = false;
            try {
                var res = JSON.parse(jsonStr);
                root.updateResult = res;
                root.showToast(res.count > 0 ? (res.count + " actualizaciones disponibles") : "Sistema al día");
            } catch (e) {}
        }
    }

    // Responsive Breakpoints (ZERO deformation on small or narrow windows!)
    readonly property bool compactNav: root.width < 820 && !root.navExpandedManual
    readonly property bool narrowBody: contentPane.width < 560

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
        "doNotDisturb": false,
        "wallpaperMode": 0,
        "customWallpaperUrl": "",
        "userAvatarUrl": ""
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
        "sinks": [],
        "sources": [],
        "micVol": 50,
        "micMuted": false,
        "btDevices": [],
        "netGateway": "—",
        "netDns": "—",
        "netIface": "—",
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
        onTriggered: { root.toastMsg = ""; root.copiedNotice = false; }
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
            function syncX(mx) {
                var r = Math.max(0.0, Math.min(1.0, (mx - 10.0) / Math.max(1.0, sSlider.width - 20.0)));
                var nv = sSlider.from + r * (sSlider.to - sSlider.from);
                sSlider.value = nv;
                sSlider.movedValue(nv);
            }
            onPressed: (mouse) => syncX(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) syncX(mouse.x); }
            onReleased: sSlider.releasedValue(sSlider.value)
        }
    }

    // Reusable WinUI 3 Fluent Action Button
    component FluentBtn : Rectangle {
        id: fBtn
        property string label: ""
        property bool accent: false
        signal clicked()
        implicitWidth: Math.max(82, fBtnTxt.implicitWidth + 24)
        implicitHeight: 32
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        radius: 5
        color: accent ? (fBtnH.containsMouse ? "#5ecbff" : "#4cc2ff")
                      : (fBtnH.containsMouse ? "#3b3b3b" : "#303030")
        border.color: accent ? "#4cc2ff" : "#24ffffff"
        border.width: 1
        Text {
            id: fBtnTxt; anchors.centerIn: parent
            text: fBtn.label
            color: fBtn.accent ? "#000000" : "#f2f2f2"
            font.pixelSize: 12
            font.weight: fBtn.accent ? Font.DemiBold : Font.Normal
        }
        MouseArea {
            id: fBtnH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: fBtn.clicked()
        }
    }

    // Reusable Auto-Sizing WinUI 3 Setting Toggle Card (never clips wrapped text!)
    component ToggleCard : Rectangle {
        id: tCard
        property string iconFile: "fluent-settings.svg"
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled(bool isChecked)
        width: parent ? parent.width : 400
        implicitHeight: tRow.implicitHeight + 24
        radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1

        RowLayout {
            id: tRow
            anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 14
            WinSvg { width: 20; height: 20; iconFile: tCard.iconFile }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: tCard.title; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                Text { visible: tCard.subtitle !== ""; text: tCard.subtitle; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            Win11Switch { checked: tCard.checked; onToggled: (v) => tCard.toggled(v) }
        }
    }

    function updateCfg(key, val) {
        var copy = Object.assign({}, cfg);
        copy[key] = val;
        cfg = copy;
        bridge.setConfigValue(key, JSON.stringify(val));
    }

    function refreshLiveState() {
        try { cfg = Object.assign({}, cfg, JSON.parse(bridge.getConfigJson())); } catch (e) {}
        try { hwState = JSON.parse(bridge.getLiveHardwareJson()); } catch (e) {}
        try { drives = JSON.parse(bridge.getDrivesJson()); } catch (e) {}
        try { extData = JSON.parse(bridge.getSettingsExtendedJson()); } catch (e) {}
        if (!brightDragging) localBrightPct = Math.round(Number(hwState.brightnessPct !== undefined ? hwState.brightnessPct : 100));
        if (!volDragging) localVolPct = Math.round(Number(hwState.volumePct !== undefined ? hwState.volumePct : 80));
        if (!micDragging) localMicPct = Math.round(Number(extData.micVol !== undefined ? extData.micVol : 50));
        if (typeof dispNameIn !== "undefined" && !dispNameIn.activeFocus) {
            dispNameIn.text = activeDisplayName;
        }
        var now = new Date();
        clockTimeStr = Boolean(cfg.clock12h) ? Qt.formatTime(now, "h:mm:ss AP") : Qt.formatTime(now, "hh:mm:ss");
    }

    function runUpdateCheck() {
        if (checkingUpdates) return;
        checkingUpdates = true;
        bridge.startAsyncUpdateCheck();
    }

    function tryConnectWifi(ssid) {
        var res = bridge.connectWifi(ssid, "");
        if (res === "ok") {
            refreshLiveState();
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
        try { sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
        try { installedApps = JSON.parse(bridge.getInstalledAppsJson()); } catch (e) {}
        refreshLiveState();
    }

    Timer {
        interval: 4000; running: true; repeat: true
        onTriggered: root.refreshLiveState()
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
            Layout.preferredWidth: root.compactNav ? 62 : 254
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
                        onClicked: { root.settingsPage = "Cuentas"; root.navExpandedManual = false; }
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
                                    for (var i = 0; i < root.navCategories.length; i++) {
                                        if (root.matchesNavFilter(root.navCategories[i])) {
                                            root.settingsPage = root.navCategories[i].name;
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
                                width: navListCol.width; height: 36; radius: 5
                                color: root.settingsPage === modelData.name ? "#2d2d2d" : (catHov.containsMouse ? "#262626" : "transparent")
                                Rectangle {
                                    visible: root.settingsPage === modelData.name
                                    x: 2; anchors.verticalCenter: parent.verticalCenter
                                    width: 3; height: 16; radius: 1.5; color: "#4cc2ff"
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: root.compactNav ? 14 : 12
                                    anchors.rightMargin: 8; spacing: 12
                                    WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                                    Text {
                                        visible: !root.compactNav
                                        text: modelData.name; color: "#f2f2f2"; font.pixelSize: 12
                                        font.weight: root.settingsPage === modelData.name ? Font.DemiBold : Font.Normal
                                        Layout.fillWidth: true; elide: Text.ElideRight
                                    }
                                }
                                MouseArea {
                                    id: catHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.settingsPage = modelData.name;
                                        root.navExpandedManual = false;
                                        root.refreshLiveState();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // [B] RIGHT MAIN CONTENT SURFACE (100% Fluid, Auto-Sizing Cards, Zero Clip!)
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
                anchors.margins: root.narrowBody ? 16 : 26
                contentWidth: width
                contentHeight: bodyCol.implicitHeight + 28
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: bodyCol
                    width: Math.min(parent.width, 940)
                    spacing: 14

                    // Page Header Row + Live Toast Feedback
                    RowLayout {
                        width: parent.width; spacing: 12
                        Text {
                            text: root.settingsPage
                            color: "#f5f5f5"; font.pixelSize: root.narrowBody ? 22 : 26; font.weight: Font.DemiBold
                            Layout.fillWidth: true; elide: Text.ElideRight
                        }
                        Rectangle {
                            visible: root.toastMsg !== ""
                            width: Math.min(280, toastTxt.implicitWidth + 20); height: 28; radius: 5
                            color: "#264cc2ff"; border.color: "#4cc2ff"; border.width: 1
                            Text {
                                id: toastTxt; anchors.centerIn: parent
                                width: Math.min(260, implicitWidth)
                                text: root.toastMsg; color: "#ffffff"; font.pixelSize: 11; elide: Text.ElideRight
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 0: INICIO (Windows 11 Bento Dashboard!)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 12
                        visible: root.settingsPage === "Inicio"

                        // Responsive Device Hero Banner (stacks cleanly on narrow windows!)
                        Rectangle {
                            width: parent.width
                            implicitHeight: homeHeroFlow.implicitHeight + 28
                            radius: 8; color: "#252525"; border.color: "#1effffff"; border.width: 1

                            ColumnLayout {
                                id: homeHeroFlow
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                anchors.margins: 14; spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 14
                                    Rectangle {
                                        width: root.narrowBody ? 84 : 112; height: root.narrowBody ? 50 : 66; radius: 6
                                        color: "#000000"; border.color: "#444444"; border.width: 2; clip: true
                                        Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: root.activeWallpaperSrc; fillMode: Image.PreserveAspectCrop }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: root.sysInfo.hostname || "Equipo X64"; color: "#f5f5f5"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: root.sysInfo.cpu || ""; color: "#a8a8a8"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Text { text: "X64 LIOS • " + (root.sysInfo.ram || "") + " • " + (root.hwState.monitors || ""); color: "#4cc2ff"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                    }
                                }

                                // Quick Status Chips (Responsive Flow!)
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    Rectangle {
                                        width: stNetRow.implicitWidth + 20; height: 34; radius: 6
                                        color: hNetH.containsMouse ? "#323232" : "#2c2c2c"; border.color: "#1effffff"
                                        Row {
                                            id: stNetRow; anchors.centerIn: parent; spacing: 8
                                            WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; iconFile: root.hwState.wifiEnabled ? "fluent-wifi.svg" : "fluent-wifi-off.svg" }
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: root.hwState.wifiEnabled ? (root.hwState.wifiSsid || "Conectado") : "Sin Wi-Fi"; color: "#f0f0f0"; font.pixelSize: 12 }
                                        }
                                        MouseArea { id: hNetH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsPage = "Red e Internet" }
                                    }
                                    Rectangle {
                                        width: stUpdRow.implicitWidth + 20; height: 34; radius: 6
                                        color: hUpdH.containsMouse ? "#323232" : "#2c2c2c"; border.color: "#1effffff"
                                        Row {
                                            id: stUpdRow; anchors.centerIn: parent; spacing: 8
                                            WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; iconFile: "update.svg" }
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Actualización del sistema"; color: "#f0f0f0"; font.pixelSize: 12 }
                                        }
                                        MouseArea { id: hUpdH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsPage = "Actualización del sistema" }
                                    }
                                    Rectangle {
                                        width: stAccRow.implicitWidth + 20; height: 34; radius: 6
                                        color: hAccH.containsMouse ? "#323232" : "#2c2c2c"; border.color: "#1effffff"
                                        Row {
                                            id: stAccRow; anchors.centerIn: parent; spacing: 8
                                            WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; iconFile: "fluent-person.svg" }
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Cuenta y foto de perfil"; color: "#f0f0f0"; font.pixelSize: 12 }
                                        }
                                        MouseArea { id: hAccH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsPage = "Cuentas" }
                                    }
                                }
                            }
                        }

                        // Responsive 2-Column Bento Cards (automatically 1 column when narrowBody!)
                        GridLayout {
                            width: parent.width
                            columns: root.narrowBody ? 1 : 2
                            rowSpacing: 12; columnSpacing: 12

                            // Card 1: Configuración recomendada
                            Rectangle {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
                                implicitHeight: recCol.implicitHeight + 28
                                radius: 8; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: recCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 6
                                    Text { text: "Configuración recomendada"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                    Text { text: "Accesos rápidos frecuentes del equipo"; color: "#9a9a9a"; font.pixelSize: 11 }
                                    Item { height: 4 }
                                    Repeater {
                                        model: [
                                            { icon: "fluent-display.svg",     label: "Pantalla y escala de monitores", page: "Sistema" },
                                            { icon: "fluent-speaker-high.svg",label: "Salida de audio PipeWire",       page: "Sistema" },
                                            { icon: "fluent-person.svg",      label: "Imagen de perfil y cuenta",      page: "Cuentas" },
                                            { icon: "fluent-paint-brush.svg", label: "Fondo de escritorio y barra",    page: "Personalización" }
                                        ]
                                        delegate: Rectangle {
                                            Layout.fillWidth: true; height: 38; radius: 5
                                            color: rLinkH.containsMouse ? "#323232" : "#202020"
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                                WinSvg { width: 16; height: 16; iconFile: modelData.icon }
                                                Text { text: modelData.label; color: "#f0f0f0"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                                WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                            }
                                            MouseArea { id: rLinkH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsPage = modelData.page }
                                        }
                                    }
                                }
                            }

                            // Card 2: Personaliza tu dispositivo
                            Rectangle {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
                                implicitHeight: persHomeCol.implicitHeight + 28
                                radius: 8; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: persHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 10
                                    Text { text: "Personaliza tu dispositivo"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 8
                                        Repeater {
                                            model: [
                                                { mode: 0, src: wpDirUrl + "win11-bloom-dark.jpg" },
                                                { mode: 1, src: wpDirUrl + "win11-bloom-light.jpg" },
                                                { mode: 2, src: wpDirUrl + "x64-monolith.jpg" }
                                            ]
                                            delegate: Rectangle {
                                                Layout.fillWidth: true; height: 58; radius: 6; clip: true
                                                border.color: root.cfg.wallpaperMode === modelData.mode ? "#4cc2ff" : "#33ffffff"
                                                border.width: root.cfg.wallpaperMode === modelData.mode ? 2 : 1
                                                Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: modelData.src; fillMode: Image.PreserveAspectCrop }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.updateCfg("wallpaperMode", modelData.mode) }
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Luz nocturna"; color: "#e6e6e6"; font.pixelSize: 12; Layout.fillWidth: true }
                                        Win11Switch { checked: Boolean(root.cfg.nightLight); onToggled: (v) => root.updateCfg("nightLight", v) }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Barra de tareas compacta"; color: "#e6e6e6"; font.pixelSize: 12; Layout.fillWidth: true }
                                        Win11Switch { checked: Boolean(root.cfg.taskbarCompact); onToggled: (v) => root.updateCfg("taskbarCompact", v) }
                                    }
                                }
                            }

                            // Card 3: Almacenamiento (clickable -> Sistema)
                            Rectangle {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
                                implicitHeight: stoHomeCol.implicitHeight + 28
                                radius: 8; color: stoHomeH.containsMouse ? "#2c2c2c" : "#262626"; border.color: "#1cffffff"; border.width: 1
                                MouseArea { id: stoHomeH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsPage = "Sistema" }
                                ColumnLayout {
                                    id: stoHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8
                                    RowLayout {
                                        Layout.fillWidth: true
                                        WinSvg { width: 18; height: 18; iconFile: "drive-c.svg" }
                                        Text { text: "Almacenamiento"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        WinSvg { width: 12; height: 12; iconFile: "fluent-chevron-right.svg"; opacity: 0.7 }
                                    }
                                    Text { text: root.drives.length > 0 ? root.drives[0].name : "Disco principal"; color: "#d4d4d4"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 8; radius: 4; color: "#383838"
                                        Rectangle { width: parent.width * (root.drives.length > 0 ? root.drives[0].usedRatio : 0.2); height: 8; radius: 4; color: "#4cc2ff" }
                                    }
                                    Text { text: root.drives.length > 0 ? root.drives[0].info : ""; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                }
                            }

                            // Card 4: Bluetooth y Perfil de Energía
                            Rectangle {
                                Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
                                implicitHeight: btHomeCol.implicitHeight + 28
                                radius: 8; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                                ColumnLayout {
                                    id: btHomeCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14; spacing: 8
                                    RowLayout {
                                        Layout.fillWidth: true
                                        WinSvg { width: 18; height: 18; iconFile: "fluent-bluetooth.svg" }
                                        Text { text: "Bluetooth y energía"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "Bluetooth (" + (root.extData.btDevices ? root.extData.btDevices.length : 0) + " vinculados)"; color: "#d8d8d8"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Win11Switch {
                                            checked: Boolean(root.hwState.btEnabled)
                                            onToggled: (v) => {
                                                var cp = Object.assign({}, root.hwState); cp.btEnabled = v; root.hwState = cp;
                                                bridge.setBluetoothEnabled(v);
                                                root.refreshLiveState();
                                            }
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 30; radius: 5
                                        color: pwrLinkH.containsMouse ? "#323232" : "#202020"
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                            Text { text: "Modo de energía activo"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true }
                                            Text { text: root.hwState.cpuGovernor || "Equilibrado"; color: "#4cc2ff"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        }
                                        MouseArea { id: pwrLinkH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.settingsPage = "Sistema" }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 1: SISTEMA (Pantalla Multi-Monitor, Sonido PipeWire, Energía, Almacenamiento, Acerca de)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Sistema"

                        // 1. Pantalla & Monitores Reales (wlr-randr)
                        Text { text: "Pantalla"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold }

                        Rectangle {
                            width: parent.width
                            implicitHeight: dispCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: dispCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12

                                // Brillo
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: root.narrowBody ? 1 : 2
                                    rowSpacing: 8; columnSpacing: 14
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        WinSvg { width: 20; height: 20; iconFile: "fluent-brightness.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: "Brillo de pantalla"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: "Ajusta la luminancia del panel conectado"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: root.narrowBody; spacing: 10
                                        SettingsSlider {
                                            Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 180
                                            from: 10; to: 100
                                            value: root.localBrightPct
                                            onDraggingChanged: root.brightDragging = dragging
                                            onMovedValue: (v) => {
                                                var iv = Math.round(v);
                                                root.localBrightPct = iv;
                                                bridge.runCtlAction("brightness set " + iv);
                                            }
                                        }
                                        Text { text: root.localBrightPct + "%"; color: "#d4d4d4"; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                                // Real Connected Monitors Scale & Resolution/Hz Control (Persisted across reboots!)
                                Repeater {
                                    model: root.extData.monitors || []
                                    delegate: Rectangle {
                                        id: monCard
                                        readonly property string mName: modelData.name || ""
                                        readonly property real mScale: Number(modelData.scale || 1)
                                        readonly property string mCurMode: modelData.currentMode || ""
                                        Layout.fillWidth: true
                                        implicitHeight: monInner.implicitHeight + 20
                                        radius: 6; color: "#202020"; border.color: "#18ffffff"
                                        ColumnLayout {
                                            id: monInner; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10; spacing: 8
                                            RowLayout {
                                                Layout.fillWidth: true; spacing: 10
                                                WinSvg { width: 18; height: 18; iconFile: "fluent-display.svg" }
                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 1
                                                    Text { text: monCard.mName + "  •  " + (monCard.mCurMode || "Activa"); color: "#f2f2f2"; font.pixelSize: 12; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                                    Text { text: (modelData.desc || "") + " • Escala actual: " + Math.round(monCard.mScale * 100) + "%"; color: "#9a9a9a"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                                }
                                            }
                                            Flow {
                                                Layout.fillWidth: true; spacing: 6
                                                Text { text: "Escala:"; color: "#b0b0b0"; font.pixelSize: 11; height: 26; verticalAlignment: Text.AlignVCenter }
                                                Repeater {
                                                    model: ["1", "1.25", "1.5", "1.75", "2"]
                                                    delegate: Rectangle {
                                                        readonly property bool isCurSc: Math.abs(Number(modelData) - monCard.mScale) < 0.05
                                                        width: 48; height: 26; radius: 4
                                                        color: isCurSc ? "#4cc2ff" : (scHov.containsMouse ? "#383838" : "#2c2c2c")
                                                        Text { anchors.centerIn: parent; text: Math.round(Number(modelData) * 100) + "%"; color: parent.isCurSc ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCurSc ? Font.DemiBold : Font.Normal }
                                                        MouseArea {
                                                            id: scHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (bridge.applyMonitorSetting(monCard.mName, modelData, "")) {
                                                                    root.refreshLiveState();
                                                                    root.showToast("Escala aplicada y guardada en " + monCard.mName);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            Flow {
                                                visible: (modelData.modes || []).length > 1
                                                Layout.fillWidth: true; spacing: 6
                                                Text { text: "Modo:"; color: "#b0b0b0"; font.pixelSize: 11; height: 26; verticalAlignment: Text.AlignVCenter }
                                                Repeater {
                                                    model: (modelData.modes || []).slice(0, 6)
                                                    delegate: Rectangle {
                                                        readonly property bool isCurM: Boolean(modelData.current)
                                                        width: mTxt.implicitWidth + 16; height: 26; radius: 4
                                                        color: isCurM ? "#4cc2ff" : (mHov.containsMouse ? "#383838" : "#2c2c2c")
                                                        Text { id: mTxt; anchors.centerIn: parent; text: modelData.label; color: parent.isCurM ? "#000000" : "#e8e8e8"; font.pixelSize: 11; font.weight: parent.isCurM ? Font.DemiBold : Font.Normal }
                                                        MouseArea {
                                                            id: mHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (bridge.applyMonitorSetting(monCard.mName, "", modelData.arg)) {
                                                                    root.refreshLiveState();
                                                                    root.showToast("Resolución aplicada: " + modelData.label);
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
                        }

                        ToggleCard {
                            iconFile: "fluent-night-light.svg"
                            title: "Luz nocturna"
                            subtitle: "Aplica tonos cálidos suaves (~4800K) para reducir la fatiga visual"
                            checked: Boolean(root.cfg.nightLight)
                            onToggled: (v) => root.updateCfg("nightLight", v)
                        }

                        // 2. Sonido PipeWire Real (Volumen + Silenciar + Selector de Dispositivo de Salida + Micrófono!)
                        Text { text: "Sonido"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 4 }

                        Rectangle {
                            width: parent.width
                            implicitHeight: sndCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: sndCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12

                                // Salida Maestra
                                GridLayout {
                                    Layout.fillWidth: true; columns: root.narrowBody ? 1 : 2; rowSpacing: 8; columnSpacing: 14
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        Rectangle {
                                            width: 32; height: 32; radius: 5; color: muteH.containsMouse ? "#383838" : "#2f2f2f"
                                            WinSvg { anchors.centerIn: parent; width: 18; height: 18; iconFile: root.hwState.muted ? "fluent-speaker-mute.svg" : "fluent-speaker-high.svg" }
                                            MouseArea { id: muteH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bridge.toggleAudioMute(); root.refreshLiveState(); } }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: "Volumen de salida"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: root.hwState.muted ? "Silenciado (clic en el altavoz para activar)" : "Audio PipeWire de baja latencia"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: root.narrowBody; spacing: 10
                                        SettingsSlider {
                                            Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 180
                                            from: 0; to: 100
                                            value: root.localVolPct
                                            onDraggingChanged: root.volDragging = dragging
                                            onMovedValue: (v) => {
                                                var iv = Math.round(v);
                                                root.localVolPct = iv;
                                                bridge.setPipewireVolume(iv);
                                            }
                                        }
                                        Text { text: root.localVolPct + "%"; color: "#d4d4d4"; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                    }
                                }

                                // Real Output Sinks Picker
                                ColumnLayout {
                                    visible: (root.extData.sinks || []).length > 0
                                    Layout.fillWidth: true; spacing: 6
                                    Text { text: "Elegir dónde reproducir el sonido:"; color: "#b8b8b8"; font.pixelSize: 11 }
                                    Repeater {
                                        model: root.extData.sinks || []
                                        delegate: Rectangle {
                                            Layout.fillWidth: true; height: 36; radius: 5
                                            color: modelData.active ? "#26384a" : (sinkH.containsMouse ? "#2e2e2e" : "#202020")
                                            border.color: modelData.active ? "#4cc2ff" : "#18ffffff"; border.width: 1
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                                Rectangle { width: 10; height: 10; radius: 5; color: modelData.active ? "#4cc2ff" : "transparent"; border.color: modelData.active ? "#4cc2ff" : "#777777"; border.width: 1.5 }
                                                Text { text: modelData.name; color: "#f2f2f2"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                                Text { visible: Boolean(modelData.active); text: "Predeterminado"; color: "#4cc2ff"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                            }
                                            MouseArea {
                                                id: sinkH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (bridge.setDefaultAudioSink(modelData.id)) {
                                                        root.refreshLiveState();
                                                        root.showToast("Salida cambiada a " + modelData.name);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }

                                // Micrófono
                                GridLayout {
                                    Layout.fillWidth: true; columns: root.narrowBody ? 1 : 2; rowSpacing: 8; columnSpacing: 14
                                    RowLayout {
                                        Layout.fillWidth: true; spacing: 12
                                        Rectangle {
                                            width: 32; height: 32; radius: 5; color: micMuteH.containsMouse ? "#383838" : "#2f2f2f"
                                            WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: root.extData.micMuted ? "fluent-speaker-mute.svg" : "fluent-call.svg" }
                                            MouseArea { id: micMuteH; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bridge.toggleMicMute(); root.refreshLiveState(); } }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: "Entrada y micrófono"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                            Text { text: root.extData.micMuted ? "Micrófono silenciado" : "Sensibilidad de entrada predeterminada"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: root.narrowBody; spacing: 10
                                        SettingsSlider {
                                            Layout.fillWidth: root.narrowBody; Layout.preferredWidth: 180
                                            from: 0; to: 100
                                            value: root.localMicPct
                                            onDraggingChanged: root.micDragging = dragging
                                            onMovedValue: (v) => {
                                                var iv = Math.round(v);
                                                root.localMicPct = iv;
                                                bridge.setMicVolume(iv);
                                            }
                                        }
                                        Text { text: root.localMicPct + "%"; color: "#d4d4d4"; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                                    }
                                }
                            }
                        }

                        // 3. Energía y Notificaciones
                        Text { text: "Energía y notificaciones"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 4 }

                        Rectangle {
                            width: parent.width; implicitHeight: pwrCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: pwrCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-plug.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text { text: "Modo de energía"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { text: "Optimiza tu equipo según consumo energético o rendimiento máximo"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    Repeater {
                                        model: [
                                            { id: "power-saver", label: "Ahorro de energía" },
                                            { id: "balanced",    label: "Equilibrado" },
                                            { id: "performance", label: "Alto rendimiento" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: root.hwState.powerProfile === modelData.id
                                            width: pLbl.implicitWidth + 24; height: 32; radius: 5
                                            color: isCur ? "#4cc2ff" : (pModeHov.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? "#4cc2ff" : "#22ffffff"
                                            Text { id: pLbl; anchors.centerIn: parent; text: modelData.label; color: parent.isCur ? "#000000" : "#f0f0f0"; font.pixelSize: 12; font.weight: parent.isCur ? Font.DemiBold : Font.Normal }
                                            MouseArea {
                                                id: pModeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var copy = Object.assign({}, root.hwState);
                                                    copy.powerProfile = modelData.id;
                                                    root.hwState = copy;
                                                    bridge.runCtlAction("power-profile " + modelData.id);
                                                    root.showToast("Modo de energía: " + modelData.label);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ToggleCard {
                            iconFile: "fluent-bell-snooze.svg"
                            title: "No molestar"
                            subtitle: "Silencia los banners emergentes de notificaciones y los archiva en el centro de notificaciones"
                            checked: Boolean(root.cfg.doNotDisturb)
                            onToggled: (v) => root.updateCfg("doNotDisturb", v)
                        }

                        // 4. Almacenamiento (ALL mounted drives!)
                        Text { text: "Almacenamiento"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 4 }

                        Rectangle {
                            width: parent.width; implicitHeight: allStoCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: allStoCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 12
                                Repeater {
                                    model: root.drives
                                    delegate: ColumnLayout {
                                        Layout.fillWidth: true; spacing: 5
                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 10
                                            WinSvg { width: 20; height: 20; iconFile: modelData.icon || "drive-c.svg" }
                                            Text { text: modelData.name; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: Math.round(Number(modelData.usedRatio || 0) * 100) + "%"; color: modelData.isCritical ? "#f87171" : "#4cc2ff"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true; height: 8; radius: 4; color: "#383838"
                                            Rectangle { width: parent.width * Number(modelData.usedRatio || 0.1); height: 8; radius: 4; color: modelData.isCritical ? "#d13438" : "#4cc2ff" }
                                        }
                                        Text { text: modelData.info; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn {
                                        label: (root.extData.tools && root.extData.tools.hasGnomeDisks) ? "Abrir Discos" : "Instalar gestor de discos"
                                        onClicked: {
                                            if (root.extData.tools && root.extData.tools.hasGnomeDisks) {
                                                bridge.launchRealApp("gnome-disks");
                                            } else {
                                                bridge.launchRealApp("/usr/bin/shelly-ui");
                                                root.showToast("Busca 'gnome-disk-utility' en Tienda Shelly");
                                            }
                                        }
                                    }
                                    FluentBtn { label: "Abrir Explorador"; onClicked: bridge.launchRealApp("/usr/bin/x64-win11-app explorer 'Este equipo'") }
                                }
                            }
                        }

                        // 5. Acerca de / Especificaciones del dispositivo (incluye TODAS las GPUs!)
                        Text { text: "Acerca de"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold; topPadding: 4 }

                        Rectangle {
                            width: parent.width; implicitHeight: specsCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: specsCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 8
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 10
                                    Text { text: "Especificaciones del dispositivo"; color: "#f5f5f5"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                    FluentBtn {
                                        label: root.copiedNotice ? "Copiado" : "Copiar"
                                        accent: root.copiedNotice
                                        onClicked: {
                                            var gpuTxt = (root.sysInfo.gpus || []).map(function(g) { return g.label + ": " + g.name; }).join(" + ") || root.hwState.gpu;
                                            bridge.copyTextToClipboard(root.sysInfo.hostname + " | " + root.sysInfo.cpu + " | RAM " + root.sysInfo.ram + " | " + gpuTxt + " | Kernel " + root.sysInfo.kernel);
                                            root.copiedNotice = true;
                                            root.showToast("Especificaciones copiadas");
                                        }
                                    }
                                }
                                Rectangle { Layout.fillWidth: true; height: 1; color: "#18ffffff" }
                                Text { text: "Nombre del dispositivo:   " + (root.sysInfo.hostname || "PC"); color: "#d4d4d4"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Text { text: "Procesador:   " + root.sysInfo.cpu + " (" + root.sysInfo.cpuCores + " hilos @ " + root.sysInfo.cpuGhz + ")"; color: "#d4d4d4"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Text { text: "RAM instalada:   " + root.sysInfo.ram; color: "#d4d4d4"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                Repeater {
                                    model: (root.sysInfo.gpus && root.sysInfo.gpus.length > 0) ? root.sysInfo.gpus : [{ label: "GPU 0", name: root.hwState.gpu, vramStr: "" }]
                                    delegate: Text {
                                        text: modelData.label + ":   " + modelData.name + (modelData.vramStr ? (" (" + modelData.vramStr + ")") : "")
                                        color: "#d4d4d4"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                    }
                                }
                                Text { text: "Sistema operativo:   X64 LIOS — Escritorio 26H2  •  Kernel " + root.sysInfo.kernel + " (" + root.sysInfo.sched + ")"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 2: BLUETOOTH Y DISPOSITIVOS
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Bluetooth y dispositivos"

                        Rectangle {
                            width: parent.width; implicitHeight: btTopCol.implicitHeight + 28
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            ColumnLayout {
                                id: btTopCol; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 16; spacing: 10
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 14
                                    WinSvg { width: 22; height: 22; iconFile: "fluent-bluetooth.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Bluetooth"; color: "#f2f2f2"; font.pixelSize: 14; font.weight: Font.DemiBold }
                                        Text { text: root.hwState.btEnabled ? "Detectable y listo para emparejar accesorios" : "Bluetooth desactivado"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                    Win11Switch {
                                        checked: Boolean(root.hwState.btEnabled)
                                        onToggled: (v) => {
                                            var cp = Object.assign({}, root.hwState); cp.btEnabled = v; root.hwState = cp;
                                            bridge.setBluetoothEnabled(v);
                                            root.refreshLiveState();
                                            root.showToast(v ? "Bluetooth activado" : "Bluetooth desactivado");
                                        }
                                    }
                                }
                                Flow {
                                    Layout.fillWidth: true; spacing: 8
                                    FluentBtn {
                                        label: (root.extData.tools && root.extData.tools.hasBlueman) ? "+ Agregar dispositivo" : "Instalar gestor Bluetooth"
                                        accent: true
                                        onClicked: bridge.launchRealApp((root.extData.tools && root.extData.tools.hasBlueman) ? "blueman-manager" : "/usr/bin/shelly-ui")
                                    }
                                    FluentBtn { label: "Actualizar lista"; onClicked: { root.refreshLiveState(); root.showToast("Lista Bluetooth actualizada"); } }
                                }
                            }
                        }

                        // Paired Bluetooth Devices List
                        Column {
                            width: parent.width; spacing: 6
                            visible: (root.extData.btDevices || []).length > 0
                            Text { text: "Dispositivos emparejados (" + (root.extData.btDevices ? root.extData.btDevices.length : 0) + ")"; color: "#b8b8b8"; font.pixelSize: 12; font.weight: Font.DemiBold }
                            Repeater {
                                model: root.extData.btDevices || []
                                delegate: Rectangle {
                                    width: parent.width; implicitHeight: btDevRow.implicitHeight + 22
                                    radius: 6; color: modelData.connected ? "#263646" : "#262626"; border.color: modelData.connected ? "#4cc2ff" : "#1cffffff"; border.width: 1
                                    RowLayout {
                                        id: btDevRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 14; spacing: 12
                                        WinSvg { width: 18; height: 18; iconFile: "fluent-bluetooth.svg" }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 1
                                            Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                                            Text { text: (modelData.connected ? "Conectado • " : "Emparejado • ") + modelData.mac; color: modelData.connected ? "#4cc2ff" : "#9a9a9a"; font.pixelSize: 11 }
                                        }
                                        FluentBtn {
                                            label: modelData.connected ? "Desconectar" : "Conectar"
                                            accent: !modelData.connected
                                            onClicked: {
                                                bridge.toggleBluetoothDevice(modelData.mac, !modelData.connected);
                                                root.showToast((modelData.connected ? "Desconectando " : "Conectando ") + modelData.name + "...");
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; implicitHeight: phoneRow.implicitHeight + 24
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            GridLayout {
                                id: phoneRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16
                                columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-phone.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Dispositivos móviles y Enlace Móvil"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text {
                                            text: (root.extData.tools && root.extData.tools.hasKdeConnect)
                                                  ? "Sincroniza mensajes, notificaciones y archivos con tu teléfono mediante KDE Connect"
                                                  : "Instala KDE Connect desde Tienda Shelly para sincronizar tu móvil Android o iPhone"
                                            color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                                FluentBtn {
                                    label: (root.extData.tools && root.extData.tools.hasKdeConnect) ? "Abrir Enlace Móvil" : "Instalar (Tienda Shelly)"
                                    onClicked: {
                                        if (root.extData.tools && root.extData.tools.hasKdeConnect) {
                                            bridge.launchRealApp("kdeconnect-app || kdeconnect-settings");
                                        } else {
                                            bridge.launchRealApp("/usr/bin/shelly-ui");
                                            root.showToast("Busca 'kdeconnect' en Tienda Shelly");
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; implicitHeight: prnRow.implicitHeight + 24
                            radius: 6; color: "#262626"; border.color: "#1cffffff"; border.width: 1
                            GridLayout {
                                id: prnRow; anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.margins: 16
                                columns: root.narrowBody ? 1 : 2; rowSpacing: 10; columnSpacing: 12
                                RowLayout {
                                    Layout.fillWidth: true; spacing: 12
                                    WinSvg { width: 20; height: 20; iconFile: "fluent-settings.svg" }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: "Impresoras y escáneres"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.Medium }
                                        Text { text: "Administra impresoras locales y de red mediante CUPS"; color: "#9e9e9e"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                    }
                                }
                                FluentBtn {
                                    label: (root.extData.tools && root.extData.tools.hasPrinterGui) ? "Configurar" : "Instalar (Tienda Shelly)"
                                    onClicked: {
                                        if (root.extData.tools && root.extData.tools.hasPrinterGui) {
                                            bridge.launchRealApp("system-config-printer");
                                        } else {
                                            bridge.launchRealApp("/usr/bin/shelly-ui");
                                            root.showToast("Busca 'system-config-printer' en Tienda Shelly");
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
}
