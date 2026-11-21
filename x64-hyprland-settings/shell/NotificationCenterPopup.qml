import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: ncWindow

    signal closeRequested()
    property bool lockClose: false

    anchors {
        top: true
        right: true
    }

    margins {
        top: 44
        right: 12
    }

    readonly property int maxListHeight: 460
    readonly property int computedListHeight: NotifState.history.length === 0
        ? 150
        : Math.min(maxListHeight, Math.max(96, notifList.contentHeight + 4))

    implicitWidth: 372
    implicitHeight: Math.min(620, headerRow.implicitHeight + computedListHeight + 52)

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: focusGrab
        active: ncWindow.visible && !ncWindow.lockClose
        windows: [ncWindow]
        onCleared: {
            if (!ncWindow.lockClose && ncWindow.visible) {
                ncWindow.closeAnimated();
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
            from: 0.86
            to: 1.0
            duration: 240
            easing.type: Easing.OutBack
            easing.overshoot: 1.3
        }
        NumberAnimation {
            target: card
            property: "y"
            from: -20
            to: 0
            duration: 240
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: card
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim
        running: false
        NumberAnimation {
            target: card
            property: "scale"
            to: 0.88
            duration: 140
            easing.type: Easing.InBack
            easing.overshoot: 1.1
        }
        NumberAnimation {
            target: card
            property: "y"
            to: -16
            duration: 140
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0.0
            duration: 120
            easing.type: Easing.InQuad
        }
        onFinished: ncWindow.closeRequested()
    }

    onVisibleChanged: {
        NotifState.drawerOpen = visible;
        if (visible) {
            NotifState.markAllRead();
            card.scale = 0.86;
            card.y = -20;
            card.opacity = 0.0;
            openAnim.restart();
        } else {
            card.scale = 1.0;
            card.y = 0;
            card.opacity = 1.0;
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        transformOrigin: Item.TopRight
        layer.enabled: openAnim.running || closeAnim.running
        layer.smooth: true
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1
        clip: true

        Keys.onEscapePressed: ncWindow.closeAnimated()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // =========================================================
            // HEADER: TITLE, COUNT, DND TOGGLE & CLEAR ALL
            // =========================================================
            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: SysState.dndActive ? Theme.statusWarn : Theme.accent
                }

                Text {
                    text: I18n.notifCenterTitle
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 1.0
                    color: Theme.textSecondary
                }

                Rectangle {
                    visible: NotifState.history.length > 0
                    implicitHeight: 18
                    implicitWidth: countTxt.implicitWidth + 10
                    radius: 9
                    color: Theme.bgElevated
                    border.color: Theme.borderSubtle
                    border.width: 1
                    Text {
                        id: countTxt
                        anchors.centerIn: parent
                        text: NotifState.history.length + "/" + NotifState.maxItems
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.textSecondary
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick DND Toggle Pill
                Rectangle {
                    implicitHeight: 24
                    implicitWidth: dndPillRow.implicitWidth + 14
                    radius: 12
                    color: SysState.dndActive ? Theme.accent : (dndPillArea.containsMouse ? Theme.bgHover : Theme.bgCard)
                    border.color: SysState.dndActive ? Theme.accentHover : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: dndPillRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: SysState.dndActive ? "󰂛" : "󰂚"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: SysState.dndActive ? Theme.accentFg : Theme.textSecondary
                        }
                        Text {
                            text: "DND"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: SysState.dndActive ? Theme.accentFg : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: dndPillArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var next = !SysState.dndActive;
                            SysState.guardToggle();
                            SysState.dndActive = next;
                            SysState.runCtl(["dnd", next ? "on" : "off"]);
                        }
                    }
                }

                // Clear All Button
                Rectangle {
                    visible: NotifState.history.length > 0
                    implicitHeight: 24
                    implicitWidth: clearRow.implicitWidth + 14
                    radius: 12
                    color: clearArea.containsMouse ? Theme.accentDim : Theme.bgCard
                    border.color: clearArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "󰎟"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: clearArea.containsMouse ? Theme.accent : Theme.textSecondary
                        }
                        Text {
                            text: I18n.notifClearAll
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: clearArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotifState.clearAll()
                    }
                }
            }

            // Subtle divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            // =========================================================
            // EMPTY STATE
            // =========================================================
            Item {
                visible: NotifState.history.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 148

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    width: parent.width - 24

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 44
                        height: 44
                        radius: 22
                        color: Theme.bgCard
                        border.color: Theme.borderSubtle
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: SysState.dndActive ? "󰂛" : "󰂚"
                            font.family: Theme.fontMono
                            font.pixelSize: 19
                            color: SysState.dndActive ? Theme.accent : Theme.textMuted
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: I18n.notifEmptyTitle
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: SysState.dndActive ? I18n.notifEmptyDndSub : I18n.notifEmptySub
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }
                }
            }

            // =========================================================
            // HISTORY LIST (UP TO 25 ITEMS)
            // =========================================================
            ListView {
                id: notifList
                visible: NotifState.history.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 7
                boundsBehavior: Flickable.StopAtBounds
                model: NotifState.history

                ScrollBar.vertical: ScrollBar {
                    id: ncScrollBar
                    policy: notifList.contentHeight > notifList.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    implicitWidth: 4
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: ncScrollBar.pressed ? Theme.accent : (ncScrollBar.hovered ? Theme.textPrimary : Theme.textMuted)
                    }
                    background: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.borderSubtle
                    }
                }

                delegate: Rectangle {
                    id: itemCard
                    required property var modelData
                    width: notifList.width - (ncScrollBar.visible ? 8 : 0)
                    implicitHeight: itemInner.implicitHeight + 18
                    radius: Theme.radiusMd
                    color: itemHover.containsMouse ? Theme.bgElevated : Theme.bgCard
                    border.color: itemHover.containsMouse ? Theme.borderGlass : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    RowLayout {
                        id: itemInner
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 9
                        spacing: 10

                        // Left Category Badge
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 30
                            implicitHeight: 30
                            radius: 9
                            color: Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: itemCard.modelData.icon || "󰂚"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: Theme.accent
                            }
                        }

                        // Text Content
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: (itemCard.modelData.appName || "X64 LIOS").toUpperCase()
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0.7
                                    color: Theme.textMuted
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: (itemCard.modelData.timeStr || "") !== ""
                                    text: itemCard.modelData.timeStr || ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }

                                Rectangle {
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: 5
                                    color: rmArea.containsMouse ? Theme.accentDim : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        color: rmArea.containsMouse ? Theme.accent : Theme.textMuted
                                    }

                                    MouseArea {
                                        id: rmArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotifState.removeById(itemCard.modelData.id)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: itemCard.modelData.summary || ""
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.textPrimary
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: (itemCard.modelData.body || "") !== ""
                                Layout.fillWidth: true
                                text: itemCard.modelData.body || ""
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
