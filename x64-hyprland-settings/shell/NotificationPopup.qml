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
        if (notifWindow.dndEnabled && cleanApp !== "No Molestar") {
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
                if (toastModel.get(i).appName !== "No Molestar") {
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
                readonly property bool isDndToast: model.appName === "No Molestar"
                readonly property color toastAccent: isDndToast ? "#c084fc" : Theme.accent

                Layout.fillWidth: true
                implicitHeight: cardInner.implicitHeight + 22
                radius: Theme.radiusMd
                color: Theme.bgGlass
                border.color: isDndToast ? "#88a855f7" : Theme.borderAccent
                border.width: 1

                // Top Neon Accent Glow Line
                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        leftMargin: 18
                        rightMargin: 18
                    }
                    height: 2
                    radius: 1
                    color: parent.toastAccent
                }

                ColumnLayout {
                    id: cardInner
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: isDndToast ? "󰂛" : "󰂚"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: toastAccent
                        }

                        Text {
                            text: model.appName.toUpperCase()
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: toastAccent
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "󰅖"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textMuted
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

                    // Auto-expire countdown bar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 3
                        height: 2
                        radius: 1
                        color: "#1affffff"

                        Rectangle {
                            width: parent.width * Math.max(0.0, model.ticks / 45.0)
                            height: parent.height
                            radius: 1
                            color: toastAccent
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toastModel.remove(index)
                }
            }
        }
    }
}
