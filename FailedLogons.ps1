$myObject = @()

$EventLogs = Get-WinEvent -ComputerName localhost -FilterHashtable @{
    LogName = 'Security'
    ID = 4625
}

Foreach ($event in $EventLogs)
{
[string]$Item = $Event.Message 

$AccountName = $Item.SubString($Item.IndexOf("Account For Which Logon Failed:"))
$AccountName = $AccountName.SubString($AccountName.IndexOf("	Account Name:"))
$AccountName = ($AccountName -split ':')[1]
$AccountName = ($AccountName -split '\n')[0]
$AccountName = $AccountName.trim()


$Reason = $Item.SubString($Item.IndexOf("Failure Reason:"))
$Reason = $Reason.SubString($Reason.IndexOf("Failure Reason:"))
$Reason = ($Reason -split ':')[1]
$Reason = ($Reason -split '\n')[0]
$Reason = $Reason.trim()

$myObject += [PSCustomObject]@{
    TimeCreated     = $($Event.TimeCreated)
    ID              = $($Event.ID)
    User            = $AccountName
    Reason          = $Reason
}
}






