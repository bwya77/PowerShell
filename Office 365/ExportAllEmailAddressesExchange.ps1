#This powershell script will export all primary and alias email addresses for all users in exchange to a CSV file

Get-Mailbox -ResultSize Unlimited |Select-Object DisplayName,ServerName,PrimarySmtpAddress, @{Name=“EmailAddresses”;Expression={$_.EmailAddresses |Where-Object {$_.PrefixString -ceq “smtp”} | ForEach-Object {$_.SmtpAddress}}} | Export-CSV -NoTypeInformation C:\ExportedEmails.csv
