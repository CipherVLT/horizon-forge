#!/usr/bin/env bash
# Run build_files/build.sh in a bubblewrap sandbox and check what it writes.
# /usr and /etc are throwaway overlays of the host, so no container engine
# or root is needed. dnf5, systemctl and ldd are stubbed, and /ehroot holds
# a fake EventHorizon in place of the eh-builder stage.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if ! command -v bwrap >/dev/null 2>&1; then
    echo "bwrap could not be found. Please install bubblewrap." >&2
    exit 1
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The ctx stage of the Containerfile: build_files at /, system_files beside it.
mkdir -p "$work/ctx" "$work/stubs"
cp -a "$repo/build_files/." "$work/ctx/"
cp -a "$repo/system_files" "$work/ctx/system_files"

cat >"$work/stubs/dnf5" <<'EOF'
#!/usr/bin/env bash
echo "dnf5 $*" >>/out/dnf5.log
if [[ $1 == install ]]; then
    # Stand in for files the real packages would install, unless the host
    # already has them (host files are read-only here).
    for f in /usr/lib/systemd/boot/efi/systemd-bootx64.efi \
        /usr/lib/systemd/system/systemd-boot-update.service; do
        [[ -e $f ]] || touch "$f"
    done
fi
EOF

cat >"$work/stubs/systemctl" <<'EOF'
#!/usr/bin/env bash
echo "systemctl $*" >>/out/systemctl.log
exit "${STUB_SYSTEMCTL_RC:-0}"
EOF

cat >"$work/stubs/ldd" <<'EOF'
#!/usr/bin/env bash
printf '%s' "${STUB_LDD_OUTPUT:-}"
EOF

# Directories build.sh writes into. Under an unprivileged overlay, host
# directories show up owned by nobody, so each one gets a copy in the upper
# layer that we own before the sandbox starts.
writable_dirs=(
    usr/bin usr/libexec usr/lib usr/lib/systemd/system usr/lib/systemd/boot/efi
    usr/share usr/share/wayland-sessions
    etc/skel etc/yum.repos.d etc/systemd/system
    etc/systemd/system/multi-user.target.wants
    etc/systemd/system/shutdown.target.wants
    etc/systemd/system/sysinit.target.wants
)
while IFS= read -r d; do
    writable_dirs+=("$d")
done < <(cd "$repo/system_files" && find usr etc -type d)

chmod 0755 "$work/stubs/"*

root_links=()
for dir in bin sbin lib lib64; do
    if [[ -L /$dir ]]; then
        root_links+=(--symlink "$(readlink "/$dir")" "/$dir")
    elif [[ -d /$dir ]]; then
        root_links+=(--ro-bind "/$dir" "/$dir")
    fi
done

