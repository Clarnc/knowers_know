#!/bin/bash

# Detect Windows user folder
WIN_USER=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' | sed 's#C:\\#c/#;s#\\#/#g')
LOGFILE="${1:-/mnt/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  echo "Usage: $0 [path_to_logfile]"
  exit 1
fi

# Start/end markers for replication section
START="ThemedSquadOverlay.lua: Mission name: Laomedeia (Neptune)"
END="Net [Info]: Replication count by type:"

# Extract the latest replication block
log_segment=$(tac "$LOGFILE" | awk -v start="$END" -v end="$START" '
  index($0, start) {found_start=1}
  found_start {block = $0 "\n" block}
  index($0, end) && found_start {print block; exit}
')

if [[ -z "$log_segment" ]]; then
  echo "Error: Could not find the Net Replication block."
  exit 1
fi

# Corpus Ship Remaster tile paths
declare -A tile_paths=(
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntWarehouseTwo/CrpShipVoidPortalSeq"]="Portals"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntGunBattery/CrpShipGunBatteryVoidThunderClapsSeq"]="GunBattery"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntHangarOne/CrpShipDataPillarLoopASeq"]="Hangar"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntReactorOne/CrpShipSpinningReactorChargeSeq"]="Reactor"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntSpacecraftRepairBayOne/CrpShipTrainDroneLoopSeq"]="RepairBay"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/ObjSabotageCore/CrpShipSabotageCoreSpinningPillarLoopSeq"]="SabotageCore"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/Gameplay/CrpShipTemplePyramidRevealSeq"]="Pyramid"
  #["/Lotus/Sounds/Ambience/CorpusShipRemaster/CapSmallShowroom/CrpShipShowroomShipArriveBSeq"]="GoldHand"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntLarge VentRoomOne/CrpShipFanLargeLoopSeq"]="VentRoom"
  ["A valid backdrop ID was specified: VenusLowOrbit however no such backdrop zone was found!"]="Bridge"

)

matches=()

# Search the replication block for matches
for path in "${!tile_paths[@]}"; do
  if grep -Fq "$path" <<< "$log_segment"; then
    matches+=("${tile_paths[$path]}")
  fi
done

# Only these tiles are allowed
allowed=("GunBattery" "Portals" "SabotageCore" "Bridge" "GoldHand")

filtered=()
for match in "${matches[@]}"; do
  if [[ " ${allowed[*]} " =~ " ${match} " ]]; then
    filtered+=("$match")
  fi
done

# Only show if 2 or more valid tiles detected
if [ "${#filtered[@]}" -ge 2 ]; then
  echo "${filtered[@]}"
else
  echo "Bad tile. Skip"
fi
