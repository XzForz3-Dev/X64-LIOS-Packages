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

    property string netDown: "0 KB/s"
    property string netUp: "0 KB/s"

    anchors {
        top: true
        right: true
    }

    margins {
        top: 44
        right: 96
    }

    implicitWidth: 400
    implicitHeight: Math.min(cardLayout.implicitHeight + 30, (screen ? screen.height : 1080) - 56)

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: netWindow.passwordSsid !== "" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool lockClose: false

    HyprlandFocusGrab {
        id: focusGrab
        active: netWindow.visible && !netWindow.lockClose
        windows: [netWindow]
        onCleared: {
            if (!netWindow.lockClose && netWindow.visible) {
                netWindow.passwordSsid = "";
                netWindow.closeAnimated();
            }
        }
    }

    function closeAnimated() {
        if (closeAnim.running) return;
        closeAnim.restart();
    }

    ParallelAnimation {
        id: openAnim
        running: false
        NumberAnimation {
            target: card
            property: "scale"
            from: 0.82
            to: 1.0
            duration: 270
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
        NumberAnimation {
            target: card
            property: "y"
            from: -24
            to: 0
            duration: 270
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
        NumberAnimation {
            target: card
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim
        running: false
        NumberAnimation {
            target: card
            property: "scale"
            to: 0.86
            duration: 150
            easing.type: Easing.InBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: card
            property: "y"
            to: -18
            duration: 150
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0.0
            duration: 130
            easing.type: Easing.InQuad
        }
        onFinished: {
            netWindow.passwordSsid = "";
            netWindow.closeRequested();
        }
    }

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
        id: netAppProc
    }

    function launchApp(cmdStr) {
        netWindow.passwordSsid = "";
        netWindow.closeRequested();
        if (netAppProc.running) {
            netAppProc.running = false;
        }
        netAppProc.command = ["bash", "-c", "nohup " + cmdStr + " >/dev/null 2>&1 &"];
        netAppProc.running = true;
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
                    if (typeof wifiListView !== "undefined" && wifiListView && wifiListView.applyNewNetworks) {
                        wifiListView.applyNewNetworks(d.networks || []);
                    } else {
                        netWindow.networks = d.networks || [];
                    }
                    netWindow.netDown = d.netDown || "0 KB/s";
                    netWindow.netUp = d.netUp || "0 KB/s";
                    if (netWindow.statusMsg === "Escaneando redes...") {
                        netWindow.statusMsg = "";
                    }
                } catch (e) {}
            }
        }
    }

    // Unified 1.5s timer for live transfer rates and status
    Timer {
        id: netLiveTimer
        interval: 1500
        repeat: true
        running: netWindow.visible && !netWindow.isBusy
        onTriggered: {
            if (!netStatusProc.running && !netActionProc.running) {
                netStatusProc.command = ["x64-hyprland-ctl", "net", "status"];
                netStatusProc.running = true;
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

    onVisibleChanged: {
        if (visible) {
            netWindow.refreshNet(true); // Active scan immediately when opened
            card.scale = 0.82;
            card.y = -24;
            card.opacity = 0.0;
            openAnim.restart();
        } else {
            card.scale = 1.0;
            card.y = 0;
            card.opacity = 1.0;
            netWindow.passwordSsid = "";
            if (typeof wifiListView !== "undefined" && wifiListView) {
                wifiListView.stickyY = 0;
                wifiListView.contentY = 0;
            }
        }
    }

    // Network Popup Card anchored below Island 3B Network Indicator with Jelly / Elastic Physics
    Rectangle {
        id: card
        anchors.fill: parent
        transformOrigin: Item.TopRight
        scale: 1.0
        opacity: 1.0
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            // =========================================================
            // 1. HEADER: TITLE, STATUS SUBTITLE & SCAN
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    spacing: 6
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: (netWindow.ethConnected || netWindow.wifiConnected) ? Theme.statusOk : Theme.accent
                    }
                    Text {
                        text: I18n.isEs ? "CONECTIVIDAD" : "CONNECTIVITY"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.1
                        color: Theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: {
                        if (netWindow.statusMsg !== "") return netWindow.statusMsg;
                        if (netWindow.wifiConnected) return "Wi-Fi: " + netWindow.wifiSsid;
                        if (netWindow.ethConnected) return I18n.isEs ? "Ethernet Activo" : "Ethernet Active";
                        return I18n.isEs ? "Sin conexión" : "Disconnected";
                    }
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textSecondary
                }
                // Rescan Button (with animated spin during scan)
                Rectangle {
                    visible: netWindow.hasWifiHw && netWindow.wifiEnabled
                    implicitWidth: 24
                    implicitHeight: 22
                    radius: 6
                    color: scanArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    Text {
                        id: scanIcon
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: (scanArea.containsMouse || netStatusProc.running) ? Theme.accent : Theme.textSecondary

                        RotationAnimation on rotation {
                            running: netStatusProc.running
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 800
                        }
                    }

                    MouseArea {
                        id: scanArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: netWindow.refreshNet(true)
                    }
                }
            }

            // =========================================================
            // 1B. ACTIVE INTERFACE, THROUGHPUT & ROUTING CARD
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: activeNetCol.implicitHeight + 16
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    id: activeNetCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Top Row: Active Interface, Device, and Live Speed Badges
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: netWindow.wifiConnected ? "󰖩" : (netWindow.ethConnected ? "󰈀" : "󰌙")
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: (netWindow.wifiConnected || netWindow.ethConnected) ? Theme.statusOk : Theme.textMuted
                        }

                        Text {
                            text: netWindow.wifiConnected ? (netWindow.wifiDevice + " • " + netWindow.wifiSsid) : (netWindow.ethConnected ? (netWindow.ethDevice + " • LAN") : (I18n.isEs ? "Sin conexión activa" : "No active connection"))
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Download Rate Badge
                        Rectangle {
                            implicitHeight: 22
                            implicitWidth: rxNetRow.implicitWidth + 12
                            radius: 6
                            color: Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1
                            RowLayout {
                                id: rxNetRow
                                anchors.centerIn: parent
                                spacing: 4
                                Text { text: "↓"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textSecondary }
                                Text { text: netWindow.netDown; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textPrimary }
                            }
                        }

                        // Upload Rate Badge
                        Rectangle {
                            implicitHeight: 22
                            implicitWidth: txNetRow.implicitWidth + 12
                            radius: 6
                            color: Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1
                            RowLayout {
                                id: txNetRow
                                anchors.centerIn: parent
                                spacing: 4
                                Text { text: "↑"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.textMuted }
                                Text { text: netWindow.netUp; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textSecondary }
                            }
                        }
                    }

                    // Bottom Row: Uniform 3-Column IP / Gateway / DNS Grid
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 6
                            color: Theme.bgElevated
                            border.color: "#0affffff"
                            border.width: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 1
                                Text { text: "IP LOCAL"; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted }
                                Text { text: netWindow.ipAddr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 6
                            color: Theme.bgElevated
                            border.color: "#0affffff"
                            border.width: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 1
                                Text { text: "GATEWAY"; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted }
                                Text { text: netWindow.gwAddr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 6
                            color: Theme.bgElevated
                            border.color: "#0affffff"
                            border.width: 1
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 1
                                Text { text: "DNS"; font.family: Theme.fontMono; font.pixelSize: 8; color: Theme.textMuted }
                                Text { text: netWindow.dnsAddr; font.family: Theme.fontMono; font.pixelSize: 9; font.bold: true; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 2. ETHERNET (LAN) ADAPTER
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 9

                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 8
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰈀"
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: netWindow.ethConnected ? Theme.textPrimary : Theme.textMuted
                        }
                    }

                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: I18n.netLanWired
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            text: netWindow.ethDevice + " • " + (netWindow.ethConnected ? "1 Gbps Full Duplex" : I18n.netCableDisconnected)
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textSecondary
                        }
                    }

                    // Ethernet Status Badge
                    Rectangle {
                        implicitHeight: 20
                        implicitWidth: ethBadgeRow.implicitWidth + 12
                        radius: 5
                        color: netWindow.ethConnected ? "#1434d399" : "transparent"
                        border.color: netWindow.ethConnected ? "#3334d399" : Theme.borderSubtle
                        border.width: 1

                        RowLayout {
                            id: ethBadgeRow
                            anchors.centerIn: parent
                            spacing: 4
                            Rectangle {
                                width: 5
                                height: 5
                                radius: 2.5
                                color: netWindow.ethConnected ? Theme.statusOk : Theme.textMuted
                            }
                            Text {
                                text: netWindow.ethConnected ? I18n.netConnected : (I18n.isEs ? "Sin cable" : "No cable")
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: netWindow.ethConnected
                                color: netWindow.ethConnected ? Theme.statusOk : Theme.textMuted
                            }
                        }

                        MouseArea {
                            id: ethBtnArea
                            anchors.fill: parent
                            enabled: netWindow.ethConnected
                            cursorShape: netWindow.ethConnected ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (netWindow.ethConnected) {
                                    netWindow.runNetCmd(["eth-toggle", netWindow.ethDevice]);
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // 3A. COMPACT WI-FI NOTICE (When no physical Wi-Fi adapter)
            // =========================================================
            Rectangle {
                visible: !netWindow.hasWifiHw
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 9
                color: "#08ffffff"
                border.color: Theme.borderSubtle
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8
                    Text { text: "󰤮"; font.family: Theme.fontMono; font.pixelSize: 12; color: Theme.textMuted }
                    Text { text: I18n.netEthernetOnlyNotice; font.family: Theme.fontSans; font.pixelSize: 9; color: Theme.textMuted; Layout.fillWidth: true; elide: Text.ElideRight }
                }
            }

            // =========================================================
            // 3B. WI-FI SECTION (Always expanded when Wi-Fi HW exists)
            // =========================================================
            Rectangle {
                visible: netWindow.hasWifiHw
                Layout.fillWidth: true
                implicitHeight: wifiCol.implicitHeight + 20
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    id: wifiCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Wi-Fi Header: Icon + Title & Radio Switch
                    RowLayout {
                        Layout.fillWidth: true

                        RowLayout {
                            spacing: 6
                            Text {
                                text: "󰤨"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: Theme.textSecondary
                            }
                            Text {
                                text: I18n.netWireless
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.textPrimary
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            id: wifiSwitchTrack
                            implicitWidth: 38
                            implicitHeight: 20
                            radius: 10
                            color: netWindow.wifiEnabled ? "#b80000" : "#1a1a20"
                            border.color: netWindow.wifiEnabled ? "#ff3333" : "#383842"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                id: wifiSwitchThumb
                                width: 14
                                height: 14
                                radius: 7
                                y: 3
                                x: netWindow.wifiEnabled ? 21 : 3
                                color: netWindow.wifiEnabled ? "#ffffff" : "#777782"
                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 150 } }
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

                    // Wi-Fi Hardware exists, but Radio is OFF
                    Text {
                        visible: !netWindow.wifiEnabled
                        Layout.fillWidth: true
                        text: I18n.netWifiOffNotice
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }

                    // Wi-Fi Networks Scrollable ListView
                    ListView {
                        id: wifiListView
                        visible: netWindow.wifiEnabled
                        Layout.fillWidth: true
                        implicitHeight: Math.min(185, Math.max(76, (netWindow.networks ? netWindow.networks.length : 0) * 40))
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        model: netWindow.networks

                        property real stickyY: 0
                        property bool updatingModel: false

                        onContentYChanged: {
                            if (!updatingModel) {
                                stickyY = Math.max(0, contentY);
                            }
                        }

                        function applyNewNetworks(newList) {
                            if (wifiScrollBar && wifiScrollBar.pressed) {
                                return;
                            }
                            if (moving || dragging || flicking) {
                                return;
                            }
                            updatingModel = true;
                            let savedY = stickyY;
                            netWindow.networks = newList;
                            contentY = Math.min(savedY, Math.max(0, contentHeight - height));
                            Qt.callLater(() => {
                                contentY = Math.min(savedY, Math.max(0, contentHeight - height));
                                updatingModel = false;
                            });
                        }

                        ScrollBar.vertical: ScrollBar {
                            id: wifiScrollBar
                            policy: wifiListView.count > 4 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            implicitWidth: 4
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: wifiScrollBar.pressed ? Theme.accent : (wifiScrollBar.hovered ? Theme.textPrimary : Theme.textMuted)
                            }
                            background: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: Theme.borderSubtle
                            }
                        }

                        delegate: Rectangle {
                            id: wifiRow
                            width: wifiListView.width - (wifiScrollBar.visible ? 8 : 0)
                            implicitHeight: (netWindow.passwordSsid === modelData.ssid) ? 76 : 36
                            radius: 7
                            readonly property bool isCurrent: Boolean(modelData.connected) || (netWindow.wifiConnected && modelData.ssid === netWindow.wifiSsid)
                            color: isCurrent ? Theme.bgElevated : (netRowArea.containsMouse ? Theme.bgHover : "#0cffffff")
                            border.color: isCurrent ? Theme.borderGlass : ((netWindow.passwordSsid === modelData.ssid) ? Theme.accentBorder : Theme.borderSubtle)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 7
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7

                                    Text {
                                        text: modelData.signal >= 75 ? "󰤨" : (modelData.signal >= 50 ? "󰤥" : (modelData.signal >= 25 ? "󰤢" : "󰤟"))
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: isCurrent ? Theme.statusOk : Theme.textSecondary
                                    }

                                    Text {
                                        text: modelData.ssid
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: isCurrent ? Theme.textPrimary : Theme.textSecondary
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: ((modelData.security !== "Abierta" && modelData.security !== "Open") ? "󰌾 " : "") + ((modelData.security === "Abierta" || modelData.security === "Open") ? (I18n.isEs ? "Abierta" : "Open") : modelData.security) + " • " + modelData.signal + "%"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                    }

                                    // Status & Interaction Indicator
                                    Item {
                                        implicitWidth: 20
                                        implicitHeight: 20

                                        Text {
                                            visible: isCurrent
                                            anchors.centerIn: parent
                                            text: netRowArea.containsMouse ? "󰅖" : "󰄬"
                                            font.family: Theme.fontMono
                                            font.pixelSize: netRowArea.containsMouse ? 12 : 13
                                            font.bold: true
                                            color: netRowArea.containsMouse ? Theme.accent : Theme.statusOk
                                        }

                                        Text {
                                            visible: !isCurrent && netRowArea.containsMouse
                                            anchors.centerIn: parent
                                            text: "󰁕"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 12
                                            color: Theme.accent
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
                                        placeholderText: I18n.netPasswordPrompt + modelData.ssid
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
                                        implicitHeight: 24
                                        implicitWidth: 64
                                        radius: 4
                                        color: Theme.accent
                                        Text {
                                            anchors.centerIn: parent
                                            text: I18n.netConnect
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
                                    if (isCurrent) {
                                        netWindow.runNetCmd(["disconnect", modelData.ssid]);
                                    } else if (modelData.saved || modelData.security === "Abierta" || modelData.security === "Open") {
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

            // =========================================================
            // 4. ADVANCED NETWORK SETTINGS BUTTON (nm-connection-editor)
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 10
                color: advArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: advArea.containsMouse ? "#28ffffff" : Theme.borderSubtle
                border.width: 1
                Behavior on color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰒓"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: advArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                    Text {
                        text: I18n.netAdvancedSettings
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: advArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }
                }

                MouseArea {
                    id: advArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        netWindow.launchApp("nm-connection-editor");
                    }
                }
            }
        }
    }
}

