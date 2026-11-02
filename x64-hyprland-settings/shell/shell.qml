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
        }

        function open() {
            launcher.visible = true;
        }

        function close() {
            launcher.visible = false;
        }
    }

    IpcHandler {
        target: "control"

        function toggle() {
            controlCenter.visible = !controlCenter.visible;
        }

        function open() {
            controlCenter.visible = true;
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
            if (launcher.visible) controlCenter.visible = false;
        }

        onToggleControl: {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) launcher.visible = false;
        }

        onTogglePower: {
            controlCenter.visible = !controlCenter.visible;
            if (controlCenter.visible) launcher.visible = false;
        }
    }

    // Cyberpunk Dashboard App Launcher
    AppLauncher {
        id: launcher
        visible: false
        onCloseRequested: launcher.visible = false
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
