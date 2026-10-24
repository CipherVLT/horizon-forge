# Bazzite Horizon recipes. Run `ujust --choose` to browse them.

# Show the image variant and the Event Horizon commit baked into it
horizon-info:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Bazzite Horizon"
    echo "Base: ${BAZZITE_HORIZON_BASE:-$(cat /usr/share/bazzite-horizon/base-image 2>/dev/null || echo unknown)}"
    if [[ -f /usr/share/bazzite-horizon/event-horizon.ref ]]; then
        echo "Event Horizon: $(tr -d '[:space:]' < /usr/share/bazzite-horizon/event-horizon.ref)"
    fi
    horizon --version

# Install QEMU/KVM virtual machines (virt-manager) system-wide. Reboot after.
horizon-vm:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing QEMU/KVM and virt-manager as system packages (applies after a reboot)..."
    rpm-ostree install --idempotent --allow-inactive qemu-kvm libvirt virt-manager virt-viewer
    sudo systemctl enable libvirtd.service
    if ! getent group libvirt >/dev/null; then
        sudo groupadd --system libvirt
    fi
    sudo usermod -aG libvirt "${USER}"
    echo "Done. Reboot, then open Virtual Machine Manager."

# Remove the QEMU/KVM packages installed by horizon-vm. Reboot after.
horizon-vm-remove:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo systemctl disable libvirtd.service || true
    rpm-ostree uninstall qemu-kvm libvirt virt-manager virt-viewer
    echo "Done. Reboot to finish."

# Check the gaming setup: CPU governor, power profile, GameMode, NTSync, Wine
horizon-gaming-check:
    #!/usr/bin/env bash
    set -uo pipefail
    cpu=/sys/devices/system/cpu/cpu0/cpufreq
    echo "CPU driver:        $(cat $cpu/scaling_driver 2>/dev/null || echo unknown)"
    echo "CPU governor:      $(cat $cpu/scaling_governor 2>/dev/null || echo unknown)"
    echo "Energy preference: $(cat $cpu/energy_performance_preference 2>/dev/null || echo n/a)"
    echo "Power profile:     $(powerprofilesctl get 2>/dev/null || tuned-adm active 2>/dev/null | sed 's/^Current active profile: //' || echo unknown)"
    echo
    if command -v gamemoded >/dev/null; then
        echo "GameMode:          $(gamemoded -s 2>&1 | tail -n 1)"
    else
        echo "GameMode:          not installed"
    fi
    if [[ -e /dev/ntsync ]]; then
        echo "NTSync:            /dev/ntsync present ($(stat -c '%A' /dev/ntsync))"
    else
        echo "NTSync:            /dev/ntsync missing (try: sudo modprobe ntsync)"
    fi
    echo "Wine:              $(wine --version 2>/dev/null || echo not installed)"
    echo "Winetricks:        $(winetricks --version 2>/dev/null | head -n 1 || echo not installed)"
    echo
    echo "While a game runs with 'gamemoderun %command%', run this again:"
    echo "the governor and energy preference should read 'performance'."
    echo "Full self-test: gamemoded -t"

