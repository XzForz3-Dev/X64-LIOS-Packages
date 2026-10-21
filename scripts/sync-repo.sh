#!/usr/bin/env bash
# ==============================================================================
# X64 LIOS Safe Repository Synchronization Tool
# Audits parity first, updates local database, and securely syncs to VPS
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="${SCRIPT_DIR}/.."
REPO_DIR="${BASE_DIR}/../X64-LIOS-REPO/x86_64"

# 1. Pre-flight Parity Audit
if ! "${SCRIPT_DIR}/audit-repo.sh"; then
    echo "❌ [ERROR CRÍTICO] La sincronización al VPS fue BLOQUEADA por fallo de paridad."
    echo "👉 Corrige o compila los paquetes desincronizados antes de continuar."
    exit 1
fi

echo "🚀 [SYNC VPS] Iniciando sincronización segura hacia x64vps..."
cd "$REPO_DIR"

# 2. Sync to VPS
rsync -avzP --delete "${REPO_DIR}/" x64vps:/var/www/x64-repo/x86_64/

echo "✅ [COMPLETADO] Repositorio de X64 LIOS sincronizado y en paridad al 100% en https://repo.x64lios.com/x86_64/"
