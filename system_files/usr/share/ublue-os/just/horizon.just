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
