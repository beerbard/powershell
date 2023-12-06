# Author: Eric Stevens
# Owner: Network for Good
# Date of last major revision: 1/24/2022 

# Usage

# Note: to add the alert to the body of a notification email, add the -alertMessage switch 

# $>logEntry -Comment "This is the comment." [-alertMessage] | Tee-Object -FilePath $logFilePath -append

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

# Use at end of parent script to send alert email - requires presence of SocketLabsAlert-APIWebRequests.ps1
#try {
#    C:\Scripts\SocketLabsAlert-APIWebRequests.ps1 -recipient "eric.stevens@networkforgood.com" -env "dv" -subject "Notification: Disaster recovery auto-restore"
#} catch {
#    $ErrorMessage = $_.Exception.Message
#    logEntry -Comment "`Warning: sending of alert email has resulted in error. Please check local log at $logFilePath to verify completion:`n`n`t$ErrorMessage" | Tee-Object -FilePath $logFilePath -Append
#} 


