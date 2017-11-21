Function Set-NewHomeDirectory
{
	#Requires -version 3 -Modules ActiveDirectory
<#
.Synopsis
    Change Bulk Users Home Drive Path in Active Directory based on /u/bradleywyatt's.
 
.Description
    Gathers all users with a home drive/directory that points to a specific server, and changes the server portion to point to a new server.
 
.Examples
    Set-NewHomeDirectory.ps1
    Set-NewHomeDirectory.ps1 -oldServer "SRVW2003" -newServer "SRVW2016"
	Set-NewHomeDirectory.ps1 -oldServer "SRVW2003" -newServer "SRVW2016" -DriveLetter "K"
	Set-NewHomeDirectory.ps1 -oldServer SRVW2003 -newServer SRVW2016 -DriveLetter K
#>
	Param (
		[Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $false)]
		[String]$OldServer,
		[Parameter(Mandatory = $True, Position = 2, ValueFromPipeline = $false)]
		[String]$NewServer,
		[Parameter(Mandatory = $False, Position = 3, ValueFromPipeline = $false)]
		[String]$DriveLetter
	)
	$Users = Get-ADUser -filter '*' -Properties homeDirectory | Where-Object { $_.homeDirectory -like "*\\$OldServer\*" }
	If (!($Users))
	{
		Write-Host "ERROR: No users were found with a home directory pointing to server $OldServer!" -ForegroundColor Red
	}
	Else
	{
		Foreach ($User in $Users)
		{
			#Gets the Display Name of the user
			$DN = ($User).Name
			Write-Host "Working on $DN..." -ForegroundColor Yellow
			
			If (!($DriveLetter))
			{
				#Gathers the users current Home Directory and stores it into a variable
				$str = ($User).HomeDirectory
				#Takes the home directory variable and replaces old server value with the new server
				$NewHomeDir = $str -replace "$OldServer", "$NewServer"
				
				Write-Host "Setting the Home Directory of $DN to $NewHomeDir" -ForegroundColor White
				#Sets the HomeDir of the user to our HomeDir variable
				Set-ADUser $User.SamAccountName -homedirectory $NewHomeDir
			}
			Else
			{
				#Gathers the users current Home Directory and stores it into a variable
				$str = ($User).HomeDirectory
				#Takes the home directory variable and replaces old server value with the new server
				$NewHomeDir = $str -replace "$OldServer", "$NewServer"
				
				Write-Host "Setting the Home Directory of $DN to $NewHomeDir" -ForegroundColor White
				#Sets the HomeDir of the user to our HomeDir variable
				Set-ADUser $User.SamAccountName -homedirectory $NewHomeDir -HomeDrive $DriveLetter
			}
			
		}
	}
}
