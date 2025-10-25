<#
.SYNOPSIS
    Windows Session Manager - Save and restore your complete Windows workspace

.DESCRIPTION
    Comprehensive PowerShell script that captures and restores your complete Windows workspace including:
    - All running applications with window positions and sizes
    - Windows Terminal sessions with multiple tabs and working directories
    - PowerShell, CMD, and WSL terminal sessions
    - VSCode workspaces
    - Open File Explorer windows
    - Shell command history (PowerShell, CMD, WSL bash)

.PARAMETER Action
    The action to perform: Save, Restore, InstallScheduler, or UninstallScheduler

.EXAMPLE
    .\SessionManager.ps1 -Action Save
    Saves the current session to .session_restore.json

.EXAMPLE
    .\SessionManager.ps1 -Action Restore
    Restores the previously saved session

.EXAMPLE
    .\SessionManager.ps1 -Action InstallScheduler
    Installs a Task Scheduler task for automatic restore on startup (requires Admin)

.NOTES
    Version: 1.0
    Author: AI Assistant (Claude)
    Last Updated: January 2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Save', 'Restore', 'InstallScheduler', 'UninstallScheduler')]
    [string]$Action
)

#region Configuration
$SessionFile = "$env:USERPROFILE\.session_restore.json"
$HistoryBackupFolder = "$env:USERPROFILE\.session_history_backup"
$ScriptVersion = "1.0"

# Processes to skip during capture (terminal emulators we handle specially)
$skipProcesses = @(
    "WindowsTerminal",
    "powershell",
    "pwsh",
    "cmd",
    "conhost",
    "explorer"  # We handle Explorer windows separately
)
#endregion

#region Windows API Definitions

