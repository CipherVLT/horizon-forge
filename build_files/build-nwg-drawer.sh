#!/usr/bin/env bash
# Compile nwg-drawer, the Super+A app drawer, and stage it under
# /drawerroot. Runs in a throwaway stage (see Containerfile), so Go and the
# -devel packages don't land in the image.
#
# Fedora retired its nwg-drawer package after Fedora 43 and Terra doesn't
# carry it, so it is built from a pinned upstream release (as Perihelion
# does). The tag must still point at the pinned commit, and go.sum pins
# every Go module (-mod=readonly refuses anything else).
set -euo pipefail
trap 'echo "::error title=build-nwg-drawer.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

version=v0.7.5
commit=6f2accf085a34cc7d82eb620f023639c87ec12bb

for try in 1 2 3; do
    dnf5 install -y --setopt=install_weak_deps=False \
        git-core golang gtk3-devel gtk-layer-shell-devel gobject-introspection-devel && break
    (( try < 3 )) || exit 1
    sleep $((try * 20))
done

work=$(mktemp -d)
git clone -q --depth 1 --branch "${version}" https://github.com/nwg-piotr/nwg-drawer "${work}/src"
got=$(git -C "${work}/src" rev-parse HEAD)
if [[ "${got}" != "${commit}" ]]; then
    echo "::error title=build-nwg-drawer.sh::nwg-drawer ${version} is ${got}, expected ${commit}"
    exit 1
fi
(
    cd "${work}/src"
    export GOTOOLCHAIN=local GOFLAGS=-mod=readonly CGO_ENABLED=1 GOPATH=/tmp/go GOCACHE=/tmp/go-cache
    go build -trimpath -ldflags='-s -w' -o "${work}/nwg-drawer" .
)

dest=/drawerroot
rm -rf "${dest}"
install -Dm755 "${work}/nwg-drawer" "${dest}/usr/bin/nwg-drawer"
install -d "${dest}/usr/share/nwg-drawer"
cp -R "${work}/src/desktop-directories" "${work}/src/img" "${dest}/usr/share/nwg-drawer/"
install -Dm644 "${work}/src/drawer.css" "${dest}/usr/share/nwg-drawer/drawer.css"
install -Dm644 "${work}/src/LICENSE" "${dest}/usr/share/licenses/nwg-drawer/LICENSE"
if [[ -f "${work}/src/LICENSE-gotk4" ]]; then
    install -Dm644 "${work}/src/LICENSE-gotk4" "${dest}/usr/share/licenses/nwg-drawer/LICENSE-gotk4"
fi
echo "Staged nwg-drawer ${version} (${commit})"
