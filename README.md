# Bazzite Horizon

**[Bazzite](https://bazzite.gg) with a Hyprland desktop and the [Event Horizon](https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell) shell.**

Everything that makes Bazzite good for gaming stays the same: Steam, Gamescope, the kernel, drivers, and automatic updates. This image adds a second desktop session, **Event Horizon**, running on Hyprland. KDE Plasma is still installed, so you can switch back at the login screen at any time.

> [!WARNING]
> Event Horizon is in **beta**. Expect rough edges. See [Known issues](#known-issues).

---

## Contents

- [Pick your image](#pick-your-image)
- [Install](#install)
  - [Option A: Switch from Bazzite (recommended)](#option-a-switch-from-bazzite-recommended)
  - [Option B: Fresh install from an ISO](#option-b-fresh-install-from-an-iso)
- [First login](#first-login)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Updating](#updating)
- [Known issues](#known-issues)
- [Build it yourself](#build-it-yourself)
- [Repository layout](#repository-layout)
- [Credits](#credits)

---

## Pick your image

| Your graphics | Image | Based on |
| --- | --- | --- |
| **AMD** or **Intel** | `bazzite-horizon` | `bazzite:stable` |
| **NVIDIA** GTX 16 / RTX 20 series and newer, including laptops with Intel + NVIDIA | `bazzite-horizon-nvidia` | `bazzite-nvidia-open:stable` |

The NVIDIA image uses NVIDIA's **open kernel driver**, which is what current cards (RTX 30, 40 and 50 series) are designed for. It does **not** support GTX 10 series or older.

On laptops with two GPUs (for example Intel + RTX), the desktop runs on the integrated GPU and leaves the NVIDIA card free for games. This is detected automatically at every login.

---

## Install

### Option A: Switch from Bazzite (recommended)

If the computer already runs Bazzite (or any other Universal Blue / bootc image), you don't need a USB stick. Open a terminal and run the line for your graphics:

```bash
# AMD / Intel
sudo bootc switch ghcr.io/ciphervlt/bazzite-horizon:latest

# NVIDIA
sudo bootc switch ghcr.io/ciphervlt/bazzite-horizon-nvidia:latest
```

Reboot when it finishes. To go back to stock Bazzite later, run `sudo bootc switch ghcr.io/ublue-os/bazzite:stable` (or `bazzite-nvidia-open:stable`) and reboot.

### Option B: Fresh install from an ISO

Use this for a blank disk or a computer without Bazzite.

**1. Download the ISO**

1. Open **[Actions → Build disk images](https://github.com/CipherVLT/horizon-forge/actions/workflows/build-disk.yml)** and click the most recent run with a green check.
2. Under **Artifacts**, download `anaconda-iso-bazzite-horizon` or `anaconda-iso-bazzite-horizon-nvidia` (about 6 GB). You need to be signed in to GitHub, and artifacts expire after 90 days.
3. Unzip it. The installer is `install.iso`.

**2. Write it to a USB stick (8 GB or larger)**

Use [Fedora Media Writer](https://fedoraproject.org/workstation/download) or [balenaEtcher](https://etcher.balena.io). On Linux you can also use `dd`; check the device name with `lsblk` first, because this erases it:

```bash
sudo dd if=install.iso of=/dev/sdX bs=4M conv=fsync status=progress
```

**3. Prepare the computer**

- Boot mode: **UEFI**.
- **Secure Boot: off.** (Installs with Secure Boot on have not been tested.)

**4. Install**

1. Boot from the USB stick.
2. At **Installation Destination**, select only the disk you want to install to and choose **Automatic** storage. Leave any other drives unchecked so they aren't touched.
3. Keep the internet connected, create your user, and start the install.
4. Reboot and remove the USB stick.

---

## First login

1. At the login screen, open the **session menu** and choose **Event Horizon**. (Plasma is in the same list.)
2. On the first login you get:
   - A Hyprland config in `~/.config/hypr/hyprland.conf`. It's yours to edit; updates never overwrite it.
   - Bazzite's wallpaper. Change it in Event Horizon's settings under **Wallpaper Settings → Wallpaper**.
3. Your home folder is fully writable. Only the system (`/usr`) is read-only, which is how Bazzite stays reliable.

Tip: in the file manager, press **Ctrl + H** to show hidden files such as `~/.config`.

---

## Keyboard shortcuts

| Keys | Action |
| --- | --- |
| <kbd>Super</kbd> + <kbd>Enter</kbd> | Terminal (kitty) |
| <kbd>Super</kbd> + <kbd>Space</kbd> | App launcher (fuzzel) |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close window |
| <kbd>Super</kbd> + <kbd>F</kbd> | Fullscreen |
| <kbd>Super</kbd> + <kbd>V</kbd> | Toggle floating |
| <kbd>Super</kbd> + <kbd>P</kbd> | Pseudo-tile |
| <kbd>Super</kbd> + <kbd>T</kbd> | Toggle split direction |
| <kbd>Super</kbd> + arrows or <kbd>H</kbd><kbd>J</kbd><kbd>K</kbd><kbd>L</kbd> | Move focus |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + arrows | Move window |
| <kbd>Super</kbd> + <kbd>1</kbd>–<kbd>9</kbd> | Go to workspace |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>1</kbd>–<kbd>9</kbd> | Send window to workspace |
| <kbd>Super</kbd> + left / right mouse drag | Move / resize window |
| <kbd>Super</kbd> + <kbd>M</kbd> | Log out |

---

## Updating

Updates work exactly like Bazzite. They download in the background and apply on the next reboot. To update by hand:

```bash
ujust update          # system, Flatpaks and Homebrew
sudo bootc upgrade    # system image only
```

If an update ever misbehaves, pick the previous entry in the boot menu, or run `sudo bootc rollback` and reboot.

`ujust horizon-info` shows which image and Event Horizon version you are running.

---

## Known issues

Event Horizon is beta software. These are known and reported upstream:

| Issue | Workaround |
| --- | --- |
| Event Horizon's settings window sometimes draws blank until you scroll | Settings → Panels & UI → **Shell renderer: Cairo** |
| Event Horizon's Wi-Fi tab may not open | Wi-Fi still works. Connect with `nmtui` in a terminal |
| Hyprland shows "*.conf config format will be removed in 0.57*" | Harmless for now. The build refuses Hyprland 0.57 until the config moves to Lua, so an update can't break your desktop |

Already fixed in this image: blurred wallpaper and desktop icons, the Xwayland Video Bridge popup, Hyprland config errors and startup warnings.

Found something new? [Open an issue](https://github.com/CipherVLT/horizon-forge/issues) and include your GPU and a photo of the error.

---

## Build it yourself

Fork this repository to publish your own copy.

1. **Fork** the repo and enable **Actions**.
2. In `image-template.env`, set `REPO_ORGANIZATION` to your GitHub username.
3. *(Optional)* Sign your images. Create a key with `COSIGN_PASSWORD="" cosign generate-key-pair` and save the contents of `cosign.key` as the repository secret `SIGNING_SECRET`. Never commit `cosign.key`.
4. Push to `main`. **Build container image** builds both images (about 15–25 minutes).
5. **Make the images public.** Go to your GitHub profile → **Packages** → `bazzite-horizon` → **Package settings** → **Change visibility** → **Public**. Repeat for `bazzite-horizon-nvidia`. If you skip this, installed computers can't download updates.
6. For an ISO: **Actions → Build disk images → Run workflow**, choose the image, platform `amd64`.

To build on your own computer instead (needs `podman`, `git`, `just` and about 80 GB free):

```bash
just cook-iso amd        # or: just cook-iso nvidia
just cook-iso amd pull   # reuse the published image instead of compiling
```

The ISO is written to `output/install.iso`.

### Publishing ISOs (Cloudflare R2)

GitHub can't host the ISOs permanently (release files are capped at 2 GB, and Actions artifacts expire). The **Build disk images** workflow can publish them to Cloudflare R2 instead, at fixed links that are replaced on every upload:

`bazzite-horizon-latest.iso` and `bazzite-horizon-nvidia-latest.iso`, each with a `.sha256` checksum.

One-time setup:

1. In the [Cloudflare dashboard](https://dash.cloudflare.com), open **R2** and create a bucket (for example `horizon-forge`).
2. In the bucket's **Settings**, turn on **Public Development URL** (`https://pub-….r2.dev`), or connect your own domain.
3. **R2 → Manage API tokens → Create API token**: permission **Object Read & Write**, limited to that bucket. Copy the **Access Key ID** and **Secret Access Key**.
4. In this repository: **Settings → Secrets and variables → Actions**.
   - **Secrets:** `R2_ACCOUNT_ID` (shown on the R2 overview page), `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`.
   - **Variables:** `R2_PUBLIC_URL`, the public URL from step 2.
5. Run **Build disk images** with **Publish the ISO to Cloudflare R2** ticked, once per image.

R2's free tier includes 10 GB of storage and free downloads. Two ISOs are about 12 GB, so expect a few cents a month for the extra space.

**Updating Event Horizon:** put the new commit hash in [`build_files/event-horizon.ref`](build_files/event-horizon.ref) and push.

---

## Repository layout

| Path | What it does |
| --- | --- |
| `Containerfile` | Starts from Bazzite, compiles Event Horizon in a separate stage, copies in the result |
| `build_files/build-event-horizon.sh` | Compiles Event Horizon at the pinned commit (portable CPU flags, local fixes) |
| `build_files/build.sh` | Installs Hyprland and runtime packages, applies system tweaks |
| `build_files/event-horizon.ref` | The Event Horizon commit that gets built |
| `system_files/` | Files copied into the image: login session, default Hyprland config, helpers |
| `disk_config/iso.toml` | Installer (ISO) settings |
| `.github/workflows/` | Automated image and ISO builds |
| `cook-iso.sh` | Builds an ISO on your own computer |

---

## Credits

- [Bazzite](https://github.com/ublue-os/bazzite) and [Universal Blue](https://universal-blue.org): the base system and the [image template](https://github.com/ublue-os/image-template) this repo started from
- [Event Horizon Shell](https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell) by Ryzendrew: the desktop shell
- [Hyprland](https://hypr.land): the compositor
- [dcli-bootc](https://gitlab.com/theblackdon/dcli-bootc) by theblackdon: the profile/modules layout (`profile.yaml`, `modules/`)

## License

This repository is [Apache-2.0](LICENSE). Event Horizon is MIT licensed and downloaded at build time; it is not included in this repository.
