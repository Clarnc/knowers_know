#!/usr/bin/env bash
set -euo pipefail

detect_logfile() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    local win_user
    win_user=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' || true)
    win_user=$(printf "%s" "$win_user" | sed 's#C:\\#c/#;s#\\#/#g')
    printf "%s" "/mnt/${win_user}/AppData/Local/Warframe/EE.log"
    return 0
  fi
  local compat_base="$HOME/.local/share/Steam/steamapps/compatdata"
  local candidate="$compat_base/230410/pfx/drive_c/users/steamuser/AppData/Local/Warframe/EE.log"
  [ -f "$candidate" ] && { printf "%s" "$candidate"; return 0; }
  find "$HOME/.local/share/Steam/steamapps/compatdata" -maxdepth 4 -type f -iname 'EE.log' -path "*/pfx/*/AppData/*/Warframe/*" 2>/dev/null | head -n1
}

LOGFILE="${1:-$(detect_logfile)}"

if [ -z "$LOGFILE" ] || [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at ${LOGFILE:-<none>}"
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

process_layer() {
  local layer=$1
  local block="$2"

  local backdrops=$(echo "$block" | grep "/Layer255/Layer${layer}/" | grep 'as backdrop' || true)
  local errors=$(echo "$block" | grep "Backdrop for zone: /Layer255/Layer${layer}/" || true)
  local count_backdrop_lines=$(printf "%s" "$backdrops" | wc -l)
  local count_errors=$(printf "%s" "$errors" | wc -l)
  local backdrop_names=$(printf "%s" "$backdrops" | grep -oP '\[\K[^]]+' | grep -vE 'Info|Error' || true)

  if echo "$backdrop_names" | grep -q 'IntShuttleBayBackdrop'; then
    echo "5"; return
  elif echo "$backdrop_names" | grep -Eq 'IntParkBBackdrop|IntParkBackdrop'; then
    echo "4"; return
  elif echo "$backdrop_names" | grep -Eq 'IntLunaroCourtBackdrop'; then
    echo "3L"; return
  elif echo "$backdrop_names" | grep -Eq 'IntLivingQuartersBackdrop'; then
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

check_between_layers() {
  local block="$1"
  local -a targets=(
    "Conshort01BD"
    "ConCornerShort03Backdrop"
    "ConNSClsRmLocal"
    "LocalSkyBox"
    "ConNSJunctShort01"
    "ConNSStrghtSht05Bkdrop"
  )
  local -A found
  for t in "${targets[@]}"; do found["$t"]=0; done
  for layer in {3..5} 7; do
    layer_data=$(echo "$block" | grep "/Layer255/Layer${layer}/" | grep 'as backdrop' || true)
    for target in "${targets[@]}"; do
      if echo "$layer_data" | grep -q "$target"; then found["$target"]=1; fi
    done
  done
  total_found=0
  for v in "${found[@]}"; do (( total_found += v )); done
  if [ "$total_found" -eq "${#targets[@]}" ]; then
    echo "godly"
  elif [ "$total_found" -gt 0 ]; then
    echo "mid"
  else
    echo "unknown"
  fi
}

room1=$(process_layer 2 "$log_segment")
room2=$(process_layer 6 "$log_segment")
room3=$(process_layer 8 "$log_segment")
status=$(check_between_layers "$log_segment")
echo "$room1 $room2 $room3 $status"
