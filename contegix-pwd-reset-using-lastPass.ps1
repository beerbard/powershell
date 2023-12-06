<#
This application is intended to simplify the process of resetting account passwords in the Contegix enviroment. This is required because:
1. Users require access to applications that are hosted in the production Contegix environment. 
2. Those applications are not exposed externally for regulatory reasons. 
3. The enterprise system is not connected to the production environment, also for regulatory reasons. 
4. User accounts are created and maintained in active directory.
5. User accounts are synced to OpenVPN, which is managed by the hosting company.
6. Users have no way to change their own passowrds since they do not have rights to access platforms. 
7. Passwords expire and users have to manually request a reset from the hosting company. 

The proposed steps for this automation:
1. A scheduled task will be created on a utility server to execute a powershell script that will query AD for accounts with expired passwords.
2. The script will reset the user's password and unlock the user's account if necessary. 
3. For each expired password, powershell will leverage the lastpass-cli utility (LastPass is a local requirment) to create a LastPass entry in the lastpass account for the nfg.sre.admin user. 
4. Powershell will then invoke the lastpass-cli utility to share the password object with the affected user(s).
5. Powershell will invoke the lastpass-cli utility to purge passowrd objects from the nfg.sre.admin account that are older than two weeks. 

#>

# Query AD for users with exired passwords. Get cn,userPrincipalName,logonCount,lastLogonTimestamp,pwdLastSet,telephoneNumber,mail,description

$OUPath = 'OU=MultiFactorOnlyUsers,DC=NFGPROD,DC=org'
$expUsers = Get-ADUser -SearchBase $OUpath -Properties * -Filter * | where-object { $_.PasswordExpired -eq $true } | `
Select-object cn,userPrincipalName,PasswordExpired,logonCount,@{Name=”LastLogon”;Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},@{Name=”pwdLastSet”;Expression={[DateTime]::FromFileTime($_.pwdLastSet)}},telephoneNumber,mail,description
$expUsers | format-table cn,userPrincipalName,PasswordExpired,logonCount,@{Name=”LastLogon”;Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},@{Name=”pwdLastSet”;Expression={[DateTime]::FromFileTime($_.pwdLastSet)}},telephoneNumber,mail,description
#$ExportPath = 'c:\MFAUsers.csv'
#$expUsers | Export-csv -NoType $ExportPath

# Check to see if Chocolatey and LastPass-cli is installed. If it is not installed, halt and send an email to nfg.sre.admin accompanied by a list of users that have an expired password. 

# Install Chocolatey if not already installed.
."./chocolateyInstall.ps1"

#Testing for Cygwin
if (test-path -path C:\ProgramData\chocolatey\bin\Cygwin.exe) {
    $lastPassInstalled = $true
} else {
    $lastPassInstalled = $false
    Write-host "Warning: Cygwin is not installed to the expected location (C:\ProgramData\chocolatey\bin\Cygwin.exe). Cygwin is the Win/Lin environment on which lastpass-cli runs. Chocolatey will now attempt to install Cygwin..."
    choco install cyg-get -y
    # cygwin is installed to C:\Tools\cygwin. Set path to include that and the \bin folder in the registry.
    # var = get path from registry; set var = var + "; path; path"; set path in registry = var 
    
    # Install the dependency packages using

    # Set the env vars that are required IN THE REGISTRY

    Set-Variable CYGWIN=OPENSSL_ROOT_DIR:C:\Tools\cygwin\bin
}

#Testing for lastpass-cli
if (test-path -path C:\ProgramData\chocolatey\bin\Cygwin.exe) {
    $lastPassInstalled = $true
} else {
    $lastPassInstalled = $false
    choco instll git -y
    mkdir c:\ProgramData\LastPass
    Set-Location c:\ProgramData\LastPass
    git clone https://github.com/lastpass/lastpass-cli.git
    Cygwin make

}


# If lastpass-cli is installed, for each expired password, query AD to update each user's password and unlock account. Use lastpass-cli to generate secure password. 
if ($lastPassInstalled -eq $true) {
    foreach ($user in $expUsers) {
        write-hsot $_.Name
    
    }





}

# Generate a LastPass entry for nfg.sre.admin for the user with the new password. 


# Using the lastpass-cli, share the password item with the user and send an email. 
