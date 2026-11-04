# shellcheck shell=sh
# Bazzite Horizon: show fastfetch when a terminal window opens (as in
# Perihelion and Veyl OS). Only in interactive shells of a graphical
# terminal, never over SSH or on a text console, and once per window
# (shells started inside it inherit the marker and stay quiet).
# Turn it off: touch ~/.config/bazzite-horizon/no-fastfetch
case $- in
    *i*)
        if [ -z "${HORIZON_FASTFETCH_SHOWN:-}" ] && [ -n "${WAYLAND_DISPLAY:-}" ] \
            && [ -z "${SSH_CONNECTION:-}" ] \
            && [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/bazzite-horizon/no-fastfetch" ] \
            && [ -x /usr/bin/fastfetch ]; then
            export HORIZON_FASTFETCH_SHOWN=1
            /usr/bin/fastfetch --color "$(/usr/libexec/bazzite-bling-fastfetch 2>/dev/null)" \
                -c /usr/share/ublue-os/bazzite/fastfetch.jsonc
        fi
        ;;
esac
