#!/bin/bash

prev_output=""
ICON_PATH="ThraxPlasm.png"
while true; do
  output=$(./gascade_secrets.sh)

  if [[ "$output" != "$prev_output" ]]; then
    prev_output="$output"
    win_icon_path=$(wslpath -w "$PWD/$ICON_PATH")
    powershell.exe -Command "Import-Module BurntToast; New-BurntToastNotification -Text \"gascade\", \"$out>  fi

  sleep 2
done
