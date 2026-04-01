# © Broadcom. All Rights Reserved.
# The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries.
# SPDX-License-Identifier: BSD-2-Clause

<#
    .DESCRIPTION
    Enables Windows Remote Management on Windows builds.
#>

$ErrorActionPreference = 'Stop'

# Set network connections provile to Private mode.
Write-Output 'Setting the network connection profiles to Private...'
$connectionProfile = Get-NetConnectionProfile
While ($connectionProfile.Name -eq 'Identifying...') {
    Start-Sleep -Seconds 10
    $connectionProfile = Get-NetConnectionProfile
}
Set-NetConnectionProfile -Name $connectionProfile.Name -NetworkCategory Private

# Set the Windows Remote Management configuration.
Write-Output 'Setting the Windows Remote Management configuration...'
winrm quickconfig -quiet
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Allow Windows Remote Management in the Windows Firewall.
Write-Output 'Allowing Windows Remote Management in the Windows Firewall...'
netsh advfirewall firewall set rule group="Windows Remote Administration" new enable=yes
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=allow

# Reset the autologon count. Reference: https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0

# Enable RDP configuration via the egistry
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0
Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services\Client' -Name fClientDisableUDP -Value 0

# Firewall
New-NetFirewallRule -DisplayName "RDP (TCP)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389 -RemoteAddress $RemoteAddress -Profile Any -Enabled True | Out-Null
New-NetFirewallRule -DisplayName "RDP (UDP)" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 3389 -RemoteAddress $RemoteAddress -Profile Any -Enabled True | Out-Null

### NYC DOE Custom Additions ###

# Set CD-ROM Drive Letter to Z
Write-Output "Change drive letter of the CD-ROM to Z:..."
Get-WmiObject -Class Win32_volume -Filter "DriveType=5" | Select-Object -First 1 | Set-WmiInstance -Arguments @{DriveLetter="Z:"}

# Set Network Ring and Buffer Size
Write-Output "Setting Ring and Buffer Sizes..."
Set-NetAdapterAdvancedProperty (Get-NetAdapter | Where-Object status -eq "Up" | Select-Object -ExpandProperty name) -DisplayName "Small Rx Buffers" -DisplayValue "8192" -NoRestart -Verbose
Set-NetAdapterAdvancedProperty (Get-NetAdapter | Where-Object status -eq "Up" | Select-Object -ExpandProperty name) -DisplayName "Rx Ring #1 Size" -DisplayValue "4096" -NoRestart -Verbose

# Disable TCP IP Version 6
Write-Output "Disabling TCP IP Version 6..."
New-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xff -PropertyType "DWord"

# Make CD folder hidden
Write-Output "Making the CD Folder Hidden..."
Set-ItemProperty -LiteralPath "C:\CD" -Name Attributes -Value Hidden