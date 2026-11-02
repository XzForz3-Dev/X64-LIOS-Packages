import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // IPC Handlers for Hyprland Keybindings & Scripts
    IpcHandler {
        target: "menu"

        function toggle() {
            launcher.visible = !launcher.visible;
            if (launcher.visible) {
                controlCenter.visible = false;
                calendarPopup.visible = false;
            }
        }

        function open() {
            launcher.visible = true;
            controlCenter.visible = false;
            calendarPopup.visible = false;
        }

        function close() {
            launcher.visible = false;
        }
    }

    IpcHandler {
        target: "calendar"

        function toggle() {
            calendarPopup.visible = !calendarPopup.visible;
            if (calendarPopup.visible) {
                launcher.visible = false;
                controlCenter.visible = false;
            }
        }

        function open() {
            calendarPopup.visible = true;
            launcher.visible = false;
            controlCenter.visible = false;
        }

        function close() {
            calendarPopup.visible = false;
        }
    }

    IpcHandler {
        target: "control"

        function toggle() {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) {
                launcher.visible = false;
                calendarPopup.visible = false;
            }
        }

        function open() {
            controlCenter.visible = true;
            launcher.visible = false;
            calendarPopup.visible = false;
        }

        function close() {
            controlCenter.visible = false;
        }
    }

    // Top Bar Floating Island
    Bar {
        id: mainBar

        onToggleLauncher: {
            launcher.visible = !launcher.visible;
            if (launcher.visible) {
                controlCenter.visible = false;
                calendarPopup.visible = false;
            }
        }

        onToggleCalendar: {
            calendarPopup.visible = !calendarPopup.visible;
            if (calendarPopup.visible) {
                launcher.visible = false;
                controlCenter.visible = false;
            }
        }

        onToggleControl: {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) {
                launcher.visible = false;
                calendarPopup.visible = false;
            }
        }

        onTogglePower: {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) {
                launcher.visible = false;
                calendarPopup.visible = false;
            }
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

    // Control Center Sliding Panel
    ControlCenter {
        id: controlCenter
        visible: false
        onCloseRequested: controlCenter.visible = false
    }

    // On-Screen Display for Volume / Mute Changes
    VolumeOsd {
        id: volumeOsd
    }
}
