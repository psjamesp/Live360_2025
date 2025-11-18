
function Get-ServiceStatus {
    $service = get-service Spooler
    if ($service.Status -eq "running") {
        Write-Host "The service is running"
    }
    else {
        Start-Service -Name $service.Name
    }
}

Get-ServiceStatus

function get-serviceStatus2 {
    [CmdletBinding()]
    param (
        $serviceName
    )
    $service = get-service $serviceName 
    if ($service.Status -eq "running") {
        Write-Host "The service is running"
    }
    else {
        Start-Service -Name $service.Name
    }
}
get-serviceStatus2 -serviceName Spooler

function Get-servicestatus3 {
    [CmdletBinding(supportsShouldProcess = $true)]
    param (
        $serviceName = "spooler"
    )
    $service = get-service $serviceName 
    if ($service.Status -eq "running") {
        Write-Host "The service $($service.name) is running"
    }
    else {
        Start-Service -Name $service.Name
    }
}

Get-servicestatus3 -serviceName bits

function Get-servicestatus4 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $serviceName
    )
    begin {
        $service = Get-service -name $ServiceName
    }
    
    process {
        if ($service.Status -eq "running") {
            Write-Host "The service $($service.name) is running"
        }
        else {
            Start-Service -Name $service.Name
        }
    }
}
Get-servicestatus4 -servicename bits

function Get-servicestatus5 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            position = 0)]
        $serviceName,
        [Parameter(Mandatory = $true,
            Position = 1)]
        $StatusToCheck
    )
    begin {
        $service = Get-service -name $ServiceName
    }
    
    process {
        if ($service.Status -eq "running") {
            Write-Host "The service $($service.name) is running"
        }
        else {
            Start-Service -Name $service.Name
        }
    }
}
Get-servicestatus5 -servicename bits -StatusToCheck running

function Get-servicestatus6 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]$serviceName,
        [Parameter(Mandatory = $true,
            Position = 1)]
        [string]$StatusToCheck
    )
    begin {
        $service = Get-Service -Name $ServiceName
    }
    
    process {
        if ($service.Status -eq $StatusToCheck) {
            Write-Host "The service $($service.Name) is in state '$($service.Status)'."
        }
        else {
            Write-Host "The service $($service.Name) is NOT in state $StatusToCheck`
             (current: $($service.Status))."
        }
    }
}
Get-servicestatus6 -servicename bits -StatusToCheck running

function Get-servicestatus7 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [string]$serviceName,
        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateSet("Running", "Stopped")]
        [string]$StatusToCheck
    )
    begin {
        $service = Get-Service -Name $ServiceName
    }
    
    process {
        if ($service.Status -eq $StatusToCheck) {
            Write-Host "The service $($service.Name) is in state '$($service.Status)'."
        }
        else {
            Write-Host "The service $($service.Name) is NOT in state $StatusToCheck`
             (current: $($service.Status))."
        }
    }
}
Get-servicestatus7 -servicename bits -StatusToCheck halted

function Get-servicestatus8 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$serviceName,
        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateSet("Running", "Stopped")]
        [string]$StatusToCheck
    )
    begin {
        $service = Get-Service -Name $ServiceName
    }
    
    process {
        foreach ($s in $service) {
            if ($s.Status -eq $StatusToCheck) {
                Write-Host "The service $($s.Name) is in state '$($s.Status)'."
            }
            else {
                Write-Host "The service $($s.Name) is NOT in state $StatusToCheck`
             (current: $($s.Status))."
                set-service -name $s.Name -status $StatusToCheck -Force
            }
        }
    }
}

Get-servicestatus8 -servicename bits -StatusToCheck Running

$servicearray = @("Spooler", "bits")
Get-servicestatus8 -servicename $servicearray -StatusToCheck Running -ErrorAction Stop

function Get-servicestatus10 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string[]]$serviceName,
        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateSet("Running", "Stopped")]
        [string]$StatusToCheck
    )
    begin {
        $service = @()
        try {
            $service = Get-Service -Name $ServiceName -ErrorAction Stop
        }
        catch {
            Write-Error "Service $serviceName not found. Please check the service name and try again."
            (get-date -format yyyy-MM-dd-hh:mm) + $error[0] | out-file .\error.txt -Append
        }
    }
    
    process {
        foreach ($s in $service) {
            if ($s.Status -eq $StatusToCheck) {
                Write-Host "The service $($s.Name) is in state '$($s.Status)'."
            }
            else {
                Write-Host "The service $($s.Name) is NOT in state $StatusToCheck`
             (current: $($s.Status))."
                set-service -name $s.Name -status $StatusToCheck -Force
            }
        }
    }
}

Get-servicestatus10 -servicename bits, spooler, asdf -StatusToCheck Running


