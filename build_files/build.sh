#!/usr/bin/env bash
# Final image: Bazzite, plus a Hyprland session, plus the Event Horizon
# binaries staged by build-event-horizon.sh. Plasma stays installed so the
# gear menu on the login screen can still fall back to KDE.
set -eoux pipefail

cp -avf /ctx/system_files/. /
chmod 0755 /usr/bin/event-horizon-session
chmod 0755 /usr/libexec/bazzite-horizon-sdboot-sync


install -d /etc/skel/.config/hypr/eh
cp /usr/share/event-horizon/skel/hypr/hyprland.conf /etc/skel/.config/hypr/hyprland.conf
cp /usr/share/event-horizon/skel/hypr/eh/colors.conf /etc/skel/.config/hypr/eh/colors.conf

if ! dnf5 copr --help >/dev/null 2>&1; then
    dnf5 install -y dnf5-plugins
fi
dnf5 copr enable -y nett00n/hyprland


# Runtime packages only. Build dependencies stayed in the eh-builder stage.
# Names follow Event Horizon's Fedora.md (F43+) plus the Hyprland session
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
    hicolor-icon-theme \
    adwaita-icon-theme \
    systemd-boot

# Bazzite ships xwaylandvideobridge for KDE screen sharing of X11 windows.
# Under Hyprland it only leaves a stray Xwayland window around, so drop it.
# Xwayland itself stays: Steam and most games need it.
if rpm -q xwaylandvideobridge >/dev/null 2>&1; then
    dnf5 remove -y xwaylandvideobridge
fi
rm -f /etc/xdg/autostart/org.kde.xwaylandvideobridge.desktop

# Dialogs Hyprland shows itself (e.g. the ANR "app not responding" prompt).
dnf5 install -y --skip-unavailable hyprland-guiutils
rpm -q hyprland-guiutils || echo "WARNING: hyprland-guiutils is not in the copr; Hyprland will warn at login" >&2

# The seeded config is hyprlang (.conf), and Event Horizon writes its
# colors.conf in that format too. Hyprland 0.57 drops .conf support, so
# refuse to publish an image that would come up with no config at all.
# Remove this guard once the config (and Event Horizon) move to Lua.
hypr_ver=$(rpm -q --qf '%{VERSION}' hyprland)
if [[ "$(printf '%s\n0.57\n' "${hypr_ver}" | sort -V | head -n 1)" == "0.57" ]]; then
    echo "Hyprland ${hypr_ver} no longer reads hyprland.conf; migrate the config to Lua first." >&2
    exit 1
fi

dnf5 copr disable -y nett00n/hyprland || true
rm -f /etc/yum.repos.d/*nett00n*hyprland*.repo

if [[ ! -d /ehroot/usr ]]; then
    echo "eh-builder did not stage /ehroot" >&2
    exit 1
fi
cp -a /ehroot/. /

install -d /usr/share/bazzite-horizon
printf '%s\n' "${BAZZITE_HORIZON_BASE:-unset}" > /usr/share/bazzite-horizon/base-image
cp /ctx/event-horizon.ref /usr/share/bazzite-horizon/event-horizon.ref

case "${BAZZITE_HORIZON_BASE:-}" in
    *nvidia*)
        BOOT_TITLE="Bazzite Horizon NVIDIA"
        ;;
    *)
        BOOT_TITLE="Bazzite Horizon"
        ;;
esac
printf '%s\n' "$BOOT_TITLE" > /usr/share/bazzite-horizon/boot-title
if [[ -f /usr/lib/os-release ]]; then
    if grep -q '^BOOTLOADER_NAME=' /usr/lib/os-release; then
        sed -i "s/^BOOTLOADER_NAME=.*/BOOTLOADER_NAME=\"${BOOT_TITLE}\"/" /usr/lib/os-release
    else
        printf 'BOOTLOADER_NAME="%s"\n' "$BOOT_TITLE" >> /usr/lib/os-release
    fi
