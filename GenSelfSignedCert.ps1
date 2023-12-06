#SCRIPT SAMPLE TITLE - Generate Self-signed Certificates
  
#AUTHOR - Adam Conkle - Microsoft Corporation
  
#VERSION - 1.1
  
   
  
$ErrorActionPreference = "SilentlyContinue" 
    
#write header
Write-Host "`n WARNING: This script sample is provided AS-IS with no warranties and confers no rights." -ForegroundColor Yellow 
Write-Host "`n This script sample will generate self-signed certificates with private key" 
Write-Host " in the Local Computer Personal certificate store." 
  
#find out how many certs they want to self-sign
[int]$Iterations = 1 # Read-Host "`n How many certificates would you like to generate?" 
$ContextAnswer = "C" # Read-Host "`n Store certificates in the User or Computer store? (U/C)"
If ($ContextAnswer -eq "U") {
    $machineContext = 0
    $initContext = 1
}
ElseIF ($ContextAnswer -eq "C") {
    $machineContext = 1
    $initContext = 2
}
Else {
    Write-Host "`n Invalid selection. Exiting`n`n" -ForegroundColor Red
    Exit
}
  
For ($Count = 1; $Count -le $Iterations; $Count++) {
  
    $Subject = $env:computername # Read-Host "`n Enter the Subject for certificate `#$Count" 
    #Generate cert in local computer My store
    $name = new-object -com "X509Enrollment.CX500DistinguishedName.1" 
    $name.Encode("CN=$Subject", 0)
    $key = new-object -com "X509Enrollment.CX509PrivateKey.1" 
    $key.ProviderName = "Microsoft RSA SChannel Cryptographic Provider" 
    $key.KeySpec = 1
    $key.Length = 2048
    $key.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)" 
    $key.MachineContext = $machineContext
    $key.ExportPolicy = 1
    $key.Create()
    $ekuoids = new-object -com "X509Enrollment.CObjectIds.1" 
    $NothingAnsweredYes = $true 
    While ($NothingAnsweredYes) {
        Write-Host "`n Add Enhanced Key Usage `(EKU`) by answering Y/N to the following`:" 
        $AddServerAuth = "N" # Read-Host " Server Authentication?" 
        $AddClientAuth = "Y" # Read-Host " Client Authentication?" 
        $AddSmartCardAuth = "N" # Read-Host " Smart Card Authentication?" 
        $AddEFS = "N" # Read-Host " EFS?" 
        $AddCodeSigning = "N" # Read-Host " Code Signing?" 
        If (($AddServerAuth -eq "Y") -or ($AddClientAuth -eq "Y") -or ($AddSmartCardAuth -eq "Y") -or ($AddEFS -eq "Y") -or ($AddCodeSigning -eq "Y")) {
            $NothingAnsweredYes = $false 
        }
        If ($NothingAnsweredYes) {
            Write-Host "`n You must select at least one EKU for certificate `#$Count." 
        }
        If ($AddServerAuth -eq "Y") {
            $serverauthoid = new-object -com "X509Enrollment.CObjectId.1" 
            $serverauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.1")
            $ekuoids.add($serverauthoid)
        }
        If ($AddClientAuth -eq "Y") {
            $clientauthoid = new-object -com "X509Enrollment.CObjectId.1" 
            $clientauthoid.InitializeFromValue("1.3.6.1.5.5.7.3.2")
            $ekuoids.add($clientauthoid)
        }
        If ($AddSmartCardAuth -eq "Y") {
            $smartcardoid = new-object -com "X509Enrollment.CObjectId.1" 
            $smartcardoid.InitializeFromValue("1.3.6.1.4.1.311.20.2.2")
            $ekuoids.add($smartcardoid)
        }
        If ($AddEFS -eq "Y") {
            $efsoid = new-object -com "X509Enrollment.CObjectId.1" 
            $efsoid.InitializeFromValue("1.3.6.1.4.1.311.10.3.4")
            $ekuoids.add($efsoid)
        }
        If ($AddCodeSigning -eq "Y") {
            $codesigningoid = new-object -com "X509Enrollment.CObjectId.1" 
            $codesigningoid.InitializeFromValue("1.3.6.1.5.5.7.3.3")
            $ekuoids.add($codesigningoid)
        }
    }
    $ekuext = new-object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1" 
    $ekuext.InitializeEncode($ekuoids)
    $cert = new-object -com "X509Enrollment.CX509CertificateRequestCertificate.1" 
    $cert.InitializeFromPrivateKey($initContext, $key, "")
    $cert.Subject = $name 
    $cert.Issuer = $cert.Subject
    $cert.NotBefore = get-date 
    $cert.NotAfter = $cert.NotBefore.AddDays(1825)
    $cert.X509Extensions.Add($ekuext)
    $cert.Encode()
    $enrollment = new-object -com "X509Enrollment.CX509Enrollment.1" 
    $enrollment.InitializeFromRequest($cert)
    $certdata = $enrollment.CreateRequest(0)
    $enrollment.InstallResponse(2, $certdata, 0, "")
}

Write-Host "`n`tFinished`n" -ForegroundColor Green
  
##################################

$thumb = Get-ChildItem -Path "Cert:\LocalMachine\My" | select-object Subject,Thumbprint | where-object {$_.Subject -eq 'CN=nfg-dr-wvm-wb02'}
$hostinfo = '@{Hostname="' + $env:computername + '"; CertificateThumbprint="' + $Thumb.Thumbprint + '"}'
winrm create winrm/config/Listener?Address=*+Transport=HTTPS $hostinfo
Enable-PSRemoting