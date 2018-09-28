<#	
	.NOTES
	===========================================================================
	 Updated on:   	6/25/2018
	 Created by:   	/u/TheLazyAdministrator
     Contributors:  /u/jmn_lab, /u/nothingpersonalbro	
	===========================================================================

        AzureAD  Module is required
            Install-Module -Name AzureAD
            https://www.powershellgallery.com/packages/azuread/
        ReportHTML Moduile is required
            Install-Module -Name ReportHTML
            https://www.powershellgallery.com/packages/ReportHTML/

	.DESCRIPTION
		Generate an interactive HTML report on your Office 365 tenant. Report on Users, Tenant information, Groups, Policies, Contacts, Mail Users, Licenses and more!
    
    .Link
        http://thelazyadministrator.com/2018/06/22/create-an-interactive-html-report-for-office-365-with-powershell/
#>
$CompanyLogo = "http://thelazyadministrator.com/wp-content/uploads/2018/06/logo-2-e1529684959389.png"
$RightLogo = "http://thelazyadministrator.com/wp-content/uploads/2018/06/amd.png"
$ReportSavePath = "C:\Automation\"


$credential = Get-Credential -Message "Please enter your Office 365 credentials"
Import-Module AzureAD
Connect-AzureAD -Credential $credential
$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Credential $credential -Authentication "Basic" -AllowRedirection
Import-PSSession $exchangeSession -AllowClobber

$Table = New-Object 'System.Collections.Generic.List[System.Object]'
$LicenseTable = New-Object 'System.Collections.Generic.List[System.Object]'
$UserTable = New-Object 'System.Collections.Generic.List[System.Object]'
$SharedMailboxTable = New-Object 'System.Collections.Generic.List[System.Object]'
$GroupTypetable = New-Object 'System.Collections.Generic.List[System.Object]'
$IsLicensedUsersTable = New-Object 'System.Collections.Generic.List[System.Object]'
$ContactTable = New-Object 'System.Collections.Generic.List[System.Object]'
$MailUser = New-Object 'System.Collections.Generic.List[System.Object]'
$ContactMailUserTable = New-Object 'System.Collections.Generic.List[System.Object]'
$RoomTable = New-Object 'System.Collections.Generic.List[System.Object]'
$EquipTable = New-Object 'System.Collections.Generic.List[System.Object]'
$GlobalAdminTable = New-Object 'System.Collections.Generic.List[System.Object]'
$StrongPasswordTable = New-Object 'System.Collections.Generic.List[System.Object]'
$CompanyInfoTable = New-Object 'System.Collections.Generic.List[System.Object]'
$MessageTraceTable = New-Object 'System.Collections.Generic.List[System.Object]'
$DomainTable = New-Object 'System.Collections.Generic.List[System.Object]'

