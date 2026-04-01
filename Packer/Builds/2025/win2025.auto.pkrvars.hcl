# ----------------------------------------------------------------------------
# Name:         win2025.auto.pkrvars.hcl
# Description:  Required vSphere variables for Windows 2025 Packer builds
# Author:       Stephen Beaver
# ----------------------------------------------------------------------------

// vSphere Credentials

vsphere_endpoint = "es10vx-w1-vc.central.nyced.org"
vsphere_username = "service.vrovsp@central.nyced.org"
vsphere_password = "!Mck26?U"
vsphere_insecure_connection = true

// vSphere Settings

vsphere_datacenter = "es00vx-w1-dc"
vsphere_cluster = "es00vx-w1c1"
//vsphere_host = "es00vx102.central.nyced.org"
vsphere_datastore = "es00vx-w1c1-vsan"
vsphere_network = "/es00vx-w1-dc/network/es00vx-w1c1-vds02/NSX-S55-10.3.49.0"
vsphere_folder = "Templates Packer"
//vsphere_resource_pool = ""
vsphere_set_host_for_datastore_uploads = false

// Installer Settings

vm_inst_os_language = "en-US"
vm_inst_os_keyboard = "en-US"
vm_inst_os_eval = true
vm_inst_os_image_standard_core = "Windows Server 2025 SERVERSTANDARDCORE"
vm_inst_os_image_standard_desktop = "Windows Server 2025 SERVERSTANDARD"
vm_inst_os_key_standard = "<down><tab><enter>"
vm_inst_os_image_datacenter_core = "Windows Server 2025 SERVERDATACENTERCORE"
vm_inst_os_image_datacenter_desktop = "Windows Server 2025 SERVERDATACENTER"
vm_inst_os_key_datacenter = "<down><down><down><tab><enter>"

// Virtual Machine Settings

vm_guest_os_language = "en-US"
vm_guest_os_keyboard = "en-US"
vm_guest_os_timezone = "Eastern Standard Time"
vm_guest_os_family = "windows"
vm_guest_os_name = "server"
vm_guest_os_version = "2025"
vm_guest_os_edition_standard = "standard"
vm_guest_os_edition_datacenter = "datacenter"
vm_guest_os_experience_core = "core"
vm_guest_os_experience_desktop = "dexp"
//vm_guest_os_systemlocale = "en-US"
vm_guest_os_type = "windows2022srvNext_64Guest"
vm_firmware = "efi-secure"
//vm_cdrom_remove = false 
vm_cdrom_type = "sata"
vm_cdrom_count = 1
vm_cpu_count = 2
vm_cpu_cores = 2
vm_cpu_hot_add = true
vm_mem_size = 4096
vm_mem_hot_add = true
vm_disk_size = 102400
vm_disk_controller_type = ["pvscsi"]
vm_disk_thin_provisioned = true
vm_nic_type = "vmxnet3"
vm_shutdown_timeout = "900s"

// Template and Content Library Settings

common_vm_version = 21
common_tools_upgrade_policy = true
common_remove_cdrom = false
common_reattach_cdroms = 1
common_template_conversion = true
common_content_library_enabled = true
common_content_library = "es10-WLD1-ContentLibrary"
common_content_library_ovf = true
common_content_library_destroy = true
common_content_library_skip_export = false

// OVF Export Settings

common_ovf_export_enabled = true
common_ovf_export_overwrite = true

// Removable Media Settings

common_iso_content_library_enabled = false
common_iso_content_library = "es10-WLD1-ContentLibrary"
common_iso_datastore = "es00vx-w1c1-vsan"
iso_datastore_path = "efa1d460-90f1-8300-1738-0c42a1cbef98"
iso_file = "SW_DVD9_Win_Server_STD_CORE_2025_24H2_64Bit_English_DC_STD_MLF_X23-81891.ISO"
iso_content_library_item = "es10-WLD1-ContentLibrary/SW_DVD9_Win_Server_STD_CORE_2025_24H2_64Bit_English_DC_STD_MLF_X23-81891.iso"

// Boot Settings

common_data_source = "disk"
common_http_ip = null
common_http_port_min = 8000
common_http_port_max = 8800
vm_boot_order = "disk,cdrom"
vm_boot_wait = "2s"
vm_boot_command = ["<spacebar>"]
vm_shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Shutdown by Packer\""
common_ip_wait_timeout = "120s"
common_ip_settle_timeout = "10s"
common_shutdown_timeout = "900s"

// Communicator Settings and Credentials

build_username = "!admin!"
build_password = "!nsecur3"
//admin_username = "administrator"
//admin_password = "Welcome.123"
build_password_encrypted = ""
build_key = ""

// Communicator Credentials

communicator_port = 5985
communicator_timeout = "120s"

// Ansible Credentials

ansible_username = ""
ansible_key = ""

// Provisioner Settings

scripts = ["echo 'Setting network back to DHCP'","powershell -File 'C:/CD/dhcp-network.ps1'"]
inline = ["echo 'Y' | powershell Get-PackageProvider -Name 'NuGet'",
          "echo 'Y' | powershell Get-PackageProvider -Name 'PowerShellGet'",
		  "Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted' -ErrorAction Continue",
		  "Get-WmiObject -Class Win32_volume -Filter 'DriveType=5' | Where-Object -Property 'DriveLetter' -eq 'F:'| Set-WmiInstance -Arguments @{DriveLetter='Z:'}",
		  "Start-Process powershell -Wait -Verb RunAs -ArgumentList '-NoProfile', '-Command', 'Get-NetAdapterBinding -ComponentID ms_tcpip6 | Disable-NetAdapterBinding'",
		  "Start-Process Powershell.exe -Wait -Verb RunAs -ArgumentList 'Set-ExecutionPolicy Bypass -Scope Process -Force; C:/Temp/Check-hardening-server-v2.ps1'",
		  "Start-Process Powershell.exe -Wait -Verb RunAs -ArgumentList 'Set-ExecutionPolicy Bypass -Scope Process -Force; C:/Temp/Auto-FullVulnerabilityHardening-v2.ps1'"]

// HCP Packer Settings

common_hcp_packer_registry_enabled = false