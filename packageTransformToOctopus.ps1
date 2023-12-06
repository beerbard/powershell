<# Find File and Perform Action

Author: Eric Stevens
Owner: Network for Good
Date of last major revision: 1/26/2022

The purpose of this script is to iterate through folder containing one or multiple code builds, find all config files and perform an action in respect to the path of each found file. 

Steps: 
0. Unzip sourceDirectory to local folder
1. Find all instances of "web.template.config"
2. For each instance, get path and content
3. Create file "web.release.config" and set content

*** This runs on CCNETAZURE02 ***

$env:AZCOPY_CRED_TYPE = "Anonymous";
./azcopy.exe copy "C:\builds\_publish\" "https://nfgdrdbbackup01.file.core.windows.net/misc/Temp/?sv=2020-08-04&ss=bfqt&srt=sco&sp=rwdlacupitfx&se=2025-05-06T02%3A48%3A02Z&st=2022-05-05T18%3A48%3A02Z&spr=https&sig=TUKLaqlPBk%2Ff2JgeWwJ%2FFcEp%2BlYPgTmqFMsyI%2BcW790%3D" --overwrite=prompt --from-to=LocalFile --follow-symlinks --put-md5 --follow-symlinks --preserve-smb-info=true --disable-auto-decoding=false --recursive --log-level=INFO;
$env:AZCOPY_CRED_TYPE = "";

#>

# Usage: $>C:\Nfg\Scripts\packageTransformToOctopus.ps1 -sourceFolder "C:\builds\_publish\GP\2.1.6.0\_Baseline" -octopusAPIKey "<api-key>"

# MUST MAINTAIN ORIGINAL BUILD FOLDER STRUCTURE.  

param (
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the path of the target build output directory. (i.e. `"C:\builds\_publish\GP\2.1.6.0\_Baseline`") - NOTE: MUST be the parent of a build package in order to properly and automatically name and version.")]
    [string[]]$sourceFolder="C:\builds\_publish\GP\2.1.6.0\_Baseline",
    [Parameter(Mandatory=$false,
    HelpMessage="Enter the API key of the Octopus account you want to send packages to.")]
    [string[]]$octopusAPIKey
)

$logFilePath = "C:\Logs\PSLog.txt"
if (!(Test-Path  $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath -Force
}

function logEntry {
    # Usage: logFile -Comment "This is the log message."
    # Returns: 2021.08.19      14:24:10        This is the log message.
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Comment
    )
    $logTime = get-date -Format "yyyy.MM.dd`tHH:mm:ss`t"
    "$logTime`t$Comment"
    }

# Verify directory is the a build directory - look for a child directory called "Build" - all MSBuild packages have it. 

<# temp #>#$sourceFolder = "C:\Users\eric.stevens\Downloads\_publish\DonateNow2.0\3.1.2.0\_Baseline"
$scriptDir = "C:\Nfg\Scripts"
Set-Location $scriptDir
$build = get-childitem -Path $sourceFolder -Directory | Where-Object { $_.Name -eq "Build"}
if ($build.Count -lt 1) {
    logEntry -Comment "Source folder specified is not a build directory. Folder should have a <solution>.<maj>.<min>.<rev>.<inc>_<Environment> format. Please verify source folder references a build directory and try again." | Tee-Object -FilePath $logFilePath -Append
    Exit
} 

# Install dependencies
Set-ExecutionPolicy -ExecutionPolicy Unrestricted
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install NuGet.CommandLine -y

<# Use build packages name to define package naming and versioning. 
Original build package naming: <solution>.<maj>.<min>.<rev>.<inc>_<Environment> -     i.e. V4.1.1.1.0_Production
Nuget package versioning: <service>.<solution>.<maj>.<min>.<rev>.<inc> -              i.e. NfgPrimary.V4.1.1.1.0

CCNet builds drop to \\ccnetazure02\C$\builds\_publish
#>




