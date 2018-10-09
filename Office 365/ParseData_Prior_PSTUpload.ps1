$items = Get-ChildItem -Recurse -LiteralPath "E:\Archive-Email\" | Where-Object {$_.Extension -eq ".pst"}
$count = 0

foreach ($item in $items)
{
    $count++
    Write-Host "Working on $($item.Name)"

    #Get the full path of the pst file 
    $Path = $Item.FullName
    #Trim everything after the first underscore, trim the ending 152
    $NewDir = (($Path.Substring(0, $Path.IndexOf('_'))).trim("152"))
    #Check to see if the folder is created already
    $check = Test-Path -Path $NewDir
    #If the directory is not present then create it 
    if ($check -eq $false)
    {
        New-Item -ItemType Directory -Name $(($NewDir).Trim("E:\Archive-Email\")) -Path $NewDir
    }
    #Rename the old pst file, the new name will be username and then an numerical incriment
    Rename-Item -Path $item.FullName -NewName ""$(($NewDir).Trim("E:\Archive-Email\"))"+"$count"+".pst""

    #Move the pst file over to the new directory
    Move-Item -Path ""$NewDir"+"$count"+".pst"" -Destination $NewDir
    
}

