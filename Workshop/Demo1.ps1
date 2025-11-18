# Full-Day PowerShell Demo Script
# Write-Host commands removed, lab sections marked with comments

#region 01 - Command Discovery
verb-noun

# Get help, commands, members - This is a single line comment
<# This is a multip line comment
asdf
sadfg
sdfg
sdfgh
dsfgh
#>

update-help

Get-Help Get-Service
Get-Help Get-Service -Full

Get-Help Get-Service -Examples
get-help get-service -Online

Get-Command
Get-Command *service*
Get-Command -Verb Get
get-command -Module Microsoft.WSMan.Management -verb get
get-command -Noun Service

Get-Service | Get-Member
Get-Process | Get-Member

get-service BITS
get-service bits | select-Object *

(get-service -Name BITS).Name

get-service -name spooler, BITS
get-service -name spooler, bits | Format-Table -AutoSize
get-service -name spooler, bits | Format-List 
get-service -name spooler, bits | Select-Object *


# Lab 1 goes here

get-service bits | restart-service
get-service bits | restart-service -name bits
get-service | Select-Object -Property Name, Status | Sort-Object Name
#endregion

#region 02 - Services and Processes
Get-Service -Name Spooler
Get-Service -Name Spooler | Select-Object *
Get-Service -Name Spooler | Get-Member
Get-Service -Name Spooler | Stop-Service
Stop-Service -Name Spooler
$service = Get-Service -Name Spooler
# Lab 2 goes here
#endregion

#region 03 - Variables and Data Types
$varName = "This is a string"

$service = get-service BITS
$service
$service = get-service bits | select name
$service

get-service bits | Stop-Service
$service | Stop-Service



$dime = 10

$dime = "ten"
$dime = "10"
$dime = dir

5 + 5
5 + "five"
"" + 5 + "five"
"five" + 5
$dime + 1
1 + $dime
"10" + 1
1 + "10"
[string]10 + 1
"5" + 5 # New Math 5+ 5 = 55

$service = get-service bits | select name, Status, DisplayName

$MyString = "The service name is $($service.DisplayName) and the status is $($service.Status)"
$MyString

$dime = ""
$dime = $dime + 10

$dime = 10
$dime = $dime + 10
$dime += 10


Restart-Service -Name "W3SVC" -Force


get-service bits | Tee-Object .\services.txt | select * | Sort-Object -Property Name




get-service -name bits | Format-List

get-process -name Code
get-process -name code | Out-Default
Get-Service
Write-Output
Write-Error "danger danger"
Write-Warning "Almost a danger"
Write-verbose "i'm verbose are you?"

Write-Host "Why is write-host so bad?"
Write-Output "I'm the more correct way"

write-host "Hi Y'all" -BackgroundColor green
$VerbosePreference
$VerbosePreference = "continue"

write-verbose "Now you see me"

get-service bits | Out-Default
get-service bits | Out-File
get-service bits | convertto-html | Out-File
get-service bits | export-csv


# Lab 2 goes here
#endregion

#region 04 - File System Operations
Get-ChildItem
Get-ChildItem | Sort-Object -Property Name | Format-Table

New-Item -Path "C:\Scripts\Live360_2025\workshop\" -Name files -ItemType directory

1..10 | ForEach-Object { New-Item -ItemType File -Name "$_.md" }
$files = Get-ChildItem -Path C:\Scripts\Live360_2025\workshop\files | Select-Object Name


foreach ($s in $services) {
    # do something
}

ForEach ($f in $files) { $f }

$Planets = "Mars", "Earth", 'Saturn', "Pluto"
$planets | ForEach-Object { new-item -ItemType File -name "$_.md" }

foreach ($p in $planets) {
    write-host $p
}

foreach ($p in $planets) {
    new-item -ItemType File -name "$p.md" -Force
}

foreach ($p in $planets) {
    remove-item "$p.md"
}

get-service spooler, bits | Stop-Service

$service = get-service spooler, BITS
foreach ($s in $service) {
    start-service -name $s.Name
    write-host "I have started the $($s.name) Service"
}


#region 05 - Loops and Object Manipulation 

5 -gt 4
"dog" -eq "dog"
"dog" -eq "cat"

"dog" -gt "cat"

"james" -gt "jane"

-lt, -gt, -eq, -ne, -le, -ge

$service = get-service bits 
$service.Status -eq "running"

if (condition) {
    <# Action to perform if the condition is true #>
}

if ($service.Status -eq "Stopped") {
    Write-Host "The service is running"
}

if ($service.status -ne "running") {
    Start-Service -Name $service.Name
    get-service $service.Name
}

if ((get-service spooler).status -eq "running") {
    Stop-Service -Name "Spooler"
    get-service spooler
}

$service = Get-Service Spooler, BITS
foreach ($s in $service) { Stop-Service -Name $s.Name }

$service = Get-Service Spooler, BITS
foreach ($s in $service) {
    if ($s.Status -eq "Stopped") { Start-Service $s.Name }
}

#on the fly lab
write a script that will check to see if the startup type for the spooler service is 
automatic
if it is automatic, change it to manual

foreach ($s in $service) {
    if ($s.StartType -eq "Automatic") {
        Set-Service -Name $s.Name -StartupType Manual
    }
}

if ($service.Status -eq "running") {
    Write-Host "The service is running"
}
elseif ($service.status -eq "stopped") {
    Start-Service -Name $service.Name
}
else {
    Write-Host "The service is in a weird state"
}


# Lab 3 goes here
#endregion

#region 06 - Date and Strings
Get-Date
Get-Date | Get-Member
Get-Date | Select-Object Hour
(get-date).Year

Get-Date -Format "MM-dd-yyyy hh:mm"
get-date -format "MM-dd-yyyy hh:mm"

(Get-Date).AddDays(-4)

$daysuntilchristmas = (get-date 12/25/2025) - (get-date)
$daysuntilchristmas.Days


#region 07 - Remoting
$cred = Get-Credential
Enter-PSSession -ComputerName srv01 -Credential $cred
Invoke-Command -ComputerName srv01, srv02 -ScriptBlock { $env:COMPUTERNAME } -Credential 714tech\bob
Invoke-Command -ComputerName (Get-Content c:\scripts\computers.txt) -ScriptBlock { $env:COMPUTERNAME }
Invoke-Command -ComputerName (Import-Csv c:\scripts\computers.Import-Csv) -ScriptBlock { $env:COMPUTERNAME }
Invoke-Command -ComputerName (Get-ADComputer -Filter "OU=printers,dc=test,dc=lab") -ScriptBlock { $env:COMPUTERNAME }
# Lab 4 goes here
#endregion

#region 08 - Registry and Environment
Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name PortNumber -Value "3399"
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "smileyface" -Value "yes" 
Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "smileyface"
# Lab 4 goes here
#endregion

$cred = Get-Credential
Enter-PSSession -ComputerName srv01 -Credential $cred
Invoke-Command -ComputerName srv01, srv02, dc01 -ScriptBlock { $env:COMPUTERNAME } -Credential $cred

invoke-command -ComputerName srv01 -FilePath .\Scripts\RemoteScript.ps1 -Credential $cred
Enter-PSSession -HostName srv01 -UserName 714tech\bob

$computers = get-adcomputer -Filter * -SearchBase "Ou=SCCM,OU=Servers,DC=test,DC=lab" | Select-Object -ExpandProperty Name
invoke-command -ComputerName $computers -ScriptBlock { restart-computer -Force }
Invoke-Command -ComputerName (get-coment .\servers.txt) -ScriptBlock { do stuff }