<#
.SYNOPSIS
    Save current session and reboot the computer

.DESCRIPTION
    This script saves your current Windows session using SessionManager.ps1
    and then initiates a complete reboot. On next boot, you'll have a
    fresh system and can manually restore your workspace when ready.

.PARAMETER Force
    Skip confirmation prompt and reboot immediately after saving

.PARAMETER Delay
    Seconds to wait after saving before rebooting (default: 5)

.EXAMPLE
    .\SaveAndReboot.ps1
    Saves session and prompts before reboot

.EXAMPLE
    .\SaveAndReboot.ps1 -Force
    Saves session and reboots immediately

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
Write-Host "  Save & Reboot" -ForegroundColor White
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Save the session
Write-Host "Step 1: Saving your session..." -ForegroundColor Yellow
Write-Host ""

& $SessionManagerPath -Action Save

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[X] Session save failed. Aborting reboot." -ForegroundColor Red
    exit 1
}

# Verify session file was created
$SessionFile = "$env:USERPROFILE\.session_restore.json"
if (-not (Test-Path $SessionFile)) {
    Write-Host ""
    Write-Host "[X] Session file not found. Aborting reboot." -ForegroundColor Red
    exit 1
}

# Check file age (should be less than 1 minute old)
$fileAge = (Get-Date) - (Get-Item $SessionFile).LastWriteTime
if ($fileAge.TotalSeconds -gt 60) {
    Write-Host ""
    Write-Host "[!] WARNING: Session file seems old ($([math]::Round($fileAge.TotalSeconds)) seconds)" -ForegroundColor Yellow
    Write-Host "This may not be your current session!" -ForegroundColor Yellow

    if (-not $Force) {
        $response = Read-Host "Continue with reboot anyway? (yes/no)"
        if ($response -ne 'yes') {
            Write-Host "Reboot cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
}

Write-Host ""
Write-Host "[+] Session saved successfully!" -ForegroundColor Green
Write-Host ""

# Confirm reboot
if (-not $Force) {
    Write-Host "Step 2: Ready to reboot" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Your session has been saved. The computer will now reboot." -ForegroundColor White
    Write-Host "After reboot, run RestoreSession.ps1 to restore your workspace." -ForegroundColor White
    Write-Host ""

    $response = Read-Host "Reboot now? (yes/no)"

    if ($response -ne 'yes') {
        Write-Host ""
        Write-Host "Reboot cancelled. Session is still saved." -ForegroundColor Yellow
        exit 0
    }
}

# Wait before reboot
Write-Host ""
Write-Host "Rebooting in $Delay seconds..." -ForegroundColor Cyan
Write-Host "(Press Ctrl+C to cancel)" -ForegroundColor Gray
Start-Sleep -Seconds $Delay

# Reboot
Write-Host ""
Write-Host "Initiating reboot..." -ForegroundColor Red
shutdown /r /t 0
