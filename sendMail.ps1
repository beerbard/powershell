# Get the credential
$credential = Get-Credential

## Define the Send-MailMessage parameters
$mailParams = @{
    SmtpServer                 = 'smtp.networkforgood.com'
    Port                       = '25' # or '25' if not using TLS
    # UseSSL                     = $true ## or not if using non-TLS
    Credential                 = $credential
    From                       = 'eric.stevens@netowrkforgood.com'
    To                         = 'eric.stevens@networkforgood.com'
    Subject                    = "SMTP Client Submission - $(Get-Date -Format g)"
    Body                       = 'This is a test email using SMTP Client Submission'
    DeliveryNotificationOption = 'OnFailure', 'OnSuccess'
}

## Send the message
Send-MailMessage @mailParams