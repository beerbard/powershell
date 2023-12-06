# Install and configure Puppet agent #
if ($env -eq "sandbox") {$pServer = "<puppet host FQDN>"}
if ($env -eq "production") {$pServer = "<puppet host FQDN>"}
choco install puppet -y
New-Item "$env:ProgramData\PuppetLabs\puppet\etc\csr_attributes.yaml" -itemtype file -value "#challengePassword`ncustom_attributes:`n1.2.840.113549.1.9.7: `"ttWpbvqc6LUglTKeLg4lNmuAOUp18wo`"" -force
$puppetConfig= (get-content $env:ProgramData\PuppetLabs\puppet\etc\puppet.conf) -join "`n"
$puppetConfig = $puppetConfig -replace "server=puppet", "server=$pServer"
Set-Content $env:ProgramData\PuppetLabs\puppet\etc\puppet.conf "$puppetConfig"
Add-Content $env:ProgramData\PuppetLabs\puppet\etc\puppet.conf "[agent]`ncertname = $env:COMPUTERNAME.$env:USERDNSDOMAIN"