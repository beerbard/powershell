# Author: Eric Stevens
# Owner: Network for Good
# Date of last major revision: 3/3/2022

# The purpose of this script is to automate the testing of auth and submission of test payment.

# Steps:
    # 1. Define json test data in hash tables for submission to API to Generate Token
    # 2. Submit hssh table converted to json to api
    # 3. Validate 200 response and pull token out of content returned
    # 4. Form body for payment call to the api in hash tables (one is a hash table inside an array)
    # 5. Send the hash table body converted to json to the donation api with the token defined in the header
    # 6. Validate 200 and do x. 

# Need:
    # Add user params to change envs. Should only need to be an env param that transforms data in-script.
    # Add logging.


$logFilePath = "C:\Logs\PSLog-PartnerDonation-APIWebRequests.txt"
if (!(Test-Path  $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath -Force
}
function logEntry {
    # Usage: logFile -Comment "This is the log message."
    # Returns: 2021.08.19      14:24:10        This is the log message.
    # Writes to screen AND defined log file.
    param (
           [Parameter()]
           [ValidateNotNullOrEmpty()]
           [string]$Comment
    )
    $logTime = get-date -Format "yyyy.MM.dd`tHH:mm:ss`t"
    "$logTime`t$Comment"
}
# logEntry -Comment "This is a log entry." | Tee-Object -FilePath $logFilePath -Append
logEntry -Comment "******************* New Submission *******************" | Tee-Object -FilePath $logFilePath -Append

$env = "uat"

# Generate Token

$authuri = "https://api-$env.networkforgood.org/access/rest/token"

$source = "NFGWEBSERVICE"
$userid = "NFGWEBAPI"
$password = "testpw"
$scope = "donation donation-reporting"

$authbody = @{
    source = $source
    userid = $userid
    password = $password
    scope = $scope
 }
logEntry -Comment "Submitting authorization request for $env test donation to $authuri..." | Tee-Object -FilePath $logFilePath -Append
$authresult = Invoke-WebRequest -Method Post -Uri $authuri -Body (ConvertTo-Json $authbody) -ContentType "application/json"
logEntry -Comment "Status Code : $($authresult.statuscode)" | Tee-Object -FilePath $logFilePath -Append

if ($authresult.statuscode -ne 200) {
    logEntry -Comment "The request was not successful:`n" | Tee-Object -FilePath $logFilePath -Append
    logEntry -Comment "Response : $authresult" | Tee-Object -FilePath $logFilePath -AppendConvertFrom-Json $authresult
    logEntry -Comment "Exiting script" | Tee-Object -FilePath $logFilePath -Append
    exit
}

# Retrieve token
logEntry -Comment "Retrieving token from response..." | Tee-Object -FilePath $logFilePath -Append
$token = (ConvertFrom-Json $authresult.Content).token
logEntry -Comment "Successfully cached token starting with : $($token.SubString(0,50))" | Tee-Object -FilePath $logFilePath -Append

# Use token to send payment to api

$partnerdonationuri = "https://api-$env.networkforgood.org/service/rest/donation"

# Headers

$authorization = "Bearer $token"

# Define json values in hast table - tables nest where value = variable

# Note: this one is a single hash table inside of a one-item array - errant coding.
$donationLineItems = @(
    @{
    organizationId = "823973974"
    organizationIdType = "Ein"
    designation = "Cheerleading Team"
    dedication = "dedication"
    donorPrivacy = "ProvideNameAndEmailOnly"
    amount = 30
    feeAddOrDeduct = "Deduct"
    transactionType = "Donation"
    }
)

 $billingAddress = @{
    street1 = "Jerry Toth Drive"
    city = "Elmendorf"
    state = "CA"
    postalCode = "90001"
    country = "US"
 }

 $donor = @{
    ip = "209.131.41.49"
    token = "DonorTokenDV"
    firstName = "Deepti"
    lastName = "Varma"
    email = "nfgcvlx+22june21@gmail.com"
    phone = "907-551-6347"
    billingAddress = $billingAddress
 }

 $expiration = @{
    year = 2022
    month = 9
 }

 $creditCard = @{
    nameOnCard = "Deepti"
    type = "Visa"
    number = "4111111111111111"
    expiration = $expiration
    securityCode = "123"
 }

 $payment = @{
    source = "CreditCard"
    donor = $donor
    creditCard = $creditCard
 }

$donationBody = @{
    source = "NFGWEBSERVICE"
    campaign = "API"
    donationLineItems = $donationLineItems
    totalAmount = 30
    tipAmount = 0
    partnerTransactionId = "230cf1c9-4d5d-4e70-be1d-1acbd21b5ebb"
    payment = $payment
}

# Submit to partnerdonation-api
logEntry -Comment "Submitting donation request for $env test donation to $partnerdonationuri..." | Tee-Object -FilePath $logFilePath -Append
$donationResult = Invoke-RestMethod -Method Post -Uri $partnerdonationuri -Body (ConvertTo-Json $donationBody -Depth 3) -Header @{"Authorization"=$authorization}  -ContentType "application/json"
logEntry -Comment "Status Code : $($donationResult.statuscode)" | Tee-Object -FilePath $logFilePath -Append
logEntry -Comment "Response : $donationResult" | Tee-Object -FilePath $logFilePath -Append

