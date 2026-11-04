#!/usr/bin/env bash
# This edition's login session (Event Horizon on Hyprland or on Mango) must
# have every program its default config launches, and a Mango config must
# parse with the Mango that was installed. Runs last in build.sh, after
# every package is in.
set -euo pipefail
trap 'echo "::error title=check-sessions.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

skel=/usr/share/event-horizon/skel
hypr="${skel}/hypr/hyprland.lua"
mango_cfg="${skel}/mango/config.conf"

desktop="${BAZZITE_HORIZON_DESKTOP:-hyprland}"
if [[ "${desktop}" == mango ]]; then
    # `mango -p` only reads the file; it needs no display.
    if ! out=$(mango -p -c "${mango_cfg}" 2>&1); then
        printf '%s\n' "${out}" >&2
        echo "::error title=check-sessions.sh::the Mango config does not parse with $(rpm -q mangowm)"
        exit 1
    fi
fi

# The current Mango default must not be listed as an older default.
if grep -qx "$(sha256sum "${mango_cfg}" | cut -d' ' -f1)" "${skel}/mango/previous-defaults.sha256"; then
    echo "::error title=check-sessions.sh::skel mango/config.conf is listed in previous-defaults.sha256"
    exit 1
fi

missing=0
check() {
    local prog=$1 where=$2
    [[ -n "${prog}" ]] || return 0
    if ! command -v "${prog}" >/dev/null 2>&1 && [[ ! -x "${prog}" ]]; then
        echo "::error title=check-sessions.sh::${where} launches ${prog}, which is not installed"
        missing=1
    fi
}
if [[ "${desktop}" == hyprland ]]; then
    while read -r prog; do check "${prog}" "hyprland.lua"; done < <(
        grep -oE 'exec_cmd\("[^" ;]+' "${hypr}" | sed 's/exec_cmd("//' | sort -u)
    compositor_tool=hyprctl
else
    while read -r prog; do check "${prog}" "mango/config.conf"; done < <(
        sed -n -E 's/^(bind[a-z]*|mousebind|axisbind|gesturebind)=[^,]*,[^,]*,spawn(_shell)?,([^ ,;]+).*/\3/p; s/^exec_once=([^ ]+).*/\1/p' \
            "${mango_cfg}" | sort -u)
    compositor_tool=mmsg
fi
# Programs the helper scripts call.
for prog in fuzzel nwg-drawer swaylock swayidle "${compositor_tool}" horizon-wallpaper notify-send; do
    check "${prog}" "a horizon-* helper"
done
(( missing == 0 )) || exit 1

# horizon-lock's options must exist in this swaylock.
help=$(swaylock --help 2>&1 || true)
for opt in $(grep -oE -- '--[a-z-]+' /usr/bin/horizon-lock | sort -u); do
    grep -q -- "${opt}" <<<"${help}" || {
        echo "::error title=check-sessions.sh::swaylock has no ${opt} (horizon-lock)"
        exit 1
    }
done

test -f "/etc/xdg/xdg-desktop-portal/${desktop}-portals.conf"
test -f "${BAZZITE_HORIZON_SESSION:?}"
# Exactly one Event Horizon session on the login screen.
n=$(find /usr/share/wayland-sessions -name 'event-horizon*.desktop' | wc -l)
(( n == 1 )) || { echo "::error title=check-sessions.sh::${n} Event Horizon sessions installed, expected 1"; exit 1; }
test -f /etc/xdg/fuzzel/fuzzel.ini
echo "sessions: the ${desktop} edition checks out"
