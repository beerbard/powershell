
# DNS Made Easy uri is built from https://api.dnsmadeeasy.com/V2.0/dns/managed/<domainid>/records/<recordid>
$domainId = "129324"
$dnsmeuri = "https://api.dnsmadeeasy.com/V2.0/dns/managed"
$requestDate = get-date -AsUTC -Format "o"
$apiKey = "thisisanapikey=="
$method = ""

# Create hash given $requestDate as message
$secret = '6KVQ05mN9iLvCg=='
$hmacsha = New-Object System.Security.Cryptography.HMACSHA1
$hmacsha.key = [Convert]::FromBase64String($secret)
$signature = [Convert]::ToBase64String($hmacsha.ComputeHash([Text.Encoding]::Default.GetBytes($requestDate.ToString())))

# Build request headers
$headers = @{ 
    "x-dnsme-requestDate" = $requestDate
    "x-dnsme-apiKey" = $apiKey
    "x-dnsme-hmac" = $signature 
}

##### -------------- Actions -------------- #####
# Get records - aids in retrieving record IDs for updating or deleting.

$dnsmeGetResult = Invoke-RestMethod -Method 'Get' -Uri "$dnsmeuri/$domainid" -Headers $headers -ContentType "application/json"

# Create a record
$dnsmeBody = @{
    name = "testy"
    type = "A"
    value = "10.99.102.10"
    gtdLocation = "DEFAULT"
    ttl = "60"
}

$dnsmeResult = Invoke-RestMethod -Method Post -Uri $uri -Body (ConvertTo-Json $dnsmeBody -Depth 1) -ContentType "application/json"
write-host "Status Code : $($dnsmeResult.statuscode)"
write-host $dnsmeResult

# update a record
$dnsmeBody = @{
    serverID = "testy"
    type = "A"
    value = "10.99.102.10"
    gtdLocation = "DEFAULT"
    ttl = "60"
}

$dnsmeResult = Invoke-RestMethod -Method Post -Uri $uri -Body (ConvertTo-Json $dnsmeBody -Depth 1) -ContentType "application/json"
write-host "Status Code : $($dnsmeResult.statuscode)"
write-host $dnsmeResult

# delete a record
$dnsmeBody = @{
    serverID = "testy"
    type = "A"
    value = "10.99.102.10"
    gtdLocation = "DEFAULT"
    ttl = "60"
}

$dnsmeResult = Invoke-RestMethod -Method Post -Uri $uri -Body (ConvertTo-Json $dnsmeBody -Depth 1) -ContentType "application/json"
write-host "Status Code : $($dnsmeResult.statuscode)"
write-host $dnsmeResult