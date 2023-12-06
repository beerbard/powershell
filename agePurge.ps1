# Author: Ewric Stevens
# Owner: Netowrk for Good
# Date of last major revision: 9/8/2021

# The purpose of this script is to truncate all files older than a certain number of days in a Windows folder.
<#
param (   
    [Parameter(Mandatory=$true,
        HelpMessage="Enter the full path of the folder you wish to purge (-Path `"C:\path\to\folder`")")]
    [string[]]$path="C:\temp",
    [Parameter(Mandatory=$false,
        HelpMessage="Declare whether you wish to NOT recursively purge. (-recurse [no add'l params needed])")]
    [string[]]$recurse=$false,
    [Parameter(Mandatory=$false,
        HelpMessage="Enter the number of days older than which you wish to purge.")]
    [string[]]$maxagedays = "90",
    [Parameter(Mandatory=$false,
        HelpMessage="Enter the number of days older than which you wish to purge.")]
    [string[]]$filetype
)
#>

# When using include, the path MUST end in a \* or no values will be returned. 

Get-ChildItem -Path $path -Recurse -File <# -include *.log #> -Force | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$maxagedays) } | Remove-Item

# get-childitem -Path "C:\Users\NFGSTasks\.azcopy" -File -Recurse -Force | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-1)} | Remove-Item -Force
