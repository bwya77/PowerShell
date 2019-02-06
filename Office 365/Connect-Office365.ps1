<#
	.NOTES
		===========================================================================
		Created on:   	2/4/2019 10:42 PM
		Created by:   	Bradley Wyatt
		E-Mail:			Brad@TheLazyAdministrator.com
		GitHub:			https://github.com/bwya77
		Website:		https://www.thelazyadministrator.com
		Organization: 	Porcaro Stolarek Mete Partners; The Lazy Administrator
		Filename:     	Connect-Office365.ps1
		Version: 		1.0.1

		Changelog:
		1.0.1
			CHANGED
				- How the function finds the MFA Module
		===========================================================================

    .SYNOPSIS
        Connect to Office 365 Services

    .DESCRIPTION
        Connect to different Office 365 Services using PowerShell function. Supports MFA. 

    .PARAMETER MFA
        Type: Boolean
		Description: Specifies MFA requirement to sign into Office 365 services. If set to $True it will use the Office 365 ExoPSSession Module to sign into Exchange & Compliance Center using MFA. Other modules support MFA without needing another external module

    .PARAMETER Exchange
        Type: Switch
		Description: Connect to Exchange Online

    .PARAMETER SkypeForBusiness
        Type: Switch
		Description: Connect to Skype for Business

    .PARAMETER SharePoint
        Type: Switch
		Description: Connect to SharePoint Online

	.PARAMETER SecurityandCompliance
		Type: Switch
		Description: Connect to Security and Compliance Center

	.PARAMETER AzureAD
		Type: Switch 
		Description: Connect to Azure AD V2

	.PARAMETER MSOnline
		Type: Switch
		Description: Connect to Azure AD V1

	.PARAMETER Teams
		Type: Switch
		Description: Connect to Teams

    .EXAMPLE
		Description: Connect to SharePoint Online
        C:\PS> Connect-Office365 -SharePoint

    .EXAMPLE
		Description: Connect to Exchange Online and Azure AD V1 (MSOnline)
        C:\PS> Connect-Office365 -Exchange -MSOnline

    .EXAMPLE
		Description: Connect to Exchange Online and Azure AD V2 using Multi-Factor Authentication
        C:\PS> Connect-Office365 -Exchange -AzureAD -MFA $True

	.EXAMPLE
		Description: Connect to Teams and Skype for Business
        C:\PS> Connect-Office365 -Teams -SkypeForBusiness

    .LINK
        Online version:  https://www.thelazyadministrator.com/2019/02/05/powershell-function-to-connect-to-all-office-365-services
    #>

function Connect-Office365
{
	Param (
		[Parameter(Mandatory = $False, Position = 1, ValueFromPipeline = $False)]
		[Boolean]$MFA,
		[Parameter(Mandatory = $False, Position = 2, ValueFromPipeline = $False)]
		[Switch]$Exchange,
		[Parameter(Mandatory = $False, Position = 3, ValueFromPipeline = $False)]
		[Switch]$SkypeForBusiness,
		[Parameter(Mandatory = $False, Position = 4, ValueFromPipeline = $False)]
		[Switch]$SharePoint,
		[Parameter(Mandatory = $False, Position = 5, ValueFromPipeline = $False)]
		[Switch]$SecurityandCompliance,
		[Parameter(Mandatory = $False, Position = 6, ValueFromPipeline = $False)]
		[Switch]$AzureAD,
		[Parameter(Mandatory = $False, Position = 7, ValueFromPipeline = $False)]
		[Switch]$MSOnline,
		[Parameter(Mandatory = $False, Position = 8, ValueFromPipeline = $False)]
		[Switch]$Teams
		
	)
	If ($MFA -ne $True)
	{
		Write-Host "Gathering User Credentials"
		$UserCredential = Get-Credential -Message "Please enter your Office 365 credentials"
	}
	If ($Exchange -eq $True)
	{
		Write-Host "Connecting to Exchange Online" -ForegroundColor Green
		If ($MFA -eq $True)
		{
			Write-Host "MFA login is enabled"
			
			Write-Host "Checking for Exchange Online MFA Module"
			#$MFAExchangeModule = ((Get-ChildItem $Env:LOCALAPPDATA\Apps\2.0\*\CreateExoPSSession.ps1 -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Target -First 1).Replace("CreateExoPSSession.ps1", ""))
			$MFAExchangeModule = ((Get-ChildItem -Path $Env:LOCALAPPDATA\Apps\2.0\ -Filter CreateExoPSSession.ps1 -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -Last 1).Directory)
			If ($null -eq $MFAExchangeModule)
			{
				Write-Warning "The Exchange Online MFA Module was not found!
https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/mfa-connect-to-exchange-online-powershell?view=exchange-ps"
				
			}
			Else
			{
				Write-Host "Importing Exchange MFA Module"
				. "$MFAExchangeModule\CreateExoPSSession.ps1"

				Write-Host "Connecting to Exchange Online with MFA"
				Connect-EXOPSSession 
			}
		}
		Else
		{
			Write-Host "Creating Exchange Online PSSession"
			$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell/" -Credential $UserCredential -Authentication Basic -AllowRedirection
			Write-Host "Importing Session"
			Import-PSSession $Session -AllowClobber
		}
	}
	If ($SkypeForBusiness -eq $True)
	{
		Write-Host "Connecting to Skype Online" -ForegroundColor Green
		If ($null -eq (Get-Module -ListAvailable -Name "SkypeOnlineConnector"))
		{
			Write-Warning "SkypeOnlineConnector Module is not present!"
		}
		Else
		{
			If ($MFA -eq $True)
			{
				#Skype for Business module
				Import-Module SkypeOnlineConnector
				$CSSession = New-CsOnlineSession
				Import-PSSession $CSSession -AllowClobber
			}
			Else
			{
				#Skype for Business module
				Import-Module SkypeOnlineConnector
				$CSSession = New-CsOnlineSession -Credential $UserCredential
				Import-PSSession $CSSession -AllowClobber
			}
			
		}
	}
	If ($SharePoint -eq $True)
	{
		Write-Host "Connecting to SharePoint" -ForegroundColor Green
		If ($null -eq (Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell))
		{
			Write-Warning "Microsoft.Online.SharePoint.PowerShell Module is not present!"
		}
		Else
		{
			If ($MFA -eq $True)
			{
				Write-Host "Gathering tenant name"
				$orgName = Read-Host "Please enter your tenant name to connect to SharePoint. EX: https://THELAZYADMINISTRATOR.sharepoint.com, my tenant name is THELAZYADMINISTRATOR"
				Write-Host "Connecting to https://$orgName-admin.sharepoint.com"
				Connect-SPOService -Url "https://$orgName-admin.sharepoint.com"
			}
			Else
			{
				Write-Host "Gathering tenant name"
				$orgName = Read-Host "Please enter your tenant name to connect to SharePoint. EX: https://THELAZYADMINISTRATOR.sharepoint.com, my tenant name is THELAZYADMINISTRATOR"
				Write-Host "Connecting to https://$orgName-admin.sharepoint.com"
				Connect-SPOService -Url "https://$orgName-admin.sharepoint.com" -Credential $userCredential
			}
			
		}
	}
	If ($SecurityandCompliance -eq $True)
	{
		Write-Host "Connecting to Security and Compliance Center" -ForegroundColor Green
		If ($MFA -eq $True)
		{
			Write-Host "MFA login is enabled"
			
			Write-Host "Checking for Exchange Online MFA Module (Required)"
			#$MFAExchangeModule = ((Get-ChildItem $Env:LOCALAPPDATA\Apps\2.0\*\CreateExoPSSession.ps1 -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Target -First 1).Replace("CreateExoPSSession.ps1", ""))
			$MFAExchangeModule = ((Get-ChildItem -Path $Env:LOCALAPPDATA\Apps\2.0\ -Filter CreateExoPSSession.ps1 -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -Last 1).Directory)
			If ($null -eq $MFAExchangeModule)
			{
				Write-Warning "The Exchange Online MFA Module was not found!
https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/mfa-connect-to-exchange-online-powershell?view=exchange-ps"
				
			}
			Else
			{
				Write-Host "Importing Exchange MFA Module (Required)"
				. "$MFAExchangeModule\CreateExoPSSession.ps1"
				
				Write-Host "Connecting to Security and Compliance Center"
				Connect-IPPSSession
			}
		}
		Else
		{
			Write-Host "Creating New PSSession"
			$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
			Write-Host "Importing PSSession"
			Import-PSSession $Session -DisableNameChecking
		}
	}
	If ($AzureAD -eq $True)
	{
		Write-Host "Connecting to Azure AD" -ForegroundColor Green
		
		Write-Host "Checking for AzureAD Module"
		If ($null -eq (Get-Module -ListAvailable -Name "AzureAD"))
		{
			Write-Warning "SkypeOnlineConnector Module is not present!"
			
		}
		Else
		{
			If ($MFA -eq $True)
			{
				Connect-AzureAD
			}
			Else
			{
				Connect-AzureAD -Credential $userCredential
			}
			
		}
	}
	If ($MSOnline -eq $True)
	{
		Write-Host "Connecting to MSOnline" -ForegroundColor Green
		
		Write-Host "Checking for MSOnline Module"
		If ($null -eq (Get-Module -ListAvailable -Name "MSOnline"))
		{
			Write-Warning "MSOnline Module is not present!"
		}
		Else
		{
			If ($MFA -eq $True)
			{
				Write-Host "MSOnline Module is present"
				Write-Host "Connecting to MSOL Service" -ForegroundColor Green
				Connect-MsolService
			}
			Else
			{
				Write-Host "MSOnline Module is present"
				Write-Host "Connecting to MSOL Service" -ForegroundColor Green
				Connect-MsolService -Credential $userCredential
			}
		}
	}
	If ($Teams -eq $True)
	{
		Write-Host "Connecting to Teams" -ForegroundColor Green
		
		Write-Host "Checking for MicrosoftTeams Module"
		If ($null -eq (Get-Module -ListAvailable -Name "MicrosoftTeams"))
		{
			Write-Warning "MicrosoftTeams Module is not present!"
		}
		Else
		{
			If ($MFA -eq $True)
			{
				Write-Host "MicrosoftTeams Module is present"
				Connect-MicrosoftTeams
			}
			Else
			{
				Write-Host "MicrosoftTeams Module is present"
				Connect-MicrosoftTeams -Credential $userCredential
			}
			
		}
	}
	If (($Teams -eq $False) -and ($MSOnline -eq $False) -and ($AzureAD -eq $false) -and ($SharePoint -eq $False) -and ($MFA -eq $False) -and ($SkypeForBusiness -eq $False) -and ($SecurityandCompliance -eq $False))
	{
		Write-Warning "No Services Specified to Connect to! Please Select a Service to Connect to"
	}
	
}
