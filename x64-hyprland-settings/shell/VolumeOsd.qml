import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: osdWindow

    anchors {
        bottom: true
    }

    margins {
        bottom: 60
    }

    implicitWidth: 250
    implicitHeight: 46
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    visible: false

    property bool ready: false
    property string mode: "volume" // "volume" or "brightness"
    property int brightnessVal: 100

    function showBrightness(val) {
        osdWindow.mode = "brightness";
        osdWindow.brightnessVal = Math.round(val);
        osdWindow.visible = true;
        hideTimer.restart();
    }

    Timer {
        interval: 600
        running: true
        repeat: false
        onTriggered: osdWindow.ready = true
    }

    PwObjectTracker {
        objects: {
            var list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            return list;
        }
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real currentVol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool currentMuted: sink && sink.audio ? sink.audio.muted : false

    onCurrentVolChanged: {
        if (!osdWindow.ready) return;
        osdWindow.mode = "volume";
        osdWindow.visible = true;
        hideTimer.restart();
    }

    onCurrentMutedChanged: {
        if (!osdWindow.ready) return;
        osdWindow.mode = "volume";
        osdWindow.visible = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: osdWindow.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
                text: {
                    if (osdWindow.mode === "brightness") return "󰃠";
                    return osdWindow.currentMuted ? "󰝟" : (osdWindow.currentVol > 0.66 ? "󰕾" : (osdWindow.currentVol > 0.33 ? "󰖀" : "󰕿"));
                }
                font.family: Theme.fontMono
                font.pixelSize: 15
                color: (osdWindow.mode === "volume" && osdWindow.currentMuted) ? Theme.accent : Theme.textPrimary
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Theme.bgElevated

                Rectangle {
                    readonly property real progress: osdWindow.mode === "brightness" ? (osdWindow.brightnessVal / 100.0) : (osdWindow.currentMuted ? 0.0 : Math.min(1.0, osdWindow.currentVol))
                    width: Math.max(4, parent.width * progress)
                    height: parent.height
                    radius: 3
                    color: osdWindow.mode === "brightness" ? "#d8d6d0" : Theme.accent
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                text: {
                    if (osdWindow.mode === "brightness") return osdWindow.brightnessVal + "%";
                    return osdWindow.currentMuted ? "MUTE" : Math.round(osdWindow.currentVol * 100) + "%";
                }
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                color: (osdWindow.mode === "volume" && osdWindow.currentMuted) ? Theme.accent : Theme.textPrimary
            }
        }
    }
}
