<# 
.SYNOPSIS
	Uploads files to an SFTP server.
	Folders are not supported.
	Uses Private/Public key file to logon to SFTP server.
	Can be easily converted to use a simple username/password.

.DESCRIPTION
	Uploads all files in the source folder to a destination SFTP server.
	Areas that can be modified are headed by "#Change Variables Here!!"

.NOTES
	Author:		Derek Bannard
	Filename:	SFTP_Upload_Posh-SSH.ps1
	Version:	1.00
	Date:		2018/01/03

.PARAMETER
	None. This script requires direct modification to set paths and variables.

.EXAMPLE
	.\SFTP_Upload_Posh-SSH.ps1
#>

#Change Variables Here!!
#Global variables
$sftpServer = "IP Address or Hostname of SFTP Server"
$sftpDestPort = "22"
$sftpRemotePath = "/"
$sftpUsername = "sftp_user"
$srcFolder = "C:\SFTP\Incoming"			# Folder containing the files you want to upload.
$dstFolder = "C:\SFTP\Outgoing"			# Folder that the script will move the files to after uploading.

#Change Variables Here!!
#Import the SFTP Module & CmdLets in per session mode.
$env:PSModulePath = $env:PSModulePath + ";C:\SFTP\Modules"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force # installs NuGet package manager if not already installed. 
Import-Module Posh-SSH

#Change Variables Here!!
#Define the Private Key file path
$pKeyFile = "C:\SFTP\KEY\private.KEY"			# Generate key using program like PuTTYgen
$nopasswd = new-object System.Security.SecureString

#Set Credetials to connect to server
$CredDest = New-Object System.Management.Automation.PSCredential($sftpUsername, $nopasswd)

#Get todays date
$todayDate = Get-Date -Format "yyyy-MM-dd HHmm"
$folderDate = Get-Date -Format "yyyyMMdd"

#Remove any open sessions
Get-SFTPsession | Remove-SFTPSession | Out-Null

#Create SFTP Session
$Session = New-SFTPSession -ComputerName $sftpServer -Credential $CredDest -KeyFile $pKeyFile -Port $sftpDestPort

#Change Variables Here!!
#Send an email when process has started
#Email the list
$Body = "SFTP Script Started`r`n`nHost: $($Session.Host)"
$Subject = "$todayDate - SFTP Upload Started"
$SMTP = "smtp-server.domain.com"
$To = "Notification Email List <notifications@domain.com>"
$From = "SFTP Notifications <sftpnotifications@domain.com>"
Send-MailMessage -To $To -From $From -SmtpServer $SMTP -Body $Body -Subject $Subject 

#Specify the local files
Set-Location $srcFolder
$LocalFiles = Get-ChildItem $srcFolder

#Now copy the files up
ForEach ($LocalFile in $LocalFiles)
{
Set-SFTPFile -SessionId $Session.SessionId -LocalFile "$LocalFile" -RemotePath "$sftpRemotePath" -Overwrite
}

#Create a list of uploaded files
$Files = (Get-SFTPChildItem -SessionId $Session.SessionId -Path "$sftpRemotePath") | Select Name,FullName,Length | Sort-Object FullName
#$msgFiles = $Files | where-object {$_.FullName -ne "/." -and $_.FullName -ne "/.."}
$msgFiles = $Files | where-object {$_.Length -ne "0"}

#Send an email when process has ended
#Email the list
$Body = "SFTP Script Ended `r`n`nFiles moved from $srcFolder to $dstFolder`r`n`nHost: $($Session.Host)`r`n`nFiles Names:`r`n"
$msgFiles | ForEach-object {$Body += " $($_.Name)`n"}
$Subject = "$todayDate - SFTP Upload Completion Report"
Send-MailMessage -To $To -From $From -SmtpServer $SMTP -Body $Body -Subject $Subject 

#Remove the session
Get-SFTPsession | Remove-SFTPSession

#Move the local files after processing
$LocalFiles | Move-Item -Destination $dstFolder -Force