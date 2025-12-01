#!/bin/bash
set -euo pipefail

# -------------------------
# Detect platform
# -------------------------
IS_WSL=0
if grep -qEi "(Microsoft|WSL)" /proc/sys/kernel/osrelease 2>/dev/null; then
  IS_WSL=1
fi

# -------------------------
# Config / constants
# -------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="/tmp/knowers"
TAIL_LINES=8000
LOG_TAIL_FILE="$TMP_DIR/latest_tail.log"

if [ $IS_WSL -eq 1 ]; then
  # Windows via WSL: Use %LOCALAPPDATA%\Temp
  WIN_LOCAL_TEMP_RAW=$(cmd.exe /c "echo %LOCALAPPDATA%\\Temp" 2>/dev/null | tr -d '\r')
  WIN_TEMP_DIR=$(printf "%s" "$WIN_LOCAL_TEMP_RAW" | sed 's#\\#/#g')
  ICON_TEMP_WIN_DIR="$(printf "%s" "$WIN_LOCAL_TEMP_RAW" | sed 's#\\#\\\\#g')\\knowers_icons"
  ICON_TEMP_UNIX_DIR="/mnt/c${WIN_TEMP_DIR#C:}/knowers_icons"
  NOTIFY_PS_PATH_WIN="$(printf "%s" "$WIN_LOCAL_TEMP_RAW" | sed 's#\\#\\\\#g')\\knowers_notify.ps1"
  NOTIFY_PS_PATH_UNIX="/mnt/c${WIN_TEMP_DIR#C:}/knowers_notify.ps1"
  WIN_USER_RAW=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
  WIN_USER_UNIX=$(printf "%s" "$WIN_USER_RAW" | sed 's#C:\\#c/#;s#\\#/#g')
  LOGFILE_DEFAULT="/mnt/$WIN_USER_UNIX/AppData/Local/Warframe/EE.log"
else
  # Native Linux: Use /tmp for icons, assume Steam Proton path for Warframe
  ICON_TEMP_UNIX_DIR="/tmp/knowers_icons"
  LOGFILE_DEFAULT="$HOME/.local/share/Steam/steamapps/compatdata/230410/pfx/drive_c/users/steamuser/AppData/Local/Warframe/EE.log"
fi

mkdir -p "$TMP_DIR" "$ICON_TEMP_UNIX_DIR" || true

# -------------------------
# Helpers
# -------------------------
escape_single_for_ps() {
  printf "%s" "$1" | sed "s/'/'\"'\"'/g"
}

ensure_notify_ps() {
  if [ ! -f "$NOTIFY_PS_PATH_UNIX" ]; then
    cat > "$NOTIFY_PS_PATH_UNIX" <<'PS1'
param(
  [string]$title,
  [string]$text,
  [string]$icon
)
try {
  Import-Module BurntToast -ErrorAction Stop
} catch {
  try {
    [System.Windows.MessageBox]::Show("$text","$title") | Out-Null
    exit 0
  } catch { exit 0 }
}
if ($icon -and (Test-Path $icon)) {
  New-BurntToastNotification -Text $title,$text -AppLogo $icon
} else {
  New-BurntToastNotification -Text $title,$text
}
PS1
  fi
}

send_notification() {
  local title="$1"
  local text="$2"
  local icon_path="$3"  # This is WIN_ICON_PATH on WSL, UNIX on Linux

  if [ $IS_WSL -eq 1 ]; then
    local esc_title esc_text
    esc_title=$(escape_single_for_ps "$title")
    esc_text=$(escape_single_for_ps "$text")
    ensure_notify_ps
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$NOTIFY_PS_PATH_WIN" \
      -title "$esc_title" -text "$esc_text" -icon "$icon_path" >/dev/null 2>&1 || true
  else
    # Native Linux: Use notify-send
    if command -v notify-send >/dev/null 2>&1; then
      notify-send -i "$icon_path" "$title" "$text" || true
    else
      echo "Notification: $title - $text"  # Fallback to console if no notify-send
    fi
  fi
}

