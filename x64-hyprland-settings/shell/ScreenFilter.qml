import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: filterWindow

    property bool nightlightActive: false
    property int brightnessVal: 100
    property bool tempHidden: false

    readonly property double nightAlpha: nightlightActive ? 0.07 : 0.0
    readonly property double dimAlpha: Math.max(0.0, Math.min(0.72, (100 - brightnessVal) * 0.0085))

    visible: !tempHidden && (nightlightActive || brightnessVal < 100)

    onTempHiddenChanged: {
        if (tempHidden) {
            unhideSafetyTimer.restart();
        } else {
            unhideSafetyTimer.stop();
        }
    }

    Timer {
        id: unhideSafetyTimer
        interval: 2500
        repeat: false
        onTriggered: filterWindow.tempHidden = false
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    color: "transparent"

    // Empty input region mask -> 100% click-through (all mouse/touch events pass through)
    mask: Region {}

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-filter"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // 1. Warm 4800K Nightlight Filter (Subtle 7% golden warmth for QEMU/VMs without DRM CTM)
    Rectangle {
        anchors.fill: parent
        color: "#ff9329"
        opacity: filterWindow.nightAlpha
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    // 2. Software Gamma / Backlight Dimmer (Universal fallback for monitors/VMs without /sys/class/backlight)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: filterWindow.dimAlpha
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }
}

