#!/bin/bash
WIN_USER=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' | sed 's#C:\\#c/#;s#\\#/#g')
LOGFILE="${1:-/mnt/$WIN_USER/AppData/Local/Warframe/EE.log}"

if [ ! -f "$LOGFILE" ]; then
  echo "Log file not found at $LOGFILE"
  exit 1
fi

START="ThemedSquadOverlay.lua: Mission name: Laomedeia (Neptune)"
END="Net \[Info\]: Replication count by type:"

log_segment=$(tac "$LOGFILE" | awk -v start="$END" -v end="$START" '
  index($0, start) {found_start=1}
  found_start {block = $0 "\n" block}
  index($0, end) && found_start {print block; exit}
')

[[ -z "$log_segment" ]] && { echo "Error: Could not find replication block."; exit 1; }

declare -A tile_paths=(
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntWarehouseTwo/CrpShipVoidPortalSeq"]="Portals"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntGunBattery/CrpShipGunBatteryVoidThunderClapsSeq"]="GunBattery"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntHangarOne/CrpShipDataPillarLoopASeq"]="Hangar"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntReactorOne/CrpShipSpinningReactorChargeSeq"]="Reactor"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntSpacecraftRepairBayOne/CrpShipTrainDroneLoopSeq"]="RepairBay"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/ObjSabotageCore/CrpShipSabotageCoreSpinningPillarLoopSeq"]="SabotageCore"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/Gameplay/CrpShipTemplePyramidRevealSeq"]="Pyramid"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/CapSmallShowroom/CrpShipShowroomShipArriveBSeq"]="GoldHand"
  ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntLarge VentRoomOne/CrpShipFanLargeLoopSeq"]="VentRoom"
  ["A valid backdrop ID was specified: VenusLowOrbit however no such backdrop zone was found!"]="Bridge"
)

matches=()
for path in "${!tile_paths[@]}"; do
  grep -Fq "$path" <<< "$log_segment" && matches+=("${tile_paths[$path]}")
done

allowed=("GunBattery" "Portals" "SabotageCore" "Bridge" "GoldHand")

filtered=()
for match in "${matches[@]}"; do
  [[ " ${allowed[*]} " =~ " ${match} " ]] && filtered+=("$match")
done

if [ "${#filtered[@]}" -ge 2 ]; then
  echo "${filtered[@]}"
else
  echo "Bad tile. Skip"
fi
