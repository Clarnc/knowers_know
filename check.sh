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
# Capture the loading block between mission name and replication using forward pass, only the last complete block
log_segment=$(awk -v start="$block_start" -v end="$block_end" '
  index($0, start) {
    block = ""
    collecting = 1
    next
  }
  collecting {
    block = block $0 "\n"
  }
  index($0, end) && collecting {
    last_block = block $0 "\n"
    collecting = 0
  }
END {
  if (last_block) print last_block
}' "$LOG_TAIL_FILE")
[[ -z "$log_segment" ]] && { exit 0; }
case "$map_type" in
  sound_match)
    matches=()
    for path in "${!tile_paths[@]}"; do
      # EXACTLY like old working scripts: grep full path on full segment
      if echo "$log_segment" | grep -Fq "$path"; then
        matches+=("${tile_paths[$path]}")
      fi
    done
    # ALWAYS show what tiles were actually detected in terminal
    if [ "${#matches[@]}" -gt 0 ]; then
      echo "Detected tiles for $MISSION: ${matches[*]}" >&2
    else
      echo "No tiles detected for $MISSION" >&2
    fi
    # Rest same as before
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
      if [ "${#filtered[@]}" -gt 2 ]; then
        echo "Bad tile. Skip"
      elif [ "${#filtered[@]}" -ge "$min_matches" ]; then
        echo "${filtered[@]}"
      else
        if [ "$MISSION" == "olympus" ]; then
          echo "Worth checking"
        else
          echo "Bad tile. Skip"
        fi
      fi
    else
      echo "Bad tile. Skip"
    fi
    ;;
  backdrop)
    process_layer() {
      local layer=$1
      local block="$2"
      local backdrops=$(echo "$block" | grep "/Layer255/Layer${layer}/" | grep 'as backdrop')
      local errors=$(echo "$block" | grep "Backdrop for zone: /Layer255/Layer${layer}/")
      local count_backdrop_lines=$(echo "$backdrops" | wc -l)
      local count_errors=$(echo "$errors" | wc -l)
      local backdrop_names=$(echo "$backdrops" | grep -oP '\[\K[^]]+' | grep -vE 'Info|Error')

      # Return numeric code for notification (unchanged logic)
      if echo "$backdrop_names" | grep -q 'IntShuttleBayBackdrop'; then
        echo "5"; return
      elif echo "$backdrop_names" | grep -Eq 'IntParkBBackdrop|IntParkBackdrop'; then
        echo "4"; return
      elif echo "$backdrop_names" | grep -q 'IntLunaroCourtBackdrop'; then
        echo "3L"; return
      elif echo "$backdrop_names" | grep -q 'IntLivingQuartersBackdrop'; then
        echo "3"; return
      fi
      if [ "$count_backdrop_lines" -eq 1 ]; then
        echo "3"; return
      elif [ "$count_backdrop_lines" -eq 5 ]; then
        echo "3x"; return
      elif [ "$count_backdrop_lines" -eq 6 ]; then
        echo "4"; return
      elif [ "$count_backdrop_lines" -eq 9 ]; then
        echo "3Ag"; return
      fi
      if [ "$count_errors" -ge 1 ]; then
        echo "4"; return
      fi
      echo "3"
    }

    # Get numeric codes
    room1_num=$(process_layer 2 "$log_segment")
    room2_num=$(process_layer 6 "$log_segment")
    room3_num=$(process_layer 8 "$log_segment")

    # Human-readable names — FIXED VERSION
    name_for() {
      local code="$1"
      local layer="$2"  # Required for per-layer computation

      # Re-compute per-layer locals
      local backdrops=$(echo "$log_segment" | grep "/Layer255/Layer${layer}/" | grep 'as backdrop')
      local count_backdrop_lines=$(echo "$backdrops" | wc -l)
      local backdrop_names=$(echo "$backdrops" | grep -oP '\[\K[^]]+' | grep -vE 'Info|Error')
      local errors=$(echo "$log_segment" | grep "Backdrop for zone: /Layer255/Layer${layer}/")
      local count_errors=$(echo "$errors" | wc -l)

      case "$code" in
        5) echo "Hangar" ;;
        4)
          if echo "$backdrop_names" | grep -q 'IntParkBBackdrop'; then
            echo "SerenityLevels"
          elif echo "$backdrop_names" | grep -q 'IntParkBackdrop'; then
            echo "AlbrechtPark"
          elif [ "$count_errors" -ge 1 ]; then
            echo "SchoolYard"
          elif [ "$count_backdrop_lines" -eq 6 ]; then
            echo "AngelRoots"
          else
            echo "AngelRoots"  # Fallback only if needed
          fi ;;
        3L) echo "LunaroCourt" ;;
        3)
          if echo "$backdrop_names" | grep -q 'IntLivingQuartersBackdrop'; then
            echo "LivingQuarters"
          elif [ "$count_backdrop_lines" -le 1 ]; then
            echo "HallOfLegems"
          else
            echo "LivingQuarters"
          fi ;;
        3x) echo "Cargo/Amphi/Brig" ;;
        3Ag) echo "AgriZone" ;;
        *) echo "Unknown ($code)" ;;
      esac
    }

    room1_name=$(name_for "$room1_num" 2)
    room2_name=$(name_for "$room2_num" 6)
    room3_name=$(name_for "$room3_num" 8)

    # Terminal output: beautiful names
    echo "Detected rooms for $MISSION: $room1_name | $room2_name | $room3_name  (codes: $room1_num $room2_num $room3_num)" >&2

    # Notification: only numbers (unchanged)
    echo "$room1_num $room2_num $room3_num"
    ;;
esac
