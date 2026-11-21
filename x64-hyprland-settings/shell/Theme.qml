pragma Singleton
import QtQuick

// =============================================================================
// X64 LIOS - Quickshell Live Animated Theme & Color Palette (Theme.qml)
// Driven dynamically by ThemeState (~/.config/x64-theme/palette.json).
// Smooth 350ms GPU ColorAnimation on core tokens cascades automatically to all
// derived alpha glows, borders, capsules, and sliders with zero restarts.
// =============================================================================
QtObject {
    id: theme

    // Core Surface Colors (animated on live theme switches)
    property color bgDark: ThemeState.bgDark
    Behavior on bgDark { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color bgCardBase: ThemeState.bgCard
    Behavior on bgCardBase { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color bgElevated: ThemeState.bgElevated
    Behavior on bgElevated { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color bgHover: ThemeState.bgHover
    Behavior on bgHover { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color bgActive: ThemeState.bgActive
    Behavior on bgActive { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color bgBarBase: ThemeState.bgBar
    Behavior on bgBarBase { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color bgCapsuleBase: ThemeState.bgCapsule
    Behavior on bgCapsuleBase { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // Glass & Surface Derived Tokens (exact alpha parity with original X64 glass)
    readonly property color bgGlass: Qt.rgba(bgDark.r, bgDark.g, bgDark.b, 0.968)
    readonly property color bgCard: Qt.rgba(bgCardBase.r, bgCardBase.g, bgCardBase.b, 0.98)
    readonly property color bgBar: Qt.rgba(bgBarBase.r, bgBarBase.g, bgBarBase.b, 0.95)
    readonly property color bgCapsule: Qt.rgba(bgCapsuleBase.r, bgCapsuleBase.g, bgCapsuleBase.b, 0.96)

    // Accents (Dynamic per theme / user override; defaults to Crimson X64 #ff2b2b)
    property color accent: ThemeState.accent
    Behavior on accent { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color accentHover: ThemeState.accentHover
    Behavior on accentHover { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color accentText: ThemeState.accentText
    Behavior on accentText { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color accentPillBase: ThemeState.accentPillBg
    Behavior on accentPillBase { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    readonly property color accentLight: accentHover
    readonly property color accentFg: (0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b) > 0.52 ? "#0a0b10" : "#ffffff"
    readonly property color accentSubtle: Qt.rgba(accent.r, accent.g, accent.b, 0.14)
    readonly property color accentDim: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
    readonly property color accentTint: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
    readonly property color accentGlowLine: Qt.rgba(accent.r, accent.g, accent.b, 0.27)
    readonly property color accentGlow: Qt.rgba(accent.r, accent.g, accent.b, 0.30)
    readonly property color accentBorder: Qt.rgba(accent.r, accent.g, accent.b, 0.45)
    readonly property color accentHalf: Qt.rgba(accent.r, accent.g, accent.b, 0.53)
    readonly property color accentSliderStart: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
    readonly property color accentSliderEnd: Qt.rgba(accent.r, accent.g, accent.b, 0.50)
    readonly property color accentPillBg: Qt.rgba(accentPillBase.r, accentPillBase.g, accentPillBase.b, 0.96)

    // Semantic Status Colors
    property color statusOk: ThemeState.statusOk
    Behavior on statusOk { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color statusWarn: ThemeState.statusWarn
    Behavior on statusWarn { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    readonly property color statusCrit: "#ff3b3b"

    // Borders & Dividers
    readonly property color borderGlass: "#17ffffff"
    readonly property color borderSubtle: "#12ffffff"
    readonly property color borderAccent: accentBorder

    // Text & Foregrounds
    property color textPrimary: ThemeState.textPrimary
    Behavior on textPrimary { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color textSecondary: ThemeState.textSecondary
    Behavior on textSecondary { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    property color textMuted: ThemeState.textMuted
    Behavior on textMuted { ColorAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // Metrics & Radius
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusPill: 999

    // Typography
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontSans: "Inter, Noto Sans, sans-serif"
}
