# Bazzite Horizon helpers. Bazzite imports /usr/share/ublue-os/just/*.just.

# Print the image variant and the Event Horizon commit baked into it
horizon-info:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Bazzite Horizon"
    echo "Base: ${BAZZITE_HORIZON_BASE:-unknown}"
    if [[ -f /usr/share/bazzite-horizon/event-horizon.ref ]]; then
        echo "Event Horizon: $(tr -d '[:space:]' < /usr/share/bazzite-horizon/event-horizon.ref)"
    fi
    EventHorizon --version
