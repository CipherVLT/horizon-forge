#!/usr/bin/env bash
# fastfetch: Perihelion's / Veyl OS's tree layout (OS, WM, PC, Age sections)
# in Bazzite's look: Bazzite's logo and logo colors, keys in Bazzite's accent
# color (passed by Bazzite's fastfetch/neofetch aliases with --color). The
# layout replaces Bazzite's own config file, so those aliases (bash and
# fish) pick it up. A new terminal window shows it once, like Perihelion.
set -euo pipefail
trap 'echo "::error title=fastfetch.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

conf=/usr/share/ublue-os/bazzite/fastfetch.jsonc
for f in "${conf}" /usr/share/ublue-os/bazzite/logo.txt /usr/libexec/bazzite-fetch-image \
        /usr/libexec/bazzite-bling-fastfetch; do
    [[ -e "${f}" ]] || { echo "::error title=fastfetch.sh::Bazzite's ${f} is gone"; exit 1; }
done
install -m644 /usr/share/bazzite-horizon/fastfetch.jsonc "${conf}"
chmod 0755 /usr/libexec/bazzite-horizon-os-age

# Fail the build if the config doesn't parse or a module errors.
out=$(fastfetch --color "$(/usr/libexec/bazzite-bling-fastfetch)" -c "${conf}" --pipe 2>&1) || { echo "${out}"; exit 1; }
if grep -qi 'error' <<<"${out}"; then
    echo "${out}"
    echo "::error title=fastfetch.sh::fastfetch reported an error with the config"
    exit 1
fi
echo "${out}"
