Set-ExecutionPolicy Bypass -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Import-Module WebAdministration
$TimeZone = "US Eastern Standard Time"
Invoke-Expression "tzutil.exe /s `"$TimeZone`""

# Install Chocolatey if it doesn't exist #
."./chocolateyInstall.ps1"


# Install and configure Puppet agent #
# ."./puppetInstall.ps1"

# Define system path registry location #
$regPath = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"

##### Replace site identities after sysprep (identies are tied to RSA keys) - replace by automatic deploys striggered from Octopus #####

# Identity Variables #
$_user = "domain\username"
$_pass = "<password>"

# Update service account principles #
Set-ItemProperty IIS:\AppPools\<appPoolName> -name processModel -value @{userName=$_user;password=$_pass;identitytype=3}
# Continue to set idnetites for all applicable app pools.

# Create Local FTP User #
**** Needs script ****

# Add Developers AD group to Local Administrators group if DevVM - identified by identifying string in  #
if ($env:COMPUTERNAME | Select-String -Pattern "AZDEVWVM") {$domainUser = "<DevelopersADGroup>"; $localGroup = "Administrators"; ([ADSI]"WinNT://$env:COMPUTERNAME/$localGroup,group").psbase.Invoke("Add",([ADSI]"WinNT://$env:USERDOMAIN/$domainUser").path)}
# Add QA AD Group to Administrators group if Feature Sandbox VM #
if (!($env:COMPUTERNAME | Select-String -Pattern "AZDEVWVM")) {$domainUser = "<QAADGroup>"; $localGroup = "Administrators"; ([ADSI]"WinNT://$env:COMPUTERNAME/$localGroup,group").psbase.Invoke("Add",([ADSI]"WinNT://$env:USERDOMAIN/$domainUser").path)}

# Delete Old Cert #
$certSubject = "<certCN>"
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match $certSubject } | Remove-Item

# Import New Cert from existing certificate - only used when a certain cert is requred, not for host auth #
$certPass = ConvertTo-SecureString -String "<pfxPassword>" -Force -AsPlainText # Should use secure password store to retrieve passwords rather than declaring here. 
Import-PfxCertificate -Exportable -FilePath <# path to existing cert #> C:\Tools\CertificateDeploymentTools\$certSubject.pfx -CertStoreLocation cert:\localMachine\my -Password $certPass

# Grant Permission to Keys #
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match $certSubject }
$rsaFile = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
$keyPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
$fullPath = $keyPath+$rsaFile
$acl = (Get-Item $fullPath).GetAccessControl('Access')
$buildAcl = New-Object System.Security.AccessControl.FileSystemAccessRule("AvidXchange\Domain Users","Read","Allow")
$acl.AddAccessRule($buildAcl)
Set-Acl $fullPath $acl

# Install Octopus Tentacle #
#choco uninstall octopusdeploy.tentacle --version 3.12.8 --force -y # Tentacle should start out uninstalled inn the GoldVM.
if (!($env:COMPUTERNAME | Select-String -Pattern "AZDEVWVM")) {choco install octopusdeploy.tentacle --version 3.12.8 --force -y}
if (!($env:COMPUTERNAME | Select-String -Pattern "AZDEVWVM")) {if (!($env:PATH | Select-String -Pattern "Tentacle")){$env:PATH = $env:PATH + ";C:\Program Files\Octopus Deploy\Tentacle";Set-ItemProperty -Path ‘Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment’ -Name PATH -Value $env:PATH}}
if (!($env:COMPUTERNAME | Select-String -Pattern "AZDEVWVM")) {Tentacle.exe create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle\Tentacle.config" --console; Tentacle.exe new-certificate --instance "Tentacle" --if-blank --console; Tentacle.exe configure --instance "Tentacle" --reset-trust --console; Tentacle.exe configure --instance "Tentacle" --home "C:\Octopus" --app "E:\AvidXchange\Applications" --port "10933" --console; Tentacle.exe configure --instance "Tentacle" --trust "A46304CE6D9110C8DCD237B4463031637E5B4017" --console}
if (!($env:COMPUTERNAME | Select-String -Pattern "AZDEVWVM")) {if ($(netsh advfirewall firewall show rule $rulename) -like "No rules match the specified criteria.*") {netsh advfirewall firewall add rule $rulename dir=in action=allow protocol=TCP localport=10933} else {Write-Host "Octopus Firewall rule already exists."}}
if (!($env:COMPUTERNAME | Select-String -Pattern "AZDEVWVM")) {Tentacle.exe register-with --instance="Tentacle" --server="http://octopus.avidxchange.com" --apiKey="API-TSYK8N6EPG8R0J8L5OKCT3ARYO" --role="AvidPay-Web" --role="AvidPay-Neuron" --environment="Development" --name="$env:COMPUTERNAME" --comms-style=TentaclePassive --console; Tentacle.exe service --instance "Tentacle" --install --start --console}


# Unnstall Octopus Tentacle #
#Tentacle.exe deregister-from --instance="Tentacle" --server="http://octopus.avidxchange.com" --apiKey="<api-key>" --console
#choco uninstall octopusdeploy.tentacle --version 3.12.8 --force -y # Tentacle should start out uninstalled inn the GoldVM.

# Git Clone to C:\Projects - AVIDPAY ONLY!!!! #
$gitRoot = "C:\Git"
if (Get-Item $gitRoot -ErrorAction SilentlyContinue) {Get-ChildItem C:\Git -recurse | remove-item -recurse -force} else {new-item $gitRoot -type directory}
set-location $gitRoot
git clone http://GitCloneSVC:W89hDr$742!7@tfs.avidxchange.com:8080/tfs/defaultcollection/_git/avidxchange-pay
git clone http://tfs.avidxchange.com:8080/tfs/defaultcollection/_git/avidxchange-pay
set-location $gitRoot\avidxchange-pay
git checkout develop

# Reassign Site PhysicalPaths - AVIDPAY ONLY!!! #
#Import-Module WebAdministration
#$gitRoot = "C:\Git"
#Set-ItemProperty 'IIS:\Sites\AvidPay\' -name physicalPath -value "$gitRoot\avidxchange-pay\Source"
#Set-ItemProperty 'IIS:\Sites\AvidPay\AvidPay.Web' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\AvidPay\AvidPay.Web"
#Set-ItemProperty 'IIS:\Sites\AvidPay\AvidPay.Api' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\AvidPay\AvidPay.Api"
#Set-ItemProperty 'IIS:\Sites\AvidInternal' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\AvidXchange.Internal"
#Set-ItemProperty 'IIS:\Sites\AvidXchange.AvidPayApi\' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\AvidXchange.AvidPayApi\AvidXchange.AvidPayApi"
#Set-ItemProperty 'IIS:\Sites\AvidXchange.Internal.Api\' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\AvidXchange.Internal.Api"
#Set-ItemProperty 'IIS:\Sites\AvidXchange.Internal.Api.V2\' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\AvidXchange.Internal.AvidPayApi\AvidXchange.Internal.AvidPayApi"
#Set-ItemProperty 'IIS:\Sites\PaymentProcessor\' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\ESB\AvidPay.ESB\AvidPay.ESB.PaymentProcesser"
#Set-ItemProperty 'IIS:\Sites\PaymentProcessor.V2\' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\ESB\AvidPay.ESB\AvidPay.ESB.PaymentProcesser.V2"
#Set-ItemProperty 'IIS:\Sites\VendorManagement.Service\' -name physicalPath -value "$gitRoot\avidxchange-pay\Source\VendorManagement\VendorManagement.Service\VendorManagement.Service"

# Add bindings for external sites FOR SANDBOX ONLY - These sites should be externalized #
$appEnv = "AvidPay"
if ($appEnv -eq "AvidPay") {New-WebBinding -Name "AvidInternal" -IPAddress "*" -Port 80 -HostHeader internal.$env:COMPUTERNAME.avidxchange.com}
if ($appEnv -eq "AvidPay") {New-WebBinding -Name "AvidPay" -IPAddress "*" -Port 80 -HostHeader avidpay.$env:COMPUTERNAME.avidxchange.com}
if ($appEnv -eq "AvidPay") {New-WebBinding -Name "AvidLogin" -IPAddress "*" -Port 80 -HostHeader login.$env:COMPUTERNAME.avidxchange.com}
if ($appEnv -eq "AvidPay") {New-WebBinding -Name "AvidXchange.Internal.Api" -IPAddress "*" -Port 80 -HostHeader internalapi.$env:COMPUTERNAME.avidxchange.com}
if ($appEnv -eq "AvidPay") {New-WebBinding -Name "AvidXchange" -IPAddress "*" -Port 80 -HostHeader servicelayer.$env:COMPUTERNAME.avidxchange.com}
if ($appEnv -eq "AvidPay") {New-WebBinding -Name "AvidSuite" -IPAddress "*" -Port 80 -HostHeader app.$env:COMPUTERNAME.avidxchange.com}
if ($appEnv -eq "AvidPay") {New-WebBinding -Name "AvidXchange.CDN" -IPAddress "*" -Port 80 -HostHeader cdn.$env:COMPUTERNAME.avidxchange.com}

# Test fot *.<hostname>.avidxchange.com alias to be in DNS - email support if it's not #
if (!(test-connection -computername avidpay.$Computer.avidxchange.com -count 4 -quiet)) {Invoke-Command -computername prhvopsapp01 -scriptblock {Send-MailMessage -To "appops@avidxchange.com" -From "no-reply@avidxchange.com" -Subject "* CNAME required for $Computer.avidxchange.com" -Body "Connection test to the hostnames for:`n`n$Computer.avidxchange.com`n`n...did not succeed. Please create a wildcard CNAME alias for the host." -SmtpServer "mail.avidxchange.com"} -credential $env:USERDOMAIN\$env:USERNAME}

#### Reference these hostnames in the AvidPay.config vars ####
$payConfig = (get-content C:\Projects\AvidPay\Main\Lib\Config\avidpay.configuration.xml) -join "`n"
$payConfig = $payConfig -replace "localhost.avidxchange.com", "$env:COMPUTERNAME.avidxchange.com"
Set-Content C:\Projects\AvidPay\Main\Lib\Config\avidpay.configuration.xml "$payConfig"

