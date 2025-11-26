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
      block_end="Net \[Info\]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntHallsOfJudgement/"]="HallsOfJudgement"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntCloister/"]="Cloister"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntEndurance/"]="Endurance"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntStealth/"]="Stealth"
        ["/Lotus/Sounds/Ambience/OrokinMoon/MoonIntPower/"]="Power"
      )
      allowed_tiles=("Power" "HallsOfJudgement" "Endurance")
      min_matches=2
      ;;
    armatus)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Armatus (Deimos)"
      block_end="Net \[Info\]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiIntEchoesSpawnMachineElectricityZapASeq"]="Circle"
        ["/Lotus/Sounds/Ambience/Entrati/Props/EntratiDanteUnboundPistonMachineSeq"]="Piston"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiGlassSphereVoidShakeSeq"]="Sphere"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiTrainPassbySeq"]="Train"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiPortcullisDoorOpenSeq"]="TorsoA"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiIntAtriumWindBlastSeq"]="Mirror"
        ["/Lotus/Sounds/Ambience/Entrati/Gameplay/EntratiConJunctionServiceDoorCloseSeq"]="TorsoB"
        ["/Lotus/Levels/EntratiLab/IntTerrarium/Scope"]="Terrarium"
      )
      bad_tiles=("Terrarium" "Piston" "TorsoB" "Sphere")
      min_matches=1
      ;;
    kappa)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Kappa (Sedna)"
      block_end="Net \[Info\]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/GrineerGalleon/GrnIntermediateSeven"]="GrnIntermediateSeven"
      )
      allowed_tiles=("GrnIntermediateSeven")
      min_matches=1
      ;;
    laomedeia)
      map_type="sound_match"
      block_start="ThemedSquadOverlay.lua: Mission name: Laomedeia (Neptune)"
      block_end="Net \[Info\]: Replication count by type:"
      declare -gA tile_paths=(
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntWarehouseTwo/CrpShipVoidPortalSeq"]="Portals"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntGunBattery/CrpShipGunBatteryVoidThunderClapsSeq"]="GunBattery"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntHangarOne/CrpShipDataPillarLoopASeq"]="Hangar"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntReactorOne/CrpShipSpinningReactorChargeSeq"]="Reactor"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntSpacecraftRepairBayOne/CrpShipTrainDroneLoopSeq"]="RepairBay"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/ObjSabotageCore/CrpShipSabotageCoreSpinningPillarLoopSeq"]="SabotageCore"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/Gameplay/CrpShipTemplePyramidRevealSeq"]="Pyramid"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/CapSmallShowroom/CrpShipShowroomShipArriveBSeq"]="GoldHand"
        ["/Lotus/Sounds/Ambience/CorpusShipRemaster/IntLargeVentRoomOne/CrpShipFanLargeLoopSeq"]="VentRoom"
        ["A valid backdrop ID was specified: VenusLowOrbit however no such backdrop zone was found!"]="Bridge"
      )
      allowed_tiles=("GunBattery" "Portals" "SabotageCore" "Bridge" "GoldHand")
      min_matches=2
      ;;
    *)
      echo "Unknown mission: $mission"
      exit 1
      ;;
  esac
}
