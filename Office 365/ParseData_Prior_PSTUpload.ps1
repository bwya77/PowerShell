<#
.Description
    This script was made to parse pst data from an old provider and prep it for upload to Azure Blob Storage. 
    It cleaned up the folder structure so there was not a bunch of nested folders that housed pst files and 
    also renamed the pst files to be the username[INT][INT].pst and saved in a folder that had the name of the
    username. 

    The folder structure looked like this:
    E:\
        Archive-Email
            BWyatt152_20180310131700
                20180310131703
                    0
                        0-1.pst
                    1
                        0-2.pst
            BRobertson152__20180310132700
                20180310132703
                    0
                        0-1.pst
                    1
                        0-2.pst
                    2
                        0-3.pst

    So this script would find all of the .pst files, store them in an array and then for each pst:
        - Grab the username by dropping everything after the underscore (ex: BWyatt152_20180310131700)
        - Remove the trailing 152 (this would leave us with BWyatt)
        - Create a new root folder with the name of the username (ex: E:\Archive-Email\Bwyatt\)
        - For each PST file it would rename it (ex: 0-1.pst becomes BWyatt1.pst)
        - Moves the new pst (BWyatt1.ps1) to the newly created folder (ex: E:\Archive-Email\Bwyatt\)
        - Repeat for all other pst files for that user. Once its completes all pst files for the user, move to next user
#>

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



