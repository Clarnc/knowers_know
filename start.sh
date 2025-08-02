#!/bin/bash

prev_output=""
ICON_PATH="ThraxPlasm.png"
while true; do
  output=$(./gascade_secrets.sh)

  if [[ "$output" != "$prev_output" ]]; then
    prev_output="$output"
    powershell.exe -Command "Import-Module BurntToast; New-BurntToastNotification -Text 'gascade', '$output' -AppLogo '${ICON_PATH}'"
  fi

  sleep 2
done
