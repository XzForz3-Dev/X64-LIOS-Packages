pragma Singleton
import QtQuick

// =============================================================================
// X64 LIOS - Quickshell Global Theme & Color Palette (Theme.qml)
// Customize colors, borders, and typography here.
// Modifying 'accent' ensures this Theme.qml is preserved across system updates.
// =============================================================================
QtObject {
    // Obsidian & Crimson Monochromatic Palette (Qt6 #AARRGGBB format)
    readonly property color bgDark: "#0b0c10"
    readonly property color bgGlass: "#f70b0c10"
    readonly property color bgCard: "#fa13151c"
    readonly property color bgElevated: "#ff1a1d26"
    readonly property color bgHover: "#ff222530"
    readonly property color bgActive: "#ff2c303e"

    // Accents (Crimson X64 — used strictly for active state & alerts)
    readonly property color accent: "#ff2b2b"
    readonly property color accentHover: "#ff4747"
    readonly property color accentLight: "#ff4747"
    readonly property color accentDim: "#2eff2b2b"
    readonly property color accentGlow: "#4dff2b2b"
    readonly property color accentBorder: "#73ff2b2b"

    // Semantic Status Colors (Threshold-only)
    readonly property color statusOk: "#34d399"
    readonly property color statusWarn: "#f5a524"

    // Borders & Dividers
    readonly property color borderGlass: "#17ffffff"
    readonly property color borderSubtle: "#12ffffff"
    readonly property color borderAccent: "#73ff2b2b"

    // Text & Foregrounds (Bone White & Neutral Silver)
    readonly property color textPrimary: "#ebe8e3"
    readonly property color textSecondary: "#8e909a"
    readonly property color textMuted: "#565863"

    // Metrics & Radius
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusPill: 999

    // Typography
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontSans: "Inter, Noto Sans, sans-serif"
}
