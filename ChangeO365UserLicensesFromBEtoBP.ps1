#VARIABLES
$LicenseAdd = "O365_BUSINESS_PREMIUM"
$LicenseRemove = "O365_BUSINESS_ESSENTIALS"

#Get credential to log into 
$UserCredential = Get-Credential

Write-Host "Connecting to Office 365..." -ForegroundColor Yellow
Connect-MsolService -Credential $UserCredentiget-msolaccal

$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
get-msolImport-PSSession $Session -AllowClobber

$Users = Get-MSOLUser -All | Where-Object { $_.isLicensed -eq "TRUE" -and $_.Licenses.AccountSKUID -like "*reseller-account:O365_BUSINESS_ESSENTIALS*" }
Foreach ($User in $Users)
{
	
		$UPN = ($User).UserPrincipalName
		$DN = ($User).DisplayName
		
		#Get License AccountSkuId
		$License = "reseller-account:O365_BUSINESS_PREMIUM"
		
		#Get License AccountSkuId
		$RemoveLicense = "reseller-account:O365_BUSINESS_ESSENTIALS"
		
		#Add Business Essentials license to the user
		Write-Host "Adding Business Essentials license for $DN..." -ForegroundColor White
		Set-MsolUserLicense -UserPrincipalName $UPN -AddLicenses $License
		
		#Remove Business Premium License for user
		Write-Host "Removing Business Premium license from $DN..." -ForegroundColor White
		Set-MsolUserLicense -UserPrincipalName $UPN -RemoveLicenses $RemoveLicense
	
}

Get-PSSession | Remove-PSSession
