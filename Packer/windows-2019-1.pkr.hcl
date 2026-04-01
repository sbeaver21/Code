# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "vsphere-iso" "example_windows" {
  CPUs                 = 1
  RAM                  = 4096
  RAM_reserve_all      = true
  communicator         = "winrm"
  disk_controller_type = ["pvscsi"]
  //floppy_files         = ["${path.root}/setup/"]
  //floppy_img_path      = "[datastore1] ISO/VMware Tools/10.2.0/pvscsi-Windows8.flp"
  guest_os_type        = "windows9_64Guest"
  host                 = "p01vim001p.mgmmirage.org"
  datacenter           = "00-m01-dc01"
  cluster              = "00-m01-cl01"
  insecure_connection  = "true"
  iso_paths            = ["[00-m01-cl01-ds-vsan01] e197fe64-140a-acd4-84ea-bc97e1bc5e26/windows2019.iso", "[00-m01-cl01-ds-vsan01] d69beb65-2c11-21f3-bfcd-bc97e1bc1086/c08c1fac-e126-46b1-81bf-f00536530122/VMware-tools-windows-12.3.0-22234872_b4315db0-1a32-436a-8e71-2600267b51c4.iso"]
  network_adapters {
    network_card = "vmxnet3"
    network      = "m00-areg"
  }
  password = "Ch@ng3me123!@#"
  storage {
    disk_size             = 32768
    disk_thin_provisioned = true
  }
  username       = "stephen.beaver@vsphere.local"
  vcenter_server = "v00aimvcsa01p.mgmmirage.org"
  vm_name        = "example-windows"
  winrm_password = "F4Lc0n!NpAraD1C3!"
  winrm_username = "administrator"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.vsphere-iso.example_windows"]

  provisioner "windows-shell" {
    inline = ["dir c:\\"]
  }
}