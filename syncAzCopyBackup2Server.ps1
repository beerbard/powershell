# Author: Eric Stevens
# Owner: Network for Good
# Last major revision date: 8/30/2021


$destination= "H:\DB Backup\Prod" # format matches both on-prem source dirs as well as the Az destination dirs on the DB server.
$source = "https://nfgdrdbbackup01.file.core.windows.net/db-backup/Prod`?<sas>"

azcopy sync $source $destination --delete-destination=true