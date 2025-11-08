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

START="ThemedSquadOverlay.lua: Mission name: Apollo (Lua)"
END="Net \\[Info\\]: Replication count by type:"

log_segment=$(tac "$LOGFILE" | awk -v start="$END" -v end="$START" '
  index($0, start) {found_start=1}
  found_start {block = $0 "\n" block}
  index($0, end) && found_start {print block; exit}
')

[[ -z "$log_segment" ]] && { echo "Error: Could not find replication block."; exit 1; }

declare -A sound_paths=(
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntHallsOfJudgement/"]="HallsOfJudgement"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntCloister/"]="Cloister"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntEndurance/"]="Endurance"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntStealth/"]="Stealth"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntPower/"]="Power"
)

matches=()
for path in "${!sound_paths[@]}"; do
  grep -Fq "$path" <<< "$log_segment" && matches+=("${sound_paths[$path]}")
done

if [ "${#matches[@]}" -ge 2 ]; then
  echo "${matches[@]}"
else
  echo "Bad tile. Skip"
fi
