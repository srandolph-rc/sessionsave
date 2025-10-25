# Windows Session Manager

Save your complete Windows workspace, shutdown/reboot for a **fresh clean boot**, then manually restore everything when you're ready.

## Why This is Better Than Hibernate

**Hibernate**: Saves RAM to disk → Preserves everything including memory leaks and system cruft

**This Tool**: Fresh clean boot → Clear RAM → Manual restore of your workspace layout

You get the **best of both worlds**:
- ✅ Fresh system with clean RAM
- ✅ Your workspace layout preserved
- ✅ Control over when to restore

---

## Quick Start

### 1. Save and Shutdown
```powershell
.\SaveAndShutdown.ps1
```

### 2. Save and Reboot
```powershell
.\SaveAndReboot.ps1
```

### 3. Restore Session (after fresh boot)
```powershell
.\RestoreSession.ps1
```

---

## What Gets Saved

✅ **All running applications** with window positions and sizes
✅ **Windows Terminal** sessions with multiple tabs and working directories
✅ **PowerShell, CMD, and WSL** terminal sessions
✅ **VSCode workspaces**
✅ **Open File Explorer** windows
✅ **Shell command history** (PowerShell, CMD, WSL bash)

❌ **Unsaved document content** (save your work first!)
❌ **Browser tabs** (use browser's built-in restore feature)

---

## Typical Workflow

```
Morning:
1. Fresh boot
2. Run: .\RestoreSession.ps1
3. All your apps, terminals, and windows restore
4. Continue working

Evening:
1. Save all your work in apps
2. Run: .\SaveAndShutdown.ps1
3. Computer shuts down
4. RAM cleared, fresh state preserved
```

---

## Manual Usage (Advanced)

If you want more control, use the core script directly:

```powershell
# Save only
.\SessionManager.ps1 -Action Save

# Restore only
.\SessionManager.ps1 -Action Restore

# Then manually shutdown
shutdown /s /t 0  # shutdown
shutdown /r /t 0  # reboot
```

---

## Installation

### First-Time Setup: Unblock the Scripts

If you downloaded these scripts from the internet, Windows will block them by default. You must unblock them first:

```powershell
# Navigate to the folder containing the scripts
cd C:\path\to\sessionsave

# Unblock all PowerShell scripts
Get-ChildItem *.ps1 | Unblock-File

# Or unblock individually
Unblock-File .\SessionManager.ps1
Unblock-File .\SaveAndShutdown.ps1
Unblock-File .\SaveAndReboot.ps1
Unblock-File .\RestoreSession.ps1
```

**Alternative**: Right-click each `.ps1` file → Properties → Check "Unblock" → OK

### Option 1: Keep in One Folder (Recommended)
```powershell
# Create scripts folder
New-Item -ItemType Directory -Path "C:\Scripts\SessionManager" -Force

# Copy all files to that folder
# Then use the scripts from there
```

### Option 2: Create Desktop Shortcuts

**Save & Shutdown Shortcut:**
```powershell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Save & Shutdown.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"C:\Scripts\SessionManager\SaveAndShutdown.ps1`""
$Shortcut.IconLocation = "shell32.dll,27"
$Shortcut.Save()
```

**Restore Session Shortcut:**
```powershell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Restore Session.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"C:\Scripts\SessionManager\RestoreSession.ps1`""
$Shortcut.IconLocation = "shell32.dll,260"
$Shortcut.Save()
```

---

## Files in This Repository

| File | Purpose |
|------|---------|
| **SessionManager.ps1** | Core script (handles save/restore logic) |
| **SaveAndShutdown.ps1** | Save session → Shutdown |
| **SaveAndReboot.ps1** | Save session → Reboot |
| **RestoreSession.ps1** | Restore saved session (use after boot) |
| **DOCUMENTATION.md** | Complete technical documentation |
| **README.md** | This file |

---

## System Requirements

- **Windows 10** (1809+) or **Windows 11**
- **PowerShell 5.1** or later (included with Windows)
- **Optional**: Windows Terminal, VSCode, WSL

---

## Troubleshooting

### "Execution Policy" Error
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### No Session Found
You need to save a session first before you can restore it:
```powershell
.\SaveAndShutdown.ps1
```

### Apps Don't Restore
Some apps need to be in your PATH:
- VSCode: Install "code" command
- Windows Terminal: Should be in PATH by default

---

## FAQ

**Q: Will this save my unsaved documents?**
A: No, you must save your work before running SaveAndShutdown.ps1

**Q: Can I use this instead of hibernate?**
A: Yes! This is the whole point - fresh boot with workspace restore

**Q: Will browser tabs restore?**
A: The script will relaunch your browser, but the browser handles its own tab restoration. Enable "Continue where you left off" in Chrome/Edge settings.

**Q: What if I want to start fresh without restoring?**
A: Just don't run RestoreSession.ps1 after boot. The session file remains saved for later use.

**Q: Can I save multiple sessions?**
A: Currently only one session is saved. You could modify the scripts to support named sessions.

---

## License

Free to use and modify. No warranty provided.

---

## See Also

- **DOCUMENTATION.md** - Complete technical documentation with all details
- Windows Terminal documentation
- PowerShell PSReadLine history
