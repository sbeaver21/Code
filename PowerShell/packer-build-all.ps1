<#
build-all-images.ps1

.--------------------------------------------------------------------------------------------------
.Created : NYC-DoE-DIIT - Server Operations
.Author  : Stephen Beaver
.Version : v1.0
.Date    : 09-2025
.Modified: 
.--------------------------------------------------------------------------------------------------

.SYNOPSIS
    A simple Powershell script to start the creation of VMware golden images via PackerIO.

.DESCRIPTION
    The script will scan for the folders located in .\build\windows\servers & .\build\linux\rhel.

.EXAMPLE
    ./build-all-images.ps1
    Runs without any parameters. Uses all the template values/settings. Will
    install the latest updated version of the guest OS.

.NOTES
    For this script to run properly you should add two environment path based on your setup.
    As an example....
    1. packer = D:\PackerIO\packer.exe.
    2. packerio = D:\PackerIO

    Otherwise adjust the value of $env:packerio to match your encironment
#>

Write-Host ""
Write-Host "Packer Golden Image Creation Process" -ForegroundColor White
Write-Host ""

# Create a list of linux builds to create.
$rhels = @(Get-ChildItem $env:packerio\builds\linux\rhel\ | Select-Object -Property "Name")

# Create a list of linux Ubuntu builds to create.
$ubuntus = @(Get-ChildItem $env:packerio\builds\linux\ubuntu\ | Select-Object -Property "Name")

# Create a list of windows builds to create.
$wins = @(Get-ChildItem $env:packerio\builds\windows\server\ | Select-Object -Property "Name")

#===============================================================================
# Start build process
#===============================================================================

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "Packer has started creating new updated golden image templates" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Set-Location -Path "$env:packerio\builds\linux\rhel\"
foreach ( $rhel in $rhels ) {
    Set-Location $rhel.Name
    Write-Host "Initializing linux-rhel-$($rhel.Name) : $(packer init -upgrade .).." -ForegroundColor Red
    Write-Host "Validating linux-rhel-$($rhel.Name) : $(packer validate .).." -ForegroundColor Yellow
    Write-Host "Packer has started building linux-rhel-$($rhel.Name)...." -ForegroundColor Green
    Start-Process packer -Argumentlist "build ." 
    Set-Location ../
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location -Path "$env:packerio\builds\windows\server\"
foreach ( $win in $wins ) {
    Set-Location $win.Name
    Write-Host "Initializing Windows-Server-$($win.Name) : $(packer init -upgrade .)..." -ForegroundColor Red
    Write-Host "Validating Windows-Server-$($win.Name) : $(packer validate .).." -ForegroundColor Yellow
    Write-Host "Packer has started building Windows-Server-$($win.Name)..." -ForegroundColor Green
    Start-Process packer -Argumentlist "build ."
    Set-Location ../
}

Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location -Path "$env:packerio\builds\linux\ubuntu\"
foreach ( $ubun in $ubuntus ) {
    Set-Location $ubun.Name
    Write-Host "Initializing linux-ubuntu-$($ubun.Name) : $(packer init -upgrade .).." -ForegroundColor Red
    Write-Host "Validating linux-ubuntu-$($ubun.Name) : $(packer validate .).." -ForegroundColor Yellow
    Write-Host "Packer has started building linux-ubuntu-$($ubun.Name)...." -ForegroundColor Green
    Start-Process packer -Argumentlist "build ." 
    Set-Location ../
}

#===============================================================================
# Script Complete
#===============================================================================

Set-Location -Path "$env:packerio\builds\"
Write-Host ""
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "Golden Image Creation Started Successfully" -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Have a nice day :)" -ForegroundColor White
#exit 0    