#### Reference these hostnames in the AVIDSUITE config vars ####
$suiteMelConfig = (get-content C:\Projects\AvidSuite\Main\Lib\Config\enterpriselibrary.config) -join "`n"
$suiteMelConfig = $suiteMelConfig -replace "localhost.avidxchange.com", "$env:COMPUTERNAME.avidxchange.com"
Set-Content C:\Projects\AvidSuite\Main\Lib\Config\enterpriselibrary.config "$suiteMelConfig"

#### added to GoldVM - One time provision ####

# Install URL Rewrite #
#choco install urlrewrite -y

# Disable UAC #
#New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force

# WinRM and PS-Remoting #
#& cmd.exe /c 'winrm quickconfig -q'
#& cmd.exe /c 'winrm set winrm/config/winrs @{MaxMemoryPerShellMB="512"}'
#& cmd.exe /c 'winrm set winrm/config @{MaxTimeoutms="180000"}'
#& cmd.exe /c 'winrm set winrm/config/service @{AllowUnencrypted="true"}'
#& cmd.exe /c 'winrm set winrm/config/service/auth @{Basic="true"}'
#& cmd.exe /c 'sc config WinRM start=auto'
#Enable-PSRemoting -force

# Application packages #
#choco install NugetPackageExplorer -y
#choco install Nuget.CommandLine -y
#New-Item "env:ProgramFiles(x86)\NuGet\NuGetDefaults.config" -itemtype file -value "<?xml version=`"1.0`" encoding=`"utf-8`"?><configuration><packageSources><add key=`"avidxchange`" value=`"http://nexus.avidxchange.com/repository/nuget-all/`" /></packageSources></configuration>" -force
#choco install microsoft-build-tools --version 14.0.25420.1 -y # Microsoft Build Tools 2015 Update 3
#choco install git -y
#choco install carbon --version 2.5.0 -y
#choco install powershell --version 5.1.14409.20170510 -y
#choco install googlechrome -y
#choco install conemu -y
choco install dotnet-4.6.2 -y
choco install beyondcompare -y

