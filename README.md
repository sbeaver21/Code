# Steve-Code-Private

Private scripts and automation modules used in vRealize Automation (vRA) and vSphere environments.

## Structure

| Directory | Description |
|-----------|-------------|
| `PowerShell/` | ABX action scripts deployed to vRA for VM lifecycle automation |

## Contents

### PowerShell

- **`abx-install-minion.ps1`** — ABX Action that installs, configures, and manages Salt Minions on provisioned Windows and Linux VMs during vRA lifecycle events (`compute.provision.post`, `compute.removal.pre`).

See [PowerShell/README.md](PowerShell/README.md) for full documentation.