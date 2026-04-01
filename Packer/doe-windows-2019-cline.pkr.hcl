# Copyright 2023-2024 Broadcom. All rights reserved.
# SPDX-License-Identifier: BSD-2

/*
    DESCRIPTION:
    Microsoft Windows Server 2019 build definition.
    Packer Plugin for VMware vSphere: 'vsphere-iso' builder.
*/

//  BLOCK: packer
//  The Packer configuration.

packer {
  required_version = ">= 1.14.0"
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

//  BLOCK: data
//  Defines the data sources.

// data "git-repository" "cwd" {}

//  BLOCK: locals
//  Defines the local variables.
locals {
  build_by          = "Built by: HashiCorp Packer ${packer.version}"
  build_date        = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  build_version     = "001"
  build_description = "Version: ${local.build_version}\nBuilt on: ${local.build_date}\n${local.build_by}"
  iso_paths = {
    content_library = "es10-WLD1-ContentLibrary/Windows2019/windows2019.iso",
    datastore       = "[es00vx-w1c1-vsan] 3d3bc261-fcf9-10bd-ef15-0c42a1cbef98/a64f7965-c42e-4a2c-81a3-75c4aff8d978/SW_DVD9_Win_Server_STD_CORE_2019_1809.18_64Bit_English_DC_STD_MLF_X22-74330_a6d4ff5f-9a5b-419d-b9ea-0f7ca6a9f7d8.ISO"
    tools           = "[] /vmimages/tools-isoimages/windows.iso"
  }
  manifest_date              = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  manifest_path              = "${path.cwd}/manifests/"
  manifest_output            = "${local.manifest_path}${local.manifest_date}.json"
  ovf_export_path            = "${path.cwd}/artifacts/"
  vm_name_datacenter_core    = "windows-server-2019-datacenter-core-${local.build_version}"
  vm_name_datacenter_desktop = "windows-server-2019-datacenter-dexp-${local.build_version}"
  vm_name_standard_core      = "windows-server-2019-standard-core-${local.build_version}"
  vm_name_standard_desktop   = "windows-server-2019-standard-dexp-${local.build_version}"
  bucket_name                = replace("windows-server-2019", ".", "")
  bucket_description         = "windows server 2019"
}


//  BLOCK: source
//  Defines the builder configuration blocks.

source "vsphere-iso" "windows-server-standard-2019-core" {

  // vCenter Server Endpoint Settings and Credentials
  vcenter_server      = "es10vx-w1-vc.central.nyced.org"
  username            = "service.vrovsp@central.nyced.org"
  password            = "!Mck26?U"
  insecure_connection = true

  // vSphere Settings
  datacenter                     = "es00vx-w1-dc"
  cluster                        = "es00vx-w1c1"
  host                           = "es00vx102.central.nyced.org"
  datastore                      = "es00vx-w1c1-vsan"
  folder                         = "Templates Packer"
  #resource_pool                  = "Resources"
  set_host_for_datastore_uploads = false

  // Virtual Machine Settings
  vm_name              = local.vm_name_standard_core
  guest_os_type        = "windows2019srv_64Guest"
  firmware             = "efi-secure"
  CPUs                 = 2
  cpu_cores            = 1
  CPU_hot_plug         = true
  RAM                  = 4096
  RAM_hot_plug         = true
  cdrom_type           = "sata"
  disk_controller_type = ["pvscsi"]
  storage {
    disk_size             = 102400
    disk_thin_provisioned = true
  }
  network_adapters {
    network       = "/es00vx-w1-dc/network/es00vx-w1c1-vds02/NSX-S55-10.3.48.0"
    network_card  = "vmxnet3"
  }
  vm_version           = 21
  remove_cdrom         = true
  reattach_cdroms      = 1
  tools_upgrade_policy = true
  notes                = local.build_description

  // Removable Media Settings
  iso_paths = false ? [local.iso_paths.content_library, local.iso_paths.tools] : [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/standard-core/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
      build_username       = "!admin!"
      build_password       = "!nsecur3"
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = "Windows Server 2019 SERVERSTANDARDCORE"
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  // Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = ["<spacebar>"]
  #ip_wait_timeout   = "60s"
  #ip_settle_timeout = "5s"
  #ip_wait_address   = "10.3.48.0/24"
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  // Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = "!admin!"
  winrm_password = "!nsecur3"
  winrm_port     = 5985
  winrm_timeout  = "60s"

  // Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = true ? [1] : []
    content {
      library     = "es10-WLD1-ContentLibrary"
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  // OVF Export Settings
  dynamic "export" {
    for_each = false ? [1] : []
    content {
      name  = local.vm_name_standard_core
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_name_standard_core}"
    }
  }
}

source "vsphere-iso" "windows-server-standard-2019-dexp" {

  // vCenter Server Endpoint Settings and Credentials
  vcenter_server      = "es10vx-w1-vc.central.nyced.org"
  username            = "service.vrovsp@central.nyced.org"
  password            = "!Mck26?U"
  insecure_connection = true

  // vSphere Settings
  datacenter                     = "es00vx-w1-dc"
  cluster                        = "es00vx-w1c1"
  host                           = "es00vx149.central.nyced.org"
  datastore                      = "es00vx-w1c1-vsan"
  folder                         = "Templates Packer"
  #resource_pool                  = "Resources"
  set_host_for_datastore_uploads = false

  // Virtual Machine Settings
  vm_name              = local.vm_name_standard_desktop
  guest_os_type        = "windows2019srv_64Guest"
  firmware             = "efi-secure"
  CPUs                 = 2
  cpu_cores            = 1
  CPU_hot_plug         = true
  RAM                  = 4096
  RAM_hot_plug         = true
  cdrom_type           = "sata"
  disk_controller_type = ["pvscsi"]
  storage {
    disk_size             = 102400
    disk_thin_provisioned = true
  }
  network_adapters {
    network      = "/es00vx-w1-dc/network/es00vx-w1c1-vds02/NSX-S55-10.3.48.0"
    network_card = "vmxnet3"
  }
  vm_version           = 21
  remove_cdrom         = true
  reattach_cdroms      = 1
  tools_upgrade_policy = true
  notes                = local.build_description

  // Removable Media Settings
  iso_paths = false ? [local.iso_paths.content_library, local.iso_paths.tools] : [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/standard-desk/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/autounattend.pkrtpl.hcl", {
      build_username       = "!admin!"
      build_password       = "!nsecur3"
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = "Windows Server 2019 SERVERSTANDARD"
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  // Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = ["<down><tab><enter>"]
  #ip_wait_timeout   = "60s"
  #ip_settle_timeout = "5s"
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  // Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = "!admin!"
  winrm_password = "!nsecur3"
  winrm_port     = 5985
  winrm_timeout  = "60s"

  // Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = true ? [1] : []
    content {
      library     = "es10-WLD1-ContentLibrary"
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  // OVF Export Settings
  dynamic "export" {
    for_each = false ? [1] : []
    content {
      name  = local.vm_name_standard_desktop
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_name_standard_desktop}"
    }
  }
}

source "vsphere-iso" "windows-server-datacenter-2019-core" {

  // vCenter Server Endpoint Settings and Credentials
  vcenter_server      = "es10vx-w1-vc.central.nyced.org"
  username            = "service.vrovsp@central.nyced.org"
  password            = "!Mck26?U"
  insecure_connection = true

  // vSphere Settings
  datacenter                     = "es00vx-w1-dc"
  cluster                        = "es00vx-w1c1"
  host                           = "es00vx149.central.nyced.org"
  datastore                      = "es00vx-w1c1-vsan"
  folder                         = "Templates Packer"
  #resource_pool                  = "Resources"
  set_host_for_datastore_uploads = false

  // Virtual Machine Settings
  vm_name              = local.vm_name_datacenter_core
  guest_os_type        = "windows2019srv_64Guest"
  firmware             = "efi-secure"
  CPUs                 = 2
  cpu_cores            = 1
  CPU_hot_plug         = true
  RAM                  = 4096
  RAM_hot_plug         = true
  cdrom_type           = "sata"
  disk_controller_type = ["pvscsi"]
  storage {
    disk_size             = 102400
    disk_thin_provisioned = true
  }
  network_adapters {
    network      = "/es00vx-w1-dc/network/es00vx-w1c1-vds02/NSX-S55-10.3.48.0"
    network_card = "vmxnet3"
  }
  vm_version           = 21
  remove_cdrom         = true
  reattach_cdroms      = 1
  tools_upgrade_policy = true
  notes                = local.build_description

  // Removable Media Settings
  iso_paths = false ? [local.iso_paths.content_library, local.iso_paths.tools] : [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/datacenter-core/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
      build_username       = "!admin!"
      build_password       = "!nsecur3"
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = "Windows Server 2019 SERVERDATACENTERCORE"
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  // Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = ["<down><down><tab><enter>"]
  #ip_wait_timeout   = "60s"
  #ip_settle_timeout = "5s"
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  // Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = "!admin!"
  winrm_password = "!nsecur3"
  winrm_port     = 5985
  winrm_timeout  = "12h"

  // Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = true ? [1] : []
    content {
      library     = "es10-WLD1-ContentLibrary"
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  // OVF Export Settings
  dynamic "export" {
    for_each = false ? [1] : []
    content {
      name  = local.vm_name_datacenter_core
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_name_datacenter_core}"
    }
  }
}

source "vsphere-iso" "windows-server-datacenter-2019-dexp" {

  // vCenter Server Endpoint Settings and Credentials
  vcenter_server      = "es10vx-w1-vc.central.nyced.org"
  username            = "service.vrovsp@central.nyced.org"
  password            = "!Mck26?U"
  insecure_connection = true

  // vSphere Settings
  datacenter                     = "es00vx-w1-dc"
  cluster                        = "es00vx-w1c1"
  host                           = "es00vx149.central.nyced.org"
  datastore                      = "es00vx-w1c1-vsan"
  folder                         = "Templates Packer"
  #resource_pool                  = "Resources"
  set_host_for_datastore_uploads = false

  // Virtual Machine Settings
  vm_name              = local.vm_name_datacenter_desktop
  guest_os_type        = "windows2019srv_64Guest"
  firmware             = "efi-secure"
  CPUs                 = 2
  cpu_cores            = 1
  CPU_hot_plug         = true
  RAM                  = 4096
  RAM_hot_plug         = true
  cdrom_type           = "sata"
  disk_controller_type = ["pvscsi"]
  storage {
    disk_size             = 102400
    disk_thin_provisioned = true
  }
  network_adapters {
    network      = "/es00vx-w1-dc/network/es00vx-w1c1-vds02/NSX-S55-10.3.48.0"
    network_card = "vmxnet3"
  }
  vm_version           = 21
  remove_cdrom         = true
  reattach_cdroms      = 1
  tools_upgrade_policy = true
  notes                = local.build_description

  // Removable Media Settings
  iso_paths = false ? [local.iso_paths.content_library, local.iso_paths.tools] : [local.iso_paths.datastore, local.iso_paths.tools]
  cd_files = [
    "${path.cwd}/scripts/windows/datacenter-desk/"
  ]
  cd_content = {
    "autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
      build_username       = "!admin!"
      build_password       = "!nsecur3"
      vm_inst_os_eval      = true
      vm_inst_os_language  = "en-US"
      vm_inst_os_keyboard  = "en-US"
      vm_inst_os_image     = "Windows Server 2019 SERVERDATACENTER"
      vm_inst_os_key       = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
      vm_guest_os_language = "en-US"
      vm_guest_os_keyboard = "en-US"
      vm_guest_os_timezone = "UTC"
    })
  }

  // Boot and Provisioning Settings
  http_port_min     = 8000
  http_port_max     = 8099
  boot_order        = "disk,cdrom"
  boot_wait         = "2s"
  boot_command      = ["<down><down><down><tab><enter>"]
  #ip_wait_timeout   = "60s"
  #ip_settle_timeout = "5s"
  shutdown_command  = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
  shutdown_timeout  = "30s"

  // Communicator Settings and Credentials
  communicator   = "winrm"
  winrm_username = "!admin!"
  winrm_password = "!nsecur3"
  winrm_port     = 5985
  winrm_timeout  = "12h"

  // Template and Content Library Settings
  convert_to_template = true
  dynamic "content_library_destination" {
    for_each = true ? [1] : []
    content {
      library     = "es10-WLD1-ContentLibrary"
      description = local.build_description
      ovf         = true
      destroy     = false
      skip_import = false
    }
  }

  // OVF Export Settings
  dynamic "export" {
    for_each = false ? [1] : []
    content {
      name  = local.vm_name_datacenter_desktop
      force = true
      options = [
        "extraconfig"
      ]
      output_directory = "${local.ovf_export_path}/${local.vm_name_datacenter_desktop}"
    }
  }
}

//  BLOCK: build
//  Defines the builders to run, provisioners, and post-processors.

build {
  sources = [
    "source.vsphere-iso.windows-server-standard-2019-core",
    "source.vsphere-iso.windows-server-standard-2019-dexp",
    "source.vsphere-iso.windows-server-datacenter-2019-core",
    "source.vsphere-iso.windows-server-datacenter-2019-dexp"
  ]
 /*
  provisioner "ansible" {
    user                   = "administrator"
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
      "--extra-vars", "ansible_user=${"administrator"}",
      "--extra-vars", "ansible_password='${"F4Lc0n!NpAraD1C3!"}'",
      "--extra-vars", "ansible_port='${5985}'",
      "--extra-vars", "build_username='${"administrator"}'",
    ]
  }
 
  post-processor "manifest" {
    output     = local.manifest_output
    strip_path = true
    strip_time = true
    custom_data = {
      build_username           = "administrator"
      build_date               = local.build_date
      build_version            = local.build_version
      common_data_source       = "disk"
      common_vm_version        = 21
      vm_cpu_cores             = 1
      vm_cpu_count             = 2
      vm_disk_size             = 102400
      vm_disk_thin_provisioned = true
      vm_firmware              = "efi-secure"
      vm_guest_os_type         = "windows2019srv_64Guest"
      vm_mem_size              = 4096
      vm_network_card          = "vmxnet3"
      vsphere_cluster          = "00-w01-cl01"
      vsphere_host             = "p01viw252p.mgmmirage.org"
      vsphere_datacenter       = "00-w01-dc01"
      vsphere_datastore        = "00-w01-cl01-ds-vsan01"
      vsphere_endpoint         = "v00aiwvcsa01p.mgmmirage.org"
      vsphere_folder           = "Templates Packer"
    }
  }
*/
  dynamic "hcp_packer_registry" {
    for_each = false ? [1] : []
    content {
      bucket_name = local.bucket_name
      description = local.bucket_description
      bucket_labels = {
        "os_family" : var.vm_guest_os_family,
        "os_name" : var.vm_guest_os_name,
        "os_version" : var.vm_guest_os_version,
      }
      build_labels = {
        "build_version" : local.build_version,
        "packer_version" : packer.version,
      }
    }
  }
}
