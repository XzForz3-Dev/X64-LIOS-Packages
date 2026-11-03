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
            calendarPopup.visible = !calendarPopup.visible;
            if (calendarPopup.visible) root.closeAllExcept("calendar");
        }

        function open() {
            calendarPopup.visible = true;
            root.closeAllExcept("calendar");
        }

        function close() {
            calendarPopup.visible = false;
        }
    }

    IpcHandler {
        target: "control"

        function toggle() {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) root.closeAllExcept("control");
        }

        function open() {
            controlCenter.visible = true;
            root.closeAllExcept("control");
        }

        function close() {
            controlCenter.visible = false;
        }
    }

    IpcHandler {
        target: "telemetry"

        function toggle() {
            telemetryPopup.visible = !telemetryPopup.visible;
            if (telemetryPopup.visible) root.closeAllExcept("telemetry");
        }

        function open() {
            telemetryPopup.visible = true;
            root.closeAllExcept("telemetry");
        }

        function close() {
            telemetryPopup.visible = false;
        }
    }

    IpcHandler {
        target: "network"

        function toggle() {
            networkPopup.visible = !networkPopup.visible;
            if (networkPopup.visible) root.closeAllExcept("network");
        }

        function open() {
            networkPopup.visible = true;
            root.closeAllExcept("network");
        }

        function close() {
            networkPopup.visible = false;
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

    // Top Bar Floating Island
    Bar {
        id: mainBar

        onToggleLauncher: {
            launcher.visible = !launcher.visible;
            if (launcher.visible) root.closeAllExcept("launcher");
        }

        onToggleCalendar: {
            calendarPopup.visible = !calendarPopup.visible;
            if (calendarPopup.visible) root.closeAllExcept("calendar");
        }

        onToggleControl: {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) root.closeAllExcept("control");
        }

        onTogglePower: {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) root.closeAllExcept("control");
        }

        onToggleTelemetry: {
            telemetryPopup.visible = !telemetryPopup.visible;
            if (telemetryPopup.visible) root.closeAllExcept("telemetry");
        }

        onToggleNetwork: {
            networkPopup.visible = !networkPopup.visible;
            if (networkPopup.visible) root.closeAllExcept("network");
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
        onLockRequested: {
            root.closeAllExcept("none");
            lockScreen.lockSession();
        }
        onBrightnessChangedOsd: (val) => {
            volumeOsd.showBrightness(val);
        }
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
