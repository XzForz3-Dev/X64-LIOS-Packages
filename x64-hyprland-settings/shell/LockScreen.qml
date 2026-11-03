import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "."

Scope {
    id: root
    property bool isLocked: false
    property string statusText: I18n.lockStatusReady
    property bool isError: false
    property bool isVerifying: false

    function lockSession() {
        if (root.isLocked) return;
        root.isError = false;
        root.isVerifying = false;
        root.statusText = I18n.lockStatusReady;
        root.isLocked = true;
    }

    function unlockSession() {
        if (pam.active) pam.abort();
        root.isVerifying = false;
        root.isError = false;
        root.isLocked = false;
    }

    PamContext {
        id: pam
        config: "system-auth"

        onResponseRequiredChanged: {
            if (pam.responseRequired && root.pendingPassword !== "") {
                var pass = root.pendingPassword;
                root.pendingPassword = "";
                pam.respond(pass);
            }
        }

        onCompleted: (result) => {
            root.isVerifying = false;
            if (result === PamResult.Success) {
                root.isError = false;
                root.statusText = I18n.isEs ? "Acceso concedido" : "Access granted";
                root.isLocked = false;
            } else {
                root.isError = true;
                root.statusText = I18n.lockStatusError;
            }
        }

        onError: (err) => {
            root.isVerifying = false;
            root.isError = true;
            root.statusText = I18n.isEs ? "󰀦 Error de autenticación PAM" : "󰀦 PAM Authentication Error";
        }
    }

    property string pendingPassword: ""

    function submitPassword(pass) {
        if (!pass || pass.length === 0 || root.isVerifying) return;
        root.isError = false;
        root.isVerifying = true;
        root.statusText = I18n.lockStatusVerifying;
        root.pendingPassword = pass;
        if (pam.active) {
            if (pam.responseRequired) {
                root.pendingPassword = "";
                pam.respond(pass);
            } else {
                pam.abort();
                pam.start();
            }
        } else {
            pam.start();
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.isLocked

        WlSessionLockSurface {
            id: lockSurface
            color: "#08090e"

            property string clockTime: "12:00"
            property string clockDate: "MARTES, 03 DE NOVIEMBRE"

            function updateClock() {
                var now = new Date();
                lockSurface.clockTime = Qt.formatDateTime(now, "HH:mm");
                var dName = I18n.dayFullNames[now.getDay()].toUpperCase();
                var dNum = ("0" + now.getDate()).slice(-2);
                var mName = I18n.monthFullNames[now.getMonth()].toUpperCase();
                if (I18n.isEs) {
                    lockSurface.clockDate = dName + ", " + dNum + " DE " + mName;
                } else {
                    lockSurface.clockDate = dName + ", " + mName + " " + dNum;
                }
            }

            Component.onCompleted: {
                lockSurface.updateClock();
                passInput.forceActiveFocus();
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: lockSurface.updateClock()
            }

            // Fondo Monolith 4K Oficial
            Image {
                anchors.fill: parent
                source: "file:///usr/share/backgrounds/x64-lios/01-monolith.jpg"
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
            }

            // Velo Obsidian Glass Oscuro
            Rectangle {
                anchors.fill: parent
                color: "#c807080d"
            }

            // Píldora Superior de Seguridad Wayland
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 28
                anchors.horizontalCenter: parent.horizontalCenter
                height: 30
                width: secRow.implicitWidth + 28
                radius: 15
                color: "#e611131c"
                border.color: "#44ff2b2b"
                border.width: 1

                RowLayout {
                    id: secRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "󰌾"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.accent
                    }

                    Text {
                        text: "X64 LIOS SECURITY LOCK • EXT-SESSION-LOCK-V1"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.textSecondary
                    }
                }
            }

            // Bloque Central: Reloj + Tarjeta de Autenticación PAM
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 26

                // Reloj Digital Gigante
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: lockSurface.clockTime
                        font.family: Theme.fontMono
                        font.pixelSize: 78
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: lockSurface.clockDate
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.accent
                    }
                }

                // Tarjeta Obsidian Glass de Desbloqueo
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 390
                    height: 228
                    radius: 14
                    color: Theme.bgGlass
                    border.color: root.isError ? Theme.accent : "#30ffffff"
                    border.width: 1

                    // Línea superior de acento neón carmesí
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 48
                        height: 2
                        radius: 1
                        color: Theme.accent
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 14

                        // Cabecera de Usuario
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 21
                                color: "#26ff2b2b"
                                border.color: Theme.accent
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰣇"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 20
                                    color: Theme.accent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: I18n.lockSessionLocked
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: Theme.accent
                                }

                                Text {
                                    text: Quickshell.env("USER") || "qqqq"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: Theme.textPrimary
                                }
                            }

                            Rectangle {
                                height: 24
                                width: 68
                                radius: 6
                                color: "#1affffff"
                                border.color: "#28ffffff"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰍁 PAM"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: Theme.textSecondary
                                }
                            }
                        }

                        // Campo de Contraseña + Botón Enter
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 42
                                radius: 8
                                color: "#141622"
                                border.color: passInput.activeFocus ? Theme.accent : "#32ffffff"
                                border.width: 1

                                TextInput {
                                    id: passInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.fontMono
                                    font.pixelSize: 14
                                    color: Theme.textPrimary
                                    echoMode: TextInput.Password
                                    passwordCharacter: "●"
                                    focus: true
                                    clip: true

                                    Keys.onReturnPressed: {
                                        var p = passInput.text;
                                        passInput.text = "";
                                        root.submitPassword(p);
                                    }
                                    Keys.onEnterPressed: {
                                        var p = passInput.text;
                                        passInput.text = "";
                                        root.submitPassword(p);
                                    }

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: I18n.lockPasswordPrompt
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: Theme.textMuted
                                        visible: passInput.text.length === 0
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: passInput.forceActiveFocus()
                                }
                            }

                            Rectangle {
                                width: 46
                                height: 42
                                radius: 8
                                color: unlockArea.containsMouse ? "#ff4242" : Theme.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: root.isVerifying ? "󰑐" : "󰌿"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 16
                                    color: "#ffffff"
                                }

                                MouseArea {
                                    id: unlockArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var p = passInput.text;
                                        passInput.text = "";
                                        root.submitPassword(p);
                                    }
                                }
                            }
                        }

                        // Mensaje de Estado / Error
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: root.statusText
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.weight: root.isError ? Font.DemiBold : Font.Normal
                            color: root.isError ? Theme.accent : (root.isVerifying ? "#f59e0b" : Theme.textMuted)
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
