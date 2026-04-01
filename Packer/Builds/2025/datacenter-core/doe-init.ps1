
<#
    .DESCRIPTION
    Performs DoE Specific Configurations on Windows builds.
#>

$ErrorActionPreference = 'Stop'

### NYC DOE Custom Additions ###

# Set Network Ring and Buffer Size
Write-Output "Setting Ring and Buffer Sizes..."
Set-NetAdapterAdvancedProperty (Get-NetAdapter | Where-Object status -eq "Up" | Select-Object -ExpandProperty name) -DisplayName "Small Rx Buffers" -DisplayValue "8192" -NoRestart -Verbose
Set-NetAdapterAdvancedProperty (Get-NetAdapter | Where-Object status -eq "Up" | Select-Object -ExpandProperty name) -DisplayName "Rx Ring #1 Size" -DisplayValue "4096" -NoRestart -Verbose

# Enable Remote Desktop.
Write-Output "Enabling Remote Desktop..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0 | Out-Null
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 0
Enable-NetFirewallRule -Group '@FirewallAPI.dll,-28752'

# Enable High Performance
Write-Output "Enabling High Performance Power Plan Settings..."
try
  {
    # Sets High Performance Power Plan Settings
    $HighPerf = powercfg -l | ForEach-Object {if($_.contains("High performance")) {$_.split()[3]}}
    $CurrPlan = $(powercfg -getactivescheme).split()[3]
    if ($CurrPlan -eq $HighPerf){
      Write-Output "High Performance Power Plan Already Enabled"
    }else{
      powercfg -setactive $HighPerf
      Write-Output "High Performance Power Plan Enabled"
    }
} catch {
	Write-Error "Failed to set the power to high performance..."
	Write-Error $_.Exception
	#Exit -1 
}

# Disable TCP IP Version 6
Write-Output "Disabling TCP IP Version 6..."
New-ItemProperty "HKLM:SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xff -PropertyType "DWord"

# Make CD folder hidden
Write-Output "Making the CD Folder Hidden..."
Set-ItemProperty -LiteralPath "C:\CD" -Name Attributes -Value Hidden