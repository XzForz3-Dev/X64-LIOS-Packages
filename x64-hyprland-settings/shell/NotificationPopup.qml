import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications

PanelWindow {
    id: notifWindow

    property bool dndEnabled: false
    property bool sidePanelOpen: false
    property int customRightMargin: 0

    // Active toast queue (up to 3 recent notifications)
    ListModel {
        id: toastModel
    }

    Process {
        id: actionProc
    }

    function openScreenshotFile(path) {
        if (!path) return;
        if (actionProc.running) actionProc.running = false;
        actionProc.command = ["sh", "-c", "setsid -f loupe \"$1\" >/dev/null 2>&1 < /dev/null", "_", path];
        actionProc.running = true;
    }

    function openScreenshotFolder(path) {
        if (!path) return;
        if (actionProc.running) actionProc.running = false;
        actionProc.command = ["sh", "-c", "setsid -f dolphin --select \"$1\" >/dev/null 2>&1 < /dev/null", "_", path];
        actionProc.running = true;
    }

    function pushScreenshot(filePath, title, subtitle) {
        var cleanApp = I18n.isEs ? "Captura X64" : "X64 Capture";
        var cleanSum = title || (I18n.isEs ? "Captura Guardada" : "Screenshot Saved");
        var cleanBod = subtitle || "";

        // Archive in persistent Notification Center history too
        NotifState.recordNotification(cleanApp, cleanSum, cleanBod);

        // Replace any previous screenshot toast in place
        for (var i = toastModel.count - 1; i >= 0; i--) {
            if (toastModel.get(i).imagePath !== "") {
                toastModel.remove(i);
            }
        }
        while (toastModel.count >= 3) {
            toastModel.remove(toastModel.count - 1);
        }

        toastModel.insert(0, {
            "appName": cleanApp,
            "summary": cleanSum,
            "body": cleanBod,
            "ticks": 75,
            "maxTicks": 75,
            "imagePath": filePath || "",
            "paused": false
        });
    }

    function pushNotification(app, sum, bod) {
        var cleanApp = app || "X64 LIOS";
        var cleanSum = sum || "Notificación";
        var cleanBod = bod || "";

        // Always archive incoming notifications in persistent history (even while DND is active)
        NotifState.recordNotification(cleanApp, cleanSum, cleanBod);

        // Skip floating toast while the Notification Center drawer is already open
        if (NotifState.drawerOpen) {
            return;
        }

        // Block floating toasts while DND is active EXCEPT DND & Gaming Mode state confirmations
        if (notifWindow.dndEnabled
            && cleanApp !== "No Molestar" && cleanApp !== "Do Not Disturb"
            && cleanApp !== "Gaming X64" && cleanApp !== "X64 Gaming") {
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
            "ticks": 45,
            "maxTicks": 45,
            "imagePath": "",
            "paused": false
        });
    }

    visible: toastModel.count > 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 46
        right: notifWindow.customRightMargin > 0 ? notifWindow.customRightMargin : (notifWindow.sidePanelOpen ? 392 : 12)
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

    // Global 100ms countdown timer for smooth progress bar & auto-dismiss (pauses on hover)
    Timer {
        interval: 100
        running: toastModel.count > 0
        repeat: true
        onTriggered: {
            for (var i = toastModel.count - 1; i >= 0; i--) {
                var row = toastModel.get(i);
                if (row.paused) continue;
                var t = row.ticks - 1;
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
                readonly property string toastIcon: NotifState.iconFor(model.appName, model.summary)
                readonly property bool hasShot: (model.imagePath || "") !== ""
                readonly property bool isCardHovered: toastArea.containsMouse || thumbArea.containsMouse || openBtnArea.containsMouse || folderBtnArea.containsMouse

                onIsCardHoveredChanged: {
                    if (index >= 0 && index < toastModel.count) {
                        toastModel.setProperty(index, "paused", isCardHovered);
                    }
                }

                Layout.fillWidth: true
                implicitHeight: cardInner.implicitHeight + 24
                radius: Theme.radiusLg
                color: isCardHovered ? Theme.bgCard : Theme.bgGlass
                border.color: isCardHovered ? Theme.borderAccent : Theme.borderGlass
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

                // Background dismiss catcher (sits underneath interactive preview & buttons)
                MouseArea {
                    id: toastArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toastModel.remove(index)
                }

                ColumnLayout {
                    id: cardInner
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 11

                        // Left Monochromatic Icon Badge with Subtle Accent Dot
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
                                    color: toastCard.isCardHovered ? Theme.textSecondary : Theme.textMuted
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

                    // Live Rounded Screenshot Thumbnail Preview (clickable to open in Loupe)
                    Rectangle {
                        visible: toastCard.hasShot
                        Layout.fillWidth: true
                        implicitHeight: 112
                        radius: 10
                        color: Theme.bgElevated
                        border.color: thumbArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            source: toastCard.hasShot ? ("file://" + model.imagePath) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            smooth: true
                            sourceSize.width: 640
                            sourceSize.height: 360
                        }

                        MouseArea {
                            id: thumbArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var p = model.imagePath;
                                var idx = index;
                                notifWindow.openScreenshotFile(p);
                                toastModel.remove(idx);
                            }
                        }
                    }

                    // 1-Click Quick Actions Row: Abrir (Loupe) & Carpeta (Dolphin --select)
                    RowLayout {
                        visible: toastCard.hasShot
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 8
                            color: openBtnArea.containsMouse ? Theme.accent : Theme.bgElevated
                            border.color: openBtnArea.containsMouse ? Theme.accent : Theme.borderSubtle
                            border.width: 1
                            scale: openBtnArea.pressed ? 0.96 : 1.0
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰋩"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    color: openBtnArea.containsMouse ? Theme.accentFg : Theme.accent
                                }
                                Text {
                                    text: I18n.shotActionOpen
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: openBtnArea.containsMouse ? Theme.accentFg : Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: openBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var p = model.imagePath;
                                    var idx = index;
                                    notifWindow.openScreenshotFile(p);
                                    toastModel.remove(idx);
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 8
                            color: folderBtnArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                            border.color: folderBtnArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                            border.width: 1
                            scale: folderBtnArea.pressed ? 0.96 : 1.0
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on scale { NumberAnimation { duration: 100 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "󰉋"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 12
                                    color: folderBtnArea.containsMouse ? Theme.accent : Theme.textSecondary
                                }
                                Text {
                                    text: I18n.shotActionFolder
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }
                            }

                            MouseArea {
                                id: folderBtnArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var p = model.imagePath;
                                    var idx = index;
                                    notifWindow.openScreenshotFolder(p);
                                    toastModel.remove(idx);
                                }
                            }
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
                        width: parent.width * Math.max(0.0, model.ticks / Math.max(1, model.maxTicks || 45))
                        height: parent.height
                        radius: 1
                        color: toastCard.hasShot ? Theme.accent : "#55ffffff"
                        Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.Linear } }
                    }
                }
            }
        }
    }
}