$Sku = @{
	"O365_BUSINESS_ESSENTIALS"			     = "Office 365 Business Essentials"
	"O365_BUSINESS_PREMIUM"				     = "Office 365 Business Premium"
	"DESKLESSPACK"						     = "Office 365 (Plan K1)"
	"DESKLESSWOFFPACK"					     = "Office 365 (Plan K2)"
	"LITEPACK"							     = "Office 365 (Plan P1)"
	"EXCHANGESTANDARD"					     = "Office 365 Exchange Online Only"
	"STANDARDPACK"						     = "Enterprise Plan E1"
	"STANDARDWOFFPACK"					     = "Office 365 (Plan E2)"
	"ENTERPRISEPACK"						 = "Enterprise Plan E3"
	"ENTERPRISEPACKLRG"					     = "Enterprise Plan E3"
	"ENTERPRISEWITHSCAL"					 = "Enterprise Plan E4"
	"STANDARDPACK_STUDENT"				     = "Office 365 (Plan A1) for Students"
	"STANDARDWOFFPACKPACK_STUDENT"		     = "Office 365 (Plan A2) for Students"
	"ENTERPRISEPACK_STUDENT"				 = "Office 365 (Plan A3) for Students"
	"ENTERPRISEWITHSCAL_STUDENT"			 = "Office 365 (Plan A4) for Students"
	"STANDARDPACK_FACULTY"				     = "Office 365 (Plan A1) for Faculty"
	"STANDARDWOFFPACKPACK_FACULTY"		     = "Office 365 (Plan A2) for Faculty"
	"ENTERPRISEPACK_FACULTY"				 = "Office 365 (Plan A3) for Faculty"
	"ENTERPRISEWITHSCAL_FACULTY"			 = "Office 365 (Plan A4) for Faculty"
	"ENTERPRISEPACK_B_PILOT"				 = "Office 365 (Enterprise Preview)"
	"STANDARD_B_PILOT"					     = "Office 365 (Small Business Preview)"
	"VISIOCLIENT"						     = "Visio Pro Online"
	"POWER_BI_ADDON"						 = "Office 365 Power BI Addon"
	"POWER_BI_INDIVIDUAL_USE"			     = "Power BI Individual User"
	"POWER_BI_STANDALONE"				     = "Power BI Stand Alone"
	"POWER_BI_STANDARD"					     = "Power-BI Standard"
	"PROJECTESSENTIALS"					     = "Project Lite"
	"PROJECTCLIENT"						     = "Project Professional"
	"PROJECTONLINE_PLAN_1"				     = "Project Online"
	"PROJECTONLINE_PLAN_2"				     = "Project Online and PRO"
	"ProjectPremium"						 = "Project Online Premium"
	"ECAL_SERVICES"						     = "ECAL"
	"EMS"								     = "Enterprise Mobility Suite"
	"RIGHTSMANAGEMENT_ADHOC"				 = "Windows Azure Rights Management"
	"MCOMEETADV"							 = "PSTN conferencing"
	"SHAREPOINTSTORAGE"					     = "SharePoint storage"
	"PLANNERSTANDALONE"					     = "Planner Standalone"
	"CRMIUR"								 = "CMRIUR"
	"BI_AZURE_P1"						     = "Power BI Reporting and Analytics"
	"INTUNE_A"							     = "Windows Intune Plan A"
	"PROJECTWORKMANAGEMENT"				     = "Office 365 Planner Preview"
	"ATP_ENTERPRISE"						 = "Exchange Online Advanced Threat Protection"
	"EQUIVIO_ANALYTICS"					     = "Office 365 Advanced eDiscovery"
	"AAD_BASIC"							     = "Azure Active Directory Basic"
	"RMS_S_ENTERPRISE"					     = "Azure Active Directory Rights Management"
	"AAD_PREMIUM"						     = "Azure Active Directory Premium"
	"MFA_PREMIUM"						     = "Azure Multi-Factor Authentication"
	"STANDARDPACK_GOV"					     = "Microsoft Office 365 (Plan G1) for Government"
	"STANDARDWOFFPACK_GOV"				     = "Microsoft Office 365 (Plan G2) for Government"
	"ENTERPRISEPACK_GOV"					 = "Microsoft Office 365 (Plan G3) for Government"
	"ENTERPRISEWITHSCAL_GOV"				 = "Microsoft Office 365 (Plan G4) for Government"
	"DESKLESSPACK_GOV"					     = "Microsoft Office 365 (Plan K1) for Government"
	"ESKLESSWOFFPACK_GOV"				     = "Microsoft Office 365 (Plan K2) for Government"
	"EXCHANGESTANDARD_GOV"				     = "Microsoft Office 365 Exchange Online (Plan 1) only for Government"
	"EXCHANGEENTERPRISE_GOV"				 = "Microsoft Office 365 Exchange Online (Plan 2) only for Government"
	"SHAREPOINTDESKLESS_GOV"				 = "SharePoint Online Kiosk"
	"EXCHANGE_S_DESKLESS_GOV"			     = "Exchange Kiosk"
	"RMS_S_ENTERPRISE_GOV"				     = "Windows Azure Active Directory Rights Management"
	"OFFICESUBSCRIPTION_GOV"				 = "Office ProPlus"
	"MCOSTANDARD_GOV"					     = "Lync Plan 2G"
	"SHAREPOINTWAC_GOV"					     = "Office Online for Government"
	"SHAREPOINTENTERPRISE_GOV"			     = "SharePoint Plan 2G"
	"EXCHANGE_S_ENTERPRISE_GOV"			     = "Exchange Plan 2G"
	"EXCHANGE_S_ARCHIVE_ADDON_GOV"		     = "Exchange Online Archiving"
	"EXCHANGE_S_DESKLESS"				     = "Exchange Online Kiosk"
	"SHAREPOINTDESKLESS"					 = "SharePoint Online Kiosk"
	"SHAREPOINTWAC"						     = "Office Online"
	"YAMMER_ENTERPRISE"					     = "Yammer for the Starship Enterprise"
	"EXCHANGE_L_STANDARD"				     = "Exchange Online (Plan 1)"
	"MCOLITE"							     = "Lync Online (Plan 1)"
	"SHAREPOINTLITE"						 = "SharePoint Online (Plan 1)"
	"OFFICE_PRO_PLUS_SUBSCRIPTION_SMBIZ"	 = "Office ProPlus"
	"EXCHANGE_S_STANDARD_MIDMARKET"		     = "Exchange Online (Plan 1)"
	"MCOSTANDARD_MIDMARKET"				     = "Lync Online (Plan 1)"
	"SHAREPOINTENTERPRISE_MIDMARKET"		 = "SharePoint Online (Plan 1)"
	"OFFICESUBSCRIPTION"					 = "Office ProPlus"
	"YAMMER_MIDSIZE"						 = "Yammer"
	"DYN365_ENTERPRISE_PLAN1"			     = "Dynamics 365 Customer Engagement Plan Enterprise Edition"
	"ENTERPRISEPREMIUM_NOPSTNCONF"		     = "Enterprise E5 (without Audio Conferencing)"
	"ENTERPRISEPREMIUM"					     = "Enterprise E5 (with Audio Conferencing)"
	"MCOSTANDARD"						     = "Skype for Business Online Standalone Plan 2"
	"PROJECT_MADEIRA_PREVIEW_IW_SKU"		 = "Dynamics 365 for Financials for IWs"
	"STANDARDWOFFPACK_IW_STUDENT"		     = "Office 365 Education for Students"
	"STANDARDWOFFPACK_IW_FACULTY"		     = "Office 365 Education for Faculty"
	"EOP_ENTERPRISE_FACULTY"				 = "Exchange Online Protection for Faculty"
	"EXCHANGESTANDARD_STUDENT"			     = "Exchange Online (Plan 1) for Students"
	"OFFICESUBSCRIPTION_STUDENT"			 = "Office ProPlus Student Benefit"
	"STANDARDWOFFPACK_FACULTY"			     = "Office 365 Education E1 for Faculty"
	"STANDARDWOFFPACK_STUDENT"			     = "Microsoft Office 365 (Plan A2) for Students"
	"DYN365_FINANCIALS_BUSINESS_SKU"		 = "Dynamics 365 for Financials Business Edition"
	"DYN365_FINANCIALS_TEAM_MEMBERS_SKU"	 = "Dynamics 365 for Team Members Business Edition"
	"FLOW_FREE"							     = "Microsoft Flow Free"
	"POWER_BI_PRO"						     = "Power BI Pro"
	"O365_BUSINESS"						     = "Office 365 Business"
	"DYN365_ENTERPRISE_SALES"			     = "Dynamics Office 365 Enterprise Sales"
	"RIGHTSMANAGEMENT"					     = "Rights Management"
	"PROJECTPROFESSIONAL"				     = "Project Professional"
	"VISIOONLINE_PLAN1"					     = "Visio Online Plan 1"
	"EXCHANGEENTERPRISE"					 = "Exchange Online Plan 2"
	"DYN365_ENTERPRISE_P1_IW"			     = "Dynamics 365 P1 Trial for Information Workers"
	"DYN365_ENTERPRISE_TEAM_MEMBERS"		 = "Dynamics 365 For Team Members Enterprise Edition"
	"CRMSTANDARD"						     = "Microsoft Dynamics CRM Online Professional"
	"EXCHANGEARCHIVE_ADDON"				     = "Exchange Online Archiving For Exchange Online"
	"EXCHANGEDESKLESS"					     = "Exchange Online Kiosk"
	"SPZA_IW"							     = "App Connect"
	"WINDOWS_STORE"						     = "Windows Store for Business"
	"MCOEV"								     = "Microsoft Phone System"
	"VIDEO_INTEROP"						     = "Polycom Skype Meeting Video Interop for Skype for Business"
	"SPE_E5"								 = "Microsoft 365 E5"
	"SPE_E3"								 = "Microsoft 365 E3"
	"ATA"								     = "Advanced Threat Analytics"
	"MCOPSTN2"							     = "Domestic and International Calling Plan"
	"FLOW_P1"							     = "Microsoft Flow Plan 1"
	"FLOW_P2"							     = "Microsoft Flow Plan 2"
}
# Get all users right away. Instead of doing several lookups, we will use this object to look up all the information needed.
$AllUsers = get-azureaduser -All:$true

