# Default install of New Relic to Dot-Net account #

[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls'; (New-Object System.Net.WebClient).DownloadFile("https://github.com/newrelic/newrelic-cli/releases/latest/download/NewRelicCLIInstaller.msi", "$env:TEMP\NewRelicCLIInstaller.msi"); msiexec.exe /qn /i $env:TEMP\NewRelicCLIInstaller.msi | Out-Null; $env:NEW_RELIC_API_KEY='NRAK-IYSZRAPFLJDC9OR9NMW0S9CXE83'; $env:NEW_RELIC_ACCOUNT_ID='3126071'; & 'C:\Program Files\New Relic\New Relic CLI\newrelic.exe' install