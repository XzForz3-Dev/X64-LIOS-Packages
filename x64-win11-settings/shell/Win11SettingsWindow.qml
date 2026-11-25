import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1020
    height: 680
    color: "#202020"

    function normalizePageName(raw) {
        var s = String(raw || "").trim();
        if (s === "" || s.indexOf("Personalizaci") === 0) return "Personalización";
        if (s.indexOf("Juegos") === 0) return "Juegos";
        if (s.indexOf("Windows") === 0 || s.indexOf("Update") !== -1) return "Windows Update";
        if (s === "Sistema" || s === "Bluetooth y dispositivos" || s === "Red e Internet" || s === "Aplicaciones") return s;
        return "Personalización";
    }

    property string settingsPage: normalizePageName(typeof initialArg !== "undefined" ? initialArg : "")
    property string navFilter: ""
    property string appSearchFilter: ""
    property bool copiedNotice: false

    property var cfg: ({
        "taskbarCompact": false,
        "taskbarLeftAlign": false,
        "showRecommended": false,
        "showPhoneLink": true,
        "showBatteryPct": true,
        "showDesktopIcons": true,
        "desktopIconSizeMode": "medium",
        "nightLight": false,
        "wallpaperMode": 0
    })

    property var sysInfo: ({
        "user": "Usuario",
        "username": "x64",
        "hostname": "x64-pc",
        "userEmail": "x64@x64-pc",
        "cpu": "Procesador x86_64",
        "cpuCores": 8,
        "cpuGhz": "3.40 GHz",
        "ram": "16.0 GB",
        "kernel": "Linux",
        "sched": "scx_lavd"
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
        "localIp": "192.168.1.10",
        "gpu": "GPU activa",
        "monitors": "1920x1080"
    })

    property var drives: []
    property var installedApps: []

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
            color: wSwitch.checked ? "#4cc2ff" : (wSwitch.hovered ? "#24ffffff" : "#14000000")
            border.color: wSwitch.checked ? "#4cc2ff" : "#99ffffff"
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

    // Smooth WinUI 3 Slider matching Quick Settings 1:1
    component SettingsSlider : Item {
        id: sSlider
        property real from: 0.0
        property real to: 100.0
        property real value: 80.0
        signal movedValue(real v)
        implicitWidth: 200
        implicitHeight: 30

        readonly property real ratio: Math.max(0.0, Math.min(1.0, (value - from) / Math.max(0.001, to - from)))

        Item {
            x: 11; anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, sSlider.width - 22); height: 4
            Rectangle { anchors.fill: parent; radius: 2; color: "#767676" }
            Rectangle { width: sSlider.ratio * parent.width; height: 4; radius: 2; color: "#4cc2ff" }
        }

        Item {
            x: sSlider.ratio * Math.max(0, sSlider.width - 22)
            anchors.verticalCenter: parent.verticalCenter
            width: 22; height: 22
            Image { anchors.fill: parent; source: assetDirUrl + "fluent-slider-outer.svg"; sourceSize.width: 96; sourceSize.height: 96; mipmap: true; smooth: true }
            Image {
                anchors.fill: parent; transformOrigin: Item.Center
                scale: sMouse.pressed ? 0.44 : (sMouse.containsMouse ? 0.68 : 0.56)
                Behavior on scale { NumberAnimation { duration: 115; easing.type: Easing.OutCubic } }
                source: assetDirUrl + "fluent-slider-inner.svg"; sourceSize.width: 96; sourceSize.height: 96; mipmap: true; smooth: true
            }
        }

        MouseArea {
            id: sMouse
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            function syncX(mx) {
                var r = Math.max(0.0, Math.min(1.0, (mx - 11.0) / Math.max(1.0, sSlider.width - 22.0)));
                var nv = sSlider.from + r * (sSlider.to - sSlider.from);
                sSlider.value = nv;
                sSlider.movedValue(nv);
            }
            onPressed: (mouse) => syncX(mouse.x)
            onPositionChanged: (mouse) => { if (pressed) syncX(mouse.x); }
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
    }

    Component.onCompleted: {
        try { sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
        try { installedApps = JSON.parse(bridge.getInstalledAppsJson()); } catch (e) {}
        refreshLiveState();
    }

    Timer {
        interval: 3000; running: true; repeat: true
        onTriggered: root.refreshLiveState()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // [A] Authentic Windows 11 26H2 Left Navigation Rail
        Rectangle {
            Layout.preferredWidth: 264
            Layout.fillHeight: true
            color: "#202020"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // User Account Header Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 6
                    color: accHov.containsMouse ? "#282828" : "transparent"

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 12
                        Rectangle {
                            width: 42; height: 42; radius: 21
                            color: "#2f2f2f"; border.color: "#2affffff"; border.width: 1
                            WinSvg { anchors.centerIn: parent; width: 22; height: 22; iconFile: "fluent-person.svg" }
                        }
                        Column {
                            Layout.fillWidth: true; spacing: 1
                            Text { text: root.sysInfo.user || "Usuario"; color: "#f5f5f5"; font.weight: Font.DemiBold; font.pixelSize: 13; elide: Text.ElideRight }
                            Text { text: "Cuenta local • " + (root.sysInfo.hostname || "PC"); color: "#9e9e9e"; font.pixelSize: 11; elide: Text.ElideRight }
                        }
                    }
                    MouseArea { id: accHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.settingsPage = "Sistema" }
                }

                // WinUI 3 Search Settings Input
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 5
                    color: navSearchIn.activeFocus ? "#171717" : "#2a2a2a"
                    border.color: "#24ffffff"
                    border.width: 1
                    clip: true

                    Rectangle {
                        anchors.bottom: parent.bottom; width: parent.width
                        height: navSearchIn.activeFocus ? 2 : 1
                        color: navSearchIn.activeFocus ? "#4cc2ff" : "#55ffffff"
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                        TextInput {
                            id: navSearchIn
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#ffffff"; font.pixelSize: 12; selectByMouse: true
                            onTextChanged: root.navFilter = text
                            Text {
                                visible: navSearchIn.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Buscar una configuración"
                                color: "#9a9a9a"; font.pixelSize: 12
                            }
                        }
                        WinSvg { width: 14; height: 14; iconFile: "fluent-search.svg"; opacity: 0.8 }
                    }
                }

                // 7 Official Categories
                Column {
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: [
                            { icon: "fluent-display.svg",     name: "Sistema" },
                            { icon: "fluent-bluetooth.svg",   name: "Bluetooth y dispositivos" },
                            { icon: "fluent-wifi.svg",        name: "Red e Internet" },
                            { icon: "fluent-paint-brush.svg", name: "Personalización" },
                            { icon: "fluent-apps-list.svg",   name: "Aplicaciones" },
                            { icon: "fluent-games.svg",       name: "Juegos" },
                            { icon: "update.svg",             name: "Windows Update" }
                        ]
                        delegate: Rectangle {
                            visible: root.navFilter.trim() === "" || modelData.name.toLowerCase().indexOf(root.navFilter.trim().toLowerCase()) !== -1
                            width: 232; height: 36; radius: 5
                            color: root.settingsPage === modelData.name ? "#2d2d2d" : (catHov.containsMouse ? "#262626" : "transparent")
                            Rectangle {
                                visible: root.settingsPage === modelData.name
                                x: 2; anchors.verticalCenter: parent.verticalCenter
                                width: 3; height: 16; radius: 1.5; color: "#4cc2ff"
                            }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 12
                                WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                                Text {
                                    text: modelData.name
                                    color: "#f2f2f2"
                                    font.pixelSize: 12
                                    font.weight: root.settingsPage === modelData.name ? Font.DemiBold : Font.Normal
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }
                            MouseArea {
                                id: catHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.settingsPage = modelData.name
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // [B] Right Main Settings Content Surface
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1b1b1b"
            radius: 8

            Flickable {
                anchors.fill: parent
                anchors.margins: 28
                contentWidth: width
                contentHeight: bodyCol.implicitHeight + 24
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: bodyCol
                    width: parent.width
                    spacing: 16

                    // Page Title
                    Text {
                        text: root.settingsPage
                        color: "#f5f5f5"
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                    }

                    // Top Device Hero Banner (shown on Sistema & Personalización)
                    Rectangle {
                        visible: root.settingsPage === "Sistema" || root.settingsPage === "Personalización"
                        width: parent.width
                        height: 88
                        radius: 8
                        color: "#252525"
                        border.color: "#1effffff"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 16
                            Rectangle {
                                width: 104; height: 60; radius: 5; color: "#000000"; border.color: "#444444"; border.width: 2; clip: true
                                Image {
                                    anchors.fill: parent; anchors.margins: 2; cache: false
                                    source: root.cfg.wallpaperMode === 0 ? (wpDirUrl + "win11-bloom-dark.jpg") : (root.cfg.wallpaperMode === 1 ? (wpDirUrl + "win11-bloom-light.jpg") : (wpDirUrl + "x64-monolith.jpg"))
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                            Column {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: root.sysInfo.hostname || "PC"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                Text { text: root.sysInfo.cpu || ""; color: "#a8a8a8"; font.pixelSize: 11; elide: Text.ElideRight; width: 320 }
                                Text { text: root.hwState.monitors || ""; color: "#4cc2ff"; font.pixelSize: 11 }
                            }
                            Row {
                                spacing: 10
                                WinSvg { anchors.verticalCenter: parent.verticalCenter; width: 22; height: 22; iconFile: "update.svg" }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text { text: "Windows Update"; color: "#f2f2f2"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    Text { text: "Todo actualizado"; color: "#6ccb5f"; font.pixelSize: 11 }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 1: SISTEMA (Pantalla, Sonido, Energía, Almacenamiento, Acerca de)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 8
                        visible: root.settingsPage === "Sistema"

                        // Pantalla: Brillo
                        Rectangle {
                            width: parent.width; height: 66; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 20; height: 20; iconFile: "fluent-brightness.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Brillo de pantalla"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Ajusta la luminancia en todos los monitores conectados (" + root.hwState.monitors + ")"; color: "#9e9e9e"; font.pixelSize: 11; elide: Text.ElideRight }
                                }
                                SettingsSlider {
                                    width: 190
                                    from: 10; to: 100
                                    value: Number(root.hwState.brightnessPct || 100)
                                    onMovedValue: (v) => bridge.runCtlAction("brightness set " + Math.round(v))
                                }
                                Text { text: Math.round(root.hwState.brightnessPct || 100) + "%"; color: "#d4d4d4"; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
                            }
                        }

                        // Luz nocturna
                        Rectangle {
                            width: parent.width; height: 60; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 20; height: 20; iconFile: "fluent-night-light.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Luz nocturna"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Usa colores más cálidos para ayudar a reducir la fatiga visual"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Win11Switch { checked: Boolean(root.cfg.nightLight); onToggled: root.updateCfg("nightLight", checked) }
                            }
                        }

                        // Sonido PipeWire
                        Rectangle {
                            width: parent.width; height: 66; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 20; height: 20; iconFile: root.hwState.muted ? "fluent-speaker-mute.svg" : "fluent-speaker-high.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Sonido y volumen maestro"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Salida PipeWire de baja latencia"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                SettingsSlider {
                                    width: 190
                                    from: 0; to: 100
                                    value: Number(root.hwState.volumePct || 80)
                                    onMovedValue: (v) => bridge.setPipewireVolume(Math.round(v))
                                }
                                Rectangle {
                                    width: 92; height: 30; radius: 5; color: "#323232"; border.color: "#22ffffff"
                                    Text { anchors.centerIn: parent; text: "Mezclador"; color: "#f0f0f0"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("pavucontrol") }
                                }
                            }
                        }

                        // Energía y batería (3 estados reales)
                        Rectangle {
                            width: parent.width; height: 70; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 20; height: 20; iconFile: "fluent-plug.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Modo de energía"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Optimiza tu equipo según consumo energético o rendimiento máximo"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: [
                                            { id: "power-saver", label: "Ahorro" },
                                            { id: "balanced",    label: "Equilibrado" },
                                            { id: "performance", label: "Alto rendimiento" }
                                        ]
                                        delegate: Rectangle {
                                            readonly property bool isCur: root.hwState.powerProfile === modelData.id
                                            width: pLbl.implicitWidth + 20; height: 30; radius: 5
                                            color: isCur ? "#4cc2ff" : (pModeHov.containsMouse ? "#383838" : "#2f2f2f")
                                            border.color: isCur ? "#4cc2ff" : "#22ffffff"
                                            Text {
                                                id: pLbl; anchors.centerIn: parent
                                                text: modelData.label
                                                color: parent.isCur ? "#000000" : "#f0f0f0"
                                                font.pixelSize: 11
                                                font.weight: parent.isCur ? Font.DemiBold : Font.Normal
                                            }
                                            MouseArea {
                                                id: pModeHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var copy = Object.assign({}, root.hwState);
                                                    copy.powerProfile = modelData.id;
                                                    root.hwState = copy;
                                                    bridge.runCtlAction("power-profile " + modelData.id);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Almacenamiento real
                        Rectangle {
                            width: parent.width; height: 78; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 22; height: 22; iconFile: "drive-c.svg" }
                                Column {
                                    Layout.fillWidth: true; spacing: 6
                                    Text { text: "Almacenamiento — " + (root.drives.length > 0 ? root.drives[0].name : "Disco (C:)"); color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Rectangle {
                                        width: 320; height: 8; radius: 4; color: "#383838"
                                        Rectangle {
                                            width: parent.width * (root.drives.length > 0 ? root.drives[0].usedRatio : 0.25)
                                            height: 8; radius: 4; color: "#4cc2ff"
                                        }
                                    }
                                    Text { text: root.drives.length > 0 ? root.drives[0].info : ""; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    width: 110; height: 30; radius: 5; color: "#323232"; border.color: "#22ffffff"
                                    Text { anchors.centerIn: parent; text: "Administrar"; color: "#f0f0f0"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("gnome-disks") }
                                }
                            }
                        }

                        // Acerca de / Especificaciones del dispositivo
                        Rectangle {
                            width: parent.width; height: specsCol.implicitHeight + 28; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            Column {
                                id: specsCol
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                anchors.margins: 16; spacing: 8
                                RowLayout {
                                    width: parent.width
                                    Text { text: "Especificaciones del dispositivo y del sistema"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                    Rectangle {
                                        width: 96; height: 28; radius: 5; color: root.copiedNotice ? "#4cc2ff" : "#333333"
                                        Text { anchors.centerIn: parent; text: root.copiedNotice ? "Copiado" : "Copiar"; color: root.copiedNotice ? "#000000" : "#f0f0f0"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                bridge.copyTextToClipboard(root.sysInfo.hostname + " | " + root.sysInfo.cpu + " | RAM " + root.sysInfo.ram + " | GPU " + root.hwState.gpu + " | Kernel " + root.sysInfo.kernel);
                                                root.copiedNotice = true;
                                            }
                                        }
                                    }
                                }
                                Text { text: "Procesador:  " + root.sysInfo.cpu + " (" + root.sysInfo.cpuCores + " hilos @ " + root.sysInfo.cpuGhz + ")"; color: "#c8c8c8"; font.pixelSize: 12 }
                                Text { text: "RAM instalada:  " + root.sysInfo.ram; color: "#c8c8c8"; font.pixelSize: 12 }
                                Text { text: "Gráficos:  " + root.hwState.gpu; color: "#c8c8c8"; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                                Text { text: "Edición:  X64 Windows 11 26H2 Edition  •  Kernel " + root.sysInfo.kernel + " (" + root.sysInfo.sched + ")"; color: "#9e9e9e"; font.pixelSize: 11 }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 2: BLUETOOTH Y DISPOSITIVOS
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 8
                        visible: root.settingsPage === "Bluetooth y dispositivos"

                        Rectangle {
                            width: parent.width; height: 68; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 22; height: 22; iconFile: "fluent-bluetooth.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Bluetooth"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: root.hwState.btEnabled ? "Detectable y listo para emparejar accesorios" : "Bluetooth desactivado"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    width: 148; height: 32; radius: 5; color: "#4cc2ff"
                                    Text { anchors.centerIn: parent; text: "+ Agregar dispositivo"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("blueman-manager") }
                                }
                                Win11Switch {
                                    checked: Boolean(root.hwState.btEnabled)
                                    onToggled: bridge.runCtlAction("bluetooth toggle")
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 64; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 20; height: 20; iconFile: "fluent-phone.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Dispositivos móviles y Enlace Móvil"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Sincroniza mensajes, llamadas, fotos y archivos desde Android o iPhone"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    width: 136; height: 30; radius: 5; color: "#323232"; border.color: "#22ffffff"
                                    Text { anchors.centerIn: parent; text: "Abrir Enlace Móvil"; color: "#f0f0f0"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("kdeconnect-app") }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 64; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 20; height: 20; iconFile: "fluent-settings.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Impresoras y escáneres"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Administra impresoras locales y en red mediante CUPS"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    width: 136; height: 30; radius: 5; color: "#323232"; border.color: "#22ffffff"
                                    Text { anchors.centerIn: parent; text: "Configurar"; color: "#f0f0f0"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("system-config-printer") }
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
                            width: parent.width; height: 82; radius: 8; color: "#252525"; border.color: "#1effffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 16
                                WinSvg { width: 34; height: 34; iconFile: root.hwState.wifiEnabled ? "fluent-wifi.svg" : "fluent-wifi-off.svg" }
                                Column {
                                    Layout.fillWidth: true; spacing: 2
                                    Text { text: root.hwState.wifiEnabled ? (root.hwState.wifiSsid + " — Conectado") : "Wi-Fi desconectado"; color: "#f5f5f5"; font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Text { text: "Red privada • Dirección IPv4: " + (root.hwState.localIp || "N/A"); color: "#9e9e9e"; font.pixelSize: 12 }
                                }
                                Rectangle {
                                    width: 156; height: 32; radius: 5; color: "#323232"; border.color: "#22ffffff"
                                    Text { anchors.centerIn: parent; text: "Opciones avanzadas"; color: "#f0f0f0"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("nm-connection-editor") }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 60; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 20; height: 20; iconFile: "fluent-wifi.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Wi-Fi"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Conéctate a redes inalámbricas cercanas"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Win11Switch {
                                    checked: Boolean(root.hwState.wifiEnabled)
                                    onToggled: bridge.runCtlAction("wifi " + (checked ? "on" : "off"))
                                }
                            }
                        }

                        Repeater {
                            model: root.hwState.wifiNetworks || []
                            delegate: Rectangle {
                                width: parent.width; height: 56; radius: 6
                                color: modelData.active ? "#26333f" : "#262626"
                                border.color: modelData.active ? "#4cc2ff" : "#1cffffff"
                                border.width: 1
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                                    WinSvg { width: 18; height: 18; iconFile: "fluent-wifi.svg" }
                                    Column {
                                        Layout.fillWidth: true
                                        Text { text: modelData.ssid || "Red"; color: "#f5f5f5"; font.pixelSize: 12; font.weight: modelData.active ? Font.DemiBold : Font.Normal }
                                        Text { text: (modelData.active ? "Conectado, seguro • " : "") + "Señal " + (modelData.signal || 0) + "% • " + (modelData.security || "WPA2"); color: modelData.active ? "#4cc2ff" : "#9e9e9e"; font.pixelSize: 11 }
                                    }
                                    Rectangle {
                                        visible: !modelData.active
                                        width: 88; height: 28; radius: 5; color: "#4cc2ff"
                                        Text { anchors.centerIn: parent; text: "Conectar"; color: "#000000"; font.pixelSize: 11; font.weight: Font.DemiBold }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: bridge.runCtlAction("wifi connect " + modelData.ssid)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 4: PERSONALIZACIÓN (Temas, Barra, Inicio, Escritorio)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 8
                        visible: root.settingsPage === "Personalización"

                        Rectangle {
                            width: parent.width; height: 96; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 12
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Seleccionar un tema"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Cambia el fondo 4K Windows Bloom en todos tus monitores al instante"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Repeater {
                                    model: [
                                        { mode: 0, src: wpDirUrl + "win11-bloom-dark.jpg" },
                                        { mode: 1, src: wpDirUrl + "win11-bloom-light.jpg" },
                                        { mode: 2, src: wpDirUrl + "x64-monolith.jpg" }
                                    ]
                                    delegate: Rectangle {
                                        width: 98; height: 62; radius: 6; clip: true
                                        border.color: root.cfg.wallpaperMode === modelData.mode ? "#4cc2ff" : "#33ffffff"
                                        border.width: root.cfg.wallpaperMode === modelData.mode ? 2 : 1
                                        Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: modelData.src; fillMode: Image.PreserveAspectCrop }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.updateCfg("wallpaperMode", modelData.mode) }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Alineación de la barra de tareas a la izquierda"; color: "#f2f2f2"; font.pixelSize: 13 }
                                    Text { text: "Alterna entre el diseño centrado de Windows 11 y el alineado a la izquierda"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Win11Switch { checked: Boolean(root.cfg.taskbarLeftAlign); onToggled: root.updateCfg("taskbarLeftAlign", checked) }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Barra de tareas compacta"; color: "#f2f2f2"; font.pixelSize: 13 }
                                    Text { text: "Reduce la altura de la barra de tareas de 48 px a 38 px"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Win11Switch { checked: Boolean(root.cfg.taskbarCompact); onToggled: root.updateCfg("taskbarCompact", checked) }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Panel lateral Enlace Móvil en el Menú Inicio"; color: "#f2f2f2"; font.pixelSize: 13 }
                                    Text { text: "Muestra el panel rápido de tu teléfono junto al Menú Inicio"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Win11Switch { checked: Boolean(root.cfg.showPhoneLink); onToggled: root.updateCfg("showPhoneLink", checked) }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Mostrar iconos del escritorio"; color: "#f2f2f2"; font.pixelSize: 13 }
                                    Text { text: "Muestra u oculta los accesos directos en el escritorio principal"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Win11Switch { checked: root.cfg.showDesktopIcons !== false; onToggled: root.updateCfg("showDesktopIcons", checked) }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 5: APLICACIONES (Aplicaciones instaladas + Tienda Shelly)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Aplicaciones"

                        RowLayout {
                            width: parent.width; spacing: 10
                            Rectangle {
                                Layout.fillWidth: true; height: 36; radius: 5; color: "#262626"; border.color: "#22ffffff"
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                                    WinSvg { width: 15; height: 15; iconFile: "fluent-search.svg" }
                                    TextInput {
                                        id: appFilterIn
                                        Layout.fillWidth: true; color: "#ffffff"; font.pixelSize: 12; selectByMouse: true
                                        onTextChanged: root.appSearchFilter = text
                                        Text { visible: appFilterIn.text === ""; text: "Buscar en " + root.installedApps.length + " aplicaciones instaladas..."; color: "#9a9a9a"; font.pixelSize: 12 }
                                    }
                                }
                            }
                            Rectangle {
                                width: 164; height: 36; radius: 5; color: "#4cc2ff"
                                Text { anchors.centerIn: parent; text: "Abrir Tienda Shelly"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("/usr/bin/shelly-ui") }
                            }
                        }

                        Repeater {
                            model: root.installedApps
                            delegate: Rectangle {
                                visible: root.appSearchFilter.trim() === "" || modelData.name.toLowerCase().indexOf(root.appSearchFilter.trim().toLowerCase()) !== -1
                                width: parent.width; height: 54; radius: 6; color: "#262626"; border.color: "#18ffffff"
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 12
                                    WinSvg { width: 26; height: 26; iconUrl: modelData.iconUrl || "" }
                                    Column {
                                        Layout.fillWidth: true
                                        Text { text: modelData.name; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { text: modelData.id; color: "#8e8e8e"; font.pixelSize: 11 }
                                    }
                                    Rectangle {
                                        width: 78; height: 28; radius: 5; color: "#333333"; border.color: "#22ffffff"
                                        Text { anchors.centerIn: parent; text: "Abrir"; color: "#f2f2f2"; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp(modelData.cmd) }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 6: JUEGOS (Modo Juego Real + Herramientas Gaming)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Juegos"

                        Rectangle {
                            width: parent.width; height: 68; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 22; height: 22; iconFile: "fluent-games.svg" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Modo Juego (Gaming X64)"; color: "#f5f5f5"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Prioriza frecuencias máximas de CPU y baja latencia en el planificador " + root.sysInfo.sched; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Win11Switch {
                                    checked: root.hwState.powerProfile === "performance"
                                    onToggled: bridge.runCtlAction("power-profile " + (checked ? "performance" : "balanced"))
                                }
                            }
                        }

                        Repeater {
                            model: [
                                { title: "Steam",              desc: "Plataforma principal con Proton-CachyOS preconfigurado", cmd: "steam",    icon: "steam.svg" },
                                { title: "GOverlay & MangoHud", desc: "Superposición de FPS, frametime y telemetría Vulkan/OpenGL", cmd: "goverlay", icon: "fluent-games.svg" },
                                { title: "X64 Hello Gaming",   desc: "Instalador rápido de launchers, codecs y optimizaciones", cmd: "x64-hello", icon: "x64lios.png" }
                            ]
                            delegate: Rectangle {
                                width: parent.width; height: 62; radius: 6; color: "#262626"; border.color: "#1cffffff"
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 14
                                    WinSvg { width: 24; height: 24; iconFile: modelData.icon }
                                    Column {
                                        Layout.fillWidth: true
                                        Text { text: modelData.title; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { text: modelData.desc; color: "#9e9e9e"; font.pixelSize: 11 }
                                    }
                                    Rectangle {
                                        width: 92; height: 30; radius: 5; color: "#323232"; border.color: "#22ffffff"
                                        Text { anchors.centerIn: parent; text: "Ejecutar"; color: "#f0f0f0"; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp(modelData.cmd) }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // PAGE 7: WINDOWS UPDATE (X64 Update & Repositorios)
                    // =========================================================
                    Column {
                        width: parent.width; spacing: 12
                        visible: root.settingsPage === "Windows Update"

                        Rectangle {
                            width: parent.width; height: 96; radius: 8; color: "#252525"; border.color: "#1effffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 18; spacing: 18
                                WinSvg { width: 42; height: 42; iconFile: "update.svg" }
                                Column {
                                    Layout.fillWidth: true; spacing: 4
                                    Text { text: "Todo está actualizado"; color: "#f5f5f5"; font.pixelSize: 18; font.weight: Font.DemiBold }
                                    Text { text: "Kernel activo: " + root.sysInfo.kernel + " • Repositorios X64 LIOS y CachyOS sincronizados"; color: "#9e9e9e"; font.pixelSize: 12 }
                                }
                                Rectangle {
                                    width: 176; height: 36; radius: 5; color: "#4cc2ff"
                                    Text { anchors.centerIn: parent; text: "Buscar actualizaciones"; color: "#000000"; font.pixelSize: 12; font.weight: Font.DemiBold }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("x64-update") }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 64; radius: 6; color: "#262626"; border.color: "#1cffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 14
                                WinSvg { width: 22; height: 22; iconUrl: "file:///usr/share/icons/hicolor/256x256/apps/shelly.png" }
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Administrador gráfico de paquetes (Tienda Shelly)"; color: "#f2f2f2"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: "Gestiona actualizaciones de aplicaciones nativas, AUR y Flatpak"; color: "#9e9e9e"; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    width: 118; height: 30; radius: 5; color: "#323232"; border.color: "#22ffffff"
                                    Text { anchors.centerIn: parent; text: "Abrir Shelly"; color: "#f0f0f0"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: bridge.launchRealApp("/usr/bin/shelly-ui") }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
