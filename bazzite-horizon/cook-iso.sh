#!/usr/bin/env bash
# Cook an Anaconda ISO on this computer.
# Usage: cook-iso.sh <amd|nvidia> [build|pull]
#
# Does not start from a Bazzite ISO. `build` compiles the container here.
# `pull` uses the tag already published to ghcr.io. Either way the ISO's
# kickstart retargets the installed system at that ghcr tag, so the tag
# has to exist before you boot the USB.
set -euo pipefail

cd "$(dirname "$0")"

variant=${1:-nvidia}
mode=${2:-build}

case "$variant" in
    nvidia | nvidia-open)
        name=bazzite-horizon-nvidia
        base=ghcr.io/ublue-os/bazzite-nvidia-open:stable
        ;;
    amd | intel | amd-intel)
        name=bazzite-horizon
        base=ghcr.io/ublue-os/bazzite:stable
        ;;
    *)
        echo "variant must be amd or nvidia" >&2
        exit 1
        ;;
esac

case "$mode" in
    build | pull) ;;
    *)
        echo "mode must be build or pull" >&2
        exit 1
        ;;
esac

org=${REPO_ORGANIZATION:-}
if [[ -z "$org" && -f image-template.env ]]; then
    org=$(sed -n 's/^REPO_ORGANIZATION=//p' image-template.env | head -n 1 | tr -d '"')
fi
if [[ -z "$org" || "$org" == "YOUR_GITHUB_USER" ]]; then
    echo "Set REPO_ORGANIZATION in image-template.env to your GitHub username." >&2
    exit 1
fi

ref="ghcr.io/${org}/${name}:latest"
local_ref="localhost/${name}:latest"

echo "Image:  ${ref}"
echo "Base:   ${base}"
echo "Mode:   ${mode}"
echo "A local compile wants about 80 GiB free. This does not use a Bazzite ISO from the website."

if [[ "$mode" == "pull" ]]; then
    podman pull "$ref"
    podman tag "$ref" "$local_ref"
else
    BASE_IMAGE="$base" just build "$local_ref" latest
fi

user_id=$(podman images --filter "reference=${local_ref}" --format '{{.ID}}')
root_id=$(sudo podman images --filter "reference=${local_ref}" --format '{{.ID}}' || true)
if [[ -z "$user_id" ]]; then
    echo "podman did not tag ${local_ref}" >&2
    exit 1
fi
if [[ "$user_id" != "$root_id" ]]; then
    copytmp=$(mktemp -d -p "${PWD}" -t _build_podman_scp.XXXXXXXXXX)
    sudo TMPDIR="$copytmp" podman image scp "${UID}@localhost::${local_ref}" "root@localhost::${local_ref}"
    rm -rf "$copytmp"
fi

sed "s|GHCR_IMAGE|${ref}|g" disk_config/iso.toml > disk_config/iso.built.toml
grep -F -q "$ref" disk_config/iso.built.toml

buildtmp=$(mktemp -d -p "${PWD}" -t _build-bib.XXXXXXXXXX)
sudo podman run \
    --rm \
    --privileged \
    --pull=newer \
    --net=host \
    --security-opt label=type:unconfined_t \
    -v "${PWD}/disk_config/iso.built.toml":/config.toml:ro \
    -v "${buildtmp}:/output" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    "${BIB_IMAGE:-quay.io/centos-bootc/bootc-image-builder:latest}" \
    --type anaconda-iso \
    --use-librepo=True \
    --rootfs=btrfs \
    "${local_ref}"

mkdir -p output
sudo mv -f "${buildtmp}"/* output/
sudo rmdir "$buildtmp"
sudo chown -R "${USER}:${USER}" output/

iso=$(find output -type f -name 'install.iso' -print -quit)
echo
echo "ISO: ${iso:-output/}"
if [[ "$mode" == "build" ]]; then
    echo "Push this before you boot the USB, or the installer stops in its post script:"
    echo "  podman login ghcr.io"
    echo "  podman push ${local_ref} ${ref}"
fi
echo "Flash that ISO. The USB menu is GRUB. After install, systemd-boot lists this image."
echo "Secure Boot has to be off. UEFI only."
