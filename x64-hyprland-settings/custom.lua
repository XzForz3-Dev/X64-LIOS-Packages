-- ==============================================================================
-- X64 LIOS - User Custom Configuration File (custom.lua)
-- ==============================================================================
-- This file is automatically loaded at the end of ~/.config/hypr/hyprland.lua
-- and is NEVER overwritten during system updates (pacman -Syu).
--
-- Feel free to add your custom keybindings, window rules, wallpapers,
-- monitor configurations, or override gaps, animations, and border colors here.
-- ==============================================================================

-- 1. EXAMPLE: Customize window borders, gaps, or active outline colors
-- hl.config({
--     general = {
--         gaps_in  = 6,
--         gaps_out = 12,
--         border_size = 2,
--         col = {
--             active_border = { colors = { "rgba(00e5ffee)", "rgba(7c4dffee)" }, angle = 45 },
--         },
--     },
-- })

-- 2. EXAMPLE: Add custom application keybindings
-- hl.bind("SUPER + B", hl.dsp.exec_cmd("chromium"))

-- 3. EXAMPLE: Autostart personal background daemons or custom wallpaper
-- hl.on("hyprland.start", function ()
--     hl.exec_cmd("killall swaybg 2>/dev/null; swaybg -i ~/Pictures/my-wallpaper.jpg -m fill &")
-- end)
