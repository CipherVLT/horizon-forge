#!/usr/bin/env bash
# Turn Bazzite's KDE desktop into a Hyprland-only creator/coder desktop.
#
# - Removes KDE apps that duplicate Event Horizon or have no use here, plus
#   Waydroid and input-remapper.
# - Installs the apps in apps.list system-wide (GNOME Files, ProtonPlus, ...)
#   and makes Nautilus the file manager.
# - Leaves the Terra repository enabled so users can rpm-ostree install more.
# - Hides the Plasma session from the login screen. Plasma's libraries stay
#   installed: the login screen (Plasma Login) and parts of Bazzite use them.
#
# Packages are erased with --nodeps on purpose. A normal dnf remove would also
# remove anything that depends on them, which on a KDE base can cascade into
# plasma-workspace and the login screen itself. The checks at the end fail
# the build if the login screen or Hyprland session went missing.
set -euo pipefail

# --- Remove ------------------------------------------------------------------
# Each name is only removed if installed, so a renamed or missing package is
# skipped (and reported) instead of failing the build.
remove=(
    waydroid
    input-remapper
    kde-connect kde-connect-libs kdeconnectd
    kdebugsettings
    kwalletmanager5 kwalletmanager
    spectacle
    dolphin dolphin-plugins
    krdc krdc-libs
    filelight
    plasma-systemsettings
)
installed=()
for pkg in "${remove[@]}"; do
    if rpm -q "${pkg}" >/dev/null 2>&1; then
        installed+=("${pkg}")
    else
        echo "trim: ${pkg} is not installed, skipping"
    fi
done
if (( ${#installed[@]} )); then
    echo "trim: removing ${installed[*]}"
    rpm --erase --nodeps "${installed[@]}"
fi

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

# --- System-wide apps (build_files/apps.list) ----------------------------------
mapfile -t apps < <(grep -v -E '^[[:space:]]*(#|$)' /ctx/apps.list | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
# Microsoft's repository for Visual Studio Code (package "code"). Left
# enabled so `rpm-ostree install`/updates can see newer VS Code builds.
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
if (( ${#apps[@]} )); then
    # Fedora Multimedia first for OBS, so it links the full-codec FFmpeg
    # Bazzite already ships instead of pulling Fedora's ffmpeg-free.
    dnf5 install -y --enable-repo=terra --enable-repo='*fedora-multimedia*' "${apps[@]}"
fi

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

# Default folder handler in the Hyprland session: Nautilus, then Strata.
cat > /usr/share/applications/hyprland-mimeapps.list <<'EOF'
[Default Applications]
inode/directory=org.gnome.Nautilus.desktop;io.github.lgse.Strata.desktop;
EOF

# --- Login screen: Event Horizon only ----------------------------------------
rm -f /usr/share/wayland-sessions/plasma.desktop \
      /usr/share/wayland-sessions/plasmawayland.desktop \
      /usr/share/xsessions/plasma.desktop \
      /usr/share/xsessions/plasmax11.desktop

# --- Checks --------------------------------------------------------------------
test -f /usr/share/wayland-sessions/event-horizon.desktop
test -x /usr/bin/Hyprland
test -x /usr/bin/nautilus
for pkg in "${apps[@]}"; do rpm -q "${pkg}" >/dev/null; done
if ! command -v plasmalogin >/dev/null 2>&1 && ! ls /usr/lib/systemd/system/plasmalogin.service >/dev/null 2>&1; then
    echo "trim: the Plasma Login screen is gone; refusing to build an image nobody can log into" >&2
    exit 1
fi
echo "trim: done"
