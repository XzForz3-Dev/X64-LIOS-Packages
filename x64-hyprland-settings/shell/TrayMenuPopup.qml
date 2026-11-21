import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// =============================================================================
// X64 LIOS - Native Obsidian System Tray DBusMenu Popup (TrayMenuPopup.qml)
// Uses Quickshell QsMenuOpener to render live SNI/DBusMenu entries (Discord,
// Steam, X64 Update, OBS, etc.) in X64 Obsidian Glass with full support for
// nested submenus (stack navigation), checkboxes, radio buttons & icons.
// =============================================================================
PanelWindow {
    id: trayMenuWin

    signal closeRequested()

    property var rootMenuHandle: null
    property string rootTitle: ""
    property string rootIcon: ""
    property real anchorX: 1600
    property bool closing: false

    // Navigation stack for nested submenus: [{ handle, title }]
    property var menuStack: []

    readonly property var currentEntry: menuStack.length > 0 ? menuStack[menuStack.length - 1] : null
    readonly property bool inSubmenu: menuStack.length > 1
    readonly property string headerTitle: currentEntry && currentEntry.title ? currentEntry.title : (rootTitle || "Menu")
    readonly property var activeOpener: {
        if (menuStack.length >= 4) return subOpener3;
        if (menuStack.length === 3) return subOpener2;
        if (menuStack.length === 2) return subOpener1;
        return rootOpener;
    }

    function cleanLabel(s) {
        if (!s) return "";
        return String(s).replace(/&&/g, "\u0000").replace(/&/g, "").replace(/\u0000/g, "&").trim();
    }

    function resolveIcon(ic) {
        if (!ic) return "";
        var s = String(ic);
        if (s.indexOf("image://") === 0 || s.indexOf("file://") === 0) return s;
        if (s.charAt(0) === "/") return "file://" + s;
        var resolved = Quickshell.iconPath(s, true);
        if (!resolved || resolved === "") return "";
        if (resolved.charAt(0) === "/") return "file://" + resolved;
        return resolved;
    }

    function openForTrayItem(trayItem, screenX) {
        if (!trayItem || !trayItem.hasMenu || !trayItem.menu) return;
        var title = trayItem.tooltipTitle || trayItem.title || trayItem.id || "App";
        trayMenuWin.rootTitle = cleanLabel(title);
        trayMenuWin.rootIcon = trayItem.icon ? String(trayItem.icon) : "";
        trayMenuWin.rootMenuHandle = trayItem.menu;
        trayMenuWin.anchorX = screenX;
        trayMenuWin.menuStack = [{ handle: trayItem.menu, title: trayMenuWin.rootTitle }];
        trayMenuWin.closing = false;
        closeAnim.stop();

        if (trayMenuWin.visible) {
            menuCard.opacity = 0;
            menuCard.scale = 0.95;
            openAnim.restart();
            keyScope.forceActiveFocus();
        } else {
            trayMenuWin.visible = true;
        }
    }

    function pushSubmenu(entry) {
        if (!entry || !entry.hasChildren) return;
        if (trayMenuWin.menuStack.length >= 4) return;
        if (entry.updateLayout) entry.updateLayout();
        var next = trayMenuWin.menuStack.slice();
        next.push({ handle: entry, title: cleanLabel(entry.text) });
        trayMenuWin.menuStack = next;
    }

    function popSubmenu() {
        if (trayMenuWin.menuStack.length <= 1) {
            trayMenuWin.closeAnimated();
            return;
        }
        var next = trayMenuWin.menuStack.slice(0, trayMenuWin.menuStack.length - 1);
        trayMenuWin.menuStack = next;
    }

    function closeAnimated() {
        if (closing || !visible) return;
        closing = true;
        closeAnim.start();
    }

    // Keep parent DBusMenu handles open across every active stack level so
    // Quickshell never closes/destroys child DBusMenuItems while navigating submenus!
    QsMenuOpener {
        id: rootOpener
        menu: trayMenuWin.visible ? trayMenuWin.rootMenuHandle : null
    }
    QsMenuOpener {
        id: subOpener1
        menu: (trayMenuWin.visible && trayMenuWin.menuStack.length >= 2) ? trayMenuWin.menuStack[1].handle : null
    }
    QsMenuOpener {
        id: subOpener2
        menu: (trayMenuWin.visible && trayMenuWin.menuStack.length >= 3) ? trayMenuWin.menuStack[2].handle : null
    }
    QsMenuOpener {
        id: subOpener3
        menu: (trayMenuWin.visible && trayMenuWin.menuStack.length >= 4) ? trayMenuWin.menuStack[3].handle : null
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
    WlrLayershell.namespace: "quickshell-tray-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        if (visible) {
            closing = false;
            closeAnim.stop();
            menuCard.opacity = 0;
            menuCard.scale = 0.95;
            openAnim.restart();
            keyScope.forceActiveFocus();
        } else {
            closing = false;
            menuStack = [];
            rootMenuHandle = null;
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: menuCard; property: "opacity"; to: 1.0; duration: 140; easing.type: Easing.OutCubic }
        NumberAnimation { target: menuCard; property: "scale"; to: 1.0; duration: 155; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: menuCard; property: "opacity"; to: 0.0; duration: 105; easing.type: Easing.InCubic }
            NumberAnimation { target: menuCard; property: "scale"; to: 0.96; duration: 105; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                trayMenuWin.closing = false;
                trayMenuWin.closeRequested();
            }
        }
    }

    // Dismiss on outside click
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: trayMenuWin.closeAnimated()
    }

    Item {
        id: keyScope
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: trayMenuWin.popSubmenu()
        Keys.onLeftPressed: {
            if (trayMenuWin.inSubmenu) trayMenuWin.popSubmenu();
        }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Backspace && trayMenuWin.inSubmenu) {
                trayMenuWin.popSubmenu();
                event.accepted = true;
            }
        }
    }

    // Ambient shadow behind card
    Rectangle {
        x: menuCard.x - 6
        y: menuCard.y - 4
        width: menuCard.width + 12
        height: menuCard.height + 12
        radius: menuCard.radius + 4
        color: "#60000000"
        opacity: menuCard.opacity
        scale: menuCard.scale
        transformOrigin: Item.Top
    }

    // Obsidian Glass Tray Menu Card anchored cleanly below clicked tray icon
    Rectangle {
        id: menuCard
        width: 256
        readonly property real maxBodyH: Math.max(180, trayMenuWin.height - 130)
        readonly property real desiredBodyH: Math.max(38, itemsCol.implicitHeight)
        height: Math.min(maxBodyH, desiredBodyH) + headerRow.implicitHeight + 28
        x: Math.max(10, Math.min(trayMenuWin.width - width - 10, trayMenuWin.anchorX - width / 2))
        y: 44
        radius: 15
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1
        opacity: 0
        scale: 0.95
        transformOrigin: Item.Top
        clip: true

        // Top subtle theme accent shimmer
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 1
            width: parent.width * 0.45
            height: 1
            radius: 0.5
            color: Theme.accent
            opacity: 0.45
        }

        // Consume clicks inside menu
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Header: App icon + Title OR Back button when inside a submenu
            Rectangle {
                id: headerRow
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 9
                color: (trayMenuWin.inSubmenu && backArea.containsMouse) ? Theme.bgHover : Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    spacing: 8

                    Text {
                        visible: trayMenuWin.inSubmenu
                        text: "󰅁"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: backArea.containsMouse ? Theme.accent : Theme.textSecondary
                    }

                    Image {
                        visible: !trayMenuWin.inSubmenu && trayMenuWin.rootIcon !== ""
                        source: trayMenuWin.rootIcon
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        sourceSize.width: 15
                        sourceSize.height: 15
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        text: trayMenuWin.headerTitle
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    enabled: trayMenuWin.inSubmenu
                    hoverEnabled: true
                    cursorShape: trayMenuWin.inSubmenu ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: trayMenuWin.popSubmenu()
                }
            }

            // Scrollable Dynamic DBusMenu Entries
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: itemsCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: itemsCol
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: trayMenuWin.activeOpener ? trayMenuWin.activeOpener.children : null

                        delegate: Item {
                            id: entryWrap
                            required property var modelData
                            readonly property bool isSep: modelData ? Boolean(modelData.isSeparator) : false
                            readonly property bool isEnabled: modelData ? Boolean(modelData.enabled) : false
                            readonly property bool hasSub: modelData ? Boolean(modelData.hasChildren) : false
                            readonly property int btnType: modelData ? modelData.buttonType : 0
                            readonly property int chkState: modelData ? modelData.checkState : 0
                            readonly property string labelTxt: modelData ? trayMenuWin.cleanLabel(modelData.text) : ""
                            readonly property string iconSrc: modelData ? trayMenuWin.resolveIcon(modelData.icon) : ""

                            // Hide empty non-separator placeholders some Electron/Qt trays emit
                            visible: isSep || labelTxt !== ""
                            Layout.fillWidth: true
                            implicitHeight: !visible ? 0 : (isSep ? 9 : 34)

                            // Separator
                            Rectangle {
                                visible: entryWrap.isSep
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                height: 1
                                color: Theme.borderSubtle
                            }

                            // Interactive Menu Row
                            Rectangle {
                                visible: !entryWrap.isSep && entryWrap.visible
                                anchors.fill: parent
                                radius: 9
                                color: (entryWrap.isEnabled && entryArea.containsMouse) ? Theme.bgHover : "transparent"
                                scale: (entryWrap.isEnabled && entryArea.pressed) ? 0.97 : 1.0
                                Behavior on color { ColorAnimation { duration: 110 } }
                                Behavior on scale { NumberAnimation { duration: 90 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 9

                                    // CheckBox / RadioButton indicator when present
                                    Text {
                                        visible: entryWrap.btnType !== QsMenuButtonType.None
                                        text: {
                                            if (entryWrap.btnType === QsMenuButtonType.CheckBox) {
                                                return entryWrap.chkState === Qt.Checked ? "󰄲" : "󰄱";
                                            }
                                            return entryWrap.chkState === Qt.Checked ? "󰄯" : "󰄰";
                                        }
                                        font.family: Theme.fontMono
                                        font.pixelSize: 13
                                        color: entryWrap.chkState === Qt.Checked ? Theme.accent : Theme.textMuted
                                        Layout.preferredWidth: 16
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Entry icon (if provided by app and no checkbox/radio)
                                    Image {
                                        visible: entryWrap.btnType === QsMenuButtonType.None && entryWrap.iconSrc !== ""
                                        source: entryWrap.iconSrc
                                        Layout.preferredWidth: 15
                                        Layout.preferredHeight: 15
                                        sourceSize.width: 15
                                        sourceSize.height: 15
                                        fillMode: Image.PreserveAspectFit
                                        opacity: entryWrap.isEnabled ? 1.0 : 0.45
                                    }

                                    // Label
                                    Text {
                                        text: entryWrap.labelTxt
                                        font.family: Theme.fontSans
                                        font.pixelSize: 12
                                        font.weight: entryWrap.isEnabled ? Font.Medium : Font.Normal
                                        color: entryWrap.isEnabled ? Theme.textPrimary : Theme.textSecondary
                                        opacity: entryWrap.isEnabled ? 1.0 : 0.88
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Submenu chevron
                                    Text {
                                        visible: entryWrap.hasSub
                                        text: "󰅂"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 13
                                        color: (entryWrap.isEnabled && entryArea.containsMouse) ? Theme.accent : Theme.textMuted
                                        Behavior on color { ColorAnimation { duration: 110 } }
                                    }
                                }

                                MouseArea {
                                    id: entryArea
                                    anchors.fill: parent
                                    enabled: entryWrap.isEnabled
                                    hoverEnabled: true
                                    cursorShape: entryWrap.isEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        var ent = entryWrap.modelData;
                                        if (!ent) return;
                                        if (ent.hasChildren) {
                                            trayMenuWin.pushSubmenu(ent);
                                        } else {
                                            ent.triggered();
                                            trayMenuWin.closeAnimated();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Graceful subtle loading state while DBusMenu populates asynchronously
                    Text {
                        visible: !trayMenuWin.activeOpener || !trayMenuWin.activeOpener.children || !trayMenuWin.activeOpener.children.values || trayMenuWin.activeOpener.children.values.length === 0
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        Layout.bottomMargin: 8
                        horizontalAlignment: Text.AlignHCenter
                        text: "..."
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }
            }
        }
    }
}
