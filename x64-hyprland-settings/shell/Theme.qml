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
    readonly property color bgGlass: "#cc0b0b12"         // ~80% opacity dark obsidian frosted glass
    readonly property color bgCard: "#22ffffff"          // translucent surface container
    readonly property color bgCardSolid: "#15161e"
    readonly property color bgContainer: "#101117"
    readonly property color bgPillTrack: "#1a1b24"
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
    readonly property color borderGlass: "#28ffffff"     // delicate 1px translucent border
    readonly property color borderSubtle: "#16ffffff"
    readonly property color borderAccent: "#88ff2b2b"

    // Text & Foregrounds
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#b0b0c2"
    readonly property color textMuted: "#6b6b80"

    // Metrics & Radius
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 20
    readonly property int radiusPill: 999

    // Typography
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontSans: "Inter, Noto Sans, sans-serif"
}
