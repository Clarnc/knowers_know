#!/bin/bash

WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
LOGFILE="${1:-/mnt/c/Users/$WIN_USER/AppData/Local/Warframe/EE.log}"
#LOGFILE="/mnt/c/Users/claus.CLARNCPC/AppData/Local/Warframe/EE.log"
if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  exit 1
fi

# Get the last "Replication count" block
START="Net [Info]: Replication count by concrete type:"
END="Net [Info]: Replication count by type:"

# Reverse the file, find the last block, and reverse again to restore order
block=$(tac "$LOGFILE" | awk -v start="$END" -v end="$START" '
  $0 ~ start {in_block=1}
  in_block {print}
  $0 ~ end && in_block {exit}
' | tac)

if [[ -z "$block" ]]; then
  echo "ERROR_NO_BLOCK_FOUND"
  exit 1
fi

# Now check for the target line
TARGET="/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven"

if echo "$block" | grep -q "$TARGET"; then
  echo "✅"
else
  echo "🟥"
fi
