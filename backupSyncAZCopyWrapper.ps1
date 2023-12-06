# Author: Eric Stevens
# Owner: Network for Good
# Last major revision date: 9/21/2021

# Relies on backupSyncAzCopy.ps1

# Purpose: this script aggregates syncs of all types of backups of certain types. 
# The sync does not run against all backup types within the same wrapper to avoid overlap and to ensure that long sync jobs don't interfere with the shorter sync jobs. 

# To execute, run: >powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\BackupTxToAzure\backupSyncAZCopyWrapper.ps1" -type DIFF -target All -direction toServer

param (   
    [Parameter(Mandatory=$false,
        HelpMessage="Enter the direction of the sync (`"toAzure`" or `"toServer`")")]
    [string[]]$direction="toAzure",   
    [Parameter(Mandatory=$true,
           HelpMessage="Enter the type of backups the copy will be handling (nonPrimaryFull, primaryFull, systemFull, transactionLogs)")]
    [string[]]$type,
    [Parameter(Mandatory=$true,
           HelpMessage="Enter the type of backups the copy will be handling (nonPrimaryFull, primaryFull, systemFull, transactionLogs)")]
    [string[]]$target="All" # [Primary,NonPrimary,System,All]
)

if ($type -eq "FULL" -and ($target -eq "System" -or $target -eq "All")) {
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA01" -dbase "LoadMonitoring" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA01" -dbase "master" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA01" -dbase "model" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA01" -dbase "msdb" -type $type -direction $direction

    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA02" -dbase "LoadMonitoring" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA02" -dbase "master" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA02" -dbase "model" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA02" -dbase "msdb" -type $type -direction $direction

    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA03" -dbase "LoadMonitoring" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA03" -dbase "master" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA03" -dbase "model" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA03" -dbase "msdb" -type $type -direction $direction

    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA05" -dbase "LoadMonitoring" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA05" -dbase "master" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA05" -dbase "model" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "469EWDBHA05" -dbase "msdb" -type $type -direction $direction
}

if ($target -eq "NonPrimary" -or $target -eq "All") {
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgDN2" -dbase "NfgCapOne" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgDN2" -dbase "NfgCoke" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgDN2" -dbase "NfgDonateNow" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgDN2" -dbase "NfgPartner" -type $type -direction $direction

    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgGP" -dbase "NfgGP" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgGP" -dbase "NfgProductConfig" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgGP" -dbase "SSISDB" -type $type -direction $direction

    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgOther" -dbase "NfgAccount" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgOther" -dbase "NfgConfig" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgOther" -dbase "NfgPrimary_GP" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgOther" -dbase "NfgSessionState" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgOther" -dbase "NPORulesEngine" -type $type -direction $direction

    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgReporting" -dbase "Nfg_Reporting" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgReporting" -dbase "ReportServer" -type $type -direction $direction
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgReporting" -dbase "ReportServerTempDB" -type $type -direction $direction
}

if ($target -eq "Primary" -or $target -eq "All") {
    C:\Scripts\BackupTxToAzure\backupSyncAzCopy.ps1 -serverFolder "NfgSqlCluster`$NfgV4" -dbase "NfgPrimary" -type $type -direction $direction
}