Function Get-O365LicenseReport
{
	#Requires -version 3 -Modules ActiveDirectory
<#
.Synopsis
    Gather a license report from your main Office 365 tenant or all tenants your partner manages
 
.Description
   Gather a license report from your main Office 365 tenant or all tenants your partner manages. Export report to CSV or display the results in the shell
 
.Examples
    Get-O365LicenseReport
    Get-O365LicenseReport -Partner $True -ExportResults "C:\Scripts\license.csv"
	Get-O365LicenseReport -Partner $True
    Get-O365LicenseReport -Partner $True -UnusedLicenseReportOnly $True -ExportResults "C:\Scripts\function.csv"
    Get-O365LicenseReport -UnusedLicenseReportOnly $True 
#>
	Param (
		[Parameter(Mandatory = $False, Position = 1, ValueFromPipeline = $false)]
		[String]$ExportResults,
		[Parameter(Mandatory = $False, Position = 2, ValueFromPipeline = $false)]
		[String]$Partner,
		[Parameter(Mandatory = $False, Position = 3, ValueFromPipeline = $false)]
		[String]$UnusedLicenseReportOnly
	)
	If (!($Partner))
	{
		$Cred = Get-Credential
		Connect-MSOLService -Credential $Cred
		Import-Module MSOnline
		
		$msolAccountSkuResults = @()
		$msolAccountSkuCsv = $OutFile
		
		$licenses = Get-MsolAccountSku
		
		foreach ($license in $licenses)
		{
			
			$UnusedUnits = $license.ActiveUnits - $license.ConsumedUnits
			$licenseProperties = @{
				UnusedUnits	      = $unusedUnits
				AccountSkuId	  = $license.AccountSkuId
				ConsumedUnits	  = $license.ConsumedUnits
				WarningUnits	  = $license.WarningUnits
				ActiveUnits	      = $license.ActiveUnits
			}
			$msolAccountSkuResults += New-Object psobject -Property $licenseProperties
		}
		
		If (!($ExportResults))
		{
			If (!($UnusedLicenseReportOnly))
			{
				$msolAccountSkuResults | Select-Object AccountSkuId, ActiveUnits, ConsumedUnits, WarningUnits, UnusedUnits | Format-Table -AutoSize
			}
			Else
			{
				$msolAccountSkuResults | Select-Object AccountSkuId, UnusedUnits | Format-Table -AutoSize
			}
		}
		Else
		{
			If (!($UnusedLicenseReportOnly))
			{
				$msolAccountSkuResults | Select-Object AccountSkuId, ActiveUnits, ConsumedUnits, WarningUnits, UnusedUnits | Export-Csv -notypeinformation -Path $ExportResults
			}
			Else
			{
				$msolAccountSkuResults | Select-Object AccountSkuId, UnusedUnits | Export-Csv -notypeinformation -Path $ExportResults
			}
		}
		Get-PSSession | Remove-PSSession
	}
	Else
	{
		$Cred = Get-Credential
		Connect-MSOLService -Credential $Cred
		Import-Module MSOnline
		
		$clients = Get-MsolPartnerContract -All
		
		$msolAccountSkuResults = @()
		
		ForEach ($client in $clients)
		{
			Write-Host "Getting licenses for $($Client.Name)..." -ForegroundColor Yellow
			
			$licenses = Get-MsolAccountSku -TenantId $client.TenantId
			
			foreach ($license in $licenses)
			{
				
				$UnusedUnits = $license.ActiveUnits - $license.ConsumedUnits
				
				$licenseProperties = @{
					TenantId   = $client.TenantID
					CompanyName = $client.Name
					PrimaryDomain = $client.DefaultDomainName
					AccountSkuId = $license.AccountSkuId
					AccountName = $license.AccountName
					SkuPartNumber = $license.SkuPartNumber
					ActiveUnits = $license.ActiveUnits
					WarningUnits = $license.WarningUnits
					ConsumedUnits = $license.ConsumedUnits
					UnusedUnits = $unusedUnits
				}
				
				$msolAccountSkuResults += New-Object psobject -Property $licenseProperties
			}
			
		}
		If (!($ExportResults))
		{
			If (!($UnusedLicenseReportOnly))
			{
				$msolAccountSkuResults | Select-Object CompanyName, AccountSkuId, ActiveUnits, ConsumedUnits, WarningUnits, UnusedUnits | Format-Table -AutoSize
			}
			Else
			{
				$msolAccountSkuResults | Select-Object CompanyName, AccountSkuId, UnusedUnits | Format-Table -AutoSize
			}
		}
		Else
		{
			If (!($UnusedLicenseReportOnly))
			{
				$msolAccountSkuResults | Select-Object CompanyName, AccountSkuId, ActiveUnits, ConsumedUnits, WarningUnits, UnusedUnits | Export-Csv -notypeinformation -Path $ExportResults
			}
			Else
			{
				$msolAccountSkuResults | Select-Object CompanyName, AccountSkuId, UnusedUnits | Export-Csv -notypeinformation -Path $ExportResults
			}
		}
		Get-PSSession | Remove-PSSession
		
	}
}
