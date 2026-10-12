# Desactivar saludo por defecto de fish
set -g fish_greeting

# Ejecutar fastfetch solo en sesiones interactivas
if status is-interactive
    fastfetch
end

# Inicializar starship
starship init fish | source

