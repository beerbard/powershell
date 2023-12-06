$role = "web"
$env = "st"

# Install New Relic agent per role (app vs SQL)
if ($role -ne 'util') { # Utility servers don't currently need to be in New Relic
    # Install the latest NR CLI
    [Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; (New-Object System.Net.WebClient).DownloadFile('https://download.newrelic.com/install/newrelic-cli/scripts/install.ps1', $env:TEMP + '\install.ps1'); & $env:TEMP\install.ps1;
    if ((test-path -path c:\SQLServerFull) -and $role -eq 'db') {
        [Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; (New-Object System.Net.WebClient).DownloadFile('https://github.com/newrelic/newrelic-cli/releases/latest/download/NewRelicCLIInstaller.msi', $env:TEMP + '\NewRelicCLIInstaller.msi'); msiexec.exe /qn /i $env:TEMP\NewRelicCLIInstaller.msi | Out-Null; $env:NEW_RELIC_API_KEY='NRAK-IYSZRAPFLJDC9OR9NMW0S9CXE83'; $env:NEW_RELIC_ACCOUNT_ID='3126071'; & 'C:\Program Files\New Relic\New Relic CLI\newrelic.exe' install -n mssql-server-integration-installer
    } else { # For app servers - Must happen AFTER a .net site is running
        [Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; (New-Object System.Net.WebClient).DownloadFile('https://github.com/newrelic/newrelic-cli/releases/latest/download/NewRelicCLIInstaller.msi', $env:TEMP + '\NewRelicCLIInstaller.msi'); msiexec.exe /qn /i $env:TEMP\NewRelicCLIInstaller.msi | Out-Null; $env:NEW_RELIC_API_KEY='NRAK-IYSZRAPFLJDC9OR9NMW0S9CXE83'; $env:NEW_RELIC_ACCOUNT_ID='3126071'; & 'C:\Program Files\New Relic\New Relic CLI\newrelic.exe' install 
    } 

    # Refresh the powershell profile to add support for the newly-installed newrelic-cli
    . $PROFILE

    # Add tagging in NR using newrelic-cli (newrelic.exe)

    # Find newrelic.exe path
    $newrelic = & where.exe newrelic
    if ($newrelic) {
        # Create local newrelic-cli connection profile
        & $newrelic profile add --profile dotnet --region us --apiKey NRAK-IYSZRAPFLJDC9OR9NMW0S9CXE83 --accountId 3126071 --licenseKey 436e35610f698e1956875cad2f0c0a4b1adbNRAL
    
        # Set profile as default
        & $newrelic profile default --profile dotnet

        $role = "web"
        $env = "pr"

        $hosts = "469ewwb01", "469ewwb02", "469ewwb04", "469ewwb05", "469ewwb06"
        # Query NR to get the data of the host entity
            # $env: PS var array is not compatible with cmd, so convert to traditional var. 
            # $hostname = $env:COMPUTERNAME
        foreach ($hostname in $hosts) {
        $entity = & $newrelic entity search --name $hostname | ConvertFrom-Json

        # Delete the custom tags of the entity just in case the server is being repurposed. 
        & $newrelic entity tags delete --guid $entity.guid --tag env --tag role

        # Add tags to `$entity.guid retrieved from ^^^ (unlike deleting tags, one tag per call)
        & $newrelic entity tags create --guid $entity.guid --tag env:$env
        & $newrelic entity tags create --guid $entity.guid --tag role:$role
        }
    }
}