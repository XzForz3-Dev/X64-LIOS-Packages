pragma Singleton
import QtQuick

QtObject {
    // Cyberpunk OLED Color Palette
    readonly property color bgDark: "#08080a"
    readonly property color bgGlass: "#0e0e13ee"
    readonly property color bgCard: "#16161ecc"
    readonly property color bgHover: "#252532dd"
    readonly property color bgActive: "#323242ee"

    // Accents (Crimson Neon)
    readonly property color accent: "#ff2b2b"
    readonly property color accentHover: "#ff4d4d"
    readonly property color accentLight: "#ff4d4d"
    readonly property color accentDim: "#991818"
    readonly property color accentGlow: "#55ff2b2b"
    readonly property color accentBorder: "#88ff2b2b"

    // Borders & Dividers
    readonly property color borderGlass: "#22ffffff"
    readonly property color borderSubtle: "#15ffffff"
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
