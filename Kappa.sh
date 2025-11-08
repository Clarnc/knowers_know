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

block=$(
  tac "$LOGFILE" | awk '
    /Net \[Info\]: Replication count by type:/ {in_block=1; next}
    in_block && /Net \[Info\]: Replication count by concrete type:/ {exit}
    in_block {print}
  ' | tac
)

if [[ -z "$block" ]]; then
  echo "ERROR_NO_BLOCK_FOUND"
  exit 1
fi

if grep -q "/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven" <<< "$block"; then
  echo "✅"
else
  echo "🟥"
fi
