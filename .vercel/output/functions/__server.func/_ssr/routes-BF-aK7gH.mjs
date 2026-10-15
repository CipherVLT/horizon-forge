import { i as __toESM } from "../_runtime.mjs";
import { K as require_react, b as require_jsx_runtime } from "../_libs/@tanstack/react-router+[...].mjs";
import { i as Check, n as Download, r as Copy } from "../_libs/lucide-react.mjs";
//#region node_modules/.nitro/vite/services/ssr/assets/routes-BF-aK7gH.js
var import_react = /* @__PURE__ */ __toESM(require_react());
var import_jsx_runtime = require_jsx_runtime();
var recipeFiles = [
	{
		id: "readme",
		label: "README",
		body: "# Bazzite Horizon\n\nA custom [Universal Blue](https://universal-blue.org) image. Bazzite stays the base, so Steam, Gamescope, the kernel, and the driver stack are still Bazzite's. On top of that is a Hyprland login session whose shell is [Event Horizon](https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell) (ryzendew).\n\nPlasma is not removed. At the login screen, open the session menu and choose **Event Horizon**. KDE is still there if you need it.\n\nThis checkout is the [ublue-os/image-template](https://github.com/ublue-os/image-template) (bootc, GitHub Actions, cosign, bootc-image-builder ISOs), revised the way [theblackdon/dcli-bootc](https://gitlab.com/theblackdon/dcli-bootc) describes an image: one profile, named base images, modules. His desktop on that pattern is KineticOS / KineticWE. This one uses Event Horizon instead.\n\n## Images\n\n| Tag | Base | Use it for |\n| --- | --- | --- |\n| `bazzite-horizon:latest` | `ghcr.io/ublue-os/bazzite:stable` | AMD and Intel |\n| `bazzite-horizon-nvidia:latest` | `ghcr.io/ublue-os/bazzite-nvidia-open:stable` | NVIDIA open module. This is the 5070 Ti / Blackwell image, and it also covers recent GeForce laptops. It is not the older proprietary `bazzite-nvidia` image. |\n\nBoth tags are built from the same Containerfile. `BASE_IMAGE` is the only difference.\n\n## What changed from the three sources\n\n**image-template.** `FROM` is an argument instead of a hard-coded line, so one workflow builds both variants. `disk_config/iso.toml` exists (the template's disk workflow points at it; upstream currently only ships `iso-kde.toml` / `iso-gnome.toml`). Signing no longer fails the build when `SIGNING_SECRET` is still empty.\n\n**Event Horizon Fedora.md.** The package list is the same F43+ set, and the shell is still installed to `/usr`. Three edits so it can live in an image rather than a pet machine:\n\n- The commit is pinned in [`build_files/event-horizon.ref`](build_files/event-horizon.ref). `just install` tracks whatever `main` is today; an image build should not.\n- `-Dnative_march=false`. Upstream's `just install` leaves that option on, which compiles for the build machine's CPU. A GitHub runner binary can SIGILL on a 5800X3D or a 9700X.\n- The compile happens in a throwaway stage. The final image gets `/ehroot` (the binaries, the shared library, the assets) and the runtime libraries, not gcc, meson, or the git checkout. JPEG is on. JPEG XL is off.\n\n**dcli-bootc / KineticWE.** [`profile.yaml`](profile.yaml) and [`modules/`](modules/) are the readable spec in his format, including `base_images.nvidia`. Actions does not run `dcli-bootc gen`. That command would overwrite the Containerfile. Don't run it in this checkout unless you mean to take the generator over.\n\n## Login session\n\n`/usr/share/wayland-sessions/event-horizon.desktop` starts `/usr/bin/event-horizon-session`.\n\nThe first time you log in, that script copies a Hyprland config from `/usr/share/event-horizon/skel` if you don't already have one. It does not touch an existing `~/.config/hypr/hyprland.conf`.\n\nThe seeded config starts the shell with `exec-once = EventHorizon` and sources `~/.config/hypr/eh/colors.conf`, which Event Horizon rewrites when you pick a wallpaper.\n\n| Keys | Action |\n| --- | --- |\n| Super + Enter | kitty |\n| Super + Space | fuzzel |\n| Super + Q | close window |\n| Super + F | fullscreen |\n| Super + V | float |\n| Super + M | exit Hyprland |\n| Super + arrows / HJKL | focus |\n| Super + Shift + arrows | move window |\n| Super + 1–9 | workspace |\n\n`ujust horizon-info` prints the Bazzite variant and `EventHorizon --version` when Bazzite's just importer is active.\n\n## Publish\n\n1. Create a new GitHub repo from this folder (or from image-template, then replace it with these files). Turn Actions on.\n2. Set `REPO_ORGANIZATION` in `image-template.env` to your GitHub user or org. That value is only an OCI label. The push path is `ghcr.io/<repo owner>/…`.\n3. Optional: `COSIGN_PASSWORD=\"\" cosign generate-key-pair`, then store `cosign.key` as the Actions secret `SIGNING_SECRET`. Do not commit the private key. Without the secret the image still publishes; it just isn't signed.\n4. Push to `main`. The **Build container image** workflow publishes both tags. The first run is long: it pulls Bazzite and compiles the shell twice, once per variant.\n5. Rebase a machine that is already on a bootc image:\n\n```bash\n# AMD / Intel\nsudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest\n\n# NVIDIA open (5070 Ti and other recent GeForce)\nsudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest\n```\n\nSwitch only between images that match the GPU. An NVIDIA image on an AMD box, or the reverse, will not come up cleanly.\n\n## ISO\n\nAfter the container workflow has pushed the tag you want:\n\n1. Actions → **Build disk images** → Run workflow.\n2. Pick `bazzite-horizon` or `bazzite-horizon-nvidia`. Leave platform on `amd64` unless you know you want the arm runner.\n3. Download the `anaconda-iso` artifact. The workflow rewrites `GHCR_IMAGE` in `disk_config/iso.toml` to the tag you picked, then bootc-image-builder makes the installer.\n\nThe ISO is an installer, not a live desktop. Boot it, install, then choose **Event Horizon** at the login screen.\n\n## Bump Event Horizon\n\n`build_files/event-horizon.ref` is one commit hash, currently `696be1a855a2c682e15765a92cc189f1f8de84be` (0.9.7.3-beta-3 era). Replace the hash and push. The builder fetches that commit and its submodules (the Inter font submodule is required; a non-recursive clone fails the way Fedora.md describes).\n\n## Local build\n\nFrom a machine with podman, and this directory as a git checkout (the Justfile skips some labels when the tree is dirty):\n\n```bash\n# edit REPO_ORGANIZATION first\njust build\nBASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia-open:stable just build bazzite-horizon-nvidia latest\n```\n\n## License\n\nThe image-template scaffold is Apache-2.0, included here as `LICENSE`. Event Horizon itself is MIT and is fetched at build time; it is not vendored in this repo.\n"
	},
	{
		id: "containerfile",
		label: "Containerfile",
		body: "# Bazzite Horizon\n# Scaffold from ublue-os/image-template. Event Horizon is compiled in a\n# throwaway stage so the compiler toolchain does not land in the image.\n# BASE_IMAGE selects the Bazzite variant (AMD/Intel or NVIDIA open).\n\nFROM scratch AS ctx\nCOPY build_files /\nCOPY system_files /system_files\n\nARG BASE_IMAGE=ghcr.io/ublue-os/bazzite:stable\n\nFROM ${BASE_IMAGE} AS eh-builder\nRUN --mount=type=bind,from=ctx,source=/,target=/ctx \\\n    --mount=type=cache,dst=/var/cache \\\n    --mount=type=cache,dst=/var/log \\\n    --mount=type=tmpfs,dst=/tmp \\\n    bash /ctx/build-event-horizon.sh\n\nFROM ${BASE_IMAGE}\nARG BASE_IMAGE\nENV BAZZITE_HORIZON_BASE=${BASE_IMAGE}\n\nRUN --mount=type=bind,from=ctx,source=/,target=/ctx \\\n    --mount=type=bind,from=eh-builder,source=/ehroot,target=/ehroot \\\n    --mount=type=cache,dst=/var/cache \\\n    --mount=type=cache,dst=/var/log \\\n    --mount=type=tmpfs,dst=/tmp \\\n    bash /ctx/build.sh\n\nRUN bootc container lint\n"
	},
	{
		id: "compile",
		label: "Compile",
		body: "#!/usr/bin/env bash\n# Compile Event Horizon Shell and stage it under /ehroot.\n# The final image copies /ehroot and does not keep this toolchain.\n#\n# Upstream Fedora.md says `sudo just install`. That is correct on a personal\n# machine and wrong for a published image: `just install` leaves\n# -Dnative_march=true, which tunes the binary for the build CPU (a GitHub\n# runner) and can SIGILL everywhere else. This script pins a commit and\n# forces a portable release build.\nset -eoux pipefail\n\nEH_REPO=\"${EH_REPO:-https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell.git}\"\nEH_REF=\"$(tr -d '[:space:]' < /ctx/event-horizon.ref)\"\n\ndnf5 install -y \\\n    git \\\n    meson \\\n    gcc \\\n    gcc-c++ \\\n    cmake \\\n    mold \\\n    ninja-build \\\n    pkgconf-pkg-config \\\n    python3 \\\n    libjpeg-turbo-devel \\\n    wayland-devel \\\n    wayland-protocols-devel \\\n    vulkan-loader-devel \\\n    vulkan-headers \\\n    freetype-devel \\\n    fontconfig-devel \\\n    cairo-devel \\\n    pango-devel \\\n    libxkbcommon-devel \\\n    glib2-devel \\\n    sdbus-cpp-devel \\\n    pipewire-devel \\\n    pam-devel \\\n    polkit-devel \\\n    libcurl-devel \\\n    openssl-devel \\\n    libwebp-devel \\\n    libpng-devel \\\n    lz4-devel \\\n    libdrm-devel \\\n    librsvg2-devel \\\n    ffmpegthumbnailer-devel \\\n    jemalloc-devel \\\n    lcms2-devel \\\n    libarchive-devel \\\n    poppler-glib-devel\n\nsrc=/eh-src\nrm -rf \"${src}\"\nmkdir -p \"${src}\"\ngit -C \"${src}\" init\ngit -C \"${src}\" remote add origin \"${EH_REPO}\"\ngit -C \"${src}\" fetch --depth 1 origin \"${EH_REF}\"\ngit -C \"${src}\" checkout --detach FETCH_HEAD\ngit -C \"${src}\" submodule update --init --recursive --depth 1\n\ncd \"${src}\"\nmeson setup build-release \\\n    --buildtype=release \\\n    --prefix=/usr \\\n    -Dembed_assets=false \\\n    -Dnative_march=false \\\n    -Djpeg=true \\\n    -Djxl=false \\\n    -Dcpp_link_args=-fuse-ld=mold \\\n    -Dc_link_args=-fuse-ld=mold \\\n    -Dunity=subprojects\n\nmeson compile -C build-release\nrm -rf /ehroot\nDESTDIR=/ehroot meson install -C build-release\n\ntest -x /ehroot/usr/bin/EventHorizon\necho \"Staged Event Horizon ${EH_REF}\"\n"
	},
	{
		id: "image",
		label: "Image",
		body: "#!/usr/bin/env bash\n# Final image: Bazzite, plus a Hyprland session, plus the Event Horizon\n# binaries staged by build-event-horizon.sh. Plasma stays installed so the\n# gear menu on the login screen can still fall back to KDE.\nset -eoux pipefail\n\ncp -avf /ctx/system_files/. /\nchmod 0755 /usr/bin/event-horizon-session\n\n# Runtime packages only. Build dependencies stayed in the eh-builder stage.\n# Names follow Event Horizon's Fedora.md (F43+) plus the Hyprland session\n# that page says the shell has to run inside.\ndnf5 install -y \\\n    hyprland \\\n    xdg-desktop-portal \\\n    xdg-desktop-portal-hyprland \\\n    xdg-desktop-portal-gtk \\\n    grim \\\n    slurp \\\n    wl-clipboard \\\n    brightnessctl \\\n    kitty \\\n    fuzzel \\\n    libjpeg-turbo \\\n    vulkan-loader \\\n    cairo \\\n    pango \\\n    freetype \\\n    fontconfig \\\n    libxkbcommon \\\n    glib2 \\\n    sdbus-cpp \\\n    pipewire \\\n    pam \\\n    polkit \\\n    libcurl \\\n    openssl \\\n    libwebp \\\n    libpng \\\n    lz4 \\\n    libdrm \\\n    librsvg2 \\\n    ffmpegthumbnailer \\\n    jemalloc \\\n    lcms2 \\\n    libarchive \\\n    poppler-glib \\\n    wayland \\\n    hicolor-icon-theme \\\n    adwaita-icon-theme\n\nif [[ ! -d /ehroot/usr ]]; then\n    echo \"eh-builder did not stage /ehroot\" >&2\n    exit 1\nfi\ncp -a /ehroot/. /\n\ninstall -d /usr/share/bazzite-horizon\nprintf '%s\\n' \"${BAZZITE_HORIZON_BASE:-unset}\" > /usr/share/bazzite-horizon/base-image\ncp /ctx/event-horizon.ref /usr/share/bazzite-horizon/event-horizon.ref\n\nif ldd /usr/bin/EventHorizon | grep -F 'not found'; then\n    echo \"EventHorizon is missing shared libraries\" >&2\n    exit 1\nfi\n\n/usr/bin/EventHorizon --version\ntest -x /usr/bin/event-horizon-session\ntest -f /usr/share/wayland-sessions/event-horizon.desktop\ntest -f /usr/share/event-horizon/skel/hypr/hyprland.conf\n\ndnf5 clean all\n"
	},
	{
		id: "hyprland",
		label: "Hyprland",
		body: "# Seeded once by /usr/bin/event-horizon-session.\n# Later logins keep your edits. Move this file aside to reseed.\n# Color matching: Event Horizon rewrites ~/.config/hypr/eh/colors.conf\n# when you pick a wallpaper (see upstream Docs/Setup.md).\n\nsource = ~/.config/hypr/eh/colors.conf\n\nmonitor=,preferred,auto,auto\n\nenv = XCURSOR_SIZE,24\nenv = QT_QPA_PLATFORM,wayland\nenv = GDK_BACKEND,wayland,x11\nenv = ELECTRON_OZONE_PLATFORM_HINT,auto\n\ninput {\n    kb_layout = us\n    follow_mouse = 1\n    sensitivity = 0\n    touchpad {\n        natural_scroll = true\n        disable_while_typing = true\n    }\n}\n\ngeneral {\n    gaps_in = 4\n    gaps_out = 10\n    border_size = 2\n    col.active_border = rgba(e4a15aee)\n    col.inactive_border = rgba(2c3038aa)\n    layout = dwindle\n}\n\ndecoration {\n    rounding = 10\n}\n\nanimations {\n    enabled = true\n}\n\ndwindle {\n    pseudotile = true\n    preserve_split = true\n}\n\nmisc {\n    force_default_wallpaper = 0\n    disable_hyprland_logo = true\n    disable_splash_rendering = true\n}\n\nexec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE\nexec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE\nexec-once = EventHorizon\n\nbind = SUPER, Return, exec, kitty\nbind = SUPER, Q, killactive\nbind = SUPER, M, exit\nbind = SUPER, F, fullscreen, 0\nbind = SUPER, Space, exec, fuzzel\nbind = SUPER, V, togglefloating\nbind = SUPER, P, pseudo\nbind = SUPER, T, togglesplit\n\nbind = SUPER, left, movefocus, l\nbind = SUPER, right, movefocus, r\nbind = SUPER, up, movefocus, u\nbind = SUPER, down, movefocus, d\n\nbind = SUPER, H, movefocus, l\nbind = SUPER, L, movefocus, r\nbind = SUPER, K, movefocus, u\nbind = SUPER, J, movefocus, d\n\nbind = SUPER SHIFT, left, movewindow, l\nbind = SUPER SHIFT, right, movewindow, r\nbind = SUPER SHIFT, up, movewindow, u\nbind = SUPER SHIFT, down, movewindow, d\n\nbind = SUPER, 1, workspace, 1\nbind = SUPER, 2, workspace, 2\nbind = SUPER, 3, workspace, 3\nbind = SUPER, 4, workspace, 4\nbind = SUPER, 5, workspace, 5\nbind = SUPER, 6, workspace, 6\nbind = SUPER, 7, workspace, 7\nbind = SUPER, 8, workspace, 8\nbind = SUPER, 9, workspace, 9\n\nbind = SUPER SHIFT, 1, movetoworkspace, 1\nbind = SUPER SHIFT, 2, movetoworkspace, 2\nbind = SUPER SHIFT, 3, movetoworkspace, 3\nbind = SUPER SHIFT, 4, movetoworkspace, 4\nbind = SUPER SHIFT, 5, movetoworkspace, 5\nbind = SUPER SHIFT, 6, movetoworkspace, 6\nbind = SUPER SHIFT, 7, movetoworkspace, 7\nbind = SUPER SHIFT, 8, movetoworkspace, 8\nbind = SUPER SHIFT, 9, movetoworkspace, 9\n\nbindm = SUPER, mouse:272, movewindow\nbindm = SUPER, mouse:273, resizewindow\n"
	},
	{
		id: "profile",
		label: "Profile",
		body: "# Declarative view of this image, in the shape theblackdon's dcli-bootc uses\n# (profile + base_images + modules). KineticOS / KineticWE is his desktop.\n# This profile keeps Bazzite and swaps the shell for Event Horizon.\n#\n# GitHub Actions does not run `dcli-bootc gen`. The files it builds are\n# Containerfile and build_files/*.sh. Running gen in this checkout would\n# overwrite those. Treat this YAML as the readable spec.\n\nname: bazzite-horizon\nbase_image: ghcr.io/ublue-os/bazzite:stable\ndefault_tag: latest\npackage_manager: dnf\n\nbase_images:\n  # Open kernel module. This is the one for RTX 50-series (5070 Ti) and\n  # recent GeForce laptops. It is not bazzite-nvidia (legacy proprietary).\n  nvidia: ghcr.io/ublue-os/bazzite-nvidia-open:stable\n\nenabled_modules:\n  - hyprland-session\n  - event-horizon\n"
	}
];
var EH_REF = "696be1a855a2c682e15765a92cc189f1f8de84be";
var layers = [
	{
		name: "Fedora bootc",
		detail: "The immutable base Universal Blue already tracks."
	},
	{
		name: "Bazzite",
		detail: "Gaming stack, kernel, Steam, Gamescope, drivers. Left intact."
	},
	{
		name: "Hyprland",
		detail: "A login session next to Plasma, not a replacement of KDE."
	},
	{
		name: "Event Horizon",
		detail: "ryzendew's shell. Dock, panel, and the rest, started with the session."
	}
];
var keys = [
	["Super + Enter", "kitty"],
	["Super + Space", "fuzzel"],
	["Super + Q", "close window"],
	["Super + M", "leave Hyprland"],
	["Super + arrows", "move focus"],
	["Super + 1–9", "workspace"]
];
function Forge() {
	const [active, setActive] = (0, import_react.useState)(recipeFiles[0].id);
	const [copied, setCopied] = (0, import_react.useState)(false);
	const file = recipeFiles.find((item) => item.id === active) ?? recipeFiles[0];
	async function copyFile() {
		try {
			await navigator.clipboard.writeText(file.body);
			setCopied(true);
			window.setTimeout(() => setCopied(false), 1600);
		} catch {
			setCopied(false);
		}
	}
	return /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("main", {
		className: "mx-auto flex w-full max-w-3xl flex-col gap-10 px-5 py-10 sm:py-14",
		children: [
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("header", {
				className: "flex flex-col gap-4",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm font-medium tracking-wide text-accent uppercase",
						children: "Universal Blue image"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h1", {
						className: "font-display text-5xl leading-none text-fg sm:text-6xl",
						children: "Horizon Forge"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "max-w-xl text-lg text-muted",
						children: "A Bazzite image with Event Horizon as the shell. Same bootc idea as theblackdon's KineticOS, pointed at ryzendew's desktop instead of KineticWE."
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", { className: "h-px w-16 bg-accent" })
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "grid gap-3 sm:grid-cols-2",
				"aria-label": "Image variants",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
					className: "flex flex-col gap-2 rounded-card border border-line bg-surface p-5",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
							className: "font-display text-2xl text-fg",
							children: "AMD and Intel"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "font-mono text-sm text-accent",
							children: "bazzite-horizon"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm text-muted",
							children: "Built from bazzite:stable. Use this tag on machines without an NVIDIA GPU."
						})
					]
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("article", {
					className: "flex flex-col gap-2 rounded-card border border-line bg-surface p-5",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
							className: "font-display text-2xl text-fg",
							children: "NVIDIA open"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "font-mono text-sm text-accent",
							children: "bazzite-horizon-nvidia"
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm text-muted",
							children: "Built from bazzite-nvidia-open. This is the Blackwell image, including a 5070 Ti. Not the older proprietary driver tag."
						})
					]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "flex flex-col gap-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "font-display text-3xl text-fg",
					children: "Stack"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("ol", {
					className: "flex flex-col",
					children: layers.map((layer, index) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
						className: "grid grid-cols-[2.5rem_1fr] gap-3 border-t border-line py-4",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("span", {
							className: "font-mono text-sm text-accent",
							children: ["0", index + 1]
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", { children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "font-medium text-fg",
							children: layer.name
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "text-sm text-muted",
							children: layer.detail
						})] })]
					}, layer.name))
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "flex flex-col gap-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "font-display text-3xl text-fg",
					children: "What was revised"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ul", {
					className: "flex flex-col gap-3",
					children: [
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
							className: "rounded-card border border-line bg-surface p-5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "font-medium text-fg",
								children: "Portable shell, pinned commit"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", {
								className: "mt-1 text-sm text-muted",
								children: [
									"Fedora.md's ",
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-fg",
										children: "sudo just install"
									}),
									" compiles with",
									" ",
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "text-fg",
										children: "-Dnative_march=true"
									}),
									". That binary matches the GitHub runner, then faults on other CPUs. The image build pins",
									" ",
									/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
										className: "font-mono text-xs text-accent",
										children: EH_REF.slice(0, 12)
									}),
									" and forces a generic release build. The compiler stays out of the final image."
								]
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
							className: "rounded-card border border-line bg-surface p-5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "font-medium text-fg",
								children: "One Containerfile, two Bazzite bases"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "mt-1 text-sm text-muted",
								children: "image-template hard-codes a single FROM line. This one takes BASE_IMAGE, the same split dcli-bootc puts under base_images. Plasma is still installed."
							})]
						}),
						/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
							className: "rounded-card border border-line bg-surface p-5",
							children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "font-medium text-fg",
								children: "A session, not a second distro"
							}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
								className: "mt-1 text-sm text-muted",
								children: "The login screen gains an Event Horizon entry. First login seeds Hyprland only if you don't already have a config. KDE remains the fallback."
							})]
						})
					]
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "flex flex-col gap-4",
				children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
					className: "font-display text-3xl text-fg",
					children: "Seeded keys"
				}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
					className: "overflow-hidden rounded-card border border-line",
					children: keys.map(([binding, action]) => /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "grid grid-cols-2 gap-3 border-t border-line px-4 py-3 first:border-t-0",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-sm text-fg",
							children: binding
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
							className: "text-sm text-muted",
							children: action
						})]
					}, binding))
				})]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "flex flex-col gap-4",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "flex items-end justify-between gap-3",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
							className: "font-display text-3xl text-fg",
							children: "Recipe"
						}), /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("button", {
							type: "button",
							onClick: copyFile,
							className: "inline-flex min-h-11 items-center gap-2 rounded-card border border-line bg-raised px-4 text-sm text-fg",
							children: [copied ? /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Check, { className: "size-4 text-accent" }) : /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Copy, { className: "size-4" }), copied ? "Copied" : "Copy"]
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("div", {
						role: "tablist",
						"aria-label": "Recipe files",
						className: "flex gap-2 overflow-x-auto pb-1",
						children: recipeFiles.map((item) => {
							const selected = item.id === file.id;
							return /* @__PURE__ */ (0, import_jsx_runtime.jsx)("button", {
								type: "button",
								role: "tab",
								"aria-selected": selected,
								onClick: () => {
									setActive(item.id);
									setCopied(false);
								},
								className: selected ? "min-h-11 shrink-0 rounded-card bg-accent px-4 text-sm font-medium text-accent-ink" : "min-h-11 shrink-0 rounded-card border border-line bg-surface px-4 text-sm text-muted",
								children: item.label
							}, item.id);
						})
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("pre", {
						className: "max-h-96 overflow-auto rounded-card border border-line bg-raised p-4 font-mono text-xs leading-relaxed text-fg",
						children: file.body
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("section", {
				className: "flex flex-col gap-4",
				children: [
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("h2", {
						className: "font-display text-3xl text-fg",
						children: "Publish"
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("ol", {
						className: "flex flex-col gap-4",
						children: [
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
								className: "flex gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "font-mono text-sm text-accent",
									children: "1"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted",
									children: "Download the recipe and push it to a new GitHub repository. Turn Actions on. Set REPO_ORGANIZATION in image-template.env to that account."
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
								className: "flex gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "font-mono text-sm text-accent",
									children: "2"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted",
									children: "Push to main. The container workflow publishes both tags. The first run pulls Bazzite and compiles the shell, so it takes a while. Signing is optional until you add a SIGNING_SECRET."
								})]
							}),
							/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("li", {
								className: "flex gap-3",
								children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("span", {
									className: "font-mono text-sm text-accent",
									children: "3"
								}), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
									className: "text-sm text-muted",
									children: "On a machine already running a bootc image, switch to the tag that matches the GPU. Or run the disk-image workflow and install from the ISO, then pick Event Horizon at the login screen."
								})]
							})
						]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("div", {
						className: "rounded-card border border-line bg-surface p-5 font-mono text-xs leading-relaxed text-fg",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", { children: "sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest" }), /* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
							className: "mt-2 text-muted",
							children: "sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest"
						})]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsxs)("a", {
						href: "/bazzite-horizon.zip",
						download: true,
						className: "inline-flex min-h-11 items-center justify-center gap-2 rounded-card bg-accent px-5 text-sm font-medium text-accent-ink",
						children: [/* @__PURE__ */ (0, import_jsx_runtime.jsx)(Download, { className: "size-4" }), "Download the recipe"]
					}),
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("p", {
						className: "text-sm text-muted",
						children: "The ISO is built by GitHub after the container image exists. This page is the blueprint and the files, not a flashed installer."
					})
				]
			}),
			/* @__PURE__ */ (0, import_jsx_runtime.jsx)("footer", {
				className: "border-t border-line pt-6 text-sm text-muted",
				children: /* @__PURE__ */ (0, import_jsx_runtime.jsxs)("p", { children: [
					"Shell docs:",
					" ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						className: "text-fg underline decoration-line underline-offset-4",
						href: "https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell/blob/main/Docs/Fedora.md",
						children: "Event Horizon on Fedora"
					}),
					". Image scaffold:",
					" ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						className: "text-fg underline decoration-line underline-offset-4",
						href: "https://github.com/ublue-os/image-template",
						children: "ublue-os/image-template"
					}),
					". Layout reference:",
					" ",
					/* @__PURE__ */ (0, import_jsx_runtime.jsx)("a", {
						className: "text-fg underline decoration-line underline-offset-4",
						href: "https://gitlab.com/theblackdon/dcli-bootc",
						children: "dcli-bootc"
					}),
					"."
				] })
			})
		]
	});
}
function Home() {
	return /* @__PURE__ */ (0, import_jsx_runtime.jsx)(Forge, {});
}
//#endregion
export { Home as component };