# run_case NAME [VAR=value ...] runs build.sh once with those variables set.
# Afterwards $out holds dnf5.log, systemctl.log, build.log and rc, and $r is
# the overlay upper layer: every file build.sh created or changed, rooted at /.
# SEED_BOOTLOADER_NAME=1 puts a BOOTLOADER_NAME line in os-release first,
# NO_EHROOT=1 leaves /ehroot empty, and STUB_LDD_OUTPUT is what ldd prints.
run_case() {
    local name=$1
    shift
    local dir=$work/$name
    out=$dir/out
    r=$dir/upper
    mkdir -p "$out" "$dir/ehroot" "$dir/work/usr" "$dir/work/etc"

    local env_args=() kv no_ehroot=0 seed_bootloader=0
    for kv in "$@"; do
        case $kv in
            NO_EHROOT=1) no_ehroot=1 ;;
            SEED_BOOTLOADER_NAME=1) seed_bootloader=1 ;;
            *) env_args+=(--setenv "${kv%%=*}" "${kv#*=}") ;;
        esac
    done

    local d
    for d in "${writable_dirs[@]}"; do
        mkdir -p "$r/$d"
    done

    # Base image state: os-release and the repo files build.sh rewrites.
    printf 'NAME="Bazzite"\n' >"$r/usr/lib/os-release"
    if [[ $seed_bootloader == 1 ]]; then
        printf 'BOOTLOADER_NAME="Bazzite"\n' >>"$r/usr/lib/os-release"
    fi
    printf '[terra]\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-terra43\n' \
        >"$r/etc/yum.repos.d/terra.repo"
    printf '[fedora]\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-43\n' \
        >"$r/etc/yum.repos.d/fedora.repo"
    touch "$r/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:nett00n:hyprland.repo"

    if [[ $no_ehroot == 0 ]]; then
        mkdir -p "$dir/ehroot/usr/bin"
        printf '#!/usr/bin/env bash\necho "EventHorizon test"\n' \
            >"$dir/ehroot/usr/bin/EventHorizon"
        chmod 0755 "$dir/ehroot/usr/bin/EventHorizon"
    fi

    local rc=0
    bwrap \
        --overlay-src /usr --overlay "$r/usr" "$dir/work/usr" /usr \
        --overlay-src /etc --overlay "$r/etc" "$dir/work/etc" /etc \
        "${root_links[@]}" \
        --proc /proc --dev /dev --tmpfs /tmp \
        --ro-bind "$work/ctx" /ctx \
        --ro-bind "$work/stubs" /stubs \
        --ro-bind "$dir/ehroot" /ehroot \
        --bind "$out" /out \
        --unshare-all --die-with-parent \
        --setenv PATH "/stubs:/usr/bin:/usr/sbin" \
        --unsetenv BAZZITE_HORIZON_BASE \
        "${env_args[@]}" \
        /usr/bin/bash /ctx/build.sh >"$out/build.log" 2>&1 || rc=$?
    echo "$rc" >"$out/rc"
    touch "$out/dnf5.log" "$out/systemctl.log"
}

failures=0
current=""

fail() {
    echo "FAIL [$current] $*" >&2
    failures=$((failures + 1))
}

assert_rc() {
    local got
    got=$(<"$out/rc")
    if [[ $got != "$1" ]]; then
        fail "exit status: want $1, got $got. Tail of build.log:"
        tail -n 20 "$out/build.log" >&2
    fi
}
assert_file_eq() {
    local file=$1 want=$2
    [[ -f $file ]] || { fail "missing $file"; return; }
    [[ $(<"$file") == "$want" ]] || fail "$file: want '$want', got '$(<"$file")'"
}
assert_grep() {
    local pattern=$1 file=$2
    grep -qE -- "$pattern" "$file" 2>/dev/null || fail "no /$pattern/ in ${file#"$work"/}"
}
assert_no_grep() {
    local pattern=$1 file=$2
    ! grep -qE -- "$pattern" "$file" 2>/dev/null || fail "unexpected /$pattern/ in ${file#"$work"/}"
}
assert_link() {
    local link=$1 target=$2
    [[ -L $link && $(readlink "$link") == "$target" ]] ||
        fail "${link#"$work"/} should link to $target"
}
assert_absent() {
    [[ ! -e $1 && ! -L $1 ]] || fail "${1#"$work"/} should not exist"
}

# --- default base, BOOTLOADER_NAME already present, systemctl unavailable --
current=default-base
run_case "$current" \
    BAZZITE_HORIZON_BASE=ghcr.io/ublue-os/bazzite:stable \
    SEED_BOOTLOADER_NAME=1 \
    STUB_SYSTEMCTL_RC=1
bh=$r/usr/share/bazzite-horizon
assert_rc 0
assert_file_eq "$bh/boot-title" "Bazzite Horizon"
assert_file_eq "$bh/base-image" "ghcr.io/ublue-os/bazzite:stable"
assert_file_eq "$bh/event-horizon.ref" "$(<"$repo/build_files/event-horizon.ref")"
[[ $(grep -c '^BOOTLOADER_NAME=' "$r/usr/lib/os-release") == 1 ]] ||
    fail "os-release should have exactly one BOOTLOADER_NAME line"
assert_grep '^BOOTLOADER_NAME="Bazzite Horizon"$' "$r/usr/lib/os-release"
cmp -s "$r/etc/skel/.config/hypr/hyprland.conf" \
    "$repo/system_files/usr/share/event-horizon/skel/hypr/hyprland.conf" ||
    fail "skel hyprland.conf was not copied"
