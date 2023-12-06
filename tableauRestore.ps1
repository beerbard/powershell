# Author: Eric Stevens for Network for Good
# Date: 4/29/2021

# This script is intended to perform a full provision and restore of Tableau Server.
# Setup user must be part of local administrators group 

# 1. Server Provision (if presented in parameters)
# 2. If no server provision, check target server has adequate resources:
    # 64 bit
    # 8-core CPU
    # 32 GB RAM
    # 50 GB free disk space
# 3. Open local firewall ports (if not disabled by policy; new provisions):
    # 80 - Gateway
    # 443 - SSL
    # 8850 - Tableau Services Manager
    # 8060 - PostgreSQL database
    # 8061 - PostgreSQL backup verification port
    # 8000-9000 - Dynamic port mapping
    # 27000-27009 - License services (on license service node)
# 4. Disable scanning of Tableau directories by AV (new provisions)
# 5. Install chocolatey if it is not already installed. 
# 6. Install tsm via chocolatey
# 7. Upgrade tsm
# 8. 

# Set initial variables from parameters
param (
    #[Parameter( ValueFromPipeline=$true,
    #    ValueFromPipelineByPropertyName=$true,
    #    ParameterSetName="ServerNames",
    #    HelpMessage="List of computer names separated by commas.")]
    #[Alias('hosts')] 
    #[string[]]$computers = 'localhost',    
        
    #[Parameter( Mandatory=$false,
    #    HelpMessage="Write to error log file or not.")]
    #[switch]$errorlog,
    #[Parameter(Mandatory=$true, 
    #    HelpMessage="Client for example OK = O client, BK = B client")]
    #[string]$client,
    [Parameter(Mandatory=$false,
        HelpMessage="Specify the newInstall parameter if the intention is a fresh install of the latest versions of Tableau Server, Prep Building and Server Management.`n
        Omitting this parameter will result in an upgrade of Tableau services to the latest version.")]
    [string]$newInstall = $false,
    [Parameter(Mandatory=$false,
        HelpMessage="Product key is required for server initialization for new installs/restores. Please include the key string with the key parameter.")]
    [string]$key,
    [Parameter( Mandatory=$false,
        HelpMessage="Path to backup settings directory and repository files if other than default - omit trailing backslash.")] 
    [string]$tsbakPath = "C:\ProgramData\Tableau\Tableau Server\data\tabsvc\files\backups",
    [Parameter( Mandatory=$false,
        HelpMessage="Specify to restore from backup post-install.")] 
    [string]$restore       
)

# Pre-execution Validation
if ($newInstall -and !$key) {
    write-host "For new installs of Tableau Server, the key parameter must also be provided. Run -h to get more details.`n"
    break script
}
if (!$newInstall -and $key) {
    write-host "The newInstall parameter was not specified, though a product key was. Script will proceed with upgrade as the assumed install type. Provided key will be ignored.`n"
}
if (!$newInstall){
    $installed = test-path -Path "C:\ProgramData\Tableau\Tableau Server\data"
    if (!$installed) {
        Write-host "Tableau services are not installed on this computer. Please re-run and include the newInstall and key parameters. Exiting...`n"
        break script
    }
}
if ($newInstall){
    if ($restore) {
        write-host "You have chosen to perform a new install with a restore. Your backup files are expected to be located at:`n
        $tsbakPath"
    } else {
        write-host "You have chosen to do a fresh install of Tableau Server, Service Manager, tabcmd, and Prep Builder.`n"
    }
}
# End of pre-execution validation

if ($newInstall) {
    # Set firewall rules if firewall is enabled
    # Get-NetFirewallProfile -policystore activestore

    # write-host $domainFW
    # get-itemproperty $domin
    # if ($domainFW -eq "False") {
    #    New-NetFirewallRule -DisplayName 'HTTP-Inbound' -Profile @('Domain', 'Private') -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('80', '443')
    # }
    Write-host "Skipping firewall configuration. Refer to documentation to manually configure."
    choco install tableau-server -y
    choco install tableau-server-management-master -y
    choco install tableau-server-tabcmd -y
    choco install tabluau-prep-builder -y

    # Activate product key
    & C:\Windows\System32\where.exe tsm > C:\ProgramData\Tableau\tsm_location.txt
    $tsm_loc = get-content C:\ProgramData\Tableau\tsm_location.txt | where-object { $_ -match "$env:TABLEAU_SERVER_DATA_DIR_VERSION" }
    & $tsm_loc licenses activate -k $key
    & $tsm_loc start
}

if (!$newInstall) {
    $scriptsFolderObject = get-childitem -path "C:\Program Files\Tableau\Tableau Server\packages" -filter "scripts.*" | sort-object -property LastWriteTime | select-object -last 1
    $scriptsFolderName = $scriptsFolderObject.ToString()
    $versionString = ($scriptsFolderName).Trim("scripts.")
    
    & "C:\Program Files\Tableau\Tableau Server\packages\scripts.$versionString\upgrade-tsm.cmd"
    & "C:\Program Files\Tableau\Tableau Server\packages\scripts.20214.21.1217.2252\upgrade-tsm.cmd"
    & "C:\Program Files\Tableau\Tableau Server\packages\scripts.20211.21.0511.0935\upgrade-tsm.cmd"
    & C:\Windows\System32\where.exe tsm > C:\ProgramData\Tableau\tsm_location.txt
    $tsm_loc = get-content C:\ProgramData\Tableau\tsm_location.txt | where-object { $_ -match "$env:TABLEAU_SERVER_DATA_DIR_VERSION" }
    & $tsm_loc start
}

# Tableau server does not start on its own.
& $tsm_loc start

# generate a template to edit for registration if needed (not part of script - more for reference)
# & $tsm_loc register --template > C:\ProgramData\Tableau\tableau-reg-file.json

# edit template with registration information and create registration info json
# All install tyes require registration.
$reg_data = "
{
    ""zip"" : ""20036"",
    ""country"" : ""USA"",
    ""city"" : ""Washington DC"",
    ""last_name"" : ""Gu"",
    ""industry"" : ""Business/Finance"",
    ""eula"" : ""yes"",
    ""title"" : ""VP Technology"",
    ""phone"" : ""2026271640"",
    ""company"" : ""Network for Good"",
    ""state"" : """",
    ""department"" : ""Engineering"",
    ""first_name"" : ""Jing"",
    ""email"" : ""nfg.sre.admin@networkforgood.com""
}"
$reg_file = new-item C:\ProgramData\Tableau\tableau-reg-file.json -itemtype File -Force
set-content $reg_file $reg_data

# Pass registration file to the Tableau server
& $tsm_loc register --file C:\ProgramData\Tableau\tableau-reg-file.json

choco install tableau-prep-builder -y
choco install tableau-server-management-master -y

if ($restore) {    

    write-host "Restoring settings from backup...`n"
    # Import settings from backup
    if (!Test-Path -path "$tsbakPath\tableau_settings_backup.json") {
        write-host "Settings .json file is not in the expected location ($tsbakPath) - please ensure .json and .tsbak are located in that location or specify the location of the files by using the tsbakPath parameter."
    } else {
        tsm settings import -f "$tsbakPath\tableau_settings_backup.json"
    }
}

# Restart Tableau
& $tsm_loc restart


# Restore repository data (.tsbak)

# Restore authentication options

# Site customizations

# Enable access to PostgreSQL repositry
