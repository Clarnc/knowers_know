#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || { echo "Failed to change directory to script location."; exit 1; }

while true; do
  clear
  echo "Choose option:"
  echo "[1] Tuvul Commons (Void Cascade)"
  echo "[2] Apollo (Disruption)"
  echo "[3] Kappa (Disruption)"
  echo "[q] Quit"
  read -p "Enter choice [1-3, q]: " choice

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
      ICON_PATH="Kappa_icon.png"
      ;;
    q|Q)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Press Enter to try again."
      read
      continue
      ;;
  esac

  WIN_ICON_PATH=$(wslpath -w "$PWD/$ICON_PATH")

  echo "Starting $TITLE check. Press 'q' then Enter to return to menu."

  prev_output=""
  while true; do
    # Run the chosen script and capture output
    output=$($SCRIPT 2>/dev/null)

    if [[ "$output" != "$prev_output" ]]; then
      prev_output="$output"
      powershell.exe -Command "Import-Module BurntToast; New-BurntToastNotification -Text '$TITLE', '$output' -AppLogo '$WIN_ICON_PATH'"
    fi

    # Non-blocking check if user wants to quit
    read -t 0.1 -n 1 key
    if [[ "$key" == "q" || "$key" == "Q" ]]; then
      echo -e "\nReturning to menu..."
      break
    fi

    sleep 2
  done
done
