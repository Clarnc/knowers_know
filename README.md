
# Gascade_secrets

## Requirements

- **WSL2** (Windows Subsystem for Linux)
- **BurntToast PowerShell module** for notifications

## Installation

1. **Enable WSL2**  
   If not already done, install WSL2 on your Windows machine.  
   See: https://apps.microsoft.com/detail/9PDXGNCFSCZV?hl=en-us&gl=PL&ocid=pdpshare

2. **Install BurntToast module in PowerShell**  
   Open PowerShell as Administrator and run:

   ```powershell
   Install-Module -Name BurntToast -Force -Scope CurrentUser
   Set-ExecutionPolicy RemoteSigned
   ```
3. **Clone this repository**
   ```bash
   git clone https://github.com/Clarnc/knowers_know
   cd knowers_know/
   chmod +x Apollo.sh Kappa.sh Armatus.sh Laomedeia.sh Tuvul_ommons.sh start.sh
   ```
4. **Run the script**
   ```bash
   ./start.sh