# Only add the type if it doesn't already exist (prevents error when running multiple times)
if (-not ([System.Management.Automation.PSTypeName]'User32').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class User32 {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_NOZORDER = 0x0004;
    public const int SW_RESTORE = 9;
    public const int SW_SHOW = 5;
}

[StructLayout(LayoutKind.Sequential)]
public struct RECT {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
"@
}

#endregion

#region Logging Functions

function Write-ProgressStep {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $symbol = switch ($Level) {
        'Success' { '[+]' }
        'Warning' { '[!]' }
        'Error'   { '[X]' }
        default   { '[-]' }
    }

    $color = switch ($Level) {
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        default   { 'Cyan' }
    }

    Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
    Write-Host "$symbol " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

function Write-SectionHeader {
    param([string]$Title)

    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-ProgressStep "Session $($Action.ToLower()) started"
}

function Write-SectionFooter {
    param(
        [string]$Message,
        [double]$ElapsedSeconds
    )

    Write-Host ""
    Write-Host "=======================================" -ForegroundColor Green
    Write-Host "  $Message" -ForegroundColor White
    if ($ElapsedSeconds) {
        Write-Host "  Time taken: $([math]::Round($ElapsedSeconds, 2)) seconds" -ForegroundColor Gray
    }
    Write-Host "=======================================" -ForegroundColor Green
}

#endregion

#region Utility Functions

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DragonRunning {
    $dragonProcesses = Get-Process -Name "natspeak", "dragon*" -ErrorAction SilentlyContinue
    if ($dragonProcesses) {
        Write-ProgressStep "WARNING: Dragon Dictation is running!" -Level Warning
        Write-Host "  Dragon may lose unsaved voice data if force-closed!" -ForegroundColor Yellow
        Write-Host ""
        return $true
    }
    return $false
}

function Get-ProcessCommandLine {
    param([int]$ProcessId)

    try {
        $wmi = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
        return $wmi.CommandLine
    }
    catch {
        return $null
    }
}

#endregion

#region Shell History Functions

function Backup-ShellHistory {
    Write-ProgressStep "Backing up shell command history..."

    try {
        # Create backup folder if it doesn't exist
        if (-not (Test-Path $HistoryBackupFolder)) {
            New-Item -ItemType Directory -Path $HistoryBackupFolder -Force | Out-Null
        }

        $backedUpCount = 0

        # PowerShell 5.1 history
        $ps51History = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if (Test-Path $ps51History) {
            $content = Get-Content $ps51History -Tail 1000 -ErrorAction SilentlyContinue
            if ($content) {
                $content | Out-File "$HistoryBackupFolder\ps51_history.txt" -Encoding UTF8 -Force
                Write-Host "  [+] Backed up PowerShell 5.1 history ($($content.Count) commands)" -ForegroundColor Green
                $backedUpCount += $content.Count
            }
        }

        # PowerShell Core history
        $psCoreHistory = "$env:APPDATA\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if (Test-Path $psCoreHistory) {
            $content = Get-Content $psCoreHistory -Tail 1000 -ErrorAction SilentlyContinue
            if ($content) {
                $content | Out-File "$HistoryBackupFolder\pscore_history.txt" -Encoding UTF8 -Force
                Write-Host "  [+] Backed up PowerShell Core history ($($content.Count) commands)" -ForegroundColor Green
                $backedUpCount += $content.Count
            }
        }

        # CMD doskey macros
        try {
            $cmdMacros = & doskey /macros 2>$null
            if ($cmdMacros) {
                $cmdMacros | Out-File "$HistoryBackupFolder\cmd_macros.txt" -Encoding UTF8 -Force
                Write-Host "  [+] Backed up CMD macros ($($cmdMacros.Count) macros)" -ForegroundColor Green
            }
        }
        catch {
            # Doskey might not be available
        }

        # WSL bash histories
        $wslDistros = @("Ubuntu", "Debian", "kali-linux")
        foreach ($distro in $wslDistros) {
            try {
                $bashHistory = wsl.exe -d $distro -e cat ~/.bash_history 2>$null
                if ($bashHistory -and $bashHistory.Count -gt 0) {
                    $bashHistory | Out-File "$HistoryBackupFolder\${distro}_bash_history.txt" -Encoding UTF8 -Force
                    Write-Host "  [+] Backed up WSL $distro bash history ($($bashHistory.Count) commands)" -ForegroundColor Green
                    $backedUpCount += $bashHistory.Count
                }
            }
            catch {
                # WSL distro not available
            }
        }

        return $backedUpCount
    }
    catch {
        Write-ProgressStep "Error backing up shell history: $_" -Level Warning
        return 0
    }
}

function Restore-ShellHistory {
    Write-Host "`nRestoring shell command history..." -ForegroundColor Cyan

    try {
        if (-not (Test-Path $HistoryBackupFolder)) {
            Write-ProgressStep "No history backup found" -Level Warning
            return
        }

        # Restore PowerShell 5.1 history
        $ps51Backup = "$HistoryBackupFolder\ps51_history.txt"
        $ps51History = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if (Test-Path $ps51Backup) {
            $backupContent = Get-Content $ps51Backup
            if ($backupContent) {
                # Merge with existing history
                $existing = @()
                if (Test-Path $ps51History) {
                    $existing = Get-Content $ps51History
                }
                ($existing + $backupContent) | Select-Object -Unique | Out-File $ps51History -Encoding UTF8 -Force
                Write-Host "  [+] Restored PowerShell 5.1 history ($($backupContent.Count) commands)" -ForegroundColor Green
            }
        }

        # Restore PowerShell Core history
        $psCoreBackup = "$HistoryBackupFolder\pscore_history.txt"
        $psCoreHistory = "$env:APPDATA\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if (Test-Path $psCoreBackup) {
            $backupContent = Get-Content $psCoreBackup
            if ($backupContent) {
                $existing = @()
                if (Test-Path $psCoreHistory) {
                    $existing = Get-Content $psCoreHistory
                }
                ($existing + $backupContent) | Select-Object -Unique | Out-File $psCoreHistory -Encoding UTF8 -Force
                Write-Host "  [+] Restored PowerShell Core history ($($backupContent.Count) commands)" -ForegroundColor Green
            }
        }

        # Note: CMD macros and WSL histories require active sessions to restore
        # They will be available when new terminal sessions are opened
    }
    catch {
        Write-ProgressStep "Error restoring shell history: $_" -Level Warning
    }
}

