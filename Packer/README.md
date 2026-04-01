# Windows Server 2019 Packer Build

This directory contains improved Packer configurations for building Windows Server 2019 templates in VMware vSphere environments.

## 🚀 Quick Start

### Prerequisites

- Packer 1.14.0 or later
- VMware vSphere environment access
- Windows Server 2019 ISO files
- Ansible (optional, for post-installation configuration)

### Build All Templates

```bash
# Build all Windows Server 2019 variants
packer build -var-file="variables.pkrvars.hcl" doe-windows-2019-improved.pkr.hcl
```

### Build Specific Template

```bash
# Build only Standard Core variant
packer build -var-file="variables.pkrvars.hcl" -only="source.vsphere-iso.windows-server-standard_core" doe-windows-2019-improved.pkr.hcl
```

## 📁 File Structure

```
Packer/
├── doe-windows-2019-improved.pkr.hcl    # Main improved configuration
├── doe-windows-2019-cline.pkr.hcl      # Original configuration (for reference)
├── variables.pkrvars.hcl               # Environment-specific variables
├── .env.example                        # Environment variables template
├── README.md                           # This file
└── scripts/
    └── windows/                        # Windows automation scripts
        ├── standard-core/
        ├── standard-desk/
        ├── datacenter-core/
        └── datacenter-desk/
```

## 🔒 Security Improvements

### 1. Environment Variables
Sensitive data is now managed through environment variables:

```bash
# Set environment variables
export VSPHERE_PASSWORD="your-secure-password"
export WIN_ADMIN_PASSWORD="your-windows-password"

# Build with environment variables
packer build doe-windows-2019-improved.pkr.hcl
```

### 2. Variable Validation
The configuration includes validation for critical inputs:

```hcl
variable "vcenter_server" {
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.vcenter_server))
    error_message = "vCenter server must be a valid hostname or IP address."
  }
}
```

### 3. Sensitive Data Handling
Sensitive variables are marked appropriately:

```hcl
variable "vcenter_password" {
  type      = string
  sensitive = true
}
```

## 🏗️ Architecture Improvements

### 1. Dynamic Source Generation
Instead of 4 nearly identical source blocks, we now use dynamic generation:

```hcl
dynamic "source" {
  for_each = toset(keys(local.windows_configs))
  labels   = ["vsphere-iso", "windows-server-${each.key}"]
  content  = call("generate_source_config", each.key, local.host_assignments[each.key])
}
```

### 2. Centralized Configuration
Common VM settings are centralized in `locals.vm_config`:

```hcl
vm_config = {
  guest_os_type        = "windows2019srv_64Guest"
  firmware             = "efi-secure"
  cpu_count            = 2
  cpu_cores            = 1
  # ... more settings
}
```

### 3. Template-Based Boot Commands
Boot commands are now template-based and configurable:

```hcl
windows_configs = {
  standard_core = {
    name         = "Windows Server 2019 SERVERSTANDARDCORE"
    boot_command = ["<spacebar>"]
    script_dir   = "standard-core"
  }
  # ... more configurations
}
```

## ⚙️ Configuration Options

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vcenter_server` | string | `es10vx-w1-vc.central.nyced.org` | vCenter Server hostname |
| `vcenter_username` | string | `service.vrovsp@central.nyced.org` | vCenter username |
| `vcenter_password` | string | `!Mck26?U` | vCenter password |
| `build_version` | string | `001` | Build version identifier |
| `enable_ovf_export` | bool | `false` | Enable OVF export |
| `enable_content_library` | bool | `true` | Enable content library publishing |

### Feature Flags

Control optional features with boolean variables:

```hcl
# Enable OVF export
enable_ovf_export = true

# Disable content library publishing
enable_content_library = false
```

## 🔧 Advanced Usage

### Custom Host Assignments

Modify the `host_assignments` local to assign specific hosts:

```hcl
host_assignments = {
  standard_core    = "es00vx102.central.nyced.org"
  standard_desktop = "es00vx149.central.nyced.org"
  # ... more assignments
}
```

### Custom VM Configuration

Override VM settings by modifying `vm_config`:

```hcl
vm_config = {
  cpu_count = 4  # Increase CPU count
  ram_mb    = 8192  # Increase RAM
  # ... other settings
}
```

### Ansible Integration

The configuration includes optional Ansible provisioning:

```bash
# Enable Ansible provisioning
packer build -var "enable_ansible=true" doe-windows-2019-improved.pkr.hcl
```

## 🚨 Security Best Practices

### 1. Never Commit Sensitive Data
Add these files to `.gitignore`:

```gitignore
# Sensitive configuration files
*.pkrvars.hcl
.env
.env.local
```

### 2. Use Environment Variables
Store credentials in environment variables:

```bash
export VSPHERE_PASSWORD=$(cat ~/.secrets/vsphere_password)
export WIN_ADMIN_PASSWORD=$(cat ~/.secrets/windows_password)
```

### 3. Rotate Credentials Regularly
Update passwords and keys periodically and update your secure storage.

### 4. Use Service Accounts
Create dedicated service accounts with minimal required permissions.

## 📊 Build Outputs

### Generated Templates
The build creates 4 Windows Server 2019 templates:

1. `windows-server-2019-standard-core-001`
2. `windows-server-2019-standard-dexp-001`
3. `windows-server-2019-datacenter-core-001`
4. `windows-server-2019-datacenter-dexp-001`

### Artifacts
- **Content Library**: Templates published to vSphere Content Library
- **OVF Exports**: Optional OVF files in `./artifacts/`
- **Manifest**: Build metadata in `./manifests/`

## 🔍 Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify vCenter credentials
   - Check network connectivity
   - Ensure service account has required permissions

2. **ISO Path Issues**
   - Verify ISO paths in `iso_paths` local
   - Check datastore accessibility
   - Ensure Content Library permissions

3. **WinRM Connection Issues**
   - Verify Windows firewall settings
   - Check WinRM service status
   - Ensure correct credentials

### Debug Mode

Enable debug output:

```bash
PACKER_LOG=1 packer build doe-windows-2019-improved.pkr.hcl
```

## 🔄 Migration from Original

To migrate from the original configuration:

1. **Backup your original file**:
   ```bash
   cp doe-windows-2019-cline.pkr.hcl doe-windows-2019-cline.pkr.hcl.backup
   ```

2. **Test the new configuration**:
   ```bash
   packer validate doe-windows-2019-improved.pkr.hcl
   ```

3. **Build a test template**:
   ```bash
   packer build -only="source.vsphere-iso.windows-server-standard_core" doe-windows-2019-improved.pkr.hcl
   ```

4. **Compare outputs** and verify functionality.

## 📝 License

This configuration is provided under the terms of your VMware licensing agreement.

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Packer documentation: https://www.packer.io/docs
3. Check VMware vSphere documentation: https://docs.vmware.com/en/VMware-vSphere/