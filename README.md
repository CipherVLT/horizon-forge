# Bazzite Horizon

**[Bazzite](https://bazzite.gg) with a Hyprland desktop and the [Event Horizon](https://github.com/Event-Horizon-desktop-environment/Event-Horizon) shell.**

Bazzite Horizon reshapes Bazzite into a complete desktop distro for **gamers, creators and coders**:

- **Install apps system-wide, no reboot.** `ujust horizon-install <app>` installs from Fedora or Terra and the app is ready right away. Terra is turned back on, so it finds apps that stock Bazzite only offers as Flatpaks, such as ProtonPlus and Discord.
- **Full speed while gaming.** Instead of staying on Bazzite's power-saving defaults, **GameMode** switches the CPU to the `performance` governor and power profile while a game runs, then returns to balanced.
- **No bloat.** The KDE Plasma apps and the handheld-focused Bazzite extras are gone, leaving one desktop: **Event Horizon** on Hyprland.

Bazzite's foundation stays: Steam, Gamescope, the BORE-scheduled kernel, drivers and automatic updates.

> [!WARNING]
> Event Horizon is in **beta**. Expect rough edges.

---

## Contents

- [Pick your image](#pick-your-image)
- [What's different from Bazzite](#whats-different-from-bazzite)
- [Install](#install)
- [First login](#first-login)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Updating](#updating)
- [Making your own](#making-your-own)
- [Credits](#credits)

---

## Pick your image

| Your graphics | Image | Based on |
| --- | --- | --- |
| **AMD** or **Intel** | `bazzite-horizon` | `bazzite:stable` |
| **NVIDIA** GTX 16 / RTX 20 series and newer, including laptops with Intel + NVIDIA | `bazzite-horizon-nvidia` | `bazzite-nvidia-open:stable` |

The NVIDIA image uses NVIDIA's **open kernel driver**, which is what current cards (RTX 30, 40 and 50 series) are designed for. It does **not** support GTX 10 series or older.

On laptops with two GPUs (for example Intel + RTX), the desktop runs on the integrated GPU and leaves the NVIDIA card free for games. This is detected automatically at every login. Run `ujust horizon-gpu` to choose when the NVIDIA card may wake up: **smart** (asleep for browsing and video, on for the games you allow), **integrated** (always off, longest battery) or **hybrid** (always available). On ASUS laptops, `ujust horizon-asus` adds asusctl and ROG Control Center for fans, keyboard lighting and the battery charge limit.

---

## Install

Bazzite Horizon is installed from its ISO.

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
| Screenshots | Spectacle | [Satty](https://github.com/gabm/Satty) (<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>): drag a box, then crop, draw, add text or blur, and Copy, Save or Save as. Saves to `~/Pictures/Screenshots` |
| Default apps | Kate, KDE Menu Editor, Steam starting at login, Steam Big Picture Mode menu entries, Waydroid, Lutris, input-remapper, KDE Connect, KDE System Settings, Konsole, KWrite, KFind, KRFB, KRDC, Help Center, KDebugSettings, KWalletManager, Filelight, Emoji Selector, ROM Properties, Fcitx 5 (Chinese/Japanese/Korean input methods), Btrfs Assistant, Cardwire app, the Discourse forum link, Xwayland Video Bridge | KDE apps removed, keeping the components Bazzite needs to run. kitty is the terminal |
| Added (system packages) | | Firefox, OBS Studio, gedit, ProtonPlus, Heroic Games Launcher, Strata, GameMode, Wine (latest development release from [Kron4ek](https://github.com/Kron4ek/Wine-Builds), NTSync on) |
| CPU while gaming | `powersave` governor, balanced profile all the time (GameMode removed) | GameMode switches to the `performance` governor and power profile while a game runs, then restores your profile. Use `gamemoderun %command%` in Steam's Launch Options |
| MangoHud CPU power | Not shown (RAPL counters are root-only) | Shown |
| Codecs | Full (FFmpeg, H.264/H.265, AAC, hardware video decode) | Same, unchanged |
| Virtual machines | `ujust setup-virtualization` (Flatpak) | `ujust horizon-vm` installs QEMU/KVM and virt-manager as system packages, on demand |
| Installing software | Flatpak first; `rpm-ostree install` only sees Fedora and needs a reboot | **Fedora and Terra first**: `ujust horizon-install <app>` installs system-wide and works immediately, no reboot. Flatpak, Homebrew and Distrobox still work, as optional extras |

Bazzite already ships the full codec set Nobara is known for (FFmpeg from Fedora Multimedia, OpenH264, hardware video decoding), so nothing extra is needed for video, streaming or editing.

Optional, installed only when you want them (keeps the ISO small):

```bash
ujust horizon-install <app> # install apps from Fedora/Terra, no reboot
ujust horizon-remove <app>  # remove them again (after a reboot)
ujust horizon-gaming-check  # governor, power profile, GameMode, NTSync, Wine
ujust horizon-yabridge      # Windows VST/CLAP plugins (Serum, ...) in Linux DAWs
ujust horizon-bitwig        # Bitwig Studio from its official .deb, into your home folder
ujust horizon-vm            # QEMU/KVM + virt-manager, then reboot
ujust horizon-vm-remove     # undo
```

### Installing apps

Install apps from **Fedora and Terra first**. They install system-wide, like on any other Fedora or Arch system, and stay through every update:

```bash
ujust horizon-install discord             # one app
ujust horizon-install obs-studio gimp     # several at once
dnf search <word>                         # find a package's name
ujust horizon-remove discord              # remove it again
```

**No reboot needed.** On Bazzite, `rpm-ostree install` normally only takes effect at the next boot; `horizon-install` switches the running system over immediately, so the app is ready right away. If a system update is already waiting for a reboot, or the package is a driver, it tells you a reboot is needed instead. Removing an app does take effect at the next reboot.

**Flatpak is optional**, for when you specifically want it: an app that only exists as a Flatpak, or one you want sandboxed. The Flathub store and `flatpak install` work as usual. For Arch packages and the AUR, Distrobox can run Arch with `yay` alongside the system.

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
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> or <kbd>Super</kbd> + <kbd>Print</kbd> | Screenshot: drag a box, then edit and save it |
| <kbd>Print</kbd> | Screenshot of the screen under the pointer, then edit and save it |
| <kbd>Alt</kbd> + <kbd>Print</kbd> | Screenshot of every screen, then edit and save it |
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

## Making your own

Want your own custom Bazzite, or another Fedora Atomic system? Universal Blue's **[image-template](https://github.com/ublue-os/image-template)** is where to start. In short:

1. On the image-template page, click **Use this template** to make your own copy, then turn on workflows in its **Actions** tab.
2. Pick a starting system on the `FROM` line of the `Containerfile`, for example `ghcr.io/ublue-os/bazzite:stable`, `ghcr.io/ublue-os/aurora:stable`, `ghcr.io/ublue-os/bluefin:stable` or `quay.io/fedora/fedora-bootc:44`.
3. Set your image name and GitHub username in `image-template.env`.
4. Add your packages and tweaks to `build_files/build.sh`.
5. Push. GitHub builds the image for you.
6. Switch an installed system to it with `sudo bootc switch ghcr.io/<your-username>/<image-name>`, or build an installer ISO with the template's disk workflow.

The [image-template README](https://github.com/ublue-os/image-template#readme) covers each step, including image signing.

---

## Credits

- [Bazzite](https://github.com/ublue-os/bazzite) and [Universal Blue](https://universal-blue.org): the base system and the [image template](https://github.com/ublue-os/image-template) this repo started from
- [Event Horizon](https://github.com/Event-Horizon-desktop-environment/Event-Horizon) by Ryzendrew: the desktop shell (Zig rewrite)
- [Hyprland](https://hypr.land): the compositor
- [Strata](https://github.com/lgse/strata) by lgse: the file manager
- [dcli-bootc](https://gitlab.com/theblackdon/dcli-bootc) by theblackdon: the profile/modules layout (`profile.yaml`, `modules/`)

## License

This repository is [Apache-2.0](LICENSE). Event Horizon is MIT licensed and downloaded at build time; it is not included in this repository.