#Company Information
$CompanyInfo = Get-AzureADTenantDetail

$CompanyName = $CompanyInfo.DisplayName
$TechEmail = $CompanyInfo.TechnicalNotificationMails | Out-String
$DirSync = $CompanyInfo.DirSyncEnabled
$LastDirSync = $CompanyInfo.CompanyLastDirSyncTime


If ($DirSync -eq $Null)
{
	$LastDirSync = "Not Available"
	$DirSync = "Disabled"
}
If ($PasswordSync -eq $Null)
{
	$LastPasswordSync = "Not Available"
}

$obj = [PSCustomObject]@{
	'Name'					   = $CompanyName
	'Technical E-mail'		   = $TechEmail
	'Directory Sync'		   = $DirSync
	'Last Directory Sync'	   = $LastDirSync
}

$CompanyInfoTable.add($obj)

#Get Tenant Global Admins
$role = Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -match "Company Administrator" }
$Admins = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
Foreach ($Admin in $Admins)
{
	$Name = $Admin.DisplayName
	$EmailAddress = $Admin.Mail
	if (($admin.assignedlicenses.SkuID) -ne $Null)
	{
		$Licensed = $True
	}
	else
	{
		$Licensed = $False
	}
	
	$obj = [PSCustomObject]@{
		'Name'			      = $Name
		'Is Licensed'		  = $Licensed
		'E-Mail Address'	  = $EmailAddress
	}
	
	$GlobalAdminTable.add($obj)
	
}



#Users with Strong Password Disabled
$LooseUsers = $AllUsers | Where-Object { $_.PasswordPolicies -eq "DisableStrongPassword" }
Foreach ($LooseUser in $LooseUsers)
{
	$NameLoose = $LooseUser.DisplayName
	$UPNLoose = $LooseUser.UserPrincipalName
	$StrongPasswordLoose = "False"
	if (($LooseUser.assignedlicenses.SkuID) -ne $Null)
	{
		$LicensedLoose = $true
	}
	else
	{
		$LicensedLoose = $false
	}
	
	$obj = [PSCustomObject]@{
		'Name'						    = $NameLoose
		'UserPrincipalName'			    = $UPNLoose
		'Is Licensed'				    = $LicensedLoose
		'Strong Password Required'	    = $StrongPasswordLoose
	}
	
	
	$StrongPasswordTable.add($obj)
}
If (($StrongPasswordTable).count -eq 0)
{
	$StrongPasswordTable = [PSCustomObject]@{
		'Information'  = 'Information: No Users were found with Strong Password Enforcement disabled'
	}
}


