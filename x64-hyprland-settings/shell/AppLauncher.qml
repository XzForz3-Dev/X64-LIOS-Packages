import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: launcherWindow

    signal closeRequested()

    property var appList: []

    function updateAppList() {
        if (!DesktopEntries.applications || !DesktopEntries.applications.values) return;

        var query = searchInput.text.trim().toLowerCase();
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
                nameLow === "vim" ||
                nameLow === "micro") {
                continue;
            }

            if (query === "" || 
                nameLow.indexOf(query) !== -1 || 
                comment.toLowerCase().indexOf(query) !== -1 ||
                execLow.indexOf(query) !== -1) {
                
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

                list.push({
                    "name": name,
                    "comment": comment,
                    "icon": iconPath,
                    "appRef": app
                });
            }
        }

        list.sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });

        launcherWindow.appList = list;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "#bb050508"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Dismiss on background click
    MouseArea {
        anchors.fill: parent
        onClicked: launcherWindow.closeRequested()
    }

    // Centered Obsidian & Crimson 2026 Dashboard Card
    Rectangle {
        id: card
        width: Math.min(parent.width - 40, 780)
        height: Math.min(parent.height - 80, 560)
        anchors.centerIn: parent
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        // Consume clicks inside the card
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Header & Search Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: Theme.radiusMd
                    color: Theme.bgCard
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.borderSubtle
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "󰍉"
                            font.family: Theme.fontMono
                            font.pixelSize: 18
                            color: searchInput.activeFocus ? Theme.accent : Theme.textMuted
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            color: Theme.textPrimary
                            clip: true
                            selectByMouse: true
                            onTextChanged: launcherWindow.updateAppList()

                            Text {
                                anchors.fill: parent
                                text: "Buscar aplicaciones, herramientas o ajustes de X64 LIOS..."
                                font.family: Theme.fontSans
                                font.pixelSize: 14
                                color: Theme.textMuted
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            Keys.onEscapePressed: launcherWindow.closeRequested()
                            Keys.onReturnPressed: {
                                if (launcherWindow.appList.length > 0) {
                                    var firstApp = launcherWindow.appList[0].appRef;
                                    if (firstApp) {
                                        firstApp.execute();
                                        launcherWindow.closeRequested();
                                    }
                                }
                            }
                        }

                        // Clear button
                        Text {
                            text: "󰅖"
                            font.family: Theme.fontMono
                            font.pixelSize: 15
                            color: Theme.textMuted
                            visible: searchInput.text.length > 0
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
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

            // GridView of Applications
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: grid.width / 2
                    cellHeight: 68
                    model: launcherWindow.appList

                    delegate: Rectangle {
                        id: appItem
                        required property var modelData
                        width: grid.cellWidth - 8
                        height: 60
                        radius: Theme.radiusMd
                        color: itemArea.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: itemArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Image {
                                source: appItem.modelData.icon || ""
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                sourceSize.width: 36
                                sourceSize.height: 36
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: appItem.modelData.name || ""
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: itemArea.containsMouse ? Theme.textPrimary : Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: appItem.modelData.comment || "Aplicación de sistema"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
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

            // Footer
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                color: "transparent"

                RowLayout {
                    anchors.fill: parent

                    Text {
                        text: launcherWindow.appList.length + " aplicaciones disponibles"
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 16

                        Text {
                            text: "<font color='#ff2b2b'>ESC</font> Cerrar"
                            textFormat: Text.RichText
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }

                        Text {
                            text: "<font color='#ff2b2b'>ENTER</font> Ejecutar"
                            textFormat: Text.RichText
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.textMuted
                        }
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            launcherWindow.updateAppList();
            searchInput.forceActiveFocus();
        }
    }

    Component.onCompleted: launcherWindow.updateAppList()
}
