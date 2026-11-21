import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: powerWindow

    signal closeRequested()
    signal lockRequested()

    property bool closing: false
    property bool hasUefi: true
    property string userHost: "X64 LIOS"
    property string liveUptime: ""
    property int selectedIndex: -1
    property var pendingAction: null

    readonly property var actions: {
        var list = [
            {
                id: "lock",
                icon: "󰌾",
                key: "L",
                label: I18n.powerLock,
                confirmTitle: "",
                confirmDesc: "",
                needsConfirm: false,
                danger: false
            },
            {
                id: "suspend",
                icon: "󰤄",
                key: "S",
                label: I18n.powerSuspend,
                confirmTitle: "",
                confirmDesc: "",
                needsConfirm: false,
                danger: false
            },
            {
                id: "logout",
                icon: "󰍃",
                key: "E",
                label: I18n.powerLogout,
                confirmTitle: I18n.powerConfirmLogoutTitle,
                confirmDesc: I18n.powerConfirmLogoutDesc,
                needsConfirm: true,
                danger: false
            },
            {
                id: "reboot",
                icon: "󰑓",
                key: "R",
                label: I18n.powerReboot,
                confirmTitle: I18n.powerConfirmRebootTitle,
                confirmDesc: I18n.powerConfirmRebootDesc,
                needsConfirm: true,
                danger: false
            }
        ];
        if (powerWindow.hasUefi) {
            list.push({
                id: "uefi",
                icon: "󰍛",
                key: "U",
                label: I18n.powerUefi,
                confirmTitle: I18n.powerConfirmUefiTitle,
                confirmDesc: I18n.powerConfirmUefiDesc,
                needsConfirm: true,
                danger: false
            });
        }
        list.push({
            id: "poweroff",
            icon: "󰐥",
            key: "P",
            label: I18n.powerShutdown,
            confirmTitle: I18n.powerConfirmShutdownTitle,
            confirmDesc: I18n.powerConfirmShutdownDesc,
            needsConfirm: true,
            danger: true
        });
        return list;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-power"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Environment & live uptime probe (user@hostname + UEFI firmware detection + /proc/uptime)
    Process {
        id: envProbeProc
        running: true
        command: ["sh", "-c", "u=$(cut -d. -f1 /proc/uptime 2>/dev/null || echo 0); d=$((u/86400)); h=$(((u%86400)/3600)); m=$(((u%3600)/60)); if [ \"$d\" -gt 0 ]; then up=\"${d}d ${h}h ${m}m\"; elif [ \"$h\" -gt 0 ]; then up=\"${h}h ${m}m\"; else up=\"${m}m\"; fi; printf '%s@%s|%s|%s' \"${USER:-user}\" \"$(hostname 2>/dev/null || echo x64)\" \"$([ -d /sys/firmware/efi ] && echo 1 || echo 0)\" \"$up\""]
        stdout: StdioCollector {
            id: envProbeCol
            onStreamFinished: {
                var raw = (envProbeCol.text || "").trim();
                var parts = raw.split("|");
                if (parts[0]) powerWindow.userHost = parts[0];
                if (parts.length > 1) powerWindow.hasUefi = (parts[1] === "1");
                if (parts.length > 2 && parts[2]) powerWindow.liveUptime = parts[2];
            }
        }
    }

    Process {
        id: execProc
    }

    function executeAction(actionId) {
        if (actionId === "lock") {
            powerWindow.pendingAction = null;
            powerWindow.closing = false;
            powerWindow.visible = false;
            powerWindow.lockRequested();
            return;
        }
        var cmd = "";
        if (actionId === "suspend") {
            cmd = "systemctl suspend";
        } else if (actionId === "logout") {
            cmd = "if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then uwsm stop; else hyprctl dispatch exit; fi";
        } else if (actionId === "reboot") {
            cmd = "systemctl reboot";
        } else if (actionId === "uefi") {
            cmd = "systemctl reboot --firmware-setup";
        } else if (actionId === "poweroff") {
            cmd = "systemctl poweroff";
        }
        if (cmd !== "") {
            powerWindow.pendingAction = null;
            powerWindow.closing = false;
            powerWindow.visible = false;
            execProc.command = ["sh", "-c", cmd];
            execProc.running = true;
        }
    }

    function triggerAction(act) {
        if (!act) return;
        if (act.needsConfirm) {
            powerWindow.pendingAction = act;
        } else {
            powerWindow.executeAction(act.id);
        }
    }

    function triggerByKey(keyChar) {
        var list = powerWindow.actions;
        for (var i = 0; i < list.length; i++) {
            if (list[i].key === keyChar) {
                powerWindow.selectedIndex = i;
                powerWindow.triggerAction(list[i]);
                return true;
            }
        }
        return false;
    }

    function closeAnimated() {
        if (closing || !visible) return;
        closing = true;
        closeAnim.start();
    }

    onVisibleChanged: {
        if (visible) {
            closing = false;
            pendingAction = null;
            selectedIndex = -1;
            if (!envProbeProc.running) envProbeProc.running = true;
            closeAnim.stop();
            scrim.opacity = 0;
            dialogCard.opacity = 0;
            dialogCard.scale = 0.94;
            openAnim.start();
            keyScope.forceActiveFocus();
        } else {
            closing = false;
            pendingAction = null;
            selectedIndex = -1;
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: scrim; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { target: dialogCard; property: "opacity"; to: 1.0; duration: 210; easing.type: Easing.OutCubic }
        NumberAnimation { target: dialogCard; property: "scale"; to: 1.0; duration: 240; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: scrim; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: dialogCard; property: "opacity"; to: 0.0; duration: 140; easing.type: Easing.InCubic }
            NumberAnimation { target: dialogCard; property: "scale"; to: 0.95; duration: 150; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                powerWindow.closing = false;
                powerWindow.closeRequested();
            }
        }
    }

    // Full-screen dimmed veil (paired with Hyprland Kawase blur on quickshell-power)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#b805060a"
        opacity: 0

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (powerWindow.pendingAction) {
                    powerWindow.pendingAction = null;
                } else {
                    powerWindow.closeAnimated();
                }
            }
        }
    }

    // Keyboard navigation & instant hotkeys
    Item {
        id: keyScope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: {
            if (powerWindow.pendingAction) {
                powerWindow.pendingAction = null;
            } else {
                powerWindow.closeAnimated();
            }
        }

        Keys.onLeftPressed: {
            if (powerWindow.pendingAction) return;
            var n = powerWindow.actions.length;
            powerWindow.selectedIndex = powerWindow.selectedIndex <= 0 ? (n - 1) : (powerWindow.selectedIndex - 1);
        }

        Keys.onRightPressed: {
            if (powerWindow.pendingAction) return;
            var n = powerWindow.actions.length;
            powerWindow.selectedIndex = (powerWindow.selectedIndex + 1) % n;
        }

        Keys.onReturnPressed: {
            if (powerWindow.pendingAction) {
                powerWindow.executeAction(powerWindow.pendingAction.id);
            } else if (powerWindow.selectedIndex >= 0 && powerWindow.selectedIndex < powerWindow.actions.length) {
                powerWindow.triggerAction(powerWindow.actions[powerWindow.selectedIndex]);
            }
        }

        Keys.onEnterPressed: {
            if (powerWindow.pendingAction) {
                powerWindow.executeAction(powerWindow.pendingAction.id);
            } else if (powerWindow.selectedIndex >= 0 && powerWindow.selectedIndex < powerWindow.actions.length) {
                powerWindow.triggerAction(powerWindow.actions[powerWindow.selectedIndex]);
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Space) {
                if (powerWindow.pendingAction) {
                    powerWindow.executeAction(powerWindow.pendingAction.id);
                } else if (powerWindow.selectedIndex >= 0 && powerWindow.selectedIndex < powerWindow.actions.length) {
                    powerWindow.triggerAction(powerWindow.actions[powerWindow.selectedIndex]);
                }
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Tab && !powerWindow.pendingAction) {
                var n = powerWindow.actions.length;
                powerWindow.selectedIndex = (powerWindow.selectedIndex + 1) % n;
                event.accepted = true;
                return;
            }
            if (!powerWindow.pendingAction && event.text) {
                var ch = event.text.toUpperCase();
                if (ch.length === 1 && powerWindow.triggerByKey(ch)) {
                    event.accepted = true;
                }
            }
        }
    }

    // Centered Obsidian Glass Dialog Card
    Rectangle {
        id: dialogCard
        anchors.centerIn: parent
        width: mainCol.implicitWidth + 44
        height: mainCol.implicitHeight + 40
        radius: 20
        color: Theme.bgGlass
        border.color: powerWindow.pendingAction && powerWindow.pendingAction.danger
            ? Theme.statusCrit
            : Theme.borderGlass
        border.width: 1
        opacity: 0
        scale: 0.94
        transformOrigin: Item.Center
        Behavior on border.color { ColorAnimation { duration: 180 } }

        // Prevent clicks inside card from dismissing scrim
        MouseArea {
            anchors.fill: parent
        }

        // Delicate top shimmer accent line
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 1
            width: parent.width * 0.42
            height: 1
            radius: 0.5
            color: powerWindow.pendingAction && powerWindow.pendingAction.danger
                ? Theme.statusCrit
                : Theme.accent
            opacity: 0.45
            Behavior on color { ColorAnimation { duration: 180 } }
        }

        ColumnLayout {
            id: mainCol
            anchors.centerIn: parent
            spacing: 18

            // =================================================================
            // HEADER ROW (Session Identity + Live Clock + Esc Close)
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: powerWindow.pendingAction && powerWindow.pendingAction.danger
                            ? Theme.statusCrit
                            : Theme.accent
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }

                    ColumnLayout {
                        spacing: 1
                        Text {
                            text: I18n.powerTitle
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.4
                            color: Theme.textPrimary
                        }
                        Text {
                            text: powerWindow.userHost + (powerWindow.liveUptime !== "" ? ("  •  " + powerWindow.liveUptime) : "")
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: SysState.timeStr
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.textSecondary
                }

                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: 13
                    color: closeBtnArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: closeBtnArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: closeBtnArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                    }

                    MouseArea {
                        id: closeBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: powerWindow.closeAnimated()
                    }
                }
            }

            // =================================================================
            // CONTENT STAGE (Action Cards Grid <-> Integrated Confirmation View)
            // Fixed clean footprint so switching to confirmation never jumps!
            // =================================================================
            Item {
                id: stageBox
                implicitWidth: actionsRow.implicitWidth
                implicitHeight: 144

                // --- VIEW A: 6 LARGE ACTION CARDS ---
                RowLayout {
                    id: actionsRow
                    anchors.centerIn: parent
                    spacing: 12
                    visible: powerWindow.pendingAction === null
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    Repeater {
                        model: powerWindow.actions

                        Rectangle {
                            id: actCard
                            required property var modelData
                            required property int index

                            readonly property bool isLit: cardArea.containsMouse || powerWindow.selectedIndex === index
                            readonly property color litColor: modelData.danger ? Theme.statusCrit : Theme.accent
                            readonly property color litFg: modelData.danger ? "#ffffff" : Theme.accentFg

                            implicitWidth: 124
                            implicitHeight: 136
                            radius: 14
                            color: isLit ? Theme.bgHover : Theme.bgCard
                            border.color: isLit ? (modelData.danger ? Theme.statusCrit : Theme.borderAccent) : Theme.borderSubtle
                            border.width: 1
                            scale: cardArea.pressed ? 0.95 : (isLit ? 1.03 : 1.0)
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            // Corner Hotkey Cap (L, S, E, R, U, P)
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: 8
                                anchors.rightMargin: 8
                                width: 19
                                height: 19
                                radius: 6
                                color: actCard.isLit ? Qt.rgba(actCard.litColor.r, actCard.litColor.g, actCard.litColor.b, 0.20) : Theme.bgElevated
                                border.color: actCard.isLit ? actCard.litColor : Theme.borderSubtle
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 140 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: actCard.modelData.key
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: actCard.isLit ? actCard.litColor : Theme.textMuted
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 4
                                spacing: 12

                                // Circular Icon Halo
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 52
                                    height: 52
                                    radius: 26
                                    color: actCard.isLit
                                        ? actCard.litColor
                                        : (actCard.modelData.danger ? Qt.rgba(Theme.statusCrit.r, Theme.statusCrit.g, Theme.statusCrit.b, 0.14) : Theme.bgElevated)
                                    border.color: actCard.isLit
                                        ? actCard.litColor
                                        : (actCard.modelData.danger ? Qt.rgba(Theme.statusCrit.r, Theme.statusCrit.g, Theme.statusCrit.b, 0.35) : Theme.borderSubtle)
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: actCard.modelData.icon
                                        font.family: Theme.fontMono
                                        font.pixelSize: 22
                                        color: actCard.isLit
                                            ? actCard.litFg
                                            : (actCard.modelData.danger ? Theme.statusCrit : Theme.textPrimary)
                                        Behavior on color { ColorAnimation { duration: 140 } }
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: actCard.modelData.label
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: actCard.isLit ? Theme.textPrimary : Theme.textSecondary
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                            }

                            MouseArea {
                                id: cardArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: powerWindow.selectedIndex = actCard.index
                                onClicked: powerWindow.triggerAction(actCard.modelData)
                            }
                        }
                    }
                }

                // --- VIEW B: INTEGRATED SAFETY CONFIRMATION PANEL ---
                RowLayout {
                    id: confirmView
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 20
                    visible: powerWindow.pendingAction !== null
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 160 } }

                    readonly property color confColor: (powerWindow.pendingAction && powerWindow.pendingAction.danger)
                        ? Theme.statusCrit
                        : Theme.accent
                    readonly property color confFg: (powerWindow.pendingAction && powerWindow.pendingAction.danger)
                        ? "#ffffff"
                        : Theme.accentFg

                    // Big Action Emblem
                    Rectangle {
                        width: 64
                        height: 64
                        radius: 32
                        color: Qt.rgba(confirmView.confColor.r, confirmView.confColor.g, confirmView.confColor.b, 0.16)
                        border.color: confirmView.confColor
                        border.width: 1.5

                        Text {
                            anchors.centerIn: parent
                            text: powerWindow.pendingAction ? powerWindow.pendingAction.icon : "󰐥"
                            font.family: Theme.fontMono
                            font.pixelSize: 28
                            color: confirmView.confColor
                        }
                    }

                    // Question & Subtitle
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Text {
                            text: powerWindow.pendingAction ? powerWindow.pendingAction.confirmTitle : ""
                            font.family: Theme.fontSans
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: powerWindow.pendingAction ? powerWindow.pendingAction.confirmDesc : ""
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textSecondary
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Cancel & Confirm Buttons
                    RowLayout {
                        spacing: 10

                        Rectangle {
                            implicitWidth: cancelRow.implicitWidth + 28
                            implicitHeight: 40
                            radius: 12
                            color: cancelArea.containsMouse ? Theme.bgHover : Theme.bgCard
                            border.color: cancelArea.containsMouse ? Theme.borderGlass : Theme.borderSubtle
                            border.width: 1
                            scale: cancelArea.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120 } }

                            RowLayout {
                                id: cancelRow
                                anchors.centerIn: parent
                                spacing: 7
                                Text {
                                    text: I18n.powerCancel
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Theme.textPrimary
                                }
                                Text {
                                    text: "ESC"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }
                            }

                            MouseArea {
                                id: cancelArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: powerWindow.pendingAction = null
                            }
                        }

                        Rectangle {
                            implicitWidth: okRow.implicitWidth + 28
                            implicitHeight: 40
                            radius: 12
                            color: okArea.containsMouse
                                ? Qt.lighter(confirmView.confColor, 1.12)
                                : confirmView.confColor
                            border.color: confirmView.confColor
                            border.width: 1
                            scale: okArea.pressed ? 0.95 : 1.0
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on scale { NumberAnimation { duration: 120 } }

                            RowLayout {
                                id: okRow
                                anchors.centerIn: parent
                                spacing: 7
                                Text {
                                    text: powerWindow.pendingAction ? powerWindow.pendingAction.icon : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    color: confirmView.confFg
                                }
                                Text {
                                    text: I18n.powerConfirmBtn
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: confirmView.confFg
                                }
                                Text {
                                    text: "↵"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: confirmView.confFg
                                    opacity: 0.8
                                }
                            }

                            MouseArea {
                                id: okArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (powerWindow.pendingAction) {
                                        powerWindow.executeAction(powerWindow.pendingAction.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // FOOTER KEYBOARD HINT BAR
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: powerWindow.pendingAction
                        ? I18n.powerHintConfirm
                        : I18n.powerHintMain
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "SUPER + M"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }
}
