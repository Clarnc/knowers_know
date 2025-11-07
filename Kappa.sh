#!/bin/bash

# Detect Windows user
WIN_USER=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' | sed 's#C:\\#c/#;s#\\#/#g')
LOGFILE="${1:-/mnt/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  exit 1
fi

# Read from bottom to get only the most recent replication block
block=$(
  tac "$LOGFILE" | awk '
    /Net \[Info\]: Replication count by type:/ {in_block=1; next}
    in_block && /Net \[Info\]: Replication count by concrete type:/ {exit}
    in_block {print}
  ' | tac
)

# Verify we got a block
if [[ -z "$block" ]]; then
  echo "ERROR_NO_BLOCK_FOUND"
  exit 1
fi

# Look for specific audio marker
if grep -q "/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven" <<< "$block"; then
  echo "✅"
else
  echo "🟥"
fi
