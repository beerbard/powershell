<# Install Octopus Tentacle agent per role (app vs SQL)
Author: Eric Stevens
Owner: Bonterra
Date of last major revision: 4/7/2023

Usage:
 
.\OctopusTentacleInstaller.ps1 -environ "qa" -role "wb","as","sl" -apikey API-0MFCOUC6QI4PCTIG2CK0Y2NW2HQNVSA -server "https://networkforgood.octopus.app" -spacename "Dot Net" [-teardown]

#>

param (
    [ValidateSet("pr","bl","gr","dr","st","dm","ut","qa","pl",IgnoreCase = $true)]
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the environment of the host being registered with the Octopus instance. <pr,bl,gr,dr,st,dm,ut,qa,pl>")]
    [string]$environ,
    [ValidateSet("wb","as","db","sl","mp","pl",IgnoreCase = $true)] 
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the role of the host being registered with the Octopus instance - this parameter can accept multiple values separated by comma (,). <wb,as,db,tk,utility>")]
    [string[]]$role,
    [ValidateLength(36,36)]
    [ValidatePattern("API-")]
    [Parameter(Mandatory=$true,
    HelpMessage="Enter the api key of the service account being used to register this Octopus Tentacle.")]
    [string]$apikey,
    [ValidatePattern("https://")]
    [Parameter(Position=0,Mandatory=$true,
    HelpMessage="Enter the server reference to the Octopus Instance you are registering this Tentacle with (i.e. `"https://networkforgood.octopus.app`").")]
    [string]$server,
    [Parameter(Mandatory=$true,
    HelpMessage="Enter the name of the space within the instance that you wish to register this Octopus Tentacle (i.e. `"Dot Net`").")]
    [string]$spacename,
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the -teardown switch if you are reprovisioning. No other switches are needed if the -teardown switch is specified.")]
    [switch]$teardown
)

# Octopus Tentacle should already be installed, however...just in case. 
$regPath = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"
<# Install Tentacle via chocolatey (easily managed updates)
choco install octopusdeploy.tentacle -y
if ($env:PATH -notcontains 'C:\Program Files\Octopus Deploy\Tentacle') {
    $env:PATH = $env:PATH + ";C:\Program Files\Octopus Deploy\Tentacle;"
    set-ItemProperty -Path $regPath -Name PATH -Value $env:PATH
}


$environ = "dr"
$role = "dc"
$apikey = "<api-key>"
$server = "https://networkforgood.octopus.app"
$spacename = "Dot Net"
#>

if (!($teardown)) {
    # Tentacle configuration
    set-location "C:\Program Files\Octopus Deploy\Tentacle"
    tentacle create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config"
    tentacle new-certificate --instance "Tentacle" --if-blank
    tentacle configure --instance "Tentacle" --reset-trust
    tentacle configure --instance "Tentacle" --app "C:\Octopus\Applications" --port "10933" --noListen "True"
    tentacle polling-proxy --instance "Tentacle" --proxyEnable "False" --proxyUsername "" --proxyPassword "" --proxyHost "" --proxyPort ""
    write-host "Registering $env:COMPUTERNAME with Octopus server..."
    tentacle register-with --instance "Tentacle" --server $server --name $env:COMPUTERNAME --comms-style "TentacleActive" --force --server-comms-port "10943" --apiKey $apikey --space $spacename --environment $environ --role $role --policy "Default Machine Policy"
    tentacle service --instance "Tentacle" --install --stop --start
}

if ($teardown) {
    tentacle deregister-from --server $server --apiKey $apikey --instance "Tentacle" --space $spacename
    choco uninstall octopusdeploy.tentacle -y
    Stop-Service -Name "OctopusDeploy Tentacle" -Force
}