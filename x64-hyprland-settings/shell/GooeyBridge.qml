import QtQuick
import QtQuick.Shapes

Shape {
    id: bridgeRoot

    property real originX: 0
    property real originY: 24
    property real topHalfW: 24
    property real botHalfW: 48
    property real botY: 34
    property real morphProgress: 1.0
    property color fillColor: Theme.bgGlass
    property color strokeColor: Theme.borderGlass
    property real strokeWidth: 1.0

    readonly property real pinch: (1.0 - Math.pow(morphProgress - 0.5, 2) * 4) * 0.65
    readonly property real currentPinch: morphProgress < 1.0 ? Math.max(0, pinch) : 0.0
    readonly property real waistHalfW: Math.max(6, topHalfW * (1.0 - currentPinch))

    layer.enabled: true
    layer.samples: 4

    ShapePath {
        strokeWidth: bridgeRoot.strokeWidth
        strokeColor: bridgeRoot.strokeColor
        fillColor: bridgeRoot.fillColor

        startX: bridgeRoot.originX - bridgeRoot.topHalfW
        startY: bridgeRoot.originY

        PathLine {
            x: bridgeRoot.originX + bridgeRoot.topHalfW
            y: bridgeRoot.originY
        }

        PathCubic {
            x: bridgeRoot.originX + bridgeRoot.botHalfW
            y: bridgeRoot.botY
            control1X: bridgeRoot.originX + bridgeRoot.waistHalfW
            control1Y: bridgeRoot.originY + (bridgeRoot.botY - bridgeRoot.originY) * 0.35
            control2X: bridgeRoot.originX + bridgeRoot.waistHalfW
            control2Y: bridgeRoot.originY + (bridgeRoot.botY - bridgeRoot.originY) * 0.65
        }

        PathLine {
            x: bridgeRoot.originX - bridgeRoot.botHalfW
            y: bridgeRoot.botY
        }

        PathCubic {
            x: bridgeRoot.originX - bridgeRoot.topHalfW
            y: bridgeRoot.originY
            control1X: bridgeRoot.originX - bridgeRoot.waistHalfW
            control1Y: bridgeRoot.originY + (bridgeRoot.botY - bridgeRoot.originY) * 0.65
            control2X: bridgeRoot.originX - bridgeRoot.waistHalfW
            control2Y: bridgeRoot.originY + (bridgeRoot.botY - bridgeRoot.originY) * 0.35
        }
    }
}
