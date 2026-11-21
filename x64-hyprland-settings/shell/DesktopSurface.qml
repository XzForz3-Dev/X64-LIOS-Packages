import QtQuick
import Quickshell
import Quickshell.Wayland

// =============================================================================
// X64 LIOS - Invisible Multi-Monitor Desktop Gesture Surface (DesktopSurface.qml)
// Sits on WlrLayer.Bottom (always below app windows, always above Wallpaper.qml
// AND mpvpaper video layers). Zero pixels drawn -> 0% GPU/CPU cost at rest.
//   • Double Left-Click  -> X64 Theme Studio (sets GPU Wave origin at cursor!)
//   • Single Right-Click -> Obsidian Context Menu at cursor (200ms zero-flicker)
//   • Double Right-Click -> Workspaces Overview / Mission Control
// =============================================================================
PanelWindow {
    id: hitWindow

    signal openThemeAt(var targetScreen, real nx, real ny)
    signal openOverview(var targetScreen)
    signal openContextMenu(var targetScreen, real px, real py)
    signal dismissPopups()

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
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desktop-hit"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property double lastLeftTime: 0
    property real lastLeftX: -100
    property real lastLeftY: -100

    property real pendingRightX: 0
    property real pendingRightY: 0

    Timer {
        id: rightClickTimer
        interval: 200
        repeat: false
        onTriggered: {
            hitWindow.openContextMenu(hitWindow.screen, hitWindow.pendingRightX, hitWindow.pendingRightY);
        }
    }

    MouseArea {
        id: desktopHitArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                // Cancel any pending right-click gesture
                rightClickTimer.stop();

                var now = Date.now();
                var dist = Math.hypot(mouse.x - hitWindow.lastLeftX, mouse.y - hitWindow.lastLeftY);
                if (now - hitWindow.lastLeftTime <= 330 && dist <= 16) {
                    hitWindow.lastLeftTime = 0;
                    var w = Math.max(1, hitWindow.width);
                    var h = Math.max(1, hitWindow.height);
                    var nx = Math.max(0.05, Math.min(0.95, mouse.x / w));
                    var ny = Math.max(0.05, Math.min(0.95, mouse.y / h));
                    hitWindow.openThemeAt(hitWindow.screen, nx, ny);
                } else {
                    hitWindow.lastLeftTime = now;
                    hitWindow.lastLeftX = mouse.x;
                    hitWindow.lastLeftY = mouse.y;
                    hitWindow.dismissPopups();
                }
            } else if (mouse.button === Qt.RightButton) {
                hitWindow.lastLeftTime = 0;
                if (rightClickTimer.running) {
                    // Second right-click within 200ms -> Overview (zero context menu flash!)
                    rightClickTimer.stop();
                    hitWindow.openOverview(hitWindow.screen);
                } else {
                    hitWindow.pendingRightX = mouse.x;
                    hitWindow.pendingRightY = mouse.y;
                    rightClickTimer.restart();
                }
            }
        }
    }
}
