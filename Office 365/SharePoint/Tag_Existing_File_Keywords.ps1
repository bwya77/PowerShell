#Add multiple enterprise keywords
$folderurl = "https://bwya77.sharepoint.com/sites/o365_training/Training"


$folder = Get-PnPFolder -Url $folderUrl
$files = Get-PnPProperty -ClientObject $folder -Property Files
foreach ($File in $Files)
{
	
	write-host "Working on $($file.name)"
	$item = Get-PnPFile -Url "/Training/$($file.name)" -AsListItem
	#Its in there twice because we must set taxValueCollection
	Set-PnPListItem -List "Training" -Identity $item.ID -Values @{ "TaxKeyword" = $Test, $Test, $Dumb, $Dumb }
	
	
}