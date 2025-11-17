# Full-Day PowerShell Demo Script - AFTERNOON SESSION
# Sections 5-10: Filtering, Functions, Error Handling, Remoting, and Practical Scenarios

#region 05 - Filtering & Where-Object
# Basic filtering
Get-Service | Where-Object { $_.Status -eq "Running" }
Get-Service | Where-Object Status -eq "Running"
Get-Service | Where-Object { $_.Status -eq "Stopped" }

# Multiple conditions
Get-Service | Where-Object { $_.Status -eq "Running" -and $_.Name -like "W*" }
Get-Process | Where-Object { $_.CPU -gt 10 -or $_.WorkingSet -gt 100MB }

# Filtering processes
Get-Process | Where-Object { $_.CPU -gt 0 } | Select-Object Name, CPU, WorkingSet
Get-Process | Where-Object WorkingSet -gt 50MB | Sort-Object WorkingSet -Descending

# Filtering files
Get-ChildItem | Where-Object { $_.Length -gt 1KB }
Get-ChildItem | Where-Object Extension -eq ".txt"
Get-ChildItem | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) }

# Comparison operators demonstration
# -eq (equal), -ne (not equal), -gt (greater than), -lt (less than)
# -like (wildcard), -match (regex), -contains, -in
Get-Service | Where-Object { $_.Name -like "Win*" }
Get-Service | Where-Object { $_.Name -match "^W" }
"BITS", "Spooler" | Where-Object { $_ -in (Get-Service).Name }

# Lab 3 goes here - Filter services and create report
# Task: Get all running services that start with "W" and export to CSV
Get-Service | Where-Object { $_.Status -eq "Running" -and $_.Name -like "W*" } | 
Select-Object Name, DisplayName, Status | 
Export-Csv -Path ".\RunningServices.csv" -NoTypeInformation

#endregion

#region 06 - Functions
# Basic function
function Get-RunningServices {
    Get-Service | Where-Object { $_.Status -eq "Running" }
}
Get-RunningServices

# Function with parameters
function Get-ServiceByStatus {
    param($Status)
    Get-Service | Where-Object { $_.Status -eq $Status }
}
Get-ServiceByStatus -Status Running
Get-ServiceByStatus -Status Stopped

# Function with multiple parameters
function Restart-ServiceSafely {
    param(
        $ServiceName,
        $WaitSeconds = 2
    )
    Write-Host "Stopping $ServiceName..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName
    Write-Host "Waiting $WaitSeconds seconds..." -ForegroundColor Cyan
    Start-Sleep -Seconds $WaitSeconds
    Write-Host "Starting $ServiceName..." -ForegroundColor Yellow
    Start-Service -Name $ServiceName
    Write-Host "Service restarted successfully!" -ForegroundColor Green
}
# Restart-ServiceSafely -ServiceName "Spooler"

# Advanced function with parameter validation
function Get-ServiceInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Running", "Stopped", "All")]
        [string]$Status = "All"
    )
    
    $services = Get-Service -Name $Name
    
    if ($Status -ne "All") {
        $services = $services | Where-Object { $_.Status -eq $Status }
    }
    
    return $services | Select-Object Name, Status, DisplayName
}
Get-ServiceInfo -Name "B*"
Get-ServiceInfo -Name "W*" -Status Running

# Function with pipeline support
function Get-LargeFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$MinimumSizeMB = 1
    )
    
    Get-ChildItem -File | 
    Where-Object { $_.Length -gt ($MinimumSizeMB * 1MB) } |
    Select-Object Name, @{Name = "SizeMB"; Expression = { [math]::Round($_.Length / 1MB, 2) } } |
    Sort-Object SizeMB -Descending
}
Get-LargeFiles
Get-LargeFiles -MinimumSizeMB 5

# Function that returns custom objects
function Get-ServiceReport {
    param($ServiceName)
    
    $service = Get-Service -Name $ServiceName
    
    $report = [PSCustomObject]@{
        ServiceName = $service.Name
        DisplayName = $service.DisplayName
        Status      = $service.Status
        StartType   = $service.StartType
        CheckTime   = Get-Date
    }
    
    return $report
}
Get-ServiceReport -ServiceName "BITS"

