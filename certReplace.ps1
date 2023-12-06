<# Replace certificates via ACME certs (letsencrypt.com)

Author: Eric Stevens
Owner: Network for Good
Date of last major revision: 3/11/2022

STEPS
0. generate certificate server request from wb06
1. renew cert via digicert using CSR
2. download certificate and upload to Octopus
ON EACH SERVER:
3. install new certificate from each server
4. run IIS cert binding snippet on each server
5. remove old cert
#>

# Gen CSR
<#
.SYNOPSIS
Creates a certificate signing request (CSR) file, which can contain aliases (CNames).
.DESCRIPTION
- Creates a CSR file for a certificate authority, which includes aliases (CNames).
- Alias names need to be comma separated.
- Run the script on the server that hosts the web service (e.g., IIS), since it needs to access the private key storage.
- This uses certreq.exe to transform the input of this script into a well-formed request file.
- For easy usage, the script exposes only the required and a few popular certutil parameters.
.LINK
https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/ff625722(v=ws.10)
.EXAMPLE
$certReqParams = @{
    FQDN                = servername01.nwtraders.msft
    Aliases             = servername01, devmachine, devmachine.nwtraders.msft, 192.168.0.1
    DestinationFilePath = C:\Temp
}
New-CertFileReqWithAlias.ps1 @certReqParams
.PARAMETER FQDN
Requests a certificate for the fully qualified domain name (FQDN) for the system (e.g., a website or a server)
.PARAMETER KeyLength
Length of keys used for encryption; 2048 bits is the standard and default value
.PARAMETER Exportable
Defines exportability of the private key included in the certificate; the default for security reasons is false
.PARAMETER EncryptionAlgorithm
Sets the algorithm used for encryption; the available choices are the most popular according to research
.PARAMETER Aliases
Comma-separated list of alias names (CNames) to include in the certificate;
all names in the list can access the target resource without name-mismatch errors
.PARAMETER DestinationFilePath
Specifies the name and path for the certificate signing request (CSR) file; the name of the CSR file will be FQDN.csr
.INPUTS
None--you cannot pipe objects to New-CertReqWithAlias
.OUTPUTS
PKCS10-formatted CSR file
.NOTES
AUTHOR: Ruben Zimmermann @ruben8z
LASTEDIT: 2018-08-27
REQUIRES: PowerShell Version 4, Windows Management Foundation 4, and at least Windows 7 or Windows Server 2008 R2.
NAME: New-CertFileReqWithAlias
KEYWORDS: certreq, pki, ca, alias
REMARK:
This PS script comes with ABSOLUTELY NO WARRANTY; for details see gnu-gpl. This is free software, and you are welcome to redistribute it under certain conditions; see gnu-gpl for details.

Usage:
$>.\New-CertReqWithAlias.ps1 -FQDN <servername>.networkforgood.org -Aliases "servername,serveralias.nwtraders.msft,serveralias,10.0.0.1" -DestinationFilePath C:\Temp

#>
param(
    [Parameter(Mandatory = $true)]
    [String]$FQDN,
    [Parameter(Mandatory = $false)]
    [ValidateSet(1024,2048,4096)]
    [int]$KeyLength = 2048,
    [Parameter(Mandatory = $false)]
    [ValidateSet('True','False')]
    [string]$Exportable = 'False',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Microsoft RSA SChannel Cryptographic Provider',`
    'Microsoft Enhanced DSS and Diffie-Hellman Cryptographic Provider')]
    [string]$EncryptionAlgorithm = 'Microsoft RSA SChannel Cryptographic Provider',
    [Parameter(Mandatory=$false)]
    [object]$Aliases,
    [Parameter(Mandatory=$true)]
    [string]$DestinationFilePath
)
#region checking_parameters
#Check if the FQDN matches valid syntax
if ($FQDN -notMatch '\w{1,}\.\w{1,}\.?[\w.]*') {
    Write-Warning -Message "The FQDN: $($FQDN) seems to be invalid.`n The expected syntax is host.domain.<optional>"
    exit
}
#Check if aliases match valid syntax
if ($Aliases -notMatch '[\w\.\s,]{1,}') {
    Write-Warning -Message "Aliases: $($Aliases) don't seem to be valid. Use a comma ',' to separate multiple aliases."
    exit
}
#Check if the destination file path exists
if (-not (Test-Path -Path $DestinationFilePath)) {
    Write-Warning -Message "Path: $($DestinationFilePath) does not exist. Please specify a valid path."
    exit
}
#Check if the specified file path has a training backslash; if not, add it.
if ($DestinationFilePath.Substring($DestinationFilePath.Length -1,1) -eq '\') {
    $DestinationFilePath = $DestinationFilePath + $FQDN + '.csr'
} else {
    $DestinationFilePath = $DestinationFilePath + '\' + $FQDN + '.csr'
}
#endregion checking_parameters
#region program_main
<#
    If a comma occurs in an aliases value, 'split' will convert the string
    to an array. Building a valid extensions section requires a loop.
    In case only one value is specified as an alias value, the script will embed it into the required information.
    [System.Environment]::NewLine ensures one alias per line.
#>
if ($Aliases -match ',') {
    $tmpAliases = $Aliases -split ','
    foreach($itmAlias in $tmpAliases) {
        $dnsAliases += '_continue_ = "DNS=' + $itmAlias + '&"' + [System.Environment]::NewLine
    }
} else {
    $dnsAliases = '_continue_ = "DNS=' + $Aliases + '&"' + [System.Environment]::NewLine
}
$certificateINF = @"
[Version]
Signature= '`$Windows NT$'
[NewRequest]
Subject = "CN=${FQDN}"
KeySpec = 1
KeyLength = ${KeyLength}
Exportable = ${Exportable}
MachineKeySet = TRUE
ProviderName = ${EncryptionAlgorithm}
RequestType = PKCS10
KeyUsage = 0xa0
[EnhancedKeyUsageExtension]
OID=1.3.6.1.5.5.7.3.1
[Extensions]
2.5.29.17 = "{text}"
_continue_ = "DNS=${FQDN}&"
${dnsAliases}
"@
<#
[System.IO.Path]::GetTmpFileName() creates a temporary file to store the information of the
certificateINF variable. The operating system will automatically drop it.
#>
$tmpFile        = [System.IO.Path]::GetTempFileName()
$certificateINF | Out-File $tmpFile
& certreq.exe -new $tmpFile $DestinationFilePath

# Send request to DigiCert api to retrieve certificate. 

# Complete the cert request on wb06 

# Export the cert to PFX and make available to other servers - look at uploading to Octopus as well.  

# ---------- Remote/Octopus/Server-side Scripting on Each Host ---------- #

# Install certificate on server

# IIS Version 8.5 and above has an auto-rebind on renewed certs feature. 
    # Find IIS version
    # If version >= 8.5, do the auto-renew feature, if not, pass hashes to do a hash compare. 
$version = get-itemproperty HKLM:\SOFTWARE\Microsoft\InetStp\  | Select-Object MajorVersion
write-host "IIS Version" $version.MajorVersion

if ($version.MajorVersion -ge 8.5) {
    write-host "Note: Versions over 8.5 should use auto rebind. Proceeding..."
} else {write-host "Proceeding to rebind based on hashes..."}

# Hash-based rebind
Import-Module WebAdministration 
Import-Module Microsoft.PowerShell.Utility

function Process-Binding
{
	[CmdletBinding()]
	param
	(
		$binding
	)
	process 
	{
		"    Binding: {0}" -f $binding.bindingInformation
		if ($binding.certificateHash -eq "<<Old Certificate Hash>>")  
		{
			$binding.RemoveSslCertificate();
			$binding.AddSslCertificate("<<New Certificate Hash>>","my") 		}
	}
}

function Process-Site-Bindings 
{
	[CmdletBinding()]
	param
	(
		$website
	)
	process 
	{
		"Site: {0}" -f $website.name
		Get-WebBinding -Name $website.name |  Where-Object protocol -eq  'https' | ForEach-Object { Process-Binding $_ }  
	}
}

Get-Website | ForEach-Object { Process-Site-Bindings  $_ }

# Process the netsh bindings for IP and protocol

netsh http show sslcert > sslbinding.txt -Force
$iisbindings = netsh http show sslcert > c:\temp\sslbindings.txt -force
$iisbindings = Get-NetIPAddress | where-object { $_.AddressFamily -eq "IPV4" } | select-object IPAddress
foreach ($binding in $iisbindings)  {
    if ($binding.certhash -eq $old_cert) {
        netsh http delete sslcert ipport=$binding
        $cmd = "http add sslcert ipport=0.0.0.0:443 certhash=DB76AF93AAB3E202A5C4EA5DE5E2E3704816623A appid={d673f5ee-a714-454d-8de2-492e4c1bd8f8}"
        $cmd | netsh
    }
}

## Replace certificate on AWS Cloudfront Edge ##

    # Requires openssl
    choco install openssl-y
    choco install openssl-wizard -y

    # Run via openssl - will requre password input if source .pfx is password-protected...meaning no unattended execution.
    $certSource = "<<Path to .pfx>>"
    $pemDestination = "c:\temp\Nfg2023.pem"
    openssl pkcs12 -in $certSource -out $pemDestination -nodes

    write-host "Navitage to $pemDestination and use the encoded private key, cert and cert chain to import cert to AWS certificates."