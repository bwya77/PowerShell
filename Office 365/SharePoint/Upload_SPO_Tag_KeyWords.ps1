$webUrl = "https://bwya77.sharepoint.com/sites/o365_training/"
Connect-PnPOnline -Url $webUrl
#Add-PnPFile -Path "C:\transfer\test.txt" -Folder "/Training/POSH" -NewFileName "upload19.txt" -Values @{"TaxKeyword"="5b6ddded-ce24-4e39-a698-14b67ab282e0","5b6ddded-ce24-4e39-a698-14b67ab282e0"}

####VARS
#Enterprise Keywords GUIDs
$Test = "5b6ddded-ce24-4e39-a698-14b67ab282e0"
$Dumb = "68a89466-cdaa-4922-9120-98d8d98305ce"

#Upload files in Dir and add Enterprise keywords
$Files = Get-ChildItem -Path C:\Transfer\Upload -Force -Recurse
foreach ($File in $Files)
{
	
	write-host "Uploading $($File.Directory)\$($File.Name)"
	
	#Its in there twice because we must set taxValueCollection
	Add-PnPFile -Path "$($File.Directory)\$($File.Name)" -Folder "/Training/" -Values @{ "TaxKeyword" = $Test, $Test }
	
}