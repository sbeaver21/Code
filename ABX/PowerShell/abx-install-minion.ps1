#---------------------------------------------------------------------------#
# ABX Action to install and/or configure the Salt Minion                    #
# Created by Stephen Beaver                                                 #
# v3.0.0 - Refactored: consolidated Linux install, fixed security issues,   #
#          eliminated dead code, batched grain ops, fixed salt-call path    #
# v2.2.0 - Bug fixes, local install and further cleanup                     #
# v2.1.0 - Refactored for modularity and performance                        #
# v2.0.4 - Refactored for structure, readability, and best practices        #
#---------------------------------------------------------------------------#

function handler($context, $inputs) {

    #---------------------------------------- Helper Functions ---------------------------------------#

    function Convert-SecureStringToPlainText {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)] [securestring] $SecureString
        )
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        try {
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        }
        finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }

    function Invoke-MyVMScript {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromPipeline)] $VM,
            [Parameter(Mandatory)]                    [string] $ScriptText,
            [Parameter(Mandatory)]                    [string] $User,
            [Parameter(Mandatory)]                    [securestring] $Password,
            [ValidateRange(1, 3600)]                  [int]    $WaitSecs    = 300,
            [string]                                            $Description = ''
        )

        if ($Description) {
            Write-Host $Description
        }

        try {
            $plainPassword = Convert-SecureStringToPlainText -SecureString $Password
            return Invoke-VMScript -VM $VM -ScriptText $ScriptText `
                -GuestUser $User -GuestPassword $plainPassword `
                -ToolsWaitSecs $WaitSecs -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to execute script '$Description' on VM '$($VM.Name)': $_"
            return $null
        }
    }

    # Waits until VMware Tools reports a usable status, with an optional timeout.
    function Wait-VMwareTools {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)] $VM,
            [ValidateRange(1, 3600)] [int] $TimeoutSeconds      = 600,
            [ValidateRange(1, 120)]  [int] $PollIntervalSeconds = 5
        )

        $elapsed = 0
        do {
            $toolsStatus = ($VM | Get-View).Guest.ToolsStatus
            Write-Host "VMware Tools status: $toolsStatus"

            if ($toolsStatus -eq 'toolsOk' -or $toolsStatus -eq 'toolsOld') {
                return $true
            }

            if ($elapsed -ge $TimeoutSeconds) {
                Write-Error "Timed out waiting for VMware Tools on '$($VM.Name)' after $TimeoutSeconds seconds."
                return $false
            }

            Start-Sleep -Seconds $PollIntervalSeconds
            $elapsed += $PollIntervalSeconds
        } while ($true)
    }

    # Run a scriptblock on the target VM and return the trimmed ScriptOutput.
    function Invoke-VMScriptAndGetOutput {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)] $VM,
            [Parameter(Mandatory)] [string] $ScriptText,
            [Parameter(Mandatory)] [string] $User,
            [Parameter(Mandatory)] [securestring] $Password,
            [int]    $WaitSecs    = 300,
            [string] $Description = ''
        )

        $result = Invoke-MyVMScript -VM $VM -ScriptText $ScriptText `
            -User $User -Password $Password -WaitSecs $WaitSecs -Description $Description
        if ($result) {
            return $result.ScriptOutput.Trim()
        }
        return $null
    }

    # Build a grains dictionary from custom properties (used by both Windows and Linux).
    function Build-GrainsHashtable {
        param(
            [hashtable] $CustomProps,
            [string] $EnvTag,
            [string] $MountPoints,
            [string] $DiskLabels,
            [string] $Role,
            [string] $MachineDomain,
            [string] $ShortDomain,
            [string] $VmId
        )

        $grains = [ordered]@{
            'custom.environmentTag' = $EnvTag
            'mountpoints'           = $MountPoints
            'custom.mounts'         = $MountPoints
            'mountlabels'           = $DiskLabels
            'custom.labels'         = $DiskLabels
            'role'                  = $Role
            'custom.role'           = $Role
            'custom.machineDomain'  = $MachineDomain
            'shortDomain'           = $ShortDomain
            'requestADName'         = $MachineDomain
            'vmId'                  = $VmId
            'min_install'           = 'Yes'
        }

        # Add role-specific grains.
        if ($Role -eq 'SQL') {
            $grains['custom.sqlserver'] = $CustomProps.'custom.sqlserver'
        }
        if ($Role -eq 'WEB') {
            $grains['custom.website']  = $CustomProps.'custom.website'
        }

        # Remove null/empty values.
        $filtered = [ordered]@{}
        foreach ($key in $grains.Keys) {
            $val = $grains[$key]
            if (-not [string]::IsNullOrWhiteSpace($val)) {
                $filtered[$key] = $val
            }
        }
        return $filtered
    }

    #---------------------------------------- Variables Definition -----------------------------------#

    $customProps = $inputs.customProperties

    # vCenter Connection
    $vcUser     = $context.getSecret($inputs.vcUsername)
    $vcPassword = $context.getSecret($inputs.vcPassword)
    $vcFqdn     = $customProps.vCenter

    # VM Details
    $vmName    = $inputs.resourceNames[0]
    $nameUpper = $vmName.ToUpper()
    $osType    = $customProps.osType

    # Salt Configuration
    $fingerPrint   = $customProps.masterFingerPrint
    $envTag        = $customProps.'custom.environmentTag'
    $role          = $customProps.role
    $masterString  = $customProps.masterString
    $masterAddress = $customProps.masterAddress
    $saltVersion   = $customProps.minionVersion

    # Domain/Machine Details
    $machineDomain = $customProps.'custom.machineDomain'
    $shortDomain   = $customProps.shortDomain
    $vmId          = $customProps.vmId

    # Disk/Mounts
    $mountPoints = $customProps.'custom.mountpoints'
    $diskLabels  = $customProps.'custom.mountlabels'

    # Credentials for Guest Operations ΓÇö convert plain-text secrets to SecureString immediately.
    $isWindowsOS = ($osType -eq 'WINDOWS')
    if ($isWindowsOS) {
        $tmplUser = $context.getSecret($inputs.template_admin_windows)
        $tmplPass = $context.getSecret($inputs.template_password_windows) |
            ConvertTo-SecureString -AsPlainText -Force
    }
    else {
        $tmplUser = $context.getSecret($inputs.template_admin_linux)
        $tmplPass = $context.getSecret($inputs.template_password_linux) |
            ConvertTo-SecureString -AsPlainText -Force
    }

    # Salt Master Management Credentials
    $smUser     = $context.getSecret($inputs.linux_vrautomation_user)
    $smPassword = $context.getSecret($inputs.linux_vrautomation_psswd) |
        ConvertTo-SecureString -AsPlainText -Force
    $mgtVCenter = $inputs.mgtvCenter

    # Event / lifecycle phase
    $eventCycle = $inputs.__metadata.eventTopicId

    # Salt grains to apply during highstate (defined once, used in both OS branches)
    $grains = Build-GrainsHashtable -CustomProps $customProps -EnvTag $envTag `
        -MountPoints $mountPoints -DiskLabels $diskLabels -Role $role `
        -MachineDomain $machineDomain -ShortDomain $shortDomain -VmId $vmId

    # Consistent salt-call path on Windows (Salt Project install path under ProgramData).
    $windowsSaltExe  = 'C:\ProgramData\Salt Project\Salt\salt-call.exe'
    $windowsSaltCall = "& '$windowsSaltExe'"

    #------------------------------------ Execution Logic -------------------------------------------#

    Write-Host "Connecting to vCenter $vcFqdn..."
    try {
        Connect-VIServer $vcFqdn -User $vcUser -Password $vcPassword -Force -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Error "Failed to connect to vCenter '$vcFqdn': $_"
        return $inputs
    }

    Write-Host "Getting Virtual Machine object for '$vmName'..."
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm) {
        Write-Error "VM '$vmName' not found in vCenter '$vcFqdn'."
        return $inputs
    }

    Write-Host "Verifying VMware Tools status on '$vmName'..."
    $toolsReady = Wait-VMwareTools -VM $vm -TimeoutSeconds 600
    if (-not $toolsReady) {
        return $inputs
    }

    Write-Host "Proceeding with Salt operations on '$vmName' [$osType]"

    #------------------------------------ Event Handling --------------------------------------------#

    if ($eventCycle -eq 'compute.removal.pre') {
        # Revoke the minion's auth before the VM is destroyed.
        Invoke-MyVMScript -VM $vm -ScriptText 'salt-call saltutil.revoke_auth' `
            -User $tmplUser -Password $tmplPass -Description 'Revoking Salt Auth...'
        Write-Host "Completed Salt Minion handling for '$vmName'."
        return $inputs
    }

    #---------------------------- Installation Phase -----------------------------------------------#

    if ($isWindowsOS) {
        # --- Windows Installation ---
        $saltDataPath = 'C:\ProgramData\Salt Project\Salt'
        $confPath     = "$saltDataPath\conf"

        # Set Network Profile to Private so WinRM / Salt can communicate.
        Invoke-MyVMScript -VM $vm `
            -ScriptText 'Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private' `
            -User $tmplUser -Password $tmplPass -Description 'Setting Network Profile to Private'

        $checkResult = Invoke-VMScriptAndGetOutput -VM $vm `
            -ScriptText "Test-Path '$saltDataPath'" `
            -User $tmplUser -Password $tmplPass -Description 'Checking for previous Salt installation...'
        $saltInstalled = ($checkResult -eq 'True')

        if ($saltInstalled) {
            Write-Host 'Salt Minion already installed. Updating minion ID only.'

            $idUpdateScript = @'
$id = $env:COMPUTERNAME.ToUpper()
$id | Set-Content -Path 'C:\ProgramData\Salt Project\Salt\conf\minion_id' -Force
(Get-Content -Path 'C:\ProgramData\Salt Project\Salt\conf\minion' -Raw) `
    -replace '(?m)^#?id:.*', "id: $id" `
    -replace '(?m)^-? es55vx-psm01.central.nyced.org', "  - es55vx-psm01.central.nyced.org" `
    -replace '(?m)^-? es55vx-psm02.central.nyced.org', "  - es55vx-psm02.central.nyced.org" |
    Set-Content -Path 'C:\ProgramData\Salt Project\Salt\conf\minion'
'@
            Invoke-MyVMScript -VM $vm -ScriptText $idUpdateScript `
                -User $tmplUser -Password $tmplPass -Description 'Updating Minion ID'
        }
        else {
            Write-Host 'Salt Minion not detected. Downloading and installing...'

            $downloadScript = @"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
`$bootstrapPath = "`$env:USERPROFILE\Downloads\bootstrap-salt.ps1"
Invoke-WebRequest -Uri 'https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.ps1' -OutFile `$bootstrapPath
& `$bootstrapPath -Master '$masterString' -Minion '$nameUpper' -Version '$saltVersion'
"@
            Invoke-MyVMScript -VM $vm -ScriptText $downloadScript `
                -User $tmplUser -Password $tmplPass -Description 'Downloading and bootstrapping Salt Minion'
        }

        # Configure the minion (fingerprint, startup_states, id).
        Write-Host "Configuring Salt Minion at '$confPath'..."
        $configScript = @"
# Taking ownership of the CD/Temp files and folders
takeown /f 'C:\Temp' /r /d y && icacls 'C:\Temp' /grant 'Administrators:(OI)(CI)F' /t /q /c && icacls 'C:\Temp' /inheritance:e /t /q /c
takeown /f 'C:\CD' /r /d y && icacls 'C:\CD' /grant 'Administrators:(OI)(CI)F' /t /q /c && icacls 'C:\CD' /inheritance:e /t /q /c

Set-Location -Path '$confPath'

# Ensure minion.d directory exists
if (-not (Test-Path '.\minion.d')) { New-Item -ItemType Directory -Path '.\minion.d' | Out-Null }

# Write minion_id
'$nameUpper' | Set-Content -Path '.\minion_id' -Force

# Patch the main minion file
`$content = Get-Content -Path '.\minion' -Raw
`$content = `$content -replace '(?m)^#?master_finger:.*',  'master_finger: $fingerPrint'
`$content = `$content -replace '(?m)^#?startup_states:.*', 'startup_states: highstate'
`$content = `$content -replace '(?m)^#?id:.*',             'id: $nameUpper'
`$content | Set-Content -Path '.\minion'

# Write drop-in config (idempotent: only add if not already present)
`$dropIn = '.\minion.d\minion.conf'
`$existing = if (Test-Path `$dropIn) { Get-Content `$dropIn -Raw } else { '' }
if (`$existing -notmatch 'master_finger') { Add-Content -Path `$dropIn -Value 'master_finger: $fingerPrint' }
if (`$existing -notmatch '^id:') { Add-Content -Path `$dropIn -Value 'id: $nameUpper' }
"@
        Invoke-MyVMScript -VM $vm -ScriptText $configScript `
            -User $tmplUser -Password $tmplPass -Description 'Configuring Salt Minion'
    }
    else {
        # --- Linux Installation ---
        # (Falls through to Linux branch below)

        # Convert master JSON string to a format suitable for bootstrap arguments.
        try {
            $masterJsonObj = $masterAddress | ConvertFrom-Json
            $masterListStr = ($masterJsonObj | ForEach-Object { '"' + $_ + '"' }) -join ','
            $masterObj     = "[$masterListStr]"
        }
        catch {
            Write-Warning "Failed to parse masterAddress JSON. Falling back to masterString."
            $masterObj = '["' + $masterString + '"]'
        }

        # Single clean Linux install script. Uses interpreter-level expansion for host-side
        # variables ($nameUpper, $masterObj, $saltVersion) and escapes the rest with heredoc.
        # Passwordless sudo is assumed for the serverops user ΓÇö if not available, the caller
        # should configure /etc/sudoers.d/serverops before this script runs.
        $linuxInstallScript = @"
#!/usr/bin/env bash
set -euo pipefail

if [[ -d "/etc/salt/" ]]; then
    echo "Minion already detected. Skipping bootstrap."
    exit 0
fi

echo "Minion not detected. Installing..."

# Set hostname
sudo hostnamectl set-hostname '$nameUpper'

cd /home/serverops

# Download bootstrap
curl -sL https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh -o install_salt.sh
chmod 755 install_salt.sh

# Run bootstrap
/bin/sh install_salt.sh -F \
    -A '$masterObj' \
    -i '$nameUpper' \
    stable '$saltVersion'

# Add Salt repo (for ongoing updates)
curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo \
    | sudo tee /etc/yum.repos.d/salt.repo > /dev/null 2>&1 || true

echo "Salt minion bootstrap complete."
"@
        $linuxOutput = Invoke-VMScriptAndGetOutput -VM $vm `
            -ScriptText $linuxInstallScript `
            -User $tmplUser -Password $tmplPass -WaitSecs 600 `
            -Description 'Installing Linux Minion'
        Write-Host "Linux install output: $linuxOutput"
    }

    #------------------------------------ Post Provisioning -----------------------------------------#

    if ($eventCycle -eq 'compute.provision.post') {
        Write-Host 'Post-provisioning configuration...'

        # --- Ensure Salt service is configured and running ---
        if ($isWindowsOS) {
            # Set service to auto-start.
            $null = Invoke-MyVMScript -VM $vm `
                -ScriptText "Set-Service -Name 'salt-minion' -StartupType Automatic" `
                -User $tmplUser -Password $tmplPass -Description 'Configuring Salt Minion service startup'

            # Determine if we need to start or restart the service.
            $serviceStatus = Invoke-VMScriptAndGetOutput -VM $vm `
                -ScriptText "(Get-Service -Name 'salt-minion' -ErrorAction SilentlyContinue).Status" `
                -User $tmplUser -Password $tmplPass

            if ($serviceStatus -eq 'Running') {
                Invoke-MyVMScript -VM $vm -ScriptText 'salt-call service.restart salt-minion' `
                    -User $tmplUser -Password $tmplPass -Description 'Restarting Salt Minion service'
            }
            else {
                Invoke-MyVMScript -VM $vm -ScriptText 'net start salt-minion' `
                    -User $tmplUser -Password $tmplPass -Description 'Starting Salt Minion service'
            }
        }
        else {
            # Linux: ensure SSH is running and (re)start the minion.
            $linuxPostScript = @'
#!/usr/bin/env bash
set -euo pipefail
systemctl enable --now sshd
systemctl restart salt-minion
'@
            Invoke-MyVMScript -VM $vm -ScriptText $linuxPostScript `
                -User $tmplUser -Password $tmplPass -Description 'Enabling SSH and restarting Salt Minion'
        }

        #-------------------------------- Accept Minion Keys -------------------------------------#

        Write-Host "Connecting to Salt Masters to accept key for '$vmName'..."

        # Connect to the management vCenter (where Salt Master VMs live) if it differs.
        if (-not [string]::IsNullOrWhiteSpace($mgtVCenter)) {
            Write-Host "Connecting to Management vCenter '$mgtVCenter'..."
            try {
                Connect-VIServer $mgtVCenter -User $vcUser -Password $vcPassword -Force -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Warning "Could not connect to management vCenter '$mgtVCenter': $_"
            }
        }

        $saltMasters = $masterString -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        foreach ($sm in $saltMasters) {
            $smShort = $sm.Split('.')[0]
            Write-Host "Accepting minion key on Salt Master '$smShort'..."

            $smVM = Get-VM -Name $smShort -ErrorAction SilentlyContinue
            if ($smVM) {
                $acceptCommand = "sudo salt-key -a '$vmName' -y"
                $null = Invoke-MyVMScript -VM $smVM -ScriptText $acceptCommand `
                    -User $smUser -Password $smPassword -Description "Accepting key on '$smShort'"
            }
            else {
                Write-Warning "Salt Master VM '$smShort' not found in current vCenter connection."
            }
        }

        #-------------------------------- Automation / Highstate ----------------------------------#

        if ($inputs.customProperties.highstate -eq 'true') {
            Write-Host 'Highstate requested. Starting automation...'

            if ($isWindowsOS) {
                try {
                    Write-Host 'Adding custom grains...'
                    foreach ($key in $grains.Keys) {
                        $val = $grains[$key]
                        Invoke-MyVMScript -VM $vm `
                            -ScriptText "$windowsSaltCall grains.setval '$key' '$val'" `
                            -User $tmplUser -Password $tmplPass `
                            -Description "Setting grain '$key'"
                    }

                    Write-Host 'Syncing Salt grains, states, modules, and all...'
                    Invoke-MyVMScript -VM $vm -ScriptText "$windowsSaltCall saltutil.sync_all" `
                        -User $tmplUser -Password $tmplPass -Description 'Syncing Salt all'

                    # Take ownership of CD and Temp folders (run locally via salt-call cmd.run).
                    $ownCmd = 'takeown /f "C:\CD" /r /d y && icacls "C:\CD" /grant "Administrators:(OI)(CI)F" /t /q /c && icacls "C:\CD" /inheritance:e /t /q /c'
                    Invoke-MyVMScript -VM $vm -ScriptText "$windowsSaltCall --local cmd.run '$ownCmd'" `
                        -User $tmplUser -Password $tmplPass -Description 'Taking ownership of CD files and folders'

                    $ownCmdTemp = 'takeown /f "C:\Temp" /r /d y && icacls "C:\Temp" /grant "Administrators:(OI)(CI)F" /t /q /c && icacls "C:\Temp" /inheritance:e /t /q /c'
                    Invoke-MyVMScript -VM $vm -ScriptText "$windowsSaltCall --local cmd.run '$ownCmdTemp'" `
                        -User $tmplUser -Password $tmplPass -Description 'Taking ownership of Temp files and folders'

                    Write-Host 'Installing SCCM...'
                    Invoke-MyVMScript -VM $vm -ScriptText "$windowsSaltCall state.apply windows.sccm.download" `
                        -User $tmplUser -Password $tmplPass -Description 'Downloading SCCM'
                    Invoke-MyVMScript -VM $vm -ScriptText "$windowsSaltCall state.apply windows.sccm.install" `
                        -User $tmplUser -Password $tmplPass -Description 'Installing SCCM'

                    Write-Host "Joining domain '$machineDomain'..."
                    Invoke-MyVMScript -VM $vm -ScriptText "$windowsSaltCall state.sls windows.ad-join" `
                        -User $tmplUser -Password $tmplPass -Description 'Applying AD Join state'

                    Start-Sleep -Seconds 30
                    Write-Host 'Windows automation complete. A reboot may be pending.'
                }
                catch {
                    Write-Error "Error during Windows automation: $_"
                }
            }
            else {
                # Linux: set grains then apply state.
                Write-Host 'Adding custom grains...'
                foreach ($key in $grains.Keys) {
                    $val = $grains[$key]
                    Invoke-MyVMScript -VM $vm `
                        -ScriptText "sudo salt-call grains.setval '$key' '$val'" `
                        -User $tmplUser -Password $tmplPass `
                        -Description "Setting grain '$key'"
                }

                Invoke-MyVMScript -VM $vm -ScriptText 'sudo salt-call saltutil.sync_grains' `
                    -User $tmplUser -Password $tmplPass -Description 'Syncing Salt grains'

                Write-Host 'Applying Linux highstate...'
                Invoke-MyVMScript -VM $vm -ScriptText 'sudo salt-call state.apply linux' `
                    -User $tmplUser -Password $tmplPass -WaitSecs 600 `
                    -Description 'Applying Linux state'

                Write-Host 'Linux state apply complete.'
                Start-Sleep -Seconds 30
            }
        }
    }

    Write-Host "Completed Salt Minion handling for '$vmName'."
    return $inputs
}
