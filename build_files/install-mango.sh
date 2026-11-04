#!/usr/bin/env bash
# The Mango session (Event Horizon on Mango, same keybinds as Hyprland) and
# what both sessions' keybinds launch: the app drawer (nwg-drawer, compiled
# in the drawer-builder stage), the lock screen (swaylock, started on lock
# requests by swayidle) and the media keys (playerctl).
set -euo pipefail
trap 'echo "::error title=install-mango.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

retry() {
    local try
    for try in 1 2 3; do
        "$@" && return 0
        echo "mango: attempt ${try} failed: $*"
        sleep $((try * 20))
    done
    return 1
}

# Mango (mangowm) comes from Terra, as in Perihelion. Its portal package
# (xdg-desktop-portal-wlr) does screen sharing and screenshots for apps.
retry dnf5 install -y --enable-repo=terra mangowm
retry dnf5 install -y \
    xdg-desktop-portal-wlr \
    swaylock \
    swayidle \
    playerctl \
    libnotify \
    gtk-layer-shell
echo "mango: $(rpm -q mangowm)"

# Only the Event Horizon (Mango) entry on the login screen: Mango's own
# session would start it without the shell.
rm -f /usr/share/wayland-sessions/mango.desktop

# App drawer
if [[ ! -x /drawerroot/usr/bin/nwg-drawer ]]; then
    echo "::error title=install-mango.sh::drawer-builder did not stage nwg-drawer"
    exit 1
fi
cp -a /drawerroot/. /
# Bazzite Horizon's colors as the default look (nwg-drawer copies this file
# to ~/.config/nwg-drawer/drawer.css the first time it runs).
install -m644 /usr/share/bazzite-horizon/nwg-drawer/drawer.css /usr/share/nwg-drawer/drawer.css
if ldd /usr/bin/nwg-drawer | grep -F 'not found'; then
    echo "::error title=install-mango.sh::nwg-drawer is missing shared libraries"
    exit 1
fi

chmod 0755 /usr/bin/horizon-drawer /usr/bin/horizon-lock /usr/bin/horizon-power-menu \
    /usr/bin/horizon-wallpaper-picker /usr/bin/horizon-glass /usr/bin/horizon-keys
test -f /usr/share/wayland-sessions/event-horizon-mango.desktop
command -v mango mmsg >/dev/null
echo "mango: session installed"
