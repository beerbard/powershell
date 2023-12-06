<#  Tableau Server Upgrade

Author: Eric G. Stevens
Ownwe: Network for Good
Date of last major revision: 04/19/2022

Refer to https://help.tableau.com/current/server/en-us/sug_plan.htm for more details. 

The purpose of this script is to fully automate the backup of the current version and upgrade to newest version of:
    Tableau Server
    Tableau Server Management Master
    Tableau Server tabcmd
    Tableau Prep Builder

To complete this process ,the following logical steps are followed:
    .5 Prepare for upgrade
    1. Find current working version of Tableau Server --> $tsm_loc
    1.5. Perform backup of current version of Tableau Server
    2. Perform upgrades in this order:
        Tableau Server
        Tableau Server Management Master
        Tableau Server tabcmd
        Tableau Prep Builder
    3. Validate services are operational
    4. Uninstall older versions to save disk space (each install takes up approximately 6 GB of disk space and can be installed separately.)

Note: The version of Tableau being used can be found between the $env:TABLEAU_SERVER_MSI (Commercial version) and the $env:TABLEAU_SERVER_DATA_DIR_VERSION (working version) variables.
    The $env:TABLEAU_SERVER_DATA_DIR_VERSION matches the version of the installed program and data directories stamps. 
#>

# Disable scheduled jobs - http://10.10.1.19/#/schedules
    # A safe execution time is COB on a Friday that is not the last day of the month
    # No jobs need to be disabled if the above is true. 

# Run Tableau Server Single Server Upgrade - https://help.tableau.com/current/server/en-us/server-upgrade-baseline-singlenode-setup.htm

<#

# Getting old versions - CURRENTLY UNUSED

$oldVer = $env:TABLEAU_SERVER_DATA_DIR_VERSION

$oldChocoVers = choco list tableau -l
$oldPrepVer = $oldChocoVers[1].replace("Tableau-Prep-Builder ","")
$oldServerVer = $oldChocoVers[2].replace("Tableau-Server ","")
$oldMgmtVer = $oldChocoVers[3].replace("Tableau-Server-Management-Master ","")
$oldTabcmdVer = $oldChocoVers[4].replace("Tableau-Server-Tabcmd ","")

#>

choco upgrade tableau-server -y

# Define new version by finding the newest bin folder post-upgrade 
$TableauPath = "C:\Program Files\Tableau\Tableau Server\packages"
$newTableauFolder = get-childitem -Path $TableauPath -Directory | Where-Object {$_.Name -like "bin.*"} | sort-object -Property LastWriteTime -Descending | select-object -first 1
$newVer = $newTableauFolder.Name.TrimStart("bin.")

$newVerTSMPath = "C:\Program Files\Tableau\Tableau Server\packages\bin.$newVer\tsm.cmd"
$newVerUpgradeScriptPath = "C:\Program Files\Tableau\Tableau Server\packages\scripts.$newVer\upgrade-tsm.cmd"


# Stop Tableau Server using the NEW version of tsm.cmd
& "$newVerTSMPath" stop

# Update content of C:\ProgramData\Tableau\tsm_location.txt to reflect new tsm.cmd path
set-content -Path "C:\ProgramData\Tableau\tsm_location.txt" -Value $newVerTSMPath 

# Upgrade TSM using NEW update-tsm.cmd script path
& "$newVerUpgradeScriptPath" #located in scripts folder

# Start Tableau Server using the NEW version of tsm.cmd
& "$newVerTSMPath" start

# Get status post-startup
& "$newVerTSMPath" status -v

choco upgrade tableau-server-management-master -y
choco upgrade tableau-server-tabcmd -y
choco upgrade tableau-prep-builder -y

# *** These do not get old versions uninstalled and cannot be uninstalled via chocolatey - needs uninstall script to clean up - DO MANUALLY UNTIL COMPLETE ***

#choco uninstall tableau-prep-builder --version=$oldPrepVer # Old version remains
#choco uninstall tableau-server-tabcmd --version=$oldTabcmdVer # Old version remains
#choco uninstall tableau-server --version=$oldServerVer # Old version remains

