# Author: Eric Stevens
# Owner: Network for Good
# Date of last major revision: 4/10/2023

# The purpose of this script is to automate the testing of auth and submission of test payment.

# Usage:
# $subject = "This is the subject."
# $body = "This is the body."
# > .\SocketLabsAlert-APIWebRequests.ps1 -recipient "<Enter recipient email here>" -env "dr" -subject $subject -body $body

# Steps:
    # 1. Local log configuration.
    # 2. Define message params
    # 3. Format JSON values/arrays/hash tables
    # 4. Make the call to SocketLabs with a dev account.

    param (   
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the TO email recipient")]
        [string[]]$recipient="eric.stevens@bonterratech.com",
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the ENV (pr, dr, st, qa, dm, ut, dv, bl, gr")]
        [string[]]$env="dv",
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the message subject")]
        [string[]]$subject="This is a test subject", 
        [Parameter(Mandatory=$false,
               HelpMessage="Enter the message body")]
        [string[]]$body="This is the test body of my message."
     )

# logEntry -Comment "This is a log entry." | Tee-Object -FilePath $logFilePath -Append
logEntry -Comment "******************* New Submission *******************"

# Catch env definition if not set by params
if (!$env) {$env = "dr"}

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
    emailAddress = "alerts-$env-noreply@sandbox.socketlabs.dev"
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
    serverID = "43303"
    APIKey = "b4A5Kty2D7QkTa68FrYz"
    messages = $messages
}

# Submit to partnerdonation-api
logEntry -Comment "Submitting mail request to SocketLabs..."
$mailResult = Invoke-RestMethod -Method Post -Uri $uri -Body (ConvertTo-Json $mailBody -Depth 5) -ContentType "application/json"
logEntry -Comment "Status Code : $($mailResult.statuscode)"
logEntry -Comment "Response : $mailResult"
