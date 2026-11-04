#!/usr/bin/env bash
# Fedora 45's dnf5 keeps the distribution's repository files in
# /usr/share/dnf5/repos.d (fedora, updates, Terra, ...) and turns repos on or
# off with overrides in /etc/dnf/repos.override.d. Two tools here only read
# /etc/yum.repos.d and know nothing about overrides:
#   - rpm-ostree (ujust horizon-install / horizon-asus layer packages with it)
#   - the ISO builder, which depsolves the installer from the image's repos
#     (it failed with "No match for argument: glibc" without them)
# Copy each packaged repo file to /etc/yum.repos.d under the same name (dnf5
# then reads that copy instead of the packaged one, so nothing is listed
# twice), with each repo on or off exactly as dnf5 has it now.
set -euo pipefail
trap 'echo "::error title=sync-repos.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

vendor=/usr/share/dnf5/repos.d
if ! compgen -G "${vendor}/*.repo" >/dev/null; then
    echo "repos: nothing in ${vendor}"
    exit 0
fi

# Repo ids dnf5 has on, after every override.
mapfile -t on < <(dnf5 repo list --enabled 2>/dev/null | awk 'NR > 1 { print $1 }')
(( ${#on[@]} )) || { echo "::error title=sync-repos.sh::dnf5 lists no enabled repos"; exit 1; }
printf '%s\n' "${on[@]}" > /tmp/repos-enabled

install -d /etc/yum.repos.d
for src in "${vendor}"/*.repo; do
    dest="/etc/yum.repos.d/$(basename "${src}")"
    if [[ -e "${dest}" ]]; then
        echo "repos: keeping existing ${dest}"
        continue
    fi
    awk -v list=/tmp/repos-enabled '
        BEGIN { while ((getline id < list) > 0) on[id] = 1 }
        /^\[.*\]$/ { id = substr($0, 2, length($0) - 2); print; print "enabled=" ((id in on) ? 1 : 0); next }
        /^enabled[[:space:]]*=/ { next }
        { print }
    ' "${src}" > "${dest}"
    chmod 644 "${dest}"
    echo "repos: ${dest} ($(grep -c '^enabled=1' "${dest}") on)"
done

# dnf5 must still see the same repos, now from /etc.
mapfile -t after < <(dnf5 repo list --enabled 2>/dev/null | awk 'NR > 1 { print $1 }')
if [[ "$(printf '%s\n' "${on[@]}" | sort)" != "$(printf '%s\n' "${after[@]}" | sort)" ]]; then
    echo "::error title=sync-repos.sh::enabled repos changed: before ${on[*]}, after ${after[*]}"
    exit 1
fi
grep -lq '^\[fedora\]' /etc/yum.repos.d/*.repo || { echo "::error title=sync-repos.sh::no [fedora] repo in /etc/yum.repos.d"; exit 1; }
echo "repos: ${#on[@]} enabled repos, all in /etc/yum.repos.d"
