import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    function closeAllExcept(targetName) {
        if (targetName !== "launcher") launcher.visible = false;
        if (targetName !== "calendar") calendarPopup.visible = false;
        if (targetName !== "control") controlCenter.visible = false;
        if (targetName !== "telemetry") telemetryPopup.visible = false;
        if (targetName !== "network") networkPopup.visible = false;
    }

    // IPC Handlers for Hyprland Keybindings & Scripts
    IpcHandler {
        target: "menu"

        function toggle() {
            launcher.visible = !launcher.visible;
            if (launcher.visible) root.closeAllExcept("launcher");
        }

        function open() {
            launcher.visible = true;
            root.closeAllExcept("launcher");
        }

        function close() {
            launcher.visible = false;
        }
    }

    IpcHandler {
        target: "calendar"

        function toggle() {
            if (calendarPopup.visible) {
                calendarPopup.closeAnimated();
            } else {
                calendarPopup.visible = true;
                root.closeAllExcept("calendar");
            }
        }

        function open() {
            calendarPopup.visible = true;
            root.closeAllExcept("calendar");
        }

        function close() {
            calendarPopup.closeAnimated();
        }
    }

    IpcHandler {
        target: "control"

        function toggle() {
            if (controlCenter.visible) {
                controlCenter.closeAnimated();
            } else {
                controlCenter.visible = true;
                root.closeAllExcept("control");
            }
        }

        function open() {
            controlCenter.visible = true;
            root.closeAllExcept("control");
        }

        function close() {
            controlCenter.closeAnimated();
        }

        function recordMenu() {
            controlCenter.visible = true;
            controlCenter.recMenuOpen = true;
            root.closeAllExcept("control");
        }
    }

    IpcHandler {
        target: "telemetry"

        function toggle() {
            if (telemetryPopup.visible) {
                telemetryPopup.closeAnimated();
            } else {
                telemetryPopup.visible = true;
                root.closeAllExcept("telemetry");
            }
        }

        function open() {
            telemetryPopup.visible = true;
            root.closeAllExcept("telemetry");
        }

        function close() {
            telemetryPopup.closeAnimated();
        }
    }

    IpcHandler {
        target: "network"

        function toggle() {
            if (networkPopup.visible) {
                networkPopup.closeAnimated();
            } else {
                networkPopup.visible = true;
                root.closeAllExcept("network");
            }
        }

        function open() {
            networkPopup.visible = true;
            root.closeAllExcept("network");
        }

        function close() {
            networkPopup.closeAnimated();
        }
    }

    IpcHandler {
        target: "lock"

        function lock() {
            root.closeAllExcept("none");
            lockScreen.lockSession();
        }

        function unlock() {
            lockScreen.unlockSession();
        }
    }

    IpcHandler {
        target: "filter"

        function hide() {
            screenFilter.tempHidden = true;
        }

        function show() {
            screenFilter.tempHidden = false;
        }
    }

    // Top Bar Floating Island
    Bar {
        id: mainBar

        controlOpen: controlCenter.visible
        calendarOpen: calendarPopup.visible
        telemetryOpen: telemetryPopup.visible
        networkOpen: networkPopup.visible

        onToggleLauncher: {
            launcher.visible = !launcher.visible;
            if (launcher.visible) root.closeAllExcept("launcher");
        }

        onToggleCalendar: {
            if (calendarPopup.visible) {
                calendarPopup.closeAnimated();
            } else {
                calendarPopup.visible = true;
                root.closeAllExcept("calendar");
            }
        }

        onToggleControl: {
            if (controlCenter.visible) {
                controlCenter.closeAnimated();
            } else {
                controlCenter.visible = true;
                root.closeAllExcept("control");
            }
        }

        onTogglePower: {
            if (controlCenter.visible) {
                controlCenter.closeAnimated();
            } else {
                controlCenter.visible = true;
                root.closeAllExcept("control");
            }
        }

        onToggleTelemetry: {
            if (telemetryPopup.visible) {
                telemetryPopup.closeAnimated();
            } else {
                telemetryPopup.visible = true;
                root.closeAllExcept("telemetry");
            }
        }

        onToggleNetwork: {
            if (networkPopup.visible) {
                networkPopup.closeAnimated();
            } else {
                networkPopup.visible = true;
                root.closeAllExcept("network");
            }
        }

        onBrightnessChangedOsd: (val) => {
            volumeOsd.showBrightness(val);
        }
    }

    // Cyberpunk Dashboard App Launcher
    AppLauncher {
        id: launcher
        visible: false
        onCloseRequested: launcher.visible = false
    }

    // Cyberpunk Calendar & Date Dropdown Popup
    CalendarPopup {
        id: calendarPopup
        visible: false
        onCloseRequested: calendarPopup.visible = false
    }

    // Expanded Hardware Telemetry Popup
    TelemetryPopup {
        id: telemetryPopup
        visible: false
        onCloseRequested: telemetryPopup.visible = false
    }

    // Native Network & Wi-Fi Popup (Omarchy 4 Quattro style)
    NetworkPopup {
        id: networkPopup
        visible: false
        onCloseRequested: networkPopup.visible = false
    }

    // Control Center Sliding Panel
    ControlCenter {
        id: controlCenter
        visible: false
        onCloseRequested: controlCenter.visible = false
        onDndToggled: (active) => {
            mainBar.dndActive = active;
        }
        onNightlightToggled: (active) => {
            mainBar.nightlightActive = active;
        }
        onLockRequested: {
            root.closeAllExcept("none");
            lockScreen.lockSession();
        }
        onBrightnessChangedOsd: (val) => {
            mainBar.brightnessVal = val;
            volumeOsd.showBrightness(val);
        }
    }

    // Universal Click-Through Screen Filter (Warm 4200K Nightlight + Software Dimming)
    ScreenFilter {
        id: screenFilter
        nightlightActive: mainBar.nightlightActive
        brightnessVal: mainBar.brightnessVal
    }

    // Unified On-Screen Display for Volume / Mute / Brightness Changes
    VolumeOsd {
        id: volumeOsd
    }

    // Native Notification Server & Toast Overlay (Respects DND No Molestar)
    NotificationPopup {
        id: notifPopup
        dndEnabled: mainBar.dndActive
        sidePanelOpen: controlCenter.visible || networkPopup.visible
    }

    // Native Wayland Security Lockscreen (ext-session-lock-v1 + PAM)
    LockScreen {
        id: lockScreen
    }
}
