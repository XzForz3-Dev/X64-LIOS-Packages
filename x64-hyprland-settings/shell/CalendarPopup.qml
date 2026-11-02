import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: calWindow

    signal closeRequested()

    anchors {
        top: true
    }

    margins {
        top: 32
    }

    implicitWidth: 350
    implicitHeight: cardLayout.implicitHeight + 32
    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    // State for viewing month/year
    property date today: new Date()
    property int currentYear: today.getFullYear()
    property int currentMonth: today.getMonth() // 0-indexed
    property int viewYear: currentYear
    property int viewMonth: currentMonth

    // Calendar generation model
    property var daysModel: []

    function updateCalendar() {
        var days = [];
        var totalCells = 42;

        var daysInViewMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
        var firstDayRaw = new Date(viewYear, viewMonth, 1).getDay();
        var firstDayMonday = (firstDayRaw === 0) ? 6 : firstDayRaw - 1;
        var daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate();

        // 1. Previous month overflow
        for (var p = firstDayMonday - 1; p >= 0; p--) {
            days.push({
                day: daysInPrevMonth - p,
                isCurrentMonth: false,
                isToday: false
            });
        }

        // 2. Current month days
        var nowD = today.getDate();
        var nowM = today.getMonth();
        var nowY = today.getFullYear();

        for (var d = 1; d <= daysInViewMonth; d++) {
            var isToday = (d === nowD && viewMonth === nowM && viewYear === nowY);
            days.push({
                day: d,
                isCurrentMonth: true,
                isToday: isToday
            });
        }

        // 3. Next month overflow to complete 42 cells
        var nextDay = 1;
        while (days.length < totalCells) {
            days.push({
                day: nextDay++,
                isCurrentMonth: false,
                isToday: false
            });
        }

        calWindow.daysModel = days;
    }

    Component.onCompleted: updateCalendar()
    onViewMonthChanged: updateCalendar()
    onViewYearChanged: updateCalendar()

    // Centered Cyberpunk Calendar Card
    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        // Top Neon Glow Bar
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: 20
                rightMargin: 20
            }
            height: 2
            radius: 1
            color: Theme.accent
        }

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // =========================================================
            // HERO: DIGITAL CLOCK & FULL DATE
            // =========================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 2

                Text {
                    id: heroClock
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 26
                    font.bold: true
                    color: Theme.textPrimary

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            var now = new Date();
                            var h = String(now.getHours()).padStart(2, "0");
                            var m = String(now.getMinutes()).padStart(2, "0");
                            var s = String(now.getSeconds()).padStart(2, "0");
                            heroClock.text = h + ":" + m + ":" + s;
                            calWindow.today = now;
                        }
                    }
                }

                Text {
                    id: heroDate
                    Layout.alignment: Qt.AlignHCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: Theme.textSecondary

                    Component.onCompleted: {
                        var now = new Date();
                        var days = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"];
                        var months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
                        heroDate.text = days[now.getDay()] + ", " + now.getDate() + " de " + months[now.getMonth()] + " de " + now.getFullYear();
                    }
                }

                // Year Progress Micro-Indicator
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 4
                    spacing: 8

                    readonly property int dayOfYear: {
                        var start = new Date(calWindow.today.getFullYear(), 0, 0);
                        var diff = calWindow.today - start;
                        var oneDay = 1000 * 60 * 60 * 24;
                        return Math.floor(diff / oneDay);
                    }
                    readonly property real yearProgressVal: Math.min(1.0, dayOfYear / 365.0)

                    Text {
                        text: "Progreso " + calWindow.today.getFullYear() + ":"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }

                    // Progress bar track
                    Rectangle {
                        implicitWidth: 100
                        implicitHeight: 4
                        radius: 2
                        color: "#22ffffff"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * parent.parent.yearProgressVal
                            radius: 2
                            color: Theme.accent
                        }
                    }

                    Text {
                        text: Math.round(parent.yearProgressVal * 100) + "%"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accent
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            // =========================================================
            // CALENDAR MONTH NAVIGATION
            // =========================================================
            RowLayout {
                Layout.fillWidth: true

                // Prev Month Button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 24
                    radius: Theme.radiusSm
                    color: prevArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: prevArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "❮"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.textPrimary
                    }

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (calWindow.viewMonth === 0) {
                                calWindow.viewMonth = 11;
                                calWindow.viewYear--;
                            } else {
                                calWindow.viewMonth--;
                            }
                        }
                    }
                }

                // Month / Year Label
                Text {
                    id: monthYearLabel
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.textPrimary

                    property var monthNames: [
                        "ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO",
                        "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"
                    ]

                    text: monthNames[calWindow.viewMonth] + " " + calWindow.viewYear
                }

                // "Today" Reset Pill (Visible only if viewing another month)
                Rectangle {
                    visible: (calWindow.viewMonth !== calWindow.currentMonth || calWindow.viewYear !== calWindow.currentYear)
                    implicitWidth: 42
                    implicitHeight: 24
                    radius: Theme.radiusSm
                    color: todayResetArea.containsMouse ? Theme.accent : Theme.bgCard
                    border.color: Theme.borderAccent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "HOY"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: todayResetArea.containsMouse ? "#ffffff" : Theme.accent
                    }

                    MouseArea {
                        id: todayResetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            calWindow.viewYear = calWindow.currentYear;
                            calWindow.viewMonth = calWindow.currentMonth;
                        }
                    }
                }

                // Next Month Button
                Rectangle {
                    implicitWidth: 26
                    implicitHeight: 24
                    radius: Theme.radiusSm
                    color: nextArea.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: nextArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "❯"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.textPrimary
                    }

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (calWindow.viewMonth === 11) {
                                calWindow.viewMonth = 0;
                                calWindow.viewYear++;
                            } else {
                                calWindow.viewMonth++;
                            }
                        }
                    }
                }
            }

            // =========================================================
            // CALENDAR GRID: WEEKDAY HEADERS
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: ["LU", "MA", "MI", "JU", "VI", "SÁ", "DO"]

                    Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: (modelData === "SÁ" || modelData === "DO") ? Theme.accentLight : Theme.textMuted
                    }
                }
            }

            // =========================================================
            // CALENDAR GRID: 42 DAYS REPEATER
            // =========================================================
            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: calWindow.daysModel

                    Rectangle {
                        id: dayCell
                        required property var modelData

                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: Theme.radiusSm

                        readonly property bool isCurrent: modelData.isCurrentMonth
                        readonly property bool isToday: modelData.isToday

                        color: isToday ? Theme.accent : (dayArea.containsMouse && isCurrent ? Theme.bgHover : "transparent")
                        border.color: isToday ? Theme.accentLight : (dayArea.containsMouse && isCurrent ? Theme.borderSubtle : "transparent")
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: String(dayCell.modelData.day)
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: dayCell.isToday
                            color: dayCell.isToday ? "#ffffff" : (dayCell.isCurrent ? Theme.textPrimary : Theme.textMuted)
                            opacity: dayCell.isToday ? 1.0 : (dayCell.isCurrent ? 0.95 : 0.35)
                        }

                        MouseArea {
                            id: dayArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: dayCell.isCurrent ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderSubtle
            }

            // =========================================================
            // SYSTEM TELEMETRY FOOTER: UPTIME & TIMEZONE
            // =========================================================
            RowLayout {
                Layout.fillWidth: true

                // Uptime
                RowLayout {
                    spacing: 4

                    Text {
                        text: "󰔛"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: Theme.accent
                    }

                    Text {
                        id: uptimeLabel
                        text: "Uptime: ..."
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textSecondary

                        Process {
                            id: uptimeProc
                            command: ["bash", "-c", "uptime -p | sed 's/up //;s/ hours*/h/;s/ minutes*/m/'"]
                            stdout: StdioCollector {
                                id: uptimeCollector
                                waitForEnd: true
                                onStreamFinished: {
                                    if (uptimeCollector.text) {
                                        uptimeLabel.text = "Uptime: " + uptimeCollector.text.trim();
                                    }
                                }
                            }
                        }

                        Component.onCompleted: uptimeProc.running = true
                    }
                }

                Item { Layout.fillWidth: true }

                // Timezone
                Text {
                    id: tzLabel
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.textMuted

                    Component.onCompleted: {
                        try {
                            tzLabel.text = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
                        } catch (e) {
                            tzLabel.text = "UTC";
                        }
                    }
                }
            }
        }
    }
}