# Install Redis #
#choco install redis-64 --version 3.0.503 -y
#choco install redis-desktop-manager -y
#uninstall-service -name redis
#$redisConfig = (get-content "C:\Program Files\Redis\redis.windows-service.conf") -join "`n"
#$redisConfig = $redisConfig -replace "dir ./", "dir ./redis6379"
#$redisConfig = $redisConfig -replace "port 6379", "port 6379"
#$redisConfig = $redisConfig -replace "syslog-ident redis", "syslog-ident redis6379"
#Set-Content "C:\Program Files\Redis\redis.windows-service-6379.conf" "$redisConfig"
New-Item -ItemType directory "C:\Program Files\Redis\Redis6379"
#Install-Service -Name Redis6379 -Path "C:\Program Files\Redis\redis-server.exe --service-run redis.windows-service-6379.conf" -Username NetworkService -DisplayName "Redis 6379" # Needs to use service config NOT named after the service. 
# OR #
#& cmd.exe /c "sc.exe create Redis6379 obj= `"NT AUTHORITY\NetworkService`" start= auto DisplayName= `"Redis6379`" binPath= `"C:\Program Files\Redis\redis-server.exe --service-run redis.windows-service-6379.conf`""

# RabbitMQ 3.6.10 and Erlang 19.3 #
$env:ERLANG_SERVICE_MANAGER_PATH = "$env:ProgramFiles\erl8.3\erts-8.3\bin"
$env:ERLANG_HOME = "$env:ProgramFiles\erl8.3"
$env:RABBITMQ_SERVER = "$env:ProgramFiles\RabbitMQ Server\rabbitmq_server-3.6.10"
$env:RABBITMQ_BASE = "$env:ProgramData\RabbitMQ"
if (!($env:PATH | Select-String -Pattern "erl8.3")){$env:PATH = $env:PATH + ";$env:ProgramFiles\erl8.3\erts-8.3\bin"}
if (!($env:PATH | Select-String -Pattern "RabbitMQ")){$env:PATH = $env:PATH + ";$env:RABBITMQ_SERVER\sbin"}
set-ItemProperty -Path $regPath -Name PATH -Value $env:PATH
choco install Erlang --version 19.3 --force -y
choco install RabbitMQ --version 3.6.10 -y --force --params="/RABBITMQBASE:$env:RABBITMQ_BASE"
New-Item "$env:RABBITMQ_BASE\enabled_plugins" -itemtype file -value "[rabbitmq_management,rabbitmq_management_agent,rabbitmq_management_visualiser,rabbitmq_tracing]." -force
$cip = (Get-NetIPConfiguration).IPv4Address.IPAddress
New-Item "$env:RABBITMQ_BASE\rabbitmq.config" -itemtype file -value "[{rabbit,[{auth_backends,[rabbit_auth_backend_internal]},{tcp_listen_options,[binary,{packet,raw},{reuseaddr,true},{backlog,512},{nodelay,true},{linger,{true,0}},{exit_on_close,false}]},{tcp_listeners,[{`"$cip`",5672}]},{handshake_timeout,30000},{log_levels,[{connection,info},{channel,info}]},{vm_memory_high_watermark,0.75},{default_vhost,<<`"/`">>},{default_user,<<`"AvidX`">>},{default_pass,<<`"password`">>},{default_permissions,[<<`".*`">>,<<`".*`">>,<<`".*`">>]},{default_user_tags,[administrator]}]},{kernel,[]},{rabbitmq_management,[{listener,[{port,15672}]}]}]." -force
New-Item "$env:RABBITMQ_BASE\rabbitmqadmin.conf" -itemtype file -value "[default]port=15672" -force
copy-item C:\Windows\.erlang.cookie $env:USERPROFILE\.erlang.cookie -force
# All RabbitMQ installs - Add default admin user #
rabbitmqctl add_user AvidX password
rabbitmqctl set_user_tags AvidX administrator
rabbitmqctl set_permissions -p / AvidX ".*" ".*" ".*"
rabbitmqctl set_permissions -p AvidXchange AvidX ".*" ".*" ".*"
rabbitmqctl set_permissions -p NeuronAvidPay AvidX ".*" ".*" ".*"

# AvidXchange vHosts #
#rabbitmqctl add_vhost AvidXchange
#rabbitmqctl add_vhost NeuronAvidPay

# Add AvidPay vHost user #
#rabbitmqctl add_user AvidPaySVC password
#rabbitmqctl set_permissions -p AvidXchange AvidPaySVC "^avidpaysvc-.*" ".*" ".*"

# Add AvidPay Neuron user #
#rabbitmqctl add_user NeuronAvidPaySVC password
#rabbitmqctl set_user_tags NeuronAvidPaySVC administrator # Neuron requires adminstrator tag to connect to instance via Neuron Explorer
#rabbitmqctl set_permissions -p NeuronAvidPay NeuronAvidPaySVC ".*" ".*" ".*"

# Add MuleESB vHost user #
#rabbitmqctl add_user MuleESBSVC password
#rabbitmqctl set_permissions -p MuleESB MuleESBSVC "^muleesbsvc-.*" ".*" ".*"

$rulename = "name=RabbitMQ" 
if ($(netsh advfirewall firewall show rule $rulename) -like "No rules match the specified criteria.*") {netsh advfirewall firewall add rule $rulename dir=in action=allow protocol=TCP localport=5672} else {Write-Host "RabbitMQ firewall rule already exists."}
$rulename = "name=RabbitMQ Management Console" 
if ($(netsh advfirewall firewall show rule $rulename) -like "No rules match the specified criteria.*") {netsh advfirewall firewall add rule $rulename dir=in action=allow protocol=TCP localport=15672} else {Write-Host "Rabbit Management Console firewall rule already exists."}
$rulename = "name=Erlang Port Mapper Daemon" 
if ($(netsh advfirewall firewall show rule $rulename) -like "No rules match the specified criteria.*") {netsh advfirewall firewall add rule $rulename dir=in action=allow protocol=TCP localport=4369} else {Write-Host "Erlang Port Mapper Daemon firewall rule already exists."}
	



# To Do #

#2.)	servicelayer webservice API is missing in the IIS configured websites
#4.)	The bank account API is not functional (I belive its missing the servicelayer webservice API above in #2)
