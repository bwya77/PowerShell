#This script will return all users in Active Directory that are not a member of all 3 groups
Get-ADUser -Filter * -Properties memberof | Where-Object {(!($_.memberof -like "Group1")) -and (!($_.memberof -like "Group2")) -and (!($_.memberof -like "Group3"))}  | Sort-Object Username | Format-Table -AutoSize
