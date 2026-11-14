import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    // Discover Primary Laptop Display (eDP / LVDS) or fallback to first available screen
    readonly property var primaryScreen: {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            var s = Quickshell.screens[i];
            if (s && s.name && (s.name.indexOf("eDP") !== -1 || s.name.indexOf("LVDS") !== -1)) {
                return s;
            }
        }
        return (Quickshell.screens.length > 0) ? Quickshell.screens[0] : null;
    }

    function closeAllExcept(targetName) {
        if (targetName !== "launcher") launcher.visible = false;
        if (targetName !== "calendar") calendarPopup.visible = false;
        if (targetName !== "control") controlCenter.visible = false;
        if (targetName !== "telemetry") telemetryPopup.visible = false;
        if (targetName !== "network") networkPopup.visible = false;
        if (targetName !== "audio") audioPopup.visible = false;
        if (targetName !== "shortcuts") shortcutsPopup.visible = false;
        if (targetName !== "clipboard") clipboardPopup.visible = false;
        if (targetName !== "overview") overviewPopup.visible = false;
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

    // Screenshot & Recording Protection: Locks popups so they do not dismiss when slurp grabs focus
    property bool lockPopups: false

    Timer {
        id: popupsLockSafetyTimer
        interval: 15000
        repeat: false
        onTriggered: root.lockPopups = false
    }

    IpcHandler {
        target: "popups"

        function lock() {
            root.lockPopups = true;
            popupsLockSafetyTimer.restart();
        }

        function unlock() {
            popupsLockSafetyTimer.stop();
            root.lockPopups = false;
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
        target: "audio"

        function toggle() {
            if (audioPopup.visible) {
                audioPopup.closeAnimated();
            } else {
                audioPopup.visible = true;
                root.closeAllExcept("audio");
            }
        }

        function open() {
            audioPopup.visible = true;
            root.closeAllExcept("audio");
        }

        function openSinks() {
            audioPopup.activeTab = "sinks";
            audioPopup.visible = true;
            root.closeAllExcept("audio");
        }

        function openSources() {
            audioPopup.activeTab = "sources";
            audioPopup.visible = true;
            root.closeAllExcept("audio");
        }

        function close() {
            audioPopup.closeAnimated();
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

    IpcHandler {
        target: "shortcuts"

        function toggle() {
            shortcutsPopup.visible = !shortcutsPopup.visible;
            if (shortcutsPopup.visible) root.closeAllExcept("shortcuts");
        }

        function open() {
            shortcutsPopup.visible = true;
            root.closeAllExcept("shortcuts");
        }

        function close() {
            shortcutsPopup.visible = false;
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle() {
            clipboardPopup.visible = !clipboardPopup.visible;
            if (clipboardPopup.visible) {
                root.closeAllExcept("clipboard");
                clipboardPopup.reload();
            }
        }

        function open() {
            clipboardPopup.visible = true;
            root.closeAllExcept("clipboard");
            clipboardPopup.reload();
        }

        function close() {
            clipboardPopup.visible = false;
        }

        function reload() {
            if (clipboardPopup.visible) {
                clipboardPopup.reload();
            }
        }
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            overviewPopup.visible = !overviewPopup.visible;
            if (overviewPopup.visible) {
                root.closeAllExcept("overview");
                overviewPopup.reload();
            }
        }

        function open() {
            overviewPopup.visible = true;
            root.closeAllExcept("overview");
            overviewPopup.reload();
        }

        function close() {
            overviewPopup.visible = false;
        }

        function reload() {
            if (overviewPopup.visible) {
                overviewPopup.reload();
            }
        }
    }

    // Top Bar Floating Island
    Bar {
        id: mainBar
        screen: root.primaryScreen

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

        onToggleAudio: (tab) => {
            if (audioPopup.visible && (!tab || audioPopup.activeTab === tab)) {
                audioPopup.closeAnimated();
            } else {
                if (tab) audioPopup.activeTab = tab;
                audioPopup.visible = true;
                root.closeAllExcept("audio");
            }
        }

        onBrightnessChangedOsd: (val) => {
            volumeOsd.showBrightness(val);
        }
    }

    // Cyberpunk Dashboard App Launcher
    AppLauncher {
        id: launcher
        screen: root.primaryScreen
        visible: false
        onCloseRequested: launcher.visible = false
    }

    // Cyberpunk Calendar & Date Dropdown Popup
    CalendarPopup {
        id: calendarPopup
        screen: root.primaryScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: calendarPopup.visible = false
    }

    // Expanded Hardware Telemetry Popup
    TelemetryPopup {
        id: telemetryPopup
        screen: root.primaryScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: telemetryPopup.visible = false
    }

    // Native Network & Wi-Fi Popup (Omarchy 4 Quattro style)
    NetworkPopup {
        id: networkPopup
        screen: root.primaryScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: networkPopup.visible = false
    }

    // Native Audio & Devices Popup (Outputs, Mic VU Meter, Boost 150%, Streams Mixer)
    AudioPopup {
        id: audioPopup
        screen: root.primaryScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: audioPopup.visible = false
    }

    // Control Center Sliding Panel
    ControlCenter {
        id: controlCenter
        screen: root.primaryScreen
        visible: false
        lockClose: root.lockPopups
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
        screen: root.primaryScreen
    }

    // Native Notification Server & Toast Overlay (Respects DND No Molestar)
    NotificationPopup {
        id: notifPopup
        screen: root.primaryScreen
        dndEnabled: mainBar.dndActive
        sidePanelOpen: controlCenter.visible || networkPopup.visible
    }

    // Native Interactive Shortcuts Guide & HUD (SUPER + F1)
    ShortcutsPopup {
        id: shortcutsPopup
        screen: root.primaryScreen
        visible: false
        onCloseRequested: shortcutsPopup.visible = false
    }

    // Native Wayland Clipboard History Manager (SUPER + V)
    ClipboardPopup {
        id: clipboardPopup
        screen: root.primaryScreen
        visible: false
        onCloseRequested: clipboardPopup.visible = false
    }

    // Native Wayland Workspaces Overview / Mission Control (SUPER + TAB)
    OverviewPopup {
        id: overviewPopup
        screen: root.primaryScreen
        visible: false
        onCloseRequested: overviewPopup.visible = false
    }

    // Native Wayland Security Lockscreen (ext-session-lock-v1 + PAM)
    LockScreen {
        id: lockScreen
    }
}
