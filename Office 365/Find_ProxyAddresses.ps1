$Users = Get-ADUser -Filter * -Properties ProxyAddresses -SearchBase "OU=Office 365 Sync,OU=Users,DC=bwya77,DC=local"
$ProxyMatch = ".local"
Foreach ($User in $Users){
$Name = ($User).Name
$ProxyInfo = (Get-ADUser $User -Properties ProxyAddresses).ProxyAddresses
If($ProxyInfo -like "*$ProxyMatch*")
    {
    Write-Host "$Name has proxyaddresses that match..." -ForegroundColor Yellow
    
    }
}