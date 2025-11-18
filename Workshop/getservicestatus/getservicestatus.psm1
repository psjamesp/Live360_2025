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