# Testing for Chocolatey
write-host "Checking for Chocolatey installation..."
if (test-path -path C:\ProgramData\chocolatey\bin\choco.exe) {
    write-host "Chocolately is already installed!"
} else {
    Write-host "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

choco install octopusdeploy.tentacle -y
Set-Location "C:\Program Files\Octopus Deploy\Tentacle"
.\Tentacle.exe create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config"
.\Tentacle.exe new-certificate --instance "Tentacle" --if-blank
.\Tentacle.exe configure --instance "Tentacle" --reset-trust
.\Tentacle.exe configure --instance "Tentacle" --app "C:\Octopus\Applications" --port "10933" --noListen "True"
.\Tentacle.exe polling-proxy --instance "Tentacle" --proxyEnable "False" --proxyUsername "" --proxyPassword "" --proxyHost "" --proxyPort ""
write-host "Registering $env:COMPUTERNAME with Octopus server..."
.\Tentacle.exe register-with --instance "Tentacle" --server "https://networkforgood.octopus.app" --name $env:COMPUTERNAME --comms-style "TentacleActive" --force --server-comms-port "10943" --apiKey "<api-key>" --space "Dot Net" --environment "dr" --role "wb" --policy "Default Machine Policy"
.\Tentacle.exe service --instance "Tentacle" --install --stop --start

