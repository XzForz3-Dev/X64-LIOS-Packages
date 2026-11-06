import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: overviewWindow

    signal closeRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "#d0050508"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Dismiss on background click
    MouseArea {
        anchors.fill: parent
        onClicked: overviewWindow.closeRequested()
    }

    // =========================================================================
    // STATE & DATA RETRIEVAL
    // =========================================================================
    property int activeWorkspaceId: 1
    property var allClients: []

    function reload() {
        if (!dataProc.running) {
            dataProc.running = true;
        }
    }

    function focusWorkspace(wsId) {
        actionProc.command = ["x64-hyprland-ctl", "focus-workspace", wsId.toString()];
        actionProc.running = true;
        overviewWindow.closeRequested();
    }

    function focusWindow(addr) {
        actionProc.command = ["x64-hyprland-ctl", "focus-window", addr.toString()];
        actionProc.running = true;
        overviewWindow.closeRequested();
    }

    function getWindowsForWorkspace(wsId) {
        var res = [];
        for (var i = 0; i < allClients.length; i++) {
            var c = allClients[i];
            if (c && c.workspace && c.workspace.id === wsId) {
                res.push(c);
            }
        }
        return res;
    }

    function getIconForClass(cls) {
        if (!cls) return "";
        var lower = cls.toLowerCase();
        if (lower.indexOf("kitty") !== -1 || lower.indexOf("terminal") !== -1) return "";
        if (lower.indexOf("dolphin") !== -1 || lower.indexOf("thunar") !== -1 || lower.indexOf("files") !== -1) return "󰉋";
        if (lower.indexOf("chromium") !== -1 || lower.indexOf("firefox") !== -1 || lower.indexOf("brave") !== -1 || lower.indexOf("browser") !== -1) return "󰖟";
        if (lower.indexOf("opencode") !== -1) return "󰚩";
        if (lower.indexOf("btop") !== -1 || lower.indexOf("monitor") !== -1) return "󰻠";
        if (lower.indexOf("steam") !== -1 || lower.indexOf("heroic") !== -1 || lower.indexOf("lutris") !== -1) return "󰓓";
        if (lower.indexOf("code") !== -1 || lower.indexOf("vsc") !== -1) return "󰨞";
        if (lower.indexOf("discord") !== -1) return "󰙯";
        if (lower.indexOf("spotify") !== -1) return "󰓇";
        return "";
    }

    onVisibleChanged: {
        if (visible) {
            reload();
        }
    }

    // Process to fetch active workspace & client list in unified JSON
    Process {
        id: dataProc
        command: ["x64-hyprland-ctl", "overview-data"]
        stdout: StdioCollector {
            id: dataCollector
            onStreamFinished: {
                if (!dataCollector.text) return;
                try {
                    var data = JSON.parse(dataCollector.text.trim());
                    overviewWindow.activeWorkspaceId = data.active || 1;
                    overviewWindow.allClients = data.clients || [];
                } catch (e) {
                    overviewWindow.activeWorkspaceId = 1;
                    overviewWindow.allClients = [];
                }
            }
        }
    }

    Process {
        id: actionProc
        command: ["true"]
    }

    // =========================================================================
    // MAIN MISSION CONTROL MODAL (OBSIDIAN & CRIMSON)
    // =========================================================================
    Rectangle {
        id: mainCard
        width: 1000
        height: 660
        anchors.centerIn: parent

        color: "#12141a"
        radius: 14
        border.color: Theme.accentBorder
        border.width: 1

        // Consume clicks so background dismiss doesn't trigger
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // -----------------------------------------------------------------
            // 1. HEADER (Title, Crimson Badge & Quick Actions)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Crimson Icon Badge
                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 8
                    color: Theme.accentDim
                    border.color: Theme.accentBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰘳"
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                        color: Theme.accent
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: I18n.isEs ? "VISTA GENERAL DE ESCRITORIOS • MISSION CONTROL" : "WORKSPACES OVERVIEW • MISSION CONTROL"
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        text: I18n.isEs
                            ? "Navegación espacial entre los 6 escritorios virtuales y ventanas activas"
                            : "Spatial navigation across all 6 virtual workspaces and running windows"
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        color: Theme.textSecondary
                    }
                }

                // Shortcut Hint Pill
                Rectangle {
                    implicitHeight: 26
                    implicitWidth: hintRow.implicitWidth + 14
                    radius: 6
                    color: "#14ffffff"
                    border.color: "#18ffffff"
                    border.width: 1

                    RowLayout {
                        id: hintRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "SUPER + TAB"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.accent
                        }
                    }
                }

                // ESC Close Pill
                Rectangle {
                    implicitWidth: 54
                    implicitHeight: 26
                    radius: 6
                    color: escArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                    border.color: escArea.containsMouse ? Theme.accentBorder : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "ESC"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textSecondary
                        }
                        Text {
                            text: "×"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            color: Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: escArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: overviewWindow.closeRequested()
                    }
                }
            }

            // Separator Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            // -----------------------------------------------------------------
            // 2. WORKSPACES 3x2 GRID CONTAINER
            // -----------------------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Grid {
                    id: workspacesGrid
                    anchors.fill: parent
                    columns: 3
                    spacing: 12

                    readonly property real cellWidth: (width - (spacing * 2)) / 3
                    readonly property real cellHeight: (height - spacing) / 2

                    Repeater {
                        model: [1, 2, 3, 4, 5, 6]

                        Item {
                            id: wsCell
                            width: workspacesGrid.cellWidth
                            height: workspacesGrid.cellHeight

                            readonly property int wsId: modelData
                            readonly property bool isActiveWs: overviewWindow.activeWorkspaceId === wsId
                            readonly property var wsWindows: overviewWindow.getWindowsForWorkspace(wsId)

                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: wsCell.isActiveWs
                                    ? "#161822"
                                    : (wsMouseArea.containsMouse ? Theme.bgHover : "#101218")
                                border.color: wsCell.isActiveWs
                                    ? Theme.accent
                                    : (wsMouseArea.containsMouse ? "#44ffffff" : "#222634")
                                border.width: wsCell.isActiveWs ? 2 : 1
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                                Behavior on color { ColorAnimation { duration: 120 } }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    // Workspace Header
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        // Workspace ID Pill
                                        Rectangle {
                                            implicitHeight: 22
                                            implicitWidth: wsTitleRow.implicitWidth + 12
                                            radius: 5
                                            color: wsCell.isActiveWs ? Theme.accentDim : "#18ffffff"
                                            border.color: wsCell.isActiveWs ? Theme.accentBorder : "transparent"
                                            border.width: 1

                                            RowLayout {
                                                id: wsTitleRow
                                                anchors.centerIn: parent
                                                spacing: 4

                                                Text {
                                                    text: "󰘳"
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 10
                                                    color: wsCell.isActiveWs ? Theme.accent : Theme.textSecondary
                                                }

                                                Text {
                                                    text: (I18n.isEs ? "Escritorio " : "Workspace ") + wsCell.wsId
                                                    font.family: Theme.fontSans
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: wsCell.isActiveWs ? Theme.textPrimary : Theme.textSecondary
                                                }
                                            }
                                        }

                                        // Active Tag Badge
                                        Rectangle {
                                            visible: wsCell.isActiveWs
                                            implicitHeight: 18
                                            implicitWidth: activeLabel.implicitWidth + 8
                                            radius: 4
                                            color: Theme.accent
                                            Text {
                                                id: activeLabel
                                                anchors.centerIn: parent
                                                text: I18n.isEs ? "ACTUAL" : "CURRENT"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: "#ffffff"
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Window Count Badge
                                        Text {
                                            text: wsCell.wsWindows.length === 0
                                                ? (I18n.isEs ? "Vacío" : "Empty")
                                                : (wsCell.wsWindows.length + (wsCell.wsWindows.length === 1 ? (I18n.isEs ? " ventana" : " window") : (I18n.isEs ? " ventanas" : " windows")))
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                            color: wsCell.wsWindows.length === 0 ? Theme.textMuted : Theme.textSecondary
                                        }
                                    }

                                    // Workspace Content Area
                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        // Empty Workspace Visual
                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            visible: wsCell.wsWindows.length === 0
                                            spacing: 4

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: "󰘳"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 22
                                                color: "#22ffffff"
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: I18n.isEs ? "Sin ventanas abiertas" : "No open windows"
                                                font.family: Theme.fontSans
                                                font.pixelSize: 9
                                                color: Theme.textMuted
                                            }

                                            Text {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: I18n.isEs ? "Clic para ir a este espacio" : "Click to switch here"
                                                font.family: Theme.fontSans
                                                font.pixelSize: 8
                                                color: "#44ffffff"
                                            }
                                        }

                                        // Running Windows List
                                        ListView {
                                            anchors.fill: parent
                                            visible: wsCell.wsWindows.length > 0
                                            spacing: 4
                                            clip: true
                                            model: wsCell.wsWindows

                                            delegate: Item {
                                                id: winItem
                                                width: parent ? parent.width : 200
                                                height: 38

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 6
                                                    color: winArea.containsMouse ? Theme.accentDim : "#181a24"
                                                    border.color: winArea.containsMouse ? Theme.accent : "#282c3c"
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 100 } }
                                                    Behavior on border.color { ColorAnimation { duration: 100 } }

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 8
                                                        anchors.rightMargin: 8
                                                        spacing: 8

                                                        // Window Icon Badge
                                                        Rectangle {
                                                            implicitWidth: 24
                                                            implicitHeight: 24
                                                            radius: 5
                                                            color: winArea.containsMouse ? Theme.accent : "#20ffffff"
                                                            Behavior on color { ColorAnimation { duration: 100 } }

                                                            Text {
                                                                anchors.centerIn: parent
                                                                text: overviewWindow.getIconForClass(modelData.class)
                                                                font.family: Theme.fontMono
                                                                font.pixelSize: 11
                                                                color: winArea.containsMouse ? "#ffffff" : Theme.textPrimary
                                                            }
                                                        }

                                                        // Window Title & Class
                                                        ColumnLayout {
                                                            Layout.fillWidth: true
                                                            spacing: 1

                                                            Text {
                                                                Layout.fillWidth: true
                                                                text: modelData.title || modelData.class || "Window"
                                                                font.family: Theme.fontSans
                                                                font.pixelSize: 10
                                                                font.bold: true
                                                                color: winArea.containsMouse ? Theme.textPrimary : Theme.textPrimary
                                                                elide: Text.ElideRight
                                                            }

                                                            RowLayout {
                                                                spacing: 6
                                                                Text {
                                                                    text: modelData.class || ""
                                                                    font.family: Theme.fontMono
                                                                    font.pixelSize: 8
                                                                    color: Theme.textMuted
                                                                    elide: Text.ElideRight
                                                                }

                                                                Text {
                                                                    visible: modelData.floating
                                                                    text: "• " + (I18n.isEs ? "Flotante" : "Float")
                                                                    font.family: Theme.fontSans
                                                                    font.pixelSize: 8
                                                                    color: Theme.accent
                                                                }
                                                            }
                                                        }

                                                        // Focus Jump Pill
                                                        Text {
                                                            text: "󰅂"
                                                            font.family: Theme.fontMono
                                                            font.pixelSize: 11
                                                            color: winArea.containsMouse ? Theme.accent : Theme.textMuted
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: winArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: overviewWindow.focusWindow(modelData.address)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Click on empty area of workspace card jumps to that workspace
                                MouseArea {
                                    id: wsMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: -1
                                    onClicked: overviewWindow.focusWorkspace(wsCell.wsId)
                                }
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. FOOTER (Status & Navigation Guide)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰘳"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.accent
                }

                Text {
                    text: I18n.isEs
                        ? "6 escritorios virtuales • Clic en ventana para enfocar o en escritorio para saltar • ESC para cerrar"
                        : "6 virtual workspaces • Click window to focus or workspace to switch • ESC to dismiss"
                    font.family: Theme.fontSans
                    font.pixelSize: 10
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "X64 LIOS Hyprland • Obsidian & Crimson 2026"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }
}

