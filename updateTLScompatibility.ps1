$enabledtlsvers = "1.2"
$tlsvers = "1.2","1.1","1.0"
$apps = "Client","Server"
# Verify TLS 1.2 is available

foreach ($tlsver in $tlsvers) {
    if ($enabledtlsvers.Contains($tlsver)) {
        $status = "Enabled"
        $disabledbydefault = 0
        $enabledstate = 1
    } else {
        $status = "Disabled"
        $disabledbydefault = 1
        $enabledstate = 0
    }
    foreach ($app in $apps) {
        $key = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL $tlsver\$app"
        write-host "Validating TLS $tlsver $app configuration is $status..."
        if (Test-Path $key) {
            $keyObject = Get-ItemProperty $key
            if ($keyObject.DisabledByDefault) {
                if ($keyObject.DisabledByDefault -ne $disabledbydefault) {
                    set-itemproperty -Path $key -Name DisabledByDefault -value $disabledbydefault
                }
            } else {
                write-host "$keyObject.DisabledByDefault has not been definied...creating..."
                Try {
                    New-itemproperty -Path $key -Name DisabledByDefault -value $disabledbydefault
                    write-host "TLS $tlsver $keyObject.DisabledByDefault has been created and configured successfully...continuing."
                } catch {
                    write-host "Error: TLS $tlsver $keyObject.DisabledByDefault has NOT been created and configured successfully...continuing."
                }
            }
            if ($keyObject.Enabled) {
                if ($keyObject.Enabled -ne $enabledstate) {
                    set-itemproperty -Path $key -Name Enabled -value $enabledstate
                }
            } else {
                try {
                    new-itemproperty -Path $key -Name Enabled -value $enabledstate
                    write-host "TLS $tlsver $keyObject.Enabled has been created and configured successfully...continuing."
                } catch {
                    write-host "Error: TLS $tlsver $keyObject.Enabled has NOT been created and configured successfully...continuing."
                }
            }
        }
    }
}