cmp -s "$r/etc/skel/.config/hypr/eh/colors.conf" \
    "$repo/system_files/usr/share/event-horizon/skel/hypr/eh/colors.conf" ||
    fail "skel colors.conf was not copied"
assert_link "$r/etc/systemd/system/bootloader-update.service" /dev/null
assert_link "$r/etc/systemd/system/sysinit.target.wants/systemd-boot-update.service" \
    /usr/lib/systemd/system/systemd-boot-update.service
for target in multi-user shutdown; do
    assert_link "$r/etc/systemd/system/$target.target.wants/bazzite-horizon-sdboot-sync.service" \
        /usr/lib/systemd/system/bazzite-horizon-sdboot-sync.service
done
assert_grep '^gpgkey=https://raw\.githubusercontent\.com/terrapkg/packages/frawhide/anda/terra/gpg-keys/RPM-GPG-KEY-terra43$' \
    "$r/etc/yum.repos.d/terra.repo"
assert_grep '^gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-43$' "$r/etc/yum.repos.d/fedora.repo"
assert_absent "$r/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:nett00n:hyprland.repo"
assert_grep '^dnf5 copr enable -y nett00n/hyprland$' "$out/dnf5.log"
assert_grep '^dnf5 install -y hyprland ' "$out/dnf5.log"
assert_grep '^dnf5 copr disable -y nett00n/hyprland$' "$out/dnf5.log"
assert_grep '^dnf5 clean all$' "$out/dnf5.log"

# --- NVIDIA base, no BOOTLOADER_NAME yet, systemctl works ------------------
current=nvidia-base
run_case "$current" \
    BAZZITE_HORIZON_BASE=ghcr.io/ublue-os/bazzite-nvidia-open:stable \
    STUB_SYSTEMCTL_RC=0
assert_rc 0
assert_file_eq "$r/usr/share/bazzite-horizon/boot-title" "Bazzite Horizon NVIDIA"
assert_grep '^BOOTLOADER_NAME="Bazzite Horizon NVIDIA"$' "$r/usr/lib/os-release"
assert_grep '^NAME="Bazzite"$' "$r/usr/lib/os-release"
assert_grep '^systemctl enable systemd-boot-update\.service$' "$out/systemctl.log"
assert_grep '^systemctl enable bazzite-horizon-sdboot-sync\.service$' "$out/systemctl.log"
assert_absent "$r/etc/systemd/system/multi-user.target.wants/bazzite-horizon-sdboot-sync.service"
assert_absent "$r/etc/systemd/system/sysinit.target.wants/systemd-boot-update.service"

# --- eh-builder staged nothing ---------------------------------------------
current=missing-ehroot
run_case "$current" BAZZITE_HORIZON_BASE=ghcr.io/ublue-os/bazzite:stable NO_EHROOT=1
assert_rc 1
assert_grep 'eh-builder did not stage /ehroot' "$out/build.log"
assert_no_grep '^dnf5 clean all$' "$out/dnf5.log"

# --- EventHorizon is missing a shared library ------------------------------
current=missing-library
run_case "$current" \
    BAZZITE_HORIZON_BASE=ghcr.io/ublue-os/bazzite:stable \
    "STUB_LDD_OUTPUT=	libhyprutils.so.7 => not found"
assert_rc 1
assert_grep 'EventHorizon is missing shared libraries' "$out/build.log"

# --- BAZZITE_HORIZON_BASE unset (build.sh run outside the Containerfile) ---
current=unset-base
run_case "$current"
assert_rc 0
assert_file_eq "$r/usr/share/bazzite-horizon/base-image" "unset"
assert_file_eq "$r/usr/share/bazzite-horizon/boot-title" "Bazzite Horizon"
assert_grep '^BOOTLOADER_NAME="Bazzite Horizon"$' "$r/usr/lib/os-release"

if ((failures > 0)); then
    echo "$failures assertion(s) failed" >&2
    exit 1
fi
echo "build.sh: all cases passed"
