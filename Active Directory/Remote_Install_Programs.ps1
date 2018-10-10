#Local files to transfer over so it will run locally
$FiletoTransfer = "C:\Transfer\agent_chicago.exe"
###Make sure to modify line 53 to match the .exe file name!!! 

#Parse computers from Active Directory
#$Computers = Get-ADComputer -Filter * -SearchBase "OU=BW Computers,DC=BW,DC=LOCAL" | %{$_.Name} 
#Manually enter in computers
$Computers = "BWYATT-Spare001","BWYATT025","BWYATT6","BWYATT03","BWYATT02"
#Parse computers in a network range
#$Computers = 1..254 | % { "192.168.1.$_" }
#Credentials for accessing the remote machines
$Cred = Get-Credential
$CounterHeartBeat = 0
$Computerpathfound = 0
$computerwork = 0
#Counts the number of computers it will have to hit, this tells the script when to stop once it hits this number of computers
$ComputerCount = ($Computers).count

 
# Get Start Time so we can output how long it takes the script to run
$startDTM = (Get-Date)
Do {
ForEach ($Computer in $Computers)
    {
    Write-Host "Testing Connection to $Computer" -ForegroundColor Yellow -BackgroundColor Blue
    $Heartbeat = (Test-Connection -Count 1 -BufferSize 1 -ComputerName $computer -ErrorAction SilentlyContinue).ResponseTime
    If(!$Heartbeat)
        {
        Write-Host "$Computer is offline/unreachable" -ForegroundColor Red
        $CounterHeartBeat ++
        }
    Else
        {
        Write-Host "Done!" -ForegroundColor White
        Write-Host "Testing path for $Computer..." -ForegroundColor Yellow
        #Tests to see if the path is present on the remote computer
        $Testing = Test-Path "\\$Computer\C$\Transfer\"
        If ($Testing -eq $False)
            {
            #Adds 1 to the variable to keep track of how many computers don't have the path and will be worked on
            $ComputerWork ++
            Write-Host "No path found, continuing..." -ForegroundColor Yellow
            Write-Host "Creating C:\Transfer\ on $Computer" -ForegroundColor Yellow
            #Creates a directory on the remote machine 
            Invoke-Command -ComputerName $Computer -Credential $cred -ScriptBlock {New-Item -ItemType Directory "C:\Transfer" -ErrorAction SilentlyContinue} | Out-Null 
            Write-Host "Done!" -ForegroundColor White 
            Write-Host "Copying over the Windows Agent File to $Computer..." -ForegroundColor Yellow
            #Copys over the file to our new directory we created above
            Copy-Item -Path $FiletoTransfer -Destination "\\$computer\C$\Transfer\" -ErrorAction SilentlyContinue
            Write-Host "Done!" -ForegroundColor White
            Write-Host "Installing the agent on $Computer..." -ForegroundColor Yellow
            #Runs the exe in silent mode. Please note that when PowerShell runs the .exe file you wont see it if youre logged in as a user anyways because it wont launch it in an interactive login by default
            Invoke-Command -ComputerName $Computers -ScriptBlock {Start-Process "C:\Transfer\agent_chicago.exe" -ArgumentList "/s" }
            Write-Host "Done!" -ForegroundColor White
            }
        Else
            {
            Write-Host "Looks like the folder is present, canceling..." -ForegroundColor Red
            #Adds 1 to the variable to count how many computers have the path already, this shows us that they have been hit already since we create the directory on new computers
            $ComputerPathFound ++
            }
        }
    }
Write-Host "Computers Hit: $ComputerWork" -ForegroundColor Green
}
#Run the script until we hit all of the computers
Until ($Computerpathfound -eq $ComputerCount)
# Get End Time
$endDTM = (Get-Date)
 
Write-Host "---------STATS----------" -ForegroundColor White
Write-Host "SCRIPT RUNTIME:$(($endDTM-$startDTM).totalseconds) seconds" -ForegroundColor Green
Write-Host "COMPUTERS NOT REACHABLE: $CounterHeartBeat" -ForegroundColor Green
Write-Host "COMPUTERS WORKED ON: $computerwork" -ForegroundColor Green
Write-Host "COMPUTERS SKIPPED: $Computerpathfound" -ForegroundColor Green