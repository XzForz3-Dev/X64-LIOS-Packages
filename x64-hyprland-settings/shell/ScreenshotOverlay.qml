import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// =============================================================================
// X64 LIOS - Native Multi-Monitor Freeze-Frame Screenshot Overlay
// Displays an instant frozen PNG captured per-monitor in tmpfs RAM (0 motion,
// freezes videos, animations, tooltips & popups). Theme-accent selection box,
// live physical pixel dimensions (W x H px), Esc/Right-Click cancel, Enter full.
// =============================================================================
PanelWindow {
    id: shotWin

    property bool active: false
    property bool isFocusedMonitor: false
    property string freezeDir: ""
    property string freezeToken: ""
    property string activeDragMonitor: ""

    signal dragBegan(string monName)
    signal regionSelected(string monName, real nx, real ny, real nw, real nh)
    signal fullMonitorSelected(string monName)
    signal cancelRequested()

    readonly property string monName: (shotWin.screen && shotWin.screen.name) ? shotWin.screen.name : ""
    readonly property string freezeUrl: (shotWin.active && shotWin.freezeDir !== "" && shotWin.monName !== "")
        ? ("file://" + shotWin.freezeDir + "/freeze-" + shotWin.monName + ".png?t=" + shotWin.freezeToken)
        : ""

    property bool dragging: false
    property real startX: 0
    property real startY: 0
    property real curX: 0
    property real curY: 0

    readonly property real selX: Math.min(startX, curX)
    readonly property real selY: Math.min(startY, curY)
    readonly property real selW: Math.abs(curX - startX)
    readonly property real selH: Math.abs(curY - startY)
    readonly property bool hasSelection: dragging && selW >= 4 && selH >= 4

    // Physical pixel dimensions (accurate even under fractional scaling 125%/150%)
    readonly property int physW: {
        var iw = frozenImg.implicitWidth > 0 ? frozenImg.implicitWidth : shotWin.width;
        return Math.max(1, Math.round(selW * iw / Math.max(1, shotWin.width)));
    }
    readonly property int physH: {
        var ih = frozenImg.implicitHeight > 0 ? frozenImg.implicitHeight : shotWin.height;
        return Math.max(1, Math.round(selH * ih / Math.max(1, shotWin.height)));
    }

    visible: active

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

    color: "#000000"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screenshot-freeze"
    WlrLayershell.keyboardFocus: (shotWin.active && (shotWin.isFocusedMonitor || shotWin.activeDragMonitor === shotWin.monName))
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    onActiveChanged: {
        dragging = false;
        startX = 0; startY = 0; curX = 0; curY = 0;
        if (active && isFocusedMonitor) {
            keyCatcher.forceActiveFocus();
        }
    }

    // 1. Frozen Per-Monitor Frame (100% sharp original pixels from tmpfs)
    Image {
        id: frozenImg
        anchors.fill: parent
        source: shotWin.freezeUrl
        cache: false
        asynchronous: false
        smooth: false
        fillMode: Image.Stretch
    }

    // 2. Darkening Scrim: full subtle dim when idle, 4-panel cutout around selection while dragging
    readonly property color veilColor: "#8805060b"

    // Idle dim (no active selection on this monitor)
    Rectangle {
        anchors.fill: parent
        visible: !shotWin.hasSelection
        color: (shotWin.activeDragMonitor !== "" && shotWin.activeDragMonitor !== shotWin.monName)
            ? "#aa05060b"
            : "#6205060b"
    }

    // Active cutout veil: Top, Bottom, Left, Right around clear selection window
    Rectangle {
        visible: shotWin.hasSelection
        x: 0; y: 0
        width: shotWin.width
        height: Math.max(0, shotWin.selY)
        color: shotWin.veilColor
    }
    Rectangle {
        visible: shotWin.hasSelection
        x: 0; y: shotWin.selY + shotWin.selH
        width: shotWin.width
        height: Math.max(0, shotWin.height - (shotWin.selY + shotWin.selH))
        color: shotWin.veilColor
    }
    Rectangle {
        visible: shotWin.hasSelection
        x: 0; y: shotWin.selY
        width: Math.max(0, shotWin.selX)
        height: shotWin.selH
        color: shotWin.veilColor
    }
    Rectangle {
        visible: shotWin.hasSelection
        x: shotWin.selX + shotWin.selW
        y: shotWin.selY
        width: Math.max(0, shotWin.width - (shotWin.selX + shotWin.selW))
        height: shotWin.selH
        color: shotWin.veilColor
    }

    // 3. Crisp Theme-Accent Selection Frame + Corner L-Accents
    Rectangle {
        id: selBox
        visible: shotWin.hasSelection
        x: shotWin.selX
        y: shotWin.selY
        width: shotWin.selW
        height: shotWin.selH
        color: "transparent"
        border.color: Theme.accent
        border.width: 2

        // Subtle 4 corner precision handles
        Rectangle { width: 8; height: 2; color: Theme.accentLight; anchors.top: parent.top; anchors.left: parent.left; anchors.topMargin: -1; anchors.leftMargin: -1 }
        Rectangle { width: 2; height: 8; color: Theme.accentLight; anchors.top: parent.top; anchors.left: parent.left; anchors.topMargin: -1; anchors.leftMargin: -1 }

        Rectangle { width: 8; height: 2; color: Theme.accentLight; anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: -1; anchors.rightMargin: -1 }
        Rectangle { width: 2; height: 8; color: Theme.accentLight; anchors.top: parent.top; anchors.right: parent.right; anchors.topMargin: -1; anchors.rightMargin: -1 }

        Rectangle { width: 8; height: 2; color: Theme.accentLight; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.bottomMargin: -1; anchors.leftMargin: -1 }
        Rectangle { width: 2; height: 8; color: Theme.accentLight; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.bottomMargin: -1; anchors.leftMargin: -1 }

        Rectangle { width: 8; height: 2; color: Theme.accentLight; anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.bottomMargin: -1; anchors.rightMargin: -1 }
        Rectangle { width: 2; height: 8; color: Theme.accentLight; anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.bottomMargin: -1; anchors.rightMargin: -1 }
    }

    // 4. Floating Live Pixel Dimension Badge (e.g. "842 × 510 px")
    Rectangle {
        id: dimPill
        visible: shotWin.hasSelection
        implicitWidth: dimTxt.implicitWidth + 18
        implicitHeight: 24
        radius: 8
        color: Theme.bgGlass
        border.color: Theme.borderAccent
        border.width: 1
        x: Math.max(8, Math.min(shotWin.width - width - 8, shotWin.selX))
        y: shotWin.selY >= 34 ? (shotWin.selY - 30) : (shotWin.selY + 8)

        Text {
            id: dimTxt
            anchors.centerIn: parent
            text: shotWin.physW + " × " + shotWin.physH + " px"
            font.family: Theme.fontMono
            font.pixelSize: 10
            font.bold: true
            color: Theme.textPrimary
        }
    }

    // 5. Top-Center Subtle Hint Capsule (sits cleanly below 40px top bar; hides while dragging)
    Rectangle {
        visible: shotWin.active && shotWin.isFocusedMonitor && !shotWin.dragging && shotWin.activeDragMonitor === ""
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 52
        implicitWidth: hintRow.implicitWidth + 24
        implicitHeight: 34
        radius: 17
        color: Theme.bgGlass
        border.color: Theme.borderGlass
        border.width: 1

        RowLayout {
            id: hintRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 7
                height: 7
                radius: 3.5
                color: Theme.accent
            }

            Text {
                text: I18n.shotFreezeHint
                font.family: Theme.fontSans
                font.pixelSize: 11
                font.weight: Font.Medium
                color: Theme.textPrimary
            }
        }
    }

    // 6. Keyboard Controls (Esc = cancel, Enter/Space = capture full monitor)
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: shotWin.active

        Keys.onEscapePressed: shotWin.cancelRequested()
        Keys.onReturnPressed: shotWin.fullMonitorSelected(shotWin.monName)
        Keys.onEnterPressed: shotWin.fullMonitorSelected(shotWin.monName)
        Keys.onSpacePressed: shotWin.fullMonitorSelected(shotWin.monName)
    }

    // 7. Fullscreen Crosshair Drag Area
    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor
        hoverEnabled: true

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                shotWin.cancelRequested();
                return;
            }
            shotWin.startX = mouse.x;
            shotWin.startY = mouse.y;
            shotWin.curX = mouse.x;
            shotWin.curY = mouse.y;
            shotWin.dragging = true;
            shotWin.dragBegan(shotWin.monName);
        }

        onPositionChanged: (mouse) => {
            if (!shotWin.dragging) return;
            shotWin.curX = Math.max(0, Math.min(shotWin.width, mouse.x));
            shotWin.curY = Math.max(0, Math.min(shotWin.height, mouse.y));
        }

        onReleased: (mouse) => {
            if (mouse.button !== Qt.LeftButton || !shotWin.dragging) return;
            shotWin.curX = Math.max(0, Math.min(shotWin.width, mouse.x));
            shotWin.curY = Math.max(0, Math.min(shotWin.height, mouse.y));
            var rx = shotWin.selX;
            var ry = shotWin.selY;
            var rw = shotWin.selW;
            var rh = shotWin.selH;
            shotWin.dragging = false;

            if (rw >= 6 && rh >= 6) {
                var w = Math.max(1, shotWin.width);
                var h = Math.max(1, shotWin.height);
                shotWin.regionSelected(shotWin.monName, rx / w, ry / h, rw / w, rh / h);
            }
        }
    }
}
