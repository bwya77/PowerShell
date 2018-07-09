<#	
	.NOTES
	===========================================================================
	 Updated on:   	7/9/2018
	 Created by:   	Bradley Wyatt
	===========================================================================
	.DESCRIPTION
		Parse computers to provide a list of local administrators. Uses WMI
#>


$CSV = "C:\Test\LocalAdmins.csv"
$strcomputerS = (Get-ADComputer -Filter * -SearchBase "OU=Laptops,OU=Chicago,DC=TheLazyAdministrator,DC=com").Name


Foreach ($strcomputer in $strcomputerS)
{
	Write-Host "Working on $strcomputer" -ForegroundColor Yellow
	
	$admins = Get-WmiObject win32_groupuser -ComputerName $strcomputer -ErrorAction SilentlyContinue
	If ($null -ne $admins)
	{
		$admins = $admins | Where-Object { $_.groupcomponent –like '*"Administrators"' }
		
		$admins | ForEach-Object {
			$_.partcomponent –match ".+Domain\=(.+)\,Name\=(.+)$" > $null
			$LAdmin = $matches[1].trim('"') + "\" + $matches[2].trim('"')
			$LAdmin | Select-Object @{ name = 'Computer'; expression = { $strcomputer } }, @{ name = 'LocalAdmins'; expression = { $LAdmin } } | Export-Csv -NoTypeInformation $CSV -Append
		}
		Write-Host "Done" -ForegroundColor Green
		
	}
	Else
	{
		Write-Host "$strcomputer is not reachable" -ForegroundColor Red
		$strcomputer | Select-Object @{ name = 'Computer'; expression = { $strcomputer } }, @{ name = 'LocalAdmins'; expression = { "Not Available" } } | Export-Csv -NoTypeInformation $CSV -Append
	}
}