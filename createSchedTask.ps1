# Author: Eric Stevens
# Owner: Network for Good
# Last revision date: 7/29/2021

New-Item "C:\tools\chocoUpgradeAll.ps1" -ItemType File -Value "choco upgrade all -y" -force
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument C:\tools\chocoUpgradeAll.ps1
$trigger = New-ScheduledTaskTrigger -Daily -At 10pm
# for tasks that do not require network auth, use LOCALSERVICE
$user = New-ScheduledTaskPrincipal -UserId "LOCALSERVICE" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Chocolatey daily upgrades" -Description "This task runs choco upgrade daily at 10pm" -Principal $user
