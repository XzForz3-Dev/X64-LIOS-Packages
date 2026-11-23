import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 960
    height: 650
    color: "#202020"

    property string settingsPage: (typeof initialArg !== "undefined" && initialArg !== "") ? initialArg : "Personalización (26H2)"
    property var cfg: ({
        "taskbarCompact": false,
        "taskbarLeftAlign": false,
        "showRecommended": false,
        "showPhoneLink": true,
        "showBatteryPct": true,
        "wallpaperMode": 0
    })
    property var sysInfo: ({ "user": "Usuario", "username": "x64", "hostname": "x64-pc", "userEmail": "x64@x64-pc", "cpu": "Procesador x86_64", "ram": "16 GB", "kernel": "Linux", "sched": "scx_lavd", "diskLabel": "Disco del Sistema (BTRFS)" })
    property var drives: []

    component WinSvg : Image {
        property string iconFile: "settings.svg"
        Layout.preferredWidth: width
        Layout.preferredHeight: height
        Layout.maximumWidth: width
        Layout.maximumHeight: height
        source: assetDirUrl + iconFile
        sourceSize.width: 96
        sourceSize.height: 96
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    function updateCfg(key, val) {
        var copy = Object.assign({}, cfg);
        copy[key] = val;
        cfg = copy;
        bridge.setConfigValue(key, JSON.stringify(val));
    }

    Component.onCompleted: {
        try { cfg = JSON.parse(bridge.getConfigJson()); } catch (e) {}
        try { sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
        try { drives = JSON.parse(bridge.getDrivesJson()); } catch (e) {}
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left Sidebar
        Rectangle {
            Layout.preferredWidth: 245
            Layout.fillHeight: true
            color: "#202020"

            Column {
                anchors.fill: parent; anchors.margins: 16; spacing: 6

                Row {
                    spacing: 12
                    WinSvg { width: 42; height: 42; iconFile: "x64lios.png" }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: root.sysInfo.user || "Usuario"; color: "#ffffff"; font.bold: true; font.pixelSize: 13 }
                        Text { text: root.sysInfo.userEmail || "x64@x64lios"; color: "#999999"; font.pixelSize: 11 }
                    }
                }

                Item { width: 1; height: 12 }

                Repeater {
                    model: [
                        { icon: "thispc.svg",    name: "Sistema" },
                        { icon: "bluetooth.svg", name: "Bluetooth y dispositivos" },
                        { icon: "wifi.svg",      name: "Red e Internet" },
                        { icon: "windows.svg",   name: "Personalización (26H2)" },
                        { icon: "gaming.svg",    name: "Juegos (FalconD & scx_lavd)" },
                        { icon: "update.svg",    name: "Windows / X64 Update" }
                    ]
                    delegate: Rectangle {
                        width: 213; height: 36; radius: 5
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

        // Right Main Area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1c1c1c"
            radius: 8

            Flickable {
                anchors.fill: parent; anchors.margins: 26
                contentWidth: width; contentHeight: bodyCol.implicitHeight + 20; clip: true

                Column {
                    id: bodyCol; width: parent.width; spacing: 14

                    Text { text: root.settingsPage; color: "#ffffff"; font.pixelSize: 24; font.bold: true }

                    // Hero Header Card
                    Rectangle {
                        width: parent.width; height: 86; radius: 6; color: "#252525"; border.color: "#1fffffff"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 16
                            Rectangle {
                                width: 100; height: 58; radius: 4; color: "#000000"; border.color: "#555555"; border.width: 2
                                Image {
                                    anchors.fill: parent; anchors.margins: 2; cache: false
                                    source: root.cfg.wallpaperMode === 0 ? (wpDirUrl + "win11-bloom-dark.jpg") : (root.cfg.wallpaperMode === 1 ? (wpDirUrl + "win11-bloom-light.jpg") : (wpDirUrl + "x64-monolith.jpg"))
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }
                            Column {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: root.sysInfo.hostname; color: "#ffffff"; font.pixelSize: 15; font.bold: true }
                                Text { text: "X64 LIOS Windows 11 26H2 • " + root.sysInfo.cpu; color: "#aaaaaa"; font.pixelSize: 11; elide: Text.ElideRight; width: 340 }
                                Text { text: "Kernel " + root.sysInfo.kernel + " • " + root.sysInfo.sched; color: "#60cdff"; font.pixelSize: 11 }
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

                        Rectangle {
                            width: parent.width; height: 92; radius: 6; color: "#272727"; border.color: "#1fffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 14; spacing: 12
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Seleccionar un tema de Windows 11 26H2"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                                    Text { text: "Cambia el fondo 4K en tiempo real en todos tus monitores"; color: "#999999"; font.pixelSize: 11 }
                                }
                                Repeater {
                                    model: [
                                        { mode: 0, src: wpDirUrl + "win11-bloom-dark.jpg" },
                                        { mode: 1, src: wpDirUrl + "win11-bloom-light.jpg" },
                                        { mode: 2, src: wpDirUrl + "x64-monolith.jpg" }
                                    ]
                                    delegate: Rectangle {
                                        width: 96; height: 60; radius: 5
                                        border.color: root.cfg.wallpaperMode === modelData.mode ? "#60cdff" : "#33ffffff"
                                        border.width: root.cfg.wallpaperMode === modelData.mode ? 2 : 1
                                        Image { anchors.fill: parent; anchors.margins: 2; cache: false; source: modelData.src; fillMode: Image.PreserveAspectCrop }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.updateCfg("wallpaperMode", modelData.mode) }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#272727"; border.color: "#1fffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 14
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Iconos pequeños en la barra de tareas (Windows 11 26H2)"; color: "#ffffff"; font.pixelSize: 13 }
                                    Text { text: "Reduce la barra de tareas de 48 px a 38 px en tiempo real"; color: "#999999"; font.pixelSize: 11 }
                                }
                                Switch { checked: Boolean(root.cfg.taskbarCompact); onToggled: root.updateCfg("taskbarCompact", checked) }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#272727"; border.color: "#1fffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 14
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Alineación de la barra de tareas a la izquierda"; color: "#ffffff"; font.pixelSize: 13 }
                                    Text { text: "Alterna entre el diseño centrado y el diseño alineado a la izquierda"; color: "#999999"; font.pixelSize: 11 }
                                }
                                Switch { checked: Boolean(root.cfg.taskbarLeftAlign); onToggled: root.updateCfg("taskbarLeftAlign", checked) }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#272727"; border.color: "#1fffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 14
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Mostrar sección «Recomendado» en el Menú Inicio (26H2)"; color: "#ffffff"; font.pixelSize: 13 }
                                    Text { text: "Desactívalo para dejar un Menú Inicio unificado 100 % limpio"; color: "#999999"; font.pixelSize: 11 }
                                }
                                Switch { checked: Boolean(root.cfg.showRecommended); onToggled: root.updateCfg("showRecommended", checked) }
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 58; radius: 6; color: "#272727"; border.color: "#1fffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 14
                                Column {
                                    Layout.fillWidth: true
                                    Text { text: "Panel lateral Phone Link / KDE Connect en el Menú Inicio (26H2)"; color: "#ffffff"; font.pixelSize: 13 }
                                    Text { text: "Muestra el estado de tu teléfono Android/iPhone junto al Menú Inicio"; color: "#999999"; font.pixelSize: 11 }
                                }
                                Switch { checked: Boolean(root.cfg.showPhoneLink); onToggled: root.updateCfg("showPhoneLink", checked) }
                            }
                        }
                    }

                    // PAGE 2: SISTEMA
                    Column {
                        width: parent.width; spacing: 10
                        visible: root.settingsPage === "Sistema"

                        Repeater {
                            model: [
                                { icon: "thispc.svg", title: "Especificaciones del dispositivo (" + root.sysInfo.hostname + ")", desc: "CPU: " + root.sysInfo.cpu + "  |  RAM: " + root.sysInfo.ram },
                                { icon: "windows.svg", title: "Especificaciones de Windows 11 Edition (X64 LIOS)", desc: "Versión 26H2  |  Kernel " + root.sysInfo.kernel + "  |  Planificador activo: " + root.sysInfo.sched },
                                { icon: "audio.svg", title: "Sonido PipeWire Low-Latency (5.3 ms)", desc: "Piso cuántico anti-crackling activo para gaming y streaming" },
                                { icon: "drive-c.svg", title: "Almacenamiento NVMe Btrfs ZSTD", desc: root.drives.length > 0 ? root.drives[0].info : "NVMe Gen4" }
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

                    // PAGE 3, 4, 5, 6
                    Column {
                        width: parent.width; spacing: 12
                        visible: root.settingsPage !== "Personalización (26H2)" && root.settingsPage !== "Sistema"

                        Rectangle {
                            width: parent.width; height: 84; radius: 6; color: "#272727"; border.color: "#1fffffff"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 16
                                WinSvg { width: 38; height: 38; iconFile: root.settingsPage === "Windows / X64 Update" ? "update.svg" : (root.settingsPage === "Juegos (FalconD & scx_lavd)" ? "gaming.svg" : "x64lios.png") }
                                Column {
                                    Layout.fillWidth: true; spacing: 4
                                    Text { text: root.settingsPage; color: "#ffffff"; font.pixelSize: 15; font.bold: true }
                                    Text { text: "Conectado en vivo con el motor X64 LIOS (scx_lavd, FalconD, UFW, X64 Update y X64 Hello)"; color: "#999999"; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    width: 150; height: 34; radius: 5; color: "#0078d4"
                                    Text { anchors.centerIn: parent; text: root.settingsPage === "Windows / X64 Update" ? "Abrir X64 Update" : "Abrir X64 Hello"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: bridge.launchRealApp(root.settingsPage === "Windows / X64 Update" ? "x64-update" : "x64-hello")
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
