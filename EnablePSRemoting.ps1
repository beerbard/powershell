$SubID = "<SubID>" 
$RgName = "nfg-partner-rg" 
$VmName = "PRT-DC01" 
$Location = "East US" 

Connect-AzAccount 
Select-AzSubscription -SubscriptionId $SubID 
Set-AzVMAccessExtension -ResourceGroupName $RgName -Location $Location -VMName $VmName -Credential (get-credential) -typeHandlerVersion "2.1" -Name VMAccessAgent
















Publisher       MicrosoftWindowsServer