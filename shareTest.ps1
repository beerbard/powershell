$requestDate = get-date -AsUTC -Format "o"
$apiKey = "thisisanapikey=="
$hmac = "thisisanhmachash"

# Create hash given $requestDate as message
$secret = '6KVQ05mN9iLvCg=='

$hmacsha = New-Object System.Security.Cryptography.HMACSHA1
$hmacsha.key = [Convert]::FromBase64String($secret)
$signature = [Convert]::ToBase64String($hmacsha.ComputeHash([Text.Encoding]::Default.GetBytes($requestDate.ToString())))

$header = @{ "x-dnsme-requestDate" = $requestDate; "x-dnsme-apiKey" = $apiKey; "x-dnsme-hmac" = $signature }
$header

