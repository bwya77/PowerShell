$webUrl = "https://bwya77.sharepoint.com/sites/o365_training/"
Connect-PnPOnline -Url $webUrl

$folderurl = "https://bwya77.sharepoint.com/sites/o365_training/Training"

$folder = Get-PnPFolder -Url $folderUrl
$files = Get-PnPProperty -ClientObject $folder -Property Files
foreach ($File in $Files)
{
	Copy-PnPFile -SourceUrl "$folderurl" -TargetUrl "/sites/Files/Shared Documents/" -Force -OverwriteIfAlreadyExists
}