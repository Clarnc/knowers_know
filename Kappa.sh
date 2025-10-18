#!/bin/bash

WIN_USER=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' | sed 's#C:\\#c/#;s#\\#/#g')
LOGFILE="${1:-/mnt/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  exit 1
fi

# Get only the last full matching block
block=$(awk '
  /Net \[Info\]: Replication count by concrete type:/ {in_block=1; block=""; next}
  in_block && /Net \[Info\]: Replication count by type:/ {in_block=0; found=block}
  in_block {block = block $0 "\n"}
  END { if (found) print found; else print "" }
' "$LOGFILE")

# Check that we got a block
if [[ -z "$block" ]]; then
  echo "ERROR_NO_BLOCK_FOUND"
  exit 1
fi

# Look for the specific audio line
if echo "$block" | grep -q "/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven"; then
  echo "✅"
else
  echo "🟥"
fi
