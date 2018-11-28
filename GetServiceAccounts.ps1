$Cred = Get-Credential
$Computers = "BWDC01","BWTS","BW-WORDPRESS"
$CSVPath = "C:\Scripts\ServiceAccounts.csv"
ForEach ($Computer in $Computers)
{
Get-WmiObject win32_service -ComputerName $Computer -Credential $Cred | Sort-Object Name | Select-Object PSComputerName, Name, StartName, StartMode | Export-CSV -Path $CSVPath -Append -NoTypeInformation
}
