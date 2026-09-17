#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
USER_NAME="$(id -un)"
NEW_CONFIG_FILES_PATH="$SCRIPT_DIR/config"
CONFIG_DIR="$HOME/.config"
CONFIG_FILES=("hypr" "kitty" "paths" "quickshell" "scripts" "waypaper" "wofi")
BACKUP_DIR=$(mktemp -d "$SCRIPT_DIR/backup-config-XXXXXX")
created_links=()

echo "UPDATING CONFIG FOR USER: '$USER_NAME'"
echo ""

mkdir -pv -- "$CONFIG_DIR"

cleanup() {
    local status=$? # Сохраняем код завершения
    local target_path backup_path file_name
    local rollback_failed=0

    if (( status != 0 )); then
        echo "Failed. Error code: $status" >&2

        echo "Rolling back..."

        for target_path in "${created_links[@]}"; do
            if [[ -L "$target_path" ]]; then
                if ! rm -- "$target_path"; then
                    rollback_failed=1
                fi
            fi
        done

        for file_name in "${CONFIG_FILES[@]}"; do
            backup_path="$BACKUP_DIR/$file_name"
            target_path="$CONFIG_DIR/$file_name"
            if [[ -e "$backup_path" || -L "$backup_path" ]]; then
                if [[ -e "$target_path" || -L "$target_path" ]]; then
                    echo "Cannot restore: $target_path already exists" >&2
                    rollback_failed=1
                elif ! mv -T -- "$backup_path" "$target_path"; then
                    rollback_failed=1
                fi
            fi
        done

        if (( rollback_failed )); then
            echo "Rollback incomplete. Check backup: $BACKUP_DIR" >&2
        else
            echo "Rollback completed"
        fi
    fi

    exit "$status"
}

trap cleanup EXIT

exists_files=()
for file_name in "${CONFIG_FILES[@]}"; do
    if [[ -e "$CONFIG_DIR/$file_name" || -L "$CONFIG_DIR/$file_name" ]]; then
        exists_files+=("$file_name")
    fi
done

answer=""
if [[ ${#exists_files[@]} -gt 0 ]]; then
    echo "files '${exists_files[*]}' already exist in config."
    read -r -p "Overwrite ? [Y/n] " answer
fi

case "$answer" in
    [Yy]|[Yy][Ee][Ss]|"")
        ;;
    [Nn]|[Nn][Oo])
        echo "Stopping..."
        rm -r "$BACKUP_DIR"
        exit 0
        ;;
    *)
        echo "Unknown answer"
        rm -r "$BACKUP_DIR"
        exit 1
        ;;
esac

for file_name in "${CONFIG_FILES[@]}"; do
    source_path="$NEW_CONFIG_FILES_PATH/$file_name"
    target_path="$CONFIG_DIR/$file_name"

    # Существующий конфиг переносим в резервную копию.
    if [[ -e "$target_path" || -L "$target_path" ]]; then
        mv -- "$target_path" "$BACKUP_DIR/$file_name"
    fi

    ln -s -- "$source_path" "$target_path"
    created_links+=("$target_path")
done

echo "Script compleated successfully"
