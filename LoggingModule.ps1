<#  LoggingModule.ps1
    Author: Eric Stevens
    Owner: Bonterra
    Date of last major revision: 4/10/2023

To call from parent script: 
    LoggingModule.ps1 -logEnv <environment (Default: dv)> -scriptName ($Script:MyInvocation.MyCommand.Name -replace '\..*')

    Usage:
    logEntry -Comment "This is the log message." [-alertMessage] 
Returns: 
    2021.08.19      14:24:10        This is the log message.

Note: to send a log email, a function will have to be inserted at the end of the script - this script is specifically designed to send via SocketLabs mail service:
    sendAlertEmail -recipient "<Enter recipient email here>" -SLserverID "43303" -SLAPIKey "b4A5Kty2D7QkTa68FrYz"

Latest: Logging is working, but send mail is failing at the api. 

#>

param (
    [Parameter(Mandatory=$false,HelpMessage="Select the environment of the server you are deploying (pr, bl, gr, st, dm, ut, qa, dv).")]
    [string[]]$logEnv="dv",
    [Parameter(Mandatory=$false,HelpMessage="This is passed as a pre-formed method. Ensure the usage defined above is used correctly.")]
    [string[]]$scriptName # ensures $scriptName is set to avoid failures.
)
write-host "Script name is $scriptName"
# Define logging
$logFilePath = "C:\Logs\PSLog-$scriptName.txt"
if (!(Test-Path  $logFilePath)) {
   New-Item -ItemType File -Path $logFilePath -Force
}
$alertFilePath = "$env:TEMP\temp_alertMessage.txt"
if (!(Test-Path  $alertFilePath)) {
   New-Item -ItemType File -Path $alertFilePath -Force
}
function logEntry {
    param (
           [Parameter()]
           [ValidateNotNullOrEmpty()]
           [string]$Comment="auto comment",
           [Parameter()]
           [switch]$alertMessage
    )

    $logTime = get-date -Format "yyyy.MM.dd`tHH:mm:ss`t"
    if ($alertMessage) {
        "$logTime`t$Comment" | Tee-Object -FilePath $alertFilePath -append
    }
    "$logTime`t$Comment" | Tee-Object -FilePath $logFilePath -append
}

# Send mail function.

# Steps:
    # 1. Local log configuration.
    # 2. Define message params
    # 3. Format JSON values/arrays/hash tables
    # 4. Make the call to SocketLabs with a dev account.

function sendAlertEmail {
    param (   
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the TO email recipient")]
        [string[]]$recipient="eric.stevens@bonterratech.com",
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the id of the server from SocketLabs (get from account)")]
        [string[]]$SLserverID="43303",
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the api key of the SocketLabs user account (get from account)")]
        [string[]]$SLAPIKey="b4A5Kty2D7QkTa68FrYz",
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the api key of the SocketLabs user account (get from account)")]
        [string[]]$alertScriptName=$scriptName
    )

    # Pull body from "$env:TEMP\temp_alertMessage.txt"
    $subject = "Results of $alertScriptName.ps1 in $logEnv"
    $body = get-content -path $alertFilePath

    # Catch env definition if not set by params
    if (!$alertEnv) {$alertEnv = "dv"}

    # Define URI
    $uri = "https://inject.socketlabs.com/api/v1/email"

    # Define headers
        # No headers

    # Define json values in hash table - tables nest where value = variable

    <# Example JSON call
    {
        "serverId": 43303,
        "APIKey": "b4A5Kty2D7QkTa68FrYz",
        "Messages": [
            {
                "To": [
                    {
                        "emailAddress": "eric.stevens@networkforgood.com"
                    }
                ],
                "From": {
                    "emailAddress": "alerts-dr-noreply@sandbox.socketlabs.dev"
                },
                "Subject": "Sending A Test Message",
                "HtmlBody": "<html>This is the Html Body of my message.</html>",
                "TextBody": "This is the Plain Text Body of my message."
            }
        ]
    }
    #>

    # Single-item array containing a single hash table. STRING VALUES MUST BE IN "" OR THE CONVERTTO-JSON WILL INTERPRET IT AS A SINGLE-ITEM ARRAY.
    $to = @(
        @{
            emailAddress = "$recipient"
        }
    )
    $from = @{
        emailAddress = "alerts-$alertEnv-noreply@sandbox.socketlabs.dev"
    }
    $messages = @(
        @{
            to = $to
            from = $from
            Subject = "$subject"
            HtmlBody = "<html>$body</html>"
            TextBody = "$body"
        }
    )
    $mailBody = @{
        serverID = "$SLserverID"
        APIKey = "$SLAPIKey"
        messages = $messages
    }

    # Submit to partnerdonation-api
    logEntry -Comment "Submitting mail request to SocketLabs..."
    $mailResult = Invoke-RestMethod -Method Post -Uri $uri -Body (ConvertTo-Json $mailBody -Depth 5) -ContentType "application/json"
    logEntry -Comment "Status Code : $($mailResult.statuscode)"
    logEntry -Comment "Response : $mailResult"
}
