# shellcheck shell=sh
# Bazzite Horizon: on Fedora atomic, /home is a link to /var/home, so a shell
# started in the resolved path shows /var/home/<user> instead of ~.
# If the current directory is the home directory under another name, switch
# to $HOME so prompts show ~.
if [ -n "${HOME:-}" ] && [ "${PWD:-}" != "${HOME}" ] \
    && [ "$(pwd -P 2>/dev/null)" = "$(cd "${HOME}" 2>/dev/null && pwd -P)" ]; then
    cd "${HOME}" || :
fi
