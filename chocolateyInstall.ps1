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
