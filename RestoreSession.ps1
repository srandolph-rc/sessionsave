<#
.SYNOPSIS
    Restore previously saved session

.DESCRIPTION
    This script restores your Windows session that was saved using SaveAndShutdown.ps1
    or SaveAndReboot.ps1. It will launch all your applications, position windows,
    and restore terminal sessions.

.EXAMPLE
    .\RestoreSession.ps1
    Restores your saved session

.NOTES
    Run this after a fresh boot to restore your workspace
#>

[CmdletBinding()]
param()

$ScriptRoot = Split-Path -Parent $PSCommandPath
$SessionManagerPath = Join-Path $ScriptRoot "SessionManager.ps1"
$SessionFile = "$env:USERPROFILE\.session_restore.json"

# Check if SessionManager exists
if (-not (Test-Path $SessionManagerPath)) {
    Write-Host "[X] ERROR: SessionManager.ps1 not found at: $SessionManagerPath" -ForegroundColor Red
    exit 1
}

# Check if session file exists
if (-not (Test-Path $SessionFile)) {
    Write-Host ""
    Write-Host "[X] No saved session found!" -ForegroundColor Red
    Write-Host "    Please run SaveAndShutdown.ps1 or SaveAndReboot.ps1 first." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Show session info
$sessionData = Get-Content $SessionFile | ConvertFrom-Json
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  Restore Session" -ForegroundColor White
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Found saved session from: " -NoNewline
Write-Host $sessionData.Timestamp -ForegroundColor Yellow
Write-Host ""

# Ask for confirmation
$response = Read-Host "Restore this session? (yes/no)"

if ($response -ne 'yes') {
    Write-Host ""
    Write-Host "Restore cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Restore the session
& $SessionManagerPath -Action Restore

exit $LASTEXITCODE