# Lab 4 goes here - Create a function to manage multiple services
function Restart-MultipleServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ServiceNames
    )
    
    foreach ($service in $ServiceNames) {
        try {
            Write-Host "Restarting $service..." -ForegroundColor Cyan
            Restart-Service -Name $service -Force -ErrorAction Stop
            Write-Host "✓ $service restarted successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Failed to restart $service" -ForegroundColor Red
        }
    }
}
# Restart-MultipleServices -ServiceNames "Spooler", "BITS"

#endregion

#region 07 - Error Handling
# Basic error handling
try {
    Get-Service -Name "FakeServiceName" -ErrorAction Stop
}
catch {
    Write-Warning "An error occurred: $_"
}

# Try/Catch/Finally
try {
    Write-Host "Attempting to stop a service..." -ForegroundColor Yellow
    Stop-Service -Name "NonExistentService" -ErrorAction Stop
}
catch {
    Write-Error "Failed to stop service: $($_.Exception.Message)"
}
finally {
    Write-Host "Cleanup or logging code goes here" -ForegroundColor Cyan
}

# ErrorAction parameter options
Get-Service -Name "FakeService" -ErrorAction SilentlyContinue
Get-Service -Name "FakeService" -ErrorAction Continue
Get-Service -Name "FakeService" -ErrorAction Ignore
# Get-Service -Name "FakeService" -ErrorAction Stop  # Will throw terminating error

# Error variables
Get-Service -Name "FakeService" -ErrorAction SilentlyContinue -ErrorVariable ServiceError
$ServiceError

# Handling specific error types
try {
    $result = 1 / 0
}
catch [System.DivideByZeroException] {
    Write-Warning "Cannot divide by zero!"
}
catch {
    Write-Error "An unexpected error occurred: $_"
}

# Function with error handling
function Get-ServiceSafely {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    try {
        $service = Get-Service -Name $Name -ErrorAction Stop
        return $service
    }
    catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
        Write-Warning "Service '$Name' not found"
        return $null
    }
    catch {
        Write-Error "Unexpected error: $($_.Exception.Message)"
        return $null
    }
}
Get-ServiceSafely -Name "BITS"
Get-ServiceSafely -Name "FakeService"

# Robust service restart with error handling
function Restart-ServiceRobust {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    
    try {
        # Check if service exists
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        Write-Host "Current status: $($service.Status)" -ForegroundColor Cyan
        
        if ($service.Status -eq "Stopped") {
            Write-Host "Service is already stopped, starting..." -ForegroundColor Yellow
            Start-Service -Name $ServiceName -ErrorAction Stop
        }
        else {
            Write-Host "Restarting service..." -ForegroundColor Yellow
            Restart-Service -Name $ServiceName -Force -ErrorAction Stop
        }
        
        Write-Host "Service operation completed successfully!" -ForegroundColor Green
        return $true
    }
    catch [Microsoft.PowerShell.Commands.ServiceCommandException] {
        Write-Error "Service '$ServiceName' not found"
        return $false
    }
    catch [System.InvalidOperationException] {
        Write-Error "Cannot perform operation on service: $($_.Exception.Message)"
        return $false
    }
    catch {
        Write-Error "Unexpected error: $($_.Exception.Message)"
        return $false
    }
}
# Restart-ServiceRobust -ServiceName "Spooler"

# Lab 5 goes here - Add error handling to previous functions

#endregion

#region 08 - PowerShell Remoting
# NOTE: These commands require administrative privileges and proper network configuration

# Enable PowerShell Remoting (run on remote computer)
# Enable-PSRemoting -Force

# Test connectivity
Test-WSMan -ComputerName localhost

# One-to-One remoting (Interactive session)
# Enter-PSSession -ComputerName "Server01"
# Get-Service
# Exit-PSSession

# One-to-Many remoting
Invoke-Command -ComputerName localhost -ScriptBlock {
    Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object -First 5
}

# Run commands on multiple computers
$computers = "localhost", "127.0.0.1"
Invoke-Command -ComputerName $computers -ScriptBlock {
    $env:COMPUTERNAME
    Get-Service -Name "BITS" | Select-Object Name, Status
}

# Using variables in remote commands
$serviceName = "BITS"
Invoke-Command -ComputerName localhost -ScriptBlock {
    param($svc)
    Get-Service -Name $svc
} -ArgumentList $serviceName