# Use source folder details to get package and version
$sourceFolderDeets = $sourceFolder.Split("\") # Remove extra path from the string.
$packageDeets = $sourceFolderDeets[-2].Split(".")
$solution = $sourceFolderDeets[-3]
$version = $packageDeets[0],$packageDeets[1],$packageDeets[2] -join "."

# Shorten long solution names to short so the package names aren't huge.
if ($solution -eq "DonateNow2.0") {$solution = "DN2"}
if ($solution -eq "ProductConfiguration") {$solution = "PC"}

logEntry -Comment "Transforming files [$originalConfigs] to xxxx.Release.config" | Tee-Object -FilePath $logFilePath -Append 

$files = get-childitem -Path $sourceFolder -recurse -ErrorAction SilentlyContinue -Include *.template.config # | Where-Object { $_.Name -eq $originalConfigFile}# | Select-Object -last 1
    
# Define find and replace strings - Octopus transform .configs use the #{<var>} notation and the .NET templates use ${<var>} notation.
$find = "`${"
$replace = "#{"
$count = $files.Count
logEntry -Comment "Messing with $count xxx.template.config files:" | Tee-Object -FilePath $logFilePath -Append
foreach ($file in $files) {
    write-host "File details: `n`tDirectory Name: "$file.DirectoryName"`n`tFile Name: "$file.BaseName"`n`tFull Path : "$file.FullName
    $configType = $file.Name.Split(".")
    $newFileName = $configType[0] + ".config"

    # Transform the xxx.Template.config variable syntax to adhere to Octopus standards.
    $configContent = get-content -Path $file
    $updatedConfigContent = $configContent.replace($find,$replace)

    $newFilePath = $file.DirectoryName + "\$newFileName"
    $serviceName = $file.DirectoryName.Split("\")[-1] # Returns project folder name
    if (!(Test-Path -path $newFilePath)) { 
        New-Item -Path $newFilePath -ItemType File -Force        
        logEntry -Comment "$newFilePath has been created and synced." | Tee-Object -FilePath $logFilePath -Append
    } else {
        logEntry -Comment "$newFilePath already exists. Setting variablized content." | Tee-Object -FilePath $logFilePath -Append
    }
    Set-Content -Path $newFilePath -Value $updatedConfigContent -Force

    # Create NuGet Package
    Set-Location $file.DirectoryName
    logEntry -Comment "Creating Nuspec file..." | Tee-Object -FilePath $logFilePath -Append
    nuget spec -Force
    logEntry -Comment "Nuspec file created...configuring..." | Tee-Object -FilePath $logFilePath -Append
    $nuspecContent = get-content -Path .\Package.nuspec
    $nuspecContent = $nuspecContent.replace("<id>Package</id>","<id>$serviceName</id>")
    $nuspecContent = $nuspecContent.replace("<version>1.0.0</version>","<version>$version</version>")
    $nuspecContent = $nuspecContent.replace("<authors>eric.stevens</authors>","<authors>NFG Site Reliability Engineering Team</authors>`n`t<owners>Network for Good</owners>")
    $nuspecContent = $nuspecContent.replace("<projectUrl>http://project_url_here_or_delete_this_line/</projectUrl>","<projectUrl>https://www.networkforgood.org</projectUrl>")
    $nuspecContent = $nuspecContent.replace("<description>Package description</description>","<description>All binaries and artifacts included in the $serviceName project in the $solution solution for version $version.</description>")
    $nuspecContent = $nuspecContent.replace("<releaseNotes>Summary of changes made in this release of the package.</releaseNotes>","<releaseNotes>Please refer to Github for release notes.</releaseNotes>")
    $nuspecContent = $nuspecContent.replace("<tags>Tag1 Tag2</tags>","<tags>$serviceName $solution</tags>")
    $nuspecContent = $nuspecContent.replace("</package>","`t<files>`n`t`t<file src=`"**\*.*`" target=`"`" />`n`t</files>`n</package>")
    set-content -Path .\Package.nuspec -value $nuspecContent -force
    logEntry -Comment "Nuspec file configured successfully...creating Nuget package..." | Tee-Object -FilePath $logFilePath -Append
    try {
        nuget pack .\Package.nuspec -Force
        logEntry -Comment "Nuget package successfully created..." | Tee-Object -FilePath $logFilePath -Append
    } catch{
        $ErrorMessage = $_.Exception.Message
        logEntry -Comment "Package did not successfully get created...please refer to this error for more details:`n`n`t$ErrorMessage" | Tee-Object -FilePath $logFilePath -Append
        return
    }

    $nugetPackages = get-childitem -Path .\*.$version.nupkg -File
    write-host "The resultant set from retrieving the nuget package is:`n`t$nugetPackages"
    foreach ($package in $nugetPackages) {

        logEntry -Comment "Attempting to copy $package to Packages folder..." | Tee-Object -FilePath $logFilePath -Append
        if (!(Test-Path "C:\builds\nugetPackages\$solution\$version")) {
            mkdir "C:\builds\nugetPackages\$solution\$version" -Force
        }
        Copy-Item -Path $package -Destination "C:\builds\nugetPackages\$solution\$version" -Force
    
        <#
        if (!($octopusAPIKey)) {
            $octopusAPIKey = "<api-key>"
        }
        #>
        if (test-path "C:\Nfg\Scripts\PushPackagesToOctoRepo.ps1") {
            # Upload to Octopus Repo
            if ($octopusAPIKey) {
                logEntry -Comment "Uploading Nuget package to Octopus package repository..." | Tee-Object -FilePath $logFilePath -Append
                try {
                    C:\Nfg\Scripts\PushPackagesToOctoRepo.ps1 -octopusURL "https://networkforgood.octopus.app" -spaceName "Dot Net" <# -octopusAPIKey $octopusAPIKey #> -packageFile $package -replacePackage "true"
                    logEntry -Comment "Package successfully uploaded to Octopus package repository!" | Tee-Object -FilePath $logFilePath -Append
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    logEntry -Comment "Package did not successfully upload to Octopus package repository...please refer to this error for more details:`n`n`t$ErrorMessage" | Tee-Object -FilePath $logFilePath -Append
                }
            }
        } else {
            logEntry -Comment "No Octopus API Key defined. Package will not be uploaded to Octopus...continuing..." | Tee-Object -FilePath $logFilePath -Append
        }
    }
    #>
}

logEntry -Comment "Sucessfully processed $count $solution config files. Please verify, and see you again soon!" | Tee-Object -FilePath $logFilePath -Append
Set-Location $scriptDir