copy_icon_to_win_temp() {
  local unix_icon="$1"
  local basename="$2"
  local dest_unix="$ICON_TEMP_UNIX_DIR/$basename"
  mkdir -p "$ICON_TEMP_UNIX_DIR" || true
  cp -f "$unix_icon" "$dest_unix" || true
  echo "${ICON_TEMP_WIN_DIR}\\${basename}"
}

update_tail_cache() {
  tail -n "$TAIL_LINES" "$LOGFILE" > "$LOG_TAIL_FILE" 2>/dev/null || true
}
run_check_script() {
  local mission="$1"
  ./check.sh "$LOG_TAIL_FILE" "$mission" 2>&1 || echo "Bad tile. Skip"
}
get_current_mission() {
  local log="$1"
  # Get the latest mission indicator line using forward pass
  indicator_line=$(awk '/ThemedSquadOverlay.lua: Mission name:|missionType=MT_VOID_CASCADE/ { last = $0 } END {print last}' "$log")
  if [[ "$indicator_line" =~ "missionType=MT_VOID_CASCADE" ]]; then
    echo "tuvul_commons"
  elif [[ "$indicator_line" =~ "ThemedSquadOverlay.lua: Mission name:" ]]; then
    # Extract just the base mission name, ignoring suffixes like " - THE STEEL PATH"
    full_name=$(echo "$indicator_line" | sed 's/.*Mission name: \([^ ]* ([^)]*)\).*/\1/')
    case "$full_name" in
      "Tuvul Commons (Zariman)") echo "tuvul_commons" ;;
      "Apollo (Lua)") echo "apollo" ;;
      "Kappa (Sedna)") echo "kappa" ;;
      "Armatus (Deimos)") echo "armatus" ;;
      "Laomedeia (Neptune)") echo "laomedeia" ;;
      "Ur (Uranus)") echo "ur";;
      "Olympus (Mars)")echo "olympus";;
      "Tamu (Kuva Fortress)")echo "tamu";;
      "Ganymede (Jupiter)")echo "ganymede";;
      *) echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}
# -------------------------
# Setup / defaults
# -------------------------
if [ $IS_WSL -eq 1 ]; then
  ensure_notify_ps
fi
cd "$SCRIPT_DIR" || exit 1

LOGFILE="${1:-$LOGFILE_DEFAULT}"
if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  exit 1
fi

# -------------------------
# Main monitoring loop (automated, no menu)
# -------------------------
echo "Monitoring Warframe log for supported missions... (Ctrl-C to quit)"

prev_mission=""
prev_output=""
prev_sent_output=""
last_size=0
last_inode=0
MISSION=""
TITLE=""
ICON_PATH_TO_USE=""
counter=0
prev_tiles=()
prev_rooms=()

update_tail_cache

