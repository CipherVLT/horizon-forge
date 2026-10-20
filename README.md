# Bazzite Horizon

**[Bazzite](https://bazzite.gg) with a Hyprland desktop and the [Event Horizon](https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell) shell.**

Everything that makes Bazzite good for gaming stays the same: Steam, Gamescope, the BORE-scheduled kernel, drivers, and automatic updates. On top of that it is set up for **creators and coders**: a single desktop, **Event Horizon** on Hyprland, without the KDE apps it replaces, and package repositories left open so you can install software system-wide.

> [!WARNING]
> Event Horizon is in **beta**. Expect rough edges. See [Known issues](#known-issues).

---

## Contents

- [Pick your image](#pick-your-image)
- [What's different from Bazzite](#whats-different-from-bazzite)
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

## What's different from Bazzite

| | Bazzite (KDE) | Bazzite Horizon |
| --- | --- | --- |
| Desktop | KDE Plasma | Event Horizon on Hyprland (Plasma session hidden) |
| Login screen | Plasma Login | SDDM with the [Pixie](https://github.com/xCaptaiN09/pixie-sddm) theme, Bazzite wallpaper, 12-hour clock |
| File manager | Dolphin | [Strata](https://github.com/lgse/strata) (GTK 4) |
| Screenshots | Spectacle | Event Horizon's tool (<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>) |
| Removed | | Kate, KDE Menu Editor, Steam starting at login, Waydroid, Lutris, input-remapper, KDE Connect, KDE System Settings, Konsole (kitty is the terminal), KWrite, KFind, KRFB, KRDC, Help Center, KDebugSettings, KWalletManager, Filelight, Emoji Selector, ROM Properties, Fcitx 5 configuration, Btrfs Assistant, Cardwire app (the GPU-switching service stays in the NVIDIA image for dual-GPU laptops), the Discourse forum link, Xwayland Video Bridge |
| Added (system packages) | | Firefox, OBS Studio, gedit, ProtonPlus, Heroic Games Launcher, Strata |
| Codecs | Full (FFmpeg, H.264/H.265, AAC, hardware video decode) | Same, unchanged |
| Virtual machines | `ujust setup-virtualization` (Flatpak) | `ujust horizon-vm` installs QEMU/KVM and virt-manager as system packages, on demand |
| Installing software | Flatpak first; `rpm-ostree install` only sees Fedora | The **Terra** repository is left on, so `rpm-ostree install` finds far more apps (for example `protonplus`). Flatpak, Homebrew and Distrobox work as usual |

Bazzite already ships the full codec set Nobara is known for (FFmpeg from Fedora Multimedia, OpenH264, hardware video decoding), so nothing extra is needed for video, streaming or editing.

Optional, installed only when you want them (keeps the ISO small):

```bash
ujust horizon-vm          # QEMU/KVM + virt-manager, then reboot
ujust horizon-vm-remove   # undo
```

`rpm-ostree install <package>` adds a system package that survives updates. Use it for things you want system-wide; every layered package is reapplied on each update, so a handful is fine.

---

## First login

1. Log in. **Event Horizon** is the only session on the login screen.
2. On the first login you get:
   - **[Strata](https://github.com/lgse/strata)** as the file manager. It also answers "Show in folder" from Firefox, Steam and other apps.
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
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Screenshot (select an area) |
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
| Event Horizon's settings draw blank except the item under the pointer (Vulkan renderer) | New installs use the Cairo renderer. Otherwise: Settings → Panels & UI → **Shell renderer: Cairo** |
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
| `build_files/apps.list` | Extra apps installed system-wide. Add a line to add an app |
| `build_files/trim-desktop.sh` | Removes the KDE apps, installs `apps.list`, opens the Terra repository, hides the Plasma session |
| `build_files/install-greeter.sh` | Switches the login screen to SDDM with the Pixie theme (vendored in `system_files/usr/share/sddm/themes/pixie`) |
| `build_files/strata.ref`, `install-strata.sh` | Strata file manager: pinned release and its checksum |
| `system_files/` | Files copied into the image: login session, default Hyprland config, helpers |
| `disk_config/iso.toml` | Installer (ISO) settings |
| `.github/workflows/` | Image and ISO builds, lint (ShellCheck, actionlint) on every change, weekly Trivy vulnerability scan |
| `cook-iso.sh` | Builds an ISO on your own computer |
| `.mcp.json` | Tools for Claude Code when working on this repo ([Sequential Thinking](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking)). Not part of the image |

---

## Credits

- [Bazzite](https://github.com/ublue-os/bazzite) and [Universal Blue](https://universal-blue.org): the base system and the [image template](https://github.com/ublue-os/image-template) this repo started from
- [Event Horizon Shell](https://github.com/Event-Horizon-desktop-environment/Event-Horizon-Shell) by Ryzendrew: the desktop shell
- [Hyprland](https://hypr.land): the compositor
- [Strata](https://github.com/lgse/strata) by lgse: the file manager
- [dcli-bootc](https://gitlab.com/theblackdon/dcli-bootc) by theblackdon: the profile/modules layout (`profile.yaml`, `modules/`)

## License

This repository is [Apache-2.0](LICENSE). Event Horizon is MIT licensed and downloaded at build time; it is not included in this repository.
