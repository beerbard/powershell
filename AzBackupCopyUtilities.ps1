# Author: Eric Stevens
# Owner: Network for Good
# Last Revision Date: 8/3/2021

# To use: >./AzCopyUtilities.ps -copyDirection [fromAzStorage, toAzStorage] -server [] -drive [D,S (on-prem drives),H (Azure DB drive)] -instance [(cluster name), AllProdDatabases (Azure)] -dbase [name of db] -type [Diff, FULL, LOG] -timePeriod [previousDay (default), previousHour]

param (   
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the direction of transfer (fromAzStorage, toAzStorage")]
       [string[]]$copyDirection="fromAzStorage",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the name of the server that is being copied from or to")]
       [string[]]$server = "nfg-dr-wvm-db01",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the name of the drive (admin share minus the `$) that is being copied to\from (server to Az is usually D or S, Az to db server is currently H)")]
       [string[]]$drive = "H", 
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the abreviation for the environment, which can be found in the source/destination folder name in Az Storage - defaults to Prod")]
       [string[]]$env="Prod",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the folder on the server where the backups are grouped - toAz only. This will be the cluster name or the server name in the case of system DBs.")]
       [string[]]$instance = "NfgSqlCluster`$NfgDN2",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the name of the database being transferred.")]
       [string[]]$dbase = "NfgDonateNow",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the type of backup files being transferred (DIFF, FULL or LOG")]
       [string[]]$type = "LOG",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the directory to where the log file will be written.")]
       [string[]]$tempFileDir="C:\temp",
       [Parameter(Mandatory=$false,
              HelpMessage="Enter the time peroid the copy will cover (previousDay, previousHour")]
       [string[]]$timePeriod="previousHour"
    )
   
$logFilePath = "C:\Scripts\AzBackupCopyUtilities_Log.txt"
       
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

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Tee-Object -FilePath $logFilePath -Append



logEntry -Comment "Initiating file transfer." | Tee-Object -FilePath $logFilePath -Append

   if ($copyDirection -eq "fromAzStorage") {
       
       
       
       ################# Azure Blob Storage - PowerShell ####################  
 
       ## Input Parameters  
       $resourceGroupName="<SA-rg-name>"  
       $storageAccountKey="<SA-Key>"
       $storageAccountName="<sa-name>"  
       $fileShareName="db-backup"  
       $directoryPath="$env\"
 
       ## Connect to Azure Account  
       # Connect-AzAccount   
 
       ## Function to Lists directories and files  
       Function GetFiles {  
              # logEntry -Comment "Listing files." | Tee-Object -FilePath $logFilePath -Append

              ## Get the storage account context  
              $ctx=New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

              ## List directories
              $date = get-date
              $cutoff = $date.AddDays(-1).Date
              $cutoff
              
              $files = Get-AZStorageFile -Context $ctx -ShareName $fileShareName -Path "Prod\469ewdbha01\LoadMonitoring\FULL" | where-object {$_.Date } | get-AzStorageFile

              ## Loop through directories  
              foreach($file in $files) {  
                     # logEntry -Comment " Directory Name: $directory.Name" | Tee-Object -FilePath $logFilePath -Append  
                     $thename = $file.Name
                     "File Name: $thename"
                     # $files=Get-AZStorageFile -Context $ctx -ShareName $fileShareName -Path $directory.Name | get-AzStorageFile
                     ## Loop through all files and display  
                     # foreach ($file in $files) {  ""
                     #        $file.Name # | Tee-Object -FilePath $logFilePath -Append
                     # }  
              }  
       }  

  
       GetFiles   
 
       ## Disconnect from Azure Account  
       Disconnect-AzAccount 
       
       
       
       
       
       
       
       
       
       
       
       
       
       
       # Copy from Azure Storage to server
       $env:AZCOPY_CRED_TYPE = "Anonymous";
       ./azcopy.exe copy "https://nfgdrdbbackup01.file.core.windows.net/db-backup/*?sv=2020-02-10&ss=f&srt=sco&sp=rwdlc&se=2023-05-19T04%3A18%3A40Z&st=2021-05-17T20%3A18%3A40Z&spr=https&sig=Um5qyvJGvUGAFf0%2F73pT5x62mUUOvoy5giaVlc9lCUI%3D" "H:\UAT" --overwrite=prompt --check-md5 FailIfDifferent --from-to=FileLocal --preserve-smb-info=false --list-of-files "C:\Users\NFG-SR~1\AppData\Local\Temp\2\stg-exp-azcopy-65f2c67e-dc63-46b7-b8f4-11732e1cfb5f.txt" --recursive --trusted-microsoft-suffixes=;
       $env:AZCOPY_CRED_TYPE = "";



   } elseif ($copyDirection -eq "toAzStorage") {
   
       logEntry -Comment "Copying from $server to Azure Storage via azcopy.exe using SAS that expires on 7/19/2030" | Tee-Object -FilePath $logFilePath -Append
   
       # Params required:
   
       # date (file naming only) - not used in batching files by date
       $date = get-date -Format "yyyyMMdd.HH.mm.ss"
   
       # Aggregate variable strings (automatic if vars above are set - don't touch!)
       $source = "\\$server\$drive`$\DB Backups\$instance\$dbase\$type\*" # format matches both on-prem source dirs as well as the Az destination dirs on the DB server.
       logEntry -Comment "Source: $source" | Tee-Object -FilePath $logFilePath -Append
       $destination = "https://nfgdrdbbackup01.file.core.windows.net/db-backup/$env/$instance/$dbase/$type`?sv=2020-08-04&ss=bfqt&srt=sco&sp=rwdlacuptfx&se=2030-07-19T23:21:11Z&st=2020-07-19T15:21:11Z&spr=https&sig=6VXm9eWxH1D8%2B9lSCE97aM2Ju6Kte7y6FNv0XQxgDWY%3D"
       logEntry -Comment "Destination: $destination" | Tee-Object -FilePath $logFilePath -Append
       logEntry -Comment "Testing source: $source" | Tee-Object -FilePath $logFilePath -Append
       if (!(test-path -path $source)) {
              logEntry -Comment "Source folder does not exist. Plesae check your parameters before rerunning." | Tee-Object -FilePath $logFilePath -Append
              exit
       } else {
              logEntry -Comment "Source folder has been validated. Continuing..." | Tee-Object -FilePath $logFilePath -Append
       }
       $tempFileName = "backupFileTxList_$dbase`_$type`_$server`_$date.txt"
       logEntry -Comment "Creating text file with file transfer list: $tempFileName" | Tee-Object -FilePath $logFilePath -Append
       New-Item -Path $tempFileDir -Name $tempFileName -ItemType File -Force
       $tempFilePath = "$tempFileDir\$tempFileName"
       logEntry -Comment "Full path to file list: $tempFilePath" | Tee-Object -FilePath $logFilePath -Append
       logEntry -Comment "Testing temp file list location: $tempFilePath" | Tee-Object -FilePath $logFilePath -Append
       if (!(test-path -path $source)) {
              logEntry -Comment "Temp file list has not been created. Please check your parameters before rerunning." | Tee-Object -FilePath $logFilePath -Append
              exit
       } else {
              logEntry -Comment "Creation of temp file list has been validated. Continuing..." | Tee-Object -FilePath $logFilePath -Append
       }
       $timePeriod = "previousDay"
          # Set file batch min and max write times
          $startDate = Get-Date
          if ($timePeriod -eq "previousDay") {
                 # Calculate min
                 $min = $startDate.AddDays(-1).Date
                 # Calculate max
                 $max = $startDate.Date
          } elseif ($timePeriod -eq "previousHour") {
                 # Calculate min
                 $min = $startDate.AddSeconds(-$startDate.second % 60)
                 $min = $min.AddMinutes(-$min.minute % 60)
                 $min = $min.AddHours(-2)
                 # Calculate max
                 $max = $startDate.AddSeconds(-$startDate.second % 60)
                 $max = $max.AddMinutes(-$max.minute % 60)
                 $max = $max.AddHours(-1)
          } else {
   
              logEntry -Comment "Please enter a valid parameter for -timePeriod (previousDay or previousHour only). Default is previousDay if ommitted. Declare previousHour for hourly transfers." | Tee-Object -FilePath $logFilePath -Append
              exit
          }
   
          logEntry -Comment "Looking for files written between: $min and $max" | Tee-Object -FilePath $logFilePath -Append
       $files = Get-ChildItem -Path $source | where-object {$_.LastWriteTime -ge $min -and $_.LastWriteTime -lt $max}
       logEntry -Comment "List of files to transfer: $files" | Tee-Object -FilePath $logFilePath -Append
       
       if (($files.count) -eq 0) { 
              logEntry -Comment "No files have been batched that match the timeframe criteria." | Tee-Object -FilePath $logFilePath -Append
              add-content -Path $tempFilePath -value "No files have been batched that match the timeframe criteria."
              exit
       } else {
              foreach ($file in $files) {
                     logEntry -Comment "Adding $file.Name to temp file list txt file." | Tee-Object -FilePath $logFilePath -Append
                     add-content -Path $tempFilePath -value $file.name -Force
                 }
       }  
       
       if ((get-content -path $tempFilePath).Length -gt 0) {
              logEntry -Comment "Files to copy successfulyl batched to temp file. Proceeding to copy..." | Tee-Object -FilePath $logFilePath -Append
       } else {
              logEntry -Comment "No files were batched to temp file. Check your timeframe filters before rerunning." | Tee-Object -FilePath $logFilePath -Append
              exit
       }
       logEntry -Comment "Initiating copy to Azure Storage..." | Tee-Object -FilePath $logFilePath -Append
       $env:AZCOPY_CRED_TYPE = "Anonymous";
       azcopy.exe copy $source $destination --overwrite=ifSourceNewer --from-to=LocalFile --follow-symlinks --put-md5 --follow-symlinks --preserve-smb-info=false --list-of-files $tempFilePath --recursive --trusted-microsoft-suffixes= --log-level=INFO;
       $env:AZCOPY_CRED_TYPE = "";
       # Remove-Item -Path $tempFilePath # deletes file transfer list - enable once validated working correctly - or keep and use to move files to ha03. 
   
   } else {

       logEntry -Comment "Please enter a valid value for the -copyDirection parameter [toAzStorage (default) or fromAzStorage]" | Tee-Object -FilePath $logFilePath -Append
   }