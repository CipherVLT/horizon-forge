#!/usr/bin/env bash
# Compile Event Horizon Shell and stage it under /ehroot.
# The final image copies /ehroot and does not keep this toolchain.
#
# Upstream Fedora.md says `sudo just install`. That is correct on a personal
# machine and wrong for a published image: `just install` leaves
# -Dnative_march=true, which tunes the binary for the build CPU (a GitHub
# runner) and can SIGILL everywhere else. This script pins a commit and
# forces a portable release build.
set -eoux pipefail

EH_REPO="${EH_REPO:-https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell.git}"
EH_REF="$(tr -d '[:space:]' < /ctx/event-horizon.ref)"

dnf5 install -y \
    git \
    meson \
    gcc \
    gcc-c++ \
    cmake \
    mold \
    ninja-build \
    pkgconf-pkg-config \
    python3 \
    libjpeg-turbo-devel \
    wayland-devel \
    wayland-protocols-devel \
    vulkan-loader-devel \
    vulkan-headers \
    freetype-devel \
    fontconfig-devel \
    cairo-devel \
    pango-devel \
    libxkbcommon-devel \
    glib2-devel \
    sdbus-cpp-devel \
    pipewire-devel \
    pam-devel \
    polkit-devel \
    libcurl-devel \
    openssl-devel \
    libwebp-devel \
    libpng-devel \
    lz4-devel \
    libdrm-devel \
    librsvg2-devel \
    ffmpegthumbnailer-devel \
    jemalloc-devel \
    lcms2-devel \
    libarchive-devel \
    poppler-glib-devel

src=/eh-src
rm -rf "${src}"
mkdir -p "${src}"
git -C "${src}" init
git -C "${src}" remote add origin "${EH_REPO}"
git -C "${src}" fetch --depth 1 origin "${EH_REF}"
git -C "${src}" checkout --detach FETCH_HEAD
git -C "${src}" submodule update --init --recursive --depth 1

cd "${src}"
meson setup build-release \
    --buildtype=release \
    --prefix=/usr \
    -Dembed_assets=false \
    -Dnative_march=false \
    -Djpeg=true \
    -Djxl=false \
    -Dcpp_link_args=-fuse-ld=mold \
    -Dc_link_args=-fuse-ld=mold \
    -Dunity=subprojects

meson compile -C build-release
rm -rf /ehroot
DESTDIR=/ehroot meson install -C build-release

test -x /ehroot/usr/bin/EventHorizon
echo "Staged Event Horizon ${EH_REF}"
