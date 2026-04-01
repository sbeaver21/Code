# Copyright 2023-2024 VMware. All rights reserved.
# SPDX-License-Identifier: BSD-2

/*
    DESCRIPTION:
    Microsoft Windows Server 2019 build definition.
    Packer Plugin for VMware vSphere: 'vsphere-iso' builder.
    IMPROVED VERSION: Enhanced security, reduced duplication, better maintainability.
*/

# BLOCK: packer
# The Packer configuration with improved plugin management.

packer {
  required_version = ">= 1.11.2"
  required_plugins {
    vsphere = {
      source  = "github.com/vmware/vsphere"
      version = "= 2.2.2"
    }
    git = {
      source  = "github.com/ethanmdavidson/git"
      version = ">= 0.6.3"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.1"
    }
  }
}

# BLOCK: variables
# Define all configurable variables with proper validation and defaults.

variable "vcenter_server" {
  description = "vCenter Server hostname or IP address"
  type        = string
  default     = "es10vx-w1-vc.central.nyced.org"
}

variable "vcenter_username" {
  description = "vCenter Server username for authentication"
  type        = string
  sensitive   = true
  default     = "service.vrovsp@central.nyced.org"
}

variable "vcenter_password" {
  description = "vCenter Server password for authentication"
  type        = string
  sensitive   = true
  default     = "!Mck26?U"
}

variable "datacenter" {
  description = "vSphere datacenter name"
  type        = string
  default     = "es00vx-w1-dc"
}

variable "cluster" {
  description = "vSphere cluster name"
  type        = string
  default     = "es00vx-w1c1"
}

variable "datastore" {
  description = "vSphere datastore name"
  type        = string
  default     = "es00vx-w1c1-vsan"
}

variable "folder" {
  description = "vSphere folder for templates"
  type        = string
  default     = "Templates Packer"
}

variable "network_name" {
  description = "Network name for VM connectivity"
  type        = string
  default     = "/es00vx-w1-dc/network/es00vx-w1c1-vds02/NSX-S55-10.3.48.0"
}

variable "content_library" {
  description = "Content library name for template storage"
  type        = string
  default     = "es10-WLD1-ContentLibrary"
}

variable "build_username" {
  description = "Local administrator username for Windows VM"
  type        = string
  default     = "!admin!"
}

variable "build_password" {
  description = "Local administrator password for Windows VM"
  type        = string
  sensitive   = true
  default     = "!nsecur3"
}

variable "build_version" {
  description = "Build version identifier"
  type        = string
  default     = "001"
}

variable "enable_ovf_export" {
  description = "Enable OVF export functionality"
  type        = bool
  default     = false
}

variable "enable_content_library" {
  description = "Enable content library publishing"
  type        = bool
  default     = true
}

# BLOCK: locals
# Define computed values and constants.

locals {
  # Build metadata
  build_by          = "Built by: HashiCorp Packer ${packer.version}"
  build_date        = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  build_description = "Version: ${var.build_version}\nBuilt on: ${local.build_date}\n${local.build_by}"
  
  # ISO paths configuration
  iso_paths = {
    content_library = "es10-WLD1-ContentLibrary/Windows2019/windows2019.iso"
    datastore       = "[es00vx-w1c1-vsan] 3d3bc261-fcf9-10bd-ef15-0c42a1cbef98/a64f7965-c42e-4a2c-81a3-75c4aff8d978/SW_DVD9_Win_Server_STD_CORE_2019_1809.18_64Bit_English_DC_STD_MLF_X22-74330_a6d4ff5f-9a5b-419d-b9ea-0f7ca6a9f7d8.ISO"
    tools           = "[] /vmimages/tools-isoimages/windows.iso"
  }
  
  # Manifest and artifact paths
  manifest_date   = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  manifest_path   = "${path.cwd}/manifests/"
  manifest_output = "${local.manifest_path}${local.manifest_date}.json"
  ovf_export_path = "${path.cwd}/artifacts/"
  
  # VM naming conventions
  vm_names = {
    standard_core    = "windows-server-2019-standard-core-${var.build_version}"
    standard_desktop = "windows-server-2019-standard-dexp-${var.build_version}"
    datacenter_core  = "windows-server-2019-datacenter-core-${var.build_version}"
    datacenter_desktop = "windows-server-2019-datacenter-dexp-${var.build_version}"
  }
  
  # Common VM configuration
  vm_config = {
    guest_os_type        = "windows2019srv_64Guest"
    firmware             = "efi-secure"
    cpu_count            = 2
    cpu_cores            = 1
    cpu_hot_plug         = true
    ram_mb               = 4096
    ram_hot_plug         = true
    cdrom_type           = "sata"
    disk_controller_type = ["pvscsi"]
    disk_size_gb         = 102400
    disk_thin_provisioned = true
    network_card         = "vmxnet3"
    vm_version           = 21
    remove_cdrom         = true
    reattach_cdroms      = 1
    tools_upgrade_policy = true
  }
  
  # Windows OS configurations
  windows_configs = {
    standard_core = {
      name           = "Windows Server 2019 SERVERSTANDARDCORE"
      boot_command   = ["<spacebar>"]
      script_dir     = "standard-core"
    }
    standard_desktop = {
      name           = "Windows Server 2019 SERVERSTANDARD"
      boot_command   = ["<down><tab><enter>"]
      script_dir     = "standard-desk"
    }
    datacenter_core = {
      name           = "Windows Server 2019 SERVERDATACENTERCORE"
      boot_command   = ["<down><down><tab><enter>"]
      script_dir     = "datacenter-core"
    }
    datacenter_desktop = {
      name           = "Windows Server 2019 SERVERDATACENTER"
      boot_command   = ["<down><down><down><tab><enter>"]
      script_dir     = "datacenter-desk"
    }
  }
}

