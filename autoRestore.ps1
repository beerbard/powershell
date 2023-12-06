# Author: Eric Stevens
# Owner: Network for Good
# # Date of last major revision: 03/23/2022

# Purpose: This scrip is intended to automate the restore of backup files in the NFG DR environment. 
# It should be able to be run ay any time to restore to a certain point (FULL, DIFF or LOG, or a combination thereof.)

param (
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the year (yyyy) of the desired restore datetime. Defaults to current year.")]
       [string[]]$yyyy = (get-date -Format "yyyy"),   
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the month (MM - two-digit number) of the desired restore datetime. Defaults to current month.")]
       [string[]]$MM = (get-date -Format "MM"),
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the day (dd - two-digit number) of the desired restore datetime. Defaults to current day.")]
       [string[]]$dd = (get-date -Format "dd"),
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the base folder on the share in which the files reside. This should be mirrored across all envs (`"469ewdbha01`" [system dbs] or `"NfgSqlCluster`$NfgDN2`" [application dbs], for example.")]
       [string[]]$serverFolder = "NfgSqlCluster`$NfgDN2",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the name of the database being copied as it is listed in Prod MS SQL.")]
       [string[]]$dbase = "NfgDonateNow",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the environment (currently only `"Prod`" is available)")]
       [string[]]$env="Prod"
 )

# DIFF - daily - Build the date range to get DIFFs.

    # Get-ChildItem -Path "$path\DIFF" -Recurse -File -include *.bak -Force | Where-Object { $_.CreationTime -gt ($inputDateTime).AddDays(-3) -and $_.CreationTime -lt $inputDateTime}
    # $inputDateTime = Get-Date
    # $path = "C:\Users\eric.stevens\Downloads"
    # $fileName = Get-ChildItem -Path $path -File -Force | Where-Object { $_.CreationTime -gt ($inputDateTime).AddDays(-3) -and $_.CreationTime -lt $inputDateTime} | Sort-Object LastWriteTime | Select-Object -last 1 Name
    # $fileNameString = $fileName.Name.ToString()
    # $fileNameString

# Log - hourly
# Stop NfgUtilityService on all servers.

# Define logging


$logFilePath = "C:\Logs\PSLog.txt"
if (!(Test-Path  $logFilePath)) {
   New-Item -ItemType File -Path $logFilePath -Force
}
$alertFilePath = "C:\Logs\temp_alertMessage.txt"
if (!(Test-Path  $alertFilePath)) {
   New-Item -ItemType File -Path $alertFilePath -Force
}
function logEntry {
    # Usage: logFile -Comment "This is the log message."
    # Returns: 2021.08.19      14:24:10        This is the log message.
    
    param (
           [Parameter()]
           [ValidateNotNullOrEmpty()]
           [string]$Comment="auto comment",
           [Parameter()]
           [switch]$alertMessage
    )

    $logTime = get-date -Format "yyyy.MM.dd`tHH:mm:ss`t"
    if ($alertMessage) {
       $alertBody = get-content -Path $alertFilePath
       $alertBody = $alertBody + "$logTime`t$Comment"
       set-content -path $alertFilePath -value $alertBody
    }
    "$logTime`t$Comment"
}

logentry -comment "Ipsum ildor..." -alertMessage | Tee-Object -FilePath $logFilePath

# Pick up later: tee to a tempBody.txt file


Add-Type -AssemblyName "Microsoft.SqlServer.Smo"
$smo = New-Object Microsoft.SqlServer.Management.Smo.Server $env:COMPUTERNAME

$instances = @(
    "NfgSqlCluster`$NfgDN2"
    ,"NfgSqlCluster`$NfgGP"
    ,"NfgSqlCluster`$NfgOther"
    ,"NfgSqlCluster`$NfgV4"
    )
