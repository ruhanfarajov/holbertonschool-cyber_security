<#
.SYNOPSIS
    BITS Job Detection Script
.DESCRIPTION
    Scans for suspicious BITS jobs that may indicate persistence mechanisms.
.NOTES
    Author: Security Research Lab
    Date: 2026-07-23
#>

function Get-SuspiciousBITSJobs {
    $suspiciousPatterns = @(
        "*update*",
        "*system*", 
        "*windows*",
        "*temp*",
        "*public*"
    )

    $suspiciousExtensions = @(".exe", ".dll", ".ps1", ".bat", ".vbs")

    $allJobs = Get-BitsTransfer -AllUsers

    foreach ($job in $allJobs) {
        $isSuspicious = $false
        $reasons = @()

        # Check display name
        foreach ($pattern in $suspiciousPatterns) {
            if ($job.DisplayName -like $pattern) {
                $isSuspicious = $true
                $reasons += "Suspicious name pattern: $pattern"
            }
        }

        # Check destination path
        if ($job.FileList -match "(temp|public|appdata)") {
            $isSuspicious = $true
            $reasons += "Suspicious destination path"
        }

        # Check file extension
        foreach ($ext in $suspiciousExtensions) {
            if ($job.FileList -like "*$ext") {
                $isSuspicious = $true
                $reasons += "Executable file type: $ext"
            }
        }

        if ($isSuspicious) {
            [PSCustomObject]@{
                DisplayName = $job.DisplayName
                JobState = $job.JobState
                FileList = $job.FileList
                Owner = $job.OwnerIdentity
                Reasons = ($reasons -join "; ")
                RiskLevel = "HIGH"
            }
        }
    }
}

# Run detection
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BITS JOB DETECTION SCAN" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$suspicious = Get-SuspiciousBITSJobs
if ($suspicious) {
    Write-Host "[!] SUSPICIOUS BITS JOBS DETECTED!" -ForegroundColor Red
    $suspicious | Format-Table -AutoSize
} else {
    Write-Host "[+] No suspicious BITS jobs found." -ForegroundColor Green
}
