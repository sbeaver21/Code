# ABX Salt Minion Install Action

This directory contains the **ABX Action** (`abx-install-minion.ps1`) used in VMware vRealize Automation (vRA) to automatically install, configure, and manage Salt Minions on provisioned virtual machines.

## File

| File | Description |
|------|-------------|
| `abx-install-minion.ps1` | The ABX action script deployed to vRA. |

## Overview

The script is triggered during the VM lifecycle in vRA (post-provision or pre-removal) and handles:

- **Installation** — Downloads and bootstraps the Salt Minion on both **Windows** and **Linux** VMs.
- **Configuration** — Sets the minion ID, master fingerprint, startup states (highstate), and drop-in configs.
- **Post-Provision Automation** — Runs only on `compute.provision.post` events:
  - Starts/restarts the Salt Minion service.
  - Accepts the minion key on each configured Salt Master.
  - Applies custom Salt grains from VM custom properties.
  - Executes highstate (if `highstate=true` in custom properties).
  - Windows-specific: SCCM installation and domain join.
  - Linux-specific: Ensures SSH is enabled, applies `linux` state.
- **Pre-Removal Cleanup** — On `compute.removal.pre` events, revokes the minion's Salt authentication before the VM is destroyed.

## Security

- All passwords are retrieved via `$context.getSecret()` (vRA secure string handling).
- Passwords are immediately converted to `[securestring]` and kept in that form throughout the script's helper functions.
- The plain-text password is only materialized at the single call site where `Invoke-VMScript` requires it, and is promptly discarded.

## Dependencies

The script assumes the following environment is available at runtime:

- **PowerShell** (PowerShell 5.1+ or PowerShell 7) — must be available within the vRA ABX runtime context.
- **VMware PowerCLI** — Provides `Connect-VIServer`, `Get-VM`, `Invoke-VMScript`, `Get-View`, and related cmdlets.
- **vCenter Server** — The script connects to one or two vCenter instances (main and optional management vCenter).
- **Salt Bootstrap** — The Salt Minion binary is downloaded from the official Salt Bootstrap repository during installation.
- **vRA ABX Runtime** — The `$context.getSecret()` method and `$inputs` / `$context` objects are provided by the vRA ABX execution environment.

## Inputs (from vRA)

| Input | Source | Description |
|-------|--------|-------------|
| `customProperties` | vRA blueprint / deployment | VM-specific properties (osType, masterFingerPrint, masterString, minionVersion, etc.) |
| `vcUsername` / `vcPassword` | Secure string inputs | vCenter connection credentials |
| `template_admin_windows` / `template_password_windows` | Secure string inputs | Windows guest OS credentials |
| `template_admin_linux` / `template_password_linux` | Secure string inputs | Linux guest OS credentials |
| `linux_vrautomation_user` / `linux_vrautomation_psswd` | Secure string inputs | Credentials for Salt Master VM guest operations |
| `resourceNames[0]` | vRA deployment | The target VM name |
| `__metadata.eventTopicId` | vRA lifecycle | The event topic (e.g., `compute.provision.post`, `compute.removal.pre`) |

## vRA Deployment Notes

This script is deployed as an **ABX Action** in vRealize Automation (vRA). It is typically subscribed to the `compute.provision.post` and `compute.removal.pre` event topics.

### Custom Properties on the Blueprint

The following custom properties must be defined on the VM (e.g., via blueprint or property group):

- `osType` — `WINDOWS` or `LINUX`
- `vCenter` — The vCenter FQDN
- `masterFingerPrint` — Salt Master fingerprint
- `masterString` — Comma-separated list of Salt Master FQDNs
- `masterAddress` — JSON array of Salt Master addresses (optional; falls back to `masterString`)
- `minionVersion` — Salt Minion version to install
- `custom.environmentTag`, `custom.machineDomain`, `custom.mountpoints`, `custom.mountlabels`, `shortDomain`, `vmId` — Grain values
- `highstate` — Set to `true` to run highstate during post-provision
- `role` — e.g., `SQL`, `WEB`, `APP`, etc.

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v3.0.0 | — | Refactored: consolidated Linux install, fixed security issues, eliminated dead code, batched grain ops, fixed `salt-call` path |
| v2.2.0 | — | Bug fixes, local install and further cleanup |
| v2.1.0 | — | Refactored for modularity and performance |
| v2.0.4 | — | Refactored for structure, readability, and best practices |