-- ==============================================================================
-- X64 LIOS - Archivo Personal de Usuario para Hyprland (custom.lua)
-- ==============================================================================
-- Este archivo se carga automáticamente al final de ~/.config/hypr/hyprland.lua
-- y NUNCA es sobrescrito por las actualizaciones del sistema (pacman -Syu).
--
-- Aquí puedes añadir tus propios atajos de teclado, reglas de ventanas,
-- fondos de pantalla personalizados, monitores o sobreescribir bordes y gaps.
-- ==============================================================================

-- 1. EJEMPLO: Cambiar bordes, gaps o colores del marco activo
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

-- 2. EJEMPLO: Añadir tus propios atajos de teclado
-- hl.bind("SUPER + B", hl.dsp.exec_cmd("chromium"))

-- 3. EJEMPLO: Usar tu propio fondo de pantalla o iniciar programas propios
-- hl.on("hyprland.start", function ()
--     hl.exec_cmd("killall swaybg 2>/dev/null; swaybg -i ~/Pictures/mi-wallpaper.jpg -m fill &")
-- end)