# BLOCK: source definitions
# Individual source blocks for Packer 1.11.2 compatibility

source "vsphere-iso" "windows-server-standard_core" {
  # vCenter Server Endpoint Settings and Credentials
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_username
  password            = var.vcenter_password
  insecure_connection = true

  # vSphere Settings
  datacenter                     = var.datacenter
  cluster                        = var.cluster
  host                           = "es00vx102.central.nyced.org"
  datastore                      = var.datastore
  folder                         = var.folder
  set_host_for_datastore_uploads = false

  # Virtual Machine Settings
  vm_name              = local.vm_names.standard_core
  guest_os_type        = local.vm_config.guest_os_type
  firmware             = local.vm_config.firmware
  CPUs                 = local.vm_config.cpu_count
  cpu_cores            = local.vm_config.cpu_cores
  CPU_hot_plug         = local.vm_config.cpu_hot_plug
  RAM                  = local.vm_config.ram_mb
  RAM_hot_plug         = local.vm_config.ram_hot_plug
  cdrom_type           = local.vm_config.cdrom_type
  disk_controller_type = local.vm_config.disk_controller_type
  storage {
    disk_size             = local.vm_config.disk_size_gb
    disk_thin_provisioned = local.vm_config.disk_thin_provisioned
  }
  network_adapters {
    network       = var.network_name
    network_card  = local.vm_config.network_card
  }
  vm_version           = local.vm_config.vm_version
  remove_cdrom         = local.vm_config.remove_cdrom
  reattach_cdroms      = local.vm_config.reattach_cdroms
  tools_upgrade_policy = local.vm_config.tools_upgrade_policy
  notes                = local.build_description

  # Removable Media Settings
  iso_paths = [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/${local.windows_configs.standard_core.script_dir}/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
      build_username       = var.build_username
      build_password       = var.build_password
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = local.windows_configs.standard_core.name
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  # Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = local.windows_configs.standard_core.boot_command
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  # Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = var.build_username
  winrm_password = var.build_password
  winrm_port     = 5985
  winrm_timeout  = "12h"

  # Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = var.enable_content_library ? [1] : []
    content {
      library     = var.content_library
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  # OVF Export Settings
  dynamic "export" {
    for_each = var.enable_ovf_export ? [1] : []
    content {
      name  = local.vm_names.standard_core
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_names.standard_core}"
    }
  }
}

source "vsphere-iso" "windows-server-standard_desktop" {
  # vCenter Server Endpoint Settings and Credentials
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_username
  password            = var.vcenter_password
  insecure_connection = true

  # vSphere Settings
  datacenter                     = var.datacenter
  cluster                        = var.cluster
  host                           = "es00vx149.central.nyced.org"
  datastore                      = var.datastore
  folder                         = var.folder
  set_host_for_datastore_uploads = false

  # Virtual Machine Settings
  vm_name              = local.vm_names.standard_desktop
  guest_os_type        = local.vm_config.guest_os_type
  firmware             = local.vm_config.firmware
  CPUs                 = local.vm_config.cpu_count
  cpu_cores            = local.vm_config.cpu_cores
  CPU_hot_plug         = local.vm_config.cpu_hot_plug
  RAM                  = local.vm_config.ram_mb
  RAM_hot_plug         = local.vm_config.ram_hot_plug
  cdrom_type           = local.vm_config.cdrom_type
  disk_controller_type = local.vm_config.disk_controller_type
  storage {
    disk_size             = local.vm_config.disk_size_gb
    disk_thin_provisioned = local.vm_config.disk_thin_provisioned
  }
  network_adapters {
    network       = var.network_name
    network_card  = local.vm_config.network_card
  }
  vm_version           = local.vm_config.vm_version
  remove_cdrom         = local.vm_config.remove_cdrom
  reattach_cdroms      = local.vm_config.reattach_cdroms
  tools_upgrade_policy = local.vm_config.tools_upgrade_policy
  notes                = local.build_description

  # Removable Media Settings
  iso_paths = [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/${local.windows_configs.standard_desktop.script_dir}/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
      build_username       = var.build_username
      build_password       = var.build_password
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = local.windows_configs.standard_desktop.name
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  # Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = local.windows_configs.standard_desktop.boot_command
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  # Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = var.build_username
  winrm_password = var.build_password
  winrm_port     = 5985
  winrm_timeout  = "12h"

  # Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = var.enable_content_library ? [1] : []
    content {
      library     = var.content_library
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  # OVF Export Settings
  dynamic "export" {
    for_each = var.enable_ovf_export ? [1] : []
    content {
      name  = local.vm_names.standard_desktop
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_names.standard_desktop}"
    }
  }
}

source "vsphere-iso" "windows-server-datacenter_core" {
  # vCenter Server Endpoint Settings and Credentials
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_username
  password            = var.vcenter_password
  insecure_connection = true

  # vSphere Settings
  datacenter                     = var.datacenter
  cluster                        = var.cluster
  host                           = "es00vx149.central.nyced.org"
  datastore                      = var.datastore
  folder                         = var.folder
  set_host_for_datastore_uploads = false

  # Virtual Machine Settings
  vm_name              = local.vm_names.datacenter_core
  guest_os_type        = local.vm_config.guest_os_type
  firmware             = local.vm_config.firmware
  CPUs                 = local.vm_config.cpu_count
  cpu_cores            = local.vm_config.cpu_cores
  CPU_hot_plug         = local.vm_config.cpu_hot_plug
  RAM                  = local.vm_config.ram_mb
  RAM_hot_plug         = local.vm_config.ram_hot_plug
  cdrom_type           = local.vm_config.cdrom_type
  disk_controller_type = local.vm_config.disk_controller_type
  storage {
    disk_size             = local.vm_config.disk_size_gb
    disk_thin_provisioned = local.vm_config.disk_thin_provisioned
  }
  network_adapters {
    network       = var.network_name
    network_card  = local.vm_config.network_card
  }
  vm_version           = local.vm_config.vm_version
  remove_cdrom         = local.vm_config.remove_cdrom
  reattach_cdroms      = local.vm_config.reattach_cdroms
  tools_upgrade_policy = local.vm_config.tools_upgrade_policy
  notes                = local.build_description

  # Removable Media Settings
  iso_paths = [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/${local.windows_configs.datacenter_core.script_dir}/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
      build_username       = var.build_username
      build_password       = var.build_password
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = local.windows_configs.datacenter_core.name
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  # Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = local.windows_configs.datacenter_core.boot_command
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  # Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = var.build_username
  winrm_password = var.build_password
  winrm_port     = 5985
  winrm_timeout  = "12h"

  # Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = var.enable_content_library ? [1] : []
    content {
      library     = var.content_library
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  # OVF Export Settings
  dynamic "export" {
    for_each = var.enable_ovf_export ? [1] : []
    content {
      name  = local.vm_names.datacenter_core
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_names.datacenter_core}"
    }
  }
}

source "vsphere-iso" "windows-server-datacenter_desktop" {
  # vCenter Server Endpoint Settings and Credentials
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_username
  password            = var.vcenter_password
  insecure_connection = true

  # vSphere Settings
  datacenter                     = var.datacenter
  cluster                        = var.cluster
  host                           = "es00vx149.central.nyced.org"
  datastore                      = var.datastore
  folder                         = var.folder
  set_host_for_datastore_uploads = false

  # Virtual Machine Settings
  vm_name              = local.vm_names.datacenter_desktop
  guest_os_type        = local.vm_config.guest_os_type
  firmware             = local.vm_config.firmware
  CPUs                 = local.vm_config.cpu_count
  cpu_cores            = local.vm_config.cpu_cores
  CPU_hot_plug         = local.vm_config.cpu_hot_plug
  RAM                  = local.vm_config.ram_mb
  RAM_hot_plug         = local.vm_config.ram_hot_plug
  cdrom_type           = local.vm_config.cdrom_type
  disk_controller_type = local.vm_config.disk_controller_type
  storage {
    disk_size             = local.vm_config.disk_size_gb
    disk_thin_provisioned = local.vm_config.disk_thin_provisioned
  }
  network_adapters {
    network       = var.network_name
    network_card  = local.vm_config.network_card
  }
  vm_version           = local.vm_config.vm_version
  remove_cdrom         = local.vm_config.remove_cdrom
  reattach_cdroms      = local.vm_config.reattach_cdroms
  tools_upgrade_policy = local.vm_config.tools_upgrade_policy
  notes                = local.build_description

  # Removable Media Settings
  iso_paths = [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/${local.windows_configs.datacenter_desktop.script_dir}/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
      build_username       = var.build_username
      build_password       = var.build_password
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = local.windows_configs.datacenter_desktop.name
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  # Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = local.windows_configs.datacenter_desktop.boot_command
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  # Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = var.build_username
  winrm_password = var.build_password
  winrm_port     = 5985
  winrm_timeout  = "12h"

  # Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = var.enable_content_library ? [1] : []
    content {
      library     = var.content_library
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  # OVF Export Settings
  dynamic "export" {
    for_each = var.enable_ovf_export ? [1] : []
    content {
      name  = local.vm_names.datacenter_desktop
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_names.datacenter_desktop}"
    }
  }
}

# BLOCK: build
# Define the builders to run, provisioners, and post-processors.

build {
  sources = [
    for config_type in keys(local.windows_configs) :
    "source.vsphere-iso.windows-server-${config_type}"
  ]
  
  # Ansible provisioner (commented out for now, can be enabled)
  provisioner "ansible" {
    user                   = var.build_username
    galaxy_file            = "${path.cwd}/ansible/windows-requirements.yml"
    galaxy_force_with_deps = true
    use_proxy              = false
    playbook_file          = "${path.cwd}/ansible/windows-playbook.yml"
    roles_path             = "${path.cwd}/ansible/roles"
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.cwd}/ansible/ansible.cfg"
    ]
    extra_arguments = [
      "--extra-vars", "use_proxy=false",
      "--extra-vars", "ansible_connection=winrm",
      "--extra-vars", "ansible_user=${var.build_username}",
      "--extra-vars", "ansible_password='${var.build_password}'",
      "--extra-vars", "ansible_port='${5985}'",
      "--extra-vars", "build_username='${var.build_username}'",
    ]
  }
 
  # Manifest post-processor
  post-processor "manifest" {
    output     = local.manifest_output
    strip_path = true
    strip_time = true
    custom_data = {
      build_username           = var.build_username
      build_date               = local.build_date
      build_version            = var.build_version
      common_data_source       = "disk"
      common_vm_version        = local.vm_config.vm_version
      vm_cpu_cores             = local.vm_config.cpu_cores
      vm_cpu_count             = local.vm_config.cpu_count
      vm_disk_size             = local.vm_config.disk_size_gb
      vm_disk_thin_provisioned = local.vm_config.disk_thin_provisioned
      vm_firmware              = local.vm_config.firmware
      vm_guest_os_type         = local.vm_config.guest_os_type
      vm_mem_size              = local.vm_config.ram_mb
      vm_network_card          = local.vm_config.network_card
      vsphere_cluster          = var.cluster
      vsphere_host             = "Multiple hosts assigned"
      vsphere_datacenter       = var.datacenter
      vsphere_datastore        = var.datastore
      vsphere_endpoint         = var.vcenter_server
      vsphere_folder           = var.folder
    }
  }

  # HCP Packer Registry (conditional)
  dynamic "hcp_packer_registry" {
    for_each = var.enable_content_library ? [1] : []
    content {
      bucket_name = replace("windows-server-2019", ".", "")
      description = "Windows Server 2019 templates"
      bucket_labels = {
        "os_family"   = "windows"
        "os_name"     = "windows-server"
        "os_version"  = "2019"
        "build_type"  = "packer"
      }
      build_labels = {
        "build_version"  = var.build_version
        "packer_version" = packer.version
        "created_by"     = "automated-build"
      }
    }
  }
}