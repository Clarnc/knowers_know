#!/usr/bin/env bash
set -euo pipefail

# start.sh - launcher (WSL + native Linux Proton compatible)
# Put this file in the same folder as the child scripts.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMP_DIR:-/tmp/knowers}"
TAIL_LINES="${TAIL_LINES:-8000}"
# By default pass the full logfile (not a tail) to child scripts for maximum compatibility.
# If you prefer the tail-file behavior set USE_TAIL_CACHE=1 before running.
USE_TAIL_CACHE="${USE_TAIL_CACHE:-0}"
APPID="${APPID:-230410}"  # Warframe AppID (override if needed)
LOG_TAIL_FILE="$TMP_DIR/latest_tail.log"

ICON_TEMP_WIN_DIR="C:\\Temp\\knowers_icons"
ICON_TEMP_UNIX_WSL="/mnt/c/Temp/knowers_icons"
ICON_TEMP_UNIX_NATIVE="$TMP_DIR/knowers_icons"
NOTIFY_PS_PATH_WIN="C:\\Temp\\knowers_notify.ps1"
NOTIFY_PS_PATH_UNIX_WSL="/mnt/c/Temp/knowers_notify.ps1"
NOTIFY_PS_PATH_UNIX_NATIVE="$TMP_DIR/knowers_notify.ps1"

mkdir -p "$TMP_DIR" || true
mkdir -p "$ICON_TEMP_UNIX_NATIVE" || true

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null || false
}

escape_single_for_ps() {
  printf "%s" "$1" | sed "s/'/'\"'\"'/g"
}

ensure_notify_ps() {
  local dest="$1"
  if [ -f "$dest" ]; then return 0; fi
  mkdir -p "$(dirname "$dest")" || true
  cat >"$dest" <<'PS1'
param(
  [string]$title,
  [string]$text,
  [string]$icon
)
try {
  Import-Module BurntToast -ErrorAction Stop
} catch {
  try {
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.MessageBox]::Show($text, $title) | Out-Null
    exit 0
  } catch {
    Write-Host "$title - $text"
    exit 0
  }
}
if ($icon -and (Test-Path $icon)) {
  New-BurntToastNotification -Text $title, $text -AppLogo $icon
} else {
  New-BurntToastNotification -Text $title, $text
}
PS1
  chmod 0644 "$dest" || true
}

send_notification() {
  local title="$1"
  local text="$2"
  local icon_unix="$3"

  if is_wsl; then
    local ps_unix="$NOTIFY_PS_PATH_UNIX_WSL"
    ensure_notify_ps "$ps_unix"
    local icon_win=""
    if [ -n "$icon_unix" ] && [ -f "$icon_unix" ]; then
      mkdir -p "$ICON_TEMP_UNIX_WSL"
      cp -f "$icon_unix" "$ICON_TEMP_UNIX_WSL/" 2>/dev/null || true
      icon_win="${ICON_TEMP_WIN_DIR}\\$(basename "$icon_unix")"
    fi
    local esc_title esc_text
    esc_title=$(escape_single_for_ps "$title")
    esc_text=$(escape_single_for_ps "$text")
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$NOTIFY_PS_PATH_WIN" -title "$esc_title" -text "$esc_text" -icon "$icon_win" >/dev/null 2>&1 || \
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps_unix" -title "$esc_title" -text "$esc_text" -icon "$icon_win" >/dev/null 2>&1 || true
  else
    if command -v notify-send >/dev/null 2>&1; then
      if [ -n "$icon_unix" ] && [ -f "$icon_unix" ]; then
        notify-send "$title" "$text" -i "$icon_unix" || true
      else
        notify-send "$title" "$text" || true
      fi
    else
      echo "[Notification] $title: $text"
    fi
  fi
}

copy_icon_for_env() {
  local unix_icon="$1"
  if [ -z "$unix_icon" ] || [ ! -f "$unix_icon" ]; then
    echo ""
    return
  fi
  if is_wsl; then
    mkdir -p "$ICON_TEMP_UNIX_WSL"
    cp -f "$unix_icon" "$ICON_TEMP_UNIX_WSL/" 2>/dev/null || true
    printf "%s" "${ICON_TEMP_WIN_DIR}\\$(basename "$unix_icon")"
  else
    mkdir -p "$ICON_TEMP_UNIX_NATIVE"
    cp -f "$unix_icon" "$ICON_TEMP_UNIX_NATIVE/" 2>/dev/null || true
    printf "%s" "${ICON_TEMP_UNIX_NATIVE}/$(basename "$unix_icon")"
  fi
}

have_inotifywait() {
  command -v inotifywait >/dev/null 2>&1
}

detect_logfile() {
  # If explicit path provided, prefer it
  if [ "${1:-}" != "" ]; then
    if [ -f "$1" ]; then
      printf "%s" "$1"; return 0
    fi
  fi

  if is_wsl; then
    local win_user
    win_user=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' || true)
    win_user=$(printf "%s" "$win_user" | sed 's#C:\\#c/#;s#\\#/#g')
    local candidate="/mnt/${win_user}/AppData/Local/Warframe/EE.log"
    if [ -f "$candidate" ]; then printf "%s" "$candidate"; return 0; fi
  fi

  local compat_base="$HOME/.local/share/Steam/steamapps/compatdata"
  local candidate="$compat_base/${APPID}/pfx/drive_c/users/steamuser/AppData/Local/Warframe/EE.log"
  if [ -f "$candidate" ]; then printf "%s" "$candidate"; return 0; fi

  local compat_base2="$HOME/.steam/steam/steamapps/compatdata"
  candidate="$compat_base2/${APPID}/pfx/drive_c/users/steamuser/AppData/Local/Warframe/EE.log"
  if [ -f "$candidate" ]; then printf "%s" "$candidate"; return 0; fi

  if [ -d "$HOME/.local/share/Steam/steamapps/compatdata" ]; then
    local found
    found=$(find "$HOME/.local/share/Steam/steamapps/compatdata" -maxdepth 4 -type f -iname 'EE.log' -path "*/pfx/*/AppData/*/Warframe/*" 2>/dev/null | head -n1 || true)
    if [ -n "$found" ]; then printf "%s" "$found"; return 0; fi
  fi

  return 1
}