# Install yabridge: use Windows VST2/VST3/CLAP plugins (Serum, ...) in Linux DAWs
horizon-yabridge:
    #!/usr/bin/env bash
    set -euo pipefail
    # Built from current upstream code by this project's "Build yabridge"
    # workflow: yabridge's last release (5.1.1) breaks plugin GUIs on Wine 9.22+.
    repo=CipherVLT/horizon-forge
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    echo "Looking up the newest yabridge build..."
    curl -fsSL "https://api.github.com/repos/${repo}/releases?per_page=50" -o "$work/releases.json"
    mapfile -t urls < <(python3 - "$work/releases.json" <<'PY'
    import json, sys
    for rel in json.load(open(sys.argv[1])):
        if not rel["tag_name"].startswith("yabridge-") or rel["draft"]:
            continue
        assets = {a["name"]: a["browser_download_url"] for a in rel["assets"]}
        tgz = [n for n in assets if n.endswith(".tar.gz")]
        if tgz and tgz[0] + ".sha256" in assets:
            print(rel["tag_name"]); print(assets[tgz[0]]); print(assets[tgz[0] + ".sha256"])
            break
    PY
    )
    if (( ${#urls[@]} < 3 )); then
        echo "No yabridge build is published yet. Run the 'Build yabridge' workflow on GitHub first." >&2
        exit 1
    fi
    echo "Installing ${urls[0]}..."
    curl -fsSL "${urls[1]}" -o "$work/$(basename "${urls[1]}")"
    curl -fsSL "${urls[2]}" -o "$work/$(basename "${urls[2]}")"
    (cd "$work" && sha256sum -c "$(basename "${urls[2]}")")
    mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
    rm -rf "$HOME/.local/share/yabridge"
    tar -C "$HOME/.local/share" -xzf "$work/$(basename "${urls[1]}")"
    ln -sfn "$HOME/.local/share/yabridge/yabridgectl" "$HOME/.local/bin/yabridgectl"
    yabridgectl="$HOME/.local/share/yabridge/yabridgectl"
    # Register the usual plugin folders of the default Wine prefix (~/.wine).
    c="$HOME/.wine/drive_c/Program Files"
    for dir in "$c/Common Files/VST3" "$c/Common Files/CLAP" "$c/Steinberg/VstPlugins" "$c/VstPlugins"; do
        if [[ -d "$dir" ]] && ! "$yabridgectl" list 2>/dev/null | grep -qF "$dir"; then
            "$yabridgectl" add "$dir"
        fi
    done
    "$yabridgectl" sync || true
    echo
    echo "yabridge is installed. To add a Windows plugin:"
    echo "  1. Run its installer with Wine:   wine ~/Downloads/<plugin-installer>.exe"
    echo "  2. If it went to a new folder:    yabridgectl add \"<folder with the .dll/.vst3>\""
    echo "  3. Then, after every install:     yabridgectl sync"
    echo "Your DAW finds them in ~/.vst3 and ~/.clap (VST2: the folder you added)."
    echo "Only 64-bit plugins work: this Wine is a WoW64 build."
    echo "If 'yabridgectl' is not found, open a new terminal (~/.local/bin is on PATH)."

# Remove yabridge and the plugin links it made (your Windows plugins stay in ~/.wine)
horizon-yabridge-remove:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf "$HOME/.local/share/yabridge" "$HOME/.vst3/yabridge" "$HOME/.clap/yabridge" "$HOME/.config/yabridgectl"
    rm -f "$HOME/.local/bin/yabridgectl"
    echo "yabridge removed. VST2 .so links next to your plugin .dll files are left in place."

# Install Bitwig Studio from Bitwig's official .deb into your home folder (not the Flatpak)
horizon-bitwig deb="":
    #!/usr/bin/env bash
    set -euo pipefail
    dest="$HOME/.local/opt/bitwig-studio"
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    deb="{{ deb }}"
    if [[ -z "$deb" ]]; then
        deb=$(ls -t "$HOME"/Downloads/bitwig-studio*.deb 2>/dev/null | head -n 1 || true)
    fi
    if [[ -z "$deb" ]]; then
        echo "Looking for the newest Bitwig Studio .deb on bitwig.com..."
        id=$(curl -fsSL https://www.bitwig.com/download/ 2>/dev/null \
            | grep -oE 'dl/\?id=[0-9]+&(amp;)?os=installer_linux' | head -n 1 | grep -oE 'id=[0-9]+' | cut -d= -f2 || true)
        if [[ -n "$id" ]]; then
            deb="$work/bitwig-studio.deb"
            curl -fL "https://www.bitwig.com/dl/?id=${id}&os=installer_linux" -o "$deb"
        fi
    fi
    if [[ -z "$deb" || ! -f "$deb" ]]; then
        echo "Download the Linux (.deb) installer from https://www.bitwig.com/download/" >&2
        echo "into ~/Downloads and run this again, or: ujust horizon-bitwig /path/to/bitwig-studio.deb" >&2
        exit 1
    fi
    if [[ "$(head -c 8 "$deb")" != '!<arch>' ]]; then
        echo "$deb is not a .deb package." >&2
        exit 1
    fi
    echo "Unpacking $deb..."
    # A .deb is an 'ar' archive; read it with Python (no dpkg on Fedora).
    data=$(python3 - "$deb" "$work" <<'PY'
    import os, sys
    deb, out = sys.argv[1], sys.argv[2]
    with open(deb, "rb") as f:
        assert f.read(8) == b"!<arch>\n"
        while header := f.read(60):
            name = header[:16].decode().strip().rstrip("/")
            size = int(header[48:58].decode().strip())
            body = f.read(size)
            if size % 2:
                f.read(1)
            if name.startswith("data.tar"):
                path = os.path.join(out, name)
                open(path, "wb").write(body)
                print(path)
    PY
    )
    [[ -n "$data" ]] || { echo "No data archive inside $deb" >&2; exit 1; }
    mkdir -p "$work/root"
    tar -xf "$data" -C "$work/root"
    src="$work/root/opt/bitwig-studio"
    [[ -d "$src" ]] || { echo "Unexpected .deb layout: no /opt/bitwig-studio" >&2; exit 1; }
    rm -rf "$dest"
    mkdir -p "$(dirname "$dest")" "$HOME/.local/bin" "$HOME/.local/share"
    mv "$src" "$dest"
    ln -sfn "$dest/bitwig-studio" "$HOME/.local/bin/bitwig-studio"
    # Menu entry, icons and file types, pointed at the new location.
    for sub in applications icons mime metainfo; do
        if [[ -d "$work/root/usr/share/$sub" ]]; then
            cp -a "$work/root/usr/share/$sub" "$HOME/.local/share/"
        fi
    done
    for f in "$work"/root/usr/share/applications/*.desktop; do
        [[ -f "$f" ]] || continue
        installed="$HOME/.local/share/applications/$(basename "$f")"
        # /opt paths first, then a bare or /usr/bin Exec, so nothing is rewritten twice.
        sed -i -E "s|/opt/bitwig-studio|$dest|g; s|^Exec=(/usr/bin/)?bitwig-studio|Exec=$dest/bitwig-studio|" "$installed"
    done
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    if [[ -d "$HOME/.local/share/mime/packages" ]]; then
        update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
    fi
    # Report libraries the system lacks (Bitwig is built for Debian/Ubuntu).
    missing=$(find "$dest" -maxdepth 2 -type f \( -name '*.so*' -o -perm -u+x \) -exec sh -c \
        'file -b "$1" | grep -q ELF && ldd "$1" 2>/dev/null' _ {} \; | awk '/not found/ {print $1}' | sort -u)
    if [[ -n "$missing" ]]; then
        echo
        echo "Bitwig needs libraries this system does not have:"
        pkgs=""
        for lib in $missing; do
            case "$lib" in
                libxcb-imdkit.so*) p=xcb-imdkit ;;
                libxcb-icccm.so*|libxcb-ewmh.so*) p=xcb-util-wm ;;
                libxcb-cursor.so*) p=xcb-util-cursor ;;
                libxcb-keysyms.so*) p=xcb-util-keysyms ;;
                libxcb-image.so*) p=xcb-util-image ;;
                libxcb-render-util.so*) p=xcb-util-renderutil ;;
                libxkbcommon-x11.so*) p=libxkbcommon-x11 ;;
                libbsd.so*) p=libbsd ;;
                *) p="" ;;
            esac
            echo "  $lib${p:+  (package: $p)}"
            [[ -n "$p" && " $pkgs " != *" $p "* ]] && pkgs="$pkgs $p"
        done
        if [[ -n "$pkgs" ]]; then
            echo "Install them with:  rpm-ostree install$pkgs   (then reboot)"
        fi
    fi
    echo
    echo "Bitwig Studio is installed in $dest."
    echo "Start it from the app menu or with 'bitwig-studio'. Sign in with your Bitwig account to activate it."
    echo "Audio: in Settings > Audio pick 'PipeWire' or 'JACK' (PipeWire provides JACK) for low latency."
    echo "To update, download the new .deb and run this again."

# Remove Bitwig Studio installed by horizon-bitwig (projects and settings are kept)
horizon-bitwig-remove:
    #!/usr/bin/env bash
    set -euo pipefail
    rm -rf "$HOME/.local/opt/bitwig-studio"
    rm -f "$HOME/.local/bin/bitwig-studio"
    grep -l 'local/opt/bitwig-studio' "$HOME"/.local/share/applications/*.desktop 2>/dev/null | xargs -r rm -f
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    echo "Bitwig Studio removed. Your projects and ~/.BitwigStudio settings are untouched."

# Install apps from Fedora or Terra, ready to use right away (no reboot). Example: ujust horizon-install discord
horizon-install +packages:
    #!/usr/bin/env bash
    set -uo pipefail
    pkgs=({{ packages }})
    echo "Installing ${pkgs[*]} from Fedora/Terra..."
    # Step 1: add the packages to the system image. --idempotent: a package
    # that is already installed is not an error. A misspelled name stops here.
    if ! sudo rpm-ostree install --idempotent "${pkgs[@]}"; then
        echo
        echo "Nothing was installed. Check the package name, for example with:"
        echo "  dnf search ${pkgs[0]}"
        exit 1
    fi
    # Step 2: switch the running system over to that image now instead of at
    # the next boot. It stays installed after reboots either way.
    if sudo rpm-ostree apply-live; then
        echo
        echo "Done: ${pkgs[*]} is ready to use now, no reboot needed."
        echo "If it doesn't show in the app menu yet, log out and back in."
    else
        echo
        echo "${pkgs[*]} is installed, but couldn't be switched on live."
        echo "This happens when a system update is already waiting for a reboot,"
        echo "or for packages like drivers that need one. Reboot to start using it."
    fi

# Remove apps installed with horizon-install (takes effect after a reboot). Example: ujust horizon-remove discord
horizon-remove +packages:
    #!/usr/bin/env bash
    set -uo pipefail
    pkgs=({{ packages }})
    if sudo rpm-ostree uninstall "${pkgs[@]}"; then
        echo
        echo "${pkgs[*]} will be gone after your next reboot."
        echo "(Removing needs a reboot; installing with horizon-install does not.)"
    fi

# Laptop graphics (NVIDIA image): smart | integrated | hybrid | app | app-remove. No option shows the status
horizon-gpu MODE="":
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v cardwire >/dev/null; then
        echo "Cardwire isn't in this image. GPU switching is part of the NVIDIA image (bazzite-horizon-nvidia)."
        exit 1
    fi
    cw() { cardwire "$@" 2>/dev/null || sudo cardwire "$@"; }
    case "{{ MODE }}" in
        "")
            echo "Mode: $(cardwire get 2>/dev/null || echo unknown)"
            echo
            cardwire list 2>/dev/null || true
            echo
            echo "  ujust horizon-gpu smart        NVIDIA asleep; games you allow can use it (recommended)"
            echo "  ujust horizon-gpu integrated   NVIDIA always off: longest battery"
            echo "  ujust horizon-gpu hybrid       Both GPUs open to every app (plugged in)"
            echo "  ujust horizon-gpu app          Install the Cardwire app (pick games for smart mode)"
            echo
            echo "Steam launch options for a game on the NVIDIA card in smart mode:"
            echo "  CARDWIRE_FORCE_DGPU=1 gamemoderun %command%"
            ;;
        smart|integrated|hybrid)
            cw set "{{ MODE }}"
            echo "Mode: $(cardwire get 2>/dev/null || echo "{{ MODE }}")"
            echo "Apps that are already open keep their GPU until you restart them."
            ;;
        app)
            rpm-ostree install --idempotent --allow-inactive cardwire-gui
            echo "Done. Reboot, then open Cardwire from the app menu."
            ;;
        app-remove)
            rpm-ostree uninstall cardwire-gui
            echo "Done. Reboot to finish."
            ;;
        *)
            echo "Unknown option '{{ MODE }}'. Use: smart, integrated, hybrid, app or app-remove." >&2
            exit 1
            ;;
    esac
