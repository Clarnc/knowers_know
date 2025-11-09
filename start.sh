#!/bin/bash
set -euo pipefail

# -------------------------
# Config / constants
# -------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="/tmp/knowers"
TAIL_LINES=8000
ICON_TEMP_WIN_DIR="C:\\Temp\\knowers_icons"
ICON_TEMP_UNIX_DIR="/mnt/c/Temp/knowers_icons"
NOTIFY_PS_PATH_WIN="C:\\Temp\\knowers_notify.ps1"
NOTIFY_PS_PATH_UNIX="/mnt/c/Temp/knowers_notify.ps1"
LOG_TAIL_FILE="$TMP_DIR/latest_tail.log"

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
  local win_icon="$3"

  local esc_title esc_text
  esc_title=$(escape_single_for_ps "$title")
  esc_text=$(escape_single_for_ps "$text")

  ensure_notify_ps
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$NOTIFY_PS_PATH_WIN" \
    -title "$esc_title" -text "$esc_text" -icon "$win_icon" >/dev/null 2>&1 || true
}

copy_icon_to_win_temp() {
  local unix_icon="$1"
  local basename="$2"
  local dest_unix="$ICON_TEMP_UNIX_DIR/$basename"
  mkdir -p "$ICON_TEMP_UNIX_DIR"
  cp -f "$unix_icon" "$dest_unix" || true
  echo "${ICON_TEMP_WIN_DIR}\\${basename}"
}

update_tail_cache() {
  tail -n "$TAIL_LINES" "$LOGFILE" > "$LOG_TAIL_FILE"
}

run_check_script() {
  local script="$1"
  "$script" "$LOG_TAIL_FILE" 2>/dev/null || true
}

# -------------------------
# Setup / defaults
# -------------------------
WIN_USER_RAW=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
WIN_USER_UNIX=$(printf "%s" "$WIN_USER_RAW" | sed 's#C:\\#c/#;s#\\#/#g')
LOGFILE_DEFAULT="/mnt/$WIN_USER_UNIX/AppData/Local/Warframe/EE.log"

mkdir -p "/mnt/c/Temp"
ensure_notify_ps

cd "$SCRIPT_DIR" || exit 1

# -------------------------
# Main interactive loop
# -------------------------
while true; do
  clear
  cat <<'MENU'
Choose option:
[1] Tuvul Commons (Void Cascade)
[2] Apollo (Disruption)
[3] Kappa (Disruption)
[4] Armatus (Disruption)
[5] Laomedeia (Disruption)
[q] Quit
MENU

  read -rp "Enter choice [1-5, q]: " choice

  case "$choice" in
    1) SCRIPT="./Tuvul_Commons.sh"; TITLE="Tuvul Commons"; ICON_PATH="Icons/Tuvul_Commons_icon.png";;
    2) SCRIPT="./Apollo.sh"; TITLE="Apollo"; ICON_PATH="Icons/Apollo_icon.png";;
    3) SCRIPT="./Kappa.sh"; TITLE="Kappa"; ICON_PATH="Icons/Kappa_icon.png";;
    4) SCRIPT="./Armatus.sh"; TITLE="Armatus"; ICON_PATH="Icons/Armatus_icon.png";;
    5) SCRIPT="./Laomedeia.sh"; TITLE="Laomedeia"; ICON_PATH="Icons/Laomedeia_icon.png";;
    q|Q) echo "Exiting."; exit 0;;
    *) echo "Invalid choice. Press Enter to try again."; read -r; continue;;
  esac

  if [ ! -x "$SCRIPT" ] && [ ! -f "$SCRIPT" ]; then
    echo "Script $SCRIPT not found or not executable."
    read -r -p "Press Enter to return to menu."
    continue
  fi

  ICON_FULL_UNIX="$SCRIPT_DIR/$ICON_PATH"
  if [ ! -f "$ICON_FULL_UNIX" ]; then
    echo "Icon not found at $ICON_FULL_UNIX. Continuing without icon."
    WIN_ICON_PATH=""
  else
    ICON_BASENAME="$(basename "$ICON_FULL_UNIX")"
    WIN_ICON_PATH=$(copy_icon_to_win_temp "$ICON_FULL_UNIX" "$ICON_BASENAME")
  fi

  LOGFILE="${1:-$LOGFILE_DEFAULT}"
  if [ ! -f "$LOGFILE" ]; then
    echo "Log file not found at $LOGFILE"
    read -r -p "Press Enter to return to menu."
    continue
  fi

  update_tail_cache
  prev_output=""
  last_size=0
  last_inode=0

  echo "Starting $TITLE check. Press 'q' then Enter to return to menu."

  while true; do
    output="$(run_check_script "$SCRIPT")"
    if [ "$output" != "$prev_output" ]; then
      prev_output="$output"
      send_notification "$TITLE" "$output" "$WIN_ICON_PATH"
    fi

    read -t 1 -n 1 key || true
    if [[ "$key" == "q" || "$key" == "Q" ]]; then
      echo -e "\nReturning to menu..."
      break
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
  done
done
