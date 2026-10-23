#!/bin/bash
# X64 LIOS - Asegura que el Look-and-Feel de Plasma use X64-LIOS como fondo por defecto
for f in /usr/share/plasma/look-and-feel/org.kde.breeze*/contents/defaults; do
    if [ -f "$f" ]; then
        sed -i 's/^Image=Next/Image=X64-LIOS/' "$f" 2>/dev/null || true
    fi
done
