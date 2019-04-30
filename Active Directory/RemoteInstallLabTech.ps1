#Local files to transfer over so it will run locally
#If you change the msi file, change lines 87, 95
$FiletoTransfer = "C:\transfer\LabTech_Install.msi"

#I want to have some basic logging because it will run unattended 
$LogFile = "C:\Automation\"
Write-Host "Checking Log File location" -ForegroundColor White
$CheckLogDir = Test-Path $LogFile -ErrorAction SilentlyContinue
If ($CheckLogDir -eq $False)
{
	Write-Host "Not found! - Creating!"
	New-Item -ItemType Directory -Path $LogFile -Force
}
Else
{
	Write-Host "Log file path is already present, continuing "
}

#Parse computers from Active Directory
$Computers = (Get-ADComputer -Filter * -SearchBase "OU=Machines,OU=Chicago,DC=BWYA77,DC=COM").Name

#Manually enter in computers
#$Computers = "IT40", "IT45"

[int]$computerwork = 0


#Counts the number of computers it will have to hit, this tells the script when to stop once it hits this number of computers
$ComputerCount = ($Computers).count


# Get Start Time so we can output how long it takes the script to run
$startDTM = (Get-Date)
Do
{
	ForEach ($Computer in $Computers)
	{
		[int]$Retry = 0
		[int]$InstallCode = 0
		[int]$RetryCopyFile = 0
		[int]$CopyCode = 0
		
		#Test WinRM, if this fails we can't do shit
		Write-Host "Testing WSMAN Connection to $Computer" -ForegroundColor Yellow -BackgroundColor Blue
		$Heartbeat = (Test-WSMan -ComputerName $Computer -ErrorAction SilentlyContinue)
		If (!$Heartbeat)
		{
			"WinRM appears to be off for $Computer" | Out-File $LogFile\log.txt -Append -Force
			Write-Host "$Computer is not able to be connected to via WinRM" -ForegroundColor Red

		}
		Else
		{
			Write-Host "WinRM appears to be open for $Computer" -ForegroundColor White
					
			#Runs the exe in silent mode. Please note that when PowerShell runs the .exe file you wont see it if youre logged in as a user anyways because it wont launch it in an interactive login by default
			
			Write-Host "Creating a new PSSession to $Computer"
			$session = New-PSSession -ComputerName $computer -ErrorAction SilentlyContinue
			If ($null -ne $Session)
			{
				Write-Host "Creating a new PSDrive on $Computer" -ForegroundColor Yellow
				Invoke-Command -Session $session -ScriptBlock { New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR } | Out-Null
				
				Write-Host "Checking to see if LabTech is installed" -ForegroundColor Yellow
				$Check = Invoke-Command -Session $session -ScriptBlock { (Get-ChildItem "HKCR:\Installer\Products") | Where-Object { $_.GetValue("ProductName") -like "*LabTech*" } }
				If ($null -ne $Check)
				{
					Write-Host "$Computer has LabTech Installed!" -ForegroundColor Yellow
					"$Computer already had it installed" | Out-File $LogFile\log.txt -Append -Force
					#incriments to keep track of the amount of computers that have it installed already 
				}
				Else
				{
					Write-Host "$Computer does not currently have LabTech installed! Continuing" -ForegroundColor Green
					Write-Host "Creating C:\Transfer\ on $Computer" -ForegroundColor Yellow
					#Creates a directory on the remote machine 
					Invoke-Command -Session $session -ScriptBlock { New-Item -ItemType Directory "C:\Transfer" -ErrorAction SilentlyContinue } | Out-Null
					Write-Host "Done!" -ForegroundColor White
					Do
					{
						Write-Host "Copying over the Windows Agent File to $Computer..." -ForegroundColor Yellow
						#Copys over the file to our new directory we created above
						Copy-Item -Path $FiletoTransfer -Destination "\\$computer\C$\Transfer\" -Force -ErrorAction Continue
						Write-Host "Done!" -ForegroundColor White
						
						$CheckforFile = Invoke-Command -Session $session -ScriptBlock { Test-Path -Path C:\transfer\LabTech_Install.msi }
						If ($CheckforFile -eq $True)
						{
							$CopyCode++
							Do
							{
								"Installing LabTech on $Computer" | Out-File $LogFile\log.txt -Append -Force
								Write-Host "Installing the agent on $Computer..." -ForegroundColor Yellow
								Invoke-Command -Session $session -ScriptBlock { Start-Process "msiexec.exe" -ArgumentList "/i C:\Transfer\LabTech_Install.msi /q" -Wait }
								
								Write-Host "Checking to see if LabTech is installed" -ForegroundColor Yellow
								$Check = Invoke-Command -Session $session -ScriptBlock { (Get-ChildItem "HKCR:\Installer\Products") | Where-Object { $_.GetValue("ProductName") -like "*LabTech*" } }
								if ($null -ne $Check)
								{
									"LabTech installed on $Computer" | Out-File $LogFile\log.txt -Append -Force
									Write-Host "$Computer has $LabTech Installed!" -ForegroundColor Green
									#Adds 1 to the variable to keep track of how many computers don't have the path and will be worked on
									$ComputerWork++
									
									$InstallCode++
								}
								Else
								{
									$Retry++
									"Could not install LabTech on $Computer" | Out-File $LogFile\log.txt -Append -Force
									Write-Host "Install Failed" -ForegroundColor Red
									#Adds 1 to the variable to keep track of how many computers don't have the path and will be worked on
									If ($Retry -eq 1)
									{
										"Retrying install of LabTech on $Computer" | Out-File $LogFile\log.txt -Append -Force
										Write-Host "Retrying install of LabTech on $Computer" -ForegroundColor Red
									}
								}
							}
							Until (($Retry -gt 3) -or ($InstallCode -gt 0))
							
							Write-Host "Exiting pssession" -ForegroundColor Yellow
							Get-PSSession -Name $Session.Name | Remove-PSSession -ErrorAction SilentlyContinue
							
						}
						Else
						{
							$RetryCopyFile++
							"Could not copy install files to $Computer" | Out-File $LogFile\log.txt -Append -Force
							Write-Host "Could not copy install files to $Computer" -ForegroundColor red
							If ($RetryCopyFile -eq 1)
							{
								"Retrying to copy install files to $Computer" | Out-File $LogFile\log.txt -Append -Force
								Write-Host "Retrying to copy install files to $Computer" -ForegroundColor red
							}
						}
					}
					Until (($RetryCopyFile -gt 3) -or ($CopyCode -gt 0))
				}
			}
			Else
			{
				"Could not establish a PSSession to $Computer" | Out-File $LogFile\log.txt -Append -Force
				Write-Host "Could not establish a PSSession to $Computer!" -ForegroundColor red
			}
			
		}
		Write-Host "Removing any ghost PSSessions" -ForegroundColor DarkYellow
		Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue
	}
}
#Run the script until we hit all of the computers
Until ($ComputerWork -eq $ComputerCount)
# Get End Time
$endDTM = (Get-Date)

Write-Host "---------STATS----------" -ForegroundColor White
Write-Host "SCRIPT RUNTIME: $(($endDTM - $startDTM).totalseconds) seconds" -ForegroundColor Green
Write-Host "COMPUTERS INSTALLED SUCESSFULLY: $computerwork" -ForegroundColor Green