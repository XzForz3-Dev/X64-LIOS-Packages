import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// =============================================================================
// X64 LIOS - Native Obsidian Desktop Context Menu (DesktopContextMenu.qml)
// Triggered by single right-click on empty desktop on any monitor.
// Auto-clamps cleanly inside screen bounds (respecting the 40px top bar).
// =============================================================================
PanelWindow {
    id: ctxWindow

    signal closeRequested()
    signal triggerAction(string actionId, var targetScreen, real nx, real ny)

    property real anchorX: 160
    property real anchorY: 160
    property bool closing: false
    property int selectedIndex: -1

    readonly property var menuItems: [
        { type: "item", id: "launcher",   icon: "󰀻", label: I18n.ctxApps,       shortcut: "SUPER + Space", danger: false },
        { type: "item", id: "overview",   icon: "󰖯", label: I18n.ctxOverview,   shortcut: "SUPER + Tab",   danger: false },
        { type: "item", id: "terminal",   icon: "󰆍", label: I18n.ctxTerminal,   shortcut: "SUPER + ↵",     danger: false },
        { type: "item", id: "files",      icon: "󰉋", label: I18n.ctxFiles,      shortcut: "SUPER + E",     danger: false },
        { type: "sep" },
        { type: "item", id: "themes",     icon: "󰏘", label: I18n.ctxThemes,     shortcut: "SUPER + T",     danger: false },
        { type: "item", id: "screenshot", icon: "󰄀", label: I18n.ctxScreenshot, shortcut: "SUPER + ⇧ + S", danger: false },
        { type: "sep" },
        { type: "item", id: "power",      icon: "󰐥", label: I18n.ctxPower,      shortcut: "SUPER + M",     danger: true  }
    ]

    function openAt(px, py) {
        ctxWindow.anchorX = px;
        ctxWindow.anchorY = py;
        ctxWindow.selectedIndex = -1;
        ctxWindow.closing = false;
        closeAnim.stop();
        if (ctxWindow.visible) {
            menuCard.opacity = 0;
            menuCard.scale = 0.94;
            openAnim.restart();
            keyScope.forceActiveFocus();
        } else {
            ctxWindow.visible = true;
        }
    }

    function closeAnimated() {
        if (closing || !visible) return;
        closing = true;
        closeAnim.start();
    }

    function runItem(itemId) {
        var w = Math.max(1, ctxWindow.width);
        var h = Math.max(1, ctxWindow.height);
        var nx = Math.max(0.05, Math.min(0.95, ctxWindow.anchorX / w));
        var ny = Math.max(0.05, Math.min(0.95, ctxWindow.anchorY / h));
        var sc = ctxWindow.screen;
        ctxWindow.closing = false;
        ctxWindow.visible = false;
        ctxWindow.triggerAction(itemId, sc, nx, ny);
    }

    function moveSelection(delta) {
        var list = ctxWindow.menuItems;
        var idx = ctxWindow.selectedIndex;
        for (var step = 0; step < list.length; step++) {
            idx = (idx + delta + list.length) % list.length;
            if (list[idx].type === "item") {
                ctxWindow.selectedIndex = idx;
                return;
            }
        }
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
    WlrLayershell.namespace: "quickshell-context-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        if (visible) {
            closing = false;
            selectedIndex = -1;
            closeAnim.stop();
            menuCard.opacity = 0;
            menuCard.scale = 0.94;
            openAnim.restart();
            keyScope.forceActiveFocus();
        } else {
            closing = false;
            selectedIndex = -1;
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: menuCard; property: "opacity"; to: 1.0; duration: 135; easing.type: Easing.OutCubic }
        NumberAnimation { target: menuCard; property: "scale"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: menuCard; property: "opacity"; to: 0.0; duration: 100; easing.type: Easing.InCubic }
            NumberAnimation { target: menuCard; property: "scale"; to: 0.95; duration: 100; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                ctxWindow.closing = false;
                ctxWindow.closeRequested();
            }
        }
    }

    // Transparent fullscreen click-outside catcher (right-click repositions smoothly!)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                ctxWindow.openAt(mouse.x, mouse.y);
            } else {
                ctxWindow.closeAnimated();
            }
        }
    }

    Item {
        id: keyScope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: ctxWindow.closeAnimated()
        Keys.onDownPressed: ctxWindow.moveSelection(1)
        Keys.onUpPressed: ctxWindow.moveSelection(-1)
        Keys.onReturnPressed: {
            if (ctxWindow.selectedIndex >= 0 && ctxWindow.selectedIndex < ctxWindow.menuItems.length) {
                var it = ctxWindow.menuItems[ctxWindow.selectedIndex];
                if (it && it.type === "item") ctxWindow.runItem(it.id);
            }
        }
        Keys.onEnterPressed: {
            if (ctxWindow.selectedIndex >= 0 && ctxWindow.selectedIndex < ctxWindow.menuItems.length) {
                var it = ctxWindow.menuItems[ctxWindow.selectedIndex];
                if (it && it.type === "item") ctxWindow.runItem(it.id);
            }
        }
    }

    // Ambient shadow behind menu card for crisp separation over dark wallpapers
    Rectangle {
        x: menuCard.x - 6
        y: menuCard.y - 4
        width: menuCard.width + 12
        height: menuCard.height + 12
        radius: menuCard.radius + 4
        color: "#60000000"
        opacity: menuCard.opacity
        scale: menuCard.scale
        transformOrigin: Item.TopLeft
    }

    // Obsidian Glass Context Menu Card positioned cleanly at cursor
    Rectangle {
        id: menuCard
        readonly property real padRight: 12
        readonly property real padBottom: 12
        x: Math.max(10, Math.min(ctxWindow.width - width - padRight, ctxWindow.anchorX))
        y: Math.max(46, Math.min(ctxWindow.height - height - padBottom, ctxWindow.anchorY))
        width: 292
        height: menuCol.implicitHeight + 18
        radius: 16
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1
        opacity: 0
        scale: 0.94
        transformOrigin: Item.TopLeft

        // Delicate top accent shimmer
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
            id: menuCol
            anchors.fill: parent
            anchors.margins: 9
            spacing: 3

            Repeater {
                model: ctxWindow.menuItems

                Loader {
                    id: rowLoader
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    sourceComponent: modelData.type === "sep" ? sepComp : itemComp

                    property var rowData: modelData
                    property int rowIndex: index
                }
            }
        }
    }

    Component {
        id: sepComp
        Item {
            implicitHeight: 11
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                height: 1
                color: Theme.borderSubtle
            }
        }
    }

    Component {
        id: itemComp
        Rectangle {
            id: rowRect
            readonly property var itemData: parent ? parent.rowData : ({ icon: "", label: "", shortcut: "", id: "", danger: false })
            readonly property int itemIdx: parent ? parent.rowIndex : -1
            readonly property bool isLit: rowArea.containsMouse || ctxWindow.selectedIndex === itemIdx
            readonly property color hiColor: itemData.danger ? Theme.statusCrit : Theme.accent

            implicitHeight: 38
            radius: 10
            color: isLit
                ? (itemData.danger ? Qt.rgba(Theme.statusCrit.r, Theme.statusCrit.g, Theme.statusCrit.b, 0.18) : Theme.bgHover)
                : "transparent"
            scale: rowArea.pressed ? 0.97 : 1.0
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 100 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 11

                Text {
                    text: rowRect.itemData.icon
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: rowRect.isLit
                        ? rowRect.hiColor
                        : (rowRect.itemData.danger ? Theme.statusCrit : Theme.textSecondary)
                    Layout.preferredWidth: 20
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Text {
                    text: rowRect.itemData.label
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: rowRect.isLit
                        ? (rowRect.itemData.danger ? Theme.statusCrit : Theme.textPrimary)
                        : Theme.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Text {
                    text: rowRect.itemData.shortcut
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: rowRect.isLit ? Theme.textPrimary : Theme.textSecondary
                    opacity: rowRect.isLit ? 0.92 : 0.72
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: ctxWindow.selectedIndex = rowRect.itemIdx
                onClicked: ctxWindow.runItem(rowRect.itemData.id)
            }
        }
    }
}
