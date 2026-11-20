import QtQuick
import Quickshell
import Quickshell.Hyprland
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

    // Dynamically track the currently focused Hyprland monitor (LVDS-1, HDMI-A-1, DP-*, etc.)
    readonly property var focusedScreen: {
        var fm = Hyprland.focusedMonitor;
        if (fm && fm.name) {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                var s = Quickshell.screens[i];
                if (s && s.name === fm.name) return s;
            }
        }
        return primaryScreen;
    }

    // Hotplug-safe target screen for bar-triggered popups (empty = follow focusedScreen)
    property string targetScreenName: ""

    readonly property var activePopupScreen: {
        if (targetScreenName !== "") {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                var s = Quickshell.screens[i];
                if (s && s.name === targetScreenName) return s;
            }
        }
        return focusedScreen;
    }

    function _screenName(scr) {
        if (scr && scr.name) return scr.name;
        return (focusedScreen && focusedScreen.name) ? focusedScreen.name : "";
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

    function toggleAnimatedPopup(popup, keyName, targetScreen) {
        var wantName = _screenName(targetScreen);
        if (popup.visible) {
            if (popup.screen && popup.screen.name === wantName) {
                popup.closeAnimated();
                return;
            }
            // Open on the other monitor -> rebind cleanly to the newly clicked/focused monitor
            popup.visible = false;
        }
        root.targetScreenName = wantName;
        root.closeAllExcept(keyName);
        popup.visible = true;
    }

    function openAnimatedPopup(popup, keyName, targetScreen) {
        var wantName = _screenName(targetScreen);
        if (popup.visible && popup.screen && popup.screen.name !== wantName) {
            popup.visible = false;
        }
        root.targetScreenName = wantName;
        root.closeAllExcept(keyName);
        popup.visible = true;
    }

    function toggleInstantPopup(popup, keyName, targetScreen, onOpenFn) {
        var wantName = _screenName(targetScreen);
        if (popup.visible) {
            if (popup.screen && popup.screen.name === wantName) {
                popup.visible = false;
                return;
            }
            popup.visible = false;
        }
        root.targetScreenName = wantName;
        root.closeAllExcept(keyName);
        popup.visible = true;
        if (onOpenFn) onOpenFn();
    }

    function openInstantPopup(popup, keyName, targetScreen, onOpenFn) {
        var wantName = _screenName(targetScreen);
        if (popup.visible && popup.screen && popup.screen.name !== wantName) {
            popup.visible = false;
        }
        root.targetScreenName = wantName;
        root.closeAllExcept(keyName);
        popup.visible = true;
        if (onOpenFn) onOpenFn();
    }

    function toggleAudioOnScreen(targetScreen, tab) {
        var wantName = _screenName(targetScreen);
        if (audioPopup.visible && (!tab || audioPopup.activeTab === tab) && audioPopup.screen && audioPopup.screen.name === wantName) {
            audioPopup.closeAnimated();
            return;
        }
        if (audioPopup.visible && (!audioPopup.screen || audioPopup.screen.name !== wantName)) {
            audioPopup.visible = false;
        }
        root.targetScreenName = wantName;
        if (tab) audioPopup.activeTab = tab;
        root.closeAllExcept("audio");
        audioPopup.visible = true;
    }

    // IPC Handlers for Hyprland Keybindings & Scripts (always follow focused monitor)
    IpcHandler {
        target: "menu"

        function toggle() {
            root.toggleInstantPopup(launcher, "launcher", root.focusedScreen, null);
        }

        function open() {
            root.openInstantPopup(launcher, "launcher", root.focusedScreen, null);
        }

        function close() {
            launcher.visible = false;
        }
    }

    IpcHandler {
        target: "calendar"

        function toggle() {
            root.toggleAnimatedPopup(calendarPopup, "calendar", root.focusedScreen);
        }

        function open() {
            root.openAnimatedPopup(calendarPopup, "calendar", root.focusedScreen);
        }

        function close() {
            calendarPopup.closeAnimated();
        }
    }

    IpcHandler {
        target: "control"

        function toggle() {
            root.toggleAnimatedPopup(controlCenter, "control", root.focusedScreen);
        }

        function open() {
            root.openAnimatedPopup(controlCenter, "control", root.focusedScreen);
        }

        function close() {
            controlCenter.closeAnimated();
        }

        function recordMenu() {
            controlCenter.recMenuOpen = true;
            root.openAnimatedPopup(controlCenter, "control", root.focusedScreen);
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
            root.toggleAnimatedPopup(telemetryPopup, "telemetry", root.focusedScreen);
        }

        function open() {
            root.openAnimatedPopup(telemetryPopup, "telemetry", root.focusedScreen);
        }

        function close() {
            telemetryPopup.closeAnimated();
        }
    }

    IpcHandler {
        target: "network"

        function toggle() {
            root.toggleAnimatedPopup(networkPopup, "network", root.focusedScreen);
        }

        function open() {
            root.openAnimatedPopup(networkPopup, "network", root.focusedScreen);
        }

        function close() {
            networkPopup.closeAnimated();
        }
    }

    IpcHandler {
        target: "audio"

        function toggle() {
            root.toggleAudioOnScreen(root.focusedScreen, "");
        }

        function open() {
            root.openAnimatedPopup(audioPopup, "audio", root.focusedScreen);
        }

        function openSinks() {
            audioPopup.activeTab = "sinks";
            root.openAnimatedPopup(audioPopup, "audio", root.focusedScreen);
        }

        function openSources() {
            audioPopup.activeTab = "sources";
            root.openAnimatedPopup(audioPopup, "audio", root.focusedScreen);
        }

        function openStreams() {
            audioPopup.activeTab = "streams";
            root.openAnimatedPopup(audioPopup, "audio", root.focusedScreen);
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

    // Universal ScreenFilter temporary hide for clean screenshots across all monitors
    property bool filterTempHidden: false

    Timer {
        id: filterUnhideSafetyTimer
        interval: 2500
        repeat: false
        onTriggered: root.filterTempHidden = false
    }

    IpcHandler {
        target: "filter"

        function hide() {
            root.filterTempHidden = true;
            filterUnhideSafetyTimer.restart();
        }

        function show() {
            filterUnhideSafetyTimer.stop();
            root.filterTempHidden = false;
        }
    }

    IpcHandler {
        target: "shortcuts"

        function toggle() {
            root.toggleInstantPopup(shortcutsPopup, "shortcuts", root.focusedScreen, null);
        }

        function open() {
            root.openInstantPopup(shortcutsPopup, "shortcuts", root.focusedScreen, null);
        }

        function close() {
            shortcutsPopup.visible = false;
        }
    }

    IpcHandler {
        target: "clipboard"

        function toggle() {
            root.toggleInstantPopup(clipboardPopup, "clipboard", root.focusedScreen, function() {
                clipboardPopup.reload();
            });
        }

        function open() {
            root.openInstantPopup(clipboardPopup, "clipboard", root.focusedScreen, function() {
                clipboardPopup.reload();
            });
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
            root.toggleInstantPopup(overviewPopup, "overview", root.focusedScreen, function() {
                overviewPopup.reload();
            });
        }

        function open() {
            root.openInstantPopup(overviewPopup, "overview", root.focusedScreen, function() {
                overviewPopup.reload();
            });
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

    // Fast IPC state sync for keybindings / external ctl commands (e.g. SUPER + G)
    IpcHandler {
        target: "sys"

        function refresh() {
            SysState.syncFromExternal();
        }
    }

    // Direct OSD trigger for hardware brightness keys (XF86MonBrightnessUp/Down)
    IpcHandler {
        target: "osd"

        function brightness(val: string) {
            var n = parseInt(val, 10);
            if (!isNaN(n)) {
                SysState.guardBrightness();
                SysState.brightnessVal = n;
                volumeOsd.showBrightness(n);
            }
        }
    }

    // Top Bar Floating Island replicated across ALL connected displays (0 duplicated polling via SysState)
    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
            isPrimaryBar: root.primaryScreen !== null && modelData.name === root.primaryScreen.name

            onToggleLauncher: root.toggleInstantPopup(launcher, "launcher", modelData, null)
            onToggleCalendar: root.toggleAnimatedPopup(calendarPopup, "calendar", modelData)
            onToggleControl: root.toggleAnimatedPopup(controlCenter, "control", modelData)
            onTogglePower: root.toggleAnimatedPopup(controlCenter, "control", modelData)
            onToggleTelemetry: root.toggleAnimatedPopup(telemetryPopup, "telemetry", modelData)
            onToggleNetwork: root.toggleAnimatedPopup(networkPopup, "network", modelData)
            onToggleAudio: (tab) => root.toggleAudioOnScreen(modelData, tab)
            onBrightnessChangedOsd: (val) => volumeOsd.showBrightness(val)
        }
    }

    // Cyberpunk Dashboard App Launcher
    AppLauncher {
        id: launcher
        screen: root.activePopupScreen
        visible: false
        onCloseRequested: launcher.visible = false
    }

    // Cyberpunk Calendar & Date Dropdown Popup
    CalendarPopup {
        id: calendarPopup
        screen: root.activePopupScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: calendarPopup.visible = false
    }

    // Expanded Hardware Telemetry Popup
    TelemetryPopup {
        id: telemetryPopup
        screen: root.activePopupScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: telemetryPopup.visible = false
    }

    // Native Network & Wi-Fi Popup (Omarchy 4 Quattro style)
    NetworkPopup {
        id: networkPopup
        screen: root.activePopupScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: networkPopup.visible = false
    }

    // Native Audio & Devices Popup (Outputs, Mic VU Meter, Boost 150%, Streams Mixer)
    AudioPopup {
        id: audioPopup
        screen: root.activePopupScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: audioPopup.visible = false
    }

    // Control Center Sliding Panel
    ControlCenter {
        id: controlCenter
        screen: root.activePopupScreen
        visible: false
        lockClose: root.lockPopups
        onCloseRequested: controlCenter.visible = false
        onLockRequested: {
            root.closeAllExcept("none");
            lockScreen.lockSession();
        }
        onBrightnessChangedOsd: (val) => {
            volumeOsd.showBrightness(val);
        }
    }

    // Universal Click-Through Screen Filter replicated across ALL connected monitors
    Variants {
        model: Quickshell.screens

        ScreenFilter {
            required property var modelData
            screen: modelData
            tempHidden: root.filterTempHidden
            nightlightActive: SysState.nightlightActive
            brightnessVal: SysState.brightnessVal
        }
    }

    // Unified On-Screen Display for Volume / Mute / Brightness Changes (follows active monitor)
    VolumeOsd {
        id: volumeOsd
        screen: root.focusedScreen
    }

    // Native Notification Server & Toast Overlay (follows active monitor, respects DND)
    NotificationPopup {
        id: notifPopup
        screen: root.focusedScreen
        dndEnabled: SysState.dndActive
        sidePanelOpen: (controlCenter.visible || networkPopup.visible) && (root.activePopupScreen === root.focusedScreen)
    }

    // Native Interactive Shortcuts Guide & HUD (SUPER + F1)
    ShortcutsPopup {
        id: shortcutsPopup
        screen: root.activePopupScreen
        visible: false
        onCloseRequested: shortcutsPopup.visible = false
    }

    // Native Wayland Clipboard History Manager (SUPER + V)
    ClipboardPopup {
        id: clipboardPopup
        screen: root.activePopupScreen
        visible: false
        onCloseRequested: clipboardPopup.visible = false
    }

    // Native Wayland Workspaces Overview / Mission Control (SUPER + TAB)
    OverviewPopup {
        id: overviewPopup
        screen: root.activePopupScreen
        visible: false
        onCloseRequested: overviewPopup.visible = false
    }

    // Native Wayland Security Lockscreen (ext-session-lock-v1 + PAM)
    LockScreen {
        id: lockScreen
    }
}
