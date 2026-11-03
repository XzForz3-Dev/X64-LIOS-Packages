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

    // Control Center Sliding Panel
    ControlCenter {
        id: controlCenter
        visible: false
        onCloseRequested: controlCenter.visible = false
        onBrightnessChangedOsd: (val) => {
            volumeOsd.showBrightness(val);
        }
    }

    // Unified On-Screen Display for Volume / Mute / Brightness Changes
    VolumeOsd {
        id: volumeOsd
    }
}
