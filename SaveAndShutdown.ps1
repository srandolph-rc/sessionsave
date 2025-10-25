<#
.SYNOPSIS
    Save current session and shutdown the computer

.DESCRIPTION
    This script saves your current Windows session using SessionManager.ps1
    and then initiates a complete shutdown. On next boot, you'll have a
    fresh system and can restore your workspace.

.PARAMETER Force
    Skip confirmation prompt and shutdown immediately after saving

.PARAMETER Delay
    Seconds to wait after saving before shutting down (default: 5)

.EXAMPLE
    .\SaveAndShutdown.ps1
    Saves session and prompts before shutdown

.EXAMPLE
    .\SaveAndShutdown.ps1 -Force
    Saves session and shuts down immediately

.NOTES
    This gives you a FRESH BOOT (clean RAM) while preserving your workspace
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [int]$Delay = 5
)

$ScriptRoot = Split-Path -Parent $PSCommandPath
$SessionManagerPath = Join-Path $ScriptRoot "SessionManager.ps1"

# Check if SessionManager exists
if (-not (Test-Path $SessionManagerPath)) {
    Write-Host "[X] ERROR: SessionManager.ps1 not found at: $SessionManagerPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  Save & Shutdown" -ForegroundColor White
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Save the session
Write-Host "Step 1: Saving your session..." -ForegroundColor Yellow
Write-Host ""

& $SessionManagerPath -Action Save

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] Session save failed. Aborting shutdown." -ForegroundColor Red
    exit 1
}

# Verify session file was created
$SessionFile = "$env:USERPROFILE\.session_restore.json"
if (-not (Test-Path $SessionFile)) {
    Write-Host ""
    Write-Host "[X] Session file not found. Aborting shutdown." -ForegroundColor Red
    exit 1
}

# Check file age (should be less than 1 minute old)
$fileAge = (Get-Date) - (Get-Item $SessionFile).LastWriteTime
if ($fileAge.TotalSeconds -gt 60) {
    Write-Host ""
    Write-Host "[!] WARNING: Session file seems old ($([math]::Round($fileAge.TotalSeconds)) seconds)" -ForegroundColor Yellow
    Write-Host "This may not be your current session!" -ForegroundColor Yellow

    if (-not $Force) {
        $response = Read-Host "Continue with shutdown anyway? (yes/no)"
        if ($response -ne 'yes') {
            Write-Host "Shutdown cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
}

Write-Host ""
Write-Host "[+] Session saved successfully!" -ForegroundColor Green
Write-Host ""

# Confirm shutdown
if (-not $Force) {
    Write-Host "Step 2: Ready to shutdown" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Your session has been saved. The computer will now shutdown." -ForegroundColor White
    Write-Host "On next boot, your workspace will be automatically restored." -ForegroundColor White
    Write-Host ""

    $response = Read-Host "Shutdown now? (yes/no)"

    if ($response -ne 'yes') {
        Write-Host ""
        Write-Host "Shutdown cancelled. Session is still saved." -ForegroundColor Yellow
        exit 0
    }
}

# Wait before shutdown
Write-Host ""
Write-Host "Shutting down in $Delay seconds..." -ForegroundColor Cyan
Write-Host "(Press Ctrl+C to cancel)" -ForegroundColor Gray
Start-Sleep -Seconds $Delay

# Shutdown
Write-Host ""
Write-Host "Initiating shutdown..." -ForegroundColor Red
shutdown /s /t 0
