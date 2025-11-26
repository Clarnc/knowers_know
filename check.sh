#!/bin/bash
# check.sh - Single script to handle all mission checks
# Usage: ./check.sh <log_tail_file> <mission>

LOG_TAIL_FILE="$1"
MISSION="$2"

if [ ! -f "$LOG_TAIL_FILE" ]; then
  echo "Log file not found at $LOG_TAIL_FILE"
  exit 1
fi

# Source the map data
source ./maps_data.sh

# Get data for this mission
get_map_data "$MISSION"

# Unified log segment extraction with anti-leakage
log_segment=$(tac "$LOG_TAIL_FILE" | awk -v first="$block_end" -v later="$block_start" '
  index($0, first) && found { exit }  # Prevent leaking into previous block
  index($0, first) {found=1}
  found {block = $0 "\n" block}
  index($0, later) && found {print block; exit}
')
[[ -z "$log_segment" ]] && { echo "Error: Could not find block for $MISSION."; exit 1; }

case "$map_type" in
  sound_match)
    # Extract all sound paths from lines like "Net [Info]: 1 /path/to/sound"
    extracted_paths=$(echo "$log_segment" | awk '/Net \[Info\]: 1 \// {print $NF}')
    matches=()
    for path in "${!tile_paths[@]}"; do
      matched=0
      if [[ "$path" == "/Lotus/Sounds/"* ]]; then
        # For sound paths, check if any extracted path starts with $path
        while IFS= read -r ext_path; do
          if [[ "$ext_path" == "$path"* ]]; then
            matched=1
            break
          fi
        done <<< "$extracted_paths"
      else
        # For non-sound paths (e.g., Bridge error message), use grep on full segment
        if echo "$log_segment" | grep -Fq "$path"; then
          matched=1
        fi
      fi
      if [ "$matched" -eq 1 ]; then
        matches+=("${tile_paths[$path]}")
      fi
    done
    if [[ -n "${bad_tiles+x}" ]]; then
      skip=0
      for bad in "${bad_tiles[@]}"; do
        if [[ " ${matches[*]} " =~ " ${bad} " ]]; then
          skip=1
          break
        fi
      done
      if [ "$skip" -eq 1 ]; then
        echo "Bad tile. Skip"
        exit 0
      fi
      if [ "${#matches[@]}" -ge "$min_matches" ]; then
        echo "${matches[@]}"
      else
        echo "Bad tile. Skip"
      fi
    elif [[ -n "${allowed_tiles+x}" ]]; then
      filtered=()
      for match in "${matches[@]}"; do
        if [[ " ${allowed_tiles[*]} " =~ " ${match} " ]]; then
          filtered+=("$match")
        fi
      done
      if [ "${#filtered[@]}" -ge "$min_matches" ]; then
        echo "${filtered[@]}"
      else
        echo "Bad tile. Skip"
      fi
    else
      echo "Bad tile. Skip"  # Explicit fallback for no matches/filters
    fi
    ;;
  backdrop)
    # Function to process a specific layer (from original Void Cascade script)
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
    room1=$(process_layer 2 "$log_segment")
    room2=$(process_layer 6 "$log_segment")
    room3=$(process_layer 8 "$log_segment")
    echo "$room1 $room2 $room3"
    ;;
  *)
    echo "Unknown map type for $MISSION"
    exit 1
    ;;
esac
