#!/usr/bin/env bash
# What both editions' keybinds launch: the app drawer (nwg-drawer, compiled
# in the drawer-builder stage), the lock screen (swaylock, started on lock
# requests by swayidle) and the media keys (playerctl). For the Mango
# edition also Mango itself. Each image keeps only its own edition's login
# session, the way Bazzite's KDE and GNOME images each have one desktop.
set -euo pipefail
trap 'echo "::error title=install-session.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

retry() {
    local try
    for try in 1 2 3; do
        "$@" && return 0
        echo "session: attempt ${try} failed: $*"
        sleep $((try * 20))
    done
    return 1
}

desktop="${BAZZITE_HORIZON_DESKTOP:?}"
session_file="${BAZZITE_HORIZON_SESSION:?}"

if [[ "${desktop}" == mango ]]; then
    # Mango (mangowm) comes from Terra, as in Perihelion. Its portal package
    # (xdg-desktop-portal-wlr) does screen sharing and screenshots for apps.
    retry dnf5 install -y --enable-repo=terra mangowm xdg-desktop-portal-wlr
    echo "mango: $(rpm -q mangowm)"
    command -v mango mmsg >/dev/null
    # Mango's own session would start it without the shell.
    rm -f /usr/share/wayland-sessions/mango.desktop
fi
retry dnf5 install -y \
    swaylock \
    swayidle \
    playerctl \
    libnotify \
    gtk-layer-shell

# One session on the login screen: this edition's.
for f in /usr/share/wayland-sessions/event-horizon.desktop /usr/share/wayland-sessions/event-horizon-mango.desktop; do
    [[ "${f}" == "${session_file}" ]] || rm -f "${f}"
done
test -f "${session_file}"

# App drawer
if [[ ! -x /drawerroot/usr/bin/nwg-drawer ]]; then
    echo "::error title=install-session.sh::drawer-builder did not stage nwg-drawer"
    exit 1
fi
cp -a /drawerroot/. /
# Bazzite Horizon's colors as the default look (nwg-drawer copies this file
# to ~/.config/nwg-drawer/drawer.css the first time it runs).
install -m644 /usr/share/bazzite-horizon/nwg-drawer/drawer.css /usr/share/nwg-drawer/drawer.css
if ldd /usr/bin/nwg-drawer | grep -F 'not found'; then
    echo "::error title=install-session.sh::nwg-drawer is missing shared libraries"
    exit 1
fi

chmod 0755 /usr/bin/horizon-drawer /usr/bin/horizon-lock /usr/bin/horizon-power-menu \
    /usr/bin/horizon-wallpaper-picker /usr/bin/horizon-glass /usr/bin/horizon-keys
echo "session: ${desktop} ($(basename "${session_file}"))"