fi

if ldd /usr/bin/EventHorizon | grep -F 'not found'; then
    echo "EventHorizon is missing shared libraries" >&2
    exit 1
fi

/usr/bin/EventHorizon --version
test -x /usr/bin/event-horizon-session
test -f /usr/share/wallpapers/convergence.png
test -f /usr/share/wayland-sessions/event-horizon.desktop
test -f /usr/share/event-horizon/skel/hypr/hyprland.conf
test -e /usr/lib/systemd/boot/efi/systemd-bootx64.efi
test -x /usr/libexec/bazzite-horizon-sdboot-sync
test -f /usr/lib/systemd/system/bazzite-horizon-sdboot-sync.service
grep -q . /usr/share/bazzite-horizon/boot-title

# bootupd on this base still installs GRUB. Mask its updater so the
# systemd-boot written by the ISO kickstart is not replaced on first boot.
# systemd-boot-update.service (from the systemd-boot package) owns updates
# of the EFI binary instead. The menu line itself is written by
# bazzite-horizon-sdboot-sync, because systemd-boot only reads the ESP.
# qcow2/raw builds do not run Anaconda, so they stay on bootupd's GRUB.
mkdir -p /etc/systemd/system
ln -sfn /dev/null /etc/systemd/system/bootloader-update.service
enable_unit() {
    local unit=$1
    if systemctl enable "$unit"; then
        return 0
    fi
    local target
    for target in multi-user shutdown; do
        mkdir -p "/etc/systemd/system/${target}.target.wants"
        ln -sfn "/usr/lib/systemd/system/${unit}" \
            "/etc/systemd/system/${target}.target.wants/${unit}"
    done
}
if [[ -e /usr/lib/systemd/system/systemd-boot-update.service ]]; then
    if ! systemctl enable systemd-boot-update.service; then
        mkdir -p /etc/systemd/system/sysinit.target.wants
        ln -sfn /usr/lib/systemd/system/systemd-boot-update.service \
            /etc/systemd/system/sysinit.target.wants/systemd-boot-update.service
    fi
fi
enable_unit bazzite-horizon-sdboot-sync.service

# Services with nothing to do on these machines: ModemManager (cellular
# modems; neither target has one) and gssproxy (Kerberos/NFS). Masked, not
# removed, so `systemctl unmask` brings either back.
for unit in ModemManager.service gssproxy.service; do
    ln -sfn /dev/null "/etc/systemd/system/${unit}"
done

# Event Horizon runs the XDG autostart entries (honouring OnlyShowIn and
# NotShowIn) like any desktop. A few that Bazzite ships for KDE or for VMs
# only fail or duplicate work under Hyprland: vmware-user (VMware guests),
# pam_kwallet_init (KWallet is not running in this session) and the KDE
# UnifiedPush distributor. Hide them from the Hyprland session only; the
# Plasma session still starts them.
for f in /etc/xdg/autostart/*.desktop; do
    [[ -f "$f" ]] || continue
    grep -Eq '^Exec=.*(vmware-user|pam_kwallet_init|kunifiedpush)' "$f" || continue
    if grep -q '^NotShowIn=' "$f"; then
        sed -i 's/^NotShowIn=/NotShowIn=Hyprland;/' "$f"
    else
        sed -i '/^\[Desktop Entry\]/a NotShowIn=Hyprland;' "$f"
    fi
    echo "autostart: not started under Hyprland: $f"
done

# The ISO builder depsolves outside the image. Terra file key
# exists in the image but not in that builder.
sed -i -E 's|gpgkey=file:///etc/pki/rpm-gpg/(RPM-GPG-KEY-terra[^[:space:]]+)|gpgkey=https://raw.githubusercontent.com/terrapkg/packages/frawhide/anda/terra/gpg-keys/\1|g' /etc/yum.repos.d/*.repo

dnf5 clean all
