$License = "thelazyadministrator:STANDARDPACK"
$CountryCode = "US"


$NotFound = 0
$NotLic = 0
$AddLic = 0
$AlreadyLic = 0
$NotAbletoLic = 0

$UserCredential = Get-Credential -Message "Please enter your Office 365 credentials"
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell/" -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
Connect-MsolService -Credential $UserCredential

$Users = Get-MigrationUser | Select-Object -ExpandProperty Identity
Foreach ($User in $Users)
{
	Write-Host "Working on $User..." -ForegroundColor White
	$IdenClean = $User.Split("@")[0]
	Write-Host "Finding $User in Office 365..." -ForegroundColor White
	$Present = Get-MsolUser | Where-Object { $_.UserPrincipalName -like "*$IdenClean*" }
	If (!($Present))
	{
		Write-Warning -Message "$User not found!"
		$NotFound++
	}
	Else
	{
		Write-Host "$($Present.DisplayName) is in Office365!" -ForegroundColor Green
		Write-Host "Checking if $($Present.DisplayName) is licensed.." -ForegroundColor White
		$LicStatus = $Present | Select-Object -ExpandProperty isLicensed
		If ($LicStatus -eq $False)
		{
			$NotLic ++
			Write-Warning -Message "$($Present.DisplayName) is not licensed!"
			
			Write-Host "Checking to see if any there is an avaialble $License license to assign to $($Present.DisplayName)..." -ForegroundColor White
			$Consumed = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -like "*$License*" } | Select-Object -ExpandProperty ConsumedUnits
			$Active = Get-MsolAccountSku | Where-Object { $_.AccountSkuId -like "*$License*" } | Select-Object -ExpandProperty ActiveUnits
			$AvailLic = $active - $Consumed
			If ($AvailLic -gt 0)
			{
				
				Write-Host "Setting $($Present.DisplayName)'s usage location to $CountryCode..." -ForegroundColor Yellow
				Set-MsolUser -UserPrincipalName ($Present).UserPrincipalName -UsageLocation $CountryCode
				Write-Host "licensing $($Present.DisplayName)..." -ForegroundColor Yellow
				Set-MsolUserLicense -UserPrincipalName ($Present).UserPrincipalName -AddLicenses $License
				$AddLic++
			}
			Else
			{
				$NotAbletoLic++
				Write-Warning -Message "Please purchase for $License licenses, there are $AvailLic left"
			}
		}
		Else
		{
			$AlreadyLic++
			Write-Host "$($Present.DisplayName) is licensed!" -ForegroundColor Green
		}
		
	}
}

Write-Host "
             END STATS
----------------------------------

Batch Users:$(($Users).count)
Users Not Found in Office 365 $NotFound
Users That Were Not Licensed: $NotLic
Users With Licenses Added: $AddLic
Users Not Able to be Licensed: $NotAbletoLic
Users Already Licensed: $AlreadyLic

-----------------------------------
" 

Get-PSSession | Remove-PSSession