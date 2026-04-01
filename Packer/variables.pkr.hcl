# Copyright 2023-2024 Broadcom. All rights reserved.
# SPDX-License-Identifier: BSD-2

/*
    DESCRIPTION:
    Microsoft Windows Server 2019 input variables.
    Packer Plugin for VMware vSphere: 'vsphere-iso' builder.
*/

//  BLOCK: variable
//  Defines the input variables.

// vSphere Credentials

vsphere_endpoint = "v00aimvcsa01p.mgmmirage.org"

vsphere_username = "stephen.beaver@vsphere.local"

vsphere_password = "Ch@ng3me123!@#"

vsphere_insecure_connection = true

// vSphere Settings

vsphere_datacenter = "00-m01-dc01"

vsphere_cluster = "00-m01-cl01"

vsphere_host = "p01vim001p.mgmmirage.org"

vsphere_datastore = "00-m01-cl01-ds-vsan01"

vsphere_network = "00-m01-cl01-vds0-pg-mgmt-DVPG"

vsphere_folder = "00-m01-templates"

vsphere_resource_pool = "Resources"

vsphere_set_host_for_datastore_uploads = false

// Installer Settings

vm_inst_os_language = "en-US"

vm_inst_os_keyboard = "en-US"

vm_inst_os_eval = true

vm_inst_os_image_standard_core = "Windows Server 2019 SERVERSTANDARDCORE"

vm_inst_os_image_standard_desktop = "Windows Server 2019 SERVERSTANDARD"


vm_inst_os_key_standard = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"

vm_inst_os_image_datacenter_core = "Windows Server 2019 SERVERDATACENTERCORE"

vm_inst_os_image_datacenter_desktop = "Windows Server 2019 SERVERDATACENTER"


vm_inst_os_key_datacenter = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"

// Virtual Machine Settings

vm_guest_os_language = "en-US"

vm_guest_os_keyboard = "en-US"

vm_guest_os_timezone = "UTC"

vm_guest_os_family = "windows"

vm_guest_os_name = "server"

vm_guest_os_version = "2019"

vm_guest_os_edition_standard = "standard"

vm_guest_os_edition_datacenter = "datacenter"

vm_guest_os_experience_core = "core"

vm_guest_os_experience_desktop = "dexp"

vm_guest_os_type = "windows9_64Guest"

vm_firmware = "efi-secure"

vm_cdrom_type = "sata"

vm_cdrom_count = 1

vm_cpu_count = 2

vm_cpu_cores = 1

vm_cpu_hot_add = false

vm_mem_size = 4096

vm_mem_hot_add = false

vm_disk_size = 102400

vm_disk_controller_type = ["pvscsi"]

vm_disk_thin_provisioned = true

vm_network_card = "vmxnet3"

common_vm_version = 21

common_tools_upgrade_policy = true

common_remove_cdrom = true

// Template and Content Library Settings

common_template_conversion = false

common_content_library_enabled = true


common_content_library = "content-library-00-m01-cl01"

common_content_library_ovf = true

common_content_library_destroy = true

common_content_library_skip_export = false

// OVF Export Settings

common_ovf_export_enabled = false

common_ovf_export_overwrite = true

// Removable Media Settings

common_iso_content_library_enabled = false

common_iso_content_library = "content-library-00-m01-cl01"

common_iso_datastore = "00-m01-cl01-ds-vsan01"

iso_datastore_path = "[00-m01-cl01-ds-vsan01] e197fe64-140a-acd4-84ea-bc97e1bc5e26/windows2019.iso"

iso_file = "windows2019.iso"

iso_content_library_item = "[00-m01-cl01-ds-vsan01] d69beb65-2c11-21f3-bfcd-bc97e1bc1086/c08c1fac-e126-46b1-81bf-f00536530122/VMware-tools-windows-12.3.0-22234872_b4315db0-1a32-436a-8e71-2600267b51c4.iso"

// Boot Settings

common_data_source = "disk"

common_http_ip = null

common_http_port_min = 80

common_http_port_max = 443

vm_boot_order = "disk,cdrom"

vm_boot_wait = "2s"

vm_boot_command = ["<spacebar>"]

vm_shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""

common_ip_wait_timeout = "60s"

common_ip_settle_timeout = "5s"

common_shutdown_timeout = "30s"

// Communicator Settings and Credentials

build_username = administrator

build_password = "F4Lc0n!NpAraD1C3!"

build_password_encrypted = ""

build_key = ""

// Communicator Credentials

communicator_port = 5985

communicator_timeout = "12h"

// Ansible Credentials

ansible_username = "anisble"

ansible_key = "password"

// Provisioner Settings

scripts = []


inline = []

// HCP Packer Settings

common_hcp_packer_registry_enabled = false

