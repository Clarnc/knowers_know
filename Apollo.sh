#!/bin/bash

WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
LOGFILE="${1:-/mnt/c/Users/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  echo "Usage: $0 [path_to_logfile]"
  exit 1
fi

START="Net [Info]: Replication count by concrete type:"
END="Net [Info]: Replication count by type:"

# Reverse the file and extract the last matching block
log_segment=$(tac "$LOGFILE" | awk -v start="$END" -v end="$START" '
  index($0, start) {found_start=1}
  found_start {block = $0 "\n" block}
  index($0, end) && found_start {print block; exit}
')

if [[ -z "$log_segment" ]]; then
  echo "Error: Could not find the Net Replication block."
  exit 1
fi

# Target ambience paths
declare -A sound_paths=(
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntHallsOfJudgement/"]="HallsOfJudgement"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntCloister/"]="Cloister"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntEndurance/"]="Endurance"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntStealth/"]="Stealth"
  ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntPower/"]="Power"
)

matches=()

for path in "${!sound_paths[@]}"; do
  if grep -Fq "$path" <<< "$log_segment"; then
    matches+=("${sound_paths[$path]}")
  fi
done

if [ "${#matches[@]}" -ge 2 ]; then
  echo "${matches[@]}"
else
  echo "Bad tile. Skip"
fi
