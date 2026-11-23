import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 1080
    height: 680
    color: "#191919"

    property string explorerSection: (typeof initialArg !== "undefined" && initialArg !== "") ? initialArg : "Este equipo"
    property string explorerRealPath: "Este equipo"
    property string explorerMode: "thispc"
    property var explorerItems: []
    property var explorerDrives: []
    property int explorerItemCount: 8
    property string explorerSortBy: "name"
    property var explorerHistory: [root.explorerSection]
    property int explorerHistoryIdx: 0
    property var explorerTabs: [root.explorerSection]
    property int activeTabIndex: 0
    property var sysInfo: ({ "kernel": "7.3.5-cachyos", "sched": "scx_lavd" })

    component WinSvg : Image {
        property string iconFile: "explorer.svg"
        Layout.preferredWidth: width
        Layout.preferredHeight: height
        Layout.maximumWidth: width
        Layout.maximumHeight: height
        source: assetDirUrl + iconFile
        sourceSize.width: 96
        sourceSize.height: 96
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    function refreshExplorer() {
        try {
            explorerDrives = JSON.parse(bridge.getDrivesJson());
            var res = JSON.parse(bridge.listDirectoryJson(explorerSection, explorerSortBy));
            explorerMode = res.mode;
            explorerRealPath = res.path;
            explorerItems = res.items;
            explorerItemCount = res.count;
        } catch (e) {}
    }

    function navigateExplorer(target, pushHistory) {
        explorerSection = target;
        var tabsCopy = explorerTabs.slice();
        tabsCopy[activeTabIndex] = target;
        explorerTabs = tabsCopy;
        if (pushHistory !== false) {
            var h = explorerHistory.slice(0, explorerHistoryIdx + 1);
            h.push(target);
            explorerHistory = h;
            explorerHistoryIdx = h.length - 1;
        }
        refreshExplorer();
    }

    Component.onCompleted: {
        try { sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
        refreshExplorer();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // [A] Tab Strip (#0e0e0e)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: "#0e0e0e"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                Repeater {
                    model: root.explorerTabs
                    delegate: Rectangle {
                        Layout.preferredWidth: Math.min(220, Math.max(130, (root.width - 160) / root.explorerTabs.length))
                        Layout.preferredHeight: 32
                        Layout.alignment: Qt.AlignBottom
                        radius: 7
                        color: index === root.activeTabIndex ? "#202020" : (tabHov.containsMouse ? "#171717" : "#121212")

                        Rectangle {
                            visible: index === root.activeTabIndex
                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                            height: 7; color: "#202020"
                        }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 7
                            WinSvg { width: 15; height: 15; iconFile: modelData === "Este equipo" ? "thispc.svg" : "folder.svg" }
                            Text {
                                text: modelData
                                color: index === root.activeTabIndex ? "#ffffff" : "#b0b0b0"
                                font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Rectangle {
                                width: 18; height: 18; radius: 4
                                color: tabCloseHov.containsMouse ? "#28ffffff" : "transparent"
                                WinSvg { anchors.centerIn: parent; width: 10; height: 10; iconFile: "window-close-symbolic.svg"; opacity: 0.75 }
                                MouseArea {
                                    id: tabCloseHov; anchors.fill: parent; hoverEnabled: true
                                    onClicked: {
                                        if (root.explorerTabs.length > 1) {
                                            var t = root.explorerTabs.slice();
                                            t.splice(index, 1);
                                            root.explorerTabs = t;
                                            root.activeTabIndex = Math.min(root.activeTabIndex, t.length - 1);
                                            root.navigateExplorer(root.explorerTabs[root.activeTabIndex], false);
                                        } else {
                                            bridge.closeWindow();
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: tabHov; anchors.fill: parent; anchors.rightMargin: 24; hoverEnabled: true
                            onClicked: {
                                root.activeTabIndex = index;
                                root.navigateExplorer(root.explorerTabs[index], false);
                            }
                        }
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 5
                    Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 2
                    color: newTabHov.containsMouse ? "#22ffffff" : "transparent"
                    Text { anchors.centerIn: parent; text: "+"; color: "#d0d0d0"; font.pixelSize: 16 }
                    MouseArea {
                        id: newTabHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.explorerTabs.length < 6) {
                                var t = root.explorerTabs.slice();
                                t.push("Este equipo");
                                root.explorerTabs = t;
                                root.activeTabIndex = t.length - 1;
                                root.navigateExplorer("Este equipo", true);
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // [B] Navigation & Breadcrumb Address Row (#202020)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            color: "#202020"

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 6

                Rectangle {
                    width: 30; height: 30; radius: 5; color: backHov.containsMouse ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "pan-start-symbolic.svg"; opacity: root.explorerHistoryIdx > 0 ? 1.0 : 0.35 }
                    MouseArea {
                        id: backHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (root.explorerHistoryIdx > 0) {
                                root.explorerHistoryIdx--;
                                root.navigateExplorer(root.explorerHistory[root.explorerHistoryIdx], false);
                            }
                        }
                    }
                }
                Rectangle {
                    width: 30; height: 30; radius: 5; color: fwdHov.containsMouse ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "pan-end-symbolic.svg"; opacity: root.explorerHistoryIdx < root.explorerHistory.length - 1 ? 1.0 : 0.35 }
                    MouseArea {
                        id: fwdHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: {
                            if (root.explorerHistoryIdx < root.explorerHistory.length - 1) {
                                root.explorerHistoryIdx++;
                                root.navigateExplorer(root.explorerHistory[root.explorerHistoryIdx], false);
                            }
                        }
                    }
                }
                Rectangle {
                    width: 30; height: 30; radius: 5; color: upHov.containsMouse ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 15; height: 15; iconFile: "pan-up-symbolic.svg"; opacity: root.explorerSection !== "Este equipo" ? 1.0 : 0.35 }
                    MouseArea {
                        id: upHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: root.navigateExplorer(bridge.getParentDir(root.explorerRealPath), true)
                    }
                }
                Rectangle {
                    width: 30; height: 30; radius: 5; color: refHov.containsMouse ? "#24ffffff" : "transparent"
                    WinSvg { anchors.centerIn: parent; width: 14; height: 14; iconFile: "view-refresh-symbolic.svg" }
                    MouseArea { id: refHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.refreshExplorer() }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 32; radius: 5
                    color: "#2b2b2b"; border.color: "#1fffffff"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; spacing: 6
                        WinSvg { width: 15; height: 15; iconFile: root.explorerMode === "thispc" ? "thispc.svg" : "folder.svg" }
                        WinSvg { width: 12; height: 12; iconFile: "pan-end-symbolic.svg"; opacity: 0.6 }
                        Text { text: root.explorerRealPath; color: "#ffffff"; font.pixelSize: 12; elide: Text.ElideMiddle; Layout.fillWidth: true }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 240; Layout.preferredHeight: 32; radius: 5
                    color: "#2b2b2b"; border.color: "#1fffffff"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                        Text { text: "Buscar en " + root.explorerSection; color: "#9e9e9e"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
                        WinSvg { width: 14; height: 14; iconFile: "searching-symbolic.svg"; opacity: 0.7 }
                    }
                }
            }
        }

        // [C] Command Bar (#191919)
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 44
            color: "#191919"; border.color: "#18ffffff"; border.width: 1

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14; spacing: 10

                Rectangle {
                    width: 92; height: 32; radius: 5
                    color: newBtnHov.containsMouse ? "#28ffffff" : "transparent"
                    RowLayout {
                        anchors.centerIn: parent; spacing: 6
                        Rectangle {
                            width: 16; height: 16; radius: 8; color: "#0078d4"
                            Text { anchors.centerIn: parent; text: "+"; color: "#ffffff"; font.pixelSize: 12; font.bold: true }
                        }
                        Text { text: "Nuevo"; color: "#ffffff"; font.pixelSize: 12 }
                        WinSvg { width: 10; height: 10; iconFile: "pan-down-symbolic.svg" }
                    }
                    MouseArea {
                        id: newBtnHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            bridge.createNewItem(root.explorerRealPath, "folder");
                            if (root.explorerMode === "thispc") root.navigateExplorer("Escritorio", true);
                            else root.refreshExplorer();
                        }
                    }
                }

                Rectangle { width: 1; height: 22; color: "#22ffffff" }

                Repeater {
                    model: ["edit-cut-symbolic.svg", "edit-copy-symbolic.svg", "edit-paste-symbolic.svg", "document-edit-symbolic.svg", "edit-delete-symbolic.svg"]
                    delegate: Rectangle {
                        width: 34; height: 32; radius: 5
                        color: cmdHov.containsMouse ? "#24ffffff" : "transparent"
                        WinSvg { anchors.centerIn: parent; width: 16; height: 16; iconFile: modelData }
                        MouseArea { id: cmdHov; anchors.fill: parent; hoverEnabled: true }
                    }
                }

                Rectangle { width: 1; height: 22; color: "#22ffffff" }

                Text { text: "⇅  Ordenar"; color: "#e5e5e5"; font.pixelSize: 12 }
                Text { text: "☰  Ver"; color: "#e5e5e5"; font.pixelSize: 12 }
                Item { Layout.fillWidth: true }
            }
        }

        // [D] Split Sidebar & Content
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 0

            Rectangle {
                Layout.preferredWidth: 215; Layout.fillHeight: true; color: "#191919"
                Column {
                    anchors.fill: parent; anchors.margins: 8; spacing: 2
                    Repeater {
                        model: [
                            { icon: "folder-home.svg",      name: "Inicio" },
                            { icon: "folder-desktop.svg",   name: "Escritorio" },
                            { icon: "folder-download.svg",  name: "Descargas" },
                            { icon: "folder-documents.svg", name: "Documentos" },
                            { icon: "folder-images.svg",    name: "Imágenes" },
                            { icon: "folder-music.svg",     name: "Música" },
                            { icon: "folder-videos.svg",    name: "Vídeos" },
                            { icon: "folder.svg",           name: "Proyectos" },
                            { icon: "thispc.svg",           name: "Este equipo" },
                            { icon: "drive-c.svg",          name: "X64 LIOS (C:)" }
                        ]
                        delegate: Rectangle {
                            width: 199; height: 32; radius: 5
                            color: root.explorerSection === modelData.name ? "#2d2d2d" : (navHover.containsMouse ? "#222222" : "transparent")
                            Rectangle {
                                visible: root.explorerSection === modelData.name
                                x: 2; anchors.verticalCenter: parent.verticalCenter
                                width: 3; height: 16; radius: 1.5; color: "#60cdff"
                            }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; spacing: 10
                                WinSvg { width: 18; height: 18; iconFile: modelData.icon }
                                Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            MouseArea {
                                id: navHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.navigateExplorer(modelData.name, true)
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#1fffffff" }

            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true; color: "#191919"

                // VIEW A: ESTE EQUIPO
                Column {
                    anchors.fill: parent; anchors.margins: 22; spacing: 16
                    visible: root.explorerMode === "thispc"

                    RowLayout {
                        width: parent.width
                        WinSvg { width: 12; height: 12; iconFile: "pan-down-symbolic.svg" }
                        Text { text: "Carpetas (6)"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                        Rectangle { Layout.fillWidth: true; height: 1; color: "#1fffffff" }
                    }

                    Grid {
                        columns: root.width < 900 ? 2 : 3
                        rowSpacing: 10; columnSpacing: 14
                        Repeater {
                            model: [
                                { name: "Escritorio", icon: "folder-desktop.svg",   sub: "Carpeta real del sistema" },
                                { name: "Descargas",  icon: "folder-download.svg",  sub: "Carpeta real del sistema" },
                                { name: "Documentos", icon: "folder-documents.svg", sub: "Carpeta real del sistema" },
                                { name: "Imágenes",   icon: "folder-images.svg",    sub: "Carpeta real del sistema" },
                                { name: "Música",     icon: "folder-music.svg",     sub: "Carpeta real del sistema" },
                                { name: "Vídeos",     icon: "folder-videos.svg",    sub: "Carpeta real del sistema" }
                            ]
                            delegate: Rectangle {
                                width: 255; height: 64; radius: 5
                                color: folderHover.containsMouse ? "#282828" : "transparent"
                                border.color: folderHover.containsMouse ? "#28ffffff" : "transparent"
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 12
                                    WinSvg { width: 46; height: 46; iconFile: modelData.icon }
                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 13 }
                                        Text { text: modelData.sub; color: "#999999"; font.pixelSize: 11 }
                                    }
                                }
                                MouseArea {
                                    id: folderHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.navigateExplorer(modelData.name, true)
                                }
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        WinSvg { width: 12; height: 12; iconFile: "pan-down-symbolic.svg" }
                        Text { text: "Dispositivos y unidades (" + root.explorerDrives.length + ")"; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
                        Rectangle { Layout.fillWidth: true; height: 1; color: "#1fffffff" }
                    }

                    Row {
                        spacing: 14
                        Repeater {
                            model: root.explorerDrives
                            delegate: Rectangle {
                                width: 315; height: 76; radius: 5
                                color: driveHover.containsMouse ? "#282828" : "transparent"
                                border.color: driveHover.containsMouse ? "#28ffffff" : "transparent"
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 12
                                    WinSvg { width: 44; height: 44; iconFile: modelData.icon }
                                    Column {
                                        Layout.fillWidth: true; spacing: 5
                                        Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 13 }
                                        Rectangle {
                                            width: 225; height: 12; radius: 2; color: "#333333"; border.color: "#555555"
                                            Rectangle {
                                                x: 1; y: 1; width: (parent.width - 2) * modelData.usedRatio; height: parent.height - 2; radius: 1
                                                color: modelData.isCritical ? "#d13438" : "#26a0da"
                                            }
                                        }
                                        Text { text: modelData.info; color: "#9e9e9e"; font.pixelSize: 11 }
                                    }
                                }
                                MouseArea {
                                    id: driveHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.navigateExplorer(modelData.path, true)
                                }
                            }
                        }
                    }
                }

                // VIEW B: REAL DIRECTORY BROWSER
                Flickable {
                    anchors.fill: parent; anchors.margins: 18
                    visible: root.explorerMode === "dir"
                    contentWidth: width; contentHeight: realDirGrid.implicitHeight + 20; clip: true

                    Grid {
                        id: realDirGrid; width: parent.width
                        columns: root.width < 900 ? 2 : 3
                        rowSpacing: 8; columnSpacing: 12
                        Repeater {
                            model: root.explorerItems
                            delegate: Rectangle {
                                width: root.width < 900 ? ((realDirGrid.width - 12) / 2) : ((realDirGrid.width - 24) / 3)
                                height: 56; radius: 5
                                color: itemHov.containsMouse ? "#282828" : "#1f1f1f"
                                border.color: itemHov.containsMouse ? "#33ffffff" : "#14ffffff"
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                                    WinSvg { width: 34; height: 34; iconFile: modelData.icon }
                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { width: parent.width; text: modelData.name; color: "#ffffff"; font.pixelSize: 12; elide: Text.ElideRight }
                                        Text { text: modelData.sub + " • " + modelData.mtime; color: "#8e8e8e"; font.pixelSize: 10; elide: Text.ElideRight }
                                    }
                                }
                                MouseArea {
                                    id: itemHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.isDir) root.navigateExplorer(modelData.path, true);
                                        else bridge.openFileOrUrl(modelData.path);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // [E] Status Footer
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 26
            color: "#191919"; border.color: "#16ffffff"; border.width: 1
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 14
                Text { text: root.explorerItemCount + " elementos   |   " + root.explorerRealPath + "   |   Kernel " + root.sysInfo.kernel + " (" + root.sysInfo.sched + ")"; color: "#9e9e9e"; font.pixelSize: 11 }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
