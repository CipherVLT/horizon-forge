#!/usr/bin/env bash
# Compile Event Horizon (the Zig rewrite) and stage it under /ehroot.
# The final image copies /ehroot and does not keep this toolchain.
#
# Upstream: https://github.com/Event-Horizon-desktop-environment/Event-Horizon
# (MIT). The earlier C++/Meson repository (Event-Horizon-Shell) is gone; the
# Zig tree replaced it. event-horizon.ref pins the upstream commit.
#
# Upstream's build.sh auto-detects the build CPU's x86-64 level, which would
# tune the binaries for a GitHub runner. This script pins x86-64-v2 instead
# (every x86-64 CPU since ~2009), so the image runs on all supported hardware.
set -eoux pipefail
# Show the failing line on the GitHub run page (as an annotation).
trap 'echo "::error title=build-event-horizon.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

EH_REPO="${EH_REPO:-https://github.com/Event-Horizon-desktop-environment/Event-Horizon.git}"
EH_REF="$(tr -d '[:space:]' < /ctx/event-horizon.ref)"
EH_CPU=x86_64_v2
# ReleaseFast like upstream's build.sh. ReleaseSafe also builds (see the
# _FORTIFY_SOURCE note below) and is handy for chasing crashes.
EH_OPTIMIZE=ReleaseFast

# Zig toolchain: the release tarball from ziglang.org, verified against the
# Zig Software Foundation's minisign key before use.
ZIG_VERSION=0.16.0
ZIG_PUBKEY='RWSGOq2NVecA2UPNdBUZykf1CCb147pkmdtYxgb3Ti+JO/wCYvhbAb/U'

dnf5 install -y \
    git \
    curl \
    xz \
    minisign \
    pkgconf-pkg-config \
    wayland-devel \
    wayland-protocols-devel \
    libxkbcommon-devel \
    cairo-devel \
    pango-devel \
    librsvg2-devel \
    libwebp-devel \
    pipewire-devel

zig_dir=/tmp/zig
mkdir -p "${zig_dir}"
zig_ok=0
for name in "zig-x86_64-linux-${ZIG_VERSION}" "zig-linux-x86_64-${ZIG_VERSION}"; do
    url="https://ziglang.org/download/${ZIG_VERSION}/${name}.tar.xz"
    if curl --fail --location --silent --show-error --retry 3 -o "${zig_dir}/zig.tar.xz" "${url}" &&
        curl --fail --location --silent --show-error --retry 3 -o "${zig_dir}/zig.tar.xz.minisig" "${url}.minisig"; then
        zig_ok=1
        break
    fi
done
(( zig_ok )) || { echo "could not download Zig ${ZIG_VERSION}" >&2; exit 1; }
minisign -V -P "${ZIG_PUBKEY}" -m "${zig_dir}/zig.tar.xz" -x "${zig_dir}/zig.tar.xz.minisig"
sha256sum "${zig_dir}/zig.tar.xz"
tar -xJf "${zig_dir}/zig.tar.xz" -C "${zig_dir}" --strip-components=1
ZIG="${zig_dir}/zig"
"${ZIG}" version
export ZIG_GLOBAL_CACHE_DIR=/tmp/zig-global-cache ZIG_LOCAL_CACHE_DIR=/tmp/zig-local-cache

src=/eh-src
rm -rf "${src}"
mkdir -p "${src}"
git -C "${src}" init
git -C "${src}" remote add origin "${EH_REPO}"
git -C "${src}" fetch --depth 1 origin "${EH_REF}"
git -C "${src}" checkout --detach FETCH_HEAD
git -C "${src}" submodule update --init --recursive --depth 1

cd "${src}"
# Safe builds turn on glibc's _FORTIFY_SOURCE wrappers, and Zig's C
# translation cannot handle some of them (gethostname: "expected c_int,
# found bool"). Undefine it inside every @cImport for non-fast builds; Zig's
# own safety checks, the reason for the safe build, are unaffected.
if [[ "${EH_OPTIMIZE}" != ReleaseFast ]]; then
    grep -rl --include='*.zig' '@cImport({' src | while read -r f; do
        sed -i 's/@cImport({/@cImport({ @cUndef("_FORTIFY_SOURCE");/' "${f}"
    done
    grep -rl --include='*.zig' '@cImport(@cInclude(' src | while read -r f; do
        sed -i -E 's/@cImport\(@cInclude\(("[^"]+")\)\)/@cImport({ @cUndef("_FORTIFY_SOURCE"); @cInclude(\1); })/' "${f}"
    done
fi

# Local patch: double free in the dock's audio poll. With pactl installed
# (Bazzite ships it), live_audio.query() moves the four `pactl list` outputs
# into the returned Queried (q.sinks_text = sinks_text, ...) but also frees
# them on return with `defer`. Queried.deinit frees them again on the next
# poll, so horizon-dock aborts every few seconds ("double free or corruption")
# and the parsed device names point at freed memory meanwhile. Drop the four
# defers: Queried owns the buffers. Fails the build if upstream changes the
# code, so the patch is re-checked instead of silently skipped.
python3 - <<'PY'
import pathlib, sys
p = pathlib.Path("src/desktop_shell/controlcenter/live_audio.zig")
s = p.read_text()
for name in ("sinks_text", "sources_text", "in_text", "out_text"):
    target = f"    defer if ({name}) |s| alloc.free(s);\n"
    owner = f"    q.{name} = {name};\n"
    if s.count(target) != 1 or s.count(owner) != 1:
        sys.exit(f"horizon-forge audio patch: expected one '{target.strip()}' and one '{owner.strip()}' in {p}")
    s = s.replace(target, f"    // horizon-forge: owned by Queried (freed in deinit), no defer free\n")
p.write_text(s)
print("horizon-forge: patched double free in live_audio.query")
PY

# Compiler errors as GitHub annotations, so they show on the run page.
if ! "${ZIG}" build "-Doptimize=${EH_OPTIMIZE}" "-Dcpu=${EH_CPU}" 2>/tmp/zig-build.err; then
    cat /tmp/zig-build.err >&2
    grep -E 'error:|note:' /tmp/zig-build.err | head -n 12 | sed 's/^/::error title=zig build::/'
    exit 1
fi

# Install exactly the binaries upstream's build.sh installs, read from it so
# a new component is picked up automatically. The supervisor (horizon)
# starts its components from its own directory, so they all go in /usr/bin.
mapfile -t binaries < <(awk '/^INSTALL_BINARIES=\(/{f=1; next} f && /^\)/{exit} f {gsub(/^[ \t]+|[ \t]+$/, ""); if ($0 != "") print}' build.sh)
(( ${#binaries[@]} > 0 )) || { echo "could not read INSTALL_BINARIES from upstream build.sh" >&2; exit 1; }
rm -rf /ehroot
install -d /ehroot/usr/bin /ehroot/usr/share
for name in "${binaries[@]}"; do
    install -m755 "zig-out/bin/${name}" "/ehroot/usr/bin/${name}"
done
"${ZIG}" build install-icons --prefix /ehroot/usr/share

test -x /ehroot/usr/bin/horizon
echo "Staged Event Horizon ${EH_REF}: ${binaries[*]}"
