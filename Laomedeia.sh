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

START="ThemedSquadOverlay.lua: Mission name: Laomedeia (Neptune)"
END="Net \\[Info\\]: Replication count by type:"

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
