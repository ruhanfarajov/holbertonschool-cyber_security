<#
.SYNOPSIS
    BITS Job Enumeration Script
.DESCRIPTION
    Enumerates all BITS jobs with detailed information.
.NOTES
    Author: Security Research Lab
    Date: 2026-07-23
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  BITS JOB ENUMERATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$jobs = Get-BitsTransfer -AllUsers

if (-not $jobs) {
    Write-Host "[+] No BITS jobs found." -ForegroundColor Green
} else {
    foreach ($job in $jobs) {
        Write-Host "Job Name: $($job.DisplayName)" -ForegroundColor Yellow
        Write-Host "  State: $($job.JobState)"
        Write-Host "  Owner: $($job.OwnerIdentity)"
        Write-Host "  Files: $($job.FileList.RemoteName -join ", ")"
        Write-Host "  Destination: $($job.FileList.LocalName -join ", ")"
        Write-Host "  Bytes Transferred: $([math]::Round($job.BytesTransferred / 1MB, 2)) MB"
        Write-Host "  Creation Time: $($job.CreationTime)"
        Write-Host "  ---" -ForegroundColor DarkGray
    }
}
