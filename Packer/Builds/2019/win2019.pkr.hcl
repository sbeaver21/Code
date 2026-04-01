# ----------------------------------------------------------------------------
# Name:         win2019.pkr.hcl
# Description:  Build definition for Windows 2019
# Author:       Stephen Beaver
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
        salt = {
            version = ">=0.5.0"
            source  = "github.com/mpoore/salt"
		    }
        git = {
		    version = ">= 0.6.5"
            source  = "github.com/ethanmdavidson/git"    
        }		
    }
}

# -------------------------------------------------------------------------- #
#                              Local Variables                               #
# -------------------------------------------------------------------------- #

locals { 
    build_by                    = "Imaged by: HashiCorp Packer ${packer.version}"
    build_create                = "Created by: NYC - DoE - DIIT"
    build_datetime              = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
    build_date                  = formatdate("YYYY-MM-DD", timestamp())
    build_time                  = formatdate("hh:mm ZZZ", timestamp())
    build_version               = "packer"
	manifest_date               = formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())
    manifest_path               = "${path.cwd}/manifests/"
    manifest_output             = "${local.manifest_path}${local.manifest_date}.json"
    ovf_export_path             = "${path.cwd}/artifacts/"
    vm_name                     = "windows-server-2019"
	vm_name_datacenter_core     = "windows-server-2019-datacenter-core-${local.build_version}"
    vm_name_datacenter_dexp     = "windows-server-2019-datacenter-dexp-${local.build_version}"
    vm_name_standard_core       = "windows-server-2019-standard-core-${local.build_version}"
    vm_name_standard_dexp       = "windows-server-2019-standard-dexp-${local.build_version}"
    build_description           = "${local.build_create}\nImaged on: ${local.build_date}\nImage Time: ${ local.build_time }\nImage Version: ${ local.build_datetime }\n${local.build_by}"
    core_std_content            = {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend19.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password   
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = "Windows Server 2019 SERVERSTANDARDCORE"
                                        vm_inst_os_key            = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone
										vm_guest_os_name          = "WIN-19-STD-CORE"
                                        vm_windows_image          = "SERVERSTANDARDCORE"
                                    })
                                  }
    dexp_std_content            = {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend19.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = "Windows Server 2019 SERVERSTANDARD"
                                        vm_inst_os_key            = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone
										vm_guest_os_name          = "WIN-19-STD-DEXP"
                                        vm_windows_image          = "SERVERSTANDARD"
                                    })
                                  }
	core_dc_content             = {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend19.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = "Windows Server 2019 SERVERDATACENTERCORE"
                                        vm_inst_os_key            = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone
										vm_guest_os_name          = "WIN-19-DC-CORE"
                                        vm_windows_image          = "SERVERDATACENTERCORE"
                                    })
                                  }
    dexp_dc_content             = {
                                    "Autounattend.xml" = templatefile("${abspath(path.root)}/data/autounattend19.pkrtpl.hcl", {
                                        build_username            = var.build_username
                                        build_password            = var.build_password
										vm_inst_os_eval           = var.vm_inst_os_eval
										vm_inst_os_language       = var.vm_inst_os_language
                                        vm_inst_os_keyboard       = var.vm_inst_os_keyboard
										vm_inst_os_image          = "Windows Server 2019 SERVERDATACENTER"
                                        vm_inst_os_key            = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
                                        vm_guest_os_language      = var.vm_guest_os_language
                                        vm_guest_os_keyboard      = var.vm_guest_os_keyboard
                                        vm_guest_os_timezone      = var.vm_guest_os_timezone
										vm_guest_os_name          = "WIN-19-DC-DEXP"
                                        vm_windows_image          = "SERVERDATACENTER"
                                    })
                                  }
    vm_description              = "${local.build_create}\nImaged on: ${local.build_date}\nImage Time: ${ local.build_time }\nImage Version: ${ local.build_datetime }\n${local.build_by}"
}

# -------------------------------------------------------------------------- #
#                       Template Source Definitions                          #
# -------------------------------------------------------------------------- #