$body = "Restoring instances $instances..."
foreach ($instance in $instances) {
       # NfgDN2
       if ($instance -eq "NfgSqlCluster`$NfgDN2") {
              $dbs = @("NfgDonateNow","NfgPartner")
       }

       # NfgGP
       if ($instance -eq "NfgSqlCluster`$NfgGP") {
              $dbs = @("NfgGP","NfgProductConfig")
       }

       # NfgOther
       if ($instance -eq "NfgSqlCluster`$NfgOther") {
              $dbs = @("NfgAccount","NfgConfig","NfgPrimary_GP","NPORulesEngine")
       }
       
       # NfgV4
       if ($instance -eq "NfgSqlCluster`$NfgV4") {
              $dbs = @("NfgPrimary")
       }

       $body = $body + "`nRestoring DBs for instance $instance"
       $inputDateTime = Get-Date
       Remove-variable nfgprimary # assumes nfgprimary has not been restored until otherwise successful
       foreach ($db in $dbs) {
              $path = "H:\DB Backup\Prod\$instance\$db\FULL"
              $fileName = Get-ChildItem -Path $path -File -include *.bak -Force -Recurse | Where-Object { $_.CreationTime -gt ($inputDateTime).AddDays(-6)} | Sort-Object LastWriteTime | Select-Object -last 1 Name
              if (!$fileName) { 
                     logentry -comment "No recent backup for $db can be found. Moving to next..." -alertMessage | Tee-Object -FilePath $logFilePath
                     return 
              }
              $fileNameString = $fileName.Name.ToString()
              logentry -comment "Processing backup file name: $fileNameString" -alertMessage | Tee-Object -FilePath $logFilePath
              $filePath = "$path\$fileNameString"
              $smo.KillAllProcesses($db)
              logentry -comment "Restoring $db from $filePath" -alertMessage | Tee-Object -FilePath $logFilePath   
              try {
                     Restore-SqlDatabase -ServerInstance "nfg-dr-wvm-db01" -Database $db -BackupFile $filePath -ReplaceDatabase
              } catch {
                     $ErrorMessage = $_.Exception.Message
                     logentry -comment "Error: Restore of $db failed with error...`n`n`t$ErrorMessage" -alertMessage | Tee-Object -FilePath $logFilePath 
                     return
              }

              # Flag NFGPrimary restore as successful to facilitate further configuration
              if ($db -eq "NfgPrimary") {$nfgprimary = $true}
              logentry -comment "Restore of $db complete...proceeeding to reassociate db users..." -alertMessage | Tee-Object -FilePath $logFilePath 
              $userSyncQuery = "
                USE $db
                declare @userVar varchar(30) 
                declare users cursor for
                select name from sys.database_principals where type = 's'
                open users
                fetch next from users into @userVar
                while @@FETCH_STATUS = 0
                begin
                       exec sp_change_users_login 'auto_fix', @userVar
                       fetch next from users into @userVar
                end
                close users
                deallocate users
                "
              try {  
                     invoke-sqlcmd -query $userSyncQuery
              } catch {
                     $ErrorMessage = $_.Exception.Message
                     logentry -comment "Error: User reassociation of $db failed with the following error:`n`n`t$ErrorMessage" -alertMessage | Tee-Object -FilePath $logFilePath
                     return
              }
              logentry -comment "Successfully reassociated users for $db...proceeding..." -alertMessage | Tee-Object -FilePath $logFilePath
              
       }
}

# Add all IPs to allow list range (specified is the range of dynamit IPs from the Azure application gateway)

$allowIPInsertQuery = "USE NfgPrimary
	DECLARE @partnerid int
	select @partnerid=min(I_PARTNER_ID) from TBL_REMOTE_API_IP_ADDRESS WHERE I_PARTNER_ID is not null
	while @partnerid is not NULL
    BEGIN
		insert into TBL_REMOTE_API_IP_ADDRESS (I_PARTNER_ID, VC_START_IP_ADDRESS, VC_END_IP_ADDRESS, B_PRODUCTION, B_DISABLED) values (@partnerid,'10.200.3.1','10.200.3.253',1,0)
		select @partnerid=min(I_PARTNER_ID) from TBL_REMOTE_API_IP_ADDRESS where I_PARTNER_ID > @partnerid and I_PARTNER_ID is not NULL
	END"
if ($NFGPrimary) {
       try {
              invoke-sqlcmd -query $allowIPInsertQuery
       } catch {
              $ErrorMessage = $_.Exception.Message
              logentry -comment "Error: Failed to update whitelist with Azure load balancer IP (clientIP) for all orgs.`n`n`t$ErrorMessage" -alertMessage | Tee-Object -FilePath $logFilePath
              $allowIPInsertQuery_failed = "true"
       }
}
if (!($allowIPInsertQuery_failed)) {
       logentry -comment "Whitelist update of Azure load balancer clientIP allow for all orgs on NfgPrimary Complete." -alertMessage | Tee-Object -FilePath $logFilePath
}

logentry -comment "Adding session state for NfgGP..." -alertMessage | Tee-Object -FilePath $logFilePath

# execute session state definition
try {
       C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regsql.exe -S dblistener.dr.internal.networkforgood.org -d NfgGp -ssadd -sstype c -E
} catch {
       $ErrorMessage = $_.Exception.Message
       logentry -comment "Error: Failed to update whitelist with Azure load balancer IP (clientIP) for all orgs.`n`n`t$ErrorMessage" -alertMessage | Tee-Object -FilePath $logFilePath
       $updateSessionState_failed = $true
}
if (!($updateSessionState_failed)) {
       logentry -comment "Session state configuration complete...please verify last backup date and user association report on each database." -alertMessage | Tee-Object -FilePath $logFilePath
}


# Send success/failure notification
try {
    C:\Scripts\SocketLabsAlert-APIWebRequests.ps1 -recipient "eric.stevens@networkforgood.com" -env "dv" -subject "Notification: Disaster recovery auto-restore"
} catch {
    $ErrorMessage = $_.Exception.Message
    logEntry -Comment "`Warning: sending of alert email has resulted in error. Please check local log at $logFilePath to verify completion:`n`n`t$ErrorMessage" | Tee-Object -FilePath $logFilePath -Append
} 