# Creating and using sessions
$session = New-PSSession -ComputerName localhost
Invoke-Command -Session $session -ScriptBlock {
    Get-Date
    $env:COMPUTERNAME
}
Remove-PSSession $session

# Persistent sessions for multiple commands
$session = New-PSSession -ComputerName localhost
Invoke-Command -Session $session -ScriptBlock { $myVar = "Hello from remote!" }
Invoke-Command -Session $session -ScriptBlock { $myVar }
Remove-PSSession $session

# Copy files to/from remote computers
# Copy-Item -Path "C:\Scripts\test.txt" -Destination "C:\Temp\" -ToSession $session
# Copy-Item -Path "C:\Temp\remotefile.txt" -Destination "C:\Local\" -FromSession $session

# Remote service management function
function Get-RemoteServiceStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        param($svc)
        Get-Service -Name $svc | Select-Object @{Name = "Computer"; Expression = { $env:COMPUTERNAME } }, Name, Status, StartType
    } -ArgumentList $ServiceName
}
Get-RemoteServiceStatus -ComputerName localhost -ServiceName "BITS"

# Lab 6 goes here - Create remote service management script

#endregion

#region 09 - Practical Scenarios
# Scenario 1: Service Health Monitoring
function Get-ServiceHealthReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$ServiceNames = @("BITS", "Spooler", "WinRM", "W3SVC")
    )
    
    $report = foreach ($serviceName in $ServiceNames) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            [PSCustomObject]@{
                ServiceName = $service.Name
                DisplayName = $service.DisplayName
                Status      = $service.Status
                StartType   = $service.StartType
                Health      = if ($service.Status -eq "Running") { "Healthy" } else { "Unhealthy" }
                CheckTime   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        catch {
            [PSCustomObject]@{
                ServiceName = $serviceName
                DisplayName = "N/A"
                Status      = "Not Found"
                StartType   = "N/A"
                Health      = "Error"
                CheckTime   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }
    
    return $report
}

# Run the report
$healthReport = Get-ServiceHealthReport
$healthReport | Format-Table -AutoSize
$healthReport | Export-Csv -Path ".\ServiceHealthReport.csv" -NoTypeInformation

# Scenario 2: Automated Service Restart with Logging
function Restart-ServiceWithLogging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = ".\ServiceRestart.log"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    try {
        # Log start
        "$timestamp - Starting restart of $ServiceName" | Out-File -FilePath $LogPath -Append
        
        # Get current status
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        "$timestamp - Current status: $($service.Status)" | Out-File -FilePath $LogPath -Append
        
        # Restart service
        Restart-Service -Name $ServiceName -Force -ErrorAction Stop
        
        # Verify restart
        Start-Sleep -Seconds 2
        $service = Get-Service -Name $ServiceName
        "$timestamp - New status: $($service.Status)" | Out-File -FilePath $LogPath -Append
        "$timestamp - Restart completed successfully" | Out-File -FilePath $LogPath -Append
        
        Write-Host "✓ $ServiceName restarted successfully" -ForegroundColor Green
        return $true
    }
    catch {
        "$timestamp - ERROR: $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append
        Write-Host "✗ Failed to restart $ServiceName" -ForegroundColor Red
        return $false
    }
}
# Restart-ServiceWithLogging -ServiceName "Spooler"

# Scenario 3: Bulk File Operations with Error Handling
function Rename-FilesWithPrefix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Prefix,
        
        [Parameter(Mandatory = $false)]
        [string]$Extension = "*"
    )
    
    try {
        $files = Get-ChildItem -Path $Path -Filter "*.$Extension" -File -ErrorAction Stop
        
        $count = 0
        foreach ($file in $files) {
            try {
                $newName = "$Prefix`_$($file.Name)"
                Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                Write-Host "✓ Renamed: $($file.Name) -> $newName" -ForegroundColor Green
                $count++
            }
            catch {
                Write-Warning "Failed to rename $($file.Name): $($_.Exception.Message)"
            }
        }
        
        Write-Host "`nTotal files renamed: $count" -ForegroundColor Cyan
        return $count
    }
    catch {
        Write-Error "Failed to process directory: $($_.Exception.Message)"
        return 0
    }
}

