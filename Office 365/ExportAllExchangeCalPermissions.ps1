#This PowerShell Script will export a list of all users and the calendar permissions to CSV. This should be ran as 2 seperate commands

$results = foreach ($mbx in (get-mailbox -resultsize unlimited)) {Get-MailboxFolderPermission ($mbx.samaccountname+":\calendar") | select @{MailboxName='Name';Expression={$mbx.Name}}, FolderName,Identity,Accessrights}

$results | select {$_.MailboxName},{$_.FolderName},{$_.Identity},{$_.Accessrights} | Export-Csv c:\data.csv -NoTypeInformation