#Message Trace / Recent Messages
$RecentMessages = Get-MessageTrace
Foreach ($RecentMessage in $RecentMessages)
{
	$TraceDate = $RecentMessage.Received
	$Sender = $RecentMessage.SenderAddress
	$Recipient = $RecentMessage.RecipientAddress
	$Subject = $RecentMessage.Subject
	$Status = $RecentMessage.Status
	
	$obj = [PSCustomObject]@{
		'Received Date'	       = $TraceDate
		'E-Mail Subject'	   = $Subject
		'Sender'			   = $Sender
		'Recipient'		       = $Recipient
		'Status'			   = $Status
	}
	
	$MessageTraceTable.add($obj)
}
If (($MessageTraceTable).count -eq 0)
{
	$MessageTraceTable = [PSCustomObject]@{
		'Information'  = 'Information: No recent E-Mails were found'
	}
}


#Tenant Domain
$Domains = Get-AzureAdDomain
foreach ($Domain in $Domains)
{
	$DomainName = $Domain.Name
	$Verified = $Domain.IsVerified
	$DefaultStatus = $Domain.IsDefault
	
	$obj = [PSCustomObject]@{
		'Domain Name'				  = $DomainName
		'Verification Status'		  = $Verified
		'Default'				      = $DefaultStatus
	}
	
	$DomainTable.add($obj)
}


#Get groups and sort in alphabetical order
$Groups = Get-AzureAdGroup -All $True | Sort-Object DisplayName
$DistroCount = ($Groups | Where-Object { $_.MailEnabled -eq $true -and $_.SecurityEnabled -eq $false }).Count
$obj1 = [PSCustomObject]@{
	'Name'					      = 'Distribution Group'
	'Count'					      = $DistroCount
}

$GroupTypetable.add($obj1)

$SecurityCount = ($Groups | Where-Object { $_.MailEnabled -eq $false -and $_.SecurityEnabled -eq $true }).Count
$obj1 = [PSCustomObject]@{
	'Name'					      = 'Security Group'
	'Count'					      = $SecurityCount
}

$GroupTypetable.add($obj1)

$SecurityMailEnabledCount = ($Groups | Where-Object { $_.MailEnabled -eq $true -and $_.SecurityEnabled -eq $true }).Count
$obj1 = [PSCustomObject]@{
	'Name'					      = 'Mail Enabled Security Group'
	'Count'					      = $SecurityMailEnabledCount
}

$GroupTypetable.add($obj1)

Foreach ($Group in $Groups)
{
	$Type = New-Object 'System.Collections.Generic.List[System.Object]'
	
	if ($group.MailEnabled -eq $True -and $group.SecurityEnabled -eq $False)
	{
		$Type = "Distribution Group"
	}
	if ($group.MailEnabled -eq $False -and $group.SecurityEnabled -eq $True)
	{
		$Type = "Security Group"
	}
	if ($group.MailEnabled -eq $True -and $group.SecurityEnabled -eq $True)
	{
		$Type = "Mail Enabled Security Group"
	}
	
	$Users = (Get-AzureADGroupMember -ObjectId $Group.ObjectID | Sort-Object DisplayName | Select-Object -ExpandProperty DisplayName) -join ", "
	$GName = $Group.DisplayName
	
	$hash = New-Object PSObject -property @{ Name = "$GName"; Type = "$Type"; Members = "$Users" }
	$GEmail = $Group.Mail
	
	
	$obj = [PSCustomObject]@{
		'Name'				   = $GName
		'Type'				   = $Type
		'Members'			   = $users
		'E-mail Address'	   = $GEmail
	}
	
	$table.add($obj)
}
If (($table).count -eq 0)
{
	$table = [PSCustomObject]@{
		'Information'  = 'Information: No Groups were found in the tenant'
	}
}


#Get all licenses
$Licenses = Get-AzureADSubscribedSku
#Split licenses at colon
Foreach ($License in $Licenses)
{
	$TextLic = $null
	
	$ASku = ($License).SkuPartNumber
	$TextLic = $Sku.Item("$ASku")
	If (!($TextLic))
	{
		$OLicense = $License.SkuPartNumber
	}
	Else
	{
		$OLicense = $TextLic
	}
	
	$TotalAmount = $License.PrepaidUnits.enabled
	$Assigned = $License.ConsumedUnits
	$Unassigned = ($TotalAmount - $Assigned)

	If ($TotalAmount -ne $Null)
	{
		$obj = [PSCustomObject]@{
			'Name'					    = $Olicense
			'Total Amount'			    = $TotalAmount
			'Assigned Licenses'		    = $Assigned
			'Unassigned Licenses'	    = $Unassigned
		}
		
		$licensetable.add($obj)
	}
}
If (($licensetable).count -eq 0)
{
	$licensetable = [PSCustomObject]@{
		'Information'  = 'Information: No Licenses were found in the tenant'
	}
}


