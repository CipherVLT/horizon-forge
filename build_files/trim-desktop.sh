#!/usr/bin/env bash
# Turn Bazzite's KDE desktop into a Hyprland-only creator/coder desktop.
#
# - Removes KDE apps that duplicate Event Horizon or have no use here, plus
#   Waydroid and input-remapper.
# - Installs the apps in apps.list system-wide (ProtonPlus, OBS, ...) and
#   makes Strata (install-strata.sh) the file manager.
# - Leaves the Terra repository enabled so users can rpm-ostree install more.
# - Hides the Plasma session from the login screen. Plasma's libraries stay
#   installed: the login screen (SDDM on KWin) and parts of Bazzite use them.
#
# Packages are erased with --nodeps on purpose. A normal dnf remove would also
# remove anything that depends on them, which on a KDE base can cascade into
# plasma-workspace and the login screen itself. The checks at the end fail
# the build if the Hyprland session went missing; install-greeter.sh checks
# the login screen.
set -euo pipefail
# Show the failing line on the GitHub run page (as an annotation).
trap 'echo "::error title=trim-desktop.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

# --- Remove ------------------------------------------------------------------
# Each line is an extended regex matched against whole installed package
# names (so "rom-properties.*" catches every rom-properties subpackage).
# Patterns that match nothing are reported and skipped, not fatal.
remove=(
    'waydroid'
    'input-remapper'
    'kde-connect(-libs)?' 'kdeconnectd'
    'kdebugsettings'
    'kwalletmanager5?'
    'spectacle'
    'dolphin(-plugins)?'
    'krdc(-libs)?'
    'krfb(-libs)?'
    'filelight'
    'plasma-systemsettings'
    'khelpcenter'
    'kfind'
    'konsole(-part)?'
    'kwrite'
    'kate(-plugins|-libs)?'
    'kmenuedit'
    'rom-properties.*'
    'lutris'
    # Fcitx 5 is for Chinese/Japanese/Korean typing. Without its KDE settings
    # page it only opened a "fcitx5-config-qt couldn't be found" dialog.
    # Bring it back with: rpm-ostree install fcitx5 fcitx5-mozc (or another
    # language addon).
    'fcitx5(-.*)?' 'kcm-fcitx5' 'libime'
    'btrfs-assistant'
    'cardwire-gui'
)
# The cardwire daemon picks the discrete GPU on laptops with two GPUs
# (Intel/AMD + NVIDIA). Keep it in the NVIDIA image for those laptops;
# remove it from the AMD/Intel image, which targets single-GPU desktops.
case "${BAZZITE_HORIZON_BASE:-}" in
    *nvidia*) ;;
    *) remove+=('cardwire') ;;
esac

