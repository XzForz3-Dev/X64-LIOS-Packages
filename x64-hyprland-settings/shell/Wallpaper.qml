import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

// =============================================================================
// X64 LIOS - GPU-Accelerated Multi-Monitor Wallpaper Layer (Wallpaper.qml)
// Replaces swaybg on WlrLayer.Background across all connected displays.
// Supports 3 GPU transitions: wave (circular ripple + accent ring), fade, zoom.
// Hands off seamlessly to mpvpaper when live video mode is enabled (zero flash).
// =============================================================================
PanelWindow {
    id: wallWindow

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

    color: Theme.bgDark
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property string monName: (wallWindow.screen && wallWindow.screen.name) ? wallWindow.screen.name : ""
    readonly property string targetUrl: {
        var _rev = ThemeState.wallpaperRev;
        return ThemeState.wallpaperUrlFor(monName);
    }
    readonly property bool liveVideoWanted: {
        var _rev = ThemeState.wallpaperRev;
        return ThemeState.isLiveVideoFor(monName);
    }

    property bool videoSettled: false
    property string activeTransition: "wave"
    property real waveProgress: 0.0
    property bool transitioning: false
    property string pendingUrl: ""

    // Keep Wallpaper visible while static, transitioning, or during 450ms handoff to mpvpaper
    visible: !videoSettled

    onLiveVideoWantedChanged: {
        if (liveVideoWanted) {
            if (!transitioning) {
                videoHandoffTimer.restart();
            }
        } else {
            videoHandoffTimer.stop();
            videoSettled = false;
        }
    }

    Timer {
        id: videoHandoffTimer
        interval: 580
        repeat: false
        onTriggered: {
            if (wallWindow.liveVideoWanted && !wallWindow.transitioning) {
                wallWindow.videoSettled = true;
            }
        }
    }

    property int _loadToken: 0

    function _beginTransition(url) {
        if (!url || url === "") return;
        var resolved = Qt.resolvedUrl(url);
        if (baseImage.source == "" || String(baseImage.source) === "") {
            baseImage.source = resolved;
            if (liveVideoWanted) videoHandoffTimer.restart();
            return;
        }
        if (baseImage.source == resolved && !transitioning) {
            if (liveVideoWanted) videoHandoffTimer.restart();
            return;
        }
        // Make sure poster layer is visible for transition even if mpvpaper was previously active
        videoHandoffTimer.stop();
        videoSettled = false;
        pendingUrl = String(resolved);
        _loadToken = _loadToken + 1;
        activeTransition = ThemeState.transition || "wave";
        nextImage.opacity = 0.0;
        nextImage.source = "";
        nextImage.source = resolved;
        if (nextImage.status === Image.Ready) {
            _startTransitionAnim();
        }
    }

    function _startTransitionAnim() {
        transitioning = true;
        fadeAnim.stop();
        zoomAnim.stop();
        waveAnim.stop();

        if (activeTransition === "fade") {
            nextImage.scale = 1.0;
            nextImage.opacity = 0.0;
            fadeAnim.restart();
        } else if (activeTransition === "zoom") {
            nextImage.scale = 1.08;
            nextImage.opacity = 0.0;
            zoomAnim.restart();
        } else {
            // Default: signature GPU circular wave reveal
            nextImage.scale = 1.0;
            nextImage.opacity = 1.0;
            waveProgress = 0.0;
            waveAnim.restart();
        }
    }

    function _finishTransition() {
        if (pendingUrl !== "") {
            baseImage.source = pendingUrl;
        }
        pendingUrl = "";
        transitioning = false;
        waveProgress = 0.0;
        nextImage.opacity = 0.0;
        nextImage.scale = 1.0;
        if (liveVideoWanted) {
            videoHandoffTimer.restart();
        }
    }

    onTargetUrlChanged: _beginTransition(targetUrl)

    Component.onCompleted: {
        if (targetUrl !== "") {
            baseImage.source = Qt.resolvedUrl(targetUrl);
        }
        if (liveVideoWanted) {
            videoHandoffTimer.restart();
        }
    }

    readonly property int decodeWidth: Math.max(1, Math.round(wallWindow.screen ? wallWindow.screen.width : wallWindow.width))
    readonly property int decodeHeight: Math.max(1, Math.round(wallWindow.screen ? wallWindow.screen.height : wallWindow.height))

    // 1. Settled Base Wallpaper (0% GPU/CPU cost at rest)
    Image {
        id: baseImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        smooth: true
        sourceSize.width: wallWindow.decodeWidth
        sourceSize.height: wallWindow.decodeHeight
    }

    // 2. Incoming Transition Layer (visible only while loading or animating transition)
    Item {
        id: revealContainer
        anchors.fill: parent
        visible: wallWindow.transitioning || wallWindow.pendingUrl !== ""

        Image {
            id: nextImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            opacity: 0.0
            scale: 1.0
            transformOrigin: Item.Center
            sourceSize.width: wallWindow.decodeWidth
            sourceSize.height: wallWindow.decodeHeight
            layer.enabled: wallWindow.transitioning && wallWindow.activeTransition === "wave"
            // Hidden from direct draw during wave mode because MultiEffect renders it masked
            visible: !(wallWindow.transitioning && wallWindow.activeTransition === "wave")

            onStatusChanged: {
                if (wallWindow.pendingUrl === "") return;
                if (status === Image.Ready && String(source) !== "") {
                    wallWindow._startTransitionAnim();
                } else if (status === Image.Error) {
                    wallWindow._finishTransition();
                }
            }
        }

        // Expanding soft-feathered radial circle mask for GPU Wave transition
        Item {
            id: waveMask
            anchors.fill: parent
            visible: false
            layer.enabled: wallWindow.transitioning && wallWindow.activeTransition === "wave"
            layer.smooth: true

            readonly property real originX: wallWindow.width * ThemeState.waveOriginX
            readonly property real originY: wallWindow.height * ThemeState.waveOriginY
            readonly property real maxRadius: Math.hypot(
                Math.max(originX, wallWindow.width - originX),
                Math.max(originY, wallWindow.height - originY)
            ) * 1.12
            readonly property real curRadius: maxRadius * wallWindow.waveProgress

            Rectangle {
                x: waveMask.originX - waveMask.curRadius
                y: waveMask.originY - waveMask.curRadius
                width: waveMask.curRadius * 2
                height: waveMask.curRadius * 2
                radius: waveMask.curRadius
                color: "#ffffff"
            }
        }

        // GPU MultiEffect circular reveal (active ONLY during the 660ms wave animation)
        MultiEffect {
            id: waveEffect
            anchors.fill: parent
            visible: wallWindow.transitioning && wallWindow.activeTransition === "wave"
            source: nextImage
            maskEnabled: true
            maskSource: waveMask
            maskThresholdMin: 0.25
            maskSpreadAtMin: 0.35
        }

        // Subtle luminous accent ring riding the wave edge
        Rectangle {
            visible: wallWindow.transitioning && wallWindow.activeTransition === "wave" && wallWindow.waveProgress > 0.01 && wallWindow.waveProgress < 0.98
            x: waveMask.originX - waveMask.curRadius
            y: waveMask.originY - waveMask.curRadius
            width: waveMask.curRadius * 2
            height: waveMask.curRadius * 2
            radius: waveMask.curRadius
            color: "transparent"
            border.color: Theme.accent
            border.width: 2.5
            opacity: Math.max(0.0, (1.0 - wallWindow.waveProgress) * 0.72)
        }
    }

    // Transition Animations
    NumberAnimation {
        id: fadeAnim
        target: nextImage
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 460
        easing.type: Easing.OutCubic
        onFinished: wallWindow._finishTransition()
    }

    ParallelAnimation {
        id: zoomAnim
        NumberAnimation {
            target: nextImage
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 480
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: nextImage
            property: "scale"
            from: 1.08
            to: 1.0
            duration: 520
            easing.type: Easing.OutQuint
        }
        onFinished: wallWindow._finishTransition()
    }

    NumberAnimation {
        id: waveAnim
        target: wallWindow
        property: "waveProgress"
        from: 0.0
        to: 1.0
        duration: 660
        easing.type: Easing.OutCubic
        onFinished: wallWindow._finishTransition()
    }
}
