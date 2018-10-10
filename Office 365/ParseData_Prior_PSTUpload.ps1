$LogFile = "C:\Automation\PSTChanges_Final.txt"

"INFO: GETTING ALL PST FILES" | Out-File $LogFile -Append
$items = Get-ChildItem -Recurse -LiteralPath "E:\Archive-Email\" | Where-Object {$_.Extension -eq ".pst"}
"DATA: PST FILES FOUND $items" | Out-File $LogFile -Append
$count = 0

foreach ($item in $items)
{
    $count++
    "INFO: WORKING ON $Item" | Out-File $LogFile -Append
    Write-Host "Working on $($item.Name)"

    #Get the full path of the pst file 
    $Path = $Item.FullName
    Write-Host "Path is $($Item.FullName)"
    "DATA: FULL PATH OF THE PST FILE: $path" | Out-File $LogFile -Append

    #Trim everything after the first underscore, trim the ending 152
    $NewDir = (($Path.Substring(0, $Path.IndexOf('_'))).trim("152"))
    "DATA: NEW DIRECTORY THAT WILL BE MADE: $NewDir" | Out-File $LogFile -Append

    $Name = $NewDir.Replace("E:\Archive-Email\","")
    "INFO: USERNAME FOR USER IS $Name" | Out-File $LogFile -Append

    #Check to see if the folder is created already
    "INFO: CHECKING TO SEE IF THE FOLDER: $NewDir IS ALREADY PRESENT" | Out-File $LogFile -Append
    $check = Test-Path -Path $NewDir
    "DATA: RESULT WAS: $check" | Out-File $LogFile -Append

    #If the directory is not present then create it 
    if ($check -eq $false)
    {
        "INFO: CHECK FALSE TRIPPED, CREATING NEW DIRECTORY" | Out-File $LogFile -Append
        $Create = New-Item -ItemType Directory -Name $Name -Path $NewDir.Replace("$Name","")
        "DATA: NEW DIRECTORY RESULTS: $Create" | Out-File $LogFile -Append
    }

    #Move the pst file over to the new directory
    "INFO: MOVING THE PST FILE TO $NewDir" | Out-File $LogFile -Append
    Move-Item -Path $($item.FullName) -Destination $NewDir

    #Rename the old pst file, the new name will be username and then an numerical incriment
    "INFO: RENAMING THE OLD PST FILE TO $Name$count.pst" | Out-File $LogFile -Append
    Rename-Item -Path "$NewDir\$($item.Name)" -NewName "$Name$count.pst"
    "INFO: RENAMING $NewDir\$($item.Name) to $Name$count.pst" | Out-File $LogFile -Append


    "INFO: COMPLETED SCRIPT BLOCK. MOVING TO THE NEXT PST" | Out-File $LogFile -Append
}



