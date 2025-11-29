#!/bin/bash
# maps_data.sh - Data for each mission/map
# Sourced by check.sh
get_map_data() {
  local mission="$1"
  unset tile_paths bad_tiles allowed_tiles min_matches
  case "$mission" in
    tuvul_commons)
      map_type="backdrop"
      block_start="missionType=MT_VOID_CASCADE"
      block_end="CreateState: CS_FIND_LEVEL_INFO"
      ;;
    apollo)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Apollo (Lua)"
      block_end="Net [Info]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntHallsOfJudgement/"]="HallsOfJudgement"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntCloister/"]="Cloister"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntEndurance/"]="Endurance"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntStealth/"]="Stealth"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntPower/"]="Power"
      )
      bad_tiles=("Cloister" "Stealth")
      allowed_tiles=("Power" "HallsOfJudgement" "Endurance")
      min_matches=2
      ;;
    armatus)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Armatus (Deimos)"
      block_end="Net [Info]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiIntEchoesSpawnMachineElectricityZap"]="Circle"
        ["/Lotus/Sounds/Ambience/Entrati/Props/EntratiDanteUnboundPistonMachine"]="Piston"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiGlassSphereVoidShake"]="Sphere"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiTrainPassby"]="Train"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiPortcullisDoorOpen"]="TorsoA"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiIntAtriumWindBlast"]="Mirror"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiConJunctionServiceDoorClose"]="TorsoB"
        ["/Lotus/Levels/EntratiLab/IntTerrarium/Scope"]="Terrarium"
      )
      bad_tiles=("Terrarium" "Piston" "TorsoB" "Sphere")
      min_matches=1
      ;;
    kappa)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Kappa (Sedna)"
      block_end="Net [Info]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven"]="GrnIntermediateSeven"
      )
      allowed_tiles=("GrnIntermediateSeven")
      min_matches=1
      ;;
    ur)
     map_type="sound_match"
     block_start="ThemedSquadOverlay.lua: Mission name: Ur (Uranus)"
     block_end="Net [Info]: Replication count by type:"
     declare -gA tile_paths=(
	["/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven"]="GrnIntermediateSeven"
    )
    allowed_tiles=("GrnIntermediateSeven")
    min_matches=1
    ;;
    laomedeia)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Laomedeia (Neptune)"
      block_end="Net [Info]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntWarehouseTwo/CrpShipVoidPortal"]="Portals"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntGunBattery/CrpShipGunBatteryVoidThunderClaps"]="GunBattery"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntHangarOne/CrpShipDataPillarLoop"]="Hangar"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntReactorOne/CrpShipSpinningReactorCharge"]="Reactor"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntSpacecraftRepairBayOne/CrpShipTrainDroneLoop"]="RepairBay"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/ObjSabotageCore/CrpShipSabotageCoreSpinningPillarLoop"]="SabotageCore"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/Gameplay/CrpShipTemplePyramidReveal"]="Pyramid"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/CapSmallShowroom/CrpShipShowroomShipArrive"]="GoldHand"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntLargeVentRoomOne/CrpShipFanLargeLoop"]="VentRoom"
        ["A valid backdrop ID was specified: VenusLowOrbit however no such backdrop zone was found!"]="Bridge"
      )
      bad_tiles=("RepairBay" "VentRoom" "Pyramid" "Reactor" "Hangar")
      allowed_tiles=("GunBattery" "Portals" "SabotageCore" "Bridge" "GoldHand")
      min_matches=2
      ;;
    olympus)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Olympus (Mars)"
      block_end="Net [Info]: Replication count by type:"
      declare -gA tile_paths=(
	["/Lotus/Levels/GrineerSettlement/CmpIntermediate06"]="CmpIntermediate06"
	["/Lotus/Sounds/Ambience/GrineerSettlement/CmpIntermediate01"]="CmpIntermediate01"
       )
     bad_tiles=("CmpIntermediate01")
     allowed_tiles=("CmpIntermediate06")
     min_matches=1
     ;;
    *)
      echo "Unknown mission: $mission"
      exit 1
      ;;
  esac
}
