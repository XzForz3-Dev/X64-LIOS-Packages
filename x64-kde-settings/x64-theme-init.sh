#!/bin/bash
# X64 LIOS Sovereign Wallpaper & Theme Initializer
# Espera activa y dinámica a que Plasma Shell esté completamente operativo en D-Bus

# 1. Esperar activamente a que Plasma Shell responda en D-Bus (máximo 30 intentos * 0.5s = 15s)
for i in $(seq 1 30); do
    if qdbus6 org.kde.plasmashell /PlasmaShell org.freedesktop.DBus.Peer.Ping >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

# 2. Breve estabilización para asegurar que los containments de vídeo/monitores terminen de crearse
sleep 0.3

# 3. Aplicar fondo de pantalla soberano X64-LIOS (Monolith) con reintentos si Plasma está ocupado
for attempt in 1 2 3 4 5; do
    if plasma-apply-wallpaperimage /usr/share/wallpapers/X64-LIOS >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done
