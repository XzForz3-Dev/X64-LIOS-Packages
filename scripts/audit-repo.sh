#!/usr/bin/env bash
# ==============================================================================
# X64 LIOS Repository Parity Audit Tool
# Validates that every package recipe in X64-LIOS-Packages matches the binary in X64-LIOS-REPO
# ==============================================================================
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="${BASE_DIR}/../X64-LIOS-REPO/x86_64"

if [ ! -d "$REPO_DIR" ]; then
    echo "❌ [ERROR] Repository directory not found: $REPO_DIR"
    exit 1
fi

echo "🔍 [X64 REPO AUDIT] Verificando paridad entre código fuente y repositorio binario..."
echo "--------------------------------------------------------------------------------"

DESYNC_COUNT=0
TOTAL_COUNT=0

for PKG_DIR in "$BASE_DIR"/*; do
    [ -d "$PKG_DIR" ] || continue
    PKG_NAME="$(basename "$PKG_DIR")"
    [ "$PKG_NAME" = "scripts" ] && continue
    [ "$PKG_NAME" = ".git" ] && continue
    [ "$PKG_NAME" = ".github" ] && continue

    PKGBUILD="${PKG_DIR}/PKGBUILD"
    [ -f "$PKGBUILD" ] || continue

    TOTAL_COUNT=$((TOTAL_COUNT + 1))

    # Extract pkgver and pkgrel
    RAW_PKGNAME=$(grep -E "^pkgname=" "$PKGBUILD" | head -n 1 | cut -d'=' -f2 | tr -d "'\"()")
    PKGVER=$(grep -E "^pkgver=" "$PKGBUILD" | head -n 1 | cut -d'=' -f2 | tr -d "'\"")
    PKGREL=$(grep -E "^pkgrel=" "$PKGBUILD" | head -n 1 | cut -d'=' -f2 | tr -d "'\"")

    if [ "$RAW_PKGNAME" = "\$_pkgname" ] || [ "$RAW_PKGNAME" = "\${_pkgname}" ]; then
        RAW_PKGNAME="calamares"
    fi

    TARGET_PREFIX="${RAW_PKGNAME}-${PKGVER}-${PKGREL}-"
    MATCHING_FILE=$(find "$REPO_DIR" -maxdepth 1 -name "${TARGET_PREFIX}*.pkg.tar.zst" -printf "%f\n" | head -n 1)

    if [ -n "$MATCHING_FILE" ]; then
        printf "  ✅ [\e[32mOK\e[0m]      %-25s (%s-%s) -> %s\n" "$RAW_PKGNAME" "$PKGVER" "$PKGREL" "$MATCHING_FILE"
    else
        printf "  ❌ [\e[31mDESYNC\e[0m]  %-25s (%s-%s) -> NO SE ENCUENTRA EN REPO\n" "$RAW_PKGNAME" "$PKGVER" "$PKGREL"
        DESYNC_COUNT=$((DESYNC_COUNT + 1))
    fi
done

echo "--------------------------------------------------------------------------------"
if [ "$DESYNC_COUNT" -eq 0 ]; then
    echo "🎉 [PARIDAD PERFECTA] Los $TOTAL_COUNT paquetes están 100% sincronizados con el repositorio."
    exit 0
else
    echo "⚠️ [ALERTA] Se encontraron $DESYNC_COUNT paquetes desincronizados de $TOTAL_COUNT."
    exit 1
fi
