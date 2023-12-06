# Author: Eric Stevens
# Organization: Network for Good
# Purpose: This script is intended to upload an individual package to an Octopus build in repository.

# Requirements:
    # Active octopus instance (known URL, space name, API key of authorized user)
    # Compatible package (.zip, .nupkg)

# Directions: The following is a sample script using all defined parameters. Optional params and their default values are in brace []. <> indicates no default value.

# >.\PushPackagesToOctoRepo.ps1 [-octopusURL "https://networkforgood.octopus.app"] [-spaceName "default"] -octopusAPIKey "<specify API key>" -packageFile "<path\to\package.nupkg>" [-replacePackage "true"]

param (
    [Parameter(Mandatory=$false,
        HelpMessage="Enter the URL of your Octopus instance omitting the trailing forward slash 9defaults to https://networkforgood.octopus.app).")]
    [string]$octopusURL="https://networkforgood.octopus.app",
    [Parameter( Mandatory=$false,
        HelpMessage="Specify the target Octopus space. This defaults to the default Space - currently 'Dot Net'.")] 
    [string]$spaceName="Dot Net",
    [Parameter(Mandatory=$false,
        HelpMessage="Enter the API key for the Octopus user that has access to upload to the repository. This is mandatory and must be entered manually as a parameter. Someone should have it in Lastpass.")]
    [string]$octopusAPIKey = "<api-key>",
    [Parameter(Mandatory=$true,
        HelpMessage="Enter the path to the package file. This parameter must be specified. Example: 'path\to\package.nupkg'")]
    [string]$packageFile,
    [Parameter(Mandatory=$false,
        HelpMessage="Specify whether you would like the process to overwrite packages with the same name. This is not required, but the default setting is 'true'. Only specify with a value of 'false' if you do not wish to overwrite packages.")]
    [string]$replacePackage="true"
)

$ErrorActionPreference = "Stop";

# Define working variables
$header = @{ "X-Octopus-ApiKey" = "<api-key>" }

# Load http assembly
Add-Type -AssemblyName System.Net.Http

# Create http client handler
$httpClientHandler = New-Object System.Net.Http.HttpClientHandler
$httpClient = New-Object System.Net.Http.HttpClient $httpClientHandler
$httpClient.DefaultRequestHeaders.Add("X-Octopus-ApiKey", "<api-key>")

# Get space
$space = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/spaces/all" -Headers @{ "X-Octopus-ApiKey" = "<api-key>" }) | Where-Object {$_.Name -eq $spaceName} 

# Open file stream
$fileStream = New-Object System.IO.FileStream($packageFile, [System.IO.FileMode]::Open)

# Create dispositon object
$contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
$contentDispositionHeaderValue.Name = "fileData"
$contentDispositionHeaderValue.FileName = [System.IO.Path]::GetFileName($packageFile)

# Create stream content
$streamContent = New-Object System.Net.Http.StreamContent $fileStream
$streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
$contentType = "multipart/form-data"
$streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $contentType

$content = New-Object System.Net.Http.MultipartFormDataContent
$content.Add($streamContent)

# Upload package
$httpClient.PostAsync("$octopusURL/api/$($space.Id)/packages/raw?replace=$replacePackage", $content).Result

if ($null -ne $fileStream)
{
    $fileStream.Close()
}
