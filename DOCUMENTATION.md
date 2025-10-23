# Windows Session Manager - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [System Requirements](#system-requirements)
4. [Installation](#installation)
5. [Usage](#usage)
6. [Technical Details](#technical-details)
7. [Troubleshooting](#troubleshooting)
8. [FAQ](#faq)
9. [Known Limitations](#known-limitations)
10. [Version History](#version-history)

---

## Overview

**SessionManager.ps1** is a comprehensive PowerShell script that captures and restores your complete Windows workspace including:
- All running applications with their window positions and sizes
- Windows Terminal sessions with multiple tabs and working directories
- PowerShell, CMD, and WSL terminal sessions
- VSCode workspaces
- Open File Explorer windows
- Shell command history (PowerShell, CMD, WSL bash)

The script allows you to save your entire workspace before a reboot or shutdown, and restore everything exactly as it was after you log back in.

---

## Features

### ✅ Application Management
- **Captures all running applications** with visible windows
- **Saves window positions and sizes** for accurate restoration
- **Preserves working directories** for applications that support it
- **Handles multi-monitor setups**

### ✅ Terminal Session Restoration
- **Windows Terminal**: Captures all windows with multiple tabs, shell types, and working directories
- **PowerShell**: Standalone PowerShell 5.1 and PowerShell Core 7+ windows
- **Command Prompt**: Standalone CMD windows
- **WSL**: Ubuntu, Debian, and Kali Linux sessions

### ✅ Shell History Preservation
- **PowerShell 5.1 history**: Last 1000 commands
- **PowerShell Core history**: Last 1000 commands
- **CMD macros**: Doskey macros and aliases
- **WSL bash history**: Complete bash history for all distributions

### ✅ Development Tools
- **VSCode workspace restoration**: Automatically reopens all workspace folders
- **Browser sessions**: Chrome/Edge restore their own tabs (built-in feature)

### ✅ File Explorer
- **Captures all open Explorer windows** with their folder paths
- **Restores folder views** in the same locations

### ✅ Safety Features
- **Dragon Dictation detection**: Warns before saving if Dragon is running
- **Verbose progress tracking**: Shows exactly what's happening with timestamps
- **Error handling**: Graceful fallback to minimal save if full save fails
- **File verification**: Confirms successful write after save

### ✅ Scheduling Options
- **Manual save/restore**: Full control over when to save
- **Task Scheduler integration**: Optional automatic save on startup
- **Group Policy support**: Can be deployed organization-wide

---

## System Requirements

### Operating System
- **Windows 10** (version 1809 or later) or **Windows 11**
- **PowerShell 5.1** or later (comes with Windows)
- **PowerShell Core 7+** (optional, for enhanced features)

### Permissions
- **User permissions** for normal save/restore operations
- **Administrator permissions** for Task Scheduler installation

### Optional Components
- **Windows Terminal** (for terminal session restoration)
- **VSCode** with `code` command in PATH (for workspace restoration)
- **WSL** (for bash history backup/restore)

### Disk Space
- **Minimal**: ~50 KB for session file
- **Typical**: ~500 KB - 2 MB depending on open applications
- **History backup**: ~1-5 MB for shell history files

---

## Installation

### Quick Install

1. **Download the script:**
```powershell
   # Save SessionManager.ps1 to a permanent location
   # Recommended: C:\Scripts\SessionManager.ps1
```

2. **Set execution policy** (if needed):
```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

3. **Test the script:**
```powershell
   .\SessionManager.ps1 -Action Save
```

### Recommended Setup

#### 1. Create Scripts Folder
```powershell
# Create a dedicated scripts folder
New-Item -ItemType Directory -Path "C:\Scripts" -Force

# Move the script there
Move-Item .\SessionManager.ps1 C:\Scripts\
```

#### 2. Add to Startup (Auto-Restore)
```powershell
# Create startup shortcut for automatic restore on login
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\RestoreSession.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"C:\Scripts\SessionManager.ps1`" -Action Restore"
$Shortcut.Save()
```

#### 3. Create Desktop Shortcuts

**Save Session Shortcut:**
```powershell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Save Session.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"C:\Scripts\SessionManager.ps1`" -Action Save"
$Shortcut.IconLocation = "shell32.dll,259"
$Shortcut.Save()
```

**Restore Session Shortcut:**
```powershell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Restore Session.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"C:\Scripts\SessionManager.ps1`" -Action Restore"
$Shortcut.IconLocation = "shell32.dll,260"
$Shortcut.Save()
```

---

## Usage

### Basic Commands

#### Save Current Session
```powershell
.\SessionManager.ps1 -Action Save
```

**Output:**
```
=======================================
  Saving Current Session
=======================================
[16:22:38.123] Session save started
[16:22:38.456] Loading Windows API functions...
[16:22:39.789] Backing up shell command history...
  [+] Backed up PowerShell 5.1 history (487 commands)
  [+] Backed up PowerShell Core history (1000 commands)
[16:22:40.012] Found 45 processes with visible windows
[16:22:42.345] Writing JSON to file...
[16:22:42.678] JSON file written successfully (523.45 KB)

[+] Session saved to: C:\Users\YourName\.session_restore.json
  * Applications: 45
  * Explorer windows: 3
  * VSCode workspaces: 2
  * Terminal sessions: 5
    - Windows Terminal: 2 windows, 6 tabs
    - PowerShell: 1 windows
  * Shell history: 1487 commands backed up

  Time taken: 4.23 seconds
=======================================
```

#### Restore Saved Session
```powershell
.\SessionManager.ps1 -Action Restore
```

**Output:**
```
=======================================
  Restoring Session
=======================================
[16:25:10.123] Session restore started
[16:25:10.456] Reading session file...
Session from: 2025-01-15 16:22:42

Restoring shell command history...
  [+] Restored PowerShell 5.1 history (487 commands)
  [+] Restored PowerShell Core history (1000 commands)

Restoring 45 applications...

Restoring Windows Terminal sessions...
  -> Opening Windows Terminal with 3 tab(s)
    * PowerShell Core: C:\Projects\MyApp
    * Windows PowerShell: C:\Users\YourName
    * WSL Ubuntu

Restoring other applications...
  -> Launching: Chrome
  -> Launching: Code
  -> Launching: Notepad

Restoring Explorer windows...
  -> Opening folder: C:\Projects
  -> Opening folder: C:\Documents

Restoring window positions...
  [+] Positioned: Chrome
  [+] Positioned: Code

=======================================
  Session Restore Complete!
  Time taken: 12.67 seconds
=======================================
```

#### Install Task Scheduler (Optional)
```powershell
# Run as Administrator
.\SessionManager.ps1 -Action InstallScheduler
```

**What this does:**
- Creates a scheduled task named "AutoSaveSessionBeforeReboot"
- Triggers at system startup (not shutdown - Windows limitation)
- Runs hidden in background
- Does NOT save automatically - you still need to save manually before shutdown

#### Uninstall Task Scheduler
```powershell
# Run as Administrator
.\SessionManager.ps1 -Action UninstallScheduler
```

### Advanced Usage

#### Verbose Mode
```powershell
# Show detailed progress with timestamps
.\SessionManager.ps1 -Action Save -Verbose
```

#### Pre-Shutdown Workflow
```powershell
# 1. Save session
.\SessionManager.ps1 -Action Save

# 2. Wait for confirmation (should show "Session save completed successfully")

# 3. Shutdown or reboot
shutdown /r /t 0
# or
shutdown /s /t 0
```

#### Safe Reboot Script
Create `SafeReboot.ps1`:
```powershell
param(
    [ValidateSet('Reboot','Shutdown')]
    [string]$Action = 'Reboot'
)

$SessionManagerPath = "C:\Scripts\SessionManager.ps1"

Write-Host "Saving current session..." -ForegroundColor Cyan
& $SessionManagerPath -Action Save

# Wait for file to be written
Start-Sleep -Seconds 3

# Verify file exists and is recent
$sessionFile = "$env:USERPROFILE\.session_restore.json"
if (Test-Path $sessionFile) {
    $fileAge = (Get-Date) - (Get-Item $sessionFile).LastWriteTime
    if ($fileAge.TotalSeconds -lt 30) {
        Write-Host "Session saved successfully!" -ForegroundColor Green
        Start-Sleep -Seconds 2

        if ($Action -eq 'Reboot') {
            shutdown /r /t 0
        } else {
            shutdown /s /t 0
        }
    } else {
        Write-Host "ERROR: Session file is too old. Please try again." -ForegroundColor Red
    }
} else {
    Write-Host "ERROR: Session file not found. Please try again." -ForegroundColor Red
}
```

---

## Technical Details

### File Locations

#### Session Data
```
C:\Users\<YourName>\.session_restore.json
```
Contains:
- Application list with paths, window positions, command lines
- Terminal sessions with tabs and working directories
- Explorer window paths
- VSCode workspace paths
- Timestamp of save

#### Shell History Backups
```
C:\Users\<YourName>\.session_history_backup\
├── ps51_history.txt              # PowerShell 5.1 history
├── pscore_history.txt            # PowerShell Core history
├── cmd_macros.txt                # CMD doskey macros
├── Ubuntu_bash_history.txt       # WSL Ubuntu bash history
├── Debian_bash_history.txt       # WSL Debian bash history
└── kali-linux_bash_history.txt   # WSL Kali bash history
```

### Data Structure

The session JSON file structure:
```json
{
  "Timestamp": "2025-01-15 16:22:42",
  "Applications": [
    {
      "ProcessName": "chrome",
      "ProcessId": 12345,
      "Path": "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
      "WindowTitle": "GitHub - Mozilla Firefox",
      "CommandLine": "\"C:\\Program Files\\...\\chrome.exe\"",
      "WorkingDirectory": "C:\\Program Files\\Google\\Chrome\\Application",
      "WindowPosition": {
        "Left": 100,
        "Top": 100,
        "Width": 1920,
        "Height": 1080
      },
      "MainWindowHandle": 123456789
    }
  ],
  "OpenFolders": [
    "C:\\Projects",
    "C:\\Documents"
  ],
  "VSCodeWorkspaces": [
    "C:\\Projects\\MyApp",
    "C:\\Work\\ClientProject"
  ],
  "TerminalSessions": {
    "WindowsTerminal": [
      {
        "ProcessId": 54321,
        "CommandLine": "...",
        "Tabs": [
          {
            "ShellType": "PowerShell Core",
            "ProcessName": "pwsh.exe",
            "WorkingDirectory": "C:\\Projects\\MyApp"
          }
        ]
      }
    ],
    "PowerShell": [],
    "CMD": []
  },
  "ShellHistory": {
    "Timestamp": "2025-01-15 16:22:42",
    "PowerShellHistory": ["command1", "command2", "..."],
    "PowerShellCoreHistory": ["command1", "command2", "..."],
    "CMDHistory": ["macro1=command1", "macro2=command2"]
  }
}
```

### How It Works

#### Save Process
1. **Check for Dragon Dictation** - Warns if running
2. **Backup shell history** - Copies history files to backup folder
3. **Enumerate applications** - Uses Windows API to get all windows with their positions
4. **Capture terminal sessions** - Identifies Windows Terminal, PowerShell, CMD processes and their child shells
5. **Get VSCode workspaces** - Parses command lines of running VSCode instances
6. **Enumerate Explorer windows** - Uses COM automation to get folder paths
7. **Convert to JSON** - Serializes all data to JSON format
8. **Write to disk** - Saves JSON file with UTF-8 encoding
9. **Verify** - Confirms file was written successfully

#### Restore Process
1. **Read session file** - Loads JSON data
2. **Restore shell history** - Merges backed-up history with current history
3. **Launch VSCode** - Opens workspace folders
4. **Restore terminals** - Launches Windows Terminal with correct tabs and working directories
5. **Launch applications** - Starts each application with preserved working directory
6. **Open Explorer windows** - Opens folder windows
7. **Position windows** - Uses Windows API to restore window sizes and positions
8. **Verify** - Reports success/failure for each component

### Windows API Functions Used

The script uses P/Invoke to call these Windows API functions:
```csharp
// Get window visibility
[DllImport("user32.dll")]
public static extern bool IsWindowVisible(IntPtr hWnd);

// Get window title
[DllImport("user32.dll")]
public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);

// Get active window
[DllImport("user32.dll")]
public static extern IntPtr GetForegroundWindow();

// Get window rectangle (position and size)
[DllImport("user32.dll")]
public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

// Set window position and size
[DllImport("user32.dll")]
public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter,
    int X, int Y, int cx, int cy, uint uFlags);

// Show/hide window
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
```

### Multi-User Behavior

**Important**: The script only saves/restores sessions for the **current user** running the script.

- Sessions are stored in `%USERPROFILE%` (user-specific folder)
- Only processes visible to the current user are captured
- Shell history is user-specific
- Cannot access other logged-in users' sessions

For multi-user systems:
- Each user must run their own save/restore
- Deploy script to all user startup folders
- Use Group Policy for organization-wide deployment

---

## Troubleshooting

### Common Issues

#### Issue: "Execution Policy" Error
```
.\SessionManager.ps1 : File cannot be loaded because running scripts is disabled
```

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

#### Issue: Script Gets Stuck at "Writing JSON"
```
[16:22:39.212] Writing session data to JSON file...
[script hangs here]
```

**Causes:**
- Too many applications open (100+)
- Very long command line strings
- Circular references in data

**Solutions:**

1. **Press Ctrl+C** to stop the script

2. **Check how many apps are running:**
```powershell
   (Get-Process | Where-Object {$_.MainWindowHandle -ne 0}).Count
```

3. **Close unnecessary applications** and try again

4. **Check if file was created:**
```powershell
   Get-Item $env:USERPROFILE\.session_restore.json
```

5. **Try minimal save** - the script automatically falls back to minimal save on error

6. **Update script** - The latest version includes better error handling

---

#### Issue: Windows Terminal Tabs Not Restoring Correctly
```
-> Opening Windows Terminal with 3 tab(s)
[Only 1 tab opens]
```

**Causes:**
- Working directory doesn't exist
- Profile not found in Windows Terminal settings
- Permissions issue

**Solutions:**

1. **Verify Windows Terminal is in PATH:**
```powershell
   Get-Command wt.exe
```

2. **Check saved session data:**
```powershell
   $session = Get-Content $env:USERPROFILE\.session_restore.json | ConvertFrom-Json
   $session.TerminalSessions.WindowsTerminal[0].Tabs | Format-Table
```

3. **Manually test Windows Terminal command:**
```powershell
   wt.exe -p "PowerShell Core" -d "C:\Projects" ; new-tab -p "cmd.exe"
```

---

#### Issue: Applications Launch But Windows Are Not Positioned
```
[+] Positioned: Chrome
[!] Window not ready for Code
```

**Cause:**
- Application takes longer to create window than expected
- Application opens minimized or hidden

**Solutions:**

1. **Increase wait time** - Edit the script and change:
```powershell
   Start-Sleep -Seconds 3  # Change to 5 or 10
```

2. **Run restore again** - Window positioning can be re-run without relaunching apps

3. **Position manually** - Some apps don't support programmatic positioning

---

#### Issue: PowerShell History Not Restoring
```
[!] No history backup found
```

**Causes:**
- History backup folder doesn't exist
- No history was saved during last session save
- History files are corrupted

**Solutions:**

1. **Check if backup folder exists:**
```powershell
   Test-Path "$env:USERPROFILE\.session_history_backup"
```

2. **List backup files:**
```powershell
   Get-ChildItem "$env:USERPROFILE\.session_history_backup"
```

3. **Verify PowerShell history location:**
```powershell
   # PowerShell 5.1
   Test-Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

   # PowerShell Core
   Test-Path "$env:APPDATA\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt"
```

4. **Run save again** to create fresh backup

---

#### Issue: Dragon Dictation Warning Appears
```
[!] WARNING: Dragon Dictation is running!
Dragon may lose unsaved voice data if force-closed!
```

**Cause:**
- Dragon NaturallySpeaking is running
- Script detects it to prevent data loss

**Solutions:**

1. **Close Dragon manually** (Recommended):
   - File → Exit Dragon
   - Wait for it to fully close
   - Re-run the script

2. **Continue anyway** (Not recommended):
   - Type `yes` when prompted
   - Script will save but Dragon data may be lost

3. **Disable Dragon detection** (Advanced):
   - Edit script and comment out the `Test-DragonRunning` call

---

#### Issue: "Administrator Privileges Required" for Task Scheduler
```
[X] Error: Administrator privileges required!
```

**Solution:**
```powershell
# Right-click PowerShell and select "Run as Administrator"
# Then run:
.\SessionManager.ps1 -Action InstallScheduler
```

---

#### Issue: VSCode Workspaces Not Restoring
```
VSCode not found in PATH
```

**Causes:**
- VSCode not installed
- `code` command not in PATH

**Solutions:**

1. **Check if VSCode is installed:**
```powershell
   Get-Command code -ErrorAction SilentlyContinue
```

2. **Add VSCode to PATH:**
   - Open VSCode
   - Press `Ctrl+Shift+P`
   - Type "Shell Command: Install 'code' command in PATH"
   - Restart PowerShell

3. **Manual restore:**
   - Open saved session JSON
   - Find VSCode workspace paths
   - Open them manually: `code "C:\Projects\MyApp"`

---

#### Issue: Session File is Corrupted
```
ConvertFrom-Json : Invalid JSON primitive
```

**Causes:**
- Script was interrupted during save
- Disk write error
- PowerShell crash during save

**Solutions:**

1. **Delete corrupted file:**
```powershell
   Remove-Item $env:USERPROFILE\.session_restore.json -Force
```

2. **Run save again:**
```powershell
   .\SessionManager.ps1 -Action Save
```

3. **Check disk space:**
```powershell
   Get-PSDrive C | Select-Object Used, Free
```

---

### Debugging Tips

#### Enable Extra Verbose Output
```powershell
$VerbosePreference = 'Continue'
.\SessionManager.ps1 -Action Save -Verbose
```

#### Check What's Running
```powershell
# See all windows
Get-Process | Where-Object {$_.MainWindowHandle -ne 0} | Format-Table ProcessName, Id, MainWindowTitle

# See Windows Terminal processes
Get-Process -Name WindowsTerminal | Format-Table Id, ProcessName, StartTime
```

#### Examine Saved Session
```powershell
# Read session file
$session = Get-Content $env:USERPROFILE\.session_restore.json | ConvertFrom-Json

# Count applications
$session.Applications.Count

# See application names
$session.Applications | Select-Object ProcessName, WindowTitle | Format-Table

# See terminal sessions
$session.TerminalSessions | ConvertTo-Json -Depth 3
```

#### Test Individual Components

**Test Windows Terminal restore:**
```powershell
# Manually test Windows Terminal command
wt.exe -p "PowerShell Core" -d "C:\Projects"
```

**Test application launch:**
```powershell
# Test launching Chrome
Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" -PassThru
```

**Test window positioning:**
```powershell
# Get a window handle
$proc = Get-Process chrome | Select-Object -First 1
$hwnd = $proc.MainWindowHandle

# Move window (requires Windows API from script)
```

---

## FAQ

### General Questions

**Q: Does this work across reboots AND shutdowns?**
A: Yes! The session file persists on disk until overwritten. You can save once and restore multiple times after any reboot or shutdown.

**Q: Will this save my work/documents?**
A: No, it only saves which applications are open and where they are. You must save your documents separately before closing.

**Q: Does this work for all users on my PC?**
A: No, each user must run their own save/restore. The script only captures the current user's session.

**Q: Can I save multiple sessions?**
A: Currently, the script only keeps one session. You could modify it to save with timestamps or create multiple profiles.

### Technical Questions

**Q: Why does it take so long to save?**
A: Saving involves:
- Querying all running processes (can be 100+)
- Getting window positions via Windows API
- Parsing command lines for each process
- Backing up shell history files
- Converting everything to JSON
- Writing large file to disk

Typical save time: 3-10 seconds depending on how much is open.

**Q: What happens if I have 200+ applications open?**
A: The script will still work, but:
- Save will take longer (15-30 seconds)
- JSON file will be larger (5-10 MB)
- Restore will take longer (30-60 seconds)
- Some applications may fail to restore

**Q: Can I use this on a work computer?**
A: Check with your IT department first. Some organizations:
- Block PowerShell execution
- Restrict Task Scheduler access
- Monitor script execution
- Have policies against automation

**Q: Does this work with Remote Desktop?**
A: Partially:
- Local sessions: Full support
- RDP sessions: Limited support (window positions may not restore correctly)
- Multiple RDP sessions: Each session is independent

**Q: Will this restore my Chrome tabs?**
A: Chrome has its own session restore feature. Enable it:
- Settings → On startup → Continue where you left off

The script will launch Chrome, and Chrome will restore its own tabs.

### Safety Questions

**Q: Is it safe to use Ctrl+C to stop the script?**
A: Yes, completely safe. The script handles interruption gracefully. Just run save again to complete.

**Q: Is it safe to close the PowerShell window?**
A: Yes, but Ctrl+C is better. Closing the window is more abrupt but won't cause permanent damage.

**Q: What if the script crashes during save?**
A: The session file might be corrupted, but your applications/windows are unaffected. Just delete the file and save again.

**Q: Can this break my Windows installation?**
A: No. The script only:
- Reads process information
- Writes to user folder (no system files)
- Uses standard Windows APIs
- Cannot modify system settings

**Q: What about Dragon Dictation?**
A: The script detects Dragon and warns you to close it first. Dragon needs to save its own data before closing.

### Performance Questions

**Q: Will this slow down my computer?**
A: Negligibly:
- Save: ~5-10 seconds of CPU usage
- Restore: Minimal, applications launch normally
- Task Scheduler: No impact (only runs on startup)

**Q: How much disk space does it use?**
A: Very little:
- Session file: 500 KB - 2 MB
- History backups: 1-5 MB
- Total: Usually under 10 MB

**Q: Can I run this on a laptop with battery?**
A: Yes, no special considerations needed. The script is lightweight.

### Customization Questions

**Q: Can I exclude certain applications?**
A: Yes, edit the `$skipProcesses` array in the script:
```powershell
$skipProcesses = @("WindowsTerminal", "powershell", "pwsh", "cmd", "Code", "Spotify")
```

**Q: Can I change where files are saved?**
A: Yes, edit these variables at the top of the script:
```powershell
$SessionFile = "D:\MyBackups\.session_restore.json"
$HistoryBackupFolder = "D:\MyBackups\.history"
```

**Q: Can I save to OneDrive/Dropbox?**
A: Yes, just change the file paths to your sync folder:
```powershell
$SessionFile = "$env:OneDrive\.session_restore.json"
```

**Q: Can I run this automatically before shutdown?**
A: Windows doesn't provide a reliable pre-shutdown trigger in Task Scheduler. You must:
- Save manually before shutdown
- Use Group Policy shutdown scripts (advanced)
- Create a custom shutdown script

---

## Known Limitations

### What's NOT Captured

❌ **Unsaved document content** - Only application state, not data
❌ **Browser tab contents** - Use browser's built-in restore
❌ **Application internal state** - Settings, open files within apps
❌ **Split panes in Windows Terminal** - Only tabs are restored
❌ **Virtual desktop layouts** - Windows doesn't provide API
❌ **Maximized/minimized state** - All windows restore as normal
❌ **Command history within active shells** - Only persisted history
❌ **Network drive connections** - May need to reconnect
❌ **Clipboard content** - Not persisted
❌ **Running services** - Only GUI applications

### Platform Limitations

⚠️ **Windows 10/11 only** - Not compatible with Windows 7/8
⚠️ **PowerShell 5.1+ required** - Won't work on older versions
⚠️ **Single user only** - Cannot capture other logged-in users
⚠️ **No WinUI3 support** - Some modern apps may not position correctly
⚠️ **Limited UWP support** - Store apps may not restore properly

### Application-Specific Issues

📝 **Some apps don't support programmatic positioning:**
- Windows Store apps (UWP)
- Some Electron apps
- Fullscreen games
- Virtual machines

📝 **Some apps open with default state:**
- Browsers (use built-in restore)
- Office apps (use AutoRecover)
- Adobe apps (use workspace save)

📝 **Some apps require additional setup:**
- Docker Desktop (must be logged in)
- VPN clients (must reconnect)
- Cloud storage (must be synced)

### Security Considerations

🔒 **Sensitive Information in JSON:**
- Process names are visible
- Window titles may contain filenames
- Command lines may contain paths
- Consider encrypting the JSON file if needed

🔒 **Passwords Not Captured:**
- The script does NOT capture passwords
- Applications must re-authenticate after restore
- Use a password manager for convenience

---

## Version History

### Version 1.0 (Current)
**Release Date:** January 2025

**Features:**
- ✅ Full application capture and restore
- ✅ Windows Terminal multi-tab support
- ✅ Shell history backup (PowerShell, CMD, WSL)
- ✅ VSCode workspace restoration
- ✅ Window position restoration
- ✅ Explorer window restoration
- ✅ Dragon Dictation detection
- ✅ Verbose progress tracking with timestamps
- ✅ Task Scheduler integration
- ✅ Error handling and fallback to minimal save
- ✅ Comprehensive documentation

**Known Issues:**
- Split panes in Windows Terminal not supported
- Some UWP apps don't restore position correctly
- Very large sessions (200+ apps) may be slow

**Future Enhancements:**
- Virtual desktop layout support
- Multiple session profiles
- Encrypted session storage
- GUI interface
- Split pane restoration for Windows Terminal
- Auto-save before shutdown (pending Windows API)

---

## Advanced Topics

### Scripting Examples

#### Automated Daily Save
```powershell
# Add to Task Scheduler to run daily at 6 PM
$trigger = New-ScheduledTaskTrigger -Daily -At 6PM
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"C:\Scripts\SessionManager.ps1`" -Action Save"
Register-ScheduledTask -TaskName "DailySessionSave" -Trigger $trigger -Action $action
```

#### Save Multiple Named Sessions
```powershell
# Modified script to support named sessions
param(
    [string]$SessionName = "default"
)

$SessionFile = "$env:USERPROFILE\.session_restore_$SessionName.json"
# ... rest of script
```

Usage:
```powershell
# Save different profiles
.\SessionManager.ps1 -Action Save -SessionName "work"
.\SessionManager.ps1 -Action Save -SessionName "personal"

# Restore specific profile
.\SessionManager.ps1 -Action Restore -SessionName "work"
```

#### Pre-Shutdown Hook
```powershell
# Create a shutdown script that always saves
$shutdownScript = @"
C:\Scripts\SessionManager.ps1 -Action Save
shutdown /s /t 0
"@

$shutdownScript | Out-File C:\Scripts\SaveAndShutdown.ps1
```

### Group Policy Deployment

For organization-wide deployment:

1. **Create GPO for Logon Script:**
   - Computer Configuration → Policies → Windows Settings → Scripts → Logon
   - Add: `C:\Scripts\SessionManager.ps1 -Action Restore`

2. **Create GPO for Logoff Script:**
   - Computer Configuration → Policies → Windows Settings → Scripts → Logoff
   - Add: `C:\Scripts\SessionManager.ps1 -Action Save`

3. **Deploy Script via File Share:**
   - Place script on network share: `\\domain\netlogon\SessionManager.ps1`
   - Copy to local machine during logon

### Integration with Other Tools

#### PowerShell Profile Integration
Add to `$PROFILE`:
```powershell
# Quick aliases for session management
function Save-MySession {
    & "C:\Scripts\SessionManager.ps1" -Action Save
}

function Restore-MySession {
    & "C:\Scripts\SessionManager.ps1" -Action Restore
}

Set-Alias -Name ssave -Value Save-MySession
Set-Alias -Name srestore -Value Restore-MySession
```

#### Windows Terminal Integration
Add to Windows Terminal settings:
```json
{
    "profiles": {
        "defaults": {
            "startingDirectory": "%USERPROFILE%"
        }
    },
    "actions": [
        {
            "command": {
                "action": "sendInput",
                "input": "C:\\Scripts\\SessionManager.ps1 -Action Save\r"
            },
            "keys": "ctrl+shift+s"
        }
    ]
}
```

---

## Support and Contributing

### Getting Help

**For issues:**
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [Known Limitations](#known-limitations)
3. Enable verbose output: `.\SessionManager.ps1 -Action Save -Verbose`
4. Check PowerShell version: `$PSVersionTable.PSVersion`

**For feature requests:**
- Consider contributing to the script
- Share your use case and requirements

### Contributing

To modify or extend the script:

1. **Understand the structure:**
   - Functions are modular and well-commented
   - Each function handles a specific component
   - Error handling is built-in

2. **Test thoroughly:**
   - Test with various applications
   - Test on clean Windows install
   - Test error scenarios

3. **Follow conventions:**
   - Use `Write-Progress-Step` for logging
   - Add try-catch blocks for error handling
   - Document parameters and functions

### Best Practices

**Before Saving:**
- Close applications you don't want restored
- Close Dragon Dictation
- Save all your work
- Close minimized applications

**Before Restoring:**
- Close conflicting applications
- Ensure working directories exist
- Check available memory
- Have patience - restore takes time

**Regular Maintenance:**
- Clean up old history backups
- Review session file periodically
- Update script when Windows updates
- Test restore occasionally

---

## Credits and License

**Created by:** AI Assistant (Claude) in collaboration with user
**Version:** 1.0
**Last Updated:** January 2025
**License:** Free to use and modify

**Acknowledgments:**
- PowerShell community for API examples
- Windows Terminal team for command-line documentation
- Microsoft for Windows API documentation

**Disclaimer:**
This script is provided as-is without warranty. Always backup your data before using automation scripts. Test thoroughly in a non-production environment first.

---

## Appendix

### Command Reference

| Command | Description |
|---------|-------------|
| `.\SessionManager.ps1 -Action Save` | Save current session |
| `.\SessionManager.ps1 -Action Restore` | Restore saved session |
| `.\SessionManager.ps1 -Action InstallScheduler` | Install Task Scheduler task (Admin required) |
| `.\SessionManager.ps1 -Action UninstallScheduler` | Remove Task Scheduler task (Admin required) |
| `.\SessionManager.ps1 -Action Save -Verbose` | Save with detailed output |

### File Path Reference

| Purpose | Path |
|---------|------|
| Session data | `C:\Users\<Name>\.session_restore.json` |
| PS 5.1 history backup | `C:\Users\<Name>\.session_history_backup\ps51_history.txt` |
| PS Core history backup | `C:\Users\<Name>\.session_history_backup\pscore_history.txt` |
| CMD macros backup | `C:\Users\<Name>\.session_history_backup\cmd_macros.txt` |
| WSL bash history | `C:\Users\<Name>\.session_history_backup\<distro>_bash_history.txt` |
| Original PS 5.1 history | `C:\Users\<Name>\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt` |
| Original PS Core history | `C:\Users\<Name>\AppData\Roaming\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt` |

### Error Code Reference

| Message | Meaning | Solution |
|---------|---------|----------|
| `[X] No saved session found` | No session file exists | Run Save first |
| `[X] ERROR writing session file` | JSON conversion failed | Check available disk space, reduce open apps |
| `[X] Administrator privileges required` | Not running as admin | Run PowerShell as Administrator |
| `[!] Windows Terminal not found` | wt.exe not in PATH | Install Windows Terminal or add to PATH |
| `[!] VSCode not found in PATH` | code command not available | Install VSCode or add code to PATH |
| `[!] No history backup found` | History backup folder doesn't exist | Run Save to create backups |
| `[X] Could not restore position` | Window positioning failed | Some apps don't support positioning |

---

**End of Documentation**

For questions, issues, or contributions, please refer to the [Support and Contributing](#support-and-contributing) section.