source "vsphere-iso" "windows-server-2019-standard-core" {

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
                name            = local.vm_name_standard_core
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine 
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = local.vm_name_standard_core
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
	reattach_cdroms             = var.common_reattach_cdroms
	tools_upgrade_policy        = var.common_tools_upgrade_policy
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
    cd_files                    = [ "${abspath(path.root)}/standard-core/", "${abspath(path.root)}/cd_files/"]
    floppy_content              = local.core_std_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = [ "<spacebar><enter>" ]
    #ip_wait_timeout            = var.common_ip_wait_timeout
    communicator                = "ssh"
    ssh_username                = var.build_username
    ssh_password                = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

source "vsphere-iso" "windows-server-2019-standard-dexp" {

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
                name            = local.vm_name_standard_dexp
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = local.vm_name_standard_dexp
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
	reattach_cdroms             = var.common_reattach_cdroms
	tools_upgrade_policy        = var.common_tools_upgrade_policy
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
    cd_files                    = [ "${abspath(path.root)}/standard-dexp/", "${abspath(path.root)}/cd_files/"]
    floppy_content              = local.dexp_std_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = ["<down><tab><enter>"]
    #ip_wait_timeout            = var.common_ip_wait_timeout
    communicator                = "ssh"
    ssh_username                = var.build_username
    ssh_password                = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

source "vsphere-iso" "windows-server-2019-datacenter-core" {
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
                name            = local.vm_name_datacenter_core
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = local.vm_name_datacenter_core
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
	reattach_cdroms             = var.common_reattach_cdroms
	tools_upgrade_policy        = var.common_tools_upgrade_policy
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
    cd_files                    = [ "${abspath(path.root)}/datacenter-core/", "${abspath(path.root)}/cd_files/"]
    floppy_content              = local.core_dc_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = ["<down><down><tab><enter>"]
    #ip_wait_timeout            = var.common_ip_wait_timeout
    communicator                = "ssh"
    ssh_username                = var.build_username
    ssh_password                = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

source "vsphere-iso" "windows-server-2019-datacenter-dexp" {
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
                name            = local.vm_name_datacenter_dexp
                description     = local.vm_description
                ovf             = var.common_content_library_ovf
                destroy         = var.common_content_library_destroy
                skip_import     = var.common_content_library_skip_export
            }
    }

    # Virtual Machine
    guest_os_type               = var.vm_guest_os_type
    vm_name                     = local.vm_name_datacenter_dexp
    notes                       = local.vm_description
    firmware                    = var.vm_firmware
    CPUs                        = var.vm_cpu_count
    cpu_cores                   = var.vm_cpu_cores
    CPU_hot_plug                = var.vm_cpu_hot_add
    RAM                         = var.vm_mem_size
    RAM_hot_plug                = var.vm_mem_hot_add
    cdrom_type                  = var.vm_cdrom_type
    remove_cdrom                = var.common_remove_cdrom
	reattach_cdroms             = var.common_reattach_cdroms
	tools_upgrade_policy        = var.common_tools_upgrade_policy
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
    cd_files                    = [ "${abspath(path.root)}/datacenter-dexp/", "${abspath(path.root)}/cd_files/"]
    floppy_content              = local.dexp_dc_content

    # Boot and Provisioner
    boot_order                  = var.vm_boot_order
    boot_wait                   = var.vm_boot_wait
    boot_command                = ["<down><down><down><tab><enter>"]
    #ip_wait_timeout            = var.common_ip_wait_timeout
    communicator                = "ssh"
    ssh_username                = var.build_username
    ssh_password                = var.build_password
    shutdown_command            = var.vm_shutdown_command
    shutdown_timeout            = var.common_shutdown_timeout
}

# -------------------------------------------------------------------------- #
#                             Build Management                               #
# -------------------------------------------------------------------------- #

build {
    # Build sources
    sources                 = [ 
                                "source.vsphere-iso.windows-server-2019-standard-core",
								"source.vsphere-iso.windows-server-2019-standard-dexp",
								"source.vsphere-iso.windows-server-2019-datacenter-core",
								"source.vsphere-iso.windows-server-2019-datacenter-dexp"
                              ]
    
    # Windows Update using https://github.com/rgl/packer-provisioner-windows-update
    provisioner "windows-update" {
        #pause_before        = "30s"
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
	
#	# PowerShell Provisioner to execute commands
#    provisioner "powershell" {
#        elevated_user       = "SYSTEM"
#        elevated_password   = ""
#        inline              = var.scripts
#    }
#
    post-processor "manifest" {
      output     = local.manifest_output
      strip_path = true
      strip_time = true
      custom_data = {
        build_username           = var.build_username
        build_date               = local.build_date
        build_version            = local.build_version
        common_data_source       = var.common_data_source
        common_vm_version        = var.common_vm_version
        vm_cpu_cores             = var.vm_cpu_cores
        vm_cpu_count             = var.vm_cpu_count
        vm_disk_size             = var.vm_disk_size
        vm_disk_thin_provisioned = var.vm_disk_thin_provisioned
        vm_firmware              = var.vm_firmware
        vm_guest_os_type         = var.vm_guest_os_type
        vm_mem_size              = var.vm_mem_size
        vm_network_card          = var.vm_network_card
        vsphere_cluster          = var.vsphere_cluster
        vsphere_datacenter       = var.vsphere_datacenter
        vsphere_datastore        = var.vsphere_datastore
        vsphere_endpoint         = var.vsphere_endpoint
      }
    }
}