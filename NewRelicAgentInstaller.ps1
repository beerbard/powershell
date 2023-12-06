<# Install New Relic agent per role (app vs SQL)
Author: Eric Stevens
Owner: Bonterra
Date of last major revision: 4/26/2023

Usage:
 
.\NewRelicAgentInstaller.ps1 -environ <"pr","bl","gr","dr","st","dm","ut","qa"> -roles <"wb","as","db","tk","utility"> -apikey "<api-key>" -accountid "<AcctID>" -licenseKey "<license-key>" [-teardown]

Current state - 
    * Spin up and teardown are both working as expected. 

#>
param (
    [ValidateSet("pr","bl","gr","dr","st","dm","ut","qa",IgnoreCase = $false)]
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the environment of the host on which the New Relic Agent is being installed. <pr,bl,gr,dr,st,dm,ut,qa>")]
    [string]$environ,
    [ValidateSet("wb","as","db","tk","utility",IgnoreCase = $false)]
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the role of the host on which the New Relic Agent is being installed - this parameter accepts multiple values separated by comma (,). <wb,as,db,tk,utility>")]
    [string[]]$roles,
    [ValidateLength(32,32)]
    [ValidatePattern("NRAK-")]
    [Parameter(Position=0,Mandatory=$false,
    HelpMessage="Enter the api key of the service account being used to register and update the New Relic entities.")]
    [string]$apikey,
    [ValidateLength(7,7)]
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the account ID of the target New Relic account you wish to register this host with.")]
    [string]$accountid,
    [ValidateLength(40,40)]
    [ValidatePattern("436e")]
    [Parameter(Position = 0,Mandatory=$false,
    HelpMessage="Enter the license key of the target New Relic account of the host of which you wish to update tags.")]
    [string]$licensekey,
    [Parameter(Mandatory=$false,
    HelpMessage="Specify the -teardown switch if deprovisioning to remove server from New Relic monitoring. No other params are required when -teardown is specified.")]
    [switch]$teardown
)

# Define NR CLI exe location
$newrelic = "C:\Program Files\New Relic\New Relic CLI\newrelic.exe"

if (!($teardown)) {
    write-host "Installing the New Relic Agent using the following parameter:`n
    Environment: $environ`n
    Roles: $roles`n
    API Key: $apikey`n
    Account ID: $accountid`n
    License Key: $licensekey`n"

    # Install the latest NR CLI
    [Net.ServicePointManager]::SecurityProtocol = 'tls12, tls'
    (New-Object System.Net.WebClient).DownloadFile("https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1", "$env:TEMP\install.ps1")
    & PowerShell.exe -ExecutionPolicy Bypass -File $env:TEMP\install.ps1
    $env:NEW_RELIC_API_KEY=$apikey
    $env:NEW_RELIC_ACCOUNT_ID=$accountid

    # Install baseline services.
    & $newrelic install -y
    if ($role -eq 'db' -and (test-path -path c:\SQLServerFull)) {
        & $newrelic install -n mssql-server-integration-installer -y
    } elseif ($role -eq 'wb' -or $role -eq 'as') { # For web/app servers - Must happen AFTER a .net site is running
        # Install the .Net Agent
        write-host "The .Net Agent installs automatically if the default installer detects IIS and is passed a '-y' parameter."
        # & $newrelic install -n dotnet-agent-installer -y
    }

    # Add tagging in NR using newrelic-cli (newrelic.exe)

    # Find newrelic.exe path

    if ($newrelic) {
        # Create local newrelic-cli connection profile
        if (($apikey) -and ($licensekey)) {
            & $newrelic profile add --profile dotnet --region us --apiKey $apikey --accountId 3126071 --licenseKey $licensekey -ErrorAction SilentlyContinue
        } else {write-host "Either the API Key or License Key were not passed as a parameter or otherwise defined. Please revise or add manually."}
        # Set profile as default
        & $newrelic profile default --profile dotnet -ErrorAction SilentlyContinue

        # Query NR to get the data of the host entity
        $entity = & $newrelic entity search --name $env:COMPUTERNAME -ErrorAction SilentlyContinue | ConvertFrom-Json

        # Delete the custom tags of the entity just in case the server is being repurposed. 
        & $newrelic entity tags delete --guid $entity.guid --tag env --tag role -ErrorAction SilentlyContinue

        # Add tags to `$entity.guid retrieved from ^^^ (unlike deleting tags, one tag per call)
        & $newrelic entity tags create --guid $entity.guid --tag env:$environ -ErrorAction SilentlyContinue
        foreach ($role in $roles) {
            & $newrelic entity tags create --guid $entity.guid --tag role:$role -ErrorAction SilentlyContinue
        }
    } else {
        wite-host "Either no roles were defined, no license key was defined or the New Relic CLI was not available. Please add tags manually if required."
    }
}

if ($teardown) {
    write-host "Stopping IIS to enable removal of New Relic Infrastructure Agent if it exists on this server..."
    iisreset -stop -ErrorAction SilentlyContinue
    get-service -name newrelic-infra | stop-service -ErrorAction SilentlyContinue
    $app = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "New Relic Infrastructure Agent"}
    $app.Uninstall()
    Get-ChildItem -path "C:\ProgramData" -Directory | Where-Object { $_.Name -eq "New Relic"} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -path "C:\Program Files" -Directory | Where-Object { $_.Name -eq "New Relic"} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Get-ChildItem -path "C:\Program Files (x86)" -Directory | Where-Object { $_.Name -eq "New Relic"} | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    write-host "New Relic has been successfully uninstalled."
    iisreset -start -ErrorAction SilentlyContinue
}
