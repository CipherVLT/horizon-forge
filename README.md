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

That command is the install if the machine already runs Bazzite or any other bootc image. No USB. No installer. Reboot when it asks.

A blank disk is the only reason to build an ISO. The USB uses Fedora's installer, Anaconda, once, and only to copy this same bootc image onto the disk. You do not configure Anaconda. The kickstart runs `bootc switch` at the end of the copy, so the installed system tracks the GitHub image. After the first boot, updates are `sudo bootc upgrade`. Anaconda is not part of the running system.

## ISO

Do not download a Bazzite ISO from the website. The KDE and GNOME files there are finished stock installers. This recipe does not remaster them. It starts from the Bazzite **container** (`bazzite:stable` or `bazzite-nvidia-open:stable`). Plasma is already inside that container, so there is no "pick KDE" step.

You cook one of two installers:

| You are installing on | Workflow choice | `just cook-iso` | Menu title after install |
| --- | --- | --- | --- |
| AMD or Intel | `bazzite-horizon` | `just cook-iso amd` | Bazzite Horizon |
| NVIDIA, including a 5070 Ti | `bazzite-horizon-nvidia` | `just cook-iso nvidia` | Bazzite Horizon NVIDIA |

The USB stick that boots the installer still shows GRUB. That is the ISO's own menu, not the bootloader that lands on the disk. `bootloader --sdboot` plus `/usr/libexec/bazzite-horizon-sdboot-sync` write a systemd-boot entry onto the EFI partition of the installed system. The entry is titled from the table above. ostree keeps the kernel on `/boot`, which systemd-boot cannot read, so the script copies the kernel and initrd onto the ESP. It runs again after later updates.

Secure Boot has to be off. This path does not use Bazzite's shim. BIOS machines cannot boot systemd-boot. qcow2 and raw images skip Anaconda, so they stay on GRUB.

### GitHub (this is the one that saves time)

1. Download the recipe (or clone this repo). Create a new GitHub repository and push these files. Turn Actions on.
2. Set `REPO_ORGANIZATION` in `image-template.env` to that GitHub account. That value is only an OCI label. The registry path is `ghcr.io/<the account that owns the repo>/…`.
3. Optional: `COSIGN_PASSWORD="" cosign generate-key-pair`, then store `cosign.key` as the Actions secret `SIGNING_SECRET`. Do not commit the private key. Without the secret the image still publishes.
4. Push to `main`. Wait until **Build container image** is green. The first run pulls Bazzite and compiles Event Horizon twice, once per GPU variant.
5. Actions → **Build disk images** → Run workflow. Pick the variant from the table. Leave platform on `amd64`.
6. Download the artifact `anaconda-iso-<variant>`. Unzip it. The installer is `install.iso`.
7. Flash the USB with Fedora Media Writer or KDE ISO Image Writer. From a shell, after you have identified the USB and not the system disk:

```bash
sudo dd if=install.iso of=/dev/sdX bs=4M conv=fsync status=progress
```

8. Firmware: UEFI, Secure Boot off. Boot the USB, install, and give the EFI partition about 2 GiB if the disk editor lets you. The kernel and initrd are copied there.
9. Reboot. systemd-boot should list **Bazzite Horizon** or **Bazzite Horizon NVIDIA**. If the first reboot is still GRUB, boot once and reboot again. The sync service writes the entry as soon as the ostree menu file exists.
10. At the login screen, open the session menu and choose **Event Horizon**. Plasma is still in that list.

### This computer

Same ISO, compiled here. You need `podman`, `git`, and `just`, and about 80 GiB free for a local compile. Set `REPO_ORGANIZATION` first. The kickstart retargets the installed system at `ghcr.io/<you>/<tag>:latest`, so that tag has to exist before you boot the USB.

```bash
sudo pacman -S --needed podman git just

# NVIDIA (5070 Ti and other recent GeForce)
just cook-iso nvidia
podman login ghcr.io
podman push localhost/bazzite-horizon-nvidia:latest \
  ghcr.io/YOUR_GITHUB_USER/bazzite-horizon-nvidia:latest

# AMD / Intel
just cook-iso amd
podman push localhost/bazzite-horizon:latest \
  ghcr.io/YOUR_GITHUB_USER/bazzite-horizon:latest
```

If GitHub has already published the tag and you only want the ISO built locally, skip the compile:

```bash
just cook-iso nvidia pull
just cook-iso amd pull
```

`just cook-iso` writes `disk_config/iso.built.toml` (the kickstart with your registry tag filled in) and runs bootc-image-builder as `--type anaconda-iso`. The upstream `just build-iso` name still uses the short type `iso`, which does not apply this kickstart. Use `just cook-iso`.

The ISO lands under `output/` as `install.iso`. Flash it the same way as the GitHub artifact.

## Bump Event Horizon

`build_files/event-horizon.ref` is one commit hash, currently `696be1a855a2c682e15765a92cc189f1f8de84be` (0.9.7.3-beta-3 era). Replace the hash and push. The builder fetches that commit and its submodules (the Inter font submodule is required; a non-recursive clone fails the way Fedora.md describes).

## Local container only

From a machine with podman, and this directory as a git checkout (the Justfile skips some labels when the tree is dirty):

```bash
# edit REPO_ORGANIZATION first
just build
BASE_IMAGE=ghcr.io/ublue-os/bazzite-nvidia-open:stable just build bazzite-horizon-nvidia latest
```

That publishes nothing and does not write an ISO. For the installer, use `just cook-iso` above.

## License

The image-template scaffold is Apache-2.0, included here as `LICENSE`. Event Horizon itself is MIT and is fetched at build time; it is not vendored in this repo.