$IsLicensed = ($AllUsers | Where-Object { $_.assignedlicenses.count -gt 0 }).Count
$objULic = [PSCustomObject]@{
	'Name'	   = 'Users Licensed'
	'Count'    = $IsLicensed
}

$IsLicensedUsersTable.add($objULic)

$ISNotLicensed = ($AllUsers | Where-Object { $_.assignedlicenses.count -eq 0 }).Count
$objULic = [PSCustomObject]@{
	'Name'	   = 'Users Not Licensed'
	'Count'    = $IsNotLicensed
}

$IsLicensedUsersTable.add($objULic)
If (($IsLicensedUsersTable).count -eq 0)
{
	$IsLicensedUsersTable = [PSCustomObject]@{
		'Information'  = 'Information: No Licenses were found in the tenant'
	}
}


Foreach ($User in $AllUsers)
{
	$ProxyA = New-Object 'System.Collections.Generic.List[System.Object]'
	$NewObject02 = New-Object 'System.Collections.Generic.List[System.Object]'
	$NewObject01 = New-Object 'System.Collections.Generic.List[System.Object]'
	$UserLicenses = ($User | Select-Object -ExpandProperty AssignedLicenses).SkuId
	If (($UserLicenses).count -gt 1)
	{
		Foreach ($UserLicense in $UserLicenses)
		{
			$lic = ($licenses | Where-Object { $_.skuid -match ($user | Select-Object -ExpandProperty assignedLicenses).skuid }).SkuPartNumber
			$TextLic = $Sku.Item("$lic")
			If (!($TextLic))
			{
				$NewObject01 = [PSCustomObject]@{
					'Licenses'	   = $lic
				}
				$NewObject02.add($NewObject01)
			}
			Else
			{
				$NewObject01 = [PSCustomObject]@{
					'Licenses'	   = $textlic
				}
				
				$NewObject02.add($NewObject01)
			}
		}
	}
	Elseif (($UserLicenses).count -eq 1)
	{
		$lic = ($licenses | Where-Object { $_.skuid -match ($user | Select-Object -ExpandProperty assignedLicenses).skuid }).SkuPartNumber
		$TextLic = $Sku.Item("$lic")
		If (!($TextLic))
		{
			$NewObject01 = [PSCustomObject]@{
				'Licenses'	   = $lic
			}
			$NewObject02.add($NewObject01)
		}
		Else
		{
			$NewObject01 = [PSCustomObject]@{
				'Licenses'	   = $textlic
			}
			$NewObject02.add($NewObject01)
		}
	}
	Else
	{
		$NewObject01 = [PSCustomObject]@{
			'Licenses'	   = $Null
		}
		$NewObject02.add($NewObject01)
	}
	
	$ProxyAddresses = ($User | Select-Object -ExpandProperty ProxyAddresses)
	If ($ProxyAddresses -ne $Null)
	{
		Foreach ($Proxy in $ProxyAddresses)
		{
			$ProxyB = $Proxy -split ":" | Select-Object -Last 1
			$ProxyA.add($ProxyB)
			
		}
		$ProxyC = $ProxyA -join ", "
	}
	Else
	{
		$ProxyC = $Null
	}
	
	$Name = $User.DisplayName
	$UPN = $User.UserPrincipalName
	$UserLicenses = ($NewObject02 | Select-Object -ExpandProperty Licenses) -join ", "
	$Enabled = $User.AccountEnabled
	$ResetPW = Get-User $User.DisplayName | Select-Object -ExpandProperty ResetPasswordOnNextLogon 
	
	$obj = [PSCustomObject]@{
		'Name'				                   = $Name
		'UserPrincipalName'	                   = $UPN
		'Licenses'			                   = $UserLicenses
		'Reset Password at Next Logon'         = $ResetPW
		'Enabled'			                   = $Enabled
		'E-mail Addresses'	                   = $ProxyC
		
	}
	
	$usertable.add($obj)
}
If (($usertable).count -eq 0)
{
	$usertable = [PSCustomObject]@{
		'Information'  = 'Information: No Users were found in the tenant'
	}
}


#Get all Shared Mailboxes
$SharedMailboxes = Get-Recipient -Resultsize unlimited | Where-Object { $_.RecipientTypeDetails -eq "SharedMailbox" }
Foreach ($SharedMailbox in $SharedMailboxes)
{
	$ProxyA = New-Object 'System.Collections.Generic.List[System.Object]'
	$Name = $SharedMailbox.Name
	$PrimEmail = $SharedMailbox.PrimarySmtpAddress
	$ProxyAddresses = ($SharedMailbox | Where-Object { $_.EmailAddresses -notlike "*$PrimEmail*" } | Select-Object -ExpandProperty EmailAddresses)
	If ($ProxyAddresses -ne $Null)
	{
		Foreach ($ProxyAddress in $ProxyAddresses)
		{
			$ProxyB = $ProxyAddress -split ":" | Select-Object -Last 1
			If ($ProxyB -eq $PrimEmail)
			{
				$ProxyB = $Null
			}
			$ProxyA.add($ProxyB)
			$ProxyC = $ProxyA
		}
	}
	Else
	{
		$ProxyC = $Null
	}
	
	$ProxyF = ($ProxyC -join ", ").TrimEnd(", ")
	
	$obj = [PSCustomObject]@{
		'Name'				   = $Name
		'Primary E-Mail'	   = $PrimEmail
		'E-mail Addresses'	   = $ProxyF
	}
	
	
	
	$SharedMailboxTable.add($obj)
	
}
If (($SharedMailboxTable).count -eq 0)
{
	$SharedMailboxTable = [PSCustomObject]@{
		'Information'  = 'Information: No Shared Mailboxes were found in the tenant'
	}
}


