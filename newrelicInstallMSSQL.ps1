# Due to the restrictive policy on the DB servers, New relic has to be installed "manually" on DB servers. 
# This script must be executed ON each DB server with a user with SA access. 

# Download New Relic Infrastructure installer. 
write-host "Downloading New Relic Infrastructure agent installer...`n"
[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls'; 
(New-Object System.Net.WebClient).DownloadFile("https://download.newrelic.com/infrastructure_agent/windows/newrelic-infra.msi", "$env:TEMP\newrelic-infra.msi");
write-host "Agent has been downloaded to $env:TEMP.`n"

# Download New Relic 



write-host "Creating basic log.yml file...`n"
New-Item "C:\Program Files\New Relic\newrelic-infra\logging.d\logs.yml" -ItemType File -Value "logs:
  - name: windows-security
    winlog:
      channel: Security
      collect-eventids:
      - 4740
      - 4728
      - 4732
      - 4756
      - 4735
      - 4624
      - 4625
      - 4648

  - name: windows-application
    winlog:
      channel: Application" -Force
write-host "Log.yml created.`n"

# Prepare MSSQL for New Relic integtration. SQL login needs to be create and user rights need to be assigned. 
# sqlcmd 

# Install mssql integration.
msiexec.exe /qn /i C:\Users\estevens\Downloads\nri-mssql-amd64.msi