# Scenario 4: System Information Report
function Get-SystemReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\SystemReport.html"
    )
    
    # Gather information
    $computerInfo = Get-ComputerInfo
    $services = Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object -First 10
    $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, CPU, WorkingSet
    
    # Create HTML report
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th { background-color: #4CAF50; color: white; padding: 10px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>System Report</h1>
    <p><strong>Generated:</strong> $(Get-Date)</p>
    <p><strong>Computer:</strong> $($computerInfo.CsName)</p>
    <p><strong>OS:</strong> $($computerInfo.OsName)</p>
    
    <h2>Top 10 Running Services</h2>
    $($services | ConvertTo-Html -Fragment)
    
    <h2>Top 10 Processes by CPU</h2>
    $($processes | ConvertTo-Html -Fragment)
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath
    Write-Host "Report generated: $OutputPath" -ForegroundColor Green
    
    # Open report
    # Invoke-Item $OutputPath
}
# Get-SystemReport

# Scenario 5: Service Dependency Checker
function Get-ServiceDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        Write-Host "`nService: $($service.DisplayName)" -ForegroundColor Cyan
        Write-Host "Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Yellow" })
        
        Write-Host "`nServices this depends on:" -ForegroundColor Yellow
        $dependencies = $service.ServicesDependedOn
        if ($dependencies.Count -eq 0) {
            Write-Host "  None" -ForegroundColor Gray
        }
        else {
            foreach ($dep in $dependencies) {
                Write-Host "  - $($dep.Name) [$($dep.Status)]" -ForegroundColor White
            }
        }
        
        Write-Host "`nServices that depend on this:" -ForegroundColor Yellow
        $dependents = Get-Service -DependentServices -Name $ServiceName
        if ($dependents.Count -eq 0) {
            Write-Host "  None" -ForegroundColor Gray
        }
        else {
            foreach ($dep in $dependents) {
                Write-Host "  - $($dep.Name) [$($dep.Status)]" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Error "Failed to get service information: $($_.Exception.Message)"
    }
}
# Get-ServiceDependencies -ServiceName "W3SVC"

# Lab 7 goes here - Combine concepts into a complete solution
# Create a script that:
# 1. Monitors specific services
# 2. Restarts them if stopped
# 3. Logs all actions
# 4. Generates an HTML report

function Monitor-ServicesWithReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ServiceNames,
        
        [Parameter(Mandatory = $false)]
        [switch]$RestartIfStopped,
        
        [Parameter(Mandatory = $false)]
        [string]$LogPath = ".\ServiceMonitor.log",
        
        [Parameter(Mandatory = $false)]
        [string]$ReportPath = ".\ServiceMonitor.html"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $results = @()
    
    foreach ($serviceName in $ServiceNames) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            $action = "Checked"
            
            if ($service.Status -ne "Running" -and $RestartIfStopped) {
                Start-Service -Name $serviceName -ErrorAction Stop
                Start-Sleep -Seconds 1
                $service = Get-Service -Name $serviceName
                $action = "Restarted"
                "$timestamp - Restarted $serviceName" | Out-File -FilePath $LogPath -Append
            }
            
            $results += [PSCustomObject]@{
                ServiceName = $service.Name
                DisplayName = $service.DisplayName
                Status      = $service.Status
                Action      = $action
                Result      = "Success"
            }
        }
        catch {
            $results += [PSCustomObject]@{
                ServiceName = $serviceName
                DisplayName = "Unknown"
                Status      = "Error"
                Action      = "Failed"
                Result      = $_.Exception.Message
            }
            "$timestamp - ERROR with $serviceName : $($_.Exception.Message)" | Out-File -FilePath $LogPath -Append
        }
    }
    
    # Generate HTML report
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Service Monitor Report</title>
    <style>
        body { font-family: Arial; margin: 20px; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #4CAF50; color: white; padding: 10px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Service Monitor Report</h1>
    <p><strong>Generated:</strong> $timestamp</p>
    $($results | ConvertTo-Html -Fragment)
</body>
</html>
"@
    
    $html | Out-File -FilePath $ReportPath
    
    # Display summary
    Write-Host "`nMonitoring Summary:" -ForegroundColor Cyan
    $results | Format-Table -AutoSize
    Write-Host "`nLog file: $LogPath" -ForegroundColor Yellow
    Write-Host "Report file: $ReportPath" -ForegroundColor Yellow
}
