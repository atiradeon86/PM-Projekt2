
#Variables

$Variables = Get-Content "data.json" | ConvertFrom-Json
$log_name= $Variables.Variable.Logfile_name
$password = $Variables.Variable.password
$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
$hostname= hostname
$username= whoami
$log_file= $pwd.Path + "\$log_name.txt"
$passwd = "1234" | ConvertTo-SecureString -AsPlainText -Force


#Functions 

Function Check {

[bool] $ok = 0

#Admin?   
$admin_check = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")

if ($admin_check -eq $true) {
    echo "Admin Ok"
    [bool] $admin_check = 1
} else {
    echo "Please run as Administrator ..."
}

$version = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release

if ($version -eq 533320) {
    [bool] $dotnet_check = 1
    echo ".Net: 4.8.1 Installed"
}

if (($admin_check -eq $true) -and ($dotnet_check -eq $true))  {
    echo "Ok"
} else {
    exit
}

}
Check
function CreatFolders {
    param (
        [string[]]$file,  [string[]]$disk
    )

    $data= Import-Csv -Path $file
    $InitialPath= "$disk`:`\Teszt" 
    echo $InitialPath
    
    $data | ForEach-Object {
        $CurrentFolder = $_.Name
        $CurrentFolder = Join-Path -Path "$InitialPath" -ChildPath "$CurrentFolder"
        New-Item -Path $CurrentFolder  -ItemType Directory
    } 
        
    }
    
Function Auth {
    param (
        [string[]]$p
    )
    [String]$pwd = Read-Host "Please enter your password"

    if (-not( $pwd -eq $p )) {
       exit
    }
    
}

function Transcript { 
    param (
        [string[]]$cmd
    )
    if ($cmd -eq "start") {
    Start-Transcript -path "$log_file" -append 
    } else {
        Stop-Transcript    
    }

}

#Transcript -cmd start
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
Auth -p $password

Data-show

function ChooseBestDisk{ 

    $Disk= Get-Disk | Sort-Object -Property Size -desc | Select-object -First 1   
    $Disk_number= $Disk.Number
    $Partition= Get-Partition -DiskNumber $Disk_number | Sort-Object "Size" -Descending | Select-object -First 1
    $Drive_Letter = $Partition.DriveLetter
    #return $Drive_Letter
}
#ChooseBestDisk

#CreatFolders -file folders.csv -disk $Drive_Letter

#Transcript -cmd stop
