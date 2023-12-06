
## Snippet used in 

iisreset /stop
$path = "#{Octopus.Action.Package.InstallationDirectoryPath}\Web.config"
$memcachedHost = "#{memcached-host}"
$memcachedPort = "#{memcached-port}"
$date = Get-Date
add-content -path "c:\temp\deploynotes.txt" -value "`n----- $date -----`n`n$date$path`n$memcachedHost`n$memcachedPort"
$webConfig = Get-Content -path $path
$updated = $webConfig.replace('<add address="localhost" port="11211" />','<add address=$memcachedHost port=$memcachedPort" />')
set-content -path $path -value $updated
iisreset /start