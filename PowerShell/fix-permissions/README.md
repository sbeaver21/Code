# Windows Permission Fix Utility

A PowerShell script that resolves common Windows file/folder ownership and permission warnings, specifically targeting the security warning: *"Warning: this is a potential security risk because anyone who can access this object can take ownership of it."*

## Description

This script automates the repair of Windows NTFS permissions when files or folders have ownership set but lack proper ACL permissions. It resolves the issue by performing the following steps on each specified path:

1. **Take ownership** of the path recursively using `takeown`
2. **Reset ACL inheritance** to clear corrupt inherited permissions
3. **Grant Full Control** to the current user (or a specified account)
4. **Grant Full Control** to the `BUILTIN\Administrators` group
5. **Optionally remove explicit Deny ACE entries** that may be blocking access

## Requirements

- **PowerShell 5.0 or later**
- **Administrator privileges** are strongly recommended, especially when operating on system-protected paths (`C:\Windows`, `C:\Program Files`, etc.)

## Usage

### Basic Usage

Fix the current working directory:

```powershell
.\Fix-Permissions.ps1
```

### Specify a Path

```powershell
.\Fix-Permissions.ps1 -Path "C:\SomeFolder"
```

### Multiple Paths

```powershell
.\Fix-Permissions.ps1 -Path "C:\Folder1", "C:\Folder2" -Recursive $true -Force
```

### Skip Confirmation Prompt

```powershell
.\Fix-Permissions.ps1 -Path "D:\Data" -Force
```

### Remove Explicit Deny Entries

```powershell
.\Fix-Permissions.ps1 -Path "C:\Shared" -RemoveExplicitDeny
```

### Specify a Different User Account

```powershell
.\Fix-Permissions.ps1 -Path "C:\Project" -GrantUser "DOMAIN\Username"
```

## Parameters

| Parameter            | Type     | Default           | Description                                                    |
| -------------------- | -------- | ----------------- | -------------------------------------------------------------- |
| `Path`               | string[] | `.` (current dir) | One or more file/folder paths to fix. Supports wildcards.      |
| `Recursive`          | bool     | `$true`           | Process all subdirectories and files recursively.              |
| `GrantUser`          | string   | Current user      | The user/account to grant permissions to.                      |
| `ResetInheritance`   | bool     | `$true`           | Reset permission inheritance so the path inherits from parent. |
| `Force`              | switch   | `$false`          | Skip confirmation prompts.                                     |
| `RemoveExplicitDeny` | switch   | `$false`          | Remove any explicit Deny ACE entries (Everyone, BUILTIN\Users).|

## How It Works

The script uses built-in Windows command-line tools:

- **`takeown`** — Takes ownership of files/folders
- **`icacls`** — Grants permissions, resets ACL inheritance, and removes deny entries

Each target path goes through the `Repair-Path` function which orchestrates the steps in sequence. The script includes error handling and logging (with timestamps) so you can see exactly what succeeded or failed.

## Administrator Detection

The script checks whether it is running with elevated privileges. If not, it issues a warning when targeting system paths (`C:\Windows`, `C:\Program Files`, `C:\Program Files (x86)`), as those operations will likely fail without administrator rights.

## Troubleshooting

If the permission warning persists after running the script, verify the file/folder is not:

- **Encrypted with EFS** — Check Properties → Advanced Attributes
- **On a network share** — The remote server may have different permissions
- **Protected by Windows System Protection** — e.g., `C:\Windows\System32`
- **Corrupted** — Run `chkdsk` to check for disk issues

### Manual Fallback Commands

```cmd
:: Reset all ACLs
icacls <path> /reset /T

:: Take ownership recursively
takeown /F <path> /R /D Y
```

## Examples

### Example 1: Fix a single folder

```powershell
.\Fix-Permissions.ps1 -Path "C:\SomeFolder"
```

### Example 2: Fix multiple folders non-interactively

```powershell
.\Fix-Permissions.ps1 -Path "C:\Folder1", "C:\Folder2" -Recursive $true -Force
```

### Example 3: Fix current directory

```powershell
.\Fix-Permissions.ps1
```

## Notes

- Modifying permissions on system directories can render Windows unstable. Use caution and prefer targeting only the specific files/folders that exhibit the warning.
- The script uses `icacls /grant` with `(OI)(CI)F` flags, which grants **Full Control** with **Object Inherit** and **Container Inherit** propagation to child objects.
- When `-ResetInheritance` is enabled, the script runs `icacls /reset` to remove explicit permissions and re-enable inheritance from the parent before granting new permissions.

## License

See the repository root for license information.