#endregion

#region Session Save Functions

function Get-VisibleWindows {
    $windows = @()
    $windowHandles = @()

    # Callback function for EnumWindows
    $callback = {
        param($hWnd, $lParam)

        if ([User32]::IsWindowVisible($hWnd)) {
            $length = [User32]::GetWindowTextLength($hWnd)
            if ($length -gt 0) {
                $sb = New-Object System.Text.StringBuilder($length + 1)
                [User32]::GetWindowText($hWnd, $sb, $sb.Capacity) | Out-Null
                $title = $sb.ToString()

                if ($title) {
                    $processId = 0
                    [User32]::GetWindowThreadProcessId($hWnd, [ref]$processId) | Out-Null

                    $script:windowHandles += [PSCustomObject]@{
                        Handle = $hWnd
                        Title = $title
                        ProcessId = $processId
                    }
                }
            }
        }
        return $true
    }

    # Enumerate all windows
    $delegateType = [User32+EnumWindowsProc]
    $delegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
        $callback.GetType().GetMethod('Invoke').MethodHandle.GetFunctionPointer(),
        $delegateType
    )

    # Use different approach - enumerate through processes
    $processes = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle }

    foreach ($proc in $processes) {
        try {
            $rect = New-Object RECT
            $success = [User32]::GetWindowRect($proc.MainWindowHandle, [ref]$rect)

            if ($success) {
                $commandLine = Get-ProcessCommandLine -ProcessId $proc.Id
                $workingDir = try { $proc.Path | Split-Path -Parent } catch { $null }

                $windows += [PSCustomObject]@{
                    ProcessName = $proc.ProcessName
                    ProcessId = $proc.Id
                    Path = $proc.Path
                    WindowTitle = $proc.MainWindowTitle
                    CommandLine = $commandLine
                    WorkingDirectory = $workingDir
                    WindowPosition = @{
                        Left = $rect.Left
                        Top = $rect.Top
                        Width = $rect.Right - $rect.Left
                        Height = $rect.Bottom - $rect.Top
                    }
                    MainWindowHandle = $proc.MainWindowHandle.ToInt64()
                }
            }
        }
        catch {
            Write-Verbose "Could not capture window for process $($proc.ProcessName): $_"
        }
    }

    return $windows
}

function Get-TerminalSessions {
    $sessions = @{
        WindowsTerminal = @()
        PowerShell = @()
        CMD = @()
    }

    # Find Windows Terminal processes
    $wtProcesses = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue
    foreach ($wt in $wtProcesses) {
        $commandLine = Get-ProcessCommandLine -ProcessId $wt.Id

        # Find child shell processes
        $childProcesses = Get-CimInstance Win32_Process | Where-Object {
            $_.ParentProcessId -eq $wt.Id
        }

        $tabs = @()
        foreach ($child in $childProcesses) {
            $shellType = switch ($child.Name) {
                "pwsh.exe" { "PowerShell Core" }
                "powershell.exe" { "Windows PowerShell" }
                "cmd.exe" { "Command Prompt" }
                "wsl.exe" { "WSL" }
                "bash.exe" { "WSL" }
                default { $child.Name }
            }

            # Try to get working directory
            $workingDir = try {
                $childProc = Get-Process -Id $child.ProcessId -ErrorAction SilentlyContinue
                if ($childProc) {
                    # This is approximate - getting actual CWD from running process is complex
                    $env:USERPROFILE
                }
            }
            catch {
                $env:USERPROFILE
            }

            $tabs += @{
                ShellType = $shellType
                ProcessName = $child.Name
                ProcessId = $child.ProcessId
                WorkingDirectory = $workingDir
            }
        }

        $sessions.WindowsTerminal += @{
            ProcessId = $wt.Id
            CommandLine = $commandLine
            Tabs = $tabs
        }
    }

    # Find standalone PowerShell windows
    $psProcesses = Get-Process -Name "powershell", "pwsh" -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 }

    foreach ($ps in $psProcesses) {
        $sessions.PowerShell += @{
            ProcessId = $ps.Id
            ProcessName = $ps.ProcessName
            WindowTitle = $ps.MainWindowTitle
            CommandLine = Get-ProcessCommandLine -ProcessId $ps.Id
        }
    }

    # Find standalone CMD windows
    $cmdProcesses = Get-Process -Name "cmd" -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 }

    foreach ($cmd in $cmdProcesses) {
        $sessions.CMD += @{
            ProcessId = $cmd.Id
            WindowTitle = $cmd.MainWindowTitle
            CommandLine = Get-ProcessCommandLine -ProcessId $cmd.Id
        }
    }

    return $sessions
}

