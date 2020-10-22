using namespace System.Net

# Input bindings are passed in via param block.
param ($Request,
	$TriggerMetadata)

Function Send-Message
{
	
	Param (
		[Parameter(Mandatory = $true)]
		[string]$AccountSid,
		[Parameter(Mandatory = $true)]
		[string]$authToken,
		[Parameter(Mandatory = $true)]
		[string]$fromNumber,
		[Parameter(Mandatory = $true)]
		[string]$toNumber,
		[Parameter(Mandatory = $true)]
		[ValidateLength(1, 160)]
		[string]$message)
	
	$secureAuthToken = ConvertTo-SecureString $authToken -AsPlainText -force
	$cred = New-Object System.Management.Automation.PSCredential($AccountSid, $secureAuthToken)
	
	$Body = @{
		From = $fromNumber
		To   = $toNumber
		Body = $message
	}
	
	$apiEndpoint = "https://api.twilio.com/2010-04-01/Accounts/$AccountSid/Messages.json"
	Invoke-RestMethod -Uri $apiEndpoint -Body $Body -Credential $cred -Method "POST" -ContentType "application/x-www-form-urlencoded"
}


function Get-VMStatus
{
	param (
		[System.Array]$Server
	)
	
	begin
	{
		#$MessageBackArray = @()
		
		Write-Host "Func: Getting status on VMS: $Server"
	}
	process
	{
		$Server | ForEach-Object {
			$timestamp = get-date -Format MMddyyy_HHmmss
			Write-Host "Getting status for $_"
			$Status = $Null
			$Status = get-azvm -name $_ -status | Select-Object -ExpandProperty PowerState
			Write-Host "Status is $Status"
			[System.String]$MessageBack = "'$_' status: $Status"
			
			if ($Null -ne $MessageBack)
			{
				
				Write-Host "Sending message: $MessageBack"
				Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
				$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
				Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
			}
			Else
			{
				Write-Host "Could not obtain a status for the server: $_"
				$MessageBack = "Could not obtain a status for the server: $_"
				Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
				$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
				Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
			}
		}
	}
}

function PowerOn-VM
{
	param (
		[System.Array]$Server
	)
	begin
	{
		Write-Host "Func: Powering on VMS: $Server"
	}
	process
	{
		$Server | ForEach-Object {
			Write-Host "Turning on server: $_"
			$timestamp = get-date -Format MMddyyy_HHmmss
			$VM = get-azvm -name $_
			
			
			$StartVM = Start-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
			If ($StartVM.Status -eq "Succeeded")
			{
				Write-Host "Successfully turned on the server"
				$MessageBack = "Successfully turned on the server, '$($VM.Name)'"
				Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
				
				$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
				Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
			}
			Else
			{
				Write-Host "Error could not turn on the server"
				Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
				$MessageBack = "Error could not turn on the server, '$($VM.Name)'.
Error Status: $($StartVM.Status)"
				Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
				
				$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
				Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
			}
		}
	}
}

function PowerOff-VM
{
	param (
		[System.Array]$Server
	)
	begin
	{
		Write-Host "Func: Powering off VMS: $Server"
	}
	process
	{
		If ($Message -eq "Yes")
		{
			#Get last message that was received 
			$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
			$LastMessage = (Get-AzTableRow -table $AzureTable -partitionKey sms | Where-Object { $_.Sender -like $Sender } | Sort-Object Tabletimestamp -Descending | Select-Object -First 1)
			$VMs = ($LastMessage.VMstoPowerDown).split(", ")
			$VMs | ForEach-Object {
				$timestamp = get-date -Format MMddyyy_HHmmss
				$VM = get-azvm -name $_
				
				
				$StopVM = Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Force
				If ($StopVM.Status -eq "Succeeded")
				{
					Write-Host "Successfully turned off the server"
					$MessageBack = "Successfully turned off the server, '$($VM.Name)'"
					Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
					
					$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
					Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
				}
				Else
				{
					Write-Host "Error could not turn off the server"
					Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
					$MessageBack = "Error could not turn off the server, '$($VM.Name)'.
Error Status: $($StopVM.Status)"
					Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
					
					$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
					Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
				}
			}
		}
		Else
		{
			$Names = @()
			$Server | ForEach-Object {
				$timestamp = get-date -Format MMddyyy_HHmmss
				$VM = get-azvm -name $_
				
				$Names += $VM.Name
			}
			#Get last message that was received 
			$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
			$LastMessage = (Get-AzTableRow -table $AzureTable -partitionKey sms | Where-Object { $_.Sender -like $Sender } | Sort-Object Tabletimestamp -Descending | Select-Object -First 1).message
			If ($LastMessage -notlike "*are you sure you want to proceed?*")
			{
				[System.String]$PowerDownList = $Names
				$strPowerDownList = $PowerDownList.Replace(" ", ", ")
				$MessageBack = "This will turn off the following VM's: '$strPowerDownList', are you sure you want to proceed? Text Yes/No"
				Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
				
				$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
				Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack"; "VMstoPowerDown" = "$strPowerDownList" }
			}
		}
	}
}

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."


#Raw body of the incomming message
$body = $Request.Body
$separator = "&"
$option = [System.StringSplitOptions]::RemoveEmptyEntries
$Message = (($body.Split($separator, $option)[10]).Replace('Body=','')).Replace("+", " ")
$Sender = (($body.Split($separator, $option)[17]).Replace('From=','')).Replace("%2B", "")
Write-Host "sender is $sender"

$FromNumber = $ENV:TwilioNumber
$tonumber = "+$sender"
$accountsid = $ENV:TwilioAccountSID
$authtoken = $ENV:TwilioAuthToken



