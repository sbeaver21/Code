# PowerShell Scripts

A collection of PowerShell scripts for automating Windows system administration, image building, and configuration tasks.

## Scripts

### windows-vmtools.ps1

Installs VMware Tools and automatically re-attempts installation if the VMware Tools service fails to start on the first attempt.

**Purpose:**  
Packer-based Windows VM image builds require the VMware Tools service to be running. This script handles the full lifecycle — checking for an existing installation, ensuring the service is running, and reinstalling if needed.

**Parameters:**

| Parameter     | Type   | Default | Description                                                                                                                       |
|---------------|--------|---------|-----------------------------------------------------------------------------------------------------------------------------------|
| SetupPath     | string | E:      | Path to the VMware Tools installation media (typically the virtual CD-ROM drive).                                                 |
| MaxRetries    | int    | 5       | Maximum number of attempts to verify the VMware Tools service is running.                                                         |
| RetryInterval | int    | 2       | Seconds to wait between service status checks.                                                                                    |

**Behavior:**

1. Checks the registry (`HKLM:\Software\...\Uninstall`) to determine if VMware Tools is already installed.
2. If installed:
   - Verifies the `VMTools` service is running.
   - If running → exits with code `0` (success).
   - If not running → uninstalls VMware Tools silently via `msiexec` and proceeds to reinstall.
3. If not installed → proceeds directly to installation.
4. Installs using `setup.exe` or `setup64.exe` from `SetupPath` with silent arguments (`/s /v "/qb REBOOT=R"`).
5. After installation, re-checks the service status up to `MaxRetries` times.
6. Exits with error if the service is still not running.

**Exit Codes:**

| Code | Meaning                                                                                                                        |
|------|--------------------------------------------------------------------------------------------------------------------------------|
| `0`  | Success — VMware Tools is installed and running.                                                                               |
| `1`  | Failure — uninstall failed or service could not be verified.                                                                   |

**Usage Example:**

```powershell
.\windows-vmtools.ps1 -SetupPath "D:" -MaxRetries 10 -RetryInterval 5
```

## Requirements

- PowerShell 5.1 or later (recommended: PowerShell 7+)
- Administrator privileges (required for installing/uninstalling software and managing services)
- VMware Tools ISO mounted or installation files accessible at `SetupPath`
