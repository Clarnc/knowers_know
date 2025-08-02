#!/bin/bash

#LOGFILE="/mnt/c/Users/claus.CLARNCPC/AppData/Local/Warframe/EE.log"

WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
LOGFILE="${1:-/mnt/c/Users/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  echo "Usage: $0 [path_to_logfile]"
  exit 1
fi

START="Adding a skin ramp texture for update:/EE/Materials/Util/AlienDiffuseScattering.png"
END="CreateState: CS_FIND_LEVEL_INFO"

# Extract the last full section
log_segment=$(awk -v start="$START" -v end="$END" '
  $0 ~ start {buffer=""; in_block=1}
  in_block {buffer = buffer $0 "\n"}
  $0 ~ end && in_block {last_block = buffer; in_block=0}
  END {if (last_block) print last_block; else print "ERROR_NO_BLOCK_FOUND" > "/dev/stderr"}
' "$LOGFILE")

if [[ -z "$log_segment" || "$log_segment" == *ERROR_NO_BLOCK_FOUND* ]]; then
  echo "Error: Could not find log section with AlienDiffuseScattering block."
  exit 1
fi

# Function to process a specific layer
process_layer() {
  local layer=$1
  local block="$2"

  local backdrops=$(echo "$block" | grep "/Layer255/Layer${layer}/" | grep 'as backdrop')
  local errors=$(echo "$block" | grep "Backdrop for zone: /Layer255/Layer${layer}/")
  local count_backdrop_lines=$(echo "$backdrops" | wc -l)
  local count_errors=$(echo "$errors" | wc -l)
  local backdrop_names=$(echo "$backdrops" | grep -oP '\[\K[^]]+' | grep -vE 'Info|Error')

  # Rule 1: Named backdrops override everything
  if echo "$backdrop_names" | grep -q 'IntShuttleBayBackdrop'; then
    echo "5"; return
  elif echo "$backdrop_names" | grep -Eq 'IntParkBBackdrop|IntParkBackdrop'; then
    echo "4"; return
  elif echo "$backdrop_names" | grep -Eq 'IntLivingQuartersBackdrop|IntLunaroCourtBackdrop'; then
    echo "3"; return
  fi

  # Rule 3: Adjusted based on count of backdrop lines
  if [ "$count_backdrop_lines" -eq 1 ]; then
    echo "3"; return
  elif [ "$count_backdrop_lines" -eq 5 ]; then
        echo "3x"; return
  elif [ "$count_backdrop_lines" -eq 6 ]; then
    echo "4"; return
  elif [ "$count_backdrop_lines" -eq 9 ]; then
    echo "3"; return
  fi

  # Rule 2: If there are errors related to the layer
  if [ "$count_errors" -ge 1 ]; then
    echo "4"; return
  fi

  # Default fallback
  echo "3"
}

# Evaluate three specific rooms/layers
room1=$(process_layer 2 "$log_segment")
room2=$(process_layer 6 "$log_segment")
room3=$(process_layer 8 "$log_segment")

echo "$room1 $room2 $room3"

