# Copyright 2023-2024 Broadcom. All Rights Reserved.
# SPDX-License-Identifier: BSD-2

<#
    .DESCRIPTION
    Set tmp network configuration on Windows builds.
#>

$ErrorActionPreference = 'Stop'

# Set the static IP address, subnet mask, and default gateway
Write-Output 'Setting the static IP address, subnet mask, and default gateway...'
Write-Output $(netsh interface ipv4 show addresses)
netsh interface ipv4 set address "$((get-netadapter).Name)" static "10.3.49.244" "255.255.255.0" "10.3.49.1"
netsh interface ipv4 add dnsserver "$((get-netadapter).Name)" address=10.213.20.26 index=1
netsh interface ipv4 add dnsserver "$((get-netadapter).Name)" address=10.213.28.26 index=2
Write-Output $(netsh interface ipv4 show addresses)