mapfile -t all_pkgs < <(rpm -qa --qf '%{NAME}\n' | sort -u)
installed=()
for pattern in "${remove[@]}"; do
    mapfile -t hits < <(printf '%s\n' "${all_pkgs[@]}" | grep -x -E "${pattern}" || true)
    if (( ${#hits[@]} )); then
        installed+=("${hits[@]}")
    else
        echo "trim: nothing installed matches ${pattern}, skipping"
    fi
done
if (( ${#installed[@]} )); then
    echo "trim: removing ${installed[*]}"
    rpm --erase --nodeps "${installed[@]}"
fi
case "${BAZZITE_HORIZON_BASE:-}" in
    *nvidia*) ;;
    *) rm -f /etc/systemd/system/*.wants/cardwired.service ;;
esac

# Fcitx 5's login autostart, if the package left it behind.
rm -f /etc/xdg/autostart/org.fcitx.Fcitx5.desktop

# Leftover enable links for removed services.
rm -f /etc/systemd/system/*.wants/input-remapper*.service \
      /etc/systemd/system/*.wants/waydroid-container.service

# Bazzite's own Waydroid helpers and its forum link.
rm -rf /usr/share/applications/Waydroid
rm -f /usr/bin/waydroid-launcher \
      /usr/libexec/waydroid-container-start \
      /usr/libexec/waydroid-container-stop \
      /usr/libexec/waydroid-container-restart \
      /usr/libexec/waydroid-fix-controllers \
      /etc/default/waydroid-launcher \
      /usr/share/polkit-1/actions/org.bazzite.waydroid.policy \
      /usr/share/polkit-1/rules.d/30-waydroid.rules \
      /usr/share/applications/waydroid-container-restart.desktop \
      /usr/share/applications/discourse.desktop
if [[ -f /usr/share/ublue-os/justfile ]]; then
    sed -i '/82-bazzite-waydroid\.just/d' /usr/share/ublue-os/justfile
fi
rm -f /usr/share/ublue-os/just/82-bazzite-waydroid.just

# Menu entries that ship inside packages we keep (the Emoji Selector lives in
# plasma-desktop) or that may outlive their package.
hide=(
    org.kde.plasma.emojier.desktop
    org.kde.kdeconnect.app.desktop
    org.kde.kdeconnect.nonplasma.desktop
    org.kde.kdeconnect.sms.desktop
    org.kde.kdeconnect_open.desktop
    org.kde.kdebugsettings.desktop
    org.kde.kwalletmanager5.desktop
    org.kde.kwalletmanager.desktop
    org.kde.spectacle.desktop
    org.kde.dolphin.desktop
    org.kde.krdc.desktop
    org.kde.filelight.desktop
    systemsettings.desktop
    kdesystemsettings.desktop
    input-remapper-gtk.desktop
    Waydroid.desktop
    org.kde.khelpcenter.desktop
    org.kde.kfind.desktop
    org.kde.konsole.desktop
    org.kde.kwrite.desktop
    org.kde.kate.desktop
    org.kde.kmenuedit.desktop
    org.kde.krfb.desktop
    com.gerbilsoft.rom-properties.rp-config.desktop
    rp-config.desktop
    net.lutris.Lutris.desktop
    org.fcitx.fcitx5-config-qt.desktop
    org.fcitx.fcitx5-migrator.desktop
    org.fcitx.Fcitx5.desktop
    btrfs-assistant.desktop
)
for id in "${hide[@]}"; do
    f="/usr/share/applications/${id}"
    [[ -f "${f}" ]] || continue
    if grep -q '^NoDisplay=' "${f}"; then
        sed -i 's/^NoDisplay=.*/NoDisplay=true/' "${f}"
    else
        sed -i '0,/^\[Desktop Entry\]/s//[Desktop Entry]\nNoDisplay=true/' "${f}"
    fi
    echo "trim: hidden ${id}"
done

# Bazzite starts Steam at every login (silently, in the tray). Don't: launch
# it when you want it, or turn on Steam > Settings > Interface > "Run Steam
# when my computer starts", which writes a per-user autostart entry.
rm -f /etc/xdg/autostart/steam.desktop /etc/skel/.config/autostart/steam.desktop

# Steam Big Picture Mode: a controller/TV interface for handhelds and couch
# setups. This is a desktop image, so drop Bazzite's "Steam Big Picture Mode"
# menu entry and its launcher, and the "Big Picture" item in Steam's
# right-click menu. Steam itself can still switch from its View menu.
rm -f /usr/share/applications/bazzite-steam-bpm.desktop /usr/bin/bazzite-steam-bpm
steam_desktop=/usr/share/applications/steam.desktop
if [[ -f "${steam_desktop}" ]]; then
    awk '
        /^\[/ { skip = ($0 == "[Desktop Action BigPicture]") }
        skip { next }
        /^Actions=/ { sub(/BigPicture;/, "") }
        { print }
    ' "${steam_desktop}" > "${steam_desktop}.new"
    mv "${steam_desktop}.new" "${steam_desktop}"
    chmod 644 "${steam_desktop}"
    if grep -q -i -E 'bigpicture|bazzite-steam-bpm' "${steam_desktop}"; then
        echo "::warning title=trim-desktop.sh::Big Picture is still referenced in ${steam_desktop}"
    fi
fi

# Anything left in the menu that launches a removed program.
for f in /usr/share/applications/*.desktop; do
    if grep -q -E '^Exec=.*\b(cardwire-gui|btrfs-assistant|rp-config|lutris|konsole|khelpcenter|kfind|kwrite|kate|kmenuedit|krfb|fcitx5|fcitx5-config-qt)\b' "${f}" \
        && ! grep -q '^NoDisplay=true' "${f}"; then
        sed -i '0,/^\[Desktop Entry\]/s//[Desktop Entry]\nNoDisplay=true/' "${f}"
        echo "trim: hidden $(basename "${f}")"
    fi
done

# Terminal for desktop entries with Terminal=true and xdg-terminal-exec,
# now that Konsole is gone: kitty in the Hyprland session.
install -d /usr/share/xdg-terminal-exec
printf 'kitty.desktop\n' > /usr/share/xdg-terminal-exec/hyprland-xdg-terminals.list

# --- System-wide apps (build_files/apps.list) ----------------------------------
mapfile -t apps < <(grep -v -E '^[[:space:]]*(#|$)' /ctx/apps.list | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
# One package at a time so a failure names the package. Errors are also
# printed as GitHub annotations (::error::), which show on the workflow run
# without opening the full log.
install_app() {
    local pkg=$1 log
    log=$(mktemp)
    # Fedora Multimedia is enabled for OBS, so it links the full-codec FFmpeg
    # Bazzite already ships instead of pulling Fedora's ffmpeg-free.
    # Fedora's mirror list times out now and then; try three times.
    local try ok=0
    for try in 1 2 3; do
        if dnf5 install -y --enable-repo=terra --enable-repo='*fedora-multimedia*' "${pkg}" >"${log}" 2>&1; then
            ok=1
            break
        fi
        echo "apps: ${pkg} attempt ${try} failed, retrying"
        sleep $((try * 20))
    done
    if (( ! ok )); then
        cat "${log}"
        echo "::error title=apps.list::dnf5 could not install ${pkg}"
        tail -n 15 "${log}" | sed 's/^/::error title=dnf5 ('"${pkg}"')::/'
        rm -f "${log}"
        return 1
    fi
    tail -n 3 "${log}"
    rm -f "${log}"
}
for pkg in "${apps[@]}"; do
    install_app "${pkg}"
done

# Firefox: use the system Open/Save dialog (the FileChooser portal, Strata)
# instead of its built-in GTK one.
ff_done=0
for ff in /usr/lib64/firefox /usr/lib/firefox; do
    [[ -d "${ff}/browser" ]] || continue
    install -d "${ff}/browser/defaults/preferences"
    printf '%s\n' \
        '// Bazzite Horizon: Open/Save dialogs through xdg-desktop-portal (Strata).' \
        'pref("widget.use-xdg-desktop-portal.file-picker", 1);' \
        > "${ff}/browser/defaults/preferences/bazzite-horizon-portal.js"
    ff_done=1
done
(( ff_done )) || echo "::warning title=trim-desktop.sh::Firefox install folder not found; its file dialog stays GTK"

# --- Open package repositories ----------------------------------------------------
# Bazzite turns Terra off in the finished image, so `rpm-ostree install`
# only searches Fedora. Leave Terra on (not terra-extras/terra-mesa, which
# replace core system libraries) so people can layer the extra apps it
# packages, ProtonPlus included.
# Edit the .repo file itself: rpm-ostree reads /etc/yum.repos.d only, not
# dnf5's config-manager overrides.
terra_repo=$(grep -l '^\[terra\]' /etc/yum.repos.d/*.repo | head -n 1)
if [[ -z "${terra_repo}" ]]; then
    echo "trim: no [terra] repository found" >&2
    exit 1
fi
awk '/^\[/{sec=($0=="[terra]")} sec && /^enabled=/{$0="enabled=1"} {print}' \
    "${terra_repo}" > "${terra_repo}.new"
mv "${terra_repo}.new" "${terra_repo}"
grep -A20 '^\[terra\]' "${terra_repo}" | grep -m1 '^enabled=1'

# Default folder handler in the Hyprland session: Strata.
cat > /usr/share/applications/hyprland-mimeapps.list <<'EOF'
[Default Applications]
inode/directory=io.github.lgse.Strata.desktop;
EOF

# --- Login screen: Event Horizon only ----------------------------------------
rm -f /usr/share/wayland-sessions/plasma.desktop \
      /usr/share/wayland-sessions/plasmawayland.desktop \
      /usr/share/xsessions/plasma.desktop \
      /usr/share/xsessions/plasmax11.desktop

# --- Checks --------------------------------------------------------------------
test -f /usr/share/wayland-sessions/event-horizon.desktop
test -x /usr/bin/Hyprland
test -x /usr/bin/strata
# Strata should be the only "Show in folder" handler.
mapfile -t fm1 < <(grep -l -x 'Name=org.freedesktop.FileManager1' /usr/share/dbus-1/services/*.service)
if (( ${#fm1[@]} != 1 )); then
    echo "::warning title=trim-desktop.sh::FileManager1 is provided by: ${fm1[*]}"
fi
for pkg in "${apps[@]}"; do rpm -q "${pkg}" >/dev/null; done
echo "trim: done"
