#!/usr/bin/env bash
# Login screen: SDDM with the Pixie theme and the Bazzite wallpaper, in place
# of Bazzite's Plasma Login.
#
# Plasma Login can't load custom themes, so the image goes back to SDDM (from
# Fedora), the login manager Bazzite used before. The greeter runs on KWin,
# which the KDE base already ships. Plasma Login stays installed but disabled:
#   sudo systemctl disable sddm && sudo systemctl enable plasmalogin
# switches back.
#
# The theme is vendored in system_files/usr/share/sddm/themes/pixie (see the
# SOURCE file there). A login screen that fails to start leaves nobody able to
# log in, so the checks at the end fail the build instead.
set -euo pipefail
# Show the failing line on the GitHub run page (as an annotation).
trap 'echo "::error title=install-greeter.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

theme=/usr/share/sddm/themes/pixie
wallpaper=/usr/share/wallpapers/convergence.png

# sddm-wayland-plasma runs the greeter on KWin; sddm-wayland-generic (Weston)
# is the fallback if Fedora ever drops it.
# Fedora's mirror list times out now and then, so each try is repeated.
retry() {
    local try
    for try in 1 2 3; do
        "$@" && return 0
        echo "greeter: attempt ${try} failed: $*"
        sleep $((try * 20))
    done
    return 1
}
if ! retry dnf5 install -y sddm sddm-wayland-plasma; then
    echo "::warning title=install-greeter.sh::sddm-wayland-plasma unavailable, using sddm-wayland-generic"
    retry dnf5 install -y sddm sddm-wayland-generic
fi

# The Bazzite wallpaper as the background (theme.conf points here).
if [[ ! -f "${wallpaper}" ]]; then
    echo "::error title=install-greeter.sh::${wallpaper} is missing from the base image"
    exit 1
fi
install -Dm644 "${wallpaper}" "${theme}/assets/background.png"
chmod -R u=rwX,go=rX "${theme}"

install -d /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-bazzite-horizon.conf <<'EOF'
[Theme]
Current=pixie

[Users]
# Show only real accounts.
MinimumUid=1000
MaximumUid=60000
EOF

# Switch the display manager. Both units claim display-manager.service, so
# drop Plasma Login's link first. The preset keeps it that way when systemd
# applies presets on a machine's first boot.
systemctl disable plasmalogin.service || true
rm -f /etc/systemd/system/display-manager.service
systemctl enable sddm.service
install -d /usr/lib/systemd/system-preset
cat > /usr/lib/systemd/system-preset/01-bazzite-horizon-greeter.preset <<'EOF'
enable sddm.service
disable plasmalogin.service
EOF

# --- Checks --------------------------------------------------------------------
test -x /usr/bin/sddm
test "$(readlink -f /etc/systemd/system/display-manager.service)" = /usr/lib/systemd/system/sddm.service
for f in Main.qml metadata.desktop theme.conf components/Clock.qml components/PowerBar.qml assets/background.png; do
    test -s "${theme}/${f}"
done
grep -q '^use24HourClock=false' "${theme}/theme.conf"
test -f /usr/share/wayland-sessions/event-horizon.desktop
id sddm >/dev/null 2>&1 || grep -qs -w sddm /usr/lib/sysusers.d/*.conf
echo "greeter: SDDM + Pixie enabled"
