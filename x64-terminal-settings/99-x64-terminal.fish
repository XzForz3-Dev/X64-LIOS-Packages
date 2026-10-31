# Detección inteligente de terminal para X64 LIOS
if test "$TERM" = "linux"
    if test -f /etc/starship-tty.toml
        set -gx STARSHIP_CONFIG /etc/starship-tty.toml
    end
end
