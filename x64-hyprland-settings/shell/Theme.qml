pragma Singleton
import QtQuick

// =============================================================================
// X64 LIOS - Quickshell Global Theme & Color Palette (Theme.qml)
// Customize colors, borders, and typography here.
// Modifying 'accent' ensures this Theme.qml is preserved across system updates.
// =============================================================================
QtObject {
    // Cyberpunk OLED Color Palette (Qt6 #AARRGGBB format)
    readonly property color bgDark: "#08080a"
    readonly property color bgGlass: "#f50b0b10"
    readonly property color bgCard: "#fa15151e"
    readonly property color bgHover: "#ff222230"
    readonly property color bgActive: "#ff2e2e40"

    // Accents (Crimson Neon)
    readonly property color accent: "#ff2b2b"
    readonly property color accentHover: "#ff4d4d"
    readonly property color accentLight: "#ff4d4d"
    readonly property color accentDim: "#991818"
    readonly property color accentGlow: "#55ff2b2b"
    readonly property color accentBorder: "#88ff2b2b"

    // Borders & Dividers
    readonly property color borderGlass: "#2affffff"
    readonly property color borderSubtle: "#1cffffff"
    readonly property color borderAccent: "#88ff2b2b"

    // Text & Foregrounds
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#a2a2b4"
    readonly property color textMuted: "#666678"

    // Metrics & Radius
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int radiusPill: 999

    // Typography
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontSans: "Inter, Noto Sans, sans-serif"
}