update_tail_cache() {
  if [ -z "${LOGFILE:-}" ] || [ ! -f "$LOGFILE" ]; then return 1; fi
  tail -n "$TAIL_LINES" "$LOGFILE" > "$LOG_TAIL_FILE" 2>/dev/null || cp -f "$LOGFILE" "$LOG_TAIL_FILE" 2>/dev/null || true
}

run_check_script() {
  local script="$1"
  local arg_path="$LOGFILE"
  if [ "${USE_TAIL_CACHE:-0}" -eq 1 ] && [ -f "$LOG_TAIL_FILE" ]; then arg_path="$LOG_TAIL_FILE"; fi
  "$script" "$arg_path" 2>/dev/null || true
}

# Precompute LOGFILE (optional first arg override)
ARG_LOGFILE="${1:-}"
if [ -n "$ARG_LOGFILE" ] && [ -f "$ARG_LOGFILE" ]; then
  LOGFILE="$ARG_LOGFILE"
else
  if logfile_path="$(detect_logfile "$ARG_LOGFILE" 2>/dev/null)"; then
    LOGFILE="$logfile_path"
  else
    LOGFILE="${ARG_LOGFILE:-}"
  fi
fi

if is_wsl; then
  mkdir -p "/mnt/c/Temp" 2>/dev/null || true
  ensure_notify_ps "$NOTIFY_PS_PATH_UNIX_WSL"
else
  ensure_notify_ps "$NOTIFY_PS_PATH_UNIX_NATIVE"
fi

cd "$SCRIPT_DIR" || exit 1

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
    1)
      SCRIPT="./gascade_secrets.sh"
      TITLE="Tuvul Commons"
      ICON_PATH="Icons/Tuvul_Commons_icon.png"
      ;;
    2)
      SCRIPT="./Apollo.sh"
      TITLE="Apollo"
      ICON_PATH="Icons/Apollo_icon.png"
      ;;
    3)
      SCRIPT="./Kappa.sh"
      TITLE="Kappa"
      ICON_PATH="Icons/Kappa_icon.png"
      ;;
    4)
      SCRIPT="./Armatus.sh"
      TITLE="Armatus"
      ICON_PATH="Icons/Armatus_icon.png"
      ;;
    5)
      SCRIPT="./Laomedeia.sh"
      TITLE="Laomedeia"
      ICON_PATH="Icons/Laomedeia_icon.png"
      ;;
    q|Q)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Press Enter to try again."
      read -r
      continue
      ;;
  esac

  if [ ! -x "$SCRIPT" ] && [ ! -f "$SCRIPT" ]; then
    echo "Script $SCRIPT not found or not executable. Press Enter to return."
    read -r
    continue
  fi

  ICON_FULL_UNIX="$SCRIPT_DIR/$ICON_PATH"
  if [ ! -f "$ICON_FULL_UNIX" ]; then
    ICON_UNIX_PATH=""
  else
    ICON_UNIX_PATH=$(copy_icon_for_env "$ICON_FULL_UNIX")
  fi

  if [ -z "${LOGFILE:-}" ] || [ ! -f "$LOGFILE" ]; then
    if logfile_path="$(detect_logfile 2>/dev/null || true)"; then
      LOGFILE="$logfile_path"
    else
      echo "Log file not found automatically."
      read -rp "Enter full path to EE.log (or press Enter to cancel): " user_log
      if [ -z "$user_log" ] || [ ! -f "$user_log" ]; then
        echo "No valid log provided. Returning to menu. Press Enter."
        read -r
        continue
      fi
      LOGFILE="$user_log"
    fi
  fi

  if [ "${USE_TAIL_CACHE:-0}" -eq 1 ]; then update_tail_cache || true; fi
  prev_output=""

  echo "Starting $TITLE check. Press 'q' then Enter to return to menu."

  if have_inotifywait; then
    while true; do
      output="$(run_check_script "$SCRIPT")"
      if [ "$output" != "$prev_output" ]; then
        prev_output="$output"
        send_notification "$TITLE" "$output" "$ICON_UNIX_PATH"
      fi

      if inotifywait -qq -t 1 -e modify "$LOGFILE" >/dev/null 2>&1; then
        if [ "${USE_TAIL_CACHE:-0}" -eq 1 ]; then update_tail_cache || true; fi
        output="$(run_check_script "$SCRIPT")"
        if [ "$output" != "$prev_output" ]; then
          prev_output="$output"
          send_notification "$TITLE" "$output" "$ICON_UNIX_PATH"
        fi
      fi

      read -t 0.01 -n 1 key || true
      if [[ "$key" == "q" || "$key" == "Q" ]]; then
        echo -e "\nReturning to menu..."
        break
      fi
    done
  else
    last_size=0
    last_inode=0
    while true; do
      output="$(run_check_script "$SCRIPT")"
      if [ "$output" != "$prev_output" ]; then
        prev_output="$output"
        send_notification "$TITLE" "$output" "$ICON_UNIX_PATH"
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
          if [ "${USE_TAIL_CACHE:-0}" -eq 1 ]; then update_tail_cache || true; fi
          last_size=$cur_size
          last_inode=$cur_inode
        fi
      fi
    done
  fi
done
