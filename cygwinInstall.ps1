write-host = "Checking for dependencies...`n"
if (test-path -path C:\ProgramData\chocolatey) {
    write-host "Chocolatey is installed...continuing...`n"
}

# Install git
choco install git -y

# Testing for Cygwin
write-host "Checking for Cygwin...`n"
if (test-path -path C:\cygwin64) {
    write-host "Cygwin has already been installed manually to C:\Cygwin64`n"
} elseif (test-path -path C:\Tools\cygwin\cygwin.bat) {
    write-host "Cygwin has already been installed via Chocolatey to C:\Tools\cygwin`n"
} else {
    Write-host "Attempting to install Cygwin from Chocolatey...`n"
    choco install cyg-get -y
        
    write-host "Cygwin has been successfully installed to C:\Tools\cygwin.`nInstalling basic packages using cyg-get...`n"
    cyg-get install wget make cmake gcc-core gcc-g++ openssl openssl-devel libcurl-devel libxml2-devel libiconv-devel cygutils-extra asciidoc xsltproc
    write-host "The base cygwin packages have been installed...setting environment variables...`n"

    # Set path to include cygwin install location
    $regPath = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"
    if (!($env:PATH | Select-String -Pattern "cygwin")){$env:PATH = $env:PATH + "; C:\Tools\cygwin; C:\Tools\cygwin\bin"}
    set-ItemProperty -Path $regPath -Name PATH -Value $env:PATH
    
    # Put any additional system variables here - cygwin packages might require system variables to be defined to execute from command line.
    # Set-Variable CYGWIN=OPENSSL_ROOT_DIR:C:\Tools\cygwin\bin

    write-host "Environment variables set."
}