import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: calWindow

    signal closeRequested()

    anchors {
        top: true
    }

    margins {
        top: 36
    }

    implicitWidth: 350
    implicitHeight: cardLayout.implicitHeight + 32

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popup"

    HyprlandFocusGrab {
        active: calWindow.visible
        windows: [calWindow]
        onCleared: calWindow.closeAnimated()
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
            from: 0.82
            to: 1.0
            duration: 270
            easing.type: Easing.OutBack
            easing.overshoot: 1.4
        }
        NumberAnimation {
            target: card
            property: "y"
            from: -20
            to: 0
            duration: 270
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
        NumberAnimation {
            target: card
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim
        running: false
        NumberAnimation {
            target: card
            property: "scale"
            to: 0.86
            duration: 150
            easing.type: Easing.InBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: card
            property: "y"
            to: -16
            duration: 150
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: card
            property: "opacity"
            to: 0.0
            duration: 130
            easing.type: Easing.InQuad
        }
        onFinished: calWindow.closeRequested()
    }

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

    onVisibleChanged: {
        if (visible) {
            calWindow.updateCalendar();
            card.scale = 0.82;
            card.y = -20;
            card.opacity = 0.0;
            openAnim.restart();
        } else {
            card.scale = 1.0;
            card.y = 0;
            card.opacity = 1.0;
        }
    }

    // Centered Obsidian & Crimson Calendar Card with Jelly / Elastic Physics
    Rectangle {
        id: card
        anchors.fill: parent
        transformOrigin: Item.Top
        scale: 1.0
        opacity: 1.0
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            readonly property int dayOfYear: {
                var start = new Date(calWindow.today.getFullYear(), 0, 0);
                var diff = calWindow.today - start;
                return Math.floor(diff / (1000 * 60 * 60 * 24));
            }
            readonly property int isoWeek: Math.max(1, Math.ceil(dayOfYear / 7.0))
            readonly property real yearProgressVal: Math.min(1.0, dayOfYear / 365.0)

            // =========================================================
            // HERO: DIGITAL CLOCK, FULL DATE & ISO WEEK / DAY BADGES
            // =========================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    spacing: 2

                    RowLayout {
                        spacing: 2
                        Text {
                            id: heroHm
                            font.family: Theme.fontMono
                            font.pixelSize: 28
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Text {
                            id: heroSec
                            font.family: Theme.fontMono
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.accent
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 4
                        }

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
                                heroHm.text = h + ":" + m;
                                heroSec.text = ":" + s;
                                calWindow.today = now;
                            }
                        }
                    }

                    Text {
                        id: heroDate
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.textSecondary

                        Component.onCompleted: {
                            var now = new Date();
                            var dName = I18n.dayFullNames[now.getDay()];
                            var mName = I18n.monthFullNames[now.getMonth()];
                            if (I18n.isEs) {
                                heroDate.text = dName + ", " + now.getDate() + " de " + mName + " de " + now.getFullYear();
                            } else {
                                heroDate.text = dName + ", " + mName + " " + now.getDate() + ", " + now.getFullYear();
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop

                    Rectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: 20
                        implicitWidth: wkTxt.implicitWidth + 14
                        radius: 6
                        color: Theme.bgCard
                        border.color: Theme.borderSubtle
                        border.width: 1
                        Text {
                            id: wkTxt
                            anchors.centerIn: parent
                            text: (I18n.isEs ? "Sem " : "Wk ") + cardLayout.isoWeek
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textSecondary
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: 20
                        implicitWidth: doyTxt.implicitWidth + 14
                        radius: 6
                        color: Theme.bgCard
                        border.color: Theme.borderSubtle
                        border.width: 1
                        Text {
                            id: doyTxt
                            anchors.centerIn: parent
                            text: (I18n.isEs ? "Día " : "Day ") + cardLayout.dayOfYear + "/365"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }
                }
            }

            // =========================================================
            // 12-MONTH SEGMENTED YEAR PROGRESS CARD
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: (I18n.isEs ? "PROGRESO ANUAL " : "YEAR PROGRESS ") + calWindow.today.getFullYear()
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(cardLayout.yearProgressVal * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Repeater {
                            model: 12
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 5
                                radius: 2.5
                                color: index === calWindow.currentMonth ? Theme.accent : (index < calWindow.currentMonth ? "#70ffffff" : Theme.bgElevated)
                            }
                        }
                    }
                }
            }

            // =========================================================
            // CALENDAR CARD: NAVIGATION + 42-DAY GRID
            // =========================================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: calGridCol.implicitHeight + 22
                radius: Theme.radiusMd
                color: Theme.bgCard
                border.color: Theme.borderSubtle
                border.width: 1

                ColumnLayout {
                    id: calGridCol
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            id: monthYearLabel
                            font.family: Theme.fontSans
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.textPrimary
                            text: I18n.monthFullNames[calWindow.viewMonth] + " " + calWindow.viewYear
                        }

                        Item { Layout.fillWidth: true }

                        // "Today" Reset Pill (Visible only if viewing another month)
                        Rectangle {
                            visible: (calWindow.viewMonth !== calWindow.currentMonth || calWindow.viewYear !== calWindow.currentYear)
                            implicitWidth: 38
                            implicitHeight: 22
                            radius: 6
                            color: todayResetArea.containsMouse ? Theme.accent : Theme.bgElevated
                            border.color: Theme.borderAccent
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: I18n.calTodayPill
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

                        // Prev Month Button
                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 22
                            radius: 6
                            color: prevArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "❮"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: prevArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
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

                        // Next Month Button
                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 22
                            radius: 6
                            color: nextArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                            border.color: Theme.borderSubtle
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "❯"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: nextArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
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

                    // Weekday Headers (Clean Monochromatic)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: I18n.isEs ? ["LU", "MA", "MI", "JU", "VI", "SÁ", "DO"] : ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

                            Text {
                                required property string modelData
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textMuted
                            }
                        }
                    }

                    // 42-Day Calendar Grid with Radial Glow on Today
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
                                radius: 8

                                readonly property bool isCurrent: modelData.isCurrentMonth
                                readonly property bool isToday: modelData.isToday

                                // Outer glow halo for today's date
                                Rectangle {
                                    visible: dayCell.isToday
                                    anchors.fill: parent
                                    anchors.margins: -2
                                    radius: 10
                                    color: "#2dff2b2b"
                                }

                                color: isToday ? Theme.accent : (dayArea.containsMouse && isCurrent ? Theme.bgHover : "transparent")
                                border.color: isToday ? "#99ff7a7a" : (dayArea.containsMouse && isCurrent ? Theme.borderSubtle : "transparent")
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: String(dayCell.modelData.day)
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: dayCell.isToday
                                    color: dayCell.isToday ? "#ffffff" : (dayCell.isCurrent ? Theme.textPrimary : Theme.textMuted)
                                    opacity: dayCell.isToday ? 1.0 : (dayCell.isCurrent ? 0.92 : 0.28)
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
                }
            }

            // =========================================================
            // SYSTEM TELEMETRY FOOTER: UPTIME & TIMEZONE
            // =========================================================
            RowLayout {
                Layout.fillWidth: true

                RowLayout {
                    spacing: 5
                    Text {
                        text: "󰔛"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                    Text {
                        id: uptimeLabel
                        text: "Uptime: ..."
                        font.family: Theme.fontMono
                        font.pixelSize: 9
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

                Text {
                    id: tzLabel
                    font.family: Theme.fontMono
                    font.pixelSize: 9
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
