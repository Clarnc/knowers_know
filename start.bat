@echo off
set WSL_SCRIPT_PATH=/home/clarnwsl/knowers_know/start.sh

echo Starting Ubuntu WSL...
wsl -d Ubuntu -- bash -ic %WSL_SCRIPT_PATH%
pause
