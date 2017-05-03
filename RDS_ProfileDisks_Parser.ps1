# This script will go through Profile Disk VHDs/VHDx's, find the user of that profile disk by converting the SID to the username,
# mount the image, find out the mount drive letter, parse the profile disk and copy a specified folder or file to the local machine 
# (or UNC to another machine) (it will create a folder using the users USERNAME to easily identify the folder content owner, unmount the 
# profile disk and do the same with the next profile disk.

#So this script will now
# - Go through a directory of profile disks
# - Mount the profile disk
# - Convert the SID to Username to find the owner of the Profile Disk
# - Create a root directory using the user's Username
# - Copy a folder or file over to that directory
# - Give the admin a status in the console, lettting them know which user the script is on

# If you want to convert the SID to usernames you must have access to Active Directory for the AD cmdlets

function get-mountedvhdDrive {            
$disks = Get-CimInstance -ClassName Win32_DiskDrive | where Caption -eq "Microsoft Virtual Disk"            
foreach ($disk in $disks){            
 $vols = Get-CimAssociatedInstance -CimInstance $disk -ResultClassName Win32_DiskPartition             
 foreach ($vol in $vols){            
   Get-CimAssociatedInstance -CimInstance $vol -ResultClassName Win32_LogicalDisk |            
   where VolumeName -ne 'System Reserved'            
        }            
    }            
}

$ExportedFiles = "D:\Export\"
$UPDShare = "D:\Test\"
#$VHD_root = "D:\Test\*"
$VHDS = (get-ChildItem "$UPDShare\*" -Include *.vhdx -Recurse).Name
    ForEach ($VHD in $VHDS)
    {
    
    $SID = [io.path]::GetFileNameWithoutExtension("$VHD")

    $SidFinal =  $SID | %{ $_.SubString(5) }
    $User = (Get-ADUser -identity $SIDFinal).Name
    Write-Host "Working on $User..." -ForegroundColor Green

    $VHDfull = "$UPDShare"+"$VHD"
    Mount-DiskImage $VHDfull
    $Drives = (get-mountedvhdDrive).DeviceID
    $NewDir = New-Item "D:\Export\$User" -ItemType Directory -Force
    #Telling what Item I want to copy over, here I am saying the Users Desktop folder
    $Source = "$Drives\Desktop"
    $Destination = "$ExportedFiles\$User"
    #Recurse will go into each folder and copy those contents as well, folder structure is kept
    Copy-Item $Source $Destination -Force -Recurse
    #Dismounting the image
    Dismount-DiskImage $VHDfull

    }
  
