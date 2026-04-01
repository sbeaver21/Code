# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# "timestamp" template function replacement
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are analogous to the "builders" in json templates. They are used
# in build blocks. A build block runs provisioners and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "vsphere-clone" "example_clone" {
  communicator        = "none"
  host                = "p01vim001p.mgmmirage.org"
  datacenter          = "00-m01-dc01"
  cluster             = "00-m01-cl01"
  folder              = "00-m01-templates"
  #resource_pool       = "Resources"
  datastore           = "00-m01-cl01-ds-vsan01"
  insecure_connection = "true"
  password            = "Ch@ng3me123!@#"
  template            = "Win_2022_Patch_2024-7_Standard_Base"
  username            = "stephen.beaver@vsphere.local"
  vcenter_server      = "v00aimvcsa01p.mgmmirage.org"
  vm_name             = "alpine-clone-${local.timestamp}"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  # use the `name` field to name a build in the logs.
  # For example this present config will display
  # "buildname.amazon-ebs.example-1" and "buildname.amazon-ebs.example-2"
  name = "vrabuild"
  sources = ["source.vsphere-clone.example_clone"]

}