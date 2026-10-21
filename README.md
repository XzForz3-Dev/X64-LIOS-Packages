# X64-LIOS-Packages (Monorepo)

Repositorio centralizado para todos los paquetes de software propietario, temas y configuraciones de X64 LIOS.

## CI/CD Pipeline y Gobernanza Autónoma por IA
Este repositorio es administrado y auditado de forma centralizada por la IA oficial (**Antigravity Brain Core**), quien se encarga de:
1. Auditar continuamente la paridad de versiones entre las recetas (`PKGBUILD`) y el repositorio binario mediante `scripts/audit-repo.sh`.
2. Compilar, empaquetar y generar los binarios `.pkg.tar.zst` para todos los entornos, temas y utilidades de X64 LIOS.
3. Actualizar la base de datos de Pacman (`x64-lios.db.tar.gz`) de forma atómica mediante `scripts/deploy-pkg.sh`.
4. Sincronizar de manera segura hacia el servidor web en producción VPS (`x64vps:/var/www/x64-repo/x86_64/`) mediante `scripts/sync-repo.sh`.

Queda establecido que la IA gestiona integralmente el ciclo de vida de los paquetes para asegurar paridad 100% matemática y estabilidad absoluta en los sistemas de los usuarios finales.
