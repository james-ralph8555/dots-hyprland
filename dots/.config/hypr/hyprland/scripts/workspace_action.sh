#!/usr/bin/env bash
curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")"
dispatcher="$1"
shift ## The target is now in $1, not $2

if [[ -z "${dispatcher}" || "${dispatcher}" == "--help" || "${dispatcher}" == "-h" || -z "$1" ]]; then
  echo "Usage: $0 <dispatcher> <target>"
  exit 1
fi
if [[ "$1" == *"+"* || "$1" == *"-"* ]]; then ## Is this something like r+1 or -1?
  hyprctl dispatch "${dispatcher}" "$1" ## $1 = workspace id since we shifted earlier.
elif [[ "$1" =~ ^[0-9]+$ ]]; then ## Is this just a number?
  hyprctl dispatch "${dispatcher}" "$1" ## Direct workspace switching for single monitor setup
else
  hyprctl dispatch "${dispatcher}" "$1" ## In case the target in a string, required for special workspaces.
  exit 1
fi
