import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: clipboardWindow

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
        onClicked: clipboardWindow.closeRequested()
    }

    // =========================================================================
    // STATE & REACTIVE DATA
    // =========================================================================
    property string searchQuery: ""
    property string currentCategory: "all" // all, urls, commands, text
    property var rawItems: []
    property int selectedIndex: 0

    // Filter items based on active search text and category filter
    readonly property var filteredItems: {
        var q = searchQuery.toLowerCase().trim();
        var cat = currentCategory;
        var res = [];

        for (var i = 0; i < rawItems.length; i++) {
            var it = rawItems[i];
            if (!it) continue;

            // Category filter
            if (cat === "urls" && !it.isUrl) continue;
            if (cat === "commands" && !it.isCmd) continue;
            if (cat === "text" && (it.isUrl || it.isCmd)) continue;

            // Text search filter
            if (q !== "" && it.content.toLowerCase().indexOf(q) === -1) continue;

            res.push(it);
        }
        return res;
    }

    function reload() {
        if (!listProc.running) {
            listProc.running = true;
        }
    }

    function copyItem(itemId) {
        if (!copyProc.running) {
            copyProc.command = ["x64-hyprland-ctl", "clipboard", "paste", itemId];
            copyProc.running = true;
        }
        clipboardWindow.closeRequested();
    }

    function deleteItem(itemContent) {
        if (!deleteProc.running) {
            deleteProc.command = ["x64-hyprland-ctl", "clipboard", "delete", itemContent];
            deleteProc.running = true;
        }
    }

    function wipeHistory() {
        if (!wipeProc.running) {
            wipeProc.running = true;
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchQuery = "";
            currentCategory = "all";
            selectedIndex = 0;
            reload();
            searchField.forceActiveFocus();
        }
    }

    // =========================================================================
    // PROCESSES (IO COMMUNICATORS)
    // =========================================================================
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                if (!listCollector.text) {
                    clipboardWindow.rawItems = [];
                    return;
                }
                var lines = listCollector.text.split("\n");
                var parsed = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (!line || line.trim() === "") continue;
                    var tabIdx = line.indexOf("\t");
                    if (tabIdx === -1) continue;

                    var idStr = line.substring(0, tabIdx).trim();
                    var contentStr = line.substring(tabIdx + 1);

                    var lower = contentStr.toLowerCase();
                    var isUrl = lower.startsWith("http://") || lower.startsWith("https://") || lower.startsWith("ftp://") || lower.startsWith("www.");
                    var isCmd = lower.startsWith("sudo ") || lower.startsWith("pacman ") || lower.startsWith("git ") ||
                                lower.startsWith("systemctl ") || lower.startsWith("curl ") || lower.startsWith("cd ") ||
                                lower.startsWith("cat ") || lower.startsWith("ssh ") || lower.startsWith("makepkg ") ||
                                lower.startsWith("yay ") || lower.startsWith("echo ") || lower.startsWith("killall ");

                    parsed.push({
                        id: idStr,
                        content: contentStr,
                        isUrl: isUrl,
                        isCmd: isCmd
                    });
                }
                clipboardWindow.rawItems = parsed;
            }
        }
    }

    Process {
        id: copyProc
        command: ["true"]
    }

    Process {
        id: deleteProc
        command: ["true"]
        onExited: clipboardWindow.reload()
    }

    Process {
        id: wipeProc
        command: ["x64-hyprland-ctl", "clipboard", "clear"]
        onExited: clipboardWindow.reload()
    }

    // =========================================================================
    // POPUP MAIN CARD (OBSIDIAN & CRIMSON)
    // =========================================================================
    Rectangle {
        id: mainCard
        width: 740
        height: 560
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
            // 1. HEADER (Title, Crimson Badge & Action Buttons)
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
                        text: "󰅍"
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
                        text: I18n.isEs ? "HISTORIAL DEL PORTAPAPELES • X64" : "CLIPBOARD HISTORY • X64"
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        text: I18n.isEs
                            ? "Gestor visual de textos, códigos y enlaces copiados recientemente"
                            : "Visual history manager for recently copied text, snippets and URLs"
                        font.family: Theme.fontSans
                        font.pixelSize: 10
                        color: Theme.textSecondary
                    }
                }

                // Clear / Wipe History Button
                Rectangle {
                    id: wipeBtn
                    implicitWidth: wipeRow.implicitWidth + 16
                    implicitHeight: 28
                    radius: 6
                    color: wipeArea.containsMouse ? Theme.accentDim : Theme.bgElevated
                    border.color: wipeArea.containsMouse ? Theme.accent : Theme.borderSubtle
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: wipeRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰆴"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: wipeArea.containsMouse ? Theme.accent : Theme.textSecondary
                        }

                        Text {
                            text: I18n.isEs ? "Vaciar Historial" : "Clear All"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: wipeArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: wipeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clipboardWindow.wipeHistory()
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
                        onClicked: clipboardWindow.closeRequested()
                    }
                }
            }

            // -----------------------------------------------------------------
            // 2. SEARCH INPUT BOX
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 8
                color: Theme.bgElevated
                border.color: searchField.activeFocus ? Theme.accent : Theme.borderSubtle
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: searchField.activeFocus ? Theme.accent : Theme.textMuted
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: I18n.isEs
                            ? "Buscar en el historial... (ej. link, comando, código, texto...)"
                            : "Search in history... (e.g. link, command, code, text...)"
                        placeholderTextColor: Theme.textMuted
                        color: Theme.textPrimary
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        background: null
                        text: clipboardWindow.searchQuery
                        onTextChanged: {
                            clipboardWindow.searchQuery = text;
                            clipboardWindow.selectedIndex = 0;
                        }

                        Keys.onEscapePressed: clipboardWindow.closeRequested()
                        Keys.onDownPressed: {
                            if (clipboardWindow.filteredItems.length > 0) {
                                clipboardWindow.selectedIndex = Math.min(clipboardWindow.selectedIndex + 1, clipboardWindow.filteredItems.length - 1);
                                clipList.positionViewAtIndex(clipboardWindow.selectedIndex, ListView.Contain);
                            }
                        }
                        Keys.onUpPressed: {
                            if (clipboardWindow.filteredItems.length > 0) {
                                clipboardWindow.selectedIndex = Math.max(clipboardWindow.selectedIndex - 1, 0);
                                clipList.positionViewAtIndex(clipboardWindow.selectedIndex, ListView.Contain);
                            }
                        }
                        Keys.onReturnPressed: {
                            if (clipboardWindow.filteredItems.length > 0 && clipboardWindow.selectedIndex >= 0 && clipboardWindow.selectedIndex < clipboardWindow.filteredItems.length) {
                                clipboardWindow.copyItem(clipboardWindow.filteredItems[clipboardWindow.selectedIndex].id);
                            }
                        }
                    }

                    // Clear search button
                    Rectangle {
                        visible: searchField.text.length > 0
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 9
                        color: clearArea.containsMouse ? Theme.accent : "#2b303d"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            color: Theme.textPrimary
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchField.text = "";
                                searchField.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. CATEGORY FILTER PILLS
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { id: "all",      icon: "", label: I18n.isEs ? "Todos" : "All" },
                        { id: "urls",     icon: "", label: I18n.isEs ? "Enlaces" : "Links" },
                        { id: "commands", icon: "", label: I18n.isEs ? "Comandos" : "Commands" },
                        { id: "text",     icon: "󰦨", label: I18n.isEs ? "Texto" : "Text" }
                    ]

                    Rectangle {
                        id: filterBtn
                        implicitHeight: 26
                        implicitWidth: filterRow.implicitWidth + 16
                        radius: 6
                        readonly property bool isSelected: clipboardWindow.currentCategory === modelData.id
                        color: isSelected ? Theme.accentDim : (filterArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                        border.color: isSelected ? Theme.accentBorder : (filterArea.containsMouse ? "#28ffffff" : Theme.borderSubtle)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: filterRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: filterBtn.isSelected ? Theme.accent : Theme.textSecondary
                            }

                            Text {
                                text: modelData.label
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.bold: filterBtn.isSelected
                                color: filterBtn.isSelected ? Theme.textPrimary : Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: filterArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                clipboardWindow.currentCategory = modelData.id;
                                clipboardWindow.selectedIndex = 0;
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: clipboardWindow.filteredItems.length + (I18n.isEs ? " elementos" : " items")
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }

            // -----------------------------------------------------------------
            // 4. CLIPBOARD LIST VIEW
            // -----------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: "#0d0e13"
                border.color: Theme.borderSubtle
                border.width: 1
                clip: true

                ListView {
                    id: clipList
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    model: clipboardWindow.filteredItems

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Item {
                        id: itemDelegate
                        width: clipList.width - 8
                        height: 52
                        readonly property bool isSel: clipboardWindow.selectedIndex === index

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: itemDelegate.isSel
                                ? Theme.accentDim
                                : (itemMouseArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                            border.color: itemDelegate.isSel
                                ? Theme.accent
                                : (itemMouseArea.containsMouse ? Theme.accentBorder : Theme.borderSubtle)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                // Type Icon & Index Badge (Sober Obsidian & Crimson)
                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 6
                                    color: itemDelegate.isSel ? "#25ff2b2b" : (itemMouseArea.containsMouse ? "#20ffffff" : "#14ffffff")
                                    border.color: itemDelegate.isSel ? Theme.accent : (itemMouseArea.containsMouse ? "#33ffffff" : "#22ffffff")
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.isUrl ? "" : (modelData.isCmd ? "" : "󰦨")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                        color: itemDelegate.isSel ? Theme.accent : Theme.textSecondary
                                    }
                                }

                                // Content Preview
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.content
                                        font.family: modelData.isCmd ? Theme.fontMono : Theme.fontSans
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: itemDelegate.isSel ? Theme.textPrimary : Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: modelData.isUrl
                                                ? (I18n.isEs ? "Enlace web" : "Web Link")
                                                : (modelData.isCmd ? (I18n.isEs ? "Comando / Terminal" : "Terminal Command") : (I18n.isEs ? "Texto sin formato" : "Plain Text"))
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                            color: Theme.textMuted
                                        }

                                        Text {
                                            text: "•"
                                            font.family: Theme.fontSans
                                            font.pixelSize: 9
                                            color: Theme.textMuted
                                        }

                                        Text {
                                            text: modelData.content.length + (I18n.isEs ? " caracteres" : " chars")
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            color: Theme.textMuted
                                        }
                                    }
                                }

                                // Action Buttons: Copy & Delete
                                RowLayout {
                                    spacing: 6

                                    // Copy Pill
                                    Rectangle {
                                        implicitWidth: copyRow.implicitWidth + 12
                                        implicitHeight: 26
                                        radius: 5
                                        color: copyArea.containsMouse ? Theme.accentDim : "#14ffffff"
                                        border.color: copyArea.containsMouse ? Theme.accent : "#22ffffff"
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Behavior on border.color { ColorAnimation { duration: 100 } }

                                        RowLayout {
                                            id: copyRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: "󰆏"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 10
                                                color: copyArea.containsMouse ? Theme.accent : Theme.textSecondary
                                            }

                                            Text {
                                                text: I18n.isEs ? "Copiar" : "Copy"
                                                font.family: Theme.fontSans
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: copyArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                            }
                                        }

                                        MouseArea {
                                            id: copyArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: clipboardWindow.copyItem(modelData.id)
                                        }
                                    }

                                    // Delete Single Item Button
                                    Rectangle {
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        radius: 5
                                        color: delArea.containsMouse ? Theme.accentDim : "#14ffffff"
                                        border.color: delArea.containsMouse ? Theme.accent : "transparent"
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Behavior on border.color { ColorAnimation { duration: 100 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 11
                                            color: delArea.containsMouse ? Theme.accent : Theme.textMuted
                                        }

                                        MouseArea {
                                            id: delArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: clipboardWindow.deleteItem(modelData.content)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    clipboardWindow.selectedIndex = index;
                                    clipboardWindow.copyItem(modelData.id);
                                }
                            }
                        }
                    }
                }

                // Empty State
                Item {
                    anchors.centerIn: parent
                    visible: clipboardWindow.filteredItems.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "󰅍"
                            font.family: Theme.fontMono
                            font.pixelSize: 32
                            color: Theme.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.isEs
                                ? "El historial del portapapeles está vacío"
                                : "Clipboard history is empty"
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textSecondary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: I18n.isEs
                                ? "Copia cualquier texto con Ctrl + C y aparecerá aquí automáticamente"
                                : "Copy any text using Ctrl + C and it will appear here automatically"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }
            }

            // -----------------------------------------------------------------
            // 5. FOOTER (Status & Navigation Guide)
            // -----------------------------------------------------------------
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰅍"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.accent
                }

                Text {
                    text: I18n.isEs
                        ? (clipboardWindow.filteredItems.length + " guardados • Clic o ENTER para copiar • ESC para cerrar")
                        : (clipboardWindow.filteredItems.length + " stored • Click or ENTER to copy • ESC to dismiss")
                    font.family: Theme.fontSans
                    font.pixelSize: 10
                    color: Theme.textSecondary
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "cliphist • Wayland Zero Latency"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }
}

