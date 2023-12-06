# Fill out these variables
$id = "Memcached"
$version = "1.4.4"
$description = "Memcached for windows - x64."
# tags separated by space
$tags = "memcached sl as wb"

<# -------------- Begin script action --------------#>

# Create NuGet Package
# mkdir "C:\temp\Packages\$id" -Force -ErrorAction SilentlyContinue
Set-Location C:\temp\Packages\$id
#logEntry -Comment "Creating Nuspec file..." | Tee-Object -FilePath $logFilePath -Append
nuget spec -Force
#logEntry -Comment "Nuspec file created...configuring..." | Tee-Object -FilePath $logFilePath -Append
$nuspecContent = get-content -Path .\Package.nuspec
$nuspecContent = $nuspecContent.replace("<id>Package</id>","<id>$id</id>")
$nuspecContent = $nuspecContent.replace("<version>1.0.0</version>","<version>$version</version>")
$nuspecContent = $nuspecContent.replace("<authors>eric.stevens</authors>","<authors>NFG Site Reliability Engineering Team</authors>`n`t<owners>Network for Good</owners>")
$nuspecContent = $nuspecContent.replace("<projectUrl>http://project_url_here_or_delete_this_line/</projectUrl>","<projectUrl>https://www.networkforgood.org</projectUrl>")
$nuspecContent = $nuspecContent.replace("<description>Package description</description>","<description>$description</description>")
$nuspecContent = $nuspecContent.replace("<releaseNotes>Summary of changes made in this release of the package.</releaseNotes>","<releaseNotes>Please refer to Github for release notes.</releaseNotes>")
$nuspecContent = $nuspecContent.replace("<tags>Tag1 Tag2</tags>","<tags>$tags</tags>")
$nuspecContent = $nuspecContent.replace("</package>","`t<files>`n`t`t<file src=`"**\*.*`" target=`"`" />`n`t</files>`n</package>")
set-content -Path .\Package.nuspec -value $nuspecContent -force
#logEntry -Comment "Nuspec file configured successfully...creating Nuget package..." | Tee-Object -FilePath $logFilePath -Append
try {
    nuget pack .\Package.nuspec -Force
    #logEntry -Comment "Nuget package successfully created..." | Tee-Object -FilePath $logFilePath -Append
} catch{
    $ErrorMessage = $_.Exception.Message
    #logEntry -Comment "Package did not successfully get created...please refer to this error for more details:`n`n`t$ErrorMessage" | Tee-Object -FilePath $logFilePath -Append
    return
}