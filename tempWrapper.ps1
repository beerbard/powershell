


C:\projects\dot-net-sre\powershell\LoggingModule.ps1 -logEnv "dv" -scriptName ($Script:MyInvocation.MyCommand.Name -replace '\..*')

logEntry -comment "This is a comment" -alertMessage
logEntry -comment "This is a comment" -alertMessage

sendAlertEmail -recipient "eric.stevens@bonterratech.com" -SLserverID "43303" -SLAPIKey "b4A5Kty2D7QkTa68FrYz"