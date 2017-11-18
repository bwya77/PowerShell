#Gathers all users with a home drive/directory that points to the server that we are changing
$Users = Get-ADUser -filter '*' -Properties homeDirectory | Where-Object { $_.homeDirectory -like "*\\OldServer\*" }
Foreach ($User in $Users)
{
	#Gets the Display Name of the user
	$DN = ($User).Name
	Write-Host "Working on $DN..." -ForegroundColor Yellow
	
	#Gets the UPN of the user
	Write-Host "Getting UPN of $DN..." -ForegroundColor White
	$UPN = ($User).UserPrincipalName
	
	#Splits the UPN var at the '@' and takes the first half to use as the users homedir folder
	Write-Host "Splitting the UPN to get the homedir string..." -ForegroundColor White
	$UPNVar = $UPN.Split('@') | Select-Object -First 1
	
	#Creates a HomeDir variable
	$HomeDirString = "\\NewServer\users\$UPNVar"
	Write-Host "Setting the Home Directory of $DN to $HomeDirString" -ForegroundColor White
	#Sets the HomeDir of the user to our HomeDir variable
	Set-ADUser $User.SamAccountName -homedirectory $HomeDirString 
	
}
