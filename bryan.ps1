
#Variables

$Variables = Get-Content "data.json" | ConvertFrom-Json
$log_name= $Variables.Variable.Logfile_name
$password = $Variables.Variable.password
$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
$hostname= hostname
$username= whoami
$log_file= $pwd.Path + "\$log_name.txt"
$passwd = "1234" | ConvertTo-SecureString -AsPlainText -Force
$fqdn= [System.Net.Dns]::GetHostByName($env:computerName).HostName;

Start-Transcript -path "$log_file" -append 


#Functions 
Function Check {

[bool] $ok = 0

#Admin?   

$admin_check = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

if ($admin_check -eq $true) {
    [bool] $admin_check = 1

    #Allow unsigned PS1 file to running
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
} else {
    echo "Please run as Administrator -> Bye..."
}

#Internet Connection Testing

[bool] $NetConnection_check = 0
$Test_NetConnection = Test-NetConnection -Port 80 -InformationLevel 'Detailed'

if ($Test_NetConnection.TcpTestSucceeded -eq $true) {
    [bool] $NetConnection_check = 1
} else {
    echo "You need internet access -> Bye..."
}

#.Net Version Check

$version = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release

[bool] $dotnet_check = 0

if ( ($version -gt 461814) -or ($version -eq 461814) ) {
    [bool] $dotnet_check = 1
} else {
    echo "Please install .Net version at least 4.7.2 (Your installed build number: $version)"
}

if (($admin_check -eq $true) -and ($dotnet_check -eq $true) -and ($NetConnection_check -eq $true))  {
    Write-Host "`r`n"
    Write-Host "Checking for requierments:`r`n" -ForegroundColor Red
    Write-Host "Admin -> Ok" -ForegroundColor Green
    Write-Host "Internet Connection -> Ok" -ForegroundColor Green
    Write-Host ".Net: Version -> Ok" -ForegroundColor Green
    Write-Host "`r`n"
    Write-Host "Done ..." -ForegroundColor Green
    Write-Host "`r`n"

} else {
    exit
}

}

function CreatFolders {
    param (
        [string[]]$file
    )

    $data= Import-Csv -Path $file

    $Disk= Get-Disk | Sort-Object -Property Size -desc | Select-object -First 1   
    $Disk_number= $Disk.Number
    $Partition= Get-Partition -DiskNumber $Disk_number | Sort-Object "Size" -Descending | Select-object -First 1
    $Drive_Letter = $Partition.DriveLetter
    $InitialPath= "$Drive_Letter`:`\Teszt" 
     
    $chk = Test-Path -Path $InitialPath

   
        $data | ForEach-Object {
                $CurrentFolder = $_.Name
                $CurrentFolder = Join-Path -Path "$InitialPath" -ChildPath "$CurrentFolder"
                New-Item -Path $CurrentFolder  -ItemType Directory
            } 
         
    $BeforeFolder = $pwd
    Set-Location $InitialPath
    $folders =  Get-ChildItem -Directory -Depth 0
    $arr =@($folders.Name)

    for ($i=0; $i -lt $arr.Length; $i++) {
        $CompFolder = $InitialPath + "\" + $arr[$i]
        New-SmbShare -Name $arr[$i] -Path "$CompFolder" -ea 0
    }
    
    Set-Location $BeforeFolder
    
}
    
Function Auth {

    #1. Step Create Credential Object
    
    [string]$userName = 'bryan'
    [string]$userPassword = '1234'
    
    [securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
    $credObject | Export-CliXml  -Path bryan-cred.xml
    

    #$Import existing Credential file
    $credential = Import-CliXml -Path .\bryan-cred.xml
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.password)
    $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    #Create temporary Credential file
    [string]$t_userName = 'bryan'
    $t_pwd = Read-Host "Please enter your password" -AsSecureString
    [pscredential]$t_credObject = New-Object System.Management.Automation.PSCredential ($t_userName, $t_pwd)
    $t_credObject | Export-CliXml  -Path temp-cred.xml

    $t_credential = Import-CliXml -Path .\temp-cred.xml
    $bstr_temp = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($t_credential.password)
    $T_UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr_temp)

    #Compare unencrypted strings ... :)
    if (-not( $UnsecurePassword -eq $T_UnsecurePassword )) {
       del .\temp-cred.xml
       del .\bryan-cred.xml
       echo "Bad Password! Bye ..."
       exit
    }
    del .\temp-cred.xml
    del .\bryan-cred.xml
}
function Data-show{

    echo "**********************"
    echo "Warning: While the program is running -> You need to provide your password!"
    echo "Script Started: $Stamp"
    echo "User Started: $username"
    echo "Server Name: $hostname" 
    echo "Started From: $pwd"
    echo "Log file location: $log_file"
    echo "**********************"
    
}
function  Myapp{

$Disk= Get-Disk | Sort-Object -Property Size -desc | Select-object -First 1   
$Disk_number= $Disk.Number
$Partition= Get-Partition -DiskNumber $Disk_number | Sort-Object "Size" -Descending | Select-object -First 1
$Drive_Letter = $Partition.DriveLetter
$InitialPath= "$Drive_Letter`:`\Teszt" 

$chk = Test-Path -Path "$InitialPath\pm-control.zip" -PathType Leaf

echo $InitialPath

if ($chk -eq $false) {

wget https://pm.bryan86.hu/pm-control.zip -OutFile "$InitialPath\pm-control.zip"

    
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip "$InitialPath\pm-control.zip" "$InitialPath\PM"
echo $pwd
}

$fqdn > $InitialPath\PM\Config.txt

#Register Event Source
[System.Diagnostics.EventLog]::CreateEventSource("Bryan PM Control", "Application")

#Create ScheduledTask

$action = New-ScheduledTaskAction -Execute "$InitialPath\PM\pmc.exe"
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet
$task = New-ScheduledTask -Action $action  -Trigger $trigger -Settings $settings
Register-ScheduledTask PMControl -InputObject $task 
Set-ScheduledTask -TaskName 'PMControl'


#Create ScheduledTask Trigger
$class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$trigger = $class | New-CimInstance -ClientOnly
$trigger.Enabled = $true
$trigger.Subscription = ' <QueryList><Query Id="0" Path="Application"><Select Path="Application">*[System[Provider[@Name=''Bryan PM Control''] and EventID=3001]]</Select></Query></QueryList>'

$ActionParameters = @{
    Execute  = "$InitialPath\PM\pmc.exe"
}

$Action = New-ScheduledTaskAction @ActionParameters
$Settings = New-ScheduledTaskSettingsSet

$RegSchTaskParameters = @{
    TaskName    = 'Bryan PM Control - Trigger'
    Description = 'Bryan PM Control - Eventlog Trigger'
    TaskPath    = '\Event Viewer Tasks\'
    Action      = $Action
    Settings    = $Settings
    Trigger     = $Trigger
}

Register-ScheduledTask @RegSchTaskParameters

#Test -> Write-EventLog -ComputerName "$env:computername" -LogName Application -Source "Bryan PM Control" -EventID 3001 -Message "New Message for Task Scheduler"
}

#Workflow

Check
Data-show
CreatFolders -file folders.csv
Myapp
Auth
CreatFolders -file folders2.csv

Stop-Transcript