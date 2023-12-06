# Author: Eric Stevens
# Owner: Network for Good

# Last Revision Date: 8/3/2021

param (   
    [Parameter(Mandatory=$true,
           HelpMessage="Enter the type of backups the copy will be handling (nonPrimaryFull, primaryFull, systemFull, transactionLogs)")]
    [string[]]$backupType
 )

if (!(test-path -path C:\Scripts)) {
    new-item -Path C:\Scripts -ItemType Directory
}
Set-Location -Path "C:\Scripts\BackupTxToAzure"
$logFilePath = "C:\Scripts\AzBackupCopyUtilities_Wrapper_Log.txt"
       
function logEntry {
       # Usage: logFile -Comment "This is the log message."
       # Returns: 2021.08.19      14:24:10        This is the log message.
       param (
              [Parameter()]
              [ValidateNotNullOrEmpty()]
              [string]$Comment
       )

       $logTime = get-date -Format "yyyy.MM.dd`tHH:mm:ss`t"
       "$logTime$Comment"
}



if ($backupType -eq "nonPrimaryFull") {
# Copy Full Backup (non-NfgPrimary DBs) - Every Saturday - completes in 1 hour - starts at 7:05 AM, completes by 8 AM. 

    #  Start at 9 AM every Saturday. 
    logEntry -Comment "Beginning transfer of FULL backups of NfgSqlCluster`$NfgDN2..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgCapOne -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgCoke -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgDonateNow -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgPartner -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgCapOne\FULL\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgCapOne\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgCoke\FULL\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgCoke\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgDonateNow\FULL\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgDonateNow\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgPartner\FULL\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgPartner\FULL" /E /MAXAGE:1

    logEntry -Comment "Beginning transfer of FULL backups of NfgSqlCluster`$NfgGP..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgGP" -dbase NfgGP -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgGP" -dbase NfgProductConfig -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgGP" -dbase SSISDB -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgGP\NfgGP\FULL\ "s:\DB Backups\NfgSqlCluster$NfgGP\NfgGP\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgGP\NfgProductConfig\FULL\ "s:\DB Backups\NfgSqlCluster$NfgGP\NfgProductConfig\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgGP\SSISDB\FULL\ "s:\DB Backups\NfgSqlCluster$NfgGP\SSISDB\FULL" /E /MAXAGE:1

    logEntry -Comment "Beginning transfer of FULL backups of NfgSqlCluster`$NfgOther..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgAccount -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgConfig -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgPrimary_GP -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgSessionState -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NPORulesEngine -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append
    
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgAccount\FULL\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgAccount\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgConfig\FULL\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgConfig\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgPrimary_GP\FULL\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgPrimary_GP\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgSessionState\FULL\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgSessionState\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NPORulesEngine\FULL\ "s:\DB Backups\NfgSqlCluster$NfgOther\NPORulesEngine\FULL" /E /MAXAGE:1

    logEntry -Comment "Beginning transfer of FULL backups of NfgSqlCluster`$NfgReporting..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgReporting" -dbase Nfg_Reporting -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgReporting" -dbase ReportServer -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgReporting" -dbase ReportServerTempDB -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgReporting\Nfg_Reporting\FULL\ "s:\DB Backups\NfgSqlCluster$NfgReporting\Nfg_Reporting\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgReporting\ReportServer\FULL\ "s:\DB Backups\NfgSqlCluster$NfgReporting\ReportServer\FULL" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgReporting\ReportServerTempDB\FULL\ "s:\DB Backups\NfgSqlCluster$NfgReporting\ReportServerTempDB\FULL" /E /MAXAGE:1
} elseif ($backupType -eq "primaryFull") {
# Copy Full Backup (NfgPrimary Only) - Every Saturday - completes in 3 1/2 hours - starts at 11 AM and completes by 2:30 PM.

    # Start at 4 PM every Saturday.

    logEntry -Comment "Beginning transfer of FULL backup of NfgSqlCluster`$NfgV4..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgV4" -dbase NfgPrimary -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgV4\NfgPrimary\FULL "s:\DB Backups\NfgSqlCluster$NfgV4\NfgPrimary\FULL" /E /MAXAGE:1
} elseif ($backupType -eq "systemFull") {
# Copy systemDB backups - Every day - Completes in 30 seconds - Starts at 6:45 AM and completes by 6:46 AM. 

    # Start at 7 AM every day.

    logEntry -Comment "Beginning transfer of FULL system backups of 469EWDBHA01..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA01" -dbase master -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA01" -dbase model -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA01" -dbase msdb -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    logEntry -Comment "Beginning transfer of FULL system backups of 469EWDBHA02..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA02" -dbase master -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA02" -dbase model -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA02" -dbase msdb -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    logEntry -Comment "Beginning transfer of FULL system backups of 469EWDBHA03..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA03" -dbase master -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA03" -dbase model -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA03" -dbase msdb -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    logEntry -Comment "Beginning transfer of FULL system backups of 469EWDBHA05..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA05" -dbase master -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA05" -dbase model -type FULL
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "469EWDBHA05" -dbase msdb -type FULL
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\469EWDBHA01\ "s:\DB Backups\469EWDBHA01" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\469EWDBHA02\ "s:\DB Backups\469EWDBHA02" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\469EWDBHA03\ "s:\DB Backups\469EWDBHA03" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\469EWDBHA05\ "s:\DB Backups\469EWDBHA05" /E /MAXAGE:1

} elseif ($backupType -eq "transactionLogs") {
# Copy Transaction Log backups - Every Day (currently disabled, take from H:) - Test for timing. - Run every hour on the half hour and take everything for the hour before minus 30 mins. 
# i.e. Execution at 10:30 AM gets transations between 9:00 AM and 10:00 AM. $now = get-date.hour(Now)`get-object | where $.date.hour -eq $now-1.

    # Continually runs every hour after start. 

    logEntry -Comment "Beginning transfer of transaction LOG backups of NfgSqlCluster`$NfgDN2..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgCapOne -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgCoke -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgDonateNow -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgDN2" -dbase NfgPartner -type LOG -timePeriod previousHour
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgCapOne\LOG\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgCapOne\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgCoke\LOG\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgCoke\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgDonateNow\LOG\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgDonateNow\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgDN2\NfgPartner\LOG\ "s:\DB Backups\NfgSqlCluster$NfgDN2\NfgPartner\LOG" /E /MAXAGE:1

    logEntry -Comment "Beginning transfer of transaction LOG backups of NfgSqlCluster`$NfgGP..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgGP" -dbase NfgGP -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgGP" -dbase NfgProductConfig -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgGP" -dbase SSISDB -type LOG -timePeriod previousHour
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgGP\NfgGP\LOG\ "s:\DB Backups\NfgSqlCluster$NfgGP\NfgGP\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgGP\NfgProductConfig\LOG\ "s:\DB Backups\NfgSqlCluster$NfgGP\NfgProductConfig\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgGP\SSISDB\LOG\ "s:\DB Backups\NfgSqlCluster$NfgGP\SSISDB\LOG" /E /MAXAGE:1

    logEntry -Comment "Beginning transfer of transaction LOG backups of NfgSqlCluster`$NfgOther..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgAccount -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgConfig -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgPrimary_GP -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NfgSessionState -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgOther" -dbase NPORulesEngine -type LOG -timePeriod previousHour
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgAccount\LOG\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgAccount\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgConfig\LOG\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgConfig\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgPrimary_GP\LOG\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgPrimary_GP\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NfgSessionState\LOG\ "s:\DB Backups\NfgSqlCluster$NfgOther\NfgSessionState\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgOther\NPORulesEngine\LOG\ "s:\DB Backups\NfgSqlCluster$NfgOther\NPORulesEngine\LOG" /E /MAXAGE:1

    logEntry -Comment "Beginning transfer of transaction LOG backups of NfgSqlCluster`$NfgReporting..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgReporting" -dbase Nfg_Reporting -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgReporting" -dbase ReportServer -type LOG -timePeriod previousHour
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgReporting" -dbase ReportServerTempDB -type LOG -timePeriod previousHour
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgReporting\Nfg_Reporting\LOG\ "s:\DB Backups\NfgSqlCluster$NfgReporting\Nfg_Reporting\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgReporting\ReportServer\LOG\ "s:\DB Backups\NfgSqlCluster$NfgReporting\ReportServer\LOG" /E /MAXAGE:1
    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgReporting\ReportServerTempDB\LOG\ "s:\DB Backups\NfgSqlCluster$NfgReporting\ReportServerTempDB\LOG" /E /MAXAGE:1

    logEntry -Comment "Beginning transfer of transaction LOG backup of NfgSqlCluster`$NfgV4..." | Tee-Object -FilePath $logFilePath -Append
    C:\Scripts\BackupTxToAzure\AzBackupCopyUtilities.ps1 -copyDirection toAzStorage -server 469ewdbha05 -drive S -serverFolder "NfgSqlCluster`$NfgV4" -dbase NfgPrimary -type LOG -timePeriod previousHour
    logEntry -Comment "Completed transfer." | Tee-Object -FilePath $logFilePath -Append

    #robocopy D:\Databases\Backups\NfgSqlCluster$NfgV4\NfgPrimary\LOG\ "s:\DB Backups\NfgSqlCluster$NfgV4\NfgPrimary\LOG" /E /MAXAGE:1

} else {

    logEntry -Comment "Please enter a valid backup type. View help for more details." | Tee-Object -FilePath $logFilePath -Append
}