Write-Host "Please wait while your file downloads"

#Function to get all files
function Get-FtpDir ($url,$credentials)
{
    $request = [Net.WebRequest]::Create($url)
    $request.Credentials = $credentials
    $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
    $response = $request.GetResponse()
    $reader = New-Object IO.StreamReader $response.GetResponseStream()
    $readline = $reader.ReadLine()
    $output = New-Object System.Collections.Generic.List[System.Object]
    while ($readline -ne $null)
    {
        $output.Add($readline)
        $readline = $reader.ReadLine()
    }
    $reader.Close()
    $response.Close()
    $output
}

$server = "ftp.server.net"
$user = "user"
$pass = "pass"
$invocation = (Get-Variable MyInvocation).Value
$localpath = Split-Path $invocation.MyCommand.Path
$TodayDate = (get-date)
$FileNameDate = date $TodayDate -f yyyy-MM-dd
$remotefilepath = "inbox/sub1/sub2"
$localfilename = "FILE_NAME_$FileNameDate.csv"
$localfilelocation = "$localpath\$localfilename"
$uri = New-Object System.Uri(“ftp://$server/$remotefilepath”)

#List of all files on FTP-Server
$files = Get-FTPDir $uri -credentials (New-Object System.Net.NetworkCredential($user, $pass))

foreach ($file in $files)
{
    if ($file -like "FILE_NAME_$($FileNameDate)_*.txt")
    {
        $file
        $fileuri = New-Object System.Uri(“ftp://$server/$remotefilepath/$file”)
        $webclient = New-Object System.Net.WebClient
        $webclient.Credentials = New-Object System.Net.NetworkCredential($user, $pass)
        $webclient.DownloadFile($fileuri, $localfilelocation)
    }
}