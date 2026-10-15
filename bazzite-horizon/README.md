# Bazzite Horizon

A custom [Universal Blue](https://universal-blue.org) image. Bazzite stays the base, so Steam, Gamescope, the kernel, and the driver stack are still Bazzite's. On top of that is a Hyprland login session whose shell is [Event Horizon](https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell) (ryzendew).

Plasma is not removed. At the login screen, open the session menu and choose **Event Horizon**. KDE is still there if you need it.

This checkout is the [ublue-os/image-template](https://github.com/ublue-os/image-template) (bootc, GitHub Actions, cosign, bootc-image-builder ISOs), revised the way [theblackdon/dcli-bootc](https://gitlab.com/theblackdon/dcli-bootc) describes an image: one profile, named base images, modules. His desktop on that pattern is KineticOS / KineticWE. This one uses Event Horizon instead.

## Images

| Tag | Base | Use it for |
| --- | --- | --- |
| `bazzite-horizon:latest` | `ghcr.io/ublue-os/bazzite:stable` | AMD and Intel |
| `bazzite-horizon-nvidia:latest` | `ghcr.io/ublue-os/bazzite-nvidia-open:stable` | NVIDIA open module. This is the 5070 Ti / Blackwell image, and it also covers recent GeForce laptops. It is not the older proprietary `bazzite-nvidia` image. |

Both tags are built from the same Containerfile. `BASE_IMAGE` is the only difference.

## What changed from the three sources

**image-template.** `FROM` is an argument instead of a hard-coded line, so one workflow builds both variants. `disk_config/iso.toml` exists (the template's disk workflow points at it; upstream currently only ships `iso-kde.toml` / `iso-gnome.toml`). Signing no longer fails the build when `SIGNING_SECRET` is still empty.

**Event Horizon Fedora.md.** The package list is the same F43+ set, and the shell is still installed to `/usr`. Three edits so it can live in an image rather than a pet machine:

- The commit is pinned in [`build_files/event-horizon.ref`](build_files/event-horizon.ref). `just install` tracks whatever `main` is today; an image build should not.
- `-Dnative_march=false`. Upstream's `just install` leaves that option on, which compiles for the build machine's CPU. A GitHub runner binary can SIGILL on a 5800X3D or a 9700X.
- The compile happens in a throwaway stage. The final image gets `/ehroot` (the binaries, the shared library, the assets) and the runtime libraries, not gcc, meson, or the git checkout. JPEG is on. JPEG XL is off.

**dcli-bootc / KineticWE.** [`profile.yaml`](profile.yaml) and [`modules/`](modules/) are the readable spec in his format, including `base_images.nvidia`. Actions does not run `dcli-bootc gen`. That command would overwrite the Containerfile. Don't run it in this checkout unless you mean to take the generator over.

## Login session

`/usr/share/wayland-sessions/event-horizon.desktop` starts `/usr/bin/event-horizon-session`.

The first time you log in, that script copies a Hyprland config from `/usr/share/event-horizon/skel` if you don't already have one. It does not touch an existing `~/.config/hypr/hyprland.conf`.

The seeded config starts the shell with `exec-once = EventHorizon` and sources `~/.config/hypr/eh/colors.conf`, which Event Horizon rewrites when you pick a wallpaper.

| Keys | Action |
| --- | --- |
| Super + Enter | kitty |
| Super + Space | fuzzel |
| Super + Q | close window |
| Super + F | fullscreen |
| Super + V | float |
| Super + M | exit Hyprland |
| Super + arrows / HJKL | focus |
| Super + Shift + arrows | move window |
| Super + 1–9 | workspace |

`ujust horizon-info` prints the Bazzite variant and `EventHorizon --version` when Bazzite's just importer is active.

## Publish

1. Create a new GitHub repo from this folder (or from image-template, then replace it with these files). Turn Actions on.
2. Set `REPO_ORGANIZATION` in `image-template.env` to your GitHub user or org. That value is only an OCI label. The push path is `ghcr.io/<repo owner>/…`.
3. Optional: `COSIGN_PASSWORD="" cosign generate-key-pair`, then store `cosign.key` as the Actions secret `SIGNING_SECRET`. Do not commit the private key. Without the secret the image still publishes; it just isn't signed.
4. Push to `main`. The **Build container image** workflow publishes both tags. The first run is long: it pulls Bazzite and compiles the shell twice, once per variant.
5. Rebase a machine that is already on a bootc image:

```bash
# AMD / Intel
sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest

# NVIDIA open (5070 Ti and other recent GeForce)
sudo bootc switch ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest
```

Switch only between images that match the GPU. An NVIDIA image on an AMD box, or the reverse, will not come up cleanly.

## ISO

After the container workflow has pushed the tag you want:

1. Actions → **Build disk images** → Run workflow.
2. Pick `bazzite-horizon` or `bazzite-horizon-nvidia`. Leave platform on `amd64` unless you know you want the arm runner.
3. Download the `anaconda-iso` artifact. The workflow rewrites `GHCR_IMAGE` in `disk_config/iso.toml` to the tag you picked, then bootc-image-builder makes the installer.

The ISO is an installer, not a live desktop. Boot it, install, then choose **Event Horizon** at the login screen.

## Bump Event Horizon

`build_files/event-horizon.ref` is one commit hash, currently `696be1a855a2c682e15765a92cc189f1f8de84be` (0.9.7.3-beta-3 era). Replace the hash and push. The builder fetches that commit and its submodules (the Inter font submodule is required; a non-recursive clone fails the way Fedora.md describes).

## Local build

From a machine with podman, and this directory as a git checkout (the Justfile skips some labels when the tree is dirty):

```bash
# edit REPO_ORGANIZATION first
just build
BASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia-open:stable just build bazzite-horizon-nvidia latest
```

## License

The image-template scaffold is Apache-2.0, included here as `LICENSE`. Event Horizon itself is MIT and is fetched at build time; it is not vendored in this repo.
