# Author: Eric Stevens
# Owner: Network for Good
# Last major revision date: 8/17/2021

# 8.1.4 Observe user accounts to verify that
#   any inactive accounts over 90 days old
#   are either removed or disabled
# 8.1.6 Limit repeated access attempts by locking out the user ID after not more than six attempts
# 8.1.7 Set the lockout duration to a minimum of 30 minutes or until an administrator enables the user ID
# 8.1.8 If a session has been idle for more than 15 minutes, require the user to re-authenticate to re-activate the terminal or
#   session.
# 8.2.3 Passwords/passphrases must meet the following:
#   • Require a minimum length of at least seven characters.
#   • Contain both numeric and alphabetic characters
# 8.2.4 Change user passwords/passphrases at least once every 90 days
# 8.2.5 Do not allow an individual to submit a new password/passphrase that is the same as any of the last four
#   passwords/passphrases he or she has used.

$date = get-date -Format "yyyyMMdd"
$reportFilePath = "C:\ADPolicyAudit-$date.txt"


"8.1.4 Observe user accounts to verify that any inactive accounts over 90 days old are either removed or disabled.`n" | tee-object -Filepath $reportFilePath
"`tGetting a list of active user accounts that have exceeded the 90-day last logon threshold that have NOT been disabled.`n" | tee-object -Filepath $reportFilePath -Append

$OUPath = 'OU=MultiFactorOnlyUsers,DC=NFGPROD,DC=org'
# $ExportPath = 'c:\MFAUsers.csv'

$cutoff = $date.AddDays(-90)
Get-ADUser -Filter * -SearchBase $OUpath -properties cn,userPrincipalName,logonCount,lastlogondate,lastLogonTimestamp,pwdLastSet,telephoneNumber,mail,description,userAccountControl | `
where-object {$_.lastlogondate -le $cutoff -and $_.userAccountControl -ne "514"} | `
Select-object cn,userPrincipalName,logonCount,@{Name=”LastLogon”;Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},@{Name=”pwdLastSet”;Expression={[DateTime]::FromFileTime($_.pwdLastSet)}},telephoneNumber,mail,description,userAccountControl | `
Format-List | tee-object -FilePath C:\temp.txt -Append

#Export-csv -NoType $ExportPath -force

$domain = "nfgprod.org"
$rootDSE = Get-ADRootDSE -Server $domain

"8.1.6 Limit repeated access attempts by locking out the user ID after not more than six attempts.`n" | tee-object -Filepath $reportFilePath -Append

Get-ADObject $rootDSE.defaultNamingContext -Property lockoutThreshold | Select-object @{n="PolicyType";e={"Account Lockout Attempts"}},DistinguishedName,lockoutThreshold | `
Format-List | tee-object -FilePath $reportFilePath -Append

"8.1.7 Set the lockout duration to a minimum of 30 minutes or until an administrator enables the user ID.`n" | tee-object -Filepath $reportFilePath -Append

Get-ADObject $rootDSE.defaultNamingContext -Property lockoutDuration, lockoutObservationWindow | Select-object @{n="PolicyType";e={"Account Lockout Duration and Window"}},DistinguishedName,`
@{n="lockoutDuration";e={"$($_.lockoutDuration / -600000000) minutes"}},`
@{n="lockoutObservationWindow";e={"$($_.lockoutObservationWindow / -600000000) minutes"}} | `
Format-List | tee-object -Filepath $reportFilePath -Append

"8.1.8 If a session has been idle for more than 15 minutes, require the user to re-authenticate to re-activate the terminal or session`n" | tee-object -Filepath $reportFilePath -Append

"*** Requires Code ***`n" | tee-object -Filepath $reportFilePath -Append


"8.2.3 Passwords/passphrases must meet the following:
    • Require a minimum length of at least seven characters.
    • Contain both numeric and alphabetic characters.`n" | tee-object -Filepath $reportFilePath -Append

Get-ADObject $RootDSE.defaultNamingContext -Property DistinguishedName, minPwdLength, pwdProperties | `
Select-object @{n="PolicyType";e={"Password Complexity"}},`
    DistinguishedName,`
    minPwdLength,`
    @{n="pwdProperties";e={Switch ($_.pwdProperties) {
        0 {"Passwords can be simple and the administrator account cannot be locked out"}
        1 {"Passwords must be complex and the administrator account cannot be locked out"}
        8 {"Passwords can be simple, and the administrator account can be locked out"}
        9 {"Passwords must be complex, and the administrator account can be locked out"}
        Default {$_.pwdProperties}
    }}} | `
    Format-List | tee-object -Filepath $reportFilePath -Append

"8.2.4 Change user passwords/passphrases at least once every 90 days.`n" | tee-object -Filepath $reportFilePath -Append

Get-ADObject $RootDSE.defaultNamingContext -Property DistinguishedName, maxPwdAge | `
Select-object @{n="PolicyType";e={"Max Password Age"}},`
    DistinguishedName,`
    @{n="maxPwdAge";e={"$($_.maxPwdAge / -864000000000) days"}} | `
    Format-List | tee-object -Filepath $reportFilePath -Append

"8.2.5 Do not allow an individual to submit a new password/passphrase that is the same as any of the last four passwords/passphrases he or she has used.`n" | tee-object -Filepath $reportFilePath -Append

Get-ADObject $RootDSE.defaultNamingContext -Property DistinguishedName, pwdHistoryLength | `
Select-object @{n="PolicyType";e={"Password"}},`
    DistinguishedName,`
    pwdHistoryLength | `
    Format-List | tee-object -Filepath $reportFilePath -Append