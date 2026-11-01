# Desactivar saludo por defecto de fish
set -g fish_greeting

# Detectar si estamos en consola virtual de Linux pura (TTY)
if test "$TERM" = "linux"
    if test -f /etc/starship-tty.toml
        set -gx STARSHIP_CONFIG /etc/starship-tty.toml
    else if test -f ~/.config/starship-tty.toml
        set -gx STARSHIP_CONFIG ~/.config/starship-tty.toml
    end

    if status is-interactive
        if test -f /etc/fastfetch/config-tty.jsonc
            fastfetch --config /etc/fastfetch/config-tty.jsonc
        else
            fastfetch
        end
    end
else
    # Terminal gráfica (Kitty, Alacritty, GNOME Console, Konsole, COSMIC Term, etc.): Diseño completo con Nerd Fonts
    if test -f $HOME/.config/starship.toml
        set -gx STARSHIP_CONFIG $HOME/.config/starship.toml
    else
        set -e STARSHIP_CONFIG
    end

    if status is-interactive
        fastfetch
    end
end

# Inicializar starship
starship init fish | source
