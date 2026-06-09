# Serve-ISO.ps1
#
# PowerShell script to serve ISOs from the project's iso/ directory over HTTP
# so that the vSphere Supervisor cluster can access them for image import.
# 
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/serve-iso.ps1
#
# To test locally before running in the Supervisor:
#   curl http://localhost:8080/
#   curl -O http://localhost:8080/SW_DVD9_Win_Server_STD_CORE_2025_24H2_64Bit_English_DC_STD_MLF_X23-81891.ISO
#
# Prerequisites:
#   - Python 3 must be available on the PATH
#
# Notes:
#   - This script will start a simple Python HTTP server on port 8080
#   - The server will serve files from the project's iso/ directory
#   - Press Ctrl+C to stop the server when done

param(
    [int]$Port = 8080,
    [string]$IsoDir = ""
)

# Determine ISO directory
if (-not $IsoDir) {
    $IsoDir = Join-Path $PSScriptRoot ".." ".." ".." ".." ".." "iso"
}
$IsoDir = Resolve-Path $IsoDir

# Verify ISO directory exists
if (-not (Test-Path $IsoDir)) {
    Write-Error "ISO directory not found: $IsoDir"
    exit 1
}

# Display available ISOs
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  vSphere Supervisor ISO File Server" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "ISO Directory: $IsoDir"
Write-Host ""
Write-Host "Available ISO files:" -ForegroundColor Green
Get-ChildItem -Path $IsoDir -Filter "*.iso" -Name | ForEach-Object {
    $file = Join-Path $IsoDir $_
    $size = (Get-Item $file).Length / 1GB
    Write-Host "  - $_ ($('{0:N2}' -f $size) GB)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Server URL: http://localhost:$Port/" -ForegroundColor Green
Write-Host ""

# Find local IP addresses for Supervisor cluster access
Write-Host "Local IP addresses for remote access:" -ForegroundColor Green
$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -ne "LinkLocal" -and $_.InterfaceAlias -notmatch "Loopback|Tunnel" -and $_.IPAddress -ne "127.0.0.1" }
foreach ($ip in $ips) {
    Write-Host "  http://$($ip.IPAddress):$Port/" -ForegroundColor White
}
Write-Host ""
Write-Host "Example import_source_url usage:" -ForegroundColor Green
foreach ($ip in $ips) {
    Get-ChildItem -Path $IsoDir -Filter "*.iso" -Name | ForEach-Object {
        Write-Host "  import_source_url = ""http://$($ip.IPAddress):$Port/$_""" -ForegroundColor White
    }
}
Write-Host ""
Write-Host "Starting HTTP server... Press Ctrl+C to stop." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Start Python HTTP server
Push-Location $IsoDir
try {
    python -m http.server $Port
}
finally {
    Pop-Location
}