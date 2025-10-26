#!/bin/bash

# Detect Windows user folder
WIN_USER=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' | sed 's#C:\\#c/#;s#\\#/#g')
LOGFILE="${1:-/mnt/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  echo "Usage: $0 [path_to_logfile]"
  exit 1
fi

# Start/end markers for log block
START="ThemedSquadOverlay.lua: Mission name: Armatus (Deimos)
END="Net \[Info\]: Replication count by type:"

# Extract the last matching block
log_segment=$(tac "$LOGFILE" | awk -v start="$END" -v end="$START" '
  index($0, start) {found_start=1}
  found_start {block = $0 "\n" block}
  index($0, end) && found_start {print block; exit}
')

if [[ -z "$log_segment" ]]; then
  echo "Error: Could not find the Net Replication block."
  exit 1
fi

# Entrati Lab sound markers
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

# Search the replication block
for path in "${!tile_paths[@]}"; do
  if grep -Fq "$path" <<< "$log_segment"; then
    matches+=("${tile_paths[$path]}")
  fi
done

# If Terrarium or Piston found → skip
if [[ " ${matches[*]} " =~ " Terrarium " ]] || [[ " ${matches[*]} " =~ " Piston " ]] || [[ " ${matches[*]} " =~ " TorsoB " ]] || [[ " ${matches[*]} " =~ " Sphere " ]] ; then
  echo "Bad tile. Skip"
  exit 0
fi

# Normal output
if [ "${#matches[@]}" -ge 1 ]; then
  echo "${matches[@]}"
else
  echo "Bad tile. Skip"
fi
