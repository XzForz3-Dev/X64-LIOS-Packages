import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 780
    height: 560
    color: "#1c1c1c"

    property var sysInfo: ({ "cpuPct": 6, "ram": "11.0 / 64.0 GB", "sched": "scx_lavd", "kernel": "7.3.5-cachyos", "procs": [] })

    component WinSvg : Image {
        property string iconFile: "thispc.svg"
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

    function refreshTelemetry() {
        try { sysInfo = JSON.parse(bridge.getSystemTelemetryJson()); } catch (e) {}
    }

    Component.onCompleted: refreshTelemetry()

    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: root.refreshTelemetry()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Live Telemetry Summary Strip
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 82; color: "#252525"; border.color: "#1fffffff"
            RowLayout {
                anchors.fill: parent; anchors.margins: 14; spacing: 16
                Rectangle {
                    Layout.fillWidth: true; height: 54; radius: 6; color: "#1d1d1d"; border.color: "#26a0da"
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "CPU (" + root.sysInfo.cpuPct + "%)"; color: "#60cdff"; font.pixelSize: 14; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.sysInfo.sched; color: "#aaaaaa"; font.pixelSize: 11 }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 54; radius: 6; color: "#1d1d1d"; border.color: "#8b5cf6"
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Memoria RAM"; color: "#c4b5fd"; font.pixelSize: 14; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.sysInfo.ram; color: "#aaaaaa"; font.pixelSize: 11 }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; height: 54; radius: 6; color: "#1d1d1d"; border.color: "#10b981"
                    Column {
                        anchors.centerIn: parent
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Disco NVMe (ADIOS)"; color: "#6ee7b7"; font.pixelSize: 14; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Activo • Btrfs ZSTD"; color: "#aaaaaa"; font.pixelSize: 11 }
                    }
                }
            }
        }

        // Table Header
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 34; color: "#202020"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                Text { text: "Nombre del proceso"; color: "#aaaaaa"; font.pixelSize: 11; font.bold: true; Layout.fillWidth: true }
                Text { text: "PID"; color: "#aaaaaa"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 80 }
                Text { text: "CPU"; color: "#60cdff"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 80 }
                Text { text: "Memoria"; color: "#aaaaaa"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 100 }
            }
        }

        // Live Processes Rows
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: width; contentHeight: procCol.implicitHeight; clip: true
            Column {
                id: procCol; width: parent.width; spacing: 1
                Repeater {
                    model: root.sysInfo.procs || []
                    delegate: Rectangle {
                        width: procCol.width; height: 34; color: index % 2 === 0 ? "#191919" : "#1e1e1e"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                            WinSvg { width: 16; height: 16; iconFile: "terminal.svg" }
                            Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 12; Layout.fillWidth: true }
                            Text { text: modelData.pid; color: "#888888"; font.pixelSize: 11; Layout.preferredWidth: 80 }
                            Text { text: modelData.cpu; color: "#60cdff"; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 80 }
                            Text { text: modelData.mem; color: "#cccccc"; font.pixelSize: 11; Layout.preferredWidth: 100 }
                        }
                    }
                }
            }
        }
    }
}
