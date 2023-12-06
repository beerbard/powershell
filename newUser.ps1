
$createCmd = "net user nfg-sre-admin <password> /domain /add"
$addCmd = "net group 'Domain Admins' nfg-sre-admin /add"
cmd.exe /C $createCmd
cmd.exe /C $addCmd

az vm run-command invoke --command-id RunPowerShellScript --name PRT-DC01 -g nfg-partner-rg --scripts "param([string]$arg1,[string]$arg2) Write-Host 'This is a sample script with parameters $arg1 and $arg2'" --parameters "arg1=somefoo" "arg2=somebar"

Get-AzVMRunCommand -ResourceGroupName nfg-partner-rg -VMName PRT-DC01
