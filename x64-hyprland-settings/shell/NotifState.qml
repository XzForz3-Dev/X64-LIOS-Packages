pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// =============================================================================
// X64 LIOS - Persistent Notification History Singleton (NotifState.qml)
// Shared by NotificationPopup (toast overlay), NotificationCenterPopup (drawer)
// and Bar (bell + unread badge).
// - Keeps the latest 25 notifications across Quickshell/session restarts.
// - Archives notifications silently even while Do Not Disturb (DND) is active.
// =============================================================================
QtObject {
    id: notifState

    readonly property int maxItems: 25
    readonly property string statePath: (Quickshell.env("HOME") || "/tmp") + "/.local/state/x64-hyprland/notifications.json"

    property var history: []
    property int unreadCount: 0
    property bool drawerOpen: false
    property int _nextSeq: 1
    property bool _loaded: false

    function iconFor(app, sum) {
        var lowerSum = (sum || "").toLowerCase();
        var lowerApp = (app || "").toLowerCase();
        if (lowerApp.indexOf("molestar") !== -1 || lowerApp.indexOf("disturb") !== -1 || lowerSum.indexOf("molestar") !== -1) return "󰂛";
        if (lowerApp.indexOf("gaming") !== -1 || lowerSum.indexOf("gaming") !== -1 || lowerSum.indexOf("planificador") !== -1 || lowerSum.indexOf("scheduler") !== -1 || lowerSum.indexOf("scx_") !== -1 || lowerSum.indexOf("bore") !== -1) return "󰊴";
        if (lowerSum.indexOf("noche") !== -1 || lowerSum.indexOf("nocturna") !== -1 || lowerSum.indexOf("night") !== -1) return "󰖔";
        if (lowerSum.indexOf("café") !== -1 || lowerSum.indexOf("cafe") !== -1 || lowerSum.indexOf("caffeine") !== -1) return "󰅶";
        if (lowerSum.indexOf("captura") !== -1 || lowerSum.indexOf("screen") !== -1 || lowerSum.indexOf("grab") !== -1) return "󰄀";
        if (lowerSum.indexOf("energía") !== -1 || lowerSum.indexOf("power") !== -1 || lowerSum.indexOf("perfil") !== -1) return "󰾅";
        if (lowerSum.indexOf("red") !== -1 || lowerSum.indexOf("wi-fi") !== -1 || lowerSum.indexOf("ethernet") !== -1) return "󰈀";
        if (lowerSum.indexOf("tema") !== -1 || lowerSum.indexOf("theme") !== -1 || lowerApp.indexOf("theme") !== -1) return "󰏘";
        if (lowerSum.indexOf("actualiz") !== -1 || lowerSum.indexOf("update") !== -1 || lowerApp.indexOf("update") !== -1) return "󰚰";
        if (lowerSum.indexOf("audio") !== -1 || lowerSum.indexOf("volumen") !== -1 || lowerSum.indexOf("volume") !== -1) return "󰕾";
        return "󰂚";
    }

    function _formatTime(now) {
        var h = String(now.getHours()).padStart(2, "0");
        var m = String(now.getMinutes()).padStart(2, "0");
        return h + ":" + m;
    }

    function _recountUnread(list) {
        var c = 0;
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].unread) c++;
        }
        return c;
    }

    function _scheduleSave() {
        saveDebounce.restart();
    }

    function recordNotification(app, sum, bod) {
        var cleanApp = (app && String(app).trim() !== "") ? String(app).trim() : "X64 LIOS";
        var cleanSum = (sum && String(sum).trim() !== "") ? String(sum).trim() : (I18n.isEs ? "Notificación" : "Notification");
        var cleanBod = bod ? String(bod).trim() : "";

        var now = new Date();
        var nowMs = now.getTime();
        var list = notifState.history ? notifState.history.slice() : [];

        // Deduplicate immediate identical bursts (within 2s)
        if (list.length > 0) {
            var top = list[0];
            if (top && top.appName === cleanApp && top.summary === cleanSum && top.body === cleanBod && (nowMs - (top.timestamp || 0)) < 2000) {
                return;
            }
        }

        var entry = {
            "id": String(nowMs) + "-" + String(notifState._nextSeq++),
            "appName": cleanApp,
            "summary": cleanSum,
            "body": cleanBod,
            "timeStr": _formatTime(now),
            "timestamp": nowMs,
            "icon": iconFor(cleanApp, cleanSum),
            "unread": !notifState.drawerOpen
        };

        list.unshift(entry);
        if (list.length > notifState.maxItems) {
            list = list.slice(0, notifState.maxItems);
        }

        notifState.history = list;
        notifState.unreadCount = _recountUnread(list);
        _scheduleSave();
    }

    function removeById(nid) {
        if (!nid) return;
        var list = [];
        for (var i = 0; i < notifState.history.length; i++) {
            var it = notifState.history[i];
            if (it && it.id !== nid) list.push(it);
        }
        notifState.history = list;
        notifState.unreadCount = _recountUnread(list);
        _scheduleSave();
    }

    function clearAll() {
        if (notifState.history.length === 0 && notifState.unreadCount === 0) return;
        notifState.history = [];
        notifState.unreadCount = 0;
        _scheduleSave();
    }

    function markAllRead() {
        var changed = false;
        var list = [];
        for (var i = 0; i < notifState.history.length; i++) {
            var it = notifState.history[i];
            if (!it) continue;
            if (it.unread) {
                changed = true;
                list.push({
                    "id": it.id,
                    "appName": it.appName,
                    "summary": it.summary,
                    "body": it.body,
                    "timeStr": it.timeStr,
                    "timestamp": it.timestamp,
                    "icon": it.icon || iconFor(it.appName, it.summary),
                    "unread": false
                });
            } else {
                list.push(it);
            }
        }
        if (changed || notifState.unreadCount !== 0) {
            notifState.history = list;
            notifState.unreadCount = 0;
            _scheduleSave();
        }
    }

    function _loadFromJson(raw) {
        if (!raw || raw.trim() === "") return;
        try {
            var parsed = JSON.parse(raw.trim());
            if (!Array.isArray(parsed)) return;
            var clean = [];
            for (var i = 0; i < parsed.length && clean.length < notifState.maxItems; i++) {
                var it = parsed[i];
                if (!it || typeof it !== "object") continue;
                var app = it.appName ? String(it.appName) : "X64 LIOS";
                var sum = it.summary ? String(it.summary) : "";
                if (sum === "") continue;
                clean.push({
                    "id": it.id ? String(it.id) : ("restored-" + i),
                    "appName": app,
                    "summary": sum,
                    "body": it.body ? String(it.body) : "",
                    "timeStr": it.timeStr ? String(it.timeStr) : "",
                    "timestamp": it.timestamp ? Number(it.timestamp) : 0,
                    "icon": it.icon ? String(it.icon) : iconFor(app, sum),
                    "unread": Boolean(it.unread)
                });
            }
            // Merge any notifications that arrived before disk load finished
            if (notifState.history.length > 0) {
                var merged = notifState.history.slice();
                for (var j = 0; j < clean.length && merged.length < notifState.maxItems; j++) {
                    merged.push(clean[j]);
                }
                clean = merged;
            }
            notifState.history = clean;
            notifState.unreadCount = _recountUnread(clean);
        } catch (e) {}
    }

    readonly property Timer _saveDebounce: Timer {
        id: saveDebounce
        interval: 220
        repeat: false
        onTriggered: {
            if (saveProc.running) {
                saveDebounce.restart();
                return;
            }
            var payload = JSON.stringify(notifState.history);
            saveProc.command = [
                "python3", "-c",
                "import os,sys; p=sys.argv[1]; d=os.path.dirname(p); os.makedirs(d,exist_ok=True); t=p+'.tmp.'+str(os.getpid()); open(t,'w',encoding='utf-8').write(sys.argv[2]); os.replace(t,p)",
                notifState.statePath,
                payload
            ];
            saveProc.running = true;
        }
    }

    readonly property Process _saveProc: Process {
        id: saveProc
    }

    readonly property Process _loadProc: Process {
        id: loadProc
        command: ["cat", notifState.statePath]
        stdout: StdioCollector {
            id: loadCollector
            onStreamFinished: {
                notifState._loaded = true;
                if (loadCollector.text) {
                    notifState._loadFromJson(loadCollector.text);
                }
            }
        }
    }

    Component.onCompleted: {
        loadProc.running = true;
    }
}
