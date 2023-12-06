<#  Name: ServerInstall
    Author: Eric Stevens
    Owner: Network for Good (Bonterra)
    Date of last major revision: 6/29/2022

    Purpose: This script is intended to be a universal initial configuration script for Windows servers in the NFG 
    application stack. It should only be run on Windows servers of the as/wb/wb-comp/util roles. Other servers may 
    needs bits and pieces of this script, but those will have to be cherry-picked and run manually. 
    - Installs chocolatey and auto-installs essential packages per role
    - Installs and configures SQL and IIS
    - Adds server to targets in NFG Octopus Deploy instance
    - Updates timezone
    - Installs appropriate agents for New Relic monitoring where required

    Execution:
        serverInstall.ps1 -roles <"wb","as","db","tk","utility"> -environ <"pr","bl","gr","dr","ut","sb","st","qa","dv"> -inf <"aws","azure","contegix"> [-update]>
        i.e. $>.\serverInstall.ps1 -roles "wb" -environ "qa" -inf "azure"

    Current state -
        * LoggingModule is not working properly - logentry statements are erroring.
#>

param (
    [ValidateSet("wb","as","db","sl","mp","pl",IgnoreCase = $true)]   
    [Parameter(Mandatory=$false,
           HelpMessage="Select the role(s) of the server you are deploying (wb, as, db, sl, mp, pl) - this parameter can accept multiple values separated by comma (,).")]
    [string[]]$roles,
    [ValidateSet("pr","bl","gr","dr","st","dm","ut","qa","pl",IgnoreCase = $true)]
    [Parameter(Mandatory=$false,
           HelpMessage="Select the environmenment we be part of (pr, bl, gr, dr, st, dm, ut, qa, dv).")]
    [string]$environ,
    [ValidateSet("aws","azure","contegix",IgnoreCase = $true)]
    [Parameter(Mandatory=$false,
           HelpMessage="Select the infrastructure the server resides in (Default: aws, azure, contegix).")]
    [string]$inf,
    [Parameter(Mandatory=$false,
           HelpMessage="Specify the -update switch if you wish to simply update the server. No other params are required when the -update switch is provided.")]
    [switch]$update
 )

# Define prod envs for any actions that are scoped to prod only (clustering features, security features, etc.)
$prodEnvs = 'pr','bl','gr','dr'

# Usage: logEntry -Comment [-alertMessage] "This is the log message."
# Returns: 2021.08.19      14:24:10        This is the log message.

    # Import logging module
    C:\NFG\Scripts\LoggingModule.ps1 -logEnv $environ -scriptName ($Script:MyInvocation.MyCommand.Name -replace '\..*')
    <#Usage: logEntry -Comment "This is the log message." [-alertMessage] 
    Returns: 
        2021.08.19      14:24:10        This is the log message.
    Note: to send a log email, a function will have to be inserted at the end of the script - this script is specifically designed to send via SocketLabs mail service:
    sendAlertEmail -recipient "<Enter recipient email here>" -SLserverID "43303" -SLAPIKey "b4A5Kty2D7QkTa68FrYz
    #>

# Registry path to env:path var
$regPath = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"

# Set PS Configs
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module PSWindowsUpdate -Force
Update-Help -ErrorAction SilentlyContinue

# Disable Windows Firewall - traffic regulation is handled at the NSG level in Azure.
Set-NetFirewallProfile -Enabled False

