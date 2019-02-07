function Connect-Office365
{
<#
	.NOTES
		===========================================================================
		Created on:   	2/4/2019 10:42 PM
		Created by:   	Bradley Wyatt
		E-Mail:		Brad@TheLazyAdministrator.com
		GitHub:		https://github.com/bwya77
		Website:	https://www.thelazyadministrator.com
		Organization: 	Porcaro Stolarek Mete Partners; The Lazy Administrator
		Filename:     	Connect-Office365.ps1
		Version: 	1.0.3
	
		Contributors:   /u/Sheppard_Ra
		===========================================================================

    .SYNOPSIS
        Connect to Office 365 Services

    .DESCRIPTION
        Connect to different Office 365 Services using PowerShell function. Supports MFA.

    .PARAMETER MFA
		Description: Specifies MFA requirement to sign into Office 365 services. If set to $True it will use the Office 365 ExoPSSession Module to sign into Exchange & Compliance Center using MFA. Other modules support MFA without needing another external module

    .PARAMETER Exchange
		Description: Connect to Exchange Online

    .PARAMETER SkypeForBusiness
		Description: Connect to Skype for Business

    .PARAMETER SharePoint
		Description: Connect to SharePoint Online

	.PARAMETER SecurityandCompliance
		Description: Connect to Security and Compliance Center

	.PARAMETER AzureAD
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
        C:\PS> Connect-Office365 -Service Exchange, MSOnline

    .EXAMPLE
		Description: Connect to Exchange Online and Azure AD V2 using Multi-Factor Authentication
        C:\PS> Connect-Office365 -Service Exchange, MSOnline -MFA

	.EXAMPLE
		Description: Connect to Teams and Skype for Business
        C:\PS> Connect-Office365 -Service Teams, SkypeForBusiness
	
	.EXAMPLE
		Description: Connect to SharePoint Online
		 C:\PS> Connect-Office365 -Service SharePoint -SharePointOrganizationName bwya77 -MFA

    .LINK
        Online version:  https://www.thelazyadministrator.com/2019/02/05/powershell-function-to-connect-to-all-office-365-services

#>
	
	[OutputType()]
	[CmdletBinding(DefaultParameterSetName)]
	Param (
		[Parameter(Mandatory = $True, Position = 1)]
		[ValidateSet('AzureAD', 'Exchange', 'MSOnline', 'SecurityAndCompliance', 'SharePoint', 'SkypeForBusiness', 'Teams')]
		[string[]]$Service,
		[Parameter(Mandatory = $False, Position = 2)]
		[Alias('SPOrgName')]
		[string]$SharePointOrganizationName,
		[Parameter(Mandatory = $False, Position = 3, ParameterSetName = 'Credential')]
		[PSCredential]$Credential,
		[Parameter(Mandatory = $False, Position = 3, ParameterSetName = 'MFA')]
		[Switch]$MFA
	)
	
	$getModuleSplat = @{
		ListAvailable = $True
		Verbose	      = $False
	}
	
	If ($MFA -ne $True)
	{
		Write-Verbose "Gathering PSCredentials object for non MFA sign on"
		$Credential = Get-Credential -Message "Please enter your Office 365 credentials"
	}
	
	ForEach ($Item in $PSBoundParameters.Service)
	{
		Write-Verbose "Attempting connection to $Item"
		Switch ($Item)
		{
			AzureAD {
				If ($null -eq (Get-Module @getModuleSplat -Name "AzureAD"))
				{
					Write-Error "SkypeOnlineConnector Module is not present!"
					continue
				}
				Else
				{
					If ($MFA -eq $True)
					{
						Connect-AzureAD
					}
					Else
					{
						Connect-AzureAD -Credential $Credential
					}
				}
				continue
			}
			
			Exchange {
				If ($MFA -eq $True)
				{
					$getChildItemSplat = @{
						Path = "$Env:LOCALAPPDATA\Apps\2.0\*\CreateExoPSSession.ps1"
						Recurse = $true
						ErrorAction = 'SilentlyContinue'
						Verbose = $false
					}
					$MFAExchangeModule = ((Get-ChildItem @getChildItemSplat | Select-Object -ExpandProperty Target -First 1).Replace("CreateExoPSSession.ps1", ""))
					
					If ($null -eq $MFAExchangeModule)
					{
						Write-Error "The Exchange Online MFA Module was not found!
        https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/mfa-connect-to-exchange-online-powershell?view=exchange-ps"
						continue
					}
					Else
					{
						Write-Verbose "Importing Exchange MFA Module"
						. "$MFAExchangeModule\CreateExoPSSession.ps1"
						
						Write-Verbose "Connecting to Exchange Online"
						Connect-EXOPSSession
					}
				}
				Else
				{
					$newPSSessionSplat = @{
						ConfigurationName = 'Microsoft.Exchange'
						ConnectionUri	  = "https://ps.outlook.com/powershell/"
						Authentication    = 'Basic'
						Credential	      = $Credential
						AllowRedirection  = $true
					}
					$Session = New-PSSession @newPSSessionSplat
					Write-Verbose "Connecting to Exchange Online"
					Import-PSSession $Session -AllowClobber
				}
				continue
			}
			
			MSOnline {
				If ($null -eq (Get-Module @getModuleSplat -Name "MSOnline"))
				{
					Write-Error "MSOnline Module is not present!"
					continue
				}
				Else
				{
					Write-Verbose "Connecting to MSOnline"
					If ($MFA -eq $True)
					{
						Connect-MsolService
					}
					Else
					{
						Connect-MsolService -Credential $Credential
					}
				}
				continue
			}
			
			SecurityAndCompliance {
				If ($MFA -eq $True)
				{
					$getChildItemSplat = @{
						Path = "$Env:LOCALAPPDATA\Apps\2.0\*\CreateExoPSSession.ps1"
						Recurse = $true
						ErrorAction = 'SilentlyContinue'
						Verbose = $false
					}
					$MFAExchangeModule = ((Get-ChildItem @getChildItemSplat | Select-Object -ExpandProperty Target -First 1).Replace("CreateExoPSSession.ps1", ""))
					If ($null -eq $MFAExchangeModule)
					{
						Write-Error "The Exchange Online MFA Module was not found!
        https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/mfa-connect-to-exchange-online-powershell?view=exchange-ps"
						continue
					}
					Else
					{
						Write-Verbose "Importing Exchange MFA Module (Required)"
						. "$MFAExchangeModule\CreateExoPSSession.ps1"
						
						Write-Verbose "Connecting to Security and Compliance Center"
						Connect-IPPSSession
					}
				}
				Else
				{
					$newPSSessionSplat = @{
						ConfigurationName = 'Microsoft.SecurityAndCompliance'
						ConnectionUri	  = 'https://ps.compliance.protection.outlook.com/powershell-liveid/'
						Authentication    = 'Basic'
						Credential	      = $Credential
						AllowRedirection  = $true
					}
					$Session = New-PSSession @newPSSessionSplat
					Write-Verbose "Connecting to SecurityAndCompliance"
					Import-PSSession $Session -DisableNameChecking
				}
				continue
			}
			
			SharePoint {
				If ($null -eq (Get-Module @getModuleSplat -Name Microsoft.Online.SharePoint.PowerShell))
				{
					Write-Error "Microsoft.Online.SharePoint.PowerShell Module is not present!"
					continue
				}
				Else
				{
					If (-not ($PSBoundParameters.ContainsKey('SharePointOrganizationName')))
					{
						Write-Error 'Please provide a valid SharePoint organization name with the -SharePointOrganizationName parameter.'
						continue
					}
					
					$SharePointURL = "https://{0}-admin.sharepoint.com" -f $SharePointOrganizationName
					Write-Verbose "Connecting to SharePoint at $SharePointURL"
					If ($MFA -eq $True)
					{
						Connect-SPOService -Url $SharePointURL
					}
					Else
					{
						Connect-SPOService -Url $SharePointURL -Credential $Credential
					}
				}
				continue
			}
			
			SkypeForBusiness {
				If ($null -eq (Get-Module @getModuleSplat -Name "SkypeOnlineConnector"))
				{
					Write-Error "SkypeOnlineConnector Module is not present!"
				}
				Else
				{
					# Skype for Business module
					Import-Module SkypeOnlineConnector
					If ($MFA -eq $True)
					{
						$CSSession = New-CsOnlineSession
						Import-PSSession $CSSession -AllowClobber
					}
					Else
					{
						$CSSession = New-CsOnlineSession -Credential $Credential
					}
					Write-Verbose "Connecting to SkypeForBusiness"
					Import-PSSession $CSSession -AllowClobber
				}
				continue
			}
			
			Teams {
				If ($null -eq (Get-Module @getModuleSplat -Name "MicrosoftTeams"))
				{
					Write-Error "MicrosoftTeams Module is not present!"
				}
				Else
				{
					Write-Verbose "Connecting to Teams"
					If ($MFA -eq $True)
					{
						Connect-MicrosoftTeams
					}
					Else
					{
						Connect-MicrosoftTeams -Credential $Credential
					}
				}
				continue
			}
			Default { }
		}
	}
}
