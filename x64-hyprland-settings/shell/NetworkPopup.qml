import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: netWindow

    signal closeRequested()

    property bool ethConnected: true
    property string ethDevice: "eth0"
    property string ethName: "Cable Ethernet"
    property string ipAddr: "0.0.0.0"
    property string gwAddr: "--"
    property string dnsAddr: "--"

    property bool hasWifiHw: false
    property bool wifiEnabled: true
    property bool wifiConnected: false
    property string wifiSsid: ""
    property string wifiDevice: "wlan0"
    property var networks: []

    property string passwordSsid: ""
    property string passwordInput: ""
    property string statusMsg: ""
    property bool isBusy: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 32
    }

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: netWindow.passwordSsid !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function refreshNet(doScan) {
        if (netStatusProc.running) return;
        if (doScan) {
            netWindow.statusMsg = "Escaneando redes...";
            netStatusProc.command = ["x64-hyprland-ctl", "net", "scan"];
        } else {
            netStatusProc.command = ["x64-hyprland-ctl", "net", "status"];
        }
        netStatusProc.running = true;
    }

    function runNetCmd(args) {
        if (netActionProc.running) return;
        netWindow.isBusy = true;
        netActionProc.command = ["x64-hyprland-ctl", "net"].concat(args);
        netActionProc.running = true;
    }

    Process {
        id: netStatusProc
        command: ["x64-hyprland-ctl", "net", "status"]
        stdout: StdioCollector {
            id: netStatusCollector
            onStreamFinished: {
                if (!netStatusCollector.text) return;
                try {
                    var d = JSON.parse(netStatusCollector.text.trim());
                    netWindow.ethConnected = Boolean(d.ethConnected);
                    netWindow.ethDevice = d.ethDevice || "eth0";
                    netWindow.ethName = d.ethName || "Cable Ethernet";
                    netWindow.ipAddr = d.ip || "Desconectado";
                    netWindow.gwAddr = d.gateway || "--";
                    netWindow.dnsAddr = d.dns || "--";
                    netWindow.hasWifiHw = Boolean(d.hasWifiHw);
                    netWindow.wifiEnabled = Boolean(d.wifiEnabled);
                    netWindow.wifiConnected = Boolean(d.wifiConnected);
                    netWindow.wifiSsid = d.wifiSsid || "";
                    netWindow.wifiDevice = d.wifiDevice || "wlan0";
                    netWindow.networks = d.networks || [];
                    if (netWindow.statusMsg === "Escaneando redes...") {
                        netWindow.statusMsg = "";
                    }
                } catch (e) {}
            }
        }
    }

    Process {
        id: netActionProc
        stdout: StdioCollector {
            id: netActionCollector
            onStreamFinished: {
                netWindow.isBusy = false;
                var out = (netActionCollector.text || "").trim();
                if (out.indexOf("OK") !== -1) {
                    netWindow.passwordSsid = "";
                    netWindow.passwordInput = "";
                    netWindow.statusMsg = "Conectado correctamente";
                } else if (out.indexOf("ERR:") !== -1) {
                    netWindow.statusMsg = "Contraseña incorrecta o fallo al conectar";
                }
                netWindow.refreshNet(false);
            }
        }
    }

    Timer {
        interval: 3000
        running: netWindow.visible && netWindow.passwordSsid === ""
        repeat: true
        triggeredOnStart: true
        onTriggered: netWindow.refreshNet(false)
    }

    // Outside click dismiss backdrop
    MouseArea {
        anchors.fill: parent
        onClicked: {
            netWindow.passwordSsid = "";
            netWindow.closeRequested();
        }
    }

    // Network Popup Card anchored below Island 3B Network Indicator
    Rectangle {
        id: card
        width: 356
        height: cardLayout.implicitHeight + 30
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 4
            rightMargin: 96
        }
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        // Consume inside clicks
        MouseArea {
            anchors.fill: parent
        }

        // Top Neon Crimson Glow Bar
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: 24
                rightMargin: 24
            }
            height: 2
            radius: 1
            color: Theme.accent
        }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            // =========================================================
            // 1. HEADER: TITLE, STATUS SUBTITLE, SCAN & CLOSE
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "󰖩 CENTRO DE RED X64"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.accent
                    }
                    Text {
                        text: {
                            if (netWindow.statusMsg !== "") return netWindow.statusMsg;
                            if (netWindow.wifiConnected) return "󰤨 Wi-Fi: " + netWindow.wifiSsid;
                            if (netWindow.ethConnected) return "󰈀 Ethernet Activo (" + netWindow.ethDevice + ")";
                            return "󰤮 Sin conexión activa";
                        }
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: (netWindow.ethConnected || netWindow.wifiConnected) ? "#10b981" : Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // Rescan Button
                Rectangle {
                    visible: netWindow.hasWifiHw && netWindow.wifiEnabled
                    implicitWidth: 24
                    implicitHeight: 22
                    radius: 6
                    color: scanArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: scanArea.containsMouse ? Theme.accent : Theme.textSecondary
                    }

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: netWindow.refreshNet(true)
                    }
                }

                Text {
                    text: "󰅖"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: Theme.textMuted
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            netWindow.passwordSsid = "";
                            netWindow.closeRequested();
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            // =========================================================
            // 2. ETHERNET (LAN) & IP / GATEWAY / DNS CARD
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 92
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: 7
                            color: netWindow.ethConnected ? "#1f10b981" : "#1affffff"
                            border.color: netWindow.ethConnected ? "#4410b981" : Theme.borderSubtle
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰈀"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: netWindow.ethConnected ? "#10b981" : Theme.textMuted
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: "Red Cableada (LAN)"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: netWindow.ethDevice + " • " + (netWindow.ethConnected ? "Conectado (1 Gbps)" : "Cable desconectado")
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: netWindow.ethConnected ? "#10b981" : Theme.textMuted
                            }
                        }

                        // Toggle Ethernet Interface Button
                        Rectangle {
                            implicitHeight: 22
                            implicitWidth: ethBtnText.implicitWidth + 14
                            radius: 6
                            color: ethBtnArea.containsMouse ? (netWindow.ethConnected ? "#33ff2b2b" : Theme.accent) : "#18ffffff"
                            border.color: ethBtnArea.containsMouse ? Theme.accent : Theme.borderSubtle
                            border.width: 1

                            Text {
                                id: ethBtnText
                                anchors.centerIn: parent
                                text: netWindow.ethConnected ? "Activo" : "Conectar"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: netWindow.ethConnected ? "#10b981" : Theme.textPrimary
                            }

                            MouseArea {
                                id: ethBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: netWindow.runNetCmd(["eth-toggle", netWindow.ethDevice])
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#14ffffff"
                    }

                    // IP / Gateway / DNS Strip
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: "DIRECCIÓN IP"; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted }
                            Text { text: netWindow.ipAddr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: "#00e5ff" }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: "GATEWAY"; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted }
                            Text { text: netWindow.gwAddr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textSecondary }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: "DNS PRIMARIO"; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted }
                            Text { text: netWindow.dnsAddr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: "#a855f7" }
                        }
                    }
                }
            }

            // =========================================================
            // 3. WI-FI SECTION (RADIO TOGGLE + SCANNER + PASSWORD INPUT)
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: wifiCol.implicitHeight + 20
                radius: Theme.radiusSm
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    id: wifiCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Wi-Fi Header & Radio Switch
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "󰤨 Redes Inalámbricas (Wi-Fi)"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: netWindow.hasWifiHw
                            implicitHeight: 20
                            implicitWidth: 44
                            radius: 10
                            color: netWindow.wifiEnabled ? Theme.accent : "#252534"
                            border.color: netWindow.wifiEnabled ? Theme.accentLight : Theme.borderSubtle
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: netWindow.wifiEnabled ? "ON" : "OFF"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: "#ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    netWindow.wifiEnabled = !netWindow.wifiEnabled;
                                    netWindow.runNetCmd(["wifi", "toggle"]);
                                }
                            }
                        }
                    }

                    // Case A: No physical Wi-Fi adapter (Desktop PC / VM)
                    Rectangle {
                        visible: !netWindow.hasWifiHw
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: 6
                        color: "#12ffffff"
                        border.color: "#1affffff"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: "󰈀"
                                font.family: Theme.fontMono
                                font.pixelSize: 16
                                color: Theme.accent
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Estación conectada por Ethernet LAN directo. Si conectas un adaptador Wi-Fi USB/PCIe aparecerán aquí las redes inalámbricas."
                                font.family: Theme.fontSans
                                font.pixelSize: 9
                                color: Theme.textSecondary
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    // Case B: Wi-Fi Hardware exists, but Radio is OFF
                    Text {
                        visible: netWindow.hasWifiHw && !netWindow.wifiEnabled
                        Layout.fillWidth: true
                        text: "󰤮 El radio Wi-Fi está apagado. Actívalo arriba para buscar redes."
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }

                    // Case C: Wi-Fi Networks List
                    ColumnLayout {
                        visible: netWindow.hasWifiHw && netWindow.wifiEnabled
                        Layout.fillWidth: true
                        spacing: 5

                        Repeater {
                            model: netWindow.networks
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: (netWindow.passwordSsid === modelData.ssid) ? 74 : 36
                                radius: 6
                                color: modelData.connected ? "#1c10b981" : (netRowArea.containsMouse ? Theme.bgHover : "#14ffffff")
                                border.color: modelData.connected ? "#4410b981" : (netWindow.passwordSsid === modelData.ssid ? Theme.accent : "#1affffff")
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 7
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: modelData.signal >= 75 ? "󰤨" : (modelData.signal >= 50 ? "󰤥" : (modelData.signal >= 25 ? "󰤢" : "󰤟"))
                                            font.family: Theme.fontMono
                                            font.pixelSize: 12
                                            color: modelData.connected ? "#10b981" : Theme.textPrimary
                                        }

                                        Text {
                                            text: modelData.ssid
                                            font.family: Theme.fontSans
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.textPrimary
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: (modelData.security !== "Abierta" ? "󰌾 " : "") + modelData.security + " • " + modelData.signal + "%"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textMuted
                                        }

                                        Rectangle {
                                            implicitHeight: 20
                                            implicitWidth: actTxt.implicitWidth + 12
                                            radius: 5
                                            color: modelData.connected ? "#2810b981" : Theme.accent
                                            Text {
                                                id: actTxt
                                                anchors.centerIn: parent
                                                text: modelData.connected ? "Conectado" : "Conectar"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: modelData.connected ? "#10b981" : "#ffffff"
                                            }
                                        }
                                    }

                                    // Inline Password Prompt when connecting to a secured Wi-Fi network
                                    RowLayout {
                                        visible: netWindow.passwordSsid === modelData.ssid
                                        Layout.fillWidth: true
                                        spacing: 6

                                        TextField {
                                            id: passField
                                            Layout.fillWidth: true
                                            implicitHeight: 24
                                            placeholderText: "Contraseña de " + modelData.ssid
                                            placeholderTextColor: Theme.textMuted
                                            echoMode: TextInput.Password
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            color: Theme.textPrimary
                                            onTextChanged: netWindow.passwordInput = text
                                            onAccepted: netWindow.runNetCmd(["connect", modelData.ssid, netWindow.passwordInput])
                                            background: Rectangle {
                                                radius: 4
                                                color: "#0b0b10"
                                                border.color: Theme.accent
                                                border.width: 1
                                            }
                                        }

                                        Rectangle {
                                            implicitWidth: 62
                                            implicitHeight: 24
                                            radius: 4
                                            color: Theme.accent
                                            Text {
                                                anchors.centerIn: parent
                                                text: "Entrar"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: "#ffffff"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: netWindow.runNetCmd(["connect", modelData.ssid, netWindow.passwordInput])
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: netRowArea
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 36
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) {
                                            netWindow.runNetCmd(["disconnect", modelData.ssid]);
                                        } else if (modelData.saved || modelData.security === "Abierta") {
                                            netWindow.runNetCmd(["connect", modelData.ssid]);
                                        } else {
                                            if (netWindow.passwordSsid === modelData.ssid) {
                                                netWindow.passwordSsid = "";
                                            } else {
                                                netWindow.passwordInput = "";
                                                netWindow.passwordSsid = modelData.ssid;
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
            // 4. ADVANCED NETWORK SETTINGS BUTTON (nm-connection-editor)
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: Theme.radiusSm
                color: advArea.containsMouse ? Theme.accent : Theme.bgCard
                border.color: advArea.containsMouse ? Theme.accentLight : Theme.borderAccent
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰒓"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: advArea.containsMouse ? "#ffffff" : Theme.accent
                    }
                    Text {
                        text: "Ajustes Avanzados de Red / VPN"
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                MouseArea {
                    id: advArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch('hl.dsp.exec_cmd("nm-connection-editor")');
                        netWindow.passwordSsid = "";
                        netWindow.closeRequested();
                    }
                }
            }
        }
    }
}

