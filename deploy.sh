#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Uso: ./deploy.sh <nombre_del_paquete_o_carpeta>"
    exit 1
fi

PKG_DIR=$1

echo "🔨 Empaquetando $PKG_DIR..."
cd /home/qqqq/Proyectos/X64-Packages/$PKG_DIR
makepkg -scf --noconfirm

echo "📦 Agregando al repositorio local..."
mkdir -p /home/qqqq/Proyectos/X64-Packages/repo-build/x86_64
mv *.pkg.tar.zst /home/qqqq/Proyectos/X64-Packages/repo-build/x86_64/
repo-add /home/qqqq/Proyectos/X64-Packages/repo-build/x86_64/x64-repo.db.tar.gz /home/qqqq/Proyectos/X64-Packages/repo-build/x86_64/*.pkg.tar.zst

echo "🚀 Desplegando en el VPS oficial..."
rsync -avz --delete /home/qqqq/Proyectos/X64-Packages/repo-build/x86_64/ x64vps:/var/www/x64-repo/x86_64/

echo "✅ Despliegue completado."
