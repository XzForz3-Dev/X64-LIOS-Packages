import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

// =============================================================================
// X64 LIOS - X64 Theme Studio (SUPER + T)
// Cinematic 3D coverflow theme, palette, wallpaper & live video studio.
// - Live muted video preview ONLY on the centered card (0 background overhead).
// - Theme backgrounds + "Mis fondos" tab + Dolphin folder access.
// - Live accent override chips + video/battery/scope/transition controls.
// - Full keyboard navigation: Left/Right, Up/Down, Enter, R (Random), Esc.
// =============================================================================
PanelWindow {
    id: studioWindow

    signal closeRequested()

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
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-theme-studio"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    property var themesList: []
    property var userBgsList: []
    property string userBgDir: ""
    property string bgTab: "theme" // "theme" | "user"
    property string applyScope: "ALL" // "ALL" | current monitor name
    property int selectedBgIndex: -1
    property string previewOverridePath: ""
    property bool previewOverrideIsVideo: false
    property string previewOverrideThumb: ""
    property bool loading: false
    property bool applying: false
    property string statusToast: ""
    property var _cmdQueue: []

    readonly property string screenName: (studioWindow.screen && studioWindow.screen.name) ? studioWindow.screen.name : ""
    readonly property bool multiMonitor: Quickshell.screens.length > 1

    readonly property var currentThemeObj: {
        if (!themesList || themesList.length === 0) return null;
        var idx = themeCarousel.currentIndex;
        if (idx < 0 || idx >= themesList.length) idx = 0;
        return themesList[idx];
    }

    readonly property var currentBgsModel: {
        if (bgTab === "user") return userBgsList || [];
        return (currentThemeObj && currentThemeObj.backgrounds) ? currentThemeObj.backgrounds : [];
    }

    readonly property string focusedAccent: (currentThemeObj && currentThemeObj.palette && currentThemeObj.palette.accent)
        ? currentThemeObj.palette.accent : Theme.accent

    function _fileUrl(p) {
        if (!p || p === "") return "";
        if (p.indexOf("file://") === 0) return p;
        return "file://" + p;
    }

    function showToast(msg) {
        studioWindow.statusToast = msg;
        toastClearTimer.restart();
    }

    function closeAnimated() {
        if (closeAnim.running) return;
        closeAnim.restart();
    }

    function refreshCatalog() {
        if (listProc.running) return;
        studioWindow.loading = true;
        listProc.running = true;
    }

    function _syncSelectionToTheme(tObj) {
        studioWindow.previewOverridePath = "";
        studioWindow.previewOverrideIsVideo = false;
        studioWindow.previewOverrideThumb = "";
        studioWindow.selectedBgIndex = -1;
        if (!tObj || !tObj.backgrounds || tObj.backgrounds.length === 0) return;
        // 1. Highlight currently active background if it belongs to this theme
        var curBg = ThemeState.backgroundPath;
        for (var i = 0; i < tObj.backgrounds.length; i++) {
            if (tObj.backgrounds[i].path === curBg) {
                studioWindow.selectedBgIndex = i;
                return;
            }
        }
        // 2. Otherwise highlight theme's configured defaultBackground (matching hero card preview!)
        if (tObj.defaultBackground) {
            for (var j = 0; j < tObj.backgrounds.length; j++) {
                if (tObj.backgrounds[j].name === tObj.defaultBackground) {
                    studioWindow.selectedBgIndex = j;
                    return;
                }
            }
        }
        studioWindow.selectedBgIndex = 0;
    }

    function selectBackgroundItem(idx) {
        var list = studioWindow.currentBgsModel;
        if (!list || idx < 0 || idx >= list.length) return;
        studioWindow.selectedBgIndex = idx;
        var item = list[idx];
        studioWindow.previewOverridePath = item.path || "";
        studioWindow.previewOverrideIsVideo = Boolean(item.isVideo);
        studioWindow.previewOverrideThumb = item.thumb || item.path || "";
    }

    function applyCurrentSelection(originX, originY) {
        if (!currentThemeObj) return;
        ThemeState.setWaveOrigin(originX !== undefined ? originX : 0.5, originY !== undefined ? originY : 0.42);
        var args = ["/usr/bin/x64-theme", "apply", currentThemeObj.id];
        var chosenBg = "";
        var chosenIsVideo = false;
        if (studioWindow.previewOverridePath !== "") {
            chosenBg = studioWindow.previewOverridePath;
            chosenIsVideo = studioWindow.previewOverrideIsVideo;
        } else if (studioWindow.bgTab === "theme" && studioWindow.selectedBgIndex >= 0 && currentThemeObj.backgrounds && studioWindow.selectedBgIndex < currentThemeObj.backgrounds.length) {
            chosenBg = currentThemeObj.backgrounds[studioWindow.selectedBgIndex].path;
            chosenIsVideo = Boolean(currentThemeObj.backgrounds[studioWindow.selectedBgIndex].isVideo);
        }
        if (chosenBg !== "") {
            args.push("--bg");
            args.push(chosenBg);
        }
        if (studioWindow.applyScope !== "ALL" && studioWindow.applyScope !== "") {
            args.push("--monitor");
            args.push(studioWindow.applyScope);
        }
        var label = currentThemeObj.name || currentThemeObj.id;
        var hint = "";
        if (chosenIsVideo && !ThemeState.videoEnabled) {
            hint = I18n.isEs ? " (póster • activa Vídeo animado para movimiento)" : " (poster • enable Live video for motion)";
        } else if (chosenIsVideo && ThemeState.videoEnabled) {
            hint = I18n.isEs ? " • vídeo animado activo" : " • live video active";
        }
        runThemeCmd(args, (I18n.isEs ? "✓ Aplicado: " : "✓ Applied: ") + label + hint);
    }

    function applyBackgroundDirectly(item) {
        if (!item || !item.path) return;
        ThemeState.setWaveOrigin(0.5, 0.72);
        var isVid = Boolean(item.isVideo);
        var hint = "";
        if (isVid && !ThemeState.videoEnabled) {
            hint = I18n.isEs ? " (póster • activa Vídeo animado)" : " (poster • enable Live video)";
        } else if (isVid && ThemeState.videoEnabled) {
            hint = I18n.isEs ? " • vídeo activo" : " • live video";
        }
        if (currentThemeObj && currentThemeObj.id !== ThemeState.themeId && studioWindow.bgTab === "theme") {
            var args = ["/usr/bin/x64-theme", "apply", currentThemeObj.id, "--bg", item.path];
            if (studioWindow.applyScope !== "ALL" && studioWindow.applyScope !== "") {
                args.push("--monitor");
                args.push(studioWindow.applyScope);
            }
            runThemeCmd(args, (I18n.isEs ? "✓ Fondo aplicado: " : "✓ Wallpaper applied: ") + (item.name || "") + hint);
        } else {
            var bgArgs = ["/usr/bin/x64-theme", "set-bg", item.path];
            if (studioWindow.applyScope !== "ALL" && studioWindow.applyScope !== "") {
                bgArgs.push("--monitor");
                bgArgs.push(studioWindow.applyScope);
            }
            runThemeCmd(bgArgs, (I18n.isEs ? "✓ Fondo aplicado: " : "✓ Wallpaper applied: ") + (item.name || "") + hint);
        }
    }

    function applyRandomTheme() {
        if (!themesList || themesList.length === 0) return;
        var candidates = [];
        for (var i = 0; i < themesList.length; i++) {
            if (themesList[i].id !== ThemeState.themeId) candidates.push(i);
        }
        var pickIdx = candidates.length > 0
            ? candidates[Math.floor(Math.random() * candidates.length)]
            : 0;
        themeCarousel.currentIndex = pickIdx;
        ThemeState.setWaveOrigin(0.5, 0.42);
        runThemeCmd(
            ["/usr/bin/x64-theme", "apply", themesList[pickIdx].id],
            (I18n.isEs ? "✓ Tema aleatorio: " : "✓ Random theme: ") + (themesList[pickIdx].name || themesList[pickIdx].id)
        );
    }

    function _drainCmdQueue() {
        if (actionProc.running || studioWindow._cmdQueue.length === 0) return;
        var q = studioWindow._cmdQueue.slice();
        var nextItem = q.shift();
        studioWindow._cmdQueue = q;
        studioWindow.applying = true;
        actionProc._pendingToast = nextItem.toast || "";
        actionProc.command = nextItem.args;
        actionProc.running = true;
    }

    // Sequential non-destructive command queue: NEVER kills an in-flight x64-theme
    // (e.g., clicking "Vídeo animado ON" then immediately clicking "Aplicar tema").
    function runThemeCmd(cmdArgs, toastMsg) {
        var q = studioWindow._cmdQueue.slice();
        q.push({ args: cmdArgs, toast: toastMsg || "" });
        studioWindow._cmdQueue = q;
        _drainCmdQueue();
    }

    function openUserFolder() {
        var dir = studioWindow.userBgDir || (Quickshell.env("HOME") + "/Imágenes/Wallpapers");
        if (folderProc.running) folderProc.running = false;
        folderProc.command = ["bash", "-c", "mkdir -p \"$1\" && setsid -f dolphin \"$1\" >/dev/null 2>&1", "_", dir];
        folderProc.running = true;
    }

    Timer {
        id: toastClearTimer
        interval: 3400
        repeat: false
        onTriggered: studioWindow.statusToast = ""
    }

    Process {
        id: listProc
        command: ["/usr/bin/x64-theme", "list"]
        stdout: StdioCollector {
            id: listCollector
            onStreamFinished: {
                studioWindow.loading = false;
                if (!listCollector.text) return;
                try {
                    var d = JSON.parse(listCollector.text.trim());
                    if (d.themes) studioWindow.themesList = d.themes;
                    if (d.userBackgrounds) studioWindow.userBgsList = d.userBackgrounds;
                    if (d.userBgDir) studioWindow.userBgDir = d.userBgDir;

                    // Center carousel on currently active theme
                    var activeIdx = 0;
                    for (var i = 0; i < studioWindow.themesList.length; i++) {
                        if (studioWindow.themesList[i].id === ThemeState.themeId) {
                            activeIdx = i;
                            break;
                        }
                    }
                    themeCarousel.currentIndex = activeIdx;
                    studioWindow._syncSelectionToTheme(studioWindow.themesList[activeIdx]);
                } catch (e) {}
            }
        }
    }

    Process {
        id: actionProc
        property string _pendingToast: ""
        stderr: SplitParser {
            onRead: (data) => {
                if (data && data.trim() !== "") {
                    console.warn("[X64 ThemeStudio] x64-theme stderr:", data.trim());
                }
            }
        }
        onExited: (code, status) => {
            // Belt-and-suspenders: always force ThemeState reload after x64-theme completes
            ThemeState.reload();
            if (code === 0 && _pendingToast !== "") {
                studioWindow.showToast(_pendingToast);
            } else if (code !== 0) {
                console.warn("[X64 ThemeStudio] x64-theme exited with code", code, "cmd:", JSON.stringify(command));
                studioWindow.showToast(I18n.isEs ? "⚠ Error aplicando tema (código " + code + ")" : "⚠ Theme error (code " + code + ")");
            }
            _pendingToast = "";
            if (studioWindow._cmdQueue.length > 0) {
                studioWindow._drainCmdQueue();
            } else {
                studioWindow.applying = false;
            }
        }
    }

    Process {
        id: folderProc
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation {
            target: studioCard
            property: "scale"
            from: 0.90
            to: 1.0
            duration: 280
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
        NumberAnimation {
            target: studioCard
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: scrim
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation {
            target: studioCard
            property: "scale"
            to: 0.93
            duration: 140
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: studioCard
            property: "opacity"
            to: 0.0
            duration: 130
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: scrim
            property: "opacity"
            to: 0.0
            duration: 130
            easing.type: Easing.InQuad
        }
        onFinished: studioWindow.closeRequested()
    }

    onVisibleChanged: {
        if (visible) {
            studioWindow.applyScope = "ALL";
            studioWindow.statusToast = "";
            studioCard.scale = 0.90;
            studioCard.opacity = 0.0;
            scrim.opacity = 0.0;
            keyFocusHost.forceActiveFocus();
            studioWindow.refreshCatalog();
            openAnim.restart();
        } else {
            studioCard.scale = 1.0;
            studioCard.opacity = 1.0;
            scrim.opacity = 1.0;
        }
    }

    // Dimmed Obsidian Scrim (click outside to dismiss — light enough to admire live wallpaper wave)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "#8c040509"

        MouseArea {
            anchors.fill: parent
            onClicked: studioWindow.closeAnimated()
        }
    }

    // Keyboard Controller (Full Keyboard Navigation)
    FocusScope {
        id: keyFocusHost
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: studioWindow.closeAnimated()
        Keys.onLeftPressed: {
            if (themesList.length > 0) themeCarousel.decrementCurrentIndex();
        }
        Keys.onRightPressed: {
            if (themesList.length > 0) themeCarousel.incrementCurrentIndex();
        }
        Keys.onUpPressed: {
            var n = studioWindow.currentBgsModel.length;
            if (n > 0) {
                var prev = studioWindow.selectedBgIndex <= 0 ? (n - 1) : (studioWindow.selectedBgIndex - 1);
                studioWindow.selectBackgroundItem(prev);
                bgStrip.positionViewAtIndex(prev, ListView.Contain);
            }
        }
        Keys.onDownPressed: {
            var n = studioWindow.currentBgsModel.length;
            if (n > 0) {
                var nxt = (studioWindow.selectedBgIndex + 1) % n;
                studioWindow.selectBackgroundItem(nxt);
                bgStrip.positionViewAtIndex(nxt, ListView.Contain);
            }
        }
        Keys.onReturnPressed: studioWindow.applyCurrentSelection(0.5, 0.42)
        Keys.onEnterPressed: studioWindow.applyCurrentSelection(0.5, 0.42)
        Keys.onPressed: (ev) => {
            if (ev.key === Qt.Key_R) {
                studioWindow.applyRandomTheme();
                ev.accepted = true;
            }
        }

        // Main Centered Studio Console
        Rectangle {
            id: studioCard
            anchors.centerIn: parent
            width: Math.min(1140, parent.width - 72)
            height: Math.min(680, parent.height - 76)
            radius: 20
            color: Theme.bgGlass
            border.color: Theme.accentBorder
            border.width: 1
            layer.enabled: openAnim.running || closeAnim.running
            layer.smooth: true
            clip: true

            // Swallow clicks inside the console
            MouseArea { anchors.fill: parent }

            // Top specular highlight + accent hairline
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: Theme.accent }
                    GradientStop { position: 0.7; color: Theme.accentHover }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // =============================================================
                // 1. HEADER BAR
                // =============================================================
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        implicitWidth: 32
                        implicitHeight: 32
                        radius: 10
                        color: Theme.accentDim
                        border.color: Theme.accentBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰏘"
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                            color: Theme.accent
                        }
                    }

                    ColumnLayout {
                        spacing: 1

                        RowLayout {
                            spacing: 8
                            Text {
                                text: "X64 THEME STUDIO"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                font.bold: true
                                font.letterSpacing: 1.4
                                color: Theme.textPrimary
                            }
                            Rectangle {
                                implicitHeight: 18
                                implicitWidth: activeBadgeTxt.implicitWidth + 12
                                radius: 9
                                color: Theme.accentDim
                                border.color: Theme.accentBorder
                                border.width: 1
                                Text {
                                    id: activeBadgeTxt
                                    anchors.centerIn: parent
                                    text: ThemeState.themeName.toUpperCase()
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    font.letterSpacing: 0.6
                                    color: Theme.accent
                                }
                            }
                        }

                        Text {
                            text: I18n.isEs
                                ? (studioWindow.themesList.length + " temas X64 oficiales • Fondos estáticos y vídeos acelerados por GPU")
                                : (studioWindow.themesList.length + " official X64 themes • GPU static & animated wallpapers")
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            color: Theme.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Live Feedback Status Pill (visible briefly after Apply / Video / Accent action)
                    Rectangle {
                        visible: studioWindow.statusToast !== "" || studioWindow.applying
                        implicitHeight: 28
                        implicitWidth: Math.min(340, toastTxt.implicitWidth + 20)
                        radius: 14
                        color: Theme.accentDim
                        border.color: Theme.accentBorder
                        border.width: 1

                        Text {
                            id: toastTxt
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: studioWindow.statusToast !== ""
                                ? studioWindow.statusToast
                                : (I18n.isEs ? "Aplicando…" : "Applying…")
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }

                    // Randomize Button (R)
                    Rectangle {
                        implicitHeight: 30
                        implicitWidth: rndRow.implicitWidth + 18
                        radius: 15
                        color: rndArea.containsMouse ? Theme.accentDim : Theme.bgCard
                        border.color: rndArea.containsMouse ? Theme.accentBorder : Theme.borderSubtle
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 140 } }

                        RowLayout {
                            id: rndRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text { text: "󰒝"; font.family: Theme.fontMono; font.pixelSize: 12; color: Theme.accent }
                            Text {
                                text: I18n.isEs ? "Aleatorio (R)" : "Random (R)"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: rndArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: studioWindow.applyRandomTheme()
                        }
                    }

                    // Close Button (ESC)
                    Rectangle {
                        implicitHeight: 30
                        implicitWidth: 52
                        radius: 15
                        color: escArea.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: Theme.borderSubtle
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "ESC"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textSecondary
                        }

                        MouseArea {
                            id: escArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: studioWindow.closeAnimated()
                        }
                    }
                }

                // =============================================================
                // 2. HERO 3D COVERFLOW CAROUSEL
                // =============================================================
                Item {
                    id: carouselSection
                    Layout.fillWidth: true
                    Layout.preferredHeight: 286

                    // Subtle Ambient Glow aligned behind centered theme card
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: carouselSection.height * 0.46 - height / 2
                        width: 462
                        height: 268
                        radius: 22
                        color: studioWindow.focusedAccent
                        opacity: 0.14
                        Behavior on color { ColorAnimation { duration: 280 } }
                    }

                    PathView {
                        id: themeCarousel
                        anchors.fill: parent
                        model: studioWindow.themesList
                        pathItemCount: Math.min(5, Math.max(1, studioWindow.themesList.length))
                        preferredHighlightBegin: 0.5
                        preferredHighlightEnd: 0.5
                        highlightRangeMode: PathView.StrictlyEnforceRange
                        highlightMoveDuration: 340
                        snapMode: PathView.SnapToItem
                        interactive: false
                        clip: false

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0 && currentIndex < studioWindow.themesList.length) {
                                studioWindow._syncSelectionToTheme(studioWindow.themesList[currentIndex]);
                            }
                        }

                        path: Path {
                            startX: 90
                            startY: carouselSection.height * 0.48
                            PathAttribute { name: "cardScale"; value: 0.62 }
                            PathAttribute { name: "cardOpacity"; value: 0.30 }
                            PathAttribute { name: "cardZ"; value: 1 }
                            PathAttribute { name: "cardAngle"; value: 36 }

                            PathLine { x: carouselSection.width * 0.25; y: carouselSection.height * 0.48 }
                            PathAttribute { name: "cardScale"; value: 0.80 }
                            PathAttribute { name: "cardOpacity"; value: 0.68 }
                            PathAttribute { name: "cardZ"; value: 5 }
                            PathAttribute { name: "cardAngle"; value: 24 }

                            PathLine { x: carouselSection.width * 0.50; y: carouselSection.height * 0.46 }
                            PathAttribute { name: "cardScale"; value: 1.0 }
                            PathAttribute { name: "cardOpacity"; value: 1.0 }
                            PathAttribute { name: "cardZ"; value: 20 }
                            PathAttribute { name: "cardAngle"; value: 0 }

                            PathLine { x: carouselSection.width * 0.75; y: carouselSection.height * 0.48 }
                            PathAttribute { name: "cardScale"; value: 0.80 }
                            PathAttribute { name: "cardOpacity"; value: 0.68 }
                            PathAttribute { name: "cardZ"; value: 5 }
                            PathAttribute { name: "cardAngle"; value: -24 }

                            PathLine { x: carouselSection.width - 90; y: carouselSection.height * 0.48 }
                            PathAttribute { name: "cardScale"; value: 0.62 }
                            PathAttribute { name: "cardOpacity"; value: 0.30 }
                            PathAttribute { name: "cardZ"; value: 1 }
                            PathAttribute { name: "cardAngle"; value: -36 }
                        }

                        delegate: Item {
                            id: cardWrapper
                            required property var modelData
                            required property int index

                            readonly property bool isCurrent: PathView.isCurrentItem
                            readonly property bool isActiveTheme: modelData.id === ThemeState.themeId
                            readonly property color cardAccent: (modelData.palette && modelData.palette.accent) ? modelData.palette.accent : Theme.accent
                            readonly property color cardBg: (modelData.palette && modelData.palette.background) ? modelData.palette.background : Theme.bgDark

                            // Resolve live preview asset (respects hovered/selected strip bg on focused card)
                            readonly property string effectiveMediaPath: {
                                if (isCurrent && studioWindow.previewOverridePath !== "") {
                                    return studioWindow.previewOverridePath;
                                }
                                if (modelData.backgrounds && modelData.backgrounds.length > 0) {
                                    // Prefer theme defaultBackground if listed
                                    if (modelData.defaultBackground) {
                                        for (var i = 0; i < modelData.backgrounds.length; i++) {
                                            if (modelData.backgrounds[i].name === modelData.defaultBackground) {
                                                return modelData.backgrounds[i].path;
                                            }
                                        }
                                    }
                                    return modelData.backgrounds[0].path;
                                }
                                return modelData.preview || "";
                            }

                            readonly property bool effectiveIsVideo: {
                                if (isCurrent && studioWindow.previewOverridePath !== "") {
                                    return studioWindow.previewOverrideIsVideo;
                                }
                                var p = effectiveMediaPath.toLowerCase();
                                return p.endsWith(".mp4") || p.endsWith(".webm") || p.endsWith(".mkv");
                            }

                            readonly property string posterImageUrl: {
                                if (isCurrent && studioWindow.previewOverridePath !== "") {
                                    return studioWindow._fileUrl(studioWindow.previewOverrideThumb || modelData.preview);
                                }
                                return studioWindow._fileUrl(modelData.preview || "");
                            }

                            width: 446
                            height: 254
                            scale: PathView.cardScale !== undefined ? PathView.cardScale : 1.0
                            opacity: PathView.cardOpacity !== undefined ? PathView.cardOpacity : 1.0
                            z: PathView.cardZ !== undefined ? PathView.cardZ : 1

                            transform: Rotation {
                                origin.x: cardWrapper.width / 2
                                origin.y: cardWrapper.height / 2
                                axis { x: 0; y: 1; z: 0 }
                                angle: cardWrapper.PathView.cardAngle !== undefined ? cardWrapper.PathView.cardAngle : 0
                            }

                            Rectangle {
                                id: themeCardRect
                                anchors.fill: parent
                                radius: 16
                                color: cardWrapper.cardBg
                                border.color: cardWrapper.isCurrent ? cardWrapper.cardAccent : Theme.borderGlass
                                border.width: cardWrapper.isCurrent ? 2 : 1
                                clip: true

                                // Poster Image (always immediate, zero black frame)
                                Image {
                                    anchors.fill: parent
                                    source: cardWrapper.posterImageUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    sourceSize.width: 480
                                    sourceSize.height: 270
                                }

                                // Live Muted Video Preview — ACTIVE ONLY ON CENTER FOCUSED CARD
                                Loader {
                                    id: liveVideoLoader
                                    anchors.fill: parent
                                    active: studioWindow.visible && cardWrapper.isCurrent && cardWrapper.effectiveIsVideo && cardWrapper.effectiveMediaPath !== ""
                                    sourceComponent: Item {
                                        anchors.fill: parent
                                        MediaPlayer {
                                            id: previewPlayer
                                            source: studioWindow._fileUrl(cardWrapper.effectiveMediaPath)
                                            loops: MediaPlayer.Infinite
                                            videoOutput: previewOutput
                                            audioOutput: AudioOutput { muted: true; volume: 0.0 }
                                            Component.onCompleted: play()
                                        }
                                        VideoOutput {
                                            id: previewOutput
                                            anchors.fill: parent
                                            fillMode: VideoOutput.PreserveAspectCrop
                                        }
                                    }
                                }

                                // Bottom Gradient Scrim for Crisp Typography
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: 112
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.45; color: "#c207080d" }
                                        GradientStop { position: 1.0; color: "#f207080d" }
                                    }
                                }

                                // Card click layer: sits cleanly above media, below top/bottom controls (z: 1)
                                MouseArea {
                                    anchors.fill: parent
                                    z: 1
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (cardWrapper.isCurrent) {
                                            studioWindow.applyCurrentSelection(0.5, 0.42);
                                        } else {
                                            themeCarousel.currentIndex = cardWrapper.index;
                                        }
                                    }
                                }

                                // Top Badges Row (Active / Animated / BG Count)
                                RowLayout {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    z: 5
                                    spacing: 6

                                    Rectangle {
                                        visible: cardWrapper.isActiveTheme
                                        implicitHeight: 20
                                        implicitWidth: actTxt.implicitWidth + 14
                                        radius: 10
                                        color: cardWrapper.cardAccent
                                        Text {
                                            id: actTxt
                                            anchors.centerIn: parent
                                            text: I18n.isEs ? "✓ ACTIVO" : "✓ ACTIVE"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: "#090a0e"
                                        }
                                    }

                                    Rectangle {
                                        visible: Boolean(cardWrapper.modelData.hasVideo)
                                        implicitHeight: 20
                                        implicitWidth: vidTxt.implicitWidth + 12
                                        radius: 10
                                        color: "#cc0c0e16"
                                        border.color: cardWrapper.cardAccent
                                        border.width: 1
                                        Text {
                                            id: vidTxt
                                            anchors.centerIn: parent
                                            text: I18n.isEs ? "󰕧 ANIMADO" : "󰕧 ANIMATED"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: "#ffffff"
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        implicitHeight: 20
                                        implicitWidth: cntTxt.implicitWidth + 12
                                        radius: 10
                                        color: "#bb0c0e16"
                                        border.color: "#28ffffff"
                                        border.width: 1
                                        Text {
                                            id: cntTxt
                                            anchors.centerIn: parent
                                            text: "󰋩 " + (cardWrapper.modelData.bgCount || 0)
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: "#e2e4ec"
                                        }
                                    }
                                }

                                // Bottom Theme Identity + 8 Palette Swatches + Apply CTA
                                RowLayout {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 12
                                    z: 6
                                    spacing: 10

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            text: cardWrapper.modelData.name || cardWrapper.modelData.id
                                            font.family: Theme.fontSans
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: "#ffffff"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: cardWrapper.modelData.description || cardWrapper.modelData.author || ""
                                            font.family: Theme.fontSans
                                            font.pixelSize: 10
                                            color: "#b4b7c5"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // 8-Dot Theme Palette Preview
                                        RowLayout {
                                            spacing: 5
                                            Repeater {
                                                model: cardWrapper.modelData.swatches || []
                                                Rectangle {
                                                    implicitWidth: 11
                                                    implicitHeight: 11
                                                    radius: 6
                                                    color: modelData
                                                    border.color: "#55ffffff"
                                                    border.width: 1
                                                }
                                            }
                                        }
                                    }

                                    // Apply CTA Button (only prominent on centered card)
                                    Rectangle {
                                        visible: cardWrapper.isCurrent
                                        implicitHeight: 32
                                        implicitWidth: applyBtnTxt.implicitWidth + 24
                                        radius: 16
                                        color: applyBtnArea.containsMouse ? cardWrapper.cardAccent : Qt.rgba(cardWrapper.cardAccent.r, cardWrapper.cardAccent.g, cardWrapper.cardAccent.b, 0.25)
                                        border.color: cardWrapper.cardAccent
                                        border.width: 1.5
                                        Behavior on color { ColorAnimation { duration: 140 } }

                                        Text {
                                            id: applyBtnTxt
                                            anchors.centerIn: parent
                                            text: cardWrapper.isActiveTheme
                                                ? (I18n.isEs ? "Reaplicar" : "Reapply")
                                                : (I18n.isEs ? "Aplicar tema" : "Apply Theme")
                                            font.family: Theme.fontSans
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: applyBtnArea.containsMouse ? "#090a0e" : "#ffffff"
                                        }

                                        MouseArea {
                                            id: applyBtnArea
                                            anchors.fill: parent
                                            z: 10
                                            hoverEnabled: true
                                            preventStealing: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: studioWindow.applyCurrentSelection(0.5, 0.42)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Non-blocking QtQuick 6 WheelHandler (never intercepts clicks on cards or CTA)
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: (w) => {
                            if (studioWindow.themesList.length === 0) return;
                            if (w.angleDelta.y > 0) themeCarousel.decrementCurrentIndex();
                            else if (w.angleDelta.y < 0) themeCarousel.incrementCurrentIndex();
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        z: 50
                        width: 36; height: 36; radius: 18
                        color: prevArea.containsMouse ? Theme.accentDim : "#dd0d0f17"
                        border.color: prevArea.containsMouse ? Theme.accentBorder : Theme.borderGlass
                        border.width: 1
                        Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 22; color: Theme.textPrimary }
                        MouseArea {
                            id: prevArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: themeCarousel.decrementCurrentIndex()
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        z: 50
                        width: 36; height: 36; radius: 18
                        color: nextArea.containsMouse ? Theme.accentDim : "#dd0d0f17"
                        border.color: nextArea.containsMouse ? Theme.accentBorder : Theme.borderGlass
                        border.width: 1
                        Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 22; color: Theme.textPrimary }
                        MouseArea {
                            id: nextArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: themeCarousel.incrementCurrentIndex()
                        }
                    }
                }

                // =============================================================
                // 3. BACKGROUNDS STRIP (THEME BACKGROUNDS + "MIS FONDOS" TAB)
                // =============================================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 128
                    radius: Theme.radiusMd
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            // Tabs: Theme Backgrounds | My Wallpapers
                            Repeater {
                                model: [
                                    { id: "theme", label: (I18n.isEs ? "Fondos del tema (" : "Theme Wallpapers (") + (studioWindow.currentThemeObj ? (studioWindow.currentThemeObj.bgCount || 0) : 0) + ")" },
                                    { id: "user",  label: (I18n.isEs ? "Mis fondos (" : "My Wallpapers (") + (studioWindow.userBgsList ? studioWindow.userBgsList.length : 0) + ")" }
                                ]

                                Rectangle {
                                    implicitHeight: 24
                                    implicitWidth: tabLbl.implicitWidth + 16
                                    radius: 12
                                    readonly property bool isAct: studioWindow.bgTab === modelData.id
                                    color: isAct ? Theme.accentDim : (tabArea.containsMouse ? Theme.bgHover : Theme.bgElevated)
                                    border.color: isAct ? Theme.accentBorder : Theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        id: tabLbl
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: parent.isAct ? Theme.textPrimary : Theme.textSecondary
                                    }

                                    MouseArea {
                                        id: tabArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            studioWindow.bgTab = modelData.id;
                                            studioWindow.selectedBgIndex = -1;
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Open Folder Button (Dolphin)
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: openDirRow.implicitWidth + 14
                                radius: 12
                                color: openDirArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                                border.color: Theme.borderSubtle
                                border.width: 1

                                RowLayout {
                                    id: openDirRow
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text { text: "󰉋"; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.accent }
                                    Text {
                                        text: I18n.isEs ? "Abrir carpeta" : "Open folder"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        color: Theme.textSecondary
                                    }
                                }

                                MouseArea {
                                    id: openDirArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioWindow.openUserFolder()
                                }
                            }

                            // Refresh Button
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: 24
                                radius: 12
                                color: refArea.containsMouse ? Theme.bgHover : Theme.bgElevated
                                border.color: Theme.borderSubtle
                                border.width: 1
                                Text { anchors.centerIn: parent; text: "󰑐"; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.textSecondary }
                                MouseArea {
                                    id: refArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioWindow.refreshCatalog()
                                }
                            }
                        }

                        // Thumbnails Horizontal List (or Empty State)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: bgStrip
                                anchors.fill: parent
                                orientation: ListView.Horizontal
                                spacing: 10
                                clip: true
                                visible: studioWindow.currentBgsModel.length > 0
                                model: studioWindow.currentBgsModel

                                delegate: Rectangle {
                                    id: bgThumb
                                    required property var modelData
                                    required property int index

                                    readonly property bool isSelected: index === studioWindow.selectedBgIndex
                                    readonly property bool isApplied: modelData.path === ThemeState.backgroundPath

                                    width: 132
                                    height: bgStrip.height
                                    radius: 10
                                    color: Theme.bgElevated
                                    border.color: (isSelected || thumbArea.containsMouse) ? Theme.accent : (isApplied ? Theme.accentBorder : Theme.borderSubtle)
                                    border.width: (isSelected || isApplied) ? 2 : 1
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: studioWindow._fileUrl(modelData.thumb || modelData.path)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        smooth: true
                                        sourceSize.width: 264
                                        sourceSize.height: 152
                                    }

                                    // Video play badge
                                    Rectangle {
                                        visible: Boolean(modelData.isVideo)
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 5
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: "#cc080a10"
                                        border.color: Theme.accent
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: "▶"
                                            font.pixelSize: 9
                                            color: "#ffffff"
                                        }
                                    }

                                    // Active check badge
                                    Rectangle {
                                        visible: bgThumb.isApplied
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.margins: 5
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: Theme.accent
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: "#090a0e"
                                        }
                                    }

                                    // Subtle filename footer
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 18
                                        color: "#aa07080d"
                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 6
                                            anchors.rightMargin: 6
                                            verticalAlignment: Text.AlignVCenter
                                            text: modelData.name || ""
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: "#e2e4ec"
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: thumbArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        preventStealing: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            studioWindow.selectBackgroundItem(bgThumb.index);
                                            studioWindow.applyBackgroundDirectly(bgThumb.modelData);
                                        }
                                    }
                                }
                            }

                            // Empty State Hint
                            RowLayout {
                                anchors.centerIn: parent
                                visible: studioWindow.currentBgsModel.length === 0
                                spacing: 8
                                Text {
                                    text: studioWindow.bgTab === "user"
                                        ? (I18n.isEs ? "Copia imágenes o vídeos (.jpg/.png/.webp/.mp4) en tu carpeta de wallpapers" : "Drop images or videos (.jpg/.png/.webp/.mp4) in your wallpapers folder")
                                        : (I18n.isEs ? "Este tema usa la paleta pura y el fondo base X64 (próximos fondos propios en 3.1-E)" : "This theme uses its pure palette and base X64 wallpaper")
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.textSecondary
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // 4. ACCENT CHIPS & QUICK OPTIONS BAR (2 CLEAN ROWS)
                // =============================================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 88
                    radius: Theme.radiusMd
                    color: Theme.bgCard
                    border.color: Theme.borderSubtle
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Row A: Live Accent Swatches
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: I18n.isEs ? "ACENTO" : "ACCENT"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 0.8
                                color: Theme.textSecondary
                            }

                            // Reset to theme's native accent
                            Rectangle {
                                implicitHeight: 24
                                implicitWidth: rstAccTxt.implicitWidth + 14
                                radius: 12
                                readonly property bool isNative: ThemeState.accentOverride === ""
                                color: isNative ? Theme.accentDim : Theme.bgElevated
                                border.color: isNative ? Theme.accentBorder : Theme.borderSubtle
                                border.width: 1
                                Text {
                                    id: rstAccTxt
                                    anchors.centerIn: parent
                                    text: I18n.isEs ? "Del tema" : "Theme default"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: parent.isNative ? Theme.textPrimary : Theme.textSecondary
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioWindow.runThemeCmd(["/usr/bin/x64-theme", "set-accent", "reset"])
                                }
                            }

                            Repeater {
                                model: [
                                    { hex: "#ff2b2b", label: "Crimson" },
                                    { hex: "#00f0ff", label: "Cyber" },
                                    { hex: "#a855f7", label: "Cosmic" },
                                    { hex: "#f59e0b", label: "Space" },
                                    { hex: "#00ff41", label: "Matrix" },
                                    { hex: "#ff71ce", label: "Vapor" },
                                    { hex: "#ffffff", label: "Titanium" }
                                ]

                                Rectangle {
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    radius: 11
                                    color: modelData.hex
                                    readonly property bool isSel: ThemeState.accentOverride.toLowerCase() === modelData.hex.toLowerCase()
                                    border.color: isSel ? "#ffffff" : "#44ffffff"
                                    border.width: isSel ? 2.5 : 1
                                    scale: accArea.containsMouse ? 1.15 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 120 } }

                                    MouseArea {
                                        id: accArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: studioWindow.runThemeCmd(["/usr/bin/x64-theme", "set-accent", modelData.hex])
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Transition Selector (Wave | Fade | Zoom)
                            Text {
                                text: I18n.isEs ? "TRANSICIÓN" : "TRANSITION"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textSecondary
                            }

                            Rectangle {
                                implicitHeight: 26
                                implicitWidth: transRow.implicitWidth + 6
                                radius: 8
                                color: Theme.bgElevated
                                border.color: Theme.borderSubtle
                                border.width: 1

                                RowLayout {
                                    id: transRow
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            { id: "wave", label: I18n.isEs ? "Onda" : "Wave" },
                                            { id: "fade", label: I18n.isEs ? "Fundido" : "Fade" },
                                            { id: "zoom", label: "Zoom" }
                                        ]
                                        Rectangle {
                                            implicitHeight: 22
                                            implicitWidth: trTxt.implicitWidth + 14
                                            radius: 6
                                            readonly property bool isAct: ThemeState.transition === modelData.id
                                            color: isAct ? Theme.accentDim : "transparent"
                                            border.color: isAct ? Theme.accentBorder : "transparent"
                                            border.width: 1
                                            Text {
                                                id: trTxt
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                font.family: Theme.fontMono
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: parent.isAct ? Theme.textPrimary : Theme.textSecondary
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: studioWindow.runThemeCmd(["/usr/bin/x64-theme", "transition", modelData.id])
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Row B: Video Enabled, Battery Poster & Multi-Monitor Scope
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Live Video Toggle
                            Rectangle {
                                implicitHeight: 26
                                implicitWidth: vidOptRow.implicitWidth + 16
                                radius: 8
                                color: ThemeState.videoEnabled ? Theme.accentDim : Theme.bgElevated
                                border.color: ThemeState.videoEnabled ? Theme.accentBorder : Theme.borderSubtle
                                border.width: 1

                                RowLayout {
                                    id: vidOptRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰕧"; font.family: Theme.fontMono; font.pixelSize: 12; color: ThemeState.videoEnabled ? Theme.accent : Theme.textSecondary }
                                    Text {
                                        text: (I18n.isEs ? "Vídeo animado: " : "Live video: ") + (ThemeState.videoEnabled ? "ON" : "OFF")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: ThemeState.videoEnabled ? Theme.textPrimary : Theme.textSecondary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var nextOn = !ThemeState.videoEnabled;
                                        studioWindow.runThemeCmd(
                                            ["/usr/bin/x64-theme", "video", nextOn ? "on" : "off"],
                                            nextOn
                                                ? (I18n.isEs ? "✓ Vídeo animado: ON" : "✓ Live video: ON")
                                                : (I18n.isEs ? "✓ Vídeo animado: OFF (póster)" : "✓ Live video: OFF (poster)")
                                        );
                                    }
                                }
                            }

                            // Battery Poster Toggle
                            Rectangle {
                                implicitHeight: 26
                                implicitWidth: batOptRow.implicitWidth + 16
                                radius: 8
                                color: ThemeState.batteryPoster ? Theme.accentDim : Theme.bgElevated
                                border.color: ThemeState.batteryPoster ? Theme.accentBorder : Theme.borderSubtle
                                border.width: 1

                                RowLayout {
                                    id: batOptRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "󰂄"; font.family: Theme.fontMono; font.pixelSize: 12; color: ThemeState.batteryPoster ? Theme.accent : Theme.textSecondary }
                                    Text {
                                        text: (I18n.isEs ? "Póster en batería: " : "Battery poster: ") + (ThemeState.batteryPoster ? "ON" : "OFF")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: ThemeState.batteryPoster ? Theme.textPrimary : Theme.textSecondary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: studioWindow.runThemeCmd(["/usr/bin/x64-theme", "battery-poster", ThemeState.batteryPoster ? "off" : "on"])
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Multi-Monitor Scope Selector (visible when >1 screen)
                            RowLayout {
                                visible: studioWindow.multiMonitor
                                spacing: 6

                                Text {
                                    text: I18n.isEs ? "APLICAR A" : "APPLY TO"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.textSecondary
                                }

                                Rectangle {
                                    implicitHeight: 26
                                    implicitWidth: scopeRow.implicitWidth + 6
                                    radius: 8
                                    color: Theme.bgElevated
                                    border.color: Theme.borderSubtle
                                    border.width: 1

                                    RowLayout {
                                        id: scopeRow
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Repeater {
                                            model: [
                                                { id: "ALL", label: I18n.isEs ? "Todos" : "All" },
                                                { id: studioWindow.screenName, label: studioWindow.screenName }
                                            ]
                                            Rectangle {
                                                implicitHeight: 22
                                                implicitWidth: scTxt.implicitWidth + 14
                                                radius: 6
                                                readonly property bool isAct: studioWindow.applyScope === modelData.id
                                                color: isAct ? Theme.accentDim : "transparent"
                                                border.color: isAct ? Theme.accentBorder : "transparent"
                                                border.width: 1
                                                Text {
                                                    id: scTxt
                                                    anchors.centerIn: parent
                                                    text: modelData.label
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: parent.isAct ? Theme.textPrimary : Theme.textSecondary
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: studioWindow.applyScope = modelData.id
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // 5. KEYBOARD HINTS FOOTER
                // =============================================================
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: I18n.isEs
                            ? "←/→ Temas   •   ↑/↓ Fondos   •   Enter Aplicar   •   R Aleatorio   •   Esc Cerrar"
                            : "←/→ Themes   •   ↑/↓ Wallpapers   •   Enter Apply   •   R Random   •   Esc Close"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }
            }
        }
    }
}
