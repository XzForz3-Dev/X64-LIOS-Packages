import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: notifWindow

    property bool dndEnabled: false
    property bool sidePanelOpen: false

    // Active toast queue (up to 3 recent notifications)
    ListModel {
        id: toastModel
    }

    function pushNotification(app, sum, bod) {
        var cleanApp = app || "X64 LIOS";
        var cleanSum = sum || "Notificación";
        var cleanBod = bod || "";

        // Block all notifications while DND is active EXCEPT the DND toggle confirmation itself
        if (notifWindow.dndEnabled && cleanApp !== "No Molestar" && cleanApp !== "Do Not Disturb") {
            return;
        }

        // If a toast from the same category/title is already visible, replace it in place
        for (var i = 0; i < toastModel.count; i++) {
            var item = toastModel.get(i);
            if (item.summary === cleanSum || (cleanApp !== "X64 LIOS" && item.appName === cleanApp)) {
                toastModel.remove(i);
                break;
            }
        }

        while (toastModel.count >= 3) {
            toastModel.remove(toastModel.count - 1);
        }

        toastModel.insert(0, {
            "appName": cleanApp,
            "summary": cleanSum,
            "body": cleanBod,
            "ticks": 45
        });
    }

    visible: toastModel.count > 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 38
        right: notifWindow.sidePanelOpen ? 380 : 12
    }

    implicitWidth: 340
    implicitHeight: toastCol.implicitHeight + 8

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    onDndEnabledChanged: {
        if (dndEnabled) {
            for (var i = toastModel.count - 1; i >= 0; i--) {
                var a = toastModel.get(i).appName;
                if (a !== "No Molestar" && a !== "Do Not Disturb") {
                    toastModel.remove(i);
                }
            }
        }
    }

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: false

        onNotification: (notif) => {
            notifWindow.pushNotification(
                notif.appName || "X64 LIOS",
                notif.summary || "Notificación",
                notif.body || ""
            );
        }
    }

    // Global 100ms countdown timer for smooth progress bar & auto-dismiss (4.5s)
    Timer {
        interval: 100
        running: toastModel.count > 0
        repeat: true
        onTriggered: {
            for (var i = toastModel.count - 1; i >= 0; i--) {
                var t = toastModel.get(i).ticks - 1;
                if (t <= 0) {
                    toastModel.remove(i);
                } else {
                    toastModel.setProperty(i, "ticks", t);
                }
            }
        }
    }

    ColumnLayout {
        id: toastCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        Repeater {
            model: toastModel
            delegate: Rectangle {
                id: toastCard
                readonly property string lowerSum: (model.summary || "").toLowerCase()
                readonly property string lowerApp: (model.appName || "").toLowerCase()
                readonly property string toastIcon: {
                    if (lowerApp.indexOf("molestar") !== -1 || lowerApp.indexOf("disturb") !== -1 || lowerSum.indexOf("molestar") !== -1) return "󰂛";
                    if (lowerSum.indexOf("noche") !== -1 || lowerSum.indexOf("nocturna") !== -1 || lowerSum.indexOf("night") !== -1) return "󰖔";
                    if (lowerSum.indexOf("café") !== -1 || lowerSum.indexOf("cafe") !== -1 || lowerSum.indexOf("caffeine") !== -1) return "󰅶";
                    if (lowerSum.indexOf("captura") !== -1 || lowerSum.indexOf("screen") !== -1 || lowerSum.indexOf("grab") !== -1) return "󰄀";
                    if (lowerSum.indexOf("energía") !== -1 || lowerSum.indexOf("power") !== -1 || lowerSum.indexOf("perfil") !== -1) return "󰾅";
                    if (lowerSum.indexOf("red") !== -1 || lowerSum.indexOf("wi-fi") !== -1 || lowerSum.indexOf("ethernet") !== -1) return "󰈀";
                    return "󰂚";
                }

                Layout.fillWidth: true
                implicitHeight: cardInner.implicitHeight + 24
                radius: Theme.radiusLg
                color: toastArea.containsMouse ? Theme.bgCard : Theme.bgGlass
                border.color: toastArea.containsMouse ? "#28ffffff" : Theme.borderGlass
                border.width: 1
                clip: true

                // Smooth entry animation
                opacity: 0.0
                scale: 0.95
                transform: Translate { id: slideTrans; x: 24 }
                transformOrigin: Item.TopRight

                Component.onCompleted: {
                    enterAnim.start();
                }

                ParallelAnimation {
                    id: enterAnim
                    NumberAnimation { target: toastCard; property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastCard; property: "scale"; from: 0.95; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                    NumberAnimation { target: slideTrans; property: "x"; from: 24; to: 0; duration: 220; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    id: cardInner
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 11

                    // Left Monochromatic Icon Badge with Subtle Crimson Dot
                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 10
                        color: Theme.bgElevated
                        border.color: Theme.borderSubtle
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: toastCard.toastIcon
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            color: Theme.textPrimary
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 5
                            anchors.rightMargin: 5
                            width: 5
                            height: 5
                            radius: 2.5
                            color: Theme.accent
                        }
                    }

                    // Right Text Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: model.appName.toUpperCase()
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.textMuted
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: "󰅖"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: toastArea.containsMouse ? Theme.textSecondary : Theme.textMuted
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.summary
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            visible: model.body !== ""
                            Layout.fillWidth: true
                            text: model.body
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            color: Theme.textSecondary
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // Subtle Bottom Countdown Line
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.bottomMargin: 1
                    height: 2
                    radius: 1
                    color: "#0fffffff"

                    Rectangle {
                        width: parent.width * Math.max(0.0, model.ticks / 45.0)
                        height: parent.height
                        radius: 1
                        color: "#55ffffff"
                        Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.Linear } }
                    }
                }

                MouseArea {
                    id: toastArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toastModel.remove(index)
                }
            }
        }
    }
}
