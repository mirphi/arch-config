#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PACKAGES_PATH="$SCRIPT_DIR/packages"

read_packages() {
    sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//; /^$/d' "$1"
}

# Read both lists before installing anything; a read error must stop the script.
package_text=$(read_packages "$PACKAGES_PATH/pacman.txt")
aur_package_text=$(read_packages "$PACKAGES_PATH/aur.txt")
packages=()
aur_packages=()
if [[ -n "$package_text" ]]; then
    mapfile -t packages <<< "$package_text"
fi
if [[ -n "$aur_package_text" ]]; then
    mapfile -t aur_packages <<< "$aur_package_text"
fi

if (( ${#packages[@]} > 0 )); then
    sudo pacman -Syu --needed "${packages[@]}"
fi

if (( ${#aur_packages[@]} > 0 )); then
    if ! command -v yay >/dev/null 2>&1; then
        sudo pacman -Syu --needed git base-devel
        (
            build_dir=$(mktemp -d)
            trap 'rm -rf -- "$build_dir"' EXIT
            git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
            cd -- "$build_dir/yay"
            makepkg -si
        )
    fi

    yay -S --needed "${aur_packages[@]}"
fi
