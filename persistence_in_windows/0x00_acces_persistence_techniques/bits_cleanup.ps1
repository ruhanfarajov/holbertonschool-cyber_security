<#
.SYNOPSIS
    BITS Job Cleanup Script
.DESCRIPTION
    Removes all non-system BITS jobs.
.NOTES
    Author: Security Research Lab
    Date: 2026-07-23
#>

$systemJobs = @("Windows Update", "Microsoft Defender")
$allJobs = Get-BitsTransfer -AllUsers

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BITS JOB CLEANUP" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($job in $allJobs) {
    if ($job.DisplayName -notin $systemJobs) {
        Write-Host "Removing: $($job.DisplayName)" -ForegroundColor Yellow
        Remove-BitsTransfer -BitsJob $job -Confirm:$false
    }
    else {
        Write-Host "Keeping system job: $($job.DisplayName)" -ForegroundColor Green
    }
}

Write-Host "`n[+] Cleanup complete." -ForegroundColor Green
