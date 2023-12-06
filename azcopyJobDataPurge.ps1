# Author: Eric Stevens
# Owner: Network for Good
# Last major revision date: 9/14/2021

<# 
The purpose of this script is to purge job and temp data from a user profile that is performing azcopy operations. 
The .azcopy folder in the user's profile (individual account or service account if running a task under a service account)
will inflate indeffinitely as more azcopy operations are executed - this requires regular purging, especially if there are 
a lot of files being targeted.
#>

# Execute azcopy job data cleanup
azcopy jobs clean --with-status=completed -force

