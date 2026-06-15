# Configure ESXi Core Dump

A PowerShell script that configures core dump settings on ESXi hosts in a vCenter cluster. This script automates the process of setting up ESXi core dumps to a designated datastore partition, which is essential for capturing diagnostic information when an ESXi host encounters a critical failure (purple diagnostic screen / PSOD).

## Features

- Connects to a vCenter Server and authenticates (supports both provided `PSCredential` objects and interactive credential prompts)
- Retrieves all ESXi hosts from a specified cluster
- Configures core dump on each host with a three-step process:
  1. **Unconfigures** any existing core dump file on the host
  2. **Adds** a new core dump file on the specified datastore partition
  3. **Sets** the core dump file with smart dump enabled
- Provides visual progress tracking via `Write-Progress`
- Supports `-WhatIf` and `-Confirm` via `SupportsShouldProcess`
- Optionally outputs the resulting core dump configuration (`-PassThru` switch)
- Cleans up the vCenter connection on completion

## Requirements

- **PowerShell** 5.1 or later
- **VMware PowerCLI** 12.0 or later (`VMware.VimAutomation.Core` module)
- Network access to the target vCenter Server
- Appropriate vCenter permissions to configure ESXi core dump settings on hosts in the target cluster

## Installation

1. Install the required VMware PowerCLI module:

   ```powershell
   Install-Module -Name VMware.PowerCLI -MinimumVersion 12.0 -Scope CurrentUser
   ```

2. Clone or download this repository and navigate to the script directory.

## Parameters

| Parameter       | Type           | Mandatory | Position | Description                                                                                       |
|-----------------|----------------|-----------|----------|---------------------------------------------------------------------------------------------------|
| `DumpPartition` | `string`       | Yes       | 0        | Name of the datastore or partition to use for core dumps.                                         |
| `VCenterFQDN`   | `string`       | Yes       | 1        | Fully qualified domain name of the vCenter Server to connect to.                                  |
| `ClusterName`   | `string`       | Yes       | 2        | Name of the cluster containing the ESXi hosts to configure.                                       |
| `Credential`    | `PSCredential` | No        | N/A      | PSCredential object for vCenter authentication. If omitted, you are prompted interactively.       |
| `PassThru`      | `switch`       | No        | N/A      | When specified, outputs the core dump file list for each host after configuration.                |

## Usage

### Basic usage (interactive credential prompt)

```powershell
.\configureCoreDump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS"
```

### With credential object (non-interactive)

```powershell
$cred = Get-Credential
.\configureCoreDump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -Credential $cred
```

### With PassThru to verify configuration

```powershell
.\configureCoreDump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -PassThru
```

### WhatIf mode (dry run)

```powershell
.\configureCoreDump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -WhatIf
```

## Script Behavior

1. **Certificate Handling** — The script configures the PowerCLI session to ignore invalid certificate warnings (scope: Session only) to accommodate self-signed or internally-signed vCenter certificates.
2. **Authentication** — If no `-Credential` parameter is provided, the script prompts the user for vCenter credentials.
3. **Host Discovery** — Retrieves all ESXi hosts within the specified cluster.
4. **Core Dump Configuration** — For each host, executes the following via `ESXCLI`:
   - Unconfigures any previously set core dump file.
   - Adds a new core dump file on the specified datastore partition named after the host (e.g., the VM host name becomes the dump file name).
   - Enables the core dump file with smart dump enabled.
5. **Progress Reporting** — Displays a progress bar as hosts are processed.
6. **Connection Cleanup** — Disconnects from the vCenter Server after processing all hosts.

## Notes

- The datastore specified by `DumpPartition` should already exist and be accessible by the ESXi hosts in the cluster.
- Smart dump (`-smart $true`) enables compact core dumps that reduce disk and network resource usage while preserving diagnostic information.
- Core dump files are named after each ESXi host and are stored on the specified datastore partition.
- The script uses `-ErrorAction Stop` on critical operations and will exit with code `1` on connection or cluster retrieval failures.

## Author

Stephen Beaver

## Version

1.0.0