#Get all Contacts
$Contacts = Get-MailContact
#Split licenses at colon
Foreach ($Contact in $Contacts)
{
	
	$ContactName = $Contact.DisplayName
	$ContactPrimEmail = $Contact.PrimarySmtpAddress
	
	$objContact = [PSCustomObject]@{
		'Name'			     = $ContactName
		'E-mail Address'	 = $ContactPrimEmail
	}
	
	$ContactTable.add($objContact)
	
}
If (($ContactTable).count -eq 0)
{
	$ContactTable = [PSCustomObject]@{
		'Information'  = 'Information: No Contacts were found in the tenant'
	}
}


#Get all Mail Users
$MailUsers = Get-MailUser
foreach ($MailUser in $mailUsers)
{
	$MailArray = New-Object 'System.Collections.Generic.List[System.Object]'
	$MailPrimEmail = $MailUser.PrimarySmtpAddress
	$MailName = $MailUser.DisplayName
	$MailEmailAddresses = ($MailUser.EmailAddresses | Where-Object { $_ -cnotmatch '^SMTP' })
	foreach ($MailEmailAddress in $MailEmailAddresses)
	{
		$MailEmailAddressSplit = $MailEmailAddress -split ":" | Select-Object -Last 1
		$MailArray.add($MailEmailAddressSplit)
		
		
	}
	
	$UserEmails = $MailArray -join ", "
	
	$obj = [PSCustomObject]@{
		'Name'				   = $MailName
		'Primary E-Mail'	   = $MailPrimEmail
		'E-mail Addresses'	   = $UserEmails
	}
	
	$ContactMailUserTable.add($obj)
}
If (($ContactMailUserTable).count -eq 0)
{
	$ContactMailUserTable = [PSCustomObject]@{
		'Information'  = 'Information: No Mail Users were found in the tenant'
	}
}

$Rooms = Get-Mailbox -Filter '(RecipientTypeDetails -eq "RoomMailBox")'
Foreach ($Room in $Rooms)
{
	$RoomArray = New-Object 'System.Collections.Generic.List[System.Object]'
	
	$RoomName = $Room.DisplayName
	$RoomPrimEmail = $Room.PrimarySmtpAddress
	$RoomEmails = ($Room.EmailAddresses | Where-Object { $_ -cnotmatch '^SMTP' })
	foreach ($RoomEmail in $RoomEmails)
	{
		$RoomEmailSplit = $RoomEmail -split ":" | Select-Object -Last 1
		$RoomArray.add($RoomEmailSplit)
	}
	$RoomEMailsF = $RoomArray -join ", "
	
	
	$obj = [PSCustomObject]@{
		'Name'				   = $RoomName
		'Primary E-Mail'	   = $RoomPrimEmail
		'E-mail Addresses'	   = $RoomEmailsF
	}
	
	$RoomTable.add($obj)
}
If (($RoomTable).count -eq 0)
{
	$RoomTable = [PSCustomObject]@{
		'Information'  = 'Information: No Room Mailboxes were found in the tenant'
	}
}


$EquipMailboxes = Get-Mailbox -Filter '(RecipientTypeDetails -eq "EquipmentMailBox")'
Foreach ($EquipMailbox in $EquipMailboxes)
{
	$EquipArray = New-Object 'System.Collections.Generic.List[System.Object]'
	
	$EquipName = $EquipMailbox.DisplayName
	$EquipPrimEmail = $EquipMailbox.PrimarySmtpAddress
	$EquipEmails = ($EquipMailbox.EmailAddresses | Where-Object { $_ -cnotmatch '^SMTP' })
	foreach ($EquipEmail in $EquipEmails)
	{
		$EquipEmailSplit = $EquipEmail -split ":" | Select-Object -Last 1
		$EquipArray.add($EquipEmailSplit)
	}
	$EquipEMailsF = $EquipArray -join ", "
	
	$obj = [PSCustomObject]@{
		'Name'				   = $EquipName
		'Primary E-Mail'	   = $EquipPrimEmail
		'E-mail Addresses'	   = $EquipEmailsF
	}
	
	
	$EquipTable.add($obj)
}
If (($EquipTable).count -eq 0)
{
	$EquipTable = [PSCustomObject]@{
		'Information'  = 'Information: No Equipment Mailboxes were found in the tenant'
	}
}



$tabarray = @('Dashboard','Groups', 'Licenses', 'Users', 'Shared Mailboxes', 'Contacts', 'Resources')