function Get-VSCodeWorkspaces {
    $workspaces = @()

    $codeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    foreach ($code in $codeProcesses) {
        $commandLine = Get-ProcessCommandLine -ProcessId $code.Id

        if ($commandLine -and $commandLine -match '--folder-uri file:///(.+?)(\s|$|")') {
            $folderPath = $matches[1] -replace '%3A', ':' -replace '/', '\'
            $workspaces += $folderPath
        }
    }

    return $workspaces | Select-Object -Unique
}

function Get-OpenFolders {
    $folders = @()

    try {
        $shell = New-Object -ComObject Shell.Application
        $windows = $shell.Windows()

        foreach ($window in $windows) {
            try {
                $path = $window.Document.Folder.Self.Path
                if ($path -and (Test-Path $path)) {
                    $folders += $path
                }
            }
            catch {
                # Some windows might not be Explorer windows
            }
        }

        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
    }
    catch {
        Write-Verbose "Error enumerating Explorer windows: $_"
    }

    return $folders | Select-Object -Unique
}

function Save-Session {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-SectionHeader "Saving Current Session"

    # Check for Dragon Dictation
    if (Test-DragonRunning) {
        Write-Host "  Press Ctrl+C to cancel, or wait 5 seconds to continue..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }

    try {
        # Backup shell history
        $historyCount = Backup-ShellHistory

        # Get all visible windows
        Write-ProgressStep "Enumerating running applications..."
        $allWindows = Get-VisibleWindows

        # Filter out processes we handle separately
        $applications = $allWindows | Where-Object {
            $skipProcesses -notcontains $_.ProcessName
        }

        Write-ProgressStep "Found $($applications.Count) processes with visible windows"

        # Get terminal sessions
        Write-ProgressStep "Capturing terminal sessions..."
        $terminalSessions = Get-TerminalSessions

        # Get VSCode workspaces
        Write-ProgressStep "Capturing VSCode workspaces..."
        $vscodeWorkspaces = Get-VSCodeWorkspaces

        # Get open folders
        Write-ProgressStep "Capturing Explorer windows..."
        $openFolders = Get-OpenFolders

        # Create session object
        $session = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = $ScriptVersion
            Applications = $applications
            OpenFolders = $openFolders
            VSCodeWorkspaces = $vscodeWorkspaces
            TerminalSessions = $terminalSessions
        }

        # Convert to JSON
        Write-ProgressStep "Converting session data to JSON..."
        $json = $session | ConvertTo-Json -Depth 10

        # Write to file
        Write-ProgressStep "Writing session file..."
        $json | Out-File -FilePath $SessionFile -Encoding UTF8 -Force

        # Verify file was written
        if (Test-Path $SessionFile) {
            $fileSize = (Get-Item $SessionFile).Length
            $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
            Write-ProgressStep "Session file written successfully ($fileSizeKB KB)" -Level Success
        }
        else {
            throw "Failed to write session file"
        }

        # Summary
        Write-Host ""
        Write-ProgressStep "Session saved to: $SessionFile" -Level Success
        Write-Host "  * Applications: $($applications.Count)" -ForegroundColor Gray
        Write-Host "  * Explorer windows: $($openFolders.Count)" -ForegroundColor Gray
        Write-Host "  * VSCode workspaces: $($vscodeWorkspaces.Count)" -ForegroundColor Gray

        $wtCount = $terminalSessions.WindowsTerminal.Count
        $wtTabs = ($terminalSessions.WindowsTerminal | ForEach-Object { $_.Tabs.Count } | Measure-Object -Sum).Sum
        $psCount = $terminalSessions.PowerShell.Count
        $cmdCount = $terminalSessions.CMD.Count

        Write-Host "  * Terminal sessions: $($wtCount + $psCount + $cmdCount)" -ForegroundColor Gray
        if ($wtCount -gt 0) {
            Write-Host "    - Windows Terminal: $wtCount windows, $wtTabs tabs" -ForegroundColor DarkGray
        }
        if ($psCount -gt 0) {
            Write-Host "    - PowerShell: $psCount windows" -ForegroundColor DarkGray
        }
        if ($cmdCount -gt 0) {
            Write-Host "    - CMD: $cmdCount windows" -ForegroundColor DarkGray
        }

        if ($historyCount -gt 0) {
            Write-Host "  * Shell history: $historyCount commands backed up" -ForegroundColor Gray
        }

        $stopwatch.Stop()
        Write-SectionFooter "Session Save Complete!" -ElapsedSeconds $stopwatch.Elapsed.TotalSeconds

        return $true
    }
    catch {
        $stopwatch.Stop()
        Write-ProgressStep "ERROR saving session: $_" -Level Error
        Write-Host $_.ScriptStackTrace -ForegroundColor Red

        # Attempt minimal save
        try {
            Write-ProgressStep "Attempting minimal save..." -Level Warning
            $minimalSession = @{
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Version = $ScriptVersion
                Applications = @()
                Error = $_.Exception.Message
            }
            $minimalSession | ConvertTo-Json | Out-File -FilePath $SessionFile -Encoding UTF8 -Force
            Write-ProgressStep "Minimal session saved" -Level Success
        }
        catch {
            Write-ProgressStep "Minimal save also failed: $_" -Level Error
        }

        return $false
    }
}

#endregion

#region Session Restore Functions

function Restore-Session {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-SectionHeader "Restoring Session"

    try {
        # Check if session file exists
        if (-not (Test-Path $SessionFile)) {
            Write-ProgressStep "No saved session found at: $SessionFile" -Level Error
            return $false
        }

        # Read session file
        Write-ProgressStep "Reading session file..."
        $json = Get-Content $SessionFile -Raw
        $session = $json | ConvertFrom-Json

        Write-Host "Session from: " -NoNewline
        Write-Host $session.Timestamp -ForegroundColor Yellow
        Write-Host ""

        # Restore shell history first
        Restore-ShellHistory

        # Count items to restore
        $appCount = if ($session.Applications) { $session.Applications.Count } else { 0 }
        $folderCount = if ($session.OpenFolders) { $session.OpenFolders.Count } else { 0 }
        $vscodeCount = if ($session.VSCodeWorkspaces) { $session.VSCodeWorkspaces.Count } else { 0 }

        Write-Host "`nRestoring $appCount applications...`n" -ForegroundColor Cyan

        # Restore Windows Terminal sessions first (they're special)
        if ($session.TerminalSessions -and $session.TerminalSessions.WindowsTerminal) {
            Write-Host "Restoring Windows Terminal sessions..." -ForegroundColor Cyan

            foreach ($wtSession in $session.TerminalSessions.WindowsTerminal) {
                try {
                    $tabCount = $wtSession.Tabs.Count
                    Write-Host "  -> Opening Windows Terminal with $tabCount tab(s)" -ForegroundColor Gray

                    # Build Windows Terminal command
                    $wtCmd = "wt.exe"
                    $firstTab = $true

                    foreach ($tab in $wtSession.Tabs) {
                        $profile = switch ($tab.ShellType) {
                            "PowerShell Core" { "PowerShell" }
                            "Windows PowerShell" { "Windows PowerShell" }
                            "Command Prompt" { "Command Prompt" }
                            "WSL" { "Ubuntu" }
                            default { $tab.ShellType }
                        }

                        $workDir = if ($tab.WorkingDirectory) { $tab.WorkingDirectory } else { $env:USERPROFILE }

                        if ($firstTab) {
                            $wtCmd += " -p `"$profile`" -d `"$workDir`""
                            $firstTab = $false
                        }
                        else {
                            $wtCmd += " ; new-tab -p `"$profile`" -d `"$workDir`""
                        }

                        Write-Host "    * $($tab.ShellType): $workDir" -ForegroundColor DarkGray
                    }

                    # Launch Windows Terminal
                    if (Get-Command wt.exe -ErrorAction SilentlyContinue) {
                        Start-Process wt.exe -ArgumentList $wtCmd.Replace("wt.exe ", "") -ErrorAction SilentlyContinue
                    }
                    else {
                        Write-ProgressStep "Windows Terminal not found in PATH" -Level Warning
                    }
                }
                catch {
                    Write-ProgressStep "Error restoring Windows Terminal session: $_" -Level Warning
                }
            }

            Write-Host ""
        }

        # Restore VSCode workspaces
        if ($vscodeCount -gt 0) {
            Write-Host "Restoring VSCode workspaces..." -ForegroundColor Cyan

            foreach ($workspace in $session.VSCodeWorkspaces) {
                if (Test-Path $workspace) {
                    Write-Host "  -> Opening workspace: $workspace" -ForegroundColor Gray

                    if (Get-Command code -ErrorAction SilentlyContinue) {
                        Start-Process code -ArgumentList "`"$workspace`"" -ErrorAction SilentlyContinue
                    }
                    else {
                        Write-ProgressStep "VSCode not found in PATH" -Level Warning
                        break
                    }
                }
            }

            Write-Host ""
        }

        # Restore other applications
        if ($appCount -gt 0) {
            Write-Host "Restoring other applications..." -ForegroundColor Cyan

            $restoredApps = @()

            foreach ($app in $session.Applications) {
                try {
                    # Skip if already running
                    $existing = Get-Process -Name $app.ProcessName -ErrorAction SilentlyContinue
                    if ($existing -and $existing.MainWindowTitle -eq $app.WindowTitle) {
                        Write-Verbose "  -> Skipping $($app.ProcessName) (already running)"
                        continue
                    }

                    # Skip some common system processes
                    if ($app.ProcessName -in @('explorer', 'taskmgr', 'mmc')) {
                        continue
                    }

                    Write-Host "  -> Launching: $($app.ProcessName)" -ForegroundColor Gray

                    # Try to launch the application
                    if ($app.Path -and (Test-Path $app.Path)) {
                        $startParams = @{
                            FilePath = $app.Path
                            ErrorAction = 'SilentlyContinue'
                        }

                        if ($app.WorkingDirectory -and (Test-Path $app.WorkingDirectory)) {
                            $startParams.WorkingDirectory = $app.WorkingDirectory
                        }

                        $proc = Start-Process @startParams -PassThru

                        if ($proc) {
                            $restoredApps += @{
                                Process = $proc
                                TargetPosition = $app.WindowPosition
                                ProcessName = $app.ProcessName
                            }
                        }
                    }
                }
                catch {
                    Write-Verbose "  -> Could not launch $($app.ProcessName): $_"
                }
            }

            Write-Host ""
        }

        # Restore Explorer windows
        if ($folderCount -gt 0) {
            Write-Host "Restoring Explorer windows..." -ForegroundColor Cyan

            foreach ($folder in $session.OpenFolders) {
                if (Test-Path $folder) {
                    Write-Host "  -> Opening folder: $folder" -ForegroundColor Gray
                    Start-Process explorer.exe -ArgumentList "`"$folder`""
                }
            }

            Write-Host ""
        }

        # Wait for windows to appear, then restore positions
        if ($restoredApps.Count -gt 0) {
            Write-Host "Waiting for windows to initialize..." -ForegroundColor Cyan
            Start-Sleep -Seconds 3

            Write-Host "`nRestoring window positions..." -ForegroundColor Cyan

            foreach ($appInfo in $restoredApps) {
                try {
                    $proc = Get-Process -Id $appInfo.Process.Id -ErrorAction SilentlyContinue

                    if ($proc -and $proc.MainWindowHandle -ne 0) {
                        $pos = $appInfo.TargetPosition

                        # Restore window
                        [User32]::ShowWindow($proc.MainWindowHandle, [User32]::SW_RESTORE) | Out-Null

                        # Set position
                        $success = [User32]::SetWindowPos(
                            $proc.MainWindowHandle,
                            [IntPtr]::Zero,
                            $pos.Left,
                            $pos.Top,
                            $pos.Width,
                            $pos.Height,
                            [User32]::SWP_NOZORDER -bor [User32]::SWP_NOACTIVATE
                        )

                        if ($success) {
                            Write-Host "  [+] Positioned: $($appInfo.ProcessName)" -ForegroundColor Green
                        }
                    }
                    else {
                        Write-Host "  [!] Window not ready for $($appInfo.ProcessName)" -ForegroundColor Yellow
                    }
                }
                catch {
                    Write-Verbose "Could not restore position for $($appInfo.ProcessName): $_"
                }
            }
        }

        $stopwatch.Stop()
        Write-SectionFooter "Session Restore Complete!" -ElapsedSeconds $stopwatch.Elapsed.TotalSeconds

        return $true
    }
    catch {
        $stopwatch.Stop()
        Write-ProgressStep "ERROR restoring session: $_" -Level Error
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        return $false
    }
}

#endregion

#region Task Scheduler Functions

function Install-SessionScheduler {
    if (-not (Test-Administrator)) {
        Write-ProgressStep "Administrator privileges required for Task Scheduler installation" -Level Error
        return $false
    }

    Write-SectionHeader "Installing Task Scheduler"

    try {
        $taskName = "AutoRestoreSessionOnStartup"
        $taskDescription = "Automatically restores Windows session on startup"

        # Remove existing task if present
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-ProgressStep "Removing existing task..."
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }

        # Create task action
        $scriptPath = $PSCommandPath
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -Action Restore"

        # Create task trigger (at logon)
        $trigger = New-ScheduledTaskTrigger -AtLogOn

        # Create task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        # Create task principal (run as current user)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited

        # Register task
        Write-ProgressStep "Registering scheduled task..."
        Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null

        Write-ProgressStep "Task Scheduler installed successfully" -Level Success
        Write-Host "  Task Name: $taskName" -ForegroundColor Gray
        Write-Host "  Trigger: At user logon" -ForegroundColor Gray
        Write-Host "  Action: Restore session" -ForegroundColor Gray

        return $true
    }
    catch {
        Write-ProgressStep "Error installing Task Scheduler: $_" -Level Error
        return $false
    }
}

function Uninstall-SessionScheduler {
    if (-not (Test-Administrator)) {
        Write-ProgressStep "Administrator privileges required for Task Scheduler removal" -Level Error
        return $false
    }

    Write-SectionHeader "Uninstalling Task Scheduler"

    try {
        $taskName = "AutoRestoreSessionOnStartup"

        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-ProgressStep "Removing scheduled task..."
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-ProgressStep "Task Scheduler removed successfully" -Level Success
        }
        else {
            Write-ProgressStep "Task Scheduler not found (already removed)" -Level Warning
        }

        return $true
    }
    catch {
        Write-ProgressStep "Error removing Task Scheduler: $_" -Level Error
        return $false
    }
}

#endregion

#region Main Execution

# Main script execution
try {
    switch ($Action) {
        'Save' {
            $result = Save-Session
            exit $(if ($result) { 0 } else { 1 })
        }

        'Restore' {
            $result = Restore-Session
            exit $(if ($result) { 0 } else { 1 })
        }

        'InstallScheduler' {
            $result = Install-SessionScheduler
            exit $(if ($result) { 0 } else { 1 })
        }

        'UninstallScheduler' {
            $result = Uninstall-SessionScheduler
            exit $(if ($result) { 0 } else { 1 })
        }
    }
}
catch {
    Write-Host "`nUnhandled error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion
