#!/usr/bin/env bash
# Install Strata (https://github.com/lgse/strata, MIT), a GTK4 file manager,
# from its official x86_64 release archive.
#
# strata.ref pins "<version> <sha256 of the .tar.gz>". The archive is checked
# against that hash before anything is installed, so a changed or tampered
# download fails the build. To update: put the new version and the hash from
# the release's .tar.gz.sha256 asset into strata.ref.
#
# Strata is the file manager: the folder handler in the Hyprland session
# (trim-desktop.sh writes hyprland-mimeapps.list) and the
# org.freedesktop.FileManager1 D-Bus service that "Show in folder" in
# Firefox, Steam and others calls. Its file-chooser portal is left opt-in
# (Strata > Settings > General > System file chooser); Open/Save dialogs
# stay on the KDE portal until a user turns it on.
set -euo pipefail
# Show the failing line on the GitHub run page (as an annotation).
trap 'echo "::error title=install-strata.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

read -r version sha256 < /ctx/strata.ref
arch=$(uname -m)
if [[ "${arch}" != x86_64 ]]; then
    echo "Strata: no ${arch} build pinned, skipping" >&2
    exit 0
fi

package="strata-${version}-x86_64-unknown-linux-gnu"
url="https://github.com/lgse/strata/releases/download/v${version}/${package}.tar.gz"

# Runtime libraries the binary links against (gtk4, gtksourceview5,
# poppler-glib, gstreamer) and what its previews use.
dnf5 install -y \
    gtk4 \
    gtksourceview5 \
    poppler-glib \
    graphene \
    gstreamer1 \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gvfs \
    bubblewrap \
    ffmpegthumbnailer \
    xdg-utils \
    desktop-file-utils

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT
curl --fail --location --silent --show-error --retry 3 -o "${work}/strata.tar.gz" "${url}"
echo "${sha256}  ${work}/strata.tar.gz" | sha256sum -c -
tar -xzf "${work}/strata.tar.gz" -C "${work}"
src="${work}/${package}"

# The binary lives in /usr/libexec; /usr/bin/strata (system_files) is a
# wrapper that runs a copy in ~/.local/bin so Strata's own updater works.
install -Dm755 "${src}/strata" /usr/libexec/strata/strata
test -x /usr/bin/strata
install -Dm644 "${src}/io.github.lgse.Strata.desktop" \
    /usr/share/applications/io.github.lgse.Strata.desktop
install -Dm644 "${src}/io.github.lgse.Strata.svg" \
    /usr/share/icons/hicolor/scalable/apps/io.github.lgse.Strata.svg
install -Dm644 -t /usr/share/licenses/strata \
    "${src}/LICENSE" "${src}/THIRD_PARTY_LICENSES.md" "${src}/UnRAR.txt"
install -Dm644 "${src}/SOURCE_COMMIT" /usr/share/licenses/strata/SOURCE_COMMIT

# "Show in folder" from other apps. dbus-broker wants the file named after
# the bus name it provides.
install -Dm644 "${src}/io.github.lgse.Strata.FileManager1.service" \
    /usr/share/dbus-1/services/org.freedesktop.FileManager1.service
grep -q '^Exec=/usr/bin/strata ' /usr/share/dbus-1/services/org.freedesktop.FileManager1.service

desktop-file-validate /usr/share/applications/io.github.lgse.Strata.desktop
if ldd /usr/libexec/strata/strata | grep -F 'not found'; then
    echo "Strata is missing shared libraries" >&2
    exit 1
fi
echo "Installed Strata ${version} ($(cat "${src}/SOURCE_COMMIT"))"
