#!/usr/bin/env bash
# Final image: Bazzite, plus a Hyprland session, plus the Event Horizon
# binaries staged by build-event-horizon.sh. Plasma stays installed so the
# gear menu on the login screen can still fall back to KDE.
set -eoux pipefail

cp -avf /ctx/system_files/. /
chmod 0755 /usr/bin/event-horizon-session

# Runtime packages only. Build dependencies stayed in the eh-builder stage.
# Names follow Event Horizon's Fedora.md (F43+) plus the Hyprland session
# that page says the shell has to run inside.
dnf5 install -y \
    hyprland \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    grim \
    slurp \
    wl-clipboard \
    brightnessctl \
    kitty \
    fuzzel \
    libjpeg-turbo \
    vulkan-loader \
    cairo \
    pango \
    freetype \
    fontconfig \
    libxkbcommon \
    glib2 \
    sdbus-cpp \
    pipewire \
    pam \
    polkit \
    libcurl \
    openssl \
    libwebp \
    libpng \
    lz4 \
    libdrm \
    librsvg2 \
    ffmpegthumbnailer \
    jemalloc \
    lcms2 \
    libarchive \
    poppler-glib \
    wayland \
    hicolor-icon-theme \
    adwaita-icon-theme

if [[ ! -d /ehroot/usr ]]; then
    echo "eh-builder did not stage /ehroot" >&2
    exit 1
fi
cp -a /ehroot/. /

install -d /usr/share/bazzite-horizon
printf '%s\n' "${BAZZITE_HORIZON_BASE:-unset}" > /usr/share/bazzite-horizon/base-image
cp /ctx/event-horizon.ref /usr/share/bazzite-horizon/event-horizon.ref

if ldd /usr/bin/EventHorizon | grep -F 'not found'; then
    echo "EventHorizon is missing shared libraries" >&2
    exit 1
fi

/usr/bin/EventHorizon --version
test -x /usr/bin/event-horizon-session
test -f /usr/share/wayland-sessions/event-horizon.desktop
test -f /usr/share/event-horizon/skel/hypr/hyprland.conf

dnf5 clean all
