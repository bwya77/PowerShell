$Cred = Get-Credential
Connect-MsolService -Credential $Cred
$customers = Get-MsolPartnerContract
Write-Host "Found $($customers.Count) customers for $((Get-MsolCompanyInformation).displayname)."
$CSVpath = "C:\Temp\outlookversions.csv"
foreach ($customer in $customers) {
    $InitialDomain = Get-MsolDomain -TenantId $customer.TenantId | Where-Object {$_.IsInitial -eq $true}
          
    Write-Host "Getting Outlook Versions for $($Customer.Name)"
    $DelegatedOrgURL = "https://outlook.office365.com/powershell-liveid?DelegatedOrg=" + $InitialDomain.Name
    $s = New-PSSession -ConnectionUri $DelegatedOrgURL -Credential $Cred -Authentication Basic -ConfigurationName Microsoft.Exchange -AllowRedirection
    Import-PSSession $s -CommandName Get-Mailbox,Search-MailboxAuditLog -AllowClobber
     
    $mailboxes = Get-Mailbox | Where-Object {$_.RecipientTypeDetails -match "User"}
    foreach ($mailbox in $mailboxes) {
        Write-Output "Checking $($mailbox.DisplayName)"
        $result = $null
        $properties = $null
         
        $result = Search-MailboxAuditLog -StartDate ([system.DateTime]::Now.AddDays(-5)) -EndDate ([system.DateTime]::Now.AddDays(1)) -Operations MailboxLogin -Identity $mailbox.UserPrincipalName -ShowDetails | where-object {$_.ClientInfoString -match "Office/12" } | Select-Object LogonUserDisplayName, ClientInfoString, LastAccessed, ClientIPAddress -First 1
         
        if ($result) {
            $properties = @{
                CustomerName         = $customer.Name
                LogonUserDisplayName = $result.LogonUserDisplayName
                EmailAddress         = $mailbox.PrimarySmtpAddress
                ClientInfoString     = $result.ClientInfoString
                LastAccessed         = $result.LastAccessed
                ClientIPAddress      = $result.ClientIpAddress
            }
     
     
            $forcsv = New-Object psobject -Property $properties
            $forcsv | Export-CSV -Path $CSVpath -Append -NoTypeInformation
        }
    }
  
    Remove-PSSession $s
}