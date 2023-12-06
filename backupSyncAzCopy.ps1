# Author: Eric Stevens
# Owner: Network for Good
# Last major revision date: 8/30/2021

# To use:

#>powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\BackupTxToAzure\backupSyncAZCopy.ps1" -direction "toServer" -server "nfg-dr-wvm-db01" -drive "H" -serverFolder "NfgSqlCluster`$NfgDN2" -dbase "NfgPrimary" -type "LOG" 


param (
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the direction of data sync (toAzure, toServer)")]
       [string[]]$direction="toAzure",   
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the name of the server being synced either to or from (469ewdbha03, nfg-dr-wvm-db01, etc.)")]
       [string[]]$server="469ewdbha03",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the drive letter of the drive on the server being coppied to or from (ensure the admin share is available and any service account used to execute has access to it.)")]
       [string[]]$drive="S",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the base folder on the share in which the files reside. This should be mirrored across all envs (`"469ewdbha01`" [system dbs] or `"NfgSqlCluster`$NfgDN2`" [application dbs], for example.")]
       [string[]]$serverFolder,
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the name of the database being copied as it is listed in Prod MS SQL.")]
       [string[]]$dbase,
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the environment (currently only `"Prod`" is available)")]
       [string[]]$env="Prod",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the type of backups the copy will be handling (nonPrimaryFull, primaryFull, systemFull, transactionLogs)")]
       [string[]]$type,
       [Parameter(Mandatory=$false,
              HelpMessage="Enter whether you would like files deleted from the source to be deleted at the destination (`"true`" [default] or `"false`")")]
       [string[]]$deleteDestination="true"
 )

# $server = "469ewdbha03"
# $drive = "S"
# $serverFolder = "NfgSqlCluster`$NfgDN2"
# $dbase = "NfgDonateNow"
# $env = "Prod"
# $type = "LOG"

if ($direction -eq "toAzure") {
       # Syncs just the specified env/instance/db/type. This is to make timing granular to accommodate the backup strategy. 
       $source = "\\$server\$drive`$\DB Backup\$env\$serverFolder\$dbase\$type" # format matches both on-prem source dirs as well as the Az destination dirs on the DB server.
       $destination = "https://nfgdrdbbackup01.file.core.windows.net/db-backup/$env/$serverFolder/$dbase/$type`?<SAS>"
} elseif ($direction -eq "toServer") {
       # Syncs the entire directory to the target server/drive since timing is not an issue. 
       $source = "https://nfgdrdbbackup01.file.core.windows.net/db-backup/$env/$serverFolder/$dbase/$type`?<SAS>"
       $destination = "\\$server\$drive`$\DB Backup\$env\$serverFolder\$dbase\$type"
}

azcopy sync $source $destination --delete-destination=$deleteDestination --exclude-pattern=".azDownload*"