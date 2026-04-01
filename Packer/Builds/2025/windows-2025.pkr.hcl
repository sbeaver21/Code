# ----------------------------------------------------------------------------
# Name:         win2025.pkr.hcl
# Description:  Build definition for Windows 2025
# Author:       Stephen Beaver
# Date:         9/14/2025 
# ----------------------------------------------------------------------------

# -------------------------------------------------------------------------- #
#                           Packer Configuration                             #
# -------------------------------------------------------------------------- #
packer {
    required_version = ">= 1.14.0"
    required_plugins {
        vsphere = {
            version = ">= 1.4.2"
            source  = "github.com/hashicorp/vsphere"
        }
    }
    required_plugins {
        windows-update = {
            version = ">= 0.16.10"
            source  = "github.com/rgl/windows-update"
        }
    }
}

# -------------------------------------------------------------------------- #
#                              Local Variables                               #
# -------------------------------------------------------------------------- #
locals { 
    build_by          = "Imaged by: HashiCorp Packer ${packer.version}"
    build_create      = "Created by: NYC - DoE - DIIT"
    build_datetime    = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
    build_date        = formatdate("YYYY-MM-DD", timestamp())
    build_time        = formatdate("hh:mm ZZZ", timestamp())
    build_version     = "packer"
    build_description = "${local.build_create}\nImaged on: ${local.build_date}\nImage Time: ${ local.build_time }\nImage Version: ${ local.build_datetime }\n${local.build_by}"
    core_std_content            = {
                                    #"Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/builds/windows/server/2025/data/autounattend.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password  
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = var.vm_inst_os_image_standard_core
                                        vm_inst_os_key            = var.vm_inst_os_key_standard
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_name          = "WIN-25-STD-CORE"
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone                                        
                                    })
                                  }
    dexp_std_content            = {
                                    #"Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/builds/windows/server/2025/data/autounattend.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = var.vm_inst_os_image_standard_desktop
                                        vm_inst_os_key            = var.vm_inst_os_key_standard
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_name          = "WIN-25-STD-DEXP"
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone
                                    })
                                  }
	core_dc_content             = {
                                    #"Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/builds/windows/server/2025/data/autounattend.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = var.vm_inst_os_image_datacenter_core
                                        vm_inst_os_key            = var.vm_inst_os_key_datacenter
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_name          = "WIN-25-DC-CORE"
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone
                                    })
                                  }
    dexp_dc_content             = {
                                    #"Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend.pkrtpl.hcl", {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/builds/windows/server/2025/data/autounattend.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = var.vm_inst_os_image_datacenter_desktop
                                        vm_inst_os_key            = var.vm_inst_os_key_datacenter
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_name          = "WIN-25-DC-DEXP"
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone
                                    })
                                  }
    vm_description              = "${local.build_create}\nImaged on: ${local.build_date}\nImage Time: ${ local.build_time }\nImage Version: ${ local.build_datetime }\n${local.build_by}"
}

# -------------------------------------------------------------------------- #
#                       Template Source Definitions                          #
# -------------------------------------------------------------------------- #
#source "vsphere-iso" "win2022stddexp" {
source "vsphere-iso" "windows-server-standard-2025-core" {

    # vCenter
    vcenter_server              = var.vsphere_endpoint
    username                    = var.vsphere_username
    password                    = var.vsphere_password
    insecure_connection         = var.vsphere_insecure_connection
    datacenter                  = var.vsphere_datacenter
    cluster                     = var.vsphere_cluster
    folder                      = var.vsphere_folder
    datastore                   = var.vsphere_datastore

    # Content Library and Template Settings
    convert_to_template         = var.common_template_conversion
    dynamic "content_library_destination" {
        for_each = var.common_content_library != null ? [1] : []
            content {
                library         = var.common_content_library
                name            = "${ source.name }"
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine 
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = "WIN-25-STD-CORE"
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
    disk_controller_type        = var.vm_disk_controller_type
    storage {
        disk_size               = var.vm_disk_size
        disk_thin_provisioned   = var.vm_disk_thin_provisioned
    }
    network_adapters {
        network                 = var.vsphere_network
        network_card            = var.vm_nic_type
    }

    # Removeable Media
    iso_paths                   = [ "[${ var.common_iso_datastore }] ${ var.iso_datastore_path }/${ var.iso_file }", "[] /vmimages/tools-isoimages/windows.iso" ]
    cd_files                    = [ "${path.cwd}/scripts/windows/standard-core/" ]
    floppy_content              = local.core_std_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = [ "<spacebar>" ]
    #ip_wait_timeout             = var.common_ip_wait_timeout
    communicator                = "winrm"
    winrm_username              = var.build_username
    winrm_password              = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

#source "vsphere-iso" "win2022stddexp" {
source "vsphere-iso" "windows-server-standard-2025-dexp" {

    # vCenter
    vcenter_server              = var.vsphere_endpoint
    username                    = var.vsphere_username
    password                    = var.vsphere_password
    insecure_connection         = var.vsphere_insecure_connection
    datacenter                  = var.vsphere_datacenter
    cluster                     = var.vsphere_cluster
    folder                      = var.vsphere_folder
    datastore                   = var.vsphere_datastore

    # Content Library and Template Settings
    convert_to_template         = var.common_template_conversion
    dynamic "content_library_destination" {
        for_each = var.common_content_library != null ? [1] : []
            content {
                library         = var.common_content_library
                name            = "${ source.name }"
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = "WIN-25-STD-DEXP"
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
    disk_controller_type        = var.vm_disk_controller_type
    storage {
        disk_size               = var.vm_disk_size
        disk_thin_provisioned   = var.vm_disk_thin_provisioned
    }
    network_adapters {
        network                 = var.vsphere_network
        network_card            = var.vm_nic_type
    }

    # Removeable Media
    iso_paths                   = [ "[${ var.common_iso_datastore }] ${ var.iso_datastore_path }/${ var.iso_file }", "[] /vmimages/tools-isoimages/windows.iso" ]
    cd_files                    = [ "${path.cwd}/scripts/windows/standard-dexp/" ]
    floppy_content              = local.dexp_std_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = ["<down><tab><enter>"]
    #ip_wait_timeout             = var.common_ip_wait_timeout
    communicator                = "winrm"
    winrm_username              = var.build_username
    winrm_password              = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

#source "vsphere-iso" "win2022stdcore" {
source "vsphere-iso" "windows-server-datacenter-2025-core" {
    # vCenter
    vcenter_server              = var.vsphere_endpoint
    username                    = var.vsphere_username
    password                    = var.vsphere_password
    insecure_connection         = var.vsphere_insecure_connection
    datacenter                  = var.vsphere_datacenter
    cluster                     = var.vsphere_cluster
    folder                      = var.vsphere_folder
    datastore                   = var.vsphere_datastore

    # Content Library and Template Settings
    convert_to_template         = var.common_template_conversion
    dynamic "content_library_destination" {
        for_each = var.common_content_library != null ? [1] : []
            content {
                library         = var.common_content_library
                name            = "${ source.name }"
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = "WIN-25-DC-CORE"
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
    disk_controller_type        = var.vm_disk_controller_type
    storage {
        disk_size               = var.vm_disk_size
        disk_thin_provisioned   = var.vm_disk_thin_provisioned
    }
    network_adapters {
        network                 = var.vsphere_network
        network_card            = var.vm_nic_type
    }

    # Removeable Media
    iso_paths                   = [ "[${ var.common_iso_datastore}] ${ var.iso_datastore_path }/${ var.iso_file }", "[] /vmimages/tools-isoimages/windows.iso" ]
    cd_files                    = [ "${path.cwd}/scripts/windows/datacenter-core/" ]
    floppy_content              = local.core_dc_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = ["<down><down><tab><enter>"]
    #ip_wait_timeout             = var.common_ip_wait_timeout
    communicator                = "winrm"
    winrm_username              = var.build_username
    winrm_password              = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

#source "vsphere-iso" "win2022stdcore" {
source "vsphere-iso" "windows-server-datacenter-2025-dexp" {
    # vCenter
    vcenter_server              = var.vsphere_endpoint
    username                    = var.vsphere_username
    password                    = var.vsphere_password
    insecure_connection         = var.vsphere_insecure_connection
    datacenter                  = var.vsphere_datacenter
    cluster                     = var.vsphere_cluster
    folder                      = var.vsphere_folder
    datastore                   = var.vsphere_datastore

    # Content Library and Template Settings
    convert_to_template         = var.common_template_conversion
    dynamic "content_library_destination" {
        for_each = var.common_content_library != null ? [1] : []
            content {
                library         = var.common_content_library
                name            = "${ source.name }"
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = "WIN-25-DC-DEXP"
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
    disk_controller_type        = var.vm_disk_controller_type
    storage {
        disk_size               = var.vm_disk_size
        disk_thin_provisioned   = var.vm_disk_thin_provisioned
    }
    network_adapters {
        network                 = var.vsphere_network
        network_card            = var.vm_network_card
    }

    # Removeable Media
    iso_paths                   = [ "[${ var.common_iso_datastore }] ${ var.iso_datastore_path }/${ var.iso_file }", "[] /vmimages/tools-isoimages/windows.iso" ]
    cd_files                    = [ "${path.cwd}/scripts/windows/datacenter-dexp/" ]
    floppy_content              = local.dexp_dc_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = ["<down><down><down><tab><enter>"]
    #ip_wait_timeout             = var.common_ip_wait_timeout
    communicator                = "winrm"
    winrm_username              = var.build_username
    winrm_password              = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

# -------------------------------------------------------------------------- #
#                             Build Management                               #
# -------------------------------------------------------------------------- #
build {
    # Build sources
    sources                 = [ "source.vsphere-iso.windows-server-standard-2025-core",
								"source.vsphere-iso.windows-server-standard-2025-dexp",
								"source.vsphere-iso.windows-server-datacenter-2025-core",
								"source.vsphere-iso.windows-server-datacenter-2025-dexp"]
    
    # Windows Update using https://github.com/rgl/packer-provisioner-windows-update
    provisioner "windows-update" {
        pause_before        = "30s"
        search_criteria     = "IsInstalled=0"
        filters             = [ "exclude:$_.Title -like '*VMware*'",
                                "exclude:$_.Title -like '*Preview*'",
                                "exclude:$_.Title -like '*Defender*'",
                                "exclude:$_.InstallationBehavior.CanRequestUserInput",
                                "include:$true" ]
        restart_timeout     = "120m"
    }      
    
    # PowerShell Provisioner to execute scripts 
    #provisioner "powershell" {
    #    elevated_user       = var.build_username
    #    elevated_password   = var.build_password
    #    scripts             = var.script_files
    #    environment_vars    = [ "PKISERVER=${ var.build_pkiserver }",
    #                            "ANSIBLEUSER=${ var.build_ansible_user }",
    #                            "ANSIBLEKEY=${ var.build_ansible_key }",
    #                            "BUILDUSER=${ var.build_username }",
    #                            "BUILDPASS=${ var.build_password }" ]
    #}

    # PowerShell Provisioner to execute commands
    provisioner "powershell" {
        elevated_user       = "SYSTEM"
        elevated_password   = ""
        inline              = var.inline
    }

#    post-processor "manifest" {
#        output              = "manifest.txt"
#        strip_path          = true
#        custom_data         = {
#            vcenter_fqdn    = var.vcenter_endpoint
#            vcenter_folder  = var.vcenter_folder
#            iso_file        = var.iso_file
#            build_repo      = var.build_repo
#            build_branch    = var.build_branch
#            build_version   = local.build_version
#            build_date      = local.build_date
#        }
#    }
}