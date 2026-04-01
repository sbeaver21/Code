# Packer Variables File
# This file contains environment-specific configuration values
# DO NOT commit this file to version control if it contains sensitive data

# vCenter Server Configuration
vcenter_server = "es10vx-w1-vc.central.nyced.org"
vcenter_username = "service.vrovsp@central.nyced.org"
vcenter_password = "!Mck26?U"

# vSphere Infrastructure
datacenter = "es00vx-w1-dc"
cluster = "es00vx-w1c1"
datastore = "es00vx-w1c1-vsan"
folder = "Templates Packer"
network_name = "/es00vx-w1-dc/network/es00vx-w1c1-vds02/NSX-S55-10.3.48.0"
content_library = "es10-WLD1-ContentLibrary"

# Windows VM Configuration
build_username = "!admin!"
build_password = "!nsecur3"
build_version = "001"

# Feature Flags
enable_ovf_export = false
enable_content_library = true