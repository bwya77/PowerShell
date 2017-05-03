# This script will go through Profile Disk VHDs/VHDx's, find the user of that profile disk by converting the SID to the username,
# mount the image, find out the mount drive letter, parse the profile disk and copy a specified folder or file to the local machine 
# (or UNC to another machine) (it will create a folder using the users USERNAME to easily identify the folder content owner, unmount the 
# profile disk and do the same with the next profile disk.

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


$UPDShare = "C:\Hyper-V\Virtual Machines\New\"
$VHDS = "C:\Hyper-V\Virtual Machines\New\*"
$fc = new-object -com scripting.filesystemobject
$folder = $fc.getfolder($UPDShare)
foreach ($i in $folder.files)
{
  $sid = $i.Name
  $sid = $sid.Substring(5,$sid.Length-10)
  if ($sid -ne "template")
  {
    $securityidentifier = new-object security.principal.securityidentifier $sid
    $user = ( $securityidentifier.translate( [security.principal.ntaccount] ) ).Value
    ForEach ($VHD in $VHDS)
    {
    Mount-VHD -Path $VHD
    $Drives = (get-mountedvhdDrive).DeviceID
        ForEach ($Drive in $Drives)
        {
        $NewDir = New-Item "C:\Test\$user" -ItemType Directory
        Copy-Item "$Drive\Desktop" $NewDir
        Dismount-VHD $VHD
        }
    }
  }
}
