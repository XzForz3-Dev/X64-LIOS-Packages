-- ==============================================================================
-- X64 LIOS - Official Hyprland Desktop Configuration (Cyberpunk Edition)
-- Architecture: Quickshell (Qt6/QML) Desktop Shell + Native Hyprland Lua Engine
-- ==============================================================================

------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "dolphin"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
    -- Export Wayland & Desktop session variables to DBus / Systemd
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")

    -- Polkit Authentication Agent
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1 &")

    -- Monolith 4K Wallpaper Daemon
    hl.exec_cmd("killall swaybg 2>/dev/null; swaybg -i /usr/share/backgrounds/x64-lios/01-monolith.jpg -m fill &")

    -- Quickshell Cyberpunk Desktop Shell (Top Bar, App Launcher, Control Center, OSD)
    hl.exec_cmd("killall quickshell 2>/dev/null; QT_QUICK_BACKEND=software quickshell -n &")

    -- X64 System Update Tray Monitor (SNI)
    hl.exec_cmd("x64-update-tray &")

    -- X64 Hello Welcome Center (Floating Centered)
    hl.exec_cmd("x64-hello &")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(ff2b2bee)", "rgba(ff4d4dee)" }, angle = 45 },
            inactive_border = "rgba(1a1a1aaa)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.96,

        shadow = {
            enabled      = true,
            range        = 10,
            render_power = 3,
            color        = 0x88000000,
        },

        blur = {
            enabled   = true,
            size      = 6,
            passes    = 2,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
    },

    input = {
        kb_layout  = "us,es",
        kb_options = "grp:alt_shift_toggle",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Cyberpunk Animation Curves
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })

hl.animation({ leaf = "global",     enabled = true, speed = 8,   bezier = "default" })
hl.animation({ leaf = "windows",    enabled = true, speed = 5,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4,   bezier = "linear", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 6,   bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4,   bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4,   bezier = "easeOutQuint", style = "fade" })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- Suppress maximize requests
hl.window_rule({
    name           = "suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- X64 Hello Floating Centered Window
hl.window_rule({
    name   = "x64-hello-float",
    match  = { class = "x64-hello" },
    float  = true,
    center = true,
    size   = "1100 680",
})

-- Floating Dialogs & System Management Tools
hl.window_rule({
    name   = "system-dialogs-float",
    match  = { class = "(pavucontrol|nm-connection-editor|blueman-manager|gpartedbin|btrfs-assistant)" },
    float  = true,
    center = true,
})

-- Quickshell Surface Blur
hl.layer_rule({
    name  = "quickshell-blur",
    match = { namespace = "^quickshell$" },
    blur  = true,
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

-- Core Applications
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("quickshell ipc call menu toggle"))
hl.bind(mainMod .. " + C",      hl.dsp.exec_cmd("quickshell ipc call control toggle"))
hl.bind(mainMod .. " + CTRL + N", hl.dsp.exec_cmd("quickshell ipc call network toggle"))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("quickshell ipc call lock lock"))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))

-- Navigation focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces 1..10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces with mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse window dragging and resizing
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Multimedia Audio, Brightness and Screenshot keys
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("x64-hyprland-ctl brightness up"),                   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("x64-hyprland-ctl brightness down"),                 { locked = true, repeating = true })
hl.bind("Print",                 hl.dsp.exec_cmd("x64-hyprland-ctl screenshot full"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("x64-hyprland-ctl screenshot region"))
