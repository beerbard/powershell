# Author: Eric Stevens for Network for Good
# Date: 4/29/2021

# This is a command line backup script for Tableau Server. 
# This script requires Tableau Server to be installed
# Intended to be configured as a scheduled task on the controller server. 

# Checks the location of the tsm.cmd operator, which is version-dependent. 
# Performs backup of data.
# Performs backup of server settings. 
# Performs maintenance of logs, purges Redis cache, removed http request table, and purges temp files.
# Exclusions: 

# Script must be run with elevated permissions on the target server. 

remove-item "C:\ProgramData\Tableau\tsm_location.txt"
& C:\Windows\System32\where.exe tsm > C:\ProgramData\Tableau\tsm_location.txt 
$tsm_loc = get-content C:\ProgramData\Tableau\tsm_location.txt | where-object { $_ -match "$env:TABLEAU_SERVER_DATA_DIR_VERSION" }

if ($tsm_loc) {

	# Perform backup maintenance
	$tsm_backup_path = "C:\ProgramData\Tableau\Tableau Server\data\tabsvc\files\backups"
	$tsm_backup_archive_path = "E:\Nfg\TableauBackups"
	copy-item -Path $tsm_backup_path\*.json -Destination $tsm_backup_archive_path -Force
	copy-item -Path $tsm_backup_path\*.tsbak -Destination $tsm_backup_archive_path -Force
	remove-item -Path $tsm_backup_path\*.tsbak
	remove-item -Path $tsm_backup_path\*.json
	Get-ChildItem –Path $tsm_backup_archive_path -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | Remove-Item
	
	# Execute tsm backup
	& $tsm_loc maintenance backup -f tableau_backup -d --ignore-prompt
	& $tsm_loc settings export -f "C:\ProgramData\Tableau\Tableau Server\data\tabsvc\files\backups\tableau_settings_backup.json"
	
	# Execute tsm cleanup maintenance
	& $tsm_loc maintenance cleanup -l -t -r -q --log-files-retention 7
} else {
	write-host "Tableau Server is either not installed on the target or tsm.cmd cannot be located."
}