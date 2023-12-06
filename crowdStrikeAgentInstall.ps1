<# Install Octopus Tentacle agent per role (app vs SQL)
Author: Eric Stevens
Owner: Bonterra
Date of last major revision: 4/26/2023

Usage:
 
.\crowdStrikeAgentInstall.ps1 -cid "<cid>" -octoapikey "<api-key>" [-teardown]

Current state - 
    * Invoke-webrequest to retrieve Octopus Deploy space does not work when API key is passed as a parameter for some reason. 
        Workaround is to define the $cid and $octoapikey vars in the body of the script rather than passing.
        Ideally we want to keep the api key and the CrowdStrike cid in a key store rather than in the body. 
    * There is not currently a provision for teardown - it is unknown whether or not it is required. 
    * Needs loggingModule added.

#>

param (
    [ValidateLength(35,35)]
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the CrowdStrike customer ID.")]
    [string]$cid,
    [ValidateLength(36,36)]
    [ValidatePattern("API-")]
    [Parameter(Position = 0,Mandatory=$false,
    HelpMessage="Enter the Octopus API key for the instance\user you wish to use to download the package.")]
    [string]$octoapikey,
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the CrowdStrike version (you can find this in the Octopus instance. Default is 6.49.16303).")]
    [string]$pkgver="6.49.16303",
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the -teardown switch if you are reprovisioning. No other switches are needed if the -teardown switch is specified.")]
    [switch]$teardown
)

# Define Logging

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

# Temp vars
$cid = "<cid>"
$pkgver = "6.49.16303"
$octoapikey="<api-key>"

# Download and extract CrowdStrike Agent from Octopus.

$ErrorActionPreference = "Stop";

# Define working variables
$octopusURL = "<workspace-url>"
$octopusAPIKey = $octoapikey
$header = @{ "X-Octopus-ApiKey" = $octopusAPIKey }
$spaceName = "Dot Net"
$packageName = "CrowdstrikeWindowsSensor"
$packageVersion = $pkgver
$outputFolder = "$env:temp\Octopus\Packages\Crowdstrike\$pkgver"

# Ensure output folder exists and is empty
mkdir $outputFolder -Force -ErrorAction SilentlyContinue
Get-ChildItem -path $outputFolder -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Get space
write-host "Getting space"
$space = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/spaces/all" -Headers $header) | Where-Object {$_.Name -eq $spaceName}
$space

# Get package details
write-host "Getting package deets."
$package = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/packages/packages-$packageName.$packageVersion" -Headers $header)
$package

# Get package
$filePath = [System.IO.Path]::Combine($outputFolder, "$($package.PackageId).$($package.Version)$($package.FileExtension)")
write-host "Fetching package to $filePath."
Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/packages/$packageName.$packageVersion/raw" -Headers $header -OutFile $filePath
Write-Host "Downloaded file to $filePath"
Rename-Item $filePath "$filePath.zip"
Expand-Archive -literalpath "$filePath.zip" -DestinationPath $filepath
Remove-Item "$filePath.zip"
$installerPath = "$filepath\WindowsSensor.exe"

# Verify services:
# TCP/IP NetBIOS Helper (LMHosts)
$lmhostsStat = (Get-Service "LMHosts").Status
if ($lmhostsStat -ne "Running") {
    write-host "LMHosts service is not running and is a dependency. Attempting restart..."
    try {
        start-service -Name "LMHosts"
        write-host "LMHosts service has been successfully started. Continuting..."
    } catch {
        write-host "LMHosts service is not running and cannot be started. Please investigate and restart once remediated."
        exit
    }
} else {
    write-host "LMHosts service is checking out good. Continuing..." 
}
# nsi
$nsiSvcStat = (Get-Service "nsi").Status
if ($nsiSvcStat -ne "Running") {
    write-host "Network Store Interface Service is not running and is a dependency. Attempting restart..."
    try {
        start-service -Name "nsi"
        write-host "Network Store Interface Service has been successfully started. Continuting..."
    } catch {
        write-host "Network Store Interface Service is not running and cannot be started. Please investigate and restart once remediated."
        exit
    }
} else {
    write-host "Network Store Interface Service is checking out good. Continuing..." 
}
# Base Filtering Engine (BFE)
$bfeSvcStat = (Get-Service "bfe").Status
if ($bfeSvcStat -ne "Running") {
    write-host "Base Filtering Engine service is not running and is a dependency. Attempting restart..."
    try {
        start-service -Name "bfe"
        write-host "Base Filtering Engine service has been successfully started. Continuting..."
    } catch {
        write-host "Base Filtering Engine service is not running and cannot be started. Please investigate and restart once remediated."
        #exit
    }
} else {
    write-host "Base Filtering Engine service is checking out good. Continuing..." 
}
# Power
$powerSvcStat = (Get-Service "power").Status
if ($powerSvcStat -ne "Running") {
    write-host "Windows Power Service is not running and is a dependency. Attempting restart..."
    try {
        start-service -Name "power"
        write-host "Windows Power Service has been successfully started. Continuting..."
    } catch {
        write-host "Windows Power Service is not running and cannot be started. Please investigate and restart once remediated."
        exit
    }
} else {
    write-host "Windows Power Service is checking out good. Continuing..." 
}

# Run the installer
if (test-path -path $installerPath) {
    write-host "Installer path exists, proceeding to install..."
    & $installerPath /install /norestart CID=$cid ProvWaitTime=3600000 /quiet
} else { 
    write-host "Installer is not found at the path specified...please re-evaluate setup file location and restart."
}

# Check for running service during loop delay
$m = 0

while ($i -eq 0 -or $m -le 15) {
    $service = get-service | where-object -filterScript {$_.Name -eq "CSFalconService" -and $_.Status -eq "Running"}
    if ($service) {
        $i = 1
        write-host "The CSFalconService has been successfully installed in $m minutes. Please check with the security team if further verification is neccessary."
        break
    }
    start-sleep -seconds 60
    $m++
    write-host "$m min: Checking for status of CSFalconService to be set to Running"
}

if (!($i)) {
    write-host "The install of the CSFalconService did not install successfully within 15 minutes. The install may require intervention. Please manually verify."
    # Disable Windows Defender Threat Protection - this is saved for the CrowdStrike install so Windows Defender realtime monitoring is not turned off until the CS agent has been installed.
    exit
} else {
    # Accounting for any instance where server might be a domain controller, which requires specialized port availability for CrowdStrike-protected servers.
    write-host "Checking to see if server is a domain controller."
    $adcontroller = get-addomaincontroller -ErrorAction SilentlyContinue
    if ($adcontroller.hostname) { 
        WRITE-HOST "Host is a Domain Controller...ensuring UDP 137 is open..."
        New-NetFirewallRule -DisplayName 'Crowdstrike Allow UDP 137' -Profile 'Domain' -Direction Inbound -Action Allow -Protocol UDP -LocalPort 137
    } else {
        write-host "Host is not a domain controller. No firewall configuration necessary."
    }
    write-host "Disabling Windows Defender realtime monitoring."
    Set-MpPreference -DisableRealtimeMonitoring $true
    Write-host "Complete...the end!"
}