#!/usr/bin/env bash
# Compile Event Horizon Shell and stage it under /ehroot.
# The final image copies /ehroot and does not keep this toolchain.
#
# Upstream Fedora.md says `sudo just install`. That is correct on a personal
# machine and wrong for a published image: `just install` leaves
# -Dnative_march=true, which tunes the binary for the build CPU (a GitHub
# runner) and can SIGILL everywhere else. This script pins a commit and
# forces a portable release build. event-horizon.ref pins the upstream
# commit; 4a4cd77 is tag 0.9.7.4-beta-3.
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
# Local patch: the desktop icon layer and the desktop widget layer are
# full-screen surfaces, and both ask the compositor (ext-background-effect-v1)
# to blur everything behind their whole area. On a Hyprland that implements
# that protocol the result is a permanently blurred wallpaper. Drop those two
# requests; popup menus keep their blur. Fails the build if upstream moves the
# code, so the patch is re-checked instead of silently skipped.
python3 - <<'PY'
import pathlib, sys
p = pathlib.Path("src/desktop_shell/desktop/core/desktop_layer.cpp")
s = p.read_text()
for target in (
    "L->bgEffect = ext_background_effect_manager_v1_get_background_effect(mgr, L->surface);",
    "L->widgetBgEffect = ext_background_effect_manager_v1_get_background_effect(mgr, L->widgetSurface);",
):
    if s.count(target) != 1:
        sys.exit(f"horizon-forge blur patch: expected one '{target}' in {p}")
    s = s.replace(target, "/* horizon-forge: no full-screen background blur */")
p.write_text(s)
print("horizon-forge: patched out full-screen desktop blur")
PY

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
