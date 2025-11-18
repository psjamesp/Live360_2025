# JEA DEMO Endpoint Deployment Script
# This script deploys the JEA configuration files and registers the DEMO endpoint

#Requires -RunAsAdministrator
#Requires -Version 5.1

<#
.SYNOPSIS
    Deploys and registers the DEMO JEA endpoint
.DESCRIPTION
    This script:
    1. Creates the required directory structure
    2. Copies the role capability files
    3. Copies the session configuration file
    4. Registers the JEA endpoint
    5. Verifies the deployment
.EXAMPLE
    .\Deploy-JEAEndpoint.ps1
#>

[CmdletBinding()]
param()

# Configuration variables
$ModuleName = 'JEA_DEMO'
$RoleCapabilitiesPath = "$env:ProgramFiles\WindowsPowerShell\Modules\$ModuleName\RoleCapabilities"
$SessionConfigPath = "$env:ProgramFiles\WindowsPowerShell\Modules\$ModuleName"
$TranscriptPath = "C:\ProgramData\JEAConfiguration\Transcripts"

Write-Host "Starting JEA DEMO Endpoint Deployment..." -ForegroundColor Cyan

# Step 1: Create directory structure
Write-Host "`n[Step 1] Creating directory structure..." -ForegroundColor Yellow
try {
    if (-not (Test-Path $RoleCapabilitiesPath)) {
        New-Item -Path $RoleCapabilitiesPath -ItemType Directory -Force | Out-Null
        Write-Host "  ✓ Created: $RoleCapabilitiesPath" -ForegroundColor Green
    }
    
    if (-not (Test-Path $TranscriptPath)) {
        New-Item -Path $TranscriptPath -ItemType Directory -Force | Out-Null
        Write-Host "  ✓ Created: $TranscriptPath" -ForegroundColor Green
    }
}
catch {
    Write-Error "Failed to create directories: $_"
    exit 1
}

# Step 2: Copy Role Capability files
Write-Host "`n[Step 2] Copying Role Capability files..." -ForegroundColor Yellow
try {
    Copy-Item -Path ".\BasicOperator.psrc" -Destination $RoleCapabilitiesPath -Force
    Write-Host "  ✓ Copied: BasicOperator.psrc" -ForegroundColor Green
    
    Copy-Item -Path ".\AdvancedOperator.psrc" -Destination $RoleCapabilitiesPath -Force
    Write-Host "  ✓ Copied: AdvancedOperator.psrc" -ForegroundColor Green
}
catch {
    Write-Error "Failed to copy role capability files: $_"
    exit 1
}

# Step 3: Copy Session Configuration file
Write-Host "`n[Step 3] Copying Session Configuration file..." -ForegroundColor Yellow
try {
    Copy-Item -Path ".\DEMO.pssc" -Destination $SessionConfigPath -Force
    Write-Host "  ✓ Copied: DEMO.pssc" -ForegroundColor Green
}
catch {
    Write-Error "Failed to copy session configuration file: $_"
    exit 1
}

# Step 4: Register the JEA endpoint
Write-Host "`n[Step 4] Registering DEMO JEA endpoint..." -ForegroundColor Yellow
try {
    # Check if endpoint already exists
    $existingEndpoint = Get-PSSessionConfiguration -Name DEMO -ErrorAction SilentlyContinue
    
    if ($existingEndpoint) {
        Write-Host "  ! Endpoint 'DEMO' already exists. Unregistering..." -ForegroundColor Yellow
        Unregister-PSSessionConfiguration -Name DEMO -Force -NoServiceRestart
        Write-Host "  ✓ Unregistered existing endpoint" -ForegroundColor Green
    }
    
    # Register the new endpoint
    Register-PSSessionConfiguration -Path "$SessionConfigPath\DEMO.pssc" -Name DEMO -Force -NoServiceRestart
    Write-Host "  ✓ Registered DEMO endpoint" -ForegroundColor Green
    
    # Restart WinRM service
    Write-Host "  → Restarting WinRM service..." -ForegroundColor Yellow
    Restart-Service WinRM -Force
    Write-Host "  ✓ WinRM service restarted" -ForegroundColor Green
}
catch {
    Write-Error "Failed to register JEA endpoint: $_"
    exit 1
}

# Step 5: Verify deployment
Write-Host "`n[Step 5] Verifying deployment..." -ForegroundColor Yellow
try {
    $endpoint = Get-PSSessionConfiguration -Name DEMO
    if ($endpoint) {
        Write-Host "  ✓ DEMO endpoint is registered" -ForegroundColor Green
        Write-Host "`n  Endpoint Details:" -ForegroundColor Cyan
        Write-Host "    Name: $($endpoint.Name)"
        Write-Host "    Permission: $($endpoint.Permission)"
        Write-Host "    RunAsUser: $(if($endpoint.RunAsUser){'Configured'}else{'Virtual Account'})"
    }
    else {
        Write-Warning "Endpoint verification failed"
    }
}
catch {
    Write-Warning "Could not verify endpoint: $_"
}

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "JEA DEMO Endpoint Deployment Complete!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan

Write-Host "`nTo test the endpoint, use:" -ForegroundColor Yellow
Write-Host "  Enter-PSSession -ComputerName localhost -ConfigurationName DEMO" -ForegroundColor White
Write-Host "`nTo view available commands in the JEA session:" -ForegroundColor Yellow
Write-Host "  Get-Command" -ForegroundColor White
Write-Host ""
