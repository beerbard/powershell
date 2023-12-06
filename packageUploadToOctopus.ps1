# packageUploadToOctopus.ps1

# Author: Eric Stevens for Network For Good

# Date: 6/17/2021
# Version: 0.0.1

# This script is intended to be manually executed against build packages that have been gnerated by CruiseControl build server as of 6/17/2021

# Process overview:

# Assumptions:
    # Chocolatey is installed on executing server. 

# 1. Script will be executed with user input parameters including:
    # Path to the build .zip file
    # Octopus instance URI
    # API key for user with perms to upload to the Octo built-in package repository

# 2. Unzip package file to temp dir on D drive to avoid file system space competition
    # D:\temp\

# 3. 