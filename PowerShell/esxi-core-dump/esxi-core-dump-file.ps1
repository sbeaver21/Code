<#
.SYNOPSIS
    Configures core dump settings on ESXi hosts in a vCenter cluster using an NFS share.
.DESCRIPTION
    Connects to a vCenter Server, retrieves all ESXi hosts in a specified cluster,
    and configures core dump to write to a file on an NFS share on each host.
.PARAMETER NFSServer
    The IP address or FQDN of the NFS server hosting the core dump directory.
.PARAMETER NFSDirectory
    The export path on the NFS server (e.g. /coredumps).
.PARAMETER VCenterFQDN
    The fully qualified domain name of the vCenter Server to connect to.
.PARAMETER ClusterName
    The name of the cluster containing the ESXi hosts to configure.
.PARAMETER Credential
    PSCredential object for authenticating to vCenter. If not provided, prompts the user.
.PARAMETER PassThru
    If specified, outputs the core dump file list for each host after configuration.
.EXAMPLE
    .\esxi-core-dump-file.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS"
.EXAMPLE
    .\esxi-core-dump-file.ps1 -NFSServer "10.0.0.100" -NFSDirectory "/coredumps" -VCenterFQDN "es10vcsa04.central.nyced.org" -ClusterName "VC-UCSM22-B200M4-36-PS" -PassThru
.NOTES
    Author: Stephen Beaver
    Version: 2.0.0
    Requires: PowerShell 5.1+, VMware PowerCLI 12.0+
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$NFSServer,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$NFSDirectory,

    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [string]$VCenterFQDN,

    [Parameter(Mandatory = $true, Position = 3)]
    [ValidateNotNullOrEmpty()]
    [string]$ClusterName,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential,

    [Parameter(Mandatory = $false)]
    [switch]$PassThru
)

#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'VMware.VimAutomation.Core'; ModuleVersion = '12.0' }

begin {
    Write-Verbose "Starting core dump NFS file configuration script"

    # Configure certificate handling for the current session only (not persistent)
    Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

    # Prompt for credentials if not supplied
    if (-not $Credential) {
        try {
            $Credential = Get-Credential -Message "Enter credentials to connect to vCenter Server: $VCenterFQDN"
            if (-not $Credential) {
                throw "Credential prompt was cancelled. Exiting."
            }
        }
        catch {
            Write-Error -Message $_.Exception.Message -Category AuthenticationError
            exit 1
        }
    }

    Write-Verbose "Connecting to vCenter Server: $VCenterFQDN"
}

process {
    try {
        # Connect to vCenter
        $viServer = Connect-VIServer -Server $VCenterFQDN -Credential $Credential -WarningAction SilentlyContinue -ErrorAction Stop
        Write-Host "Successfully connected to $VCenterFQDN" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Failed to connect to vCenter Server '$VCenterFQDN': $_" -Category ConnectionError
        exit 1
    }

    try {
        # Retrieve the cluster and its hosts
        Write-Verbose "Retrieving cluster: $ClusterName"
        $clusterObj = Get-Cluster -Server $viServer -Name $ClusterName -ErrorAction Stop
        $vmHosts = $clusterObj | Get-VMHost -ErrorAction Stop

        if (-not $vmHosts) {
            Write-Warning "No ESXi hosts found in cluster '$ClusterName'."
            return
        }

        Write-Host "Found $($vmHosts.Count) host(s) in cluster '$ClusterName'" -ForegroundColor Cyan
    }
    catch {
        Write-Error -Message "Failed to retrieve cluster/hosts: $_" -Category ObjectNotFound
        Disconnect-VIServer -Server $viServer -Force -Confirm:$false
        exit 1
    }

    $hostIndex = 0
    foreach ($vmHost in $vmHosts) {
        $hostIndex++
        $progressParams = @{
            Activity         = "Configuring core dump on ESXi hosts"
            Status           = "Processing host $($vmHost.Name) ($hostIndex of $($vmHosts.Count))"
            PercentComplete  = ($hostIndex / $vmHosts.Count) * 100
            CurrentOperation = $vmHost.Name
        }
        Write-Progress @progressParams

        Write-Host "`nProcessing host: $($vmHost.Name)" -ForegroundColor Yellow

        if ($PSCmdlet.ShouldProcess($vmHost.Name, "Configure NFS core dump file server='$NFSServer' path='$NFSDirectory'")) {
            try {
                # Get ESXCLI interface for this host
                $esxcli = Get-EsxCli -VMHost $vmHost -V2 -ErrorAction Stop

                # Step 1: Unconfigure any existing core dump file
                Write-Verbose "  Unconfiguring existing core dump file"
                $unconfigureArgs = $esxcli.system.coredump.file.set.CreateArgs()
                $unconfigureArgs.unconfigure = $true
                $esxcli.system.coredump.file.set.Invoke($unconfigureArgs)

                # Step 2: Add the new core dump file on the NFS share
                Write-Verbose "  Adding core dump file: $($vmHost.Name) on NFS server $NFSServer`:$NFSDirectory"
                $addArgs = $esxcli.system.coredump.file.add.CreateArgs()
                $addArgs.server    = $NFSServer
                $addArgs.directory = $NFSDirectory
                $addArgs.enable    = $true
                $addArgs.file      = $vmHost.Name
                $esxcli.system.coredump.file.add.Invoke($addArgs)

                # Step 3: Set the core dump file with smart dump enabled
                Write-Verbose "  Enabling core dump with smart dump"
                $setArgs = $esxcli.system.coredump.file.set.CreateArgs()
                $setArgs.enable       = $true
                $setArgs.smart        = $true
                $setArgs.unconfigure  = $false
                $esxcli.system.coredump.file.set.Invoke($setArgs)

                Write-Host "  NFS core dump configured successfully on $($vmHost.Name)" -ForegroundColor Green

                # Optionally output the core dump file list
                if ($PassThru) {
                    Write-Host "  Current core dump configuration:" -ForegroundColor Cyan
                    $esxcli.system.coredump.file.list.Invoke()
                }
            }
            catch {
                Write-Warning "Failed to configure NFS core dump on host '$($vmHost.Name)': $_"
            }
        }
    }

    Write-Progress -Activity "Configuring core dump on ESXi hosts" -Completed
}

end {
    # Clean up the vCenter connection
    if ($viServer) {
        try {
            Disconnect-VIServer -Server $viServer -Force -Confirm:$false -ErrorAction Stop
            Write-Host "`nDisconnected from vCenter Server: $VCenterFQDN" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to cleanly disconnect from vCenter: $_"
        }
    }
}