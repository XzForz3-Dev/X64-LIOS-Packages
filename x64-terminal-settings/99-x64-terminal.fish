# Detección inteligente de terminal para X64 LIOS
if test "$TERM" = "linux"
    if test -f /etc/starship-tty.toml
        set -gx STARSHIP_CONFIG /etc/starship-tty.toml
    end

    # Lanzar Centro de Mando interactivo al iniciar sesión en tty1 (Modo Server / CLI o Rescate)
    if status is-login; and test (tty 2>/dev/null) = "/dev/tty1"; and test -x /usr/bin/x64-dashboard; and test -z "$DISPLAY"; and test -z "$WAYLAND_DISPLAY"
        /usr/bin/x64-dashboard
    end
end

