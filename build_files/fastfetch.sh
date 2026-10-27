#!/usr/bin/env bash
# fastfetch: keep Bazzite's look (logo, colors, Nerd Font icons) and move the
# uptime into its own section at the bottom, with the OS age (days since
# install) and the date/time under it. Edits Bazzite's own config in place,
# so the fastfetch/neofetch aliases (bash and fish) pick it up.
set -euo pipefail
trap 'echo "::error title=fastfetch.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

conf=/usr/share/ublue-os/bazzite/fastfetch.jsonc
python3 - "${conf}" <<'PY'
import re, sys, pathlib
p = pathlib.Path(sys.argv[1])
s = p.read_text()
uptime = re.compile(r'\n[ \t]*\{\s*"type":\s*"uptime",\s*"key":\s*"[^"]*"\s*\},')
m = uptime.search(s)
if not m:
    sys.exit("fastfetch.sh: Bazzite's uptime module changed")
key = re.search(r'"key":\s*"([^"]*)"', m.group(0)).group(1)
s = s[:m.start()] + s[m.end():]
colors = re.compile(r'\n([ \t]*)"break",\s*\{\s*"type":\s*"colors"')
c = colors.search(s)
if not c:
    sys.exit("fastfetch.sh: Bazzite's colors module changed")
ind = c.group(1)
block = (
    f'\n{ind}"break",'
    f'\n{ind}{{\n{ind}    "type": "uptime",\n{ind}    "key": "{key}"\n{ind}}},'
    f'\n{ind}{{\n{ind}    "type": "command",\n{ind}    "key": " 󰃭",'
    f'\n{ind}    "text": "/usr/libexec/bazzite-horizon-os-age"\n{ind}}},'
    f'\n{ind}{{\n{ind}    "type": "datetime",\n{ind}    "key": " 󰃰"\n{ind}}},'
)
s = s[:c.start()] + block + s[c.start():]
p.write_text(s)
print("fastfetch: uptime, OS age and date moved to the bottom section")
PY
chmod 0755 /usr/libexec/bazzite-horizon-os-age
# Fail the build if the edited config doesn't parse or a module errors.
out=$(fastfetch -c "${conf}" --pipe 2>&1) || { echo "${out}"; exit 1; }
if grep -qi 'error' <<<"${out}"; then
    echo "${out}"
    echo "::error title=fastfetch.sh::fastfetch reported an error with the edited config"
    exit 1
fi
