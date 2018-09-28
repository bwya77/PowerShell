<#	
	.NOTES
	===========================================================================
	 Created on:   	10/12/2017
	 Created by:   	Bradley Wyatt
	===========================================================================
	.DESCRIPTION
		This PowerShell script will take a csv of users and find them in Office 365 and check their license status.
        This was created because I was doing a Remote Move migration and wanted to check if the users had a valid license
        prior to completing their migration batch.
#>
#Variable counters
$UsersnotfoundinOffice365 = 0
$Userswithalicense = 0
$Userswithoutalicense = 0
$UsersChecked = 0
 
 
#CSV with the users
$CSVCheck = "C:\Scripts\lic_check.csv"
#Get credential to log into Office 365
$UserCredential = Get-Credential
Write-Host "Connecting to Office 365..." -ForegroundColor Yellow
#Connect to Office 365
Connect-MsolService -Credential $UserCredential
 
Import-Csv $CSVCheck | Foreach-Object{
	#CSV headers to variables to work with
	$Users = $_.Name
	
	#Display a status to the shell on what user its working on
	Write-Host "Working on $Users" -ForegroundColor Yellow
    $UsersChecked++
	
	
	#Find the user from the CSV and match them with an Office 365 user
	$LicensedUsers = (Get-MsolUser | Where-Object { $_.DisplayName -like "*$Users*" }).UserPrincipalName
	If (!($LicensedUsers))
	{
		Write-Host "Could not find a matched user in Office 365 for $Users" -ForegroundColor Red
		$UsersnotfoundinOffice365++
	}
	Else
	{
		Write-Host "Matched $Users with $LicensedUsers" -ForegroundColor White
		
		Foreach ($LicensedUser in $LicensedUsers)
		{
			Write-Host "Checking license for $LicensedUser..." -ForegroundColor White
            #Get the users isLiscensed attribute value
			$LicenseStatus = (Get-MsolUser -UserPrincipalName $LicensedUser).isLicensed
			
			If ($LicenseStatus -eq "True")
			{
				Write-Host "$LicensedUser is Licensed!" -ForegroundColor Green
				$Userswithalicense++
			}
			Else
			{
				Write-Host "$LicensedUser is not Licensed!" -ForegroundColor Red
				$Userswithoutalicense++
			}
			
		}
	}
	
	
	
	
}
#End script stats
Write-Host "--------------------------STATS------------------------------" -ForegroundColor White
Write-Host "TOTAL USERS CHECKED: $UsersChecked" -ForegroundColor Black -BackgroundColor White
Write-Host "USERS NOT FOUND IN OFFICE 365: $UsersnotfoundinOffice365" -ForegroundColor Black -BackgroundColor White
Write-Host "USERS NOT LICENSED: $Userswithoutalicense" -ForegroundColor Black -BackgroundColor White
Write-Host "USERS WITHA  LICENSE: $Userswithalicense" -ForegroundColor Black -BackgroundColor White
Write-Host "-------------------------------------------------------------" -ForegroundColor White
