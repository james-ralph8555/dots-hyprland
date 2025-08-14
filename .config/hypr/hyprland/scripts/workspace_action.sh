#!/run/current-system/sw/bin/sh
hyprctl dispatch "$1" $(((($(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id') - 1) / 10) * 10 + $2))
