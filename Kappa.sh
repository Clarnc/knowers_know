#!/bin/bash

WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
LOGFILE="${1:-/mnt/c/Users/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  exit 1
fi

START="Net [Info]: Replication count by concrete type:"
END="Net [Info]: Replication count by type:"

block=$(awk -v start="$START" -v end="$END" '
  $0 ~ start {in_block=1; buffer=""}
  in_block {buffer = buffer $0 "\n"}
  $0 ~ end && in_block {print buffer; exit}
' "$LOGFILE")

if [[ -z "$block" ]]; then
  echo "ERROR_NO_BLOCK_FOUND"
  exit 1
fi

if echo "$block" | grep -q "/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven"; then
  echo "✅"
else
  echo "🟥"
fi
