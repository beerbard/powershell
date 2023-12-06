# Declare this on the executing machine. Server will use machine key and user RSA to encrypt resulting in a key.
$String = 'Dr6u5A%Tkcj6KK'
$password = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String $String -AsPlainText -Force)
$password
# 
# $password = "<Enter Secure String from above>"
$password = ConvertTo-SecureString -String -AsPlainText -Force (ConvertFrom-SecureString -SecureString $password)
$password