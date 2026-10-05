# X64-LIOS-Packages (Monorepo)

Repositorio centralizado para todos los paquetes de software propietario, temas y configuraciones de X64 LIOS.

## CI/CD Pipeline
Este repositorio utiliza GitHub Actions para compilar automáticamente cualquier paquete que contenga un `PKGBUILD` utilizando un contenedor de Arch Linux (`archlinux:base-devel`). Tras la compilación, la base de datos de pacman se actualiza y los archivos se sincronizan de forma autónoma al VPS oficial mediante `rsync`.
