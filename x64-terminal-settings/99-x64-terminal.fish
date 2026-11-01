# Detección inteligente de terminal para X64 LIOS
if test "$TERM" = "linux"
    if test -f /etc/starship-tty.toml
        set -gx STARSHIP_CONFIG /etc/starship-tty.toml
    end

    # Lanzar Centro de Mando interactivo al iniciar sesión interactiva en tty1 (Modo Server / CLI o Rescate)
    # Exige status is-interactive para no interceptar comandos de login de Display Managers (ej. greetd / cosmic-greeter)
    if status is-login; and status is-interactive; and test (tty 2>/dev/null) = "/dev/tty1"; and test -x /usr/bin/x64-dashboard; and test -z "$DISPLAY"; and test -z "$WAYLAND_DISPLAY"
        /usr/bin/x64-dashboard
    end
else
    # Terminal gráfica (Kitty, Alacritty, COSMIC Term, Konsole, etc.)
    # Desactivar herencia accidental del perfil TTY desde la consola virtual
    if test -f $HOME/.config/starship.toml
        set -gx STARSHIP_CONFIG $HOME/.config/starship.toml
    else
        set -e STARSHIP_CONFIG
    end
end

