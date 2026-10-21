#!/usr/bin/env bash
# Desktop look: Catppuccin Mocha, sapphire accent, with Conflux icons.
#
#   Icons  Conflux (https://github.com/MoshiurRahmanAdib/Conflux-Icon-Theme, GPL-3.0)
#   GTK    Catppuccin GTK, mocha / sapphire (https://github.com/catppuccin/gtk, GPL-3.0;
#          archived upstream, the last release is pinned)
#   Qt     Kvantum with Catppuccin's Kvantum theme, through qt6ct, which also
#          gets Catppuccin's color scheme (https://github.com/catppuccin/kvantum,
#          https://github.com/catppuccin/qt5ct, MIT)
#
# theme.ref pins every source: git commits, and a sha256 for the GTK zip.
# Defaults are set system-wide here; bazzite-horizon-apply-theme applies them
# to each user's settings once, at their next login.
#
# Other icon themes are hidden from theme pickers, not deleted: Conflux
# inherits hicolor, Adwaita and breeze for icons it does not draw, and every
# application installs its own icon into hicolor. The Breeze and Oxygen Qt
# styles and the Breeze GTK themes are removed. Fusion and Windows are built
# into Qt itself and cannot be.
set -euo pipefail
trap 'echo "::error title=install-theme.sh::line ${LINENO}: ${BASH_COMMAND}"' ERR

ref() { awk -v k="$1" '$1 == k { print $2 }' /ctx/theme.ref; }
sum() { awk -v k="$1" '$1 == k { print $3 }' /ctx/theme.ref; }

work=$(mktemp -d)
trap 'rm -rf "${work}"' EXIT

fetch_git() { # <dir> <url> <commit>
    git init -q "$1"
    git -C "$1" remote add origin "$2"
    local try
    for try in 1 2 3; do
        if git -C "$1" fetch -q --depth 1 origin "$3"; then
            break
        fi
        if (( try == 3 )); then
            echo "could not fetch $2 @ $3" >&2
            return 1
        fi
        sleep $(( try * 15 ))
    done
    git -C "$1" checkout -q FETCH_HEAD
    [[ "$(git -C "$1" rev-parse HEAD)" == "$3" ]]
}

dnf5 install -y git kvantum qt6ct unzip

# --- Icons: Conflux -------------------------------------------------------------
fetch_git "${work}/conflux" https://github.com/MoshiurRahmanAdib/Conflux-Icon-Theme "$(ref conflux)"
dest=/usr/share/icons/Conflux
rm -rf "${dest}"
mkdir -p "${dest}"
for d in "${work}"/conflux/*/; do
    name=$(basename "${d}")
    case "${name}" in Workspace|images) continue ;; esac
    cp -a "${d%/}" "${dest}/"
done
install -m644 "${work}/conflux/index.theme" "${work}/conflux/LICENSE" "${dest}/"
# Upstream links its developer helper (Workspace/optimize.sh) into each folder.
find "${dest}" -name optimize.sh -delete
if find "${dest}" -xtype l | grep -q .; then
    echo "Conflux: broken symlinks:" >&2
    find "${dest}" -xtype l | head >&2
    exit 1
fi
gtk-update-icon-cache -f -q "${dest}"

# Hide every other icon theme from theme pickers (Hidden=true is the
# freedesktop key for that). Lookups and fallbacks are unaffected. Cursor-only
# themes have no Directories= and keep showing in cursor pickers.
for index in /usr/share/icons/*/index.theme; do
    dir=$(dirname "${index}")
    [[ "${dir}" == "${dest}" ]] && continue
    grep -q '^Directories=' "${index}" || continue
    if grep -q '^Hidden=' "${index}"; then
        sed -i 's/^Hidden=.*/Hidden=true/' "${index}"
    else
        sed -i '0,/^\[Icon Theme\]/s//[Icon Theme]\nHidden=true/' "${index}"
    fi
    echo "icons: hidden $(basename "${dir}")"
done

# --- GTK: Catppuccin Mocha Sapphire ---------------------------------------------
gtk_ver=$(ref catppuccin-gtk)
gtk_name="catppuccin-mocha-sapphire-standard+default"
curl --fail --location --silent --show-error --retry 3 -o "${work}/gtk.zip" \
    "https://github.com/catppuccin/gtk/releases/download/${gtk_ver}/${gtk_name}.zip"
echo "$(sum catppuccin-gtk)  ${work}/gtk.zip" | sha256sum -c -
unzip -q "${work}/gtk.zip" -d "${work}/gtk"
rm -rf "/usr/share/themes/${gtk_name}"
cp -a "${work}/gtk/${gtk_name}" /usr/share/themes/
test -f "/usr/share/themes/${gtk_name}/gtk-3.0/gtk.css"
test -f "/usr/share/themes/${gtk_name}/gtk-4.0/gtk.css"
# Breeze GTK themes go; Adwaita and HighContrast are built into GTK itself.
rm -rf /usr/share/themes/Breeze /usr/share/themes/Breeze-Dark

# --- Qt: Kvantum + qt6ct color scheme -------------------------------------------
fetch_git "${work}/kvantum" https://github.com/catppuccin/kvantum "$(ref catppuccin-kvantum)"
rm -rf /usr/share/Kvantum/catppuccin-mocha-sapphire
cp -a "${work}/kvantum/themes/catppuccin-mocha-sapphire" /usr/share/Kvantum/
install -Dm644 "${work}/kvantum/LICENSE" /usr/share/Kvantum/catppuccin-mocha-sapphire/LICENSE

fetch_git "${work}/qt5ct" https://github.com/catppuccin/qt5ct "$(ref catppuccin-qt5ct)"
install -Dm644 "${work}/qt5ct/themes/catppuccin-mocha-sapphire.conf" \
    /usr/share/qt6ct/colors/catppuccin-mocha-sapphire.conf

compgen -G "/usr/lib64/qt6/plugins/styles/*kvantum*" >/dev/null

# Breeze and Oxygen widget styles (Qt 5 and 6). KDE apps fall back to the
# configured style (Kvantum) instead.
for f in /usr/lib64/qt5/plugins/styles/* /usr/lib64/qt6/plugins/styles/*; do
    [[ -e "${f}" ]] || continue
    case "$(basename "${f}")" in
        *breeze*|*oxygen*) rm -f "${f}"; echo "qt: removed style ${f}" ;;
    esac
done

# --- System-wide GTK defaults -----------------------------------------------------
cat > /usr/share/glib-2.0/schemas/zz1-bazzite-horizon-theme.gschema.override <<OVR
[org.gnome.desktop.interface]
gtk-theme='${gtk_name}'
icon-theme='Conflux'
color-scheme='prefer-dark'
OVR
glib-compile-schemas /usr/share/glib-2.0/schemas

printf '%s\n' "${gtk_name}" > /usr/share/bazzite-horizon/gtk-theme
echo "theme: Conflux icons, ${gtk_name} GTK, Kvantum catppuccin-mocha-sapphire"
