#!/bin/bash
WIN_USER=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' | sed 's#C:\\#c/#;s#\\#/#g')
LOGFILE="${1:-/mnt/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  exit 1
fi

START="missionType=MT_VOID_CASCADE"
END="CreateState: CS_FIND_LEVEL_INFO"

log_segment=$(tac "$LOGFILE" | awk -v start="$START" -v end="$END" '
  index($0, end) {in_block=1}
  in_block {block = $0 "\n" block}
  index($0, start) && in_block {print block; exit}
')

[[ -z "$log_segment" ]] && { echo "Error: Could not find cascade section."; exit 1; }

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
  elif echo "$backdrop_names" | grep -Eq 'IntLunaroCourtBackdrop'; then
    echo "3L"; return
  elif echo "$backdrop_names" | grep -Eq 'IntLivingQuartersBackdrop'; then
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
    echo "3Ag"; return
  fi

  # Rule 2: If there are errors related to the layer
  if [ "$count_errors" -ge 1 ]; then
    echo "4"; return
  fi

  # Default fallback
  echo "3"
}

# Function to check mid-layer backdrops
check_between_layers() {
  local block="$1"

  # Target backdrops
  local -a targets=(
    "Conshort01BD"
    "ConCornerShort03Backdrop"
    "ConNSClsRmLocal"
    "LocalSkyBox"
    "ConNSJunctShort01"
    "ConNSStrghtSht05Bkdrop"
  )

  local -A found=()
  for target in "${targets[@]}"; do
    found["$target"]=0
  done

  for layer in {3..5} 7; do
    layer_data=$(echo "$block" | grep "/Layer255/Layer${layer}/" | grep 'as backdrop')
    for target in "${targets[@]}"; do
      if echo "$layer_data" | grep -q "$target"; then
        found["$target"]=1
      fi
    done
  done

  total_found=0
  for value in "${found[@]}"; do
    (( total_found += value ))
  done

  if [ "$total_found" -eq "${#targets[@]}" ]; then
    echo "godly"
  elif [ "$total_found" -gt 0 ]; then
    echo "mid"
  else
    echo "unknown"
  fi
}

# Evaluate main rooms
room1=$(process_layer 2 "$log_segment")
room2=$(process_layer 6 "$log_segment")
room3=$(process_layer 8 "$log_segment")

# Check in-between layers
status=$(check_between_layers "$log_segment")

# Final output
echo "$room1 $room2 $room3 $status"
