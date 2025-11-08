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

START="ThemedSquadOverlay.lua: Mission name: Armatus (Deimos)"
END="Net [Info]: Replication count by type:"

log_segment=$(tac "$LOGFILE" | awk -v start="$END" -v end="$START" '
  index($0, start) {found_start=1}
  found_start {block = $0 "\n" block}
  index($0, end) && found_start {print block; exit}
')

[[ -z "$log_segment" ]] && { echo "Error: Could not find replication block."; exit 1; }

declare -A tile_paths=(
  ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiIntEchoesSpawnMachineElectricityZapASeq"]="Circle"
  ["/Lotus/Sounds/Ambience/Entrati/Props/EntratiDanteUnboundPistonMachineSeq"]="Piston"
  ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiGlassSphereVoidShakeSeq"]="Sphere"
  ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiTrainPassbySeq"]="Train"
  ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiPortcullisDoorOpenSeq"]="TorsoA"
  ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiIntAtriumWindBlastSeq"]="Mirror"
  ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiConJunctionServiceDoorCloseSeq"]="TorsoB"
  ["/Lotus/Levels/EntratiLab/IntTerrarium/Scope"]="Terrarium"
)

matches=()
for path in "${!tile_paths[@]}"; do
  grep -Fq "$path" <<< "$log_segment" && matches+=("${tile_paths[$path]}")
done

# Skip unwanted tiles
if [[ " ${matches[*]} " =~ " Terrarium " ]] || [[ " ${matches[*]} " =~ " Piston " ]] || [[ " ${matches[*]} " =~ " TorsoB " ]] || [[ " ${matches[*]} " =~ " Sphere " ]]; then
  echo "Bad tile. Skip"
  exit 0
fi

if [ "${#matches[@]}" -ge 1 ]; then
  echo "${matches[@]}"
else
  echo "Bad tile. Skip"
fi
