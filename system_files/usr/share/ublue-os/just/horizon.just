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
    EventHorizon --version

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