if (!($update)) {
    
    # Ensure scripts folder exists
    mkdir "C:\NFG\Scripts" -Force -ErrorAction SilentlyContinue

    # Set time-zone for web and app servers only. DB servers should be UTC.
    
    logentry -comment "Setting timezone for all servers..."
    $TimeZone = "US Eastern Standard Time"
    Invoke-Expression "tzutil.exe /s `"$TimeZone`""
    logentry -comment "Timezone successfully set. Continuing..."
    

    # Enable Windows Task Scheduler logging
    logentry -comment "Enabling task scheduler logging..."
    C:\Windows\System32\wevtutil.exe set-log Microsoft-Windows-TaskScheduler/Operational /enabled:true

    # Security Configurations
    # Verify TLS 1.2+ is available
    $key12 = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 1.2'
    logentry -comment "Testing to ensure TLS 1.2 is available before deprecating less secure propocols..."
    if (!(Test-Path $key12)) {
        # Test for Client TLS configuration and enable if explicitly disabled
        if (Test-Path "$key12\Client") {
            $client12 = Get-ItemProperty "$key12\Client"
            if ($client12 -and $client12.DisabledByDefault -ne 0 -or $client12.Enabled -eq 0) {
                logentry -comment "TLS Client 1.2 explicitly disabled. Enabling TLS Client 1.2..."
                set-itemproperty -Path "$key12\Client" -Name DisabledByDefault -value 0
                set-itemproperty -Path "$key12\Client" -Name Enabled -value 1
                logentry -comment "TLS Client 1.2 has been successfully enabled. Proceding..."
            } else { 
                logentry -comment "TLS 1.2 has been explicitly enabled. Proceding..."
            }
        } else {
            logentry -comment "TLS Client 1.2 has not been explicitly defined, thus it is enabled. Proceding..."
        }
        # Test for Server TLS configuration and enable if explicitly disabled
        if (Test-Path "$key12\Server") {
            $server12 = Get-ItemProperty "$key12\Server"
            if ($server12 -and $server12.DisabledByDefault -ne 0 -or $server12.Enabled -eq 0) {
                logentry -comment "TLS Server 1.2 explicitly disabled. Enabling TLS Server 1.2..."
                set-itemproperty -Path "$key12\Server" -Name DisabledByDefault -value 0
                set-itemproperty -Path "$key12\Server" -Name Enabled -value 1
                logentry -comment "TLS Server 1.2 has been successfully enabled. Proceding..."
            } else { 
                logentry -comment "TLS 1.2 has been explicitly enabled. Proceding..."
            }
        } else {
            logentry -comment "TLS Server 1.2 has not been explicitly defined, thus it is enabled. Proceding..."
        }
    } else {
        logentry -comment "TLS 1.2 is not explicitly defined, thus enabled. Proceding to deprecate TLS < 1.2..."
    }

    # Disable TLS 1.1 and 1.0
    $protocolsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
    logentry -comment "Disabling TLS < 1.2 for both server and client in $protocolsKey..."

    if (!(Test-Path "$protocolsKey\SSL 1.1")) {
        logentry -comment "Creating SSL 1.1 key..."
        New-Item -Path $protocolsKey -Name "SSL 1.1"
    }
    if (!(Test-Path "$protocolsKey\SSL 1.1\Client")) {
        logentry -comment "Creating SSL 1.1\Client key"
        New-Item -Path "$protocolsKey\SSL 1.1" -Name "Client"
    }
    if (!(Test-Path "$protocolsKey\SSL 1.1\Server")) {
        logentry -comment "Creating SSL 1.1\Server key"
        New-Item -Path "$protocolsKey\SSL 1.1" -Name "Server"
    }
    logentry -comment "Adding DWORD value Enabled=0 for SSL 1.1 Client and Server keys..."
    set-itemproperty -Path "$protocolsKey\SSL 1.1\Client" -Name Enabled -value 0
    set-itemproperty -Path "$protocolsKey\SSL 1.1\Server" -Name Enabled -value 0

    if (!(Test-Path "$protocolsKey\SSL 1.0")) {
        logentry -comment "Creating SSL 1.0 key..."
        New-Item -Path $protocolsKey -Name "SSL 1.0"
    }
    if (!(Test-Path "$protocolsKey\SSL 1.0\Client")) {
        logentry -comment "Creating SSL 1.0\Client key"
        New-Item -Path "$protocolsKey\SSL 1.0" -Name "Client"
    }
    if (!(Test-Path "$protocolsKey\SSL 1.0\Server")) {
        logentry -comment "Creating SSL 1.0\Server key"
        New-Item -Path "$protocolsKey\SSL 1.0" -Name "Server"
    }
    logentry -comment "Adding DWORD value Enabled=0 for SSL 1.0 Client and Server keys..."
    set-itemproperty -Path "$protocolsKey\SSL 1.0\Client" -Name Enabled -value 0
    set-itemproperty -Path "$protocolsKey\SSL 1.0\Server" -Name Enabled -value 0
    
    #Instruct asp.net 4.x apps to use Secure TLS by default
    logentry -comment "Configuring asp.net 4.x 32/64 bit apps to use Secure TLS by default..."
    if (!(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -ErrorAction SilentlyContinue)){
        logentry -comment  "setting HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319\SchUseStrongCrypto to 1"
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
    }

    if (!(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -ErrorAction SilentlyContinue)){
        logentry -comment  "setting HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319\SchUseStrongCrypto to 1"
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
    }

    # Set audit policy for Logon to success and failure 
    logentry -comment "Ensuring audit plicies for Logon is set for Success and Failure..."
    auditpol /set /subcategory:Logon /success:enable /failure:enable

    # Check for ceritificate authorities
    logentry -comment "Verifying Digicert CA certs are installed for CrowdStrike compatibility..."
    $certs = Get-ChildItem -Path Cert:\LocalMachine\AuthRoot | Where-Object -FilterScript { $_.Subject -eq 'CN=DigiCert High Assurance EV Root CA, OU=www.digicert.com, O=DigiCert Inc, C=US' -or $_.Subject -contains 'CN=DigiCert Assured ID Root CA, OU=www.digicert.com, O=DigiCert Inc, C=US' }

    <# This SHOULD return the following table:

    Thumbprint                                  Subject
    ----------                                  -------
    5FB7EE0633E259DBAD0C4C9AE6D38F1A61C7DC25    CN=DigiCert High Assurance EV Root CA, OU=www.digicert.com, O=DigiCert Inc, C=US
    0563B8630D62D75ABBC8AB1E4BDFB5A899B24D43    CN=DigiCert Assured ID Root CA, OU=www.digicert.com, O=DigiCert Inc, C=US

    Get count of $certs - if count < 2, throw error.#>

    if ($certs.Count -lt 2) {
        logentry -comment "The Digicert Trusted Root CAs are not present. Downloading via filestream and installing to Cert:\LocalMachine\Root..."
        [Net.ServicePointManager]::SecurityProtocol = 'tls12, tls'
        (New-Object System.Net.WebClient).DownloadFile("https://www.digicert.com/CACerts/DigiCertHighAssuranceEVRootCA.crt", "$env:TEMP\DigiCertHighAssuranceEVRootCA.crt")
        (New-Object System.Net.WebClient).DownloadFile("https://dl.cacerts.digicert.com/DigiCertAssuredIDRootCA.crt", "$env:TEMP\DigiCertAssuredIDRootCA.crt")
        Import-Certificate -CertStoreLocation Cert:\LocalMachine\Root -FilePath "$env:TEMP\DigiCertHighAssuranceEVRootCA.crt"
        Import-Certificate -CertStoreLocation Cert:\LocalMachine\Root -FilePath "$env:TEMP\DigiCertAssuredIDRootCA.crt"
    } else {
        logentry -comment "Certs are checking out good...moving on to Actice Dirctory provisions if required..."
    }
    
    # Testing for Chocolatey
    logentry -comment "Checking for Chocolatey installation..."
    if (test-path -path C:\ProgramData\chocolatey\bin\choco.exe) {
        logentry -comment "Chocolately is already installed! Proceding..."
    } else {
        logentry -comment "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        logentry -comment "Chocolatey successfully installed."

        # Create daily update scheduled task
        logentry -comment "Creating daily choco upgrade -all task..."
        New-Item "C:\tools\chocoUpgradeAll.ps1" -ItemType File -Value "choco upgrade all -y" -force
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument C:\tools\chocoUpgradeAll.ps1
        $trigger = New-ScheduledTaskTrigger -Daily -At 10pm
        # for tasks that do not require network auth, use LOCALSERVICE
        $user = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount -RunLevel Highest
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Chocolatey daily upgrades" -Description "This task runs choco upgrade daily at 10pm" -Principal $user
        logentry -comment "Upgrade task successfully created. Proceding..."
    }

    # Ensure any parameters passed are remembered by chocolatey for upgrades. 
    choco feature enable -n=useRememberedArgumentsForUpgrades

    logentry -comment "Installing default chocolatey apps..."
    # Install standard apps
    choco install dotnetfx -y 
    # choco install sysinternals -y 
    choco install 7zip -y
    choco install notepadplusplus -y
    choco install googlechrome -y
    choco install win-acme -y
    # choco install winscp -y

    # Install command line tools for target environment
    logentry -comment "Installing command line tools for target environment..."
    if ($inf -eq "azure" -and $roles -contains "util") {
        choco install azurestorageexplorer -y
    }
    if ($inf -eq "azure") {
        choco install azure-cli -y 
        choco install azcopy10 -y 
    }
    if ($inf -eq "aws") {
        choco install awstools.powershell -y
        choco install awscli -y
    }

    # Install role-specific applications
    if ($roles -contains "util") {
        choco install rsat -y
        choco install sql-server-management-studio -y
    }

    if ($roles -contains "db") {
        logentry -comment "Installing failover clustering for DB server role..."
        Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
        # choco install sql-server-2019 -y # Installs MSSQL Server 2019 Developer Edition (Free)
        # Join-SqlAvailabilityGroup -Path "SQLSERVER:\SQL\SecondaryServer\InstanceName" -Name "NFGQAWSQLFC01"
        # after NfgGP is created - most applicable on restore. 
        # C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regsql.exe -d NfgGP -ssadd -sstype c -E
    }

    if ($roles -contains "db") {

        # Specific to dwlite location
        mkdir "C:\NFG\SfDataRetriever\Csv" -ErrorAction SilentlyContinue
        New-SmbShare -Name "SfDataRetriever" -Path "C:\NFG\SfDataRetriever" -FullAccess "Everyone" -ErrorAction SilentlyContinue
        
    }

    if ($roles -contains "wb" -or $roles -contains "as" -or $roles -contains "sl" -or $roles -contains "db") {
        choco install winrar -y
        
        # Install .net on dapp servers
        $NetFeatures = "NET-WCF-Services45","NET-Framework-45-ASPNET","NET-Framework-Features","NET-Framework-45-CORE"
        Install-WindowsFeature -Name $NetFeatures
    }

    if ($roles -contains "wb" -or $roles -contains "as") {

        # Install Octopus Deploy Tentacle - configuration is called after provisioning
        logentry -comment "Installing Octopus Deploy Tentacle and setting PATH to include .exe location..."
        choco install octopusdeploy.tentacle -y
        $env:PATH = $env:PATH + ";C:\Program Files\Octopus Deploy\Tentacle;"
        set-ItemProperty -Path $regPath -Name PATH -Value $env:PATH
            
        # Install web services
        logentry -comment "Installing IIS web services and .Net features..."
        $IISFeatures = "Web-WebServer","Web-Common-Http","Web-Log-Libraries","Web-Request-Monitor","Web-Default-Doc","Web-Dir-Browsing","Web-Http-Errors","Web-Static-Content","Web-Http-Redirect","Web-Health","Web-Http-Logging","Web-Custom-Logging","Web-Log-Libraries","Web-ODBC-Logging","Web-Performance","Web-Stat-Compression","Web-Security","Web-Filtering","Web-Basic-Auth","Web-CertProvider","Web-Client-Auth","Web-Digest-Auth","Web-Cert-Auth","Web-IP-Security","Web-Url-Auth","Web-Windows-Auth","Web-App-Dev","Web-Net-Ext","Web-Net-Ext45","Web-AppInit","Web-Asp","Web-Asp-Net","Web-Asp-Net45","Web-CGI","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Includes","Web-WebSockets","Web-Mgmt-Tools","Web-Mgmt-Console"
        Install-WindowsFeature -Name $IISFeatures

        Import-Module WebAdministration -Force

        $WinFeatures = "Web-Scripting-Tools"
        Install-WindowsFeature $WinFeatures
        # Just in case the base image has Web DAV Publishing enabled
        logentry -comment "Checking for Web-DAV-Publishing and removing if it exists..."
        Remove-WindowsFeature -Name Web-DAV-Publishing
        
        logentry -comment "Installing IIS modules microsoft WSE and URL Rewrite 2.0 post-IIS installation..."
        choco install microsoftwse -y
        choco install urlrewrite -y
        choco install reportviewer2010sp1 -y # Check to see if the scope of this can be reduced.
        

        # Add server level web config to log actual c-ip
        logentry -comment "Adding server level web config to log actual c-ip as X-Forwarded-For by default..."
        Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/logFile/customFields" -name "." -value @{logFieldName='X-Forwarded-For';sourceName='X-Forwarded-For';sourceType='RequestHeader'} -ErrorAction SilentlyContinue
        logentry -comment "Removing default sites and app pools..."
        Remove-Website -Name "Default Web Site"
        $defaultAppPools = @('.NET v2.0','.NET v2.0 Classic','.NET v4.5','.NET v4.5 Classic','Classic .NET AppPool','DefaultAppPool')
        Foreach ($defaultAppPool in $defaultAppPools){
            IF (Test-path -path "IIS:\AppPools\$defaultAppPool"){Remove-WebAppPool -name $DefaultAppPool}
        }

        <# Set app pool CPU limits
        Import-Module WebAdministration
        $appPoolName = "IdentityServer"
        $appPool = Get-Item "IIS:\AppPools\$appPoolName"
        $appPool.cpu.limit = 90
        $appPool.cpu.action = "ThrottleUnderLoad"
        $appPool.cpu.resetInterval = "00:01:00"
        $appPool | Set-Item #>

        # add C:\Windows\Microsoft.NET\Framework64\v4.0.30319 to the path to be able to run aspnet_regsql.exe to register session db (NfgGP).
        # after NfgGP is created (the instance name has to be resolvable via AD):
        #    C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regsql.exe -d NfgGP -ssadd -sstype c -E
    }
    
    if ($roles -contains "sl") {
     
        # Temp
        # $environ = "dr"

        # Enable access to SMB shares and MSMQ queues via CNAME from localhost.
        $smbRegPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
        new-itemproperty -Path $smbRegPath -Name DisableStrictNameChecking -PropertyType dword -value 1 -Force
        new-itemproperty -Path $smbRegPath -Name SrvAllowedServerNames -PropertyType MultiString -Value @("sl.$environ.internal.networkforgood.org","msmq.$environ.internal.networkforgood.org","$env:COMPUTERNAME.$environ.internal.networkforgood.org") -Force

        $msvRegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0'
        new-itemproperty -Path $msvRegPath -Name BackConnectionHostNames -PropertyType MultiString -Value @("sl.$environ.internal.networkforgood.org","msmq.$environ.internal.networkforgood.org","$env:COMPUTERNAME.$environ.internal.networkforgood.org") -Force

        # Configure GPG
        choco install gpg4win --version=2.2.1 -y
        choco pin add --name="'gpg4win'" --version="'2.2.1'" -y
        mkdir -path "c:\NFG\GPG\Data\GPGKeys" -Force -ErrorAction SilentlyContinue
        [Environment]::SetEnvironmentVariable("GNUPGHOME","C:\NFG\GPG\Data\GPGKeys","Machine")

        # Create system shares
        mkdir "C:\NFG\BAFFOutputFiles" -ErrorAction SilentlyContinue
        New-SmbShare -Name "BAFFOutputFiles" -Path "C:\NFG\BAFFOutputFiles" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\CheckReissueReport" -ErrorAction SilentlyContinue
        mkdir "C:\NFG\CheckReissueReport\CheckReissueErrors" -ErrorAction SilentlyContinue
        New-SmbShare -Name "CheckReissueReport" -Path "C:\NFG\CheckReissueReport" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\IRSRevocationSharedData" -ErrorAction SilentlyContinue
        New-SmbShare -Name "IRSRevocationSharedData" -Path "C:\NFG\IRSRevocationSharedData" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\BatchFiles" -ErrorAction SilentlyContinue
        New-SmbShare -Name "BatchFiles" -Path "C:\NFG\BatchFiles" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\Resources" -ErrorAction SilentlyContinue
        New-SmbShare -Name "Resources" -Path "C:\NFG\Resources" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\PaypalReportOutput\SampleReports" -ErrorAction SilentlyContinue
        mkdir "C:\NFG\PaypalReportOutput\SFTP" -ErrorAction SilentlyContinue
        New-SmbShare -Name "PaypalReportOutput" -Path "C:\NFG\PaypalReportOutput" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\CheckRecon\Completed" -ErrorAction SilentlyContinue
        mkdir "C:\NFG\CheckRecon\CompletedWithError" -ErrorAction SilentlyContinue
        mkdir "C:\NFG\CheckRecon\Failed" -ErrorAction SilentlyContinue
        New-SmbShare -Name "CheckRecon" -Path "C:\NFG\CheckRecon" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\Recon\Braintree\Processed" -ErrorAction SilentlyContinue
        mkdir "C:\NFG\Recon\Braintree\Unprocessed" -ErrorAction SilentlyContinue
        New-SmbShare -Name "Recon" -Path "C:\NFG\Recon" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\Packages" -ErrorAction SilentlyContinue
        New-SmbShare -Name "Packages" -Path "C:\NFG\Packages" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\Assets\skin" -ErrorAction SilentlyContinue
        mkdir "C:\NFG\Assets\dn2" -ErrorAction SilentlyContinue
        mkdir "C:\NFG\Assets\v4" -ErrorAction SilentlyContinue
        New-SmbShare -Name "Assets" -Path "C:\NFG\Assets" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        mkdir "C:\NFG\VGS" -ErrorAction SilentlyContinue

        # Create MSMQ Queues and set ACLs to Everyone having FullControl

        New-MsmqQueue -Name "nfg_admin" -QueueType Private -Label "private$\nfg_admin" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_devhook_request" -QueueType Private -Label "private$\nfg_devhook_request" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_report_admin" -QueueType Private -Label "private$\nfg_report_admin" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_report_request" -QueueType Private -Label "private$\nfg_report_request" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_report_response" -QueueType Private -Label "private$\nfg_report_response" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_request" -QueueType Private -Label "private$\nfg_request" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_response" -QueueType Private -Label "private$\nfg_response" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_v4_queue" -QueueType Private -Label "private$\nfg_v4_queue" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl
        New-MsmqQueue -Name "nfg_v4dmsfreetrialqueue" -QueueType Private -Label "private$\nfg_v4dmsfreetrialqueue" | Set-MsmqQueueAcl -UserName "Everyone" -Allow FullControl

    }

    if ($roles -contains "ft") {
        mkdir "F:\FTPData\Production\nfgcheckrecon" -ErrorAction SilentlyContinue
        mkdir "F:\FTPData\Sandbox\nfgcheckrecon" -ErrorAction SilentlyContinue

        mkdir "F:\FTPData\Production\DNRPFCT" -ErrorAction SilentlyContinue
        mkdir "F:\FTPData\Sandbox\DNRPFCT" -ErrorAction SilentlyContinue


        New-SmbShare -Name "FTPData" -Path "F:\FTPData" -FullAccess "Everyone" -ErrorAction SilentlyContinue

        
    }
}

$update = $true
if ($update) {
    choco upgrade all -y
}

# Finish Windows Update install
# logentry -comment "Running Windows Update after all other installs are complete..."
# Set PS Configs
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module PSWindowsUpdate -Force
Update-Help -ErrorAction SilentlyContinue
$updates = Get-WindowsUpdate
Write-Host "Updates Found: $Updates.Count" 
if ($Updates.Count -gt 0) { Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot; $updateStatus = Get-WURebootStatus }
if ($updateStatus.RebootRequired -eq $true) { Restart-Computer -force } 


# Send email notification (from LoggingModule.ps1)
sendAlertEmail -recipient "eric.stevens@bonterratech.com" -SLserverID "43303" -SLAPIKey "b4A5Kty2D7QkTa68FrYz"