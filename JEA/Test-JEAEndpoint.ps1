# JEA DEMO Testing Script
# Run each section individually during your live demonstration

#Requires -Version 5.1

<#
.SYNOPSIS
    Live demo script for JEA DEMO endpoint
.DESCRIPTION
    Execute each section step-by-step during your presentation
    Highlight and run each block in your PowerShell ISE or VS Code
#>

# ============================================================================
# TEST 1: Verify the DEMO endpoint is registered
# ============================================================================

Get-PSSessionConfiguration -Name DEMO


# ============================================================================
# TEST 2: View detailed endpoint configuration
# ============================================================================

Get-PSSessionConfiguration -Name DEMO | Format-List *


# ============================================================================
# TEST 3: Connect to the JEA endpoint
# ============================================================================

$session = New-PSSession -ComputerName localhost -ConfigurationName DEMO
$session


# ============================================================================
# TEST 4: See what commands are available in the JEA session
# ============================================================================

Invoke-Command -Session $session -ScriptBlock { Get-Command }


# Group commands by type to show the constraints
Invoke-Command -Session $session -ScriptBlock { Get-Command } | Group-Object CommandType


# ============================================================================
# TEST 5: Execute an allowed command (Get-Service)
# ============================================================================

Invoke-Command -Session $session -ScriptBlock { 
    Get-Service | Select-Object -First 10 Name, Status, StartType
}


# ============================================================================
# TEST 6: Try to restart a service (also allowed)
# ============================================================================

Invoke-Command -Session $session -ScriptBlock { 
    Restart-Service -Name Spooler -WhatIf
}


# ============================================================================
# TEST 7: Test parameter constraints - allowed service name
# ============================================================================

# This should work - Spooler is in the ValidateSet
Invoke-Command -Session $session -ScriptBlock { 
    Stop-Service -Name Spooler -WhatIf
}


# ============================================================================
# TEST 8: Test parameter constraints - disallowed service name
# ============================================================================

# This should FAIL - NotInValidateSet is not in the ValidateSet
Invoke-Command -Session $session -ScriptBlock { 
    Stop-Service -Name NotInValidateSet -WhatIf
}


# ============================================================================
# TEST 9: Try a blocked command (not in VisibleCmdlets)
# ============================================================================

# This should FAIL - Get-ChildItem is not exposed
Invoke-Command -Session $session -ScriptBlock { 
    Get-ChildItem C:\
}


# ============================================================================
# TEST 10: Try another blocked command
# ============================================================================

# This should FAIL - Set-Content is not exposed
Invoke-Command -Session $session -ScriptBlock { 
    Set-Content -Path C:\test.txt -Value "test"
}


# ============================================================================
# TEST 11: Test a custom function
# ============================================================================

Invoke-Command -Session $session -ScriptBlock { 
    Get-ServiceStatus -ServiceName WinRM
}


# ============================================================================
# TEST 12: Check the session's language mode (should be NoLanguage)
# ============================================================================

Invoke-Command -Session $session -ScriptBlock { 
    $ExecutionContext.SessionState.LanguageMode
}


# ============================================================================
# TEST 13: View full session configuration details
# ============================================================================

Invoke-Command -Session $session -ScriptBlock { 
    [PSCustomObject]@{
        LanguageMode = $ExecutionContext.SessionState.LanguageMode
        UserName = $env:USERNAME
        ComputerName = $env:COMPUTERNAME
        ProcessId = $PID
    }
}


# ============================================================================
# TEST 14: Try to access variables (should fail in NoLanguage mode)
# ============================================================================

# This should FAIL - NoLanguage mode blocks variable access
Invoke-Command -Session $session -ScriptBlock { 
    $myVar = "test"
    $myVar
}


# ============================================================================
# CLEANUP: Close the JEA session
# ============================================================================

Remove-PSSession -Session $session


# ============================================================================
# INTERACTIVE DEMO: Connect interactively to the JEA endpoint
# ============================================================================

# Run this to enter an interactive session
# Then try commands manually and show the constraints in real-time

Enter-PSSession -ComputerName localhost -ConfigurationName DEMO

# Once inside the JEA session, try these commands:
# Get-Command
# Get-Service
# Get-Process
# Stop-Service -Name Spooler -WhatIf
# Stop-Service -Name InvalidService -WhatIf
# Get-ChildItem C:\
# $test = "value"
# Exit-PSSession


# ============================================================================
# BONUS: Check the transcript logs
# ============================================================================

Get-ChildItem C:\ProgramData\JEAConfiguration\Transcripts -Recurse | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 5 FullName, LastWriteTime


# View the most recent transcript
$latestTranscript = Get-ChildItem C:\ProgramData\JEAConfiguration\Transcripts -Recurse | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

Get-Content $latestTranscript.FullName
