import{i as e,n as t,r as n,t as r}from"./index-B6jCBdDG.js";var i=r(`check`,[[`path`,{d:`M20 6 9 17l-5-5`,key:`1gmf2c`}]]),a=r(`copy`,[[`rect`,{width:`14`,height:`14`,x:`8`,y:`8`,rx:`2`,ry:`2`,key:`17jyea`}],[`path`,{d:`M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2`,key:`zix9uf`}]]),o=r(`download`,[[`path`,{d:`M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4`,key:`ih7n3h`}],[`polyline`,{points:`7 10 12 15 17 10`,key:`2ggqvy`}],[`line`,{x1:`12`,x2:`12`,y1:`15`,y2:`3`,key:`1vk2je`}]]),s=e(n(),1),c=[{id:`readme`,label:`README`,body:"# Bazzite Horizon\n\nA custom [Universal Blue](https://universal-blue.org) image. Bazzite stays the base, so Steam, Gamescope, the kernel, and the driver stack are still Bazzite's. On top of that is a Hyprland login session whose shell is [Event Horizon](https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell) (ryzendew).\n\nPlasma is not removed. At the login screen, open the session menu and choose **Event Horizon**. KDE is still there if you need it.\n\nThis checkout is the [ublue-os/image-template](https://github.com/ublue-os/image-template) (bootc, GitHub Actions, cosign, bootc-image-builder ISOs), revised the way [theblackdon/dcli-bootc](https://gitlab.com/theblackdon/dcli-bootc) describes an image: one profile, named base images, modules. His desktop on that pattern is KineticOS / KineticWE. This one uses Event Horizon instead.\n\n## Images\n\n| Tag | Base | Use it for |\n| --- | --- | --- |\n| `bazzite-horizon:latest` | `ghcr.io/ublue-os/bazzite:stable` | AMD and Intel |\n| `bazzite-horizon-nvidia:latest` | `ghcr.io/ublue-os/bazzite-nvidia-open:stable` | NVIDIA open module. This is the 5070 Ti / Blackwell image, and it also covers recent GeForce laptops. It is not the older proprietary `bazzite-nvidia` image. |\n\nBoth tags are built from the same Containerfile. `BASE_IMAGE` is the only difference.\n\n## What changed from the three sources\n\n**image-template.** `FROM` is an argument instead of a hard-coded line, so one workflow builds both variants. `disk_config/iso.toml` exists (the template's disk workflow points at it; upstream currently only ships `iso-kde.toml` / `iso-gnome.toml`). Signing no longer fails the build when `SIGNING_SECRET` is still empty.\n\n**Event Horizon Fedora.md.** The package list is the same F43+ set, and the shell is still installed to `/usr`. Three edits so it can live in an image rather than a pet machine:\n\n- The commit is pinned in [`build_files/event-horizon.ref`](build_files/event-horizon.ref). `just install` tracks whatever `main` is today; an image build should not.\n- `-Dnative_march=false`. Upstream's `just install` leaves that option on, which compiles for the build machine's CPU. A GitHub runner binary can SIGILL on a 5800X3D or a 9700X.\n- The compile happens in a throwaway stage. The final image gets `/ehroot` (the binaries, the shared library, the assets) and the runtime libraries, not gcc, meson, or the git checkout. JPEG is on. JPEG XL is off.\n\n**dcli-bootc / KineticWE.** [`profile.yaml`](profile.yaml) and [`modules/`](modules/) are the readable spec in his format, including `base_images.nvidia`. Actions does not run `dcli-bootc gen`. That command would overwrite the Containerfile. Don't run it in this checkout unless you mean to take the generator over.\n\n## Login session\n\n`/usr/share/wayland-sessions/event-horizon.desktop` starts `/usr/bin/event-horizon-session`.\n\nThe first time you log in, that script copies a Hyprland config from `/usr/share/event-horizon/skel` if you don't already have one. It does not touch an existing `~/.config/hypr/hyprland.conf`.\n\nThe seeded config starts the shell with `exec-once = EventHorizon` and sources `~/.config/hypr/eh/colors.conf`, which Event Horizon rewrites when you pick a wallpaper.\n\n| Keys | Action |\n| --- | --- |\n| Super + Enter | kitty |\n| Super + Space | fuzzel |\n| Super + Q | close window |\n| Super + F | fullscreen |\n| Super + V | float |\n| Super + M | exit Hyprland |\n| Super + arrows / HJKL | focus |\n| Super + Shift + arrows | move window |\n| Super + 1–9 | workspace |\n\n`ujust horizon-info` prints the Bazzite variant and `EventHorizon --version` when Bazzite's just importer is active.\n\n## Publish\n\n1. Create a new GitHub repo from this folder (or from image-template, then replace it with these files). Turn Actions on.\n2. Set `REPO_ORGANIZATION` in `image-template.env` to your GitHub user or org. That value is only an OCI label. The push path is `ghcr.io/<repo owner>/…`.\n3. Optional: `COSIGN_PASSWORD=\"\" cosign generate-key-pair`, then store `cosign.key` as the Actions secret `SIGNING_SECRET`. Do not commit the private key. Without the secret the image still publishes; it just isn't signed.\n4. Push to `main`. The **Build container image** workflow publishes both tags. The first run is long: it pulls Bazzite and compiles the shell twice, once per variant.\n5. Rebase a machine that is already on a bootc image:\n\n```bash\n# AMD / Intel\nsudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest\n\n# NVIDIA open (5070 Ti and other recent GeForce)\nsudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest\n```\n\nSwitch only between images that match the GPU. An NVIDIA image on an AMD box, or the reverse, will not come up cleanly.\n\n## ISO\n\nAfter the container workflow has pushed the tag you want:\n\n1. Actions → **Build disk images** → Run workflow.\n2. Pick `bazzite-horizon` or `bazzite-horizon-nvidia`. Leave platform on `amd64` unless you know you want the arm runner.\n3. Download the `anaconda-iso` artifact. The workflow rewrites `GHCR_IMAGE` in `disk_config/iso.toml` to the tag you picked, then bootc-image-builder makes the installer.\n\nThe ISO is an installer, not a live desktop. Boot it, install, then choose **Event Horizon** at the login screen.\n\n## Bump Event Horizon\n\n`build_files/event-horizon.ref` is one commit hash, currently `696be1a855a2c682e15765a92cc189f1f8de84be` (0.9.7.3-beta-3 era). Replace the hash and push. The builder fetches that commit and its submodules (the Inter font submodule is required; a non-recursive clone fails the way Fedora.md describes).\n\n## Local build\n\nFrom a machine with podman, and this directory as a git checkout (the Justfile skips some labels when the tree is dirty):\n\n```bash\n# edit REPO_ORGANIZATION first\njust build\nBASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia-open:stable just build bazzite-horizon-nvidia latest\n```\n\n## License\n\nThe image-template scaffold is Apache-2.0, included here as `LICENSE`. Event Horizon itself is MIT and is fetched at build time; it is not vendored in this repo.\n"},{id:`containerfile`,label:`Containerfile`,body:`# Bazzite Horizon
# Scaffold from ublue-os/image-template. Event Horizon is compiled in a
# throwaway stage so the compiler toolchain does not land in the image.
# BASE_IMAGE selects the Bazzite variant (AMD/Intel or NVIDIA open).

FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite:stable

FROM \${BASE_IMAGE} AS eh-builder
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \\
    --mount=type=cache,dst=/var/cache \\
    --mount=type=cache,dst=/var/log \\
    --mount=type=tmpfs,dst=/tmp \\
    bash /ctx/build-event-horizon.sh

FROM \${BASE_IMAGE}
ARG BASE_IMAGE
ENV BAZZITE_HORIZON_BASE=\${BASE_IMAGE}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \\
    --mount=type=bind,from=eh-builder,source=/ehroot,target=/ehroot \\
    --mount=type=cache,dst=/var/cache \\
    --mount=type=cache,dst=/var/log \\
    --mount=type=tmpfs,dst=/tmp \\
    bash /ctx/build.sh

RUN bootc container lint
`},{id:`compile`,label:`Compile`,body:`#!/usr/bin/env bash
# Compile Event Horizon Shell and stage it under /ehroot.
# The final image copies /ehroot and does not keep this toolchain.
#
# Upstream Fedora.md says \`sudo just install\`. That is correct on a personal
# machine and wrong for a published image: \`just install\` leaves
# -Dnative_march=true, which tunes the binary for the build CPU (a GitHub
# runner) and can SIGILL everywhere else. This script pins a commit and
# forces a portable release build.
set -eoux pipefail

EH_REPO="\${EH_REPO:-https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell.git}"
EH_REF="$(tr -d '[:space:]' < /ctx/event-horizon.ref)"

dnf5 install -y \\
    git \\
    meson \\
    gcc \\
    gcc-c++ \\
    cmake \\
    mold \\
    ninja-build \\
    pkgconf-pkg-config \\
    python3 \\
    libjpeg-turbo-devel \\
    wayland-devel \\
    wayland-protocols-devel \\
    vulkan-loader-devel \\
    vulkan-headers \\
    freetype-devel \\
    fontconfig-devel \\
    cairo-devel \\
    pango-devel \\
    libxkbcommon-devel \\
    glib2-devel \\
    sdbus-cpp-devel \\
    pipewire-devel \\
    pam-devel \\
    polkit-devel \\
    libcurl-devel \\
    openssl-devel \\
    libwebp-devel \\
    libpng-devel \\
    lz4-devel \\
    libdrm-devel \\
    librsvg2-devel \\
    ffmpegthumbnailer-devel \\
    jemalloc-devel \\
    lcms2-devel \\
    libarchive-devel \\
    poppler-glib-devel

src=/eh-src
rm -rf "\${src}"
mkdir -p "\${src}"
git -C "\${src}" init
git -C "\${src}" remote add origin "\${EH_REPO}"
git -C "\${src}" fetch --depth 1 origin "\${EH_REF}"
git -C "\${src}" checkout --detach FETCH_HEAD
git -C "\${src}" submodule update --init --recursive --depth 1

cd "\${src}"
meson setup build-release \\
    --buildtype=release \\
    --prefix=/usr \\
    -Dembed_assets=false \\
    -Dnative_march=false \\
    -Djpeg=true \\
    -Djxl=false \\
    -Dcpp_link_args=-fuse-ld=mold \\
    -Dc_link_args=-fuse-ld=mold \\
    -Dunity=subprojects

meson compile -C build-release
rm -rf /ehroot
DESTDIR=/ehroot meson install -C build-release

test -x /ehroot/usr/bin/EventHorizon
echo "Staged Event Horizon \${EH_REF}"
`},{id:`image`,label:`Image`,body:`#!/usr/bin/env bash
# Final image: Bazzite, plus a Hyprland session, plus the Event Horizon
# binaries staged by build-event-horizon.sh. Plasma stays installed so the
# gear menu on the login screen can still fall back to KDE.
set -eoux pipefail

cp -avf /ctx/system_files/. /
chmod 0755 /usr/bin/event-horizon-session

# Runtime packages only. Build dependencies stayed in the eh-builder stage.
# Names follow Event Horizon's Fedora.md (F43+) plus the Hyprland session
# that page says the shell has to run inside.
dnf5 install -y \\
    hyprland \\
    xdg-desktop-portal \\
    xdg-desktop-portal-hyprland \\
    xdg-desktop-portal-gtk \\
    grim \\
    slurp \\
    wl-clipboard \\
    brightnessctl \\
    kitty \\
    fuzzel \\
    libjpeg-turbo \\
    vulkan-loader \\
    cairo \\
    pango \\
    freetype \\
    fontconfig \\
    libxkbcommon \\
    glib2 \\
    sdbus-cpp \\
    pipewire \\
    pam \\
    polkit \\
    libcurl \\
    openssl \\
    libwebp \\
    libpng \\
    lz4 \\
    libdrm \\
    librsvg2 \\
    ffmpegthumbnailer \\
    jemalloc \\
    lcms2 \\
    libarchive \\
    poppler-glib \\
    wayland \\
    hicolor-icon-theme \\
    adwaita-icon-theme

if [[ ! -d /ehroot/usr ]]; then
    echo "eh-builder did not stage /ehroot" >&2
    exit 1
fi
cp -a /ehroot/. /

install -d /usr/share/bazzite-horizon
printf '%s\\n' "\${BAZZITE_HORIZON_BASE:-unset}" > /usr/share/bazzite-horizon/base-image
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
`},{id:`hyprland`,label:`Hyprland`,body:`# Seeded once by /usr/bin/event-horizon-session.
# Later logins keep your edits. Move this file aside to reseed.
# Color matching: Event Horizon rewrites ~/.config/hypr/eh/colors.conf
# when you pick a wallpaper (see upstream Docs/Setup.md).

source = ~/.config/hypr/eh/colors.conf

monitor=,preferred,auto,auto

env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland,x11
env = ELECTRON_OZONE_PLATFORM_HINT,auto

input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
    touchpad {
        natural_scroll = true
        disable_while_typing = true
    }
}

general {
    gaps_in = 4
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(e4a15aee)
    col.inactive_border = rgba(2c3038aa)
    layout = dwindle
}

decoration {
    rounding = 10
}

animations {
    enabled = true
}

dwindle {
    pseudotile = true
    preserve_split = true
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
exec-once = EventHorizon

bind = SUPER, Return, exec, kitty
bind = SUPER, Q, killactive
bind = SUPER, M, exit
bind = SUPER, F, fullscreen, 0
bind = SUPER, Space, exec, fuzzel
bind = SUPER, V, togglefloating
bind = SUPER, P, pseudo
bind = SUPER, T, togglesplit

bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

bind = SUPER, H, movefocus, l
bind = SUPER, L, movefocus, r
bind = SUPER, K, movefocus, u
bind = SUPER, J, movefocus, d

bind = SUPER SHIFT, left, movewindow, l
bind = SUPER SHIFT, right, movewindow, r
bind = SUPER SHIFT, up, movewindow, u
bind = SUPER SHIFT, down, movewindow, d

bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9

bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9

bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow
`},{id:`profile`,label:`Profile`,body:`# Declarative view of this image, in the shape theblackdon's dcli-bootc uses
# (profile + base_images + modules). KineticOS / KineticWE is his desktop.
# This profile keeps Bazzite and swaps the shell for Event Horizon.
#
# GitHub Actions does not run \`dcli-bootc gen\`. The files it builds are
# Containerfile and build_files/*.sh. Running gen in this checkout would
# overwrite those. Treat this YAML as the readable spec.

name: bazzite-horizon
base_image: ghcr.io/ublue-os/bazzite:stable
default_tag: latest
package_manager: dnf

base_images:
  # Open kernel module. This is the one for RTX 50-series (5070 Ti) and
  # recent GeForce laptops. It is not bazzite-nvidia (legacy proprietary).
  nvidia: ghcr.io/ublue-os/bazzite-nvidia-open:stable

enabled_modules:
  - hyprland-session
  - event-horizon
`}],l=`696be1a855a2c682e15765a92cc189f1f8de84be`,u=t(),d=[{name:`Fedora bootc`,detail:`The immutable base Universal Blue already tracks.`},{name:`Bazzite`,detail:`Gaming stack, kernel, Steam, Gamescope, drivers. Left intact.`},{name:`Hyprland`,detail:`A login session next to Plasma, not a replacement of KDE.`},{name:`Event Horizon`,detail:`ryzendew's shell. Dock, panel, and the rest, started with the session.`}],f=[[`Super + Enter`,`kitty`],[`Super + Space`,`fuzzel`],[`Super + Q`,`close window`],[`Super + M`,`leave Hyprland`],[`Super + arrows`,`move focus`],[`Super + 1–9`,`workspace`]];function p(){let[e,t]=(0,s.useState)(c[0].id),[n,r]=(0,s.useState)(!1),p=c.find(t=>t.id===e)??c[0];async function m(){try{await navigator.clipboard.writeText(p.body),r(!0),window.setTimeout(()=>r(!1),1600)}catch{r(!1)}}return(0,u.jsxs)(`main`,{className:`mx-auto flex w-full max-w-3xl flex-col gap-10 px-5 py-10 sm:py-14`,children:[(0,u.jsxs)(`header`,{className:`flex flex-col gap-4`,children:[(0,u.jsx)(`p`,{className:`text-sm font-medium tracking-wide text-accent uppercase`,children:`Universal Blue image`}),(0,u.jsx)(`h1`,{className:`font-display text-5xl leading-none text-fg sm:text-6xl`,children:`Horizon Forge`}),(0,u.jsx)(`p`,{className:`max-w-xl text-lg text-muted`,children:`A Bazzite image with Event Horizon as the shell. Same bootc idea as theblackdon's KineticOS, pointed at ryzendew's desktop instead of KineticWE.`}),(0,u.jsx)(`div`,{className:`h-px w-16 bg-accent`})]}),(0,u.jsxs)(`section`,{className:`grid gap-3 sm:grid-cols-2`,"aria-label":`Image variants`,children:[(0,u.jsxs)(`article`,{className:`flex flex-col gap-2 rounded-card border border-line bg-surface p-5`,children:[(0,u.jsx)(`h2`,{className:`font-display text-2xl text-fg`,children:`AMD and Intel`}),(0,u.jsx)(`p`,{className:`font-mono text-sm text-accent`,children:`bazzite-horizon`}),(0,u.jsx)(`p`,{className:`text-sm text-muted`,children:`Built from bazzite:stable. Use this tag on machines without an NVIDIA GPU.`})]}),(0,u.jsxs)(`article`,{className:`flex flex-col gap-2 rounded-card border border-line bg-surface p-5`,children:[(0,u.jsx)(`h2`,{className:`font-display text-2xl text-fg`,children:`NVIDIA open`}),(0,u.jsx)(`p`,{className:`font-mono text-sm text-accent`,children:`bazzite-horizon-nvidia`}),(0,u.jsx)(`p`,{className:`text-sm text-muted`,children:`Built from bazzite-nvidia-open. This is the Blackwell image, including a 5070 Ti. Not the older proprietary driver tag.`})]})]}),(0,u.jsxs)(`section`,{className:`flex flex-col gap-4`,children:[(0,u.jsx)(`h2`,{className:`font-display text-3xl text-fg`,children:`Stack`}),(0,u.jsx)(`ol`,{className:`flex flex-col`,children:d.map((e,t)=>(0,u.jsxs)(`li`,{className:`grid grid-cols-[2.5rem_1fr] gap-3 border-t border-line py-4`,children:[(0,u.jsxs)(`span`,{className:`font-mono text-sm text-accent`,children:[`0`,t+1]}),(0,u.jsxs)(`div`,{children:[(0,u.jsx)(`p`,{className:`font-medium text-fg`,children:e.name}),(0,u.jsx)(`p`,{className:`text-sm text-muted`,children:e.detail})]})]},e.name))})]}),(0,u.jsxs)(`section`,{className:`flex flex-col gap-4`,children:[(0,u.jsx)(`h2`,{className:`font-display text-3xl text-fg`,children:`What was revised`}),(0,u.jsxs)(`ul`,{className:`flex flex-col gap-3`,children:[(0,u.jsxs)(`li`,{className:`rounded-card border border-line bg-surface p-5`,children:[(0,u.jsx)(`p`,{className:`font-medium text-fg`,children:`Portable shell, pinned commit`}),(0,u.jsxs)(`p`,{className:`mt-1 text-sm text-muted`,children:[`Fedora.md's `,(0,u.jsx)(`span`,{className:`text-fg`,children:`sudo just install`}),` compiles with`,` `,(0,u.jsx)(`span`,{className:`text-fg`,children:`-Dnative_march=true`}),`. That binary matches the GitHub runner, then faults on other CPUs. The image build pins`,` `,(0,u.jsx)(`span`,{className:`font-mono text-xs text-accent`,children:l.slice(0,12)}),` and forces a generic release build. The compiler stays out of the final image.`]})]}),(0,u.jsxs)(`li`,{className:`rounded-card border border-line bg-surface p-5`,children:[(0,u.jsx)(`p`,{className:`font-medium text-fg`,children:`One Containerfile, two Bazzite bases`}),(0,u.jsx)(`p`,{className:`mt-1 text-sm text-muted`,children:`image-template hard-codes a single FROM line. This one takes BASE_IMAGE, the same split dcli-bootc puts under base_images. Plasma is still installed.`})]}),(0,u.jsxs)(`li`,{className:`rounded-card border border-line bg-surface p-5`,children:[(0,u.jsx)(`p`,{className:`font-medium text-fg`,children:`A session, not a second distro`}),(0,u.jsx)(`p`,{className:`mt-1 text-sm text-muted`,children:`The login screen gains an Event Horizon entry. First login seeds Hyprland only if you don't already have a config. KDE remains the fallback.`})]})]})]}),(0,u.jsxs)(`section`,{className:`flex flex-col gap-4`,children:[(0,u.jsx)(`h2`,{className:`font-display text-3xl text-fg`,children:`Seeded keys`}),(0,u.jsx)(`div`,{className:`overflow-hidden rounded-card border border-line`,children:f.map(([e,t])=>(0,u.jsxs)(`div`,{className:`grid grid-cols-2 gap-3 border-t border-line px-4 py-3 first:border-t-0`,children:[(0,u.jsx)(`span`,{className:`text-sm text-fg`,children:e}),(0,u.jsx)(`span`,{className:`text-sm text-muted`,children:t})]},e))})]}),(0,u.jsxs)(`section`,{className:`flex flex-col gap-4`,children:[(0,u.jsxs)(`div`,{className:`flex items-end justify-between gap-3`,children:[(0,u.jsx)(`h2`,{className:`font-display text-3xl text-fg`,children:`Recipe`}),(0,u.jsxs)(`button`,{type:`button`,onClick:m,className:`inline-flex min-h-11 items-center gap-2 rounded-card border border-line bg-raised px-4 text-sm text-fg`,children:[n?(0,u.jsx)(i,{className:`size-4 text-accent`}):(0,u.jsx)(a,{className:`size-4`}),n?`Copied`:`Copy`]})]}),(0,u.jsx)(`div`,{role:`tablist`,"aria-label":`Recipe files`,className:`flex gap-2 overflow-x-auto pb-1`,children:c.map(e=>{let n=e.id===p.id;return(0,u.jsx)(`button`,{type:`button`,role:`tab`,"aria-selected":n,onClick:()=>{t(e.id),r(!1)},className:n?`min-h-11 shrink-0 rounded-card bg-accent px-4 text-sm font-medium text-accent-ink`:`min-h-11 shrink-0 rounded-card border border-line bg-surface px-4 text-sm text-muted`,children:e.label},e.id)})}),(0,u.jsx)(`pre`,{className:`max-h-96 overflow-auto rounded-card border border-line bg-raised p-4 font-mono text-xs leading-relaxed text-fg`,children:p.body})]}),(0,u.jsxs)(`section`,{className:`flex flex-col gap-4`,children:[(0,u.jsx)(`h2`,{className:`font-display text-3xl text-fg`,children:`Publish`}),(0,u.jsxs)(`ol`,{className:`flex flex-col gap-4`,children:[(0,u.jsxs)(`li`,{className:`flex gap-3`,children:[(0,u.jsx)(`span`,{className:`font-mono text-sm text-accent`,children:`1`}),(0,u.jsx)(`p`,{className:`text-sm text-muted`,children:`Download the recipe and push it to a new GitHub repository. Turn Actions on. Set REPO_ORGANIZATION in image-template.env to that account.`})]}),(0,u.jsxs)(`li`,{className:`flex gap-3`,children:[(0,u.jsx)(`span`,{className:`font-mono text-sm text-accent`,children:`2`}),(0,u.jsx)(`p`,{className:`text-sm text-muted`,children:`Push to main. The container workflow publishes both tags. The first run pulls Bazzite and compiles the shell, so it takes a while. Signing is optional until you add a SIGNING_SECRET.`})]}),(0,u.jsxs)(`li`,{className:`flex gap-3`,children:[(0,u.jsx)(`span`,{className:`font-mono text-sm text-accent`,children:`3`}),(0,u.jsx)(`p`,{className:`text-sm text-muted`,children:`On a machine already running a bootc image, switch to the tag that matches the GPU. Or run the disk-image workflow and install from the ISO, then pick Event Horizon at the login screen.`})]})]}),(0,u.jsxs)(`div`,{className:`rounded-card border border-line bg-surface p-5 font-mono text-xs leading-relaxed text-fg`,children:[(0,u.jsx)(`p`,{children:`sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest`}),(0,u.jsx)(`p`,{className:`mt-2 text-muted`,children:`sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest`})]}),(0,u.jsxs)(`a`,{href:`/bazzite-horizon.zip`,download:!0,className:`inline-flex min-h-11 items-center justify-center gap-2 rounded-card bg-accent px-5 text-sm font-medium text-accent-ink`,children:[(0,u.jsx)(o,{className:`size-4`}),`Download the recipe`]}),(0,u.jsx)(`p`,{className:`text-sm text-muted`,children:`The ISO is built by GitHub after the container image exists. This page is the blueprint and the files, not a flashed installer.`})]}),(0,u.jsx)(`footer`,{className:`border-t border-line pt-6 text-sm text-muted`,children:(0,u.jsxs)(`p`,{children:[`Shell docs:`,` `,(0,u.jsx)(`a`,{className:`text-fg underline decoration-line underline-offset-4`,href:`https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell/blob/main/Docs/Fedora.md`,children:`Event Horizon on Fedora`}),`. Image scaffold:`,` `,(0,u.jsx)(`a`,{className:`text-fg underline decoration-line underline-offset-4`,href:`https://github.com/ublue-os/image-template`,children:`ublue-os/image-template`}),`. Layout reference:`,` `,(0,u.jsx)(`a`,{className:`text-fg underline decoration-line underline-offset-4`,href:`https://gitlab.com/theblackdon/dcli-bootc`,children:`dcli-bootc`}),`.`]})})]})}function m(){return(0,u.jsx)(p,{})}export{m as component};