######VARIABLES######
#New login script
$NewLoginScript = $null
#Old login script
$OldLoginScript = "testlogin.bat"
#Gathers all users with a login script that needs to be changed
$Users = Get-ADUser -filter '*' -Properties scriptPath | Where-Object { $_.scriptPath -like "*$OldLoginScript*" }
Foreach ($User in $Users)
{
	#Gets the Display Name of the user
	$DN = ($User).Name
	Write-Host "Working on $DN..." -ForegroundColor Yellow

    If ($NewLoginScript -eq $null) {
        $NewLoginScriptString = "`$null"
    } Else {
        $NewLoginScriptString = $NewLoginScript
    }
	
	Write-Host "Setting the Login Script of $DN to $NewLoginScriptString" -ForegroundColor White
	#Sets the scriptPath of the user to our NewLoginScript variable
	Set-ADUser $User.SamAccountName -scriptPath $NewLoginScript -WhatIf
	
}