#!/usr/bin/env bash

STATE_FILE="$HOME/.config/scripts/dont-touch/.hypr_gaps_mode.txt"

if [[ -f "$STATE_FILE" ]]; then
    hyprctl --batch "keyword general:gaps_out 20; keyword general:gaps_in 5; keyword general:border_size 1; keyword decoration:rounding 10"
    pkill waybar
    waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" & disown
    rm -f "$STATE_FILE"
else
    hyprctl --batch "keyword general:gaps_out 0; keyword general:gaps_in 0; keyword general:border_size 0; keyword decoration:rounding 0"
    pkill waybar
    waybar -c "$HOME/.config/waybar/compact/config.jsonc" -s "$HOME/.config/waybar/compact/style.css" & disown
    touch "$STATE_FILE"
fi