#basic Properties 
$PieObject2 = Get-HTMLPieChartObject
$PieObject2.Title = "Office 365 Total Licenses"
$PieObject2.Size.Height = 250
$PieObject2.Size.width = 250
$PieObject2.ChartStyle.ChartType = 'doughnut'

#These file exist in the module directoy, There are 4 schemes by default
$PieObject2.ChartStyle.ColorSchemeName = "ColorScheme4"
#There are 8 generated schemes, randomly generated at runtime 
$PieObject2.ChartStyle.ColorSchemeName = "Generated7"
#you can also ask for a random scheme.  Which also happens if you have too many records for the scheme
$PieObject2.ChartStyle.ColorSchemeName = 'Random'

#Data defintion you can reference any column from name and value from the  dataset.  
#Name and Count are the default to work with the Group function.
$PieObject2.DataDefinition.DataNameColumnName = 'Name'
$PieObject2.DataDefinition.DataValueColumnName = 'Total Amount'

#basic Properties 
$PieObject3 = Get-HTMLPieChartObject
$PieObject3.Title = "Office 365 Assigned Licenses"
$PieObject3.Size.Height = 250
$PieObject3.Size.width = 250
$PieObject3.ChartStyle.ChartType = 'doughnut'

#These file exist in the module directoy, There are 4 schemes by default
$PieObject3.ChartStyle.ColorSchemeName = "ColorScheme4"
#There are 8 generated schemes, randomly generated at runtime 
$PieObject3.ChartStyle.ColorSchemeName = "Generated5"
#you can also ask for a random scheme.  Which also happens if you have too many records for the scheme
$PieObject3.ChartStyle.ColorSchemeName = 'Random'

#Data defintion you can reference any column from name and value from the  dataset.  
#Name and Count are the default to work with the Group function.
$PieObject3.DataDefinition.DataNameColumnName = 'Name'
$PieObject3.DataDefinition.DataValueColumnName = 'Assigned Licenses'

#basic Properties 
$PieObject4 = Get-HTMLPieChartObject
$PieObject4.Title = "Office 365 Unassigned Licenses"
$PieObject4.Size.Height = 250
$PieObject4.Size.width = 250
$PieObject4.ChartStyle.ChartType = 'doughnut'

#These file exist in the module directoy, There are 4 schemes by default
$PieObject4.ChartStyle.ColorSchemeName = "ColorScheme4"
#There are 8 generated schemes, randomly generated at runtime 
$PieObject4.ChartStyle.ColorSchemeName = "Generated4"
#you can also ask for a random scheme.  Which also happens if you have too many records for the scheme
$PieObject4.ChartStyle.ColorSchemeName = 'Random'

#Data defintion you can reference any column from name and value from the  dataset.  
#Name and Count are the default to work with the Group function.
$PieObject4.DataDefinition.DataNameColumnName = 'Name'
$PieObject4.DataDefinition.DataValueColumnName = 'Unassigned Licenses'

#basic Properties 
$PieObjectGroupType = Get-HTMLPieChartObject
$PieObjectGroupType.Title = "Office 365 Groups"
$PieObjectGroupType.Size.Height = 250
$PieObjectGroupType.Size.width = 250
$PieObjectGroupType.ChartStyle.ChartType = 'doughnut'

#These file exist in the module directoy, There are 4 schemes by default
$PieObjectGroupType.ChartStyle.ColorSchemeName = "ColorScheme4"
#There are 8 generated schemes, randomly generated at runtime 
$PieObjectGroupType.ChartStyle.ColorSchemeName = "Generated8"
#you can also ask for a random scheme.  Which also happens if you have too many records for the scheme
$PieObjectGroupType.ChartStyle.ColorSchemeName = 'Random'

#Data defintion you can reference any column from name and value from the  dataset.  
#Name and Count are the default to work with the Group function.
$PieObjectGroupType.DataDefinition.DataNameColumnName = 'Name'
$PieObjectGroupType.DataDefinition.DataValueColumnName = 'Count'

##--LICENSED AND UNLICENSED USERS PIE CHART--##
#basic Properties 
$PieObjectULicense = Get-HTMLPieChartObject
$PieObjectULicense.Title = "License Status"
$PieObjectULicense.Size.Height = 250
$PieObjectULicense.Size.width = 250
$PieObjectULicense.ChartStyle.ChartType = 'doughnut'

#These file exist in the module directoy, There are 4 schemes by default
$PieObjectULicense.ChartStyle.ColorSchemeName = "ColorScheme3"
#There are 8 generated schemes, randomly generated at runtime 
$PieObjectULicense.ChartStyle.ColorSchemeName = "Generated3"
#you can also ask for a random scheme.  Which also happens if you have too many records for the scheme
$PieObjectULicense.ChartStyle.ColorSchemeName = 'Random'

#Data defintion you can reference any column from name and value from the  dataset.  
#Name and Count are the default to work with the Group function.
$PieObjectULicense.DataDefinition.DataNameColumnName = 'Name'
$PieObjectULicense.DataDefinition.DataValueColumnName = 'Count'

$rpt = New-Object 'System.Collections.Generic.List[System.Object]'
$rpt += get-htmlopenpage -TitleText 'Office 365 Tenant Report' -LeftLogoString $CompanyLogo -RightLogoString $RightLogo 

