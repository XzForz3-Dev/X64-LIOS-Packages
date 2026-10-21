#!/usr/bin/env bash
# ==============================================================================
# X64 LIOS Atomic Package Deploy Tool
# Compiles, stages, updates repository database, audits parity, and syncs to VPS
# Usage: ./scripts/deploy-pkg.sh <package-name>
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${SCRIPT_DIR}/.."
REPO_DIR="${BASE_DIR}/../X64-LIOS-REPO/x86_64"

if [ $# -lt 1 ]; then
    echo "Uso: $0 <nombre-del-paquete>"
    echo "Ejemplo: $0 x64-plymouth-theme"
    exit 1
fi

PKG_TARGET="$1"
PKG_DIR="${BASE_DIR}/${PKG_TARGET}"

if [ ! -d "$PKG_DIR" ] || [ ! -f "${PKG_DIR}/PKGBUILD" ]; then
    echo "❌ [ERROR] El paquete '${PKG_TARGET}' no existe en ${BASE_DIR} o carece de PKGBUILD."
    exit 1
fi

echo "📦 [1/5] Compilando ${PKG_TARGET}..."
cd "$PKG_DIR"
makepkg -d -f

# Localizar el paquete recién compilado
BUILT_PKG=$(find . -maxdepth 1 -name "${PKG_TARGET}-*.pkg.tar.zst" -printf "%f\n" | head -n 1)

if [ -z "$BUILT_PKG" ]; then
    # Manejar paquetes con pkgname diferente a la carpeta (ej. calamares)
    BUILT_PKG=$(find . -maxdepth 1 -name "*.pkg.tar.zst" -printf "%f\n" | head -n 1)
fi

if [ -z "$BUILT_PKG" ]; then
    echo "❌ [ERROR] No se encontró el binario .pkg.tar.zst generado para ${PKG_TARGET}."
    exit 1
fi

PKG_FILEPATH="${PKG_DIR}/${BUILT_PKG}"
echo "✨ [2/5] Binario compilado: ${BUILT_PKG}"

echo "🚚 [3/5] Actualizando almacén local en ${REPO_DIR}..."
cd "$REPO_DIR"

# Eliminar versiones previas de este paquete en el repo
find "$REPO_DIR" -maxdepth 1 -name "${PKG_TARGET}-*.pkg.tar.zst" -not -name "$BUILT_PKG" -delete || true

# Copiar nuevo paquete
cp -f "$PKG_FILEPATH" "$REPO_DIR/"

# Actualizar base de datos de pacman
repo-remove x64-lios.db.tar.gz "$PKG_TARGET" 2>/dev/null || true
repo-add x64-lios.db.tar.gz "$BUILT_PKG"

echo "🔍 [4/5] Ejecutando auditoría de paridad..."
"${SCRIPT_DIR}/audit-repo.sh"

echo "🚀 [5/5] Sincronizando con el servidor de producción VPS..."
rsync -avzP --delete "${REPO_DIR}/" x64vps:/var/www/x64-repo/x86_64/

echo "🎉 [ÉXITO TOTAL] '${PKG_TARGET}' desplegado, auditado y activo en https://repo.x64lios.com/x86_64/"
