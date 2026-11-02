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

    implicitWidth: 240
    implicitHeight: 46
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay

    visible: false

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real currentVol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool currentMuted: sink && sink.audio ? sink.audio.muted : false

    onCurrentVolChanged: {
        osdWindow.visible = true;
        hideTimer.restart();
    }

    onCurrentMutedChanged: {
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
        radius: Theme.radiusPill
        color: Theme.bgGlass
        border.color: Theme.borderAccent
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 12

            Text {
                text: osdWindow.currentMuted ? "󰝟" : (osdWindow.currentVol > 0.66 ? "󰕾" : (osdWindow.currentVol > 0.33 ? "󰖀" : "󰕿"))
                font.family: Theme.fontMono
                font.pixelSize: 16
                color: osdWindow.currentMuted ? Theme.accent : Theme.textPrimary
            }

            ProgressBar {
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: osdWindow.currentVol
            }

            Text {
                text: osdWindow.currentMuted ? "MUTE" : Math.round(osdWindow.currentVol * 100) + "%"
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                color: osdWindow.currentMuted ? Theme.accent : Theme.textPrimary
            }
        }
    }
}
