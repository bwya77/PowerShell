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
		Version: 	1.0.4
	
		Contributors:   /u/Sheppard_Ra
	
		Changelog:
			1.0.4
				- Host title will add a service or services you are connected to. If unable to connect it will not display connection status until connection is valid
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
					Write-Error "AzureAD Module is not present!"
					continue
				}
				Else
				{
					If ($MFA -eq $True)
					{
						$Connect = Connect-AzureAD
						If ($Connect -ne $Null)
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: AzureAD"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - AzureAD"
							}
						}
						
					}
					Else
					{
						$Connect = Connect-AzureAD -Credential $Credential
						If ($Connect -ne $Null)
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: AzureAD"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - AzureAD"
							}
						}
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
						If ($Null -ne (Get-PSSession | Where-Object { $_.ConfigurationName -like "*Exchange*" }))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: Exchange"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - Exchange"
							}
						}
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
					If ($Null -ne (Get-PSSession | Where-Object { $_.ConfigurationName -like "*Exchange*" }))
					{
						If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
						{
							$host.ui.RawUI.WindowTitle += " - Connected To: Exchange"
						}
						Else
						{
							$host.ui.RawUI.WindowTitle += " - Exchange"
						}
					}
					
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
						If ($Null -ne (Get-MsolCompanyInformation -ErrorAction SilentlyContinue))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: MSOnline"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - MSOnline"
							}
						}
					}
					Else
					{
						Connect-MsolService -Credential $Credential
						If ($Null -ne (Get-MsolCompanyInformation -ErrorAction SilentlyContinue))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: MSOnline"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - MSOnline"
							}
						}
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
						If ($Null -ne (Get-PSSession | Where-Object { $_.ConfigurationName -like "*Exchange*" }))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: Security and Compliance Center"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - Security and Compliance Center"
							}
						}
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
					If ($Null -ne (Get-PSSession | Where-Object { $_.ConfigurationName -like "*Exchange*" }))
					{
						If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
						{
							$host.ui.RawUI.WindowTitle += " - Connected To: Security and Compliance Center"
						}
						Else
						{
							$host.ui.RawUI.WindowTitle += " - Security and Compliance Center"
						}
					}
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
						$SPOSession = Connect-SPOService -Url $SharePointURL
						If ($Null -ne (Get-SPOTenant))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: SharePoint Online"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - SharePoint Online"
							}
						}
					}
					Else
					{
						$SPOSession = Connect-SPOService -Url $SharePointURL -Credential $Credential
						If ($Null -ne (Get-SPOTenant))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: SharePoint Online"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - SharePoint Online"
							}
						}
					}
				}
				continue
			}
			
			SkypeForBusiness {
				Write-Verbose "Connecting to SkypeForBusiness"
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
						If ($Null -ne (Get-CsOnlineDirectoryTenant))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: Skype for Business"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - Skype for Business"
							}
						}
					}
					Else
					{
						$CSSession = New-CsOnlineSession -Credential $Credential
						Import-PSSession $CSSession -AllowClobber
						If ($Null -ne (Get-CsOnlineDirectoryTenant))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: Skype for Business"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - Skype for Business"
							}
						}
					}
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
						$TeamsConnect = Connect-MicrosoftTeams
						If ($Null -ne ($TeamsConnect))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: Microsoft Teams"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - Microsoft Teams"
							}
						}
					}
					Else
					{
						$TeamsConnect = Connect-MicrosoftTeams -Credential $Credential
						If ($Null -ne ($TeamsConnect))
						{
							If (($host.ui.RawUI.WindowTitle) -notlike "*Connected To:*")
							{
								$host.ui.RawUI.WindowTitle += " - Connected To: Microsoft Teams"
							}
							Else
							{
								$host.ui.RawUI.WindowTitle += " - Microsoft Teams"
							}
						}
					}
				}
				continue
			}
			Default { }
		}
	}
}
