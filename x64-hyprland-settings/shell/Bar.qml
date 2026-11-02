import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

PanelWindow {
    id: barWindow

    signal toggleLauncher()
    signal toggleControl()
    signal togglePower()

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 6
        left: 12
        right: 12
    }

    implicitHeight: 44
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 50

    // Main Floating Glass Pill
    Rectangle {
        id: barBackground
        anchors.fill: parent
        radius: Theme.radiusMd
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        // Top Subtle Red Glow Line
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: 20
                rightMargin: 20
            }
            height: 1
            color: Theme.accentGlow
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            // -------------------------------------------------------------
            // LEFT: X64 BRAND + WORKSPACES + ACTIVE TITLE
            // -------------------------------------------------------------
            // Menu / App Launcher Trigger
            Rectangle {
                id: menuBtn
                implicitWidth: 84
                implicitHeight: 32
                radius: Theme.radiusSm
                color: menuArea.containsMouse ? Theme.accentDim : Theme.bgCard
                border.color: menuArea.containsMouse ? Theme.accent : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰍉"
                        font.family: Theme.fontMono
                        font.pixelSize: 15
                        color: menuArea.containsMouse ? Theme.textPrimary : Theme.accent
                    }

                    Text {
                        text: "X64"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                MouseArea {
                    id: menuArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleLauncher()
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.borderSubtle
            }

            // Workspaces
            RowLayout {
                spacing: 4

                function workspaceById(wsId) {
                    if (!Hyprland.workspaces || !Hyprland.workspaces.values) return null;
                    for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                        if (Hyprland.workspaces.values[i].id === wsId) {
                            return Hyprland.workspaces.values[i];
                        }
                    }
                    return null;
                }

                Repeater {
                    model: [1, 2, 3, 4, 5, 6, 7]

                    Rectangle {
                        id: wsItem
                        required property int modelData
                        readonly property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === modelData
                        readonly property var wsObj: parent.workspaceById(modelData)
                        readonly property bool isOccupied: wsObj && wsObj.toplevels && wsObj.toplevels.values && wsObj.toplevels.values.length > 0

                        implicitWidth: isFocused ? 32 : 26
                        implicitHeight: 26
                        radius: Theme.radiusSm

                        color: isFocused ? Theme.accent : (isOccupied ? Theme.bgCard : (wsArea.containsMouse ? Theme.bgHover : "transparent"))
                        border.color: isFocused ? Theme.accentLight : (isOccupied ? Theme.borderSubtle : "transparent")
                        border.width: 1

                        Behavior on implicitWidth { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: String(wsItem.modelData)
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            font.bold: wsItem.isFocused
                            color: wsItem.isFocused ? Theme.textPrimary : (wsItem.isOccupied ? Theme.textPrimary : Theme.textMuted)
                        }

                        MouseArea {
                            id: wsArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + wsItem.modelData)
                        }
                    }
                }
            }

            // Active Window Title
            Item {
                Layout.fillWidth: true
                implicitHeight: parent.height

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(parent.width - 24, 300)
                    text: Hyprland.activeWindow ? Hyprland.activeWindow.title : ""
                    elide: Text.ElideRight
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.textSecondary
                }
            }

            // -------------------------------------------------------------
            // CENTER: CLOCK & DATE
            // -------------------------------------------------------------
            Rectangle {
                id: clockBox
                implicitWidth: clockContent.implicitWidth + 24
                implicitHeight: 32
                radius: Theme.radiusSm
                color: clockArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: clockArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    id: clockContent
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        id: timeText
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 12
                        color: Theme.borderSubtle
                    }

                    Text {
                        id: dateText
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: {
                        var now = new Date();
                        timeText.text = Qt.formatDateTime(now, "hh:mm:ss");
                        dateText.text = Qt.formatDateTime(now, "ddd, d MMM");
                    }
                }

                MouseArea {
                    id: clockArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleControl()
                }
            }

            Item {
                Layout.fillWidth: true
            }

            // -------------------------------------------------------------
            // RIGHT: AUDIO + TRAY + CONTROL CENTER + POWER
            // -------------------------------------------------------------
            // Pipewire Audio Volume
            Rectangle {
                id: audioBox
                readonly property var sink: Pipewire.defaultAudioSink
                readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
                readonly property real vol: sink && sink.audio ? sink.audio.volume : 0

                implicitWidth: audioRow.implicitWidth + 18
                implicitHeight: 32
                radius: Theme.radiusSm
                color: audioArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: audioArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                border.width: 1

                RowLayout {
                    id: audioRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: audioBox.isMuted ? "󰝟" : (audioBox.vol > 0.66 ? "󰕾" : (audioBox.vol > 0.33 ? "󰖀" : "󰕿"))
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: audioBox.isMuted ? Theme.accent : Theme.textPrimary
                    }

                    Text {
                        text: audioBox.isMuted ? "MUTE" : Math.round(audioBox.vol * 100) + "%"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        font.bold: true
                        color: audioBox.isMuted ? Theme.accent : Theme.textPrimary
                    }
                }

                MouseArea {
                    id: audioArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (audioBox.sink && audioBox.sink.audio) {
                            audioBox.sink.audio.muted = !audioBox.sink.audio.muted;
                        }
                    }
                    onWheel: (wheel) => {
                        if (audioBox.sink && audioBox.sink.audio) {
                            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            audioBox.sink.audio.volume = Math.max(0.0, Math.min(1.5, audioBox.sink.audio.volume + delta));
                        }
                    }
                }
            }

            // System Tray Items
            RowLayout {
                spacing: 4

                Repeater {
                    model: SystemTray.items

                    Rectangle {
                        id: trayBtn
                        required property var modelData
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: Theme.radiusSm
                        color: trayArea.containsMouse ? Theme.bgHover : "transparent"

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            sourceSize.width: 18
                            sourceSize.height: 18
                            source: trayBtn.modelData.icon || ""
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: trayArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    trayBtn.modelData.activate();
                                } else if (mouse.button === Qt.RightButton && trayBtn.modelData.hasMenu) {
                                    // Primary activation fallback
                                    trayBtn.modelData.secondaryActivate();
                                }
                            }
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                implicitWidth: 1
                implicitHeight: 18
                color: Theme.borderSubtle
            }

            // Control Center Button
            Rectangle {
                id: controlBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: Theme.radiusSm
                color: controlArea.containsMouse ? Theme.bgHover : Theme.bgCard
                border.color: controlArea.containsMouse ? Theme.borderAccent : Theme.borderSubtle
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰍜"
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: controlArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.toggleControl()
                }
            }

            // Power Session Button
            Rectangle {
                id: powerBtn
                implicitWidth: 32
                implicitHeight: 32
                radius: Theme.radiusSm
                color: powerArea.containsMouse ? Theme.accent : Theme.bgCard
                border.color: powerArea.containsMouse ? Theme.accentLight : Theme.borderSubtle
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: powerArea.containsMouse ? Theme.textPrimary : Theme.accent
                }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.togglePower()
                }
            }
        }
    }
}
