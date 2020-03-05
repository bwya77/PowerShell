$Computers = Get-ADComputer -Filter * -SearchBase "OU=Azure,OU=Servers,OU=Systems,OU=Chicago" -Properties *
$Output = @()
$CSVFile = "$env:TEMP\drivespace.csv" 

Foreach ($Computer in $Computers)
    {
    Write-Host "Getting drive sizes for $($computer.name)"
    $Output += Get-WmiObject Win32_LogicalDisk -Filter "DriveType='3'" -ComputerName $Computer.Name | ForEach {
                    New-Object PSObject -Property @{
                    Computer = $Computer.Name
                    DriveLetter = $_.Name
                    Label = $_.VolumeName
                    FreeSpace_GB = ([Math]::Round($_.FreeSpace/1GB,2))
                    TotalSize_GB = ([Math]::Round($_.Size/1GB,2))
                    UsedSpace_GB = ([Math]::Round($_.Size /1GB,2)) - ([Math]::Round($_.FreeSpace /1GB,2))
                }
            }
    }

$Output | Export-Csv -NoTypeInformation -Path $CSVFile -Force