$rpt += Get-HTMLTabHeader -TabNames $tabarray 
    $rpt += get-htmltabcontentopen -TabName $tabarray[0] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
        $rpt+= Get-HtmlContentOpen -HeaderText "Office 365 Dashboard"
          $rpt += Get-HTMLContentOpen -HeaderText "Company Information"
            $rpt += Get-HtmlContentTable $CompanyInfoTable 
          $rpt += Get-HTMLContentClose

	        $rpt+= get-HtmlColumn1of2
		        $rpt+= Get-HtmlContentOpen -BackgroundShade 1 -HeaderText 'Global Administrators'
			        $rpt+= get-htmlcontentdatatable  $GlobalAdminTable -HideFooter
		        $rpt+= Get-HtmlContentClose
	        $rpt+= get-htmlColumnClose
	            $rpt+= get-htmlColumn2of2
		            $rpt+= Get-HtmlContentOpen -HeaderText 'Users With Strong Password Enforcement Disabled'
			            $rpt+= get-htmlcontentdatatable $StrongPasswordTable -HideFooter 
		        $rpt+= Get-HtmlContentClose
	        $rpt+= get-htmlColumnClose

          $rpt += Get-HTMLContentOpen -HeaderText "Recent E-Mails"
            $rpt += Get-HTMLContentDataTable $MessageTraceTable -HideFooter
          $rpt += Get-HTMLContentClose

          $rpt += Get-HTMLContentOpen -HeaderText "Domains"
            $rpt += Get-HtmlContentTable $DomainTable 
          $rpt += Get-HTMLContentClose

        $rpt+= Get-HtmlContentClose 
    $rpt += get-htmltabcontentclose

    $rpt += get-htmltabcontentopen -TabName $tabarray[1] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Groups"
            $rpt += get-htmlcontentdatatable $Table -HideFooter
        $rpt += Get-HTMLContentClose
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Groups Chart"
		    $rpt += Get-HTMLPieChart -ChartObject $PieObjectGroupType -DataSet $GroupTypetable
	    $rpt += Get-HTMLContentClose
    $rpt += get-htmltabcontentclose
    $rpt += get-htmltabcontentopen -TabName $tabarray[2]  -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Licenses"
            $rpt += get-htmlcontentdatatable $LicenseTable -HideFooter
        $rpt += Get-HTMLContentClose
	$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Licensing Charts"
	    $rpt += Get-HTMLColumnOpen -ColumnNumber 1 -ColumnCount 2
	        $rpt += Get-HTMLPieChart -ChartObject $PieObject2 -DataSet $licensetable
	    $rpt += Get-HTMLColumnClose
	    $rpt += Get-HTMLColumnOpen -ColumnNumber 2 -ColumnCount 2
	        $rpt += Get-HTMLPieChart -ChartObject $PieObject3 -DataSet $licensetable
	    $rpt += Get-HTMLColumnClose
    $rpt += Get-HTMLContentclose
    $rpt += get-htmltabcontentclose
    $rpt += get-htmltabcontentopen -TabName $tabarray[3] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Users"
            $rpt += get-htmlcontentdatatable $UserTable -HideFooter
        $rpt += Get-HTMLContentClose
        $rpt += Get-HTMLContentOpen -HeaderText "Licensed & Unlicensed Users Chart"
		    $rpt += Get-HTMLPieChart -ChartObject $PieObjectULicense -DataSet $IsLicensedUsersTable
	    $rpt += Get-HTMLContentClose
    $rpt += get-htmltabcontentclose
    $rpt += get-htmltabcontentopen -TabName $tabarray[4] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy)) 
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Shared Mailboxes"
        $rpt += get-htmlcontentdatatable $SharedMailboxTable -HideFooter
        $rpt += Get-HTMLContentClose
    $rpt += get-htmltabcontentclose
        $rpt += get-htmltabcontentopen -TabName $tabarray[5] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy)) 
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Contacts"
            $rpt += get-htmlcontentdatatable $ContactTable -HideFooter
        $rpt += Get-HTMLContentClose
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Mail Users"
            $rpt += get-htmlcontentdatatable $ContactMailUserTable -HideFooter
        $rpt += Get-HTMLContentClose
    $rpt += get-htmltabcontentclose
    $rpt += get-htmltabcontentopen -TabName $tabarray[6] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy)) 
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Room Mailboxes"
            $rpt += get-htmlcontentdatatable $RoomTable -HideFooter
        $rpt += Get-HTMLContentClose
        $rpt += Get-HTMLContentOpen -HeaderText "Office 365 Equipment Mailboxes"
            $rpt += get-htmlcontentdatatable $EquipTable -HideFooter
        $rpt += Get-HTMLContentClose
    $rpt += get-htmltabcontentclose

$rpt += Get-HTMLClosePage

$Day = (Get-Date).Day
$Month = (Get-Date).Month
$Year = (Get-Date).Year
$ReportName = ("$Day" + "-" + "$Month" + "-" + "$Year" + "-" + "O365 Tenant Report")
Save-HTMLReport -ReportContent $rpt -ShowReport -ReportName $ReportName -ReportPath $ReportSavePath