# Configure ESXi Core Dump

A collection of PowerShell scripts that configure core dump settings on ESXi hosts in a vCenter cluster. These scripts automate the process of setting up ESXi core dumps, which is essential for capturing diagnostic information when an ESXi host encounters a critical failure (purple diagnostic screen / PSOD).

Three methods of core dump configuration are supported:

| Script | Method | Description |
| -------- | -------- | ------------- |
| `esxi-core-dump.ps1` | Datastore partition | Configures core dump to a designated datastore partition |
| `esxi-core-dump-file.ps1` | NFS file | Configures core dump to write to a file on an NFS share |
| `esxi-core-dump-mount.ps1` | NFS mount | Mounts an NFS share on each host and configures core dump to the mounted drive |

---

## Scripts

### 1. `esxi-core-dump.ps1` — Datastore Partition Core Dump

Configures core dump to a datastore partition.

#### Parameters (Datastore Partition)

| Parameter       | Type           | Mandatory | Position | Description                                                                                       |
|-----------------|----------------|-----------|----------|---------------------------------------------------------------------------------------------------|
| `DumpPartition` | `string`       | Yes       | 0        | Name of the datastore or partition to use for core dumps.                                         |
| `VCenterFQDN`   | `string`       | Yes       | 1        | Fully qualified domain name of the vCenter Server to connect to.                                  |
| `ClusterName`   | `string`       | Yes       | 2        | Name of the cluster containing the ESXi hosts to configure.                                       |
| `Credential`    | `PSCredential` | No        | N/A      | PSCredential object for vCenter authentication. If omitted, you are prompted interactively.       |
| `PassThru`      | `switch`       | No        | N/A      | When specified, outputs the core dump file list for each host after configuration.                |

#### Examples (Datastore Partition)

```powershell
# Basic usage (interactive credential prompt)
.\esxi-core-dump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS"

# With credential object (non-interactive)
$cred = Get-Credential
.\esxi-core-dump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -Credential $cred

# With PassThru to verify configuration
.\esxi-core-dump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -PassThru

# WhatIf mode (dry run)
.\esxi-core-dump.ps1 -DumpPartition "PFX1020_COREDUMP" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -WhatIf
```

---

### 2. `esxi-core-dump-file.ps1` — NFS File Core Dump

Configures core dump to write to a file on an NFS share **without** mounting the share on the host. This uses ESXCLI's `system coredump file add` command with server and directory parameters directly.

#### Parameters (NFS File)

| Parameter       | Type           | Mandatory | Position | Description                                                                                       |
|-----------------|----------------|-----------|----------|---------------------------------------------------------------------------------------------------|
| `NFSServer`     | `string`       | Yes       | 0        | IP address or FQDN of the NFS server hosting the core dump directory.                             |
| `NFSDirectory`  | `string`       | Yes       | 1        | Export path on the NFS server (e.g. `/coredumps`).                                                |
| `VCenterFQDN`   | `string`       | Yes       | 2        | Fully qualified domain name of the vCenter Server to connect to.                                  |
| `ClusterName`   | `string`       | Yes       | 3        | Name of the cluster containing the ESXi hosts to configure.                                       |
| `Credential`    | `PSCredential` | No        | N/A      | PSCredential object for vCenter authentication. If omitted, you are prompted interactively.       |
| `PassThru`      | `switch`       | No        | N/A      | When specified, outputs the core dump file list for each host after configuration.                |

#### Examples (NFS File)

```powershell
# Basic usage (interactive credential prompt)
.\esxi-core-dump-file.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS"

# With credential object (non-interactive)
$cred = Get-Credential
.\esxi-core-dump-file.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -Credential $cred

# With PassThru to verify configuration
.\esxi-core-dump-file.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -PassThru

# WhatIf mode (dry run)
.\esxi-core-dump-file.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -WhatIf
```

---

### 3. `esxi-core-dump-mount.ps1` — NFS Mount Core Dump

Mounts an NFS share on each ESXi host and configures core dump to write to a file on the mounted drive. This approach makes the NFS share available as a local path on the host before configuring the core dump target.

#### Parameters (NFS Mount)

| Parameter       | Type           | Mandatory | Position | Description                                                                                       |
|-----------------|----------------|-----------|----------|---------------------------------------------------------------------------------------------------|
| `NFSServer`     | `string`       | Yes       | 0        | IP address or FQDN of the NFS server hosting the core dump directory.                             |
| `NFSDirectory`  | `string`       | Yes       | 1        | Export path on the NFS server (e.g. `/coredumps`).                                                |
| `VCenterFQDN`   | `string`       | Yes       | 2        | Fully qualified domain name of the vCenter Server to connect to.                                  |
| `ClusterName`   | `string`       | Yes       | 3        | Name of the cluster containing the ESXi hosts to configure.                                       |
| `Credential`    | `PSCredential` | No        | N/A      | PSCredential object for vCenter authentication. If omitted, you are prompted interactively.       |
| `PassThru`      | `switch`       | No        | N/A      | When specified, outputs the core dump file list for each host after configuration.                |

#### Examples (NFS Mount)

```powershell
# Basic usage (interactive credential prompt)
.\esxi-core-dump-mount.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS"

# With credential object (non-interactive)
$cred = Get-Credential
.\esxi-core-dump-mount.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -Credential $cred

# With PassThru to verify configuration
.\esxi-core-dump-mount.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -PassThru

# WhatIf mode (dry run)
.\esxi-core-dump-mount.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -WhatIf
```

---

## Common Features

All three scripts share the following characteristics:

- **Certificate Handling** — Configure PowerCLI to ignore invalid certificate warnings (scope: Session only) to accommodate self-signed or internally-signed vCenter certificates.
- **Authentication** — If no `-Credential` parameter is provided, the script prompts the user for vCenter credentials.
- **Host Discovery** — Retrieves all ESXi hosts within the specified cluster.
- **Core Dump Configuration** — For each host, executes the following via ESXCLI:
  1. **Unconfigures** any existing core dump file on the host
  2. **Adds** a new core dump file (named after each ESXi host)
  3. **Sets** the core dump file with smart dump enabled
- **Progress Reporting** — Displays a progress bar as hosts are processed.
- **Connection Cleanup** — Disconnects from the vCenter Server after processing all hosts.
- **WhatIf/Confirm Support** — All scripts support `-WhatIf` and `-Confirm` via `SupportsShouldProcess`.

## Choosing a Method

| If you have...                                          | Use...                     |
|---------------------------------------------------------|----------------------------|
| A dedicated datastore partition for core dumps          | `esxi-core-dump.ps1`       |
| An NFS share and want ESXi to access it directly        | `esxi-core-dump-file.ps1`  |
| An NFS share and want it mounted on each host first     | `esxi-core-dump-mount.ps1` |

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

## Notes

- For **datastore partition** usage (`esxi-core-dump.ps1`): The datastore specified by `DumpPartition` should already exist and be accessible by the ESXi hosts in the cluster.
- For **NFS** usage (`esxi-core-dump-file.ps1` and `esxi-core-dump-mount.ps1`): The NFS share must be accessible from the ESXi hosts in the cluster.
- Smart dump (`-smart $true`) enables compact core dumps that reduce disk and network resource usage while preserving diagnostic information.
- Core dump files are named after each ESXi host.
- All scripts use `-ErrorAction Stop` on critical operations and will exit with code `1` on connection or cluster retrieval failures.

## Author

Stephen Beaver

## Versions

- `esxi-core-dump.ps1` — **1.0.0**
- `esxi-core-dump-file.ps1` — **2.0.0**
- `esxi-core-dump-mount.ps1` — **2.0.0**
