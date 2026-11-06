import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: launcherWindow

    signal closeRequested()

    property var fullAppList: []
    property var filteredAppList: []
    property string activeCategory: "Todas"
    property int selectedIndex: 0

    // High-precision XDG Categorization
    function detectCategory(app) {
        var rawCats = "";
        if (app.categories) {
            if (Array.isArray(app.categories)) {
                rawCats = app.categories.join(" ").toLowerCase();
            } else {
                rawCats = String(app.categories).toLowerCase();
            }
        }
        var exec = (app.execString || "").toLowerCase();
        var name = (app.name || "").toLowerCase();

        // 1. Strict XDG Categories
        if (rawCats.indexOf("game") !== -1 || exec.indexOf("steam") !== -1 || exec.indexOf("heroic") !== -1) {
            return "Juegos";
        }
        if (rawCats.indexOf("webbrowser") !== -1 || (rawCats.indexOf("network") !== -1 && rawCats.indexOf("settings") === -1) || exec.indexOf("chromium") !== -1 || exec.indexOf("firefox") !== -1) {
            return "Internet";
        }
        if (rawCats.indexOf("development") !== -1 || rawCats.indexOf("ide") !== -1 || exec.indexOf("opencode") !== -1 || exec.indexOf("meld") !== -1 || exec.indexOf("kitty") !== -1 || rawCats.indexOf("terminalemulator") !== -1) {
            return "Desarrollo";
        }
        if (rawCats.indexOf("audiovideo") !== -1 || rawCats.indexOf("audio") !== -1 || rawCats.indexOf("video") !== -1 || rawCats.indexOf("player") !== -1 || rawCats.indexOf("mixer") !== -1) {
            return "Multimedia";
        }
        if (rawCats.indexOf("system") !== -1 || rawCats.indexOf("settings") !== -1 || rawCats.indexOf("monitor") !== -1 || rawCats.indexOf("security") !== -1 || exec.indexOf("btop") !== -1 || exec.indexOf("dolphin") !== -1 || exec.indexOf("btrfs") !== -1) {
            return "Sistema";
        }

        // 2. Identity fallbacks
        if (name.indexOf("steam") !== -1 || name.indexOf("heroic") !== -1) return "Juegos";
        if (name.indexOf("chromium") !== -1) return "Internet";
        if (name.indexOf("kitty") !== -1 || name.indexOf("opencode") !== -1) return "Desarrollo";
        if (name.indexOf("dolphin") !== -1 || name.indexOf("btop") !== -1 || name.indexOf("secure boot") !== -1) return "Sistema";

        return "Utilidades";
    }

    function updateAppList() {
        if (!DesktopEntries.applications || !DesktopEntries.applications.values) return;

        var apps = DesktopEntries.applications.values;
        var list = [];

        for (var i = 0; i < apps.length; i++) {
            var app = apps[i];
            if (!app || app.noDisplay) continue;

            var name = app.name || "";
            var comment = app.comment || app.genericName || "";
            var exec = app.execString || "";
            var execLow = exec.toLowerCase();
            var nameLow = name.toLowerCase();

            // Filter out low-level hardware debuggers, CLI-only wrappers, and dev clutter
            if (execLow.indexOf("qv4l2") !== -1 ||
                execLow.indexOf("qvidcap") !== -1 ||
                execLow.indexOf("lstopo") !== -1 ||
                execLow.indexOf("cmake-gui") !== -1 ||
                execLow.indexOf("localhost:631") !== -1 ||
                execLow.indexOf("avahi-discover") !== -1 ||
                execLow.indexOf("bssh") !== -1 ||
                execLow.indexOf("bvnc") !== -1 ||
                execLow.indexOf("blueman-adapters") !== -1 ||
                execLow.indexOf("cups") !== -1 ||
                nameLow === "vim" ||
                nameLow === "micro") {
                continue;
            }

            var iconName = app.icon || "";
            var iconPath = "";
            if (iconName === "preferences-system-network") {
                iconPath = "file:///usr/share/icons/Papirus/48x48/apps/preferences-system-network-connection.svg";
            } else if (iconName === "audio-speakers") {
                iconPath = "file:///usr/share/icons/Papirus/48x48/apps/org.pipewire.Helvum.svg";
            } else if (iconName === "dev.lizardbyte.app.Sunshine") {
                iconPath = "file:///usr/share/pixmaps/x64-sunshine.svg";
            } else if (iconName.length > 0 && iconName.charAt(0) === "/") {
                iconPath = "file://" + iconName;
            } else {
                iconPath = Quickshell.iconPath(iconName, true);
                if (!iconPath || iconPath.length === 0) iconPath = Quickshell.iconPath("application-x-executable", true);
                if (iconPath && iconPath.length > 0 && iconPath.charAt(0) === "/") {
                    iconPath = "file://" + iconPath;
                }
            }

            var category = detectCategory(app);

            list.push({
                "name": name,
                "comment": comment,
                "category": category,
                "icon": iconPath,
                "appRef": app
            });
        }

        list.sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });

        launcherWindow.fullAppList = list;
        applyFilter();
    }

    function applyFilter() {
        var query = searchInput.text.trim().toLowerCase();
        var cat = launcherWindow.activeCategory;
        var res = [];

        for (var i = 0; i < launcherWindow.fullAppList.length; i++) {
            var item = launcherWindow.fullAppList[i];
            var matchesCat = (cat === "Todas" || item.category === cat);
            var matchesQuery = (query === "" ||
                item.name.toLowerCase().indexOf(query) !== -1 ||
                item.comment.toLowerCase().indexOf(query) !== -1 ||
                item.category.toLowerCase().indexOf(query) !== -1);

            if (matchesCat && matchesQuery) {
                res.push(item);
            }
        }

        launcherWindow.filteredAppList = res;
        launcherWindow.selectedIndex = 0;
    }

    function countForCategory(catName) {
        if (catName === "Todas") return launcherWindow.fullAppList.length;
        var count = 0;
        for (var i = 0; i < launcherWindow.fullAppList.length; i++) {
            if (launcherWindow.fullAppList[i].category === catName) count++;
        }
        return count;
    }

    function executeSelected() {
        if (launcherWindow.filteredAppList.length > launcherWindow.selectedIndex && launcherWindow.selectedIndex >= 0) {
            var selectedApp = launcherWindow.filteredAppList[launcherWindow.selectedIndex].appRef;
            if (selectedApp) {
                selectedApp.execute();
                launcherWindow.closeRequested();
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

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Dismiss on background click
    MouseArea {
        anchors.fill: parent
        onClicked: launcherWindow.closeRequested()
    }

    // Outer Ambient Shadow for floating depth
    Rectangle {
        anchors.centerIn: card
        width: card.width + 16
        height: card.height + 16
        radius: card.radius + 6
        color: "#70000000"
        z: -1
    }

    // =========================================================================
    // CENTERED OBSIDIAN GLASS DASHBOARD (X64 FLUID GRID 2026)
    // =========================================================================
    Rectangle {
        id: card
        width: Math.min(parent.width - 40, 960)
        height: Math.min(parent.height - 60, 640)
        anchors.centerIn: parent
        radius: 20
        color: "#0f1118"
        border.color: "#222636"
        border.width: 1

        // Subtle Top Satin Glass Highlight
        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 40
            height: 1
            color: "#30ffffff"
        }

        // Consume clicks inside the card
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // =================================================================
            // TOP FLOATING SEARCH CAPSULE (48px)
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 24
                color: "#161924"
                border.color: searchInput.activeFocus ? "#ff2b2b" : "#262a3a"
                border.width: searchInput.activeFocus ? 1.5 : 1

                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: searchInput.activeFocus ? "#ff2b2b" : "#707688"
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        color: "#ffffff"
                        clip: true
                        selectByMouse: true
                        onTextChanged: launcherWindow.applyFilter()

                        Text {
                            anchors.fill: parent
                            text: "Buscar aplicaciones, juegos o herramientas..."
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            color: "#6c7285"
                            visible: !searchInput.text
                        }

                        Keys.onEscapePressed: launcherWindow.closeRequested()
                        Keys.onReturnPressed: launcherWindow.executeSelected()

                        Keys.onDownPressed: {
                            if (launcherWindow.selectedIndex + 5 < launcherWindow.filteredAppList.length) {
                                launcherWindow.selectedIndex += 5;
                            }
                        }

                        Keys.onUpPressed: {
                            if (launcherWindow.selectedIndex - 5 >= 0) {
                                launcherWindow.selectedIndex -= 5;
                            }
                        }

                        Keys.onRightPressed: {
                            if (launcherWindow.selectedIndex + 1 < launcherWindow.filteredAppList.length) {
                                launcherWindow.selectedIndex += 1;
                            }
                        }

                        Keys.onLeftPressed: {
                            if (launcherWindow.selectedIndex - 1 >= 0) {
                                launcherWindow.selectedIndex -= 1;
                            }
                        }

                        Keys.onTabPressed: {
                            var cats = ["Todas", "Juegos", "Internet", "Desarrollo", "Multimedia", "Sistema"];
                            var curIdx = cats.indexOf(launcherWindow.activeCategory);
                            var nextIdx = (curIdx + 1) % cats.length;
                            launcherWindow.activeCategory = cats[nextIdx];
                            launcherWindow.applyFilter();
                        }
                    }

                    // Clear Search Button
                    Text {
                        text: "󰅖"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: "#8c92a4"
                        visible: searchInput.text.length > 0
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }
                    }

                    // ESC Quick Badge
                    Rectangle {
                        width: 44
                        height: 22
                        radius: 11
                        color: "#20ffffff"
                        Text {
                            anchors.centerIn: parent
                            text: "ESC"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                            font.bold: true
                            color: "#b0b5c5"
                        }
                    }
                }
            }

            // =================================================================
            // CATEGORY FILTER PILLS
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: ["Todas", "Juegos", "Internet", "Desarrollo", "Multimedia", "Sistema", "Utilidades"]

                    Rectangle {
                        id: pill
                        property bool isActive: launcherWindow.activeCategory === modelData
                        property int appCount: launcherWindow.countForCategory(modelData)

                        visible: appCount > 0
                        implicitHeight: 28
                        implicitWidth: pillText.implicitWidth + 22
                        radius: 14
                        color: isActive ? "#ff2b2b" : (pillArea.containsMouse ? "#1c202d" : "#141722")
                        border.color: isActive ? "#ff4d4d" : (pillArea.containsMouse ? "#303648" : "#222636")
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Text {
                            id: pillText
                            anchors.centerIn: parent
                            text: modelData + " (" + pill.appCount + ")"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            font.bold: pill.isActive
                            color: pill.isActive ? "#ffffff" : "#8c92a4"
                        }

                        MouseArea {
                            id: pillArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                launcherWindow.activeCategory = modelData;
                                launcherWindow.applyFilter();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // =================================================================
            // CORE 5-COLUMN APP GRID (OFFICIAL SYSTEM GRAPHIC ICONS)
            // =================================================================
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: grid.width / 5
                    cellHeight: 116
                    model: launcherWindow.filteredAppList

                    delegate: Item {
                        id: appItem
                        required property var modelData
                        required property int index

                        width: grid.cellWidth
                        height: grid.cellHeight

                        property bool isSelected: (index === launcherWindow.selectedIndex) || itemArea.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: 14
                            color: appItem.isSelected ? "#1e2230" : "#131620"
                            border.color: appItem.isSelected ? "#ff2b2b" : "#1e2232"
                            border.width: appItem.isSelected ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            // Subtle Crimson Halo on Hover / Focus
                            Rectangle {
                                visible: appItem.isSelected
                                anchors.fill: parent
                                radius: 14
                                color: "#1aff2b2b"
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                width: parent.width - 14

                                Image {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: appItem.modelData.icon || ""
                                    Layout.preferredWidth: 44
                                    Layout.preferredHeight: 44
                                    sourceSize.width: 44
                                    sourceSize.height: 44
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: appItem.modelData.name || ""
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: appItem.modelData.category || "Sistema"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 9
                                    color: appItem.isSelected ? "#ff6060" : "#757c90"
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: itemArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (appItem.modelData.appRef) {
                                        appItem.modelData.appRef.execute();
                                        launcherWindow.closeRequested();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // MINIMAL FOOTER STATUS BAR
            // =================================================================
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#1c202c"
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: launcherWindow.filteredAppList.length + " de " + launcherWindow.fullAppList.length + " aplicaciones disponibles  •  ENTER Ejecutar  •  TAB Categorías  •  ESC Cerrar"
                    font.family: Theme.fontSans
                    font.pixelSize: 10
                    color: "#6c7285"
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "X64 LIOS • Obsidian & Crimson 2026"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: "#4a5065"
                }
            }
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            launcherWindow.updateAppList();
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            launcherWindow.activeCategory = "Todas";
            launcherWindow.updateAppList();
            searchInput.forceActiveFocus();
        }
    }

    Component.onCompleted: launcherWindow.updateAppList()
}
