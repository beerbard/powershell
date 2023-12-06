
$reportingservicesinternal = "https://reportingservices.dr.internal.networkforgood.org"
$replace = "<endpoint address=`""+$reportingservicesinternal
write-host $replace

Import-Module webadministration
$sites = Get-iissite
foreach ($site in $sites){
    write-host "Updating custom logging for $site"
    Set-ItemProperty IIS:\Sites\$site -name logfile.customFields.collection -value @{logFieldName="crypt-protocol";sourceType="ServerVariable";sourceName="CRYPT_PROTOCOL"}
    Set-ItemProperty IIS:\Sites\$site -name logfile.customFields.collection -value @{logFieldName="crypt-cipher";sourceType="ServerVariable";sourceName="CRYPT_CIPHER_ALG_ID"}
    Set-ItemProperty IIS:\Sites\$site -name logfile.customFields.collection -value @{logFieldName="crypt-hash";sourceType="ServerVariable";sourceName="CRYPT_HASH_ALG_ID"}
    Set-ItemProperty IIS:\Sites\$site -name logfile.customFields.collection -value @{logFieldName="crypt-keyexchange";sourceType="ServerVariable";sourceName="CRYPT_KEYEXCHANGE_ALG_ID"}
}