while true; do
  current_mission=$(get_current_mission "$LOG_TAIL_FILE")

  if [ "$current_mission" != "$prev_mission" ] && [ "$current_mission" != "unknown" ]; then
    prev_mission="$current_mission"
    prev_output=""  # Reset output on mission change
    prev_sent_output=""
    prev_tiles=()   # Reset previous tiles on mission change
    prev_rooms=()   # Reset previous rooms on mission change

    case "$current_mission" in
      tuvul_commons) TITLE="Tuvul Commons"; ICON_PATH="Icons/Tuvul_Commons_icon.png";;
      apollo) TITLE="Apollo"; ICON_PATH="Icons/Apollo_icon.png";;
      kappa) TITLE="Kappa"; ICON_PATH="Icons/Kappa_icon.png";;
      armatus) TITLE="Armatus"; ICON_PATH="Icons/Armatus_icon.png";;
      laomedeia) TITLE="Laomedeia"; ICON_PATH="Icons/Laomedeia_icon.png";;
      ur) TITLE="Ur"; ICON_PATH="Icons/Ur_icon.png";;
      olympus) TITLE="Olympus"; ICON_PATH="Icons/Olympus_icon.png";;
      tamu) TITLE="Tamu"; ICON_PATH="Icons/Tamu_icon.png";
      ganymde) TITLE="Ganymede"; ICON_PATH="Icons/Ganymede_icon.png";;
    esac

    echo "Detected new mission: $TITLE"

    ICON_FULL_UNIX="$SCRIPT_DIR/$ICON_PATH"
    if [ ! -f "$ICON_FULL_UNIX" ]; then
      echo "Icon not found at $ICON_FULL_UNIX. Continuing without icon."
      ICON_PATH_TO_USE=""
    else
      ICON_BASENAME="$(basename "$ICON_FULL_UNIX")"
      if [ $IS_WSL -eq 1 ]; then
        ICON_PATH_TO_USE=$(copy_icon_to_win_temp "$ICON_FULL_UNIX" "$ICON_BASENAME")
      else
        ICON_PATH_TO_USE="$ICON_FULL_UNIX"  # On Linux, use direct path
      fi
    fi
  fi

  if [ "$current_mission" != "unknown" ]; then
    full_output=$(run_check_script "$current_mission")
    if [ "$full_output" != "$prev_output" ]; then
      counter=$((counter + 1))
      # Prefix each line with [nnn]:
      while IFS= read -r line; do
        printf "[%03d]: %s\n" "$counter" "$line"
      done <<< "$full_output"

      # Reset prev_tiles/prev_rooms if no detection or error
      no_tiles_line=$(echo "$full_output" | grep "No tiles detected" || true)
      error_line=$(echo "$full_output" | grep "Error:" || true)
      if [ -n "$no_tiles_line" ] || [ -n "$error_line" ]; then
        prev_tiles=()
      fi
      no_rooms_line=$(echo "$full_output" | grep "No rooms detected" || true)  # If backdrop has this, but currently not
      if [ -n "$no_rooms_line" ] || [ -n "$error_line" ]; then
        prev_rooms=()
      fi

      # Extract tiles from full_output for duplicate check (sound_match missions)
      detected_line=$(echo "$full_output" | grep "Detected tiles" || true)
      if [ -n "$detected_line" ]; then
        current_tiles=($(echo "$detected_line" | sed 's/Detected tiles for .*://'))
        for tile in "${current_tiles[@]}"; do
          if [[ " ${prev_tiles[*]} " =~ " ${tile} " ]]; then
            printf "[%03d]: Duplicate tile from previous block: %s\n" "$counter" "$tile"
          fi
        done
        prev_tiles=("${current_tiles[@]}")
      fi

      # Extract rooms from full_output for duplicate check (backdrop missions)
      detected_rooms=$(echo "$full_output" | grep "Detected rooms" || true)
      if [ -n "$detected_rooms" ]; then
        current_rooms=$(echo "$detected_rooms" | sed 's/Detected rooms for .*://' | sed 's/ (codes: .*//')
        # Assuming rooms are separated by | 
        IFS='|' read -r -a current_rooms_array <<< "$current_rooms"
        for room in "${current_rooms_array[@]}"; do
          room=$(echo "$room" | xargs)  # Trim spaces
          if [[ " ${prev_rooms[*]} " =~ " ${room} " ]]; then
            printf "[%03d]: Duplicate room from previous block: %s\n" "$counter" "$room"
          fi
        done
        prev_rooms=("${current_rooms_array[@]}")
      fi

      prev_output="$full_output"
      output=$(echo "$full_output" | grep -v "Detected tiles" | grep -v "No tiles detected" | grep -v "Detected rooms" | tail -n 1)
      if [[ "$output" != "Bad tile. Skip" ]] && [[ "$output" != *"Error:"* ]] && [ "$output" != "$prev_sent_output" ] && [ -n "$output" ]; then
        send_notification "$TITLE" "$output" "$ICON_PATH_TO_USE"
        prev_sent_output="$output"
      fi
    fi
  fi

  if [ -f "$LOGFILE" ]; then
    cur_size=$(stat -c%s "$LOGFILE" 2>/dev/null || echo 0)
    cur_inode=$(stat -c%i "$LOGFILE" 2>/dev/null || echo 0)
    if (( cur_size > last_size )) || [ "$cur_inode" != "$last_inode" ]; then
      update_tail_cache
      last_size=$cur_size
      last_inode=$cur_inode
    fi
  fi

  sleep 1
done
