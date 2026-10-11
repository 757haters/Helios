#!/usr/bin/env bash
set -euo pipefail

APPS="/Applications"
ROBLOX_APP="$APPS/Roblox.app"
HELIOS_APP="$APPS/Helios.app"

WORK="$(mktemp -d -t helios-uninstall)"

if [ -t 1 ]; then
    BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; CYAN=$'\033[36m'; NC=$'\033[0m'
else
    BOLD=""; RED=""; GREEN=""; CYAN=""; NC=""
fi

header() {
    clear 2>/dev/null || true
    echo "${BOLD}Helios | v0.0.1${NC}"
    cat <<'EOF'
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@%%%%%%@@@@@@@@@@@@@@@@@@ @@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@%%%%%%%%@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@%%%%%%%%%####*+==++**#%%   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@%%%%###**+++-----++*###+   %@@@@@%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@%%%##*++==-:::---==++#%     @@@@@#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@%%##*==--   @@@@@@#             =@@@@@%  @@@@@@@@@@@@@@@@
@@@@@@@%%#**==-@@   @@@@    @%%#==+*:    %@@    @@@@@@@@@@@@@@@@
@@@@@@@%%##*=-%@@@ @@@   @@@ @@:@-*-+@@@   %@@@@@@@@@@@@@@@@@@@@
@@@@@@@@%%#*===@@@@@   @@@ @@@@@@@@@@@ @%#   %**#%%@@@@@@@@@@@@@
@@@@@@@@%%##+==@@@@#  @@@@@@@@@@@@@@@@@@%##  +**%*+*%%%@@@@@@@@@
@@@@@@@@%%%#*+==@#   @@@@@@@@@@@@@@@@@@@%%##   *%%%##++*#%%%@@@@
@@@@@@@%%+           @@@@@@@@@@@@@@@@@@@%%%%           +@@@%*##*
@@@@@@@%%%%%%%%#*=   %@@@@@@@@@@@@@@@@@@%%%%   *%%@@@@@@@@@@@%%%
%%%%%%%%%%%%%%%%%%#+  =-@@@@@@@@@@@@@@@@@%%  *%%%@@@@@@@@@@@@@@@
%%%%%@@@@@@@@@@@@@@@    @ . ++==@@@@@@ :@   %%%%@@@@@@@@@@@@@@@@
%%%%@@@@@@@@@@@@@@@@@@   @@@%@@ %++ +@@@   %%%%%@@@@@@@@@@@@@@@@
%%%%@@@@@@@@@@@@@@ @@@@@    @@@@@@@@:    @@@%%%%@@@@@@@@@@@@@@@@
%%@@@@@@@@@@@@@@  :@@@@@@@@@@@     @@@@@@@@@@@  *@@@@@@@@@@@@@@@
%%@@@@@@@@@@@@ :@@@@@@@@@@@@@@     @@@@@@@@@@@@@= @@%@@@@@@@@@@@
@@@@@@@@@@@@####%%%@@@@@@@@@@@*   %@@@@@@@@@@@@@@@@@@@@*@@@@@@@@
@@@@+@@@@@@@%%%#****##%%@@@@@@@  :@@@@@@@@@@@@@@@@@@@@@@@@@@@*%%
=#@@@@@@@@@@@@%%##***##%%%@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*#%%@@@@@@@@@@%%%#######%%%@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
++*#%%@@@@@@@%%%%########%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
+***#%%%@@@%%%%%%########%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
****##%%%%%%%%%%##########%%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
EOF
    echo "${BOLD}Helios Uninstaller | v0.0.1${NC}"
    echo
}

step() { echo "${CYAN}>${NC} ${BOLD}$1${NC}"; }
fail() { echo "${RED}Error:${NC} $1"; exit 1; }

nuke() {
    [ -e "$1" ] || return 0
    rm -rf "$1" 2>/dev/null || sudo rm -rf "$1"
    [ ! -e "$1" ] || fail "Couldn't remove $1, delete it manually."
}

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
trap 'fail "Uninstall failed on line $LINENO."' ERR

header

step "Closing Roblox and Helios"
killall -9 RobloxPlayer helios-interface Helios 2>/dev/null || true

step "Removing Helios and Roblox"
nuke "$HELIOS_APP"
nuke "$HOME/Applications/Helios.app"
nuke "$ROBLOX_APP"
nuke "$HOME/Applications/Roblox.app"
nuke "$HOME/Documents/Helios Workspace"
nuke "$HOME/Documents/Helios Automatic Execution"
nuke "$HOME/Library/Application Support/com.helios.interface"
nuke "$HOME/Library/Caches/com.helios.interface"
nuke "$HOME/Library/WebKit/com.helios.interface"
nuke "$HOME/Library/HTTPStorages/com.helios.interface"
nuke "$HOME/Library/Preferences/com.helios.interface.plist"
nuke "$HOME/Library/Saved Application State/com.helios.interface.savedState"
nuke "$HOME/Library/Application Support/Roblox"
nuke "$HOME/Library/Caches/com.roblox.RobloxPlayer"
nuke "$HOME/Library/Logs/Roblox"

step "Fetching latest Roblox version"
VERSION_JSON="$(curl -fsSL "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")"
VERSION="$(echo "$VERSION_JSON" | grep -o '"clientVersionUpload":"[^"]*' | cut -d'"' -f4)"
[ -n "$VERSION" ] || fail "Failed to fetch latest Roblox version."

if [ "$(uname -m)" = "arm64" ]; then
    ROBLOX_URL="https://setup.rbxcdn.com/mac/arm64/${VERSION}-RobloxPlayer.zip"
else
    ROBLOX_URL="https://setup.rbxcdn.com/mac/${VERSION}-RobloxPlayer.zip"
fi

step "Downloading latest Roblox ($VERSION)"
curl -#fL "$ROBLOX_URL" -o "$WORK/RobloxPlayer.zip"
unzip -oq "$WORK/RobloxPlayer.zip" -d "$WORK/Roblox"
[ -d "$WORK/Roblox/RobloxPlayer.app" ] || fail "RobloxPlayer.app not found in download."

step "Installing clean Roblox"
mv "$WORK/Roblox/RobloxPlayer.app" "$ROBLOX_APP"
rm -rf "$ROBLOX_APP/Contents/MacOS/RobloxPlayerInstaller.app"
xattr -cr "$ROBLOX_APP"

step "Cleaning up"
cleanup

trap - ERR
echo
echo "${GREEN}${BOLD}Uninstallation complete.${NC}"

open "$ROBLOX_APP"
