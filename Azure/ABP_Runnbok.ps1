$AzureSplat = @{
    AutomationAccountName    = "PSAutomationAccount";
    RunBookName              = "Office_365_Runbook";
    ResourceGroup            = "rg-automation";
    Location                 = "North Central US";
    AutomationCredUser       = "brad@thelazyadministrator.com";
    AutomationCredPassword   = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force;
    AutomationAccountCedName = "Office 365 Creds"
}
 
Connect-AzAccount
 
#Create the Resource Group
New-AzResourceGroup -Name $AzureSplat.ResourceGroup -Location $AzureSplat.Location

#Make the automation account
New-AzAutomationAccount -ResourceGroupName $AzureSplat.ResourceGroup -Location $AzureSplat.Location -Name $AzureSplat.AutomationAccountName -Plan "Free"

#Create new automation runbook
New-AzAutomationRunbook -AutomationAccountName $AzureSplat.AutomationAccountName -Name $AzureSplat.RunBookName -ResourceGroupName $AzureSplat.ResourceGroup -Type PowerShell

#Create and store automation account credentials
[System.Management.Automation.PSCredential]$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AzureSplat.AutomationCredUser, $AzureSplat.AutomationCredPassword
New-AzAutomationCredential -AutomationAccountName $AzureSplat.AutomationAccountName -Name $AzureSplat.AutomationAccountCedName -Value $cred -ResourceGroupName $AzureSplat.ResourceGroup

########################################################################################################################################################################################################

[System.Management.Automation.PSCredential]$Credential = Get-AutomationPSCredential -Name "Office 365 Creds"

$Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid -Credential $Credential -Authentication Basic -AllowRedirection
 
Import-PSSession -Session $Session -DisableNameChecking:$true -AllowClobber:$true | Out-Null


$ProxySplat = @{
    #Avaialble proxy format options: 'FirstInitialLastName', 'FirstName.LastName', 'FirstName'
    ProxyFormat = "FirstInitialLastName";
    Domain = "chicagopowershell.com"
}

Get-Mailbox -ResultSize unlimited | ForEach-Object {
    If ($ProxySplat.ProxyFormat -like "FirstInitialLastName")
    {
        $FirstInitial = ($_.DisplayName).SubString(0,1) 
        $LastName = ($_.DisplayName).Split(" ") | Select-Object -Last 1
        Set-Mailbox -identity $_.DistinguishedName  -EmailAddresses @{add="$FirstInitial$LastName@$($ProxySplat.Domain)"}
    }
    ElseIf ($ProxySplat.ProxyFormat -like "FirstName.LastName")
    {
        $FirstName = ($_.DisplayName).Split(" ") | Select-Object -First 1
        $LastName = ($_.DisplayName).Split(" ") | Select-Object -Last 1
        Set-Mailbox -identity $_.DistinguishedName  -EmailAddresses @{add="$FirstName.$LastName@$($ProxySplat.Domain)"}
    }
    ElseIf ($ProxySplat.ProxyFormat -like "FirstName")
    {
        $FirstName = ($_.DisplayName).Split(" ") | Select-Object -First 1
        Set-Mailbox -identity $_.DistinguishedName  -EmailAddresses @{add="$FirstName@$($ProxySplat.Domain)"}
    }
    Else 
    {
        Write-Warning -Message "No valid proxy format detected"
    }
}

Remove-PSSession $Session