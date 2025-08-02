#!/bin/bash

# Menu
clear
echo "Choose what you want to scan:"
echo "[1] Tuvul Commons (Void Cascade)"
echo "[2] Apollo (Disruption)"
echo "[3] Kappa (Disruption) — Placeholder"
read -p "Enter choice [1-3]: " choice

# Set script, title, and icon per choice
case $choice in
  1)
    SCRIPT="./gascade_secrets.sh"
    TITLE="Tuvul Commons"
    ICON_PATH="ThraxPlasm.png"
    ;;
  2)
    SCRIPT="./Apollo.sh"
    TITLE="Apollo"
    ICON_PATH="LuaDisruption.png"
    ;;
  3)
    SCRIPT="./Kappa.sh"
    TITLE="Kappa"
    ICON_PATH="KappaIcon.png"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

# Convert icon path to Windows format
WIN_ICON_PATH=$(wslpath -w "$PWD/$ICON_PATH")

# Monitoring loop
prev_output=""
while true; do
  output=$($SCRIPT 2>/dev/null)

  if [[ "$output" != "$prev_output" ]]; then
    prev_output="$output"
    powershell.exe -Command "Import-Module BurntToast; New-BurntToastNotification -Text '$TITLE', '$output' -AppLogo '$WIN_ICON_PATH'"
  fi

  sleep 2
done