write-host "Message Receieved is: $message"
#if the sender is an approved sender then proceed
If (($Sender -like "*6182036528"))
{
	Write-Host "Logging into Azure"
	$User = $ENV:ApplicationID
	$PWord = ConvertTo-SecureString -String $ENV:ApplicationSecret -AsPlainText -Force
	$tenant = $ENV:TenantID
	$subscription = $ENV:SubscriptionID
	$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord
	Connect-AzAccount -Credential $Credential -Tenant $tenant -Subscription $subscription -ServicePrincipal
	
	$VMs = Get-AzVm | Select-Object -ExpandProperty Name
	if (($VMs -match $message) -and ($Message -notlike "*Status*"))
	{
		write-host "The message is about a VM, it must be a response"
		#Get last message that was received 
		$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
		$LastMessage = (Get-AzTableRow -table $AzureTable -partitionKey sms | Where-Object { $_.Sender -like $Sender } | Sort-Object Tabletimestamp -Descending | Select-Object -First 1).message
		Write-Host "The last message from this sender was $LastMessage"
		If ($LastMessage -like "*Status*")
		{
			Get-VMStatus -Server $Message
		}
		Elseif (($LastMessage -like "*Turn On*") -or ($LastMessage -like "*Power On*"))
		{
			PowerOn-VM -Server $Message
		}
		Elseif (($LastMessage -like "*Turn Off*") -or ($LastMessage -like "*Power Off*"))
		{
			PowerOff-VM -Server $Message
		}
		Else
		{
			Write-Host "Previous message makes this response invalid"
			$MessageBack = "Could not understand the command"
			Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
			
			$timestamp = get-date -Format MMddyyy_HHmmss
			$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
			Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message" }
		}
	}
	#If we are looking to get a status on 1 or more VM's'
	ElseIf ($Message -like "*Status*")
	{
		#See if the message is just status or if its asking for one or more speicifc VMS
		$MessageServer = @()
		$VMs | ForEach-Object {
			If ($message -match $_)
			{
				Write-Host "Message is asking for a status on the vm: $_"
				$MessageServer += $_
			}
		}
		If ($MessageServer -ne "")
		{
			Get-VMStatus -Server $MessageServer
		}
		Else
		{
			Write-Host "Message does not specify a server"
			$Vms = ($VMs) -Join ", "
			$MessageBack = "Which server would you like a status on?
$Vms "
			Write-Host "Sending Message: $MessageBack"
			Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
			$timestamp = get-date -Format MMddyyy_HHmmss
			$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
			Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
		}
	}
	Elseif (($Message -like "*Turn On*") -or ($Message -like "*Power On*") -or ($Message -like "*Power Up*"))
	{
		Write-Host "Message is to turn on a server"
		#See if the message already contains the server or servers
		$MessageServer = @()
		$VMs | ForEach-Object {
			If ($message -match $_)
			{
				Write-Host "Message is asking to power on the server: $_"
				$MessageServer += $_
			}
		}
		If ($MessageServer -ne "")
		{
			PowerOn-VM -Server $MessageServer
		}
		Else
		{
			Write-Host "Message does not specify a server to power on"
			$Vms = ($VMs) -Join ", "
			$MessageBack = "Which server would you like to power on?
$Vms "
			Write-Host "Sending Message: $MessageBack"
			Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
			$timestamp = get-date -Format MMddyyy_HHmmss
			$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
			Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
		}
	}
	Elseif (($Message -like "*Turn Off*") -or ($Message -like "*Power Off*") -or ($Message -like "*Power Down*"))
	{
		Write-Host "Message is to turn on a server"
		#See if the message already contains the server or servers
		$MessageServer = @()
		$VMs | ForEach-Object {
			If ($message -match $_)
			{
				Write-Host "Message is asking to power off the server: $_"
				$MessageServer += $_
			}
		}
		If ($MessageServer -ne "")
		{
			PowerOff-VM -Server $MessageServer
		}
		Else
		{
			Write-Host "Message does not specify a server to power off"
			$Vms = ($VMs) -Join ", "
			$MessageBack = "Which server would you like to power off?
$Vms "
			Write-Host "Sending Message: $MessageBack"
			Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
			$timestamp = get-date -Format MMddyyy_HHmmss
			$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
			Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
		}
	}
	Elseif ($Message -eq "No")
	{
		$MessageBack = "Power off server cancelled"
		Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
		$timestamp = get-date -Format MMddyyy_HHmmss
		$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
		Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
	}
	Elseif ($Message -eq "Yes")
	{
		PowerOff-VM
	}
	Else
	{
		Write-Host "Could not understand the message"
		[System.String]$MessageBack = "Could not understand the message"
		Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
		
		
		$timestamp = get-date -Format MMddyyy_HHmmss
		$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
		Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
	}
	Disconnect-AzAccount
}
Else
{
	$MessageBack = "Sorry you are not an approved sender and therefore cannot send text messages"
	Send-Message -AccountSid $accountsid -authToken $authtoken -fromNumber $FromNumber -toNumber $tonumber -message $MessageBack
	
	$timestamp = get-date -Format MMddyyy_HHmmss
	$AzureTable = Get-AzTableTable -TableName 'tablesmslog' -ResourceGroup 'rg-azfunctions' -StorageAccountName 'salaazfunctions'
	Add-AzTableRow -table $AzureTable -partitionKey sms -rowKey ("$timestamp") -property @{ "sender" = "$Sender"; "message" = "$message"; "response" = "$MessageBack" }